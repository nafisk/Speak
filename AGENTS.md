# Speak project guidance

- Canonical project root: `/Users/nafiskhan/Developer/Speak`. Keep project source and documentation here. Do not use sibling projects as implementation workspaces.
- Use Git for versioning and keep commits scoped. Inspect changes before editing; do not overwrite user work.
- Current phase: discovery and MVP planning. Make the transition into application implementation explicit.
- Use a regular plan unless the user explicitly requests gated SDD.
- Raycast is the primary interface. Alfred and a standalone Mac interface are secondary possibilities.
- Speech inference must run locally. Initial dependency/model downloads are separate from offline runtime operation.
- Never commit credentials, model weights, personal recordings, or transcripts.
- Ask before adding dependencies or network-facing behavior unless the user has already authorized that specific scope. Preserve macOS permission boundaries.
- Treat latency and accuracy claims as unverified until measured on the target Mac.
- Keep decisions, open questions, and verification evidence in `docs/`.
