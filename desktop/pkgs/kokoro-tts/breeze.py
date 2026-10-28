"""Breeze TTS 2 daemon: speaks Claude's replies in a cloned voice.

POST /  text -> WAV, cloned from ~/.claude/tts-voice/ref.wav + ref.txt.

Started on demand by the hooks, not socket-activated: it only binds its port
once the model is loaded and warm (~40s), so a refused connection means "not
ready yet" and the hook falls back to Kokoro for that reply. Exits after
IDLE_TIMEOUT, or once no Claude Code session is left."""
import io, os, socket, subprocess, sys
from dataclasses import replace
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import numpy as np, soundfile as sf

sys.path.insert(0, os.environ["BREEZE_SRC"])
from infer import (  # noqa: E402  the upstream repo is not a package
    FAST_CONFIG, MAX_NEW_TOKENS, MAX_SEQ_LEN, REPETITION_PENALTY,
    FastBreezeStreamingRuntime, FastStreamingConfig, get_template, load_runtime,
    load_warmup_profile, prepare_inputs, resolve_device, select_template_name,
    set_all_seeds, update_generation_config_for_breeze,
)
from sessions import exit_when_no_sessions  # noqa: E402

PORT = int(os.environ.get("PORT", "8766"))
IDLE = int(os.environ.get("IDLE_TIMEOUT", "600"))
VOICE = Path.home() / ".claude" / "tts-voice"
REF_WAV, REF_TEXT = str(VOICE / "ref.wav"), (VOICE / "ref.txt").read_text().strip()

exit_when_no_sessions()
# A GPU-resident Kokoro plus Breeze does not fit beside the desktop in 16 GB.
# Kokoro is socket-activated and reloads on CPU while ENGINE=breeze.
subprocess.run(["systemctl", "--user", "stop", "kokoro-tts.service"], check=False)

tok, model, codec = load_runtime(Path(os.environ["BREEZE_MODEL"]), device=resolve_device(), attn_implementation="eager")
update_generation_config_for_breeze(model)
# ponytail: the three fast stages that fit in ~10 GB. Adding backbone_prefill
# (upstream's --fast-all) runs out of memory beside the desktop on a 16 GB card.
runtime = FastBreezeStreamingRuntime(
    model, codec,
    FastStreamingConfig(
        max_new_tokens=MAX_NEW_TOKENS, max_seq_len=MAX_SEQ_LEN, repetition_penalty=REPETITION_PENALTY,
        fast_backbone_decode=True, fast_depth_decoder=True, fast_codec=True,
    ),
    tokenizer=tok,
)
profile = load_warmup_profile(FAST_CONFIG)
runtime.warmup_from_profile(replace(profile, codec_chunk_frames=runtime.codec_chunk_frames))


def synth(text):
    req = {"id": "r", "text": text, "speaker": "S0", "ref_audio_path": REF_WAV, "ref_text": REF_TEXT}
    set_all_seeds(42)  # same text, same delivery
    inputs = prepare_inputs(tok, codec, model, [req], get_template(select_template_name(req)),
                            guidance_scale=1.0, guidance_scale_ref=None, guidance_scale_ins=None)
    # ponytail: the whole clip is generated before playback starts. Streaming
    # would cut the wait from ~half the clip length to ~0.1s; add it if the
    # wait on long conversational replies starts to grate.
    audio = np.concatenate([c.audio for c in runtime.iter_audio_chunks(inputs, request_id="r", seed=42)])
    buf = io.BytesIO()
    sf.write(buf, audio, runtime.sample_rate, format="WAV")
    return buf.getvalue()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def reply(self, code, body, ctype):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        text = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode("utf-8", "replace").strip()
        if not text:
            return self.reply(204, b"", "text/plain")
        try:
            self.reply(200, synth(text), "audio/wav")
        except Exception as e:
            self.reply(500, str(e).encode(), "text/plain")

    def log_message(self, *a):
        pass


# One request at a time: there is one model and one GPU.
srv = HTTPServer(("127.0.0.1", PORT), Handler)
srv.timeout = IDLE
srv.handle_timeout = lambda: sys.exit(0)
while True:
    srv.handle_request()
