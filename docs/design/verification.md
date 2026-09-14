# Design verification

2026-09-13. Scope: proposed visual language, semantic tokens, and a simulated interaction preview. No native application implementation or dependencies were added.

## Completed checks

- Parsed `tokens.json` and calculated WCAG sRGB contrast for primary/secondary text and filled accent controls in both appearances using Python.
- Primary text on content: 16.78:1 light, 14.28:1 dark.
- Secondary text on content: 5.76:1 light, 7.88:1 dark. On opaque chrome, the lowest checked text pairing is 4.85:1.
- Iris button foreground: 5.69:1 light, 8.47:1 dark. Tide alternative: 6.17:1 light, 9.45:1 dark.
- JavaScript syntax checked with `node --check`; HTML IDs checked for uniqueness and literal element references checked against markup using Python's HTML parser.
- Source reviewed for local-only simulation, no microphone access or network requests, accessible names, one-time state announcements, and responsive/reduced-motion styling.

## Remaining validation

Browser security blocked opening the local rendered preview. Browser rendering, layout at narrow widths, keyboard interaction, and runtime behavior have not been visually verified. The inline preview is a design study, with simulated capture/playback and sample transcripts.

Token contrast calculations cover opaque surfaces only. Native Liquid Glass requires checks on macOS 26+, including busy backgrounds, Reduce Transparency, Increase Contrast, Reduce Motion, and VoiceOver. The current Mac's macOS 15.7.7 material fallback also needs native UI testing. Audio continuity, model latency, focus preservation, and insertion behavior must be verified with the actual app; the preview provides no evidence for those behaviors.
