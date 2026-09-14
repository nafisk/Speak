# Speak

Local speech-to-text and text-to-speech for macOS, with Raycast as the primary interface.

## Product intent

- Dictate with a shortcut and insert the transcript into the focused text field.
- Paste text into Raycast and listen to it with a local speech model.
- Prioritize responsiveness, accurate transcription, and simple controls.
- Process speech and text locally after initial model downloads.

## Status

Discovery and MVP planning. No application code or model dependencies have been installed.

The canonical development directory is `/Users/nafiskhan/Developer/Speak`. Keep all Speak source, research, and project documentation here.

Repository: [nafisk/Speak](https://github.com/nafisk/Speak) (private).

## Start here

- [MVP plan](docs/mvp-plan.md): confirmed preferences, proposed architecture, milestones, and acceptance checks.
- [Research](docs/research.md): Raycast development and distribution, model candidates, and brief Alfred/native comparisons.

Confirmed MVP: English; press a shortcut once to record and again to stop; preserve wording with punctuation and capitalization. The proposed stack is a Raycast extension plus a local Swift companion, with Parakeet for dictation and Kokoro for speech synthesis. Model selection remains provisional until measured on the target Mac.
