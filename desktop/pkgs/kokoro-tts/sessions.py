"""Shut a TTS daemon down once the last Claude Code session has quit."""
import os, threading, time
from pathlib import Path


def claude_running():
    for p in Path("/proc").iterdir():
        if not p.name.isdigit():
            continue
        try:
            if (p / "comm").read_text().strip() != "claude":
                continue
            # ponytail: Chrome's Claude extension host is also a `claude`
            # process and outlives every session, so it must not count.
            if b"--chrome-native-host" in (p / "cmdline").read_bytes():
                continue
            return True
        except OSError:
            continue
    return False


def exit_when_no_sessions(grace=30, poll=10):
    """Exit once no session has been seen for `grace` seconds. The grace period
    covers closing one terminal and opening another."""

    def loop():
        gone = None
        while True:
            time.sleep(poll)
            if claude_running():
                gone = None
            elif gone is None:
                gone = time.monotonic()
            elif time.monotonic() - gone >= grace:
                os._exit(0)

    threading.Thread(target=loop, daemon=True).start()
