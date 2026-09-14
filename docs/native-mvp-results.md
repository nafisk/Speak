# Native MVP verification

Date: 2026-09-13. Development Mac: Apple M1 Pro, 16 GB, macOS 15.7.7; Swift 6.2.4 / Xcode 26.3. FluidAudio 0.15.7, Parakeet v3, Kokoro Heart. Pearl & Tide remains the chosen design.

## Implemented

`app/` contains the native menu-bar companion, compact reader/settings, nonactivating waveform panel, local speech engine, guarded Accessibility insertion, and same-user control socket. `speakctl` passes structured commands from `raycast/`. The prototype support library now exports the existing formatter and player; pause/resume preserves the player and its position.

State transitions use session identities so cancelled/replaced work cannot insert. The original field's application, identity, value, and selection must still match at completion. Unsupported targets recover to explicit Copy. No Enter is synthesized. Recording stops at 120 seconds; ordinary completion/cancellation removes its private temporary WAV. Text is kept in memory only. A crash may leave its temporary recording behind; startup cleanup is not implemented yet.

The reader caps input at 20,000 characters, divides it into passages of at most 240 graphemes, and prepares one passage ahead. Rate changes reuse the current AVAudioPlayer with a 150 ms ramp. This establishes control continuity; acoustic smoothness across real speech and passage boundaries still needs listening validation.

## Executed checks

| Check | Result |
| --- | --- |
| `app/build.sh` | Release executable and ad-hoc signed `.app` built successfully, including repeated bundle builds. SDK 26 compilation succeeds; macOS 26 appearance has not been viewed. |
| `swift test --package-path app -c release -j 4` | 7 tests passed: stale/cancelled sessions, one insertion, UTF-16 ranges, chunk preservation/bounds, request validation, socket round-trip/mode, unexpected-file protection. |
| `SPEAK_AUDIO_TESTS=1 swift test --package-path prototypes -c release -j 4` | 8 tests passed, including muted playback/rate continuity, pause position, and resume. |
| Native app launch and initial UI inspection | Compact dark reader opened. Later changes fix button contrast, settings height, overlay fade interruption, and redundant idle progress publications; those visual changes still need a renewed inspection. |
| User microphone + Accessibility setup; shortcut dictation in Notes | User reported **“Text inserted correctly.”** This is a real happy-path result, not a measured accuracy or latency benchmark. No personal transcript is recorded here. |
| `npm run typecheck --prefix raycast` / `npm run build --prefix raycast` | Both passed with official Raycast SDK 2.3.1. |
| `npm audit --prefix raycast` | Zero vulnerabilities after removal of unused optional `react-devtools`. Before removal, advisories came through that debugger's transitive dependencies. |
| `npm run dev --prefix raycast` and Raycast UI | All four Speak commands appeared. Read Text opened; control path configured via native setup. Text area, speed selector, voice, and status rendered. |
| Live controller against older running companion | Returned “Open Speak first, then retry.” That process predates the socket implementation. Computer-control requests to Speak timed out; user restart requested. Real shared playback remains unverified. |

Sampling the older app showed repeated SwiftUI layout work while idle. The timer was publishing unchanged playback values every 40 ms; it now publishes only changes. Rebuilt successfully. CPU improvement and automation recovery require a restarted-process check.

## Remaining acceptance checks

1. Restart the updated companion, verify `speakctl status`, play a real passage from Raycast, pause/resume, change speed during speech, and close both windows while playback continues. Listen for passage gaps and test stop during synthesis.
2. Dictate into a browser with Speak closed; cancel during recording and processing; change target focus/selection before completion; verify manual-copy recovery, silence, and permission denial.
3. Measure at least 20 warm end-to-end trials and cold starts; record memory with both models loaded. Existing [prototype benchmarks](feasibility-results.md) do not measure these paths.
4. Test offline operation after downloads, unexpected exit and recording cleanup, keyboard-only/VoiceOver use, Reduce Motion/Transparency, and macOS 26 materials.

This is a locally installed development MVP. Public distribution, license selection, signing/notarization, installation/update UX, and Alfred remain later work in the [tracker](implementation-plan.md).

## Live test follow-up — 2026-09-14

The user asked for agent-run end-to-end testing. The stale process from the previous day was quit through Activity Monitor; the rebuilt app launched and `speakctl status` returned successfully. Raycast's Read Text form submitted a synthetic, non-personal passage and the companion queued speech.

**A real playback failure was found.** A process stack sample showed the UI thread blocked inside `AVAudioPlayer.prepareToPlay`, waiting on Core Audio device initialization (`AudioDeviceCreateIOProcID`). The selected output was Scarlett Solo USB at 192 kHz. This identifies the blocking call, but does not establish that the device/driver alone is at fault; a built-in-speaker comparison is still pending.

The shared player now prepares audio on a background dispatch worker and awaits it asynchronously, with a five-second timeout. Stop/cancellation resumes the caller immediately, late preparation is discarded, and only one blocked preparation may exist per player. Session identity prevents an old cancellation from affecting a newer request. Both native and prototype callers use the asynchronous API. Pause is reapplied if requested while preparation was underway. The rate ramp and existing-player pause/resume logic remain unchanged. Playback start/resume/stop after successful preparation still use the main actor; this fix specifically addresses the observed preparation hang.

| Follow-up check | Result |
| --- | --- |
| Native release build | Passed. |
| App/core regression suite | 7 passed. |
| Shared suite without hardware opt-in | 9 passed, 1 hardware test skipped. New cases cover blocked preparation timeout and cancellation/late completion. |
| Shared suite with `SPEAK_AUDIO_TESTS=1` | 9 passed; the real muted playback test failed with the five-second output timeout. It no longer blocks the test/UI indefinitely. |
| Repaired companion, real synthesis request | Returned a readable output-timeout error; status and Stop continued responding. |
| Dictation command then cancellation | `preparing → idle`; disposable TextEdit contents unchanged by dictation. Recording/transcription were not reached, so this is preparation cancellation coverage only. |
| Global shortcut via automation | Not verified: the generated key sequence inserted a space in TextEdit instead of starting capture. This does not invalidate the earlier user-confirmed Notes shortcut result. |
| Browser insertion | Not run: the browser tool blocked the local test-page URL. No alternate browser route was attempted. |
| Built-in-speaker comparison | User authorized a temporary switch and restoration. Automated Sound controls did not complete the switch; read-only device inspection still showed Scarlett selected. Manual switch requested. |

The synthetic TextEdit edits were undone and that test document closed. No personal recording or transcript was committed. Speak was quit after the test to release the stalled audio connection. Full recording, browser/focus recovery, audible rate changes, passage continuity, and playback with windows closed remain open. Do not treat the earlier successful model/prototype measurements as a pass for today's hardware configuration.
