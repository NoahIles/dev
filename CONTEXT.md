# CONTEXT

Domain glossary for this repo. Terms only — no implementation detail.

## Claude Code TTS

**Mode** — the single setting governing speech. One of `off`, `gist`,
`conversational`. Replaces the old `ENABLED` flag; there is no mode in which the
user selects truncation.

**Truncation** — the first N characters of a reply, cut to a sentence boundary.
The *fallback only*: what `gist` mode speaks when no gist line was emitted.
Never a mode the user chooses.

**Gist** — one conversational sentence emitted by Claude on its own line, marked
with a leading 🔊, summarising the turn. Visible on screen; it is what `gist`
mode speaks. The reply above it keeps its normal detail.

**Conversational mode** ("jarvis") — the reply itself is written for the ear, and
spoken in full with no length cap.

**Playback** — one clip being spoken. At most one exists: a newer playback
supersedes and cancels the one in progress.

**Interrupt** — cancelling the current playback. Three triggers: the user submits
a new prompt, the user presses the dedicated key, or a newer turn supersedes it.
