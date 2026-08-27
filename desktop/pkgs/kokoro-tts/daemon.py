"""Socket-activated Kokoro TTS daemon. POST text, get WAV back.
systemd starts it on first connection; it exits itself after IDLE_TIMEOUT."""
import io, os, socket, sys
import numpy as np, soundfile as sf, torch
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from kokoro import KPipeline

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
IDLE = int(os.environ.get("IDLE_TIMEOUT", "600"))
_pipes = {}

def pipeline(voice):  # lang_code is the voice's first letter: a=US, b=UK, ...
    lang = voice[0]
    if lang not in _pipes:
        _pipes[lang] = KPipeline(lang_code=lang, repo_id="hexgrad/Kokoro-82M", device=DEVICE)
    return _pipes[lang]

class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def do_POST(self):
        text = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode("utf-8", "replace").strip()
        if not text:
            self.send_response(204); self.send_header("Content-Length", "0"); self.end_headers(); return
        voice = self.headers.get("X-Voice", "af_heart")
        speed = float(self.headers.get("X-Speed", "1.0"))
        try:
            audio = np.concatenate([a for _, _, a in pipeline(voice)(text, voice=voice, speed=speed)])
            buf = io.BytesIO(); sf.write(buf, audio, 24000, format="WAV"); body = buf.getvalue()
            self.send_response(200); self.send_header("Content-Type", "audio/wav")
        except Exception as e:
            body = str(e).encode(); self.send_response(500)
        self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass

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
