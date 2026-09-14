# Speak implementation tracker

Updated: 2026-09-13. Selected direction: **Pearl & Tide**. The user authorized executing this regular plan; work stays in this repository.

`[x]` implemented with the stated verification · `[-]` implemented, device validation incomplete · `[ ]` pending. A milestone remains open until its device acceptance checks pass. Evidence: [native MVP results](native-mvp-results.md).

## 1. Native dictation — implemented; device validation underway

- [x] Build a launchable Swift/SwiftUI menu-bar companion using the pinned local runtime.
- [x] Global toggle shortcut, microphone permission flow, microphone-driven waveform, local transcription, conservative formatting, and guarded insertion. **User confirmed text inserted correctly into Notes.**
- [x] Verify session cancellation, stale-result rejection, one insertion per session, and UTF-16 selection handling with automated tests.
- [-] Manual-copy recovery for changed/unsupported fields; two shortcut presets; interruptible transitions and Reduce Motion support. Implemented; remaining device cases below.
- [ ] Check browser insertion, silence, changed focus/selection, repeated shortcuts, Escape during processing, denied permission, and main-window-closed dictation. Measure complete shortcut-to-capture and stop-to-insert latency.

## 2. Compact reader and settings — implemented; live validation pending

- [x] Build the 440 pt reader, settings, cached Kokoro synthesis, and bounded long-text passages with one passage prepared ahead.
- [x] Pause/resume, stop, and smooth 0.5–2× rate changes on the existing player. Muted synthetic playback test verifies continuity and paused position.
- [-] Settings for shortcut, list cues, speed memory, appearance, model readiness, and permissions. Initial user permission setup succeeded; remaining settings/appearance checks pending.
- [ ] Verify real voice playback, passage boundaries, cancellation during synthesis, and reading with the window closed.

## 3. Raycast control layer — built and installed locally; playback check pending

- [x] Add `speakctl` and a same-user Unix socket. Test structured text round-trip, invalid inputs, mode 600, and refusal to overwrite unexpected files.
- [x] Build Read Text, Read Clipboard, Stop Speaking, and Cancel Dictation. Reader actions include pause/resume, speed, and Open Speak. Native shortcut owns dictation start/stop.
- [x] TypeScript check and Raycast build pass. Extension installed in local development mode; Read Text form opens and its controller path is configured. Dependency audit reports zero advisories after omitting the optional debugger.
- [ ] Verify real shared playback and window dismissal after restarting the updated companion. The older running build does not expose the new control endpoint; app automation timed out when trying to reopen it.

## 4. Daily-use validation — next

- [ ] Exercise representative English dictation and score accuracy with user consent; keep personal samples out of Git.
- [ ] Measure warm/cold end-to-end latency, memory with both models loaded, and idle resource use after the rendering fix.
- [ ] Verify offline use after model setup, microphone disconnection, startup/shutdown, and recovery after unexpected exit. Harden temporary-recording crash cleanup.
- [ ] Review accessibility, Reduce Motion/Transparency, settings layout, macOS 15 materials, and macOS 26 Liquid Glass on supported hardware.

## 5. Public distribution — later

- [ ] Decide source license and model notices; prepare signing/notarization, install/update flow, and Raycast Store publication.
- [ ] Add Alfred after native/Raycast daily-use acceptance.

## Current checkpoint

Native and Raycast implementation is reviewable and builds. Fifteen automated tests pass (seven app/core, eight shared prototype). Notes insertion is user-confirmed. Raycast opens its native reader form. The immediate next check is restarting the rebuilt companion and exercising one real TTS passage, pause/resume, and live rate changes from Raycast. Device checks above remain open; model-only benchmarks do not establish full-app latency.
