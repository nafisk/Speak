# Speak: focused technical research

Checked 2026-09-13 (America/New_York). Findings below come from primary documentation and project/model maintainers. Recommendations are engineering judgments; no model benchmarks were run locally.

## Raycast development and production

Extensions use TypeScript/React with Raycast components. The documented prerequisites include Node 22.14+ and npm 7+. Use Create Extension or import source from within this repository. `npm install` followed by `npm run dev` provides development reloads; installed development commands remain available after stopping the dev process. Local use does not require Store publication. [Prerequisites](https://developers.raycast.com/basics/getting-started), [development flow](https://developers.raycast.com/basics/create-your-first-extension).

Raycast unloads completed commands and imposes command memory limits. Its scheduled background refresh is intended for intermittent tasks, not as a guarantee that models remain resident. Therefore, a persistent companion is the proposed home for capture, inference, and playback. This is an architectural inference, not a Raycast requirement. [Lifecycle](https://developers.raycast.com/information/lifecycle), [background refresh](https://developers.raycast.com/information/lifecycle/background-refresh).

Raycast supports aliases, view/no-view commands, and multiline forms. Clipboard.paste inserts into the frontmost app; closeMainWindow dismisses Raycast. These APIs do not establish reliable delayed insertion into a previously focused field, so that behavior needs a prototype. [Clipboard](https://developers.raycast.com/api-reference/clipboard), [window control](https://developers.raycast.com/api-reference/window-and-search-bar), [forms](https://developers.raycast.com/api-reference/user-interface/form).

Raycast also provides Swift bridging tools for native APIs. A bridge alone does not establish a persistent service lifecycle. Check its exact toolchain requirements before adopting it. [Official Swift tools](https://github.com/raycast/extensions-swift-tools).

For Store distribution, build with `npm run build`, follow preparation guidelines, and use `npm run publish` to open/update a PR in raycast/extensions. Raycast reviews the submission before publication. Include the npm lockfile. Heavy/opaque binaries and executable download provenance are review concerns; use traceable builds and integrity checks. A companion creates a separate installation/distribution concern that the extension must explain. [Publishing](https://developers.raycast.com/basics/publish-an-extension), [Store guidelines](https://developers.raycast.com/basics/prepare-an-extension-for-store).

## Model shortlist

| Purpose | Candidate | Why evaluate it | Limitation |
| --- | --- | --- | --- |
| Speech to text | NVIDIA Parakeet TDT 0.6B v3 | Local model with punctuation/capitalization; English is supported. | Published results do not predict M1 Pro end-to-end latency or personal vocabulary accuracy. |
| Text to speech | Kokoro 82M | Compact open-weight model suitable for evaluating English read-aloud. | Test voice quality, abbreviations, names, and first-audio delay. |
| Swift runtime | FluidAudio | Supports Parakeet and Kokoro on Apple devices using local models. | Current README contains inconsistent broad language/beta statements; pin a tested release and inspect actual APIs/assets. |
| STT fallback | WhisperKit / Argmax OSS Swift | Apple Silicon on-device speech stack; evaluate if the preferred recognizer misses the accuracy target. | Additional runtime/model integration; not needed unless the baseline fails. |

The Parakeet card lists CC BY 4.0 terms; Kokoro lists Apache 2.0 weights; FluidAudio identifies an Apache 2.0 code license. Keep code, model conversions, voices, and auxiliary phonemizer assets separately inventoried before distribution. [Parakeet model card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3), [Kokoro model card](https://huggingface.co/hexgrad/Kokoro-82M), [FluidAudio](https://github.com/FluidInference/FluidAudio), [Argmax OSS Swift](https://github.com/argmaxinc/argmax-oss-swift).

FluidAudio describes Kokoro as non-streaming. Speak can synthesize short sentences and queue their audio to reduce the wait before playback. This needs bounded buffering and cancellation. Its automatic first-use model downloads also need explicit setup handling so normal use works offline and loading is visible. Do not equate model inference throughput with shortcut-to-result latency. [FluidAudio TTS documentation in README](https://github.com/FluidInference/FluidAudio#text-to-speech-tts).

## Open-source dictation reference

[Handy](https://github.com/cjpais/Handy) is an independent MIT-licensed alternative with offline transcription, shortcut recording, paste into text fields, and a Raycast integration. Its README documents toggle/cancel CLI controls and a Tauri/Rust implementation. Study the user flow, permission onboarding, session lifecycle, and focus handling. It is not the Wispr Flow source code. It is also a credible build-versus-integrate option; the proposed Speak route owns a small macOS companion to unify dictation and TTS without requiring a separate dictation product.

## Brief alternatives

| Interface | What it would take | Recommendation |
| --- | --- | --- |
| Alfred | Powerpack workflow: Hotkey/Keyword → Run Script → the same companion control CLI. Hotkeys can carry clipboard/selection and focused-app context. | Add later after the companion interface stabilizes. |
| Native Mac app | Extend the Swift companion with SwiftUI/AppKit settings, text input, menu-bar controls, and its own global shortcut management. | Preserve this option, but keep the first user-facing interface in Raycast. |

Alfred's workflow capabilities are a Powerpack feature. [Powerpack](https://www.alfredapp.com/powerpack/), [Hotkey trigger](https://www.alfredapp.com/help/workflows/triggers/hotkey/), [Run Script](https://www.alfredapp.com/help/workflows/actions/run-script/).

A Mac companion must declare microphone usage and request authorization. Accessibility permission may be needed for insertion/global interaction depending on ownership. For direct public distribution, plan Developer ID signing and notarization; local development and public packaging are separate steps. [Microphone authorization](https://developer.apple.com/documentation/bundleresources/requesting-authorization-for-media-capture-on-macos), [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Local environment checked

| Item | Observed |
| --- | --- |
| Mac | MacBook Pro, M1 Pro, 16 GB |
| macOS | 15.7.7 |
| Raycast | 1.104.29 in /Applications |
| Node / npm | 26.5.0 / 11.17.0 |
| Swift | 6.2.4, arm64 |

Xcode is selected at `/Applications/Xcode.app/Contents/Developer`. Choose a documented compatible Node version and pinned Swift dependencies during implementation; the presence of tools is not a successful build check. No package installations, downloads of weights, recordings, performance tests, or runtime permission changes were made.
