"""Socket-activated Kokoro TTS daemon.

POST /          text -> WAV bytes (the Stop hook's synthesis path)
GET  /          the config UI
GET  /voices    JSON list of available Kokoro voices
GET  /config    current ~/.claude/tts.conf as JSON
POST /config    write ~/.claude/tts.conf
POST /edit-style  open the conversational output style in $EDITOR

systemd starts it on first connection; it exits itself after IDLE_TIMEOUT."""
import io, json, os, shlex, socket, ssl, subprocess, sys, urllib.request
import numpy as np, soundfile as sf, torch
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from kokoro import KPipeline

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
IDLE = int(os.environ.get("IDLE_TIMEOUT", "600"))
CONF = Path.home() / ".claude" / "tts.conf"
STYLE = Path.home() / ".claude" / "output-styles" / "jarvis.md"
UI = Path(__file__).with_name("ui.html").read_text()
DEFAULTS = {
    "MODE": "gist",
    "VOICE": "af_heart",
    "SPEED": "1.1",
    "FALLBACK_CHARS": "300",
    "GIST_PROMPT": "End every reply with a line starting '\U0001f50a ' holding one "
    "short spoken-English sentence saying what you did and whether I need to act.",
}
_pipes = {}
_voices = []


def pipeline(voice):  # lang_code is the voice's first letter: a=US, b=UK, ...
    lang = voice[0]
    if lang not in _pipes:
        _pipes[lang] = KPipeline(lang_code=lang, repo_id="hexgrad/Kokoro-82M", device=DEVICE)
    return _pipes[lang]


def voices():
    if not _voices:
        # ponytail: the uv venv has no system CA bundle on the loader path, so
        # plain urlopen fails to verify. certifi is already here via kokoro.
        import certifi

        ctx = ssl.create_default_context(cafile=certifi.where())
        with urllib.request.urlopen(
            "https://huggingface.co/api/models/hexgrad/Kokoro-82M", timeout=10, context=ctx
        ) as r:
            for s in json.load(r)["siblings"]:
                n = s["rfilename"]
                if n.startswith("voices/") and n.endswith(".pt"):
                    _voices.append(n[len("voices/") : -len(".pt")])
        _voices.sort()
    return _voices


def read_conf():
    conf = dict(DEFAULTS)
    if CONF.exists():
        for line in CONF.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            k = k.strip()
            if k in DEFAULTS:
                # values may be quoted and/or followed by a trailing comment
                parts = shlex.split(v, comments=True)
                conf[k] = parts[0] if parts else ""
    return conf


def write_conf(new):
    conf = read_conf()
    for k, v in new.items():
        if k in DEFAULTS:
            # ponytail: tts.conf is `source`d by bash, so newlines would break it
            conf[k] = " ".join(str(v).split())
    CONF.parent.mkdir(parents=True, exist_ok=True)
    body = "# Claude Code TTS config. Written by the UI at http://127.0.0.1:8765/\n"
    body += "".join(f"{k}={shlex.quote(conf[k])}\n" for k in DEFAULTS)
    CONF.write_text(body)
    return conf


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def reply(self, code, body, ctype):
        if isinstance(body, str):
            body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/voices"):
            try:
                self.reply(200, json.dumps(voices()), "application/json")
            except Exception as e:
                self.reply(502, json.dumps({"error": str(e)}), "application/json")
        elif self.path.startswith("/config"):
            self.reply(200, json.dumps(read_conf()), "application/json")
        elif self.path in ("/", "/index.html"):
            self.reply(200, UI, "text/html; charset=utf-8")
        else:
            self.reply(404, "not found", "text/plain")

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path.startswith("/config"):
            try:
                self.reply(200, json.dumps(write_conf(json.loads(raw))), "application/json")
            except Exception as e:
                self.reply(400, json.dumps({"error": str(e)}), "application/json")
            return
        if self.path.startswith("/edit-style"):
            # ponytail: the style file is deliberately not nix-managed, so it is
            # writable — an HM-owned symlink into /nix/store could not be saved.
            STYLE.parent.mkdir(parents=True, exist_ok=True)
            STYLE.touch()
            editor = os.environ.get("EDITOR") or "xdg-open"
            subprocess.Popen([editor, str(STYLE)], start_new_session=True)
            self.reply(200, json.dumps({"opened": str(STYLE)}), "application/json")
            return
        text = raw.decode("utf-8", "replace").strip()
        if not text:
            self.send_response(204)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        voice = self.headers.get("X-Voice", "af_heart")
        speed = float(self.headers.get("X-Speed", "1.0"))
        try:
            audio = np.concatenate([a for _, _, a in pipeline(voice)(text, voice=voice, speed=speed)])
            buf = io.BytesIO()
            sf.write(buf, audio, 24000, format="WAV")
            self.reply(200, buf.getvalue(), "audio/wav")
        except Exception as e:
            self.reply(500, str(e), "text/plain")

    def log_message(self, *a):
        pass


class Server(ThreadingHTTPServer):
    daemon_threads = True


srv = Server(("127.0.0.1", 0), Handler, bind_and_activate=False)
srv.socket.close()
# ponytail: fd 3 is the listening socket systemd hands us
srv.socket = socket.socket(fileno=3) if os.environ.get("LISTEN_FDS") else socket.create_server(("127.0.0.1", 8765))
srv.server_name, srv.server_port = "localhost", srv.socket.getsockname()[1]
srv.timeout = IDLE
srv.handle_timeout = lambda: sys.exit(0)
while True:
    srv.handle_request()
