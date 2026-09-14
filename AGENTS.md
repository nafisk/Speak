# Speak project guidance

- Canonical project root: `/Users/nafiskhan/Developer/Speak`. Keep project source and documentation here. Do not use sibling projects as implementation workspaces.
- Use Git for versioning and keep commits scoped. Inspect changes before editing; do not overwrite user work.
- Current phase: local model feasibility prototypes and native app design. Mac and Raycast application implementation has not started.
- Use a regular plan unless the user explicitly requests gated SDD.
- A minimal native Swift/SwiftUI Mac companion owns speech functionality. Raycast is the first control integration; Alfred follows later. Design direction and tokens live in `docs/design/`.
- Dictation is shortcut-first through a small waveform overlay; routine use must not open the main app. Keep the optional reader compact (440 pt target width, 12 pt padding), with dedicated settings. Tide teal replaces the rejected purple accent. Raycast should expose TTS functionality using its supported native controls.
- Every meaningful user-visible state change needs a deliberate, representative transition using supported platform animation. Preserve continuity, make transitions interruptible, never delay the underlying action, and provide Reduce Motion alternatives. Follow the motion contract in `docs/design/design-language.md`.
- The user selected Pearl & Tide after reviewing the Wispr Flow-inspired Paper & Ink comparison. Keep the comparison as reference only. Next implementation milestone is native shortcut → waveform → local transcription → insertion, with the main window closed.
- Speech inference must run locally. Initial dependency/model downloads are separate from offline runtime operation.
- Never commit credentials, model weights, personal recordings, or transcripts.
- Ask before adding dependencies or network-facing behavior unless the user has already authorized that specific scope. Preserve macOS permission boundaries.
- Treat latency and accuracy claims as unverified until measured on the target Mac.
- Keep decisions, open questions, and verification evidence in `docs/`.
- GitHub repository `nafisk/Speak` is public; the user wants to build in public.
- Prototype dependency: FluidAudio 0.15.7, locked in `prototypes/Package.resolved`. The user authorized the STT/TTS prototypes and their local model setup.
