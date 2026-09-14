# Speak

Local speech-to-text and text-to-speech in a minimal native Mac app, with Raycast and later Alfred as control layers.

## Product intent

- Dictate with a shortcut and insert the transcript into the focused text field.
- Paste text into Raycast and listen to it with a local speech model.
- Prioritize responsiveness, accurate transcription, and simple controls.
- Process speech and text locally after initial model downloads.

## Status

The native Mac companion and Raycast development extension are implemented. The user confirmed shortcut dictation inserts correctly into Notes. Reader and integration validation is underway; this is a development MVP, not a packaged public release.

[Implementation tracker](docs/implementation-plan.md) · [Run the Mac app](app/README.md) · [Run the Raycast extension](raycast/README.md) · [Verification evidence](docs/native-mvp-results.md)

[Design language — Pearl & Tide](docs/design/design-language.md): colors, materials, typography, interaction standards, and accessibility. [Design verification](docs/design/verification.md) records checks and remaining gaps.

[Wispr Flow audit and Paper & Ink alternative](docs/design/wispr-flow-audit.md): public-source design review and a separate comparison concept; Pearl & Tide remains the current direction.

The canonical development directory is `/Users/nafiskhan/Developer/Speak`. Keep all Speak source, research, and project documentation here.

Repository: [nafisk/Speak](https://github.com/nafisk/Speak) (public; building in public).

## Start here

- [MVP plan](docs/mvp-plan.md): confirmed preferences, proposed architecture, milestones, and acceptance checks.
- [Research](docs/research.md): Raycast development and distribution, model candidates, and brief Alfred/native comparisons.
- [Run the prototypes](prototypes/README.md): build, dictate, listen, and benchmark locally.
- [Feasibility results](docs/feasibility-results.md): measured latency and remaining gaps.
- [Formatting and live speed controls](docs/prototype-quality-of-life.md): current behavior and verification.

Confirmed MVP: English; press a shortcut once to record and again to stop; preserve wording with punctuation and capitalization. The chosen architecture is a native Swift/SwiftUI companion with a Raycast control extension, using Parakeet for dictation and Kokoro for speech synthesis. Local latency measurements are recorded in the feasibility results; real microphone accuracy and perceived quality still need user validation.
