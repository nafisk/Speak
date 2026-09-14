# Design verification

2026-09-13, revision 2. Scope: compact reader, separate shortcut-driven waveform overlay, dedicated settings, Tide accent, and simulated interaction preview. No native application implementation or dependencies were added.

## Completed checks

- Parsed `tokens.json` and calculated WCAG sRGB contrast for primary/secondary text and filled accent controls in both appearances using Python.
- Primary text on content: 16.78:1 light, 14.28:1 dark.
- Secondary text on content: 5.76:1 light, 7.88:1 dark. On opaque chrome, the lowest checked text pairing is 4.85:1.
- Tide button foreground: 6.17:1 light, 9.45:1 dark. The previous purple accent has been removed.
- JavaScript syntax checked with `node --check`; HTML IDs checked for uniqueness and literal element references checked against markup using Python's HTML parser.
- Source reviewed for local-only simulation, no microphone access or network requests, accessible names, one-time state announcements, and responsive/reduced-motion styling.

Reproduce static checks with `python3 docs/design/checks/check-preview.py` (Python and Node required). The check validates syntax, unique IDs, literal element references, and opaque text contrast; it does not execute UI interactions.

The preview has a local keyboard handler, synthetic waveform, and sample insertion into its own example field. It does not register a system shortcut or access any other application. Source review covers cancellation of pending sample insertion and retaining playback position when rate changes; these paths still need runtime testing. Shortcut choices in Settings are examples, not production conflict-checked bindings.

## Remaining validation

Browser security blocked opening the local rendered preview. Browser rendering, layout at narrow widths, keyboard interaction, and runtime behavior have not been visually verified. The inline preview is a design study, with simulated capture/playback and sample transcripts.

Token contrast calculations cover opaque surfaces only. Native Liquid Glass requires checks on macOS 26+, including busy backgrounds, Reduce Transparency, Increase Contrast, Reduce Motion, and VoiceOver. The current Mac's macOS 15.7.7 material fallback also needs native UI testing. Audio continuity, model latency, focus preservation, and insertion behavior must be verified with the actual app; the preview provides no evidence for those behaviors.
