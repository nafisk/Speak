# Speak MVP plan

Date: 2026-09-13 (America/New_York)
Phase: model feasibility prototypes implemented; Raycast application implementation has not started. See [measured results](feasibility-results.md).

## Confirmed intent

1. Build in `/Users/nafiskhan/Developer/Speak`, with Git and the public `nafisk/Speak` GitHub repository (visibility changed at the user's request).
2. Make Raycast the primary interface for both local dictation and reading text aloud.
3. Support English first.
4. Press the dictation shortcut once to start and again to stop.
5. Preserve spoken wording, adding punctuation and capitalization. Do not intentionally rewrite, remove fillers, or summarize.

## Proposed MVP experience

| Command | Behavior |
| --- | --- |
| Toggle Dictation | Start microphone capture and show recording status. Second invocation stops capture, transcribes locally, and inserts text into the intended focused field. |
| Read Text | Open a multiline Raycast form; paste or type text and start playback. |
| Read Clipboard | Read copied text directly, avoiding the form when desired. |
| Stop Speaking | Stop playback and discard queued synthesis. |
| Cancel Dictation | Stop recording/processing without inserting text. |

Assign Raycast aliases and global hotkeys after checking conflicts. An alias requires opening Raycast; a hotkey launches the command directly. Exact key combinations remain user-configurable.

Proposed defaults: one English voice, adjustable reading speed, no saved transcript history, microphone capture only after explicit command invocation. The user requested speed changes during speech without restarting; the prototype now supports a 0.5–2.0× playback rate with a short ramp. Retain the latest uninserted result in memory for manual copy if insertion fails. Do not send Enter or submit messages after pasting.

Scope exclusions: voice cloning, cloud inference, translation, meeting transcription, diarization, prose rewriting, account systems, Alfred implementation, and standalone application UI beyond the minimal companion/status controls.

## Proposed architecture

```text
Raycast extension (TypeScript + React)
  commands, text form, preferences, status
               |
       local control interface
               |
Speak companion (Swift app + small control CLI)
  microphone, model lifecycle, playback, recording status
               |
  Parakeet STT                 Kokoro TTS
       via a pinned, evaluated local Swift runtime
```

Recommendation: evaluate FluidAudio first because it supports both model families in Swift/Core ML. Benchmark a Parakeet TDT 0.6B variant (v3 first; v2 English comparison only if useful) and Kokoro 82M. Keep WhisperKit as the transcription fallback if Parakeet struggles with the user's accent, vocabulary, or hardware. See [research and sources](research.md).

Keep the companion running while Speak is active so commands do not reload weights each time. Measure memory with both models loaded; permit idle unloading if necessary. Recording and playback must survive closing Raycast. Serialize dictation sessions and cancel stale results so repeated shortcuts cannot cause duplicate inserts. Stop speech playback when recording starts to avoid transcribing Speak's own audio.

Prefer local IPC, such as a user-restricted Unix socket behind a small CLI, over an HTTP listener. Final transport and paste ownership are feasibility decisions. Pass text through structured input/stdin, never interpolate dictated text into shell code. Keep implementation and build outputs in Speak; normal macOS installation and model-cache destinations should be documented when introduced.

Insertion needs an early experiment: capture the intended application before Raycast takes focus, restore it appropriately, and insert once. Raycast's Clipboard.paste is the first API to evaluate. If delayed completion requires the companion to own insertion, validate the Accessibility permission and focus behavior there. If the target changes or cannot be safely restored, offer manual copy instead of guessing. Clipboard restoration must not overwrite content the user copied during processing.

Use model-produced punctuation/capitalization plus conservative whitespace cleanup. The user also requested list formatting. The prototype provides opt-in spoken list cues (`start a list`, `next item`, `end list`) and retains raw recognition output. Automatic list inference from natural speech remains undecided. No third generative model is planned. Recognition errors remain possible; preserving wording is a product intent, not a claim of perfect transcription.

## Delivery sequence

Estimates are provisional engineering effort, not a delivery promise; re-estimate after milestone 1.

| Milestone | Deliverable and verification | Rough effort |
| --- | --- | --- |
| 1. Feasibility | Verify compatible pinned runtime/toolchain; benchmark STT/TTS; prove microphone permission, two-invocation recording, Raycast dismissal, and target-field insertion. Record failures and measurements. | 1–2 days |
| 2. Dictation | Complete toggle/cancel/status flow; test rapid repeated shortcuts, silence, denied permission, focus changes, app exit, and manual-copy fallback. | 1–2 days |
| 3. Read aloud | Form and clipboard inputs; one English voice; speed and stop controls; sentence-by-sentence audio queue. Check long text and playback while Raycast closes. | 1–2 days |
| 4. Daily-use pass | Model setup/recovery, companion restart, offline checks, memory/latency measurements, and tests across browser text fields, Notes, and Codex. | 1–2 days |

Public distribution is a later milestone: signing/notarization for the companion, model notices, install/update flow, Raycast Store submission and review. Store acceptance is not assumed.

## Acceptance and benchmark plan

These are proposed targets, not measured results. Baseline hardware: M1 Pro, 16 GB RAM, macOS 15.7.7.

| Area | Proposed acceptance check |
| --- | --- |
| Recording responsiveness | Warm shortcut-to-recording readiness p95 at or below 300 ms; visible state must accurately indicate whether audio is being captured. Measure first launch separately. |
| Dictation speed | Warm stop-to-insert p95 at or below 2 seconds for 10–30 second utterances. Include decoding, formatting, focus restoration, and paste. Report 60 second utterances separately. |
| Reading speed | Warm submit-to-first-audible-audio p95 at or below 1 second for a short first sentence. Chunk long passages; Kokoro sentence chunking is not true model streaming. |
| Correctness | Evaluate at least 20 English utterances with reference transcripts, including names, numbers, technical terms, pauses, and background noise; report normalized WER separately from punctuation and perceived usefulness. Agree an accuracy threshold after baseline. |
| Reliability/privacy | No duplicate inserts, no insertion on cancel/silence, clear permission errors, successful reading and dictation with networking disabled after setup, no transcript/audio contents in logs or Git. |

For each latency case, run at least 20 warm trials, report median/p95, and record cold load separately. Measure peak resident memory and resource use after returning to idle. Model/runtime versions, configuration, and sample descriptions belong in a benchmark report; personal recordings do not belong in Git.

## Decisions still open

- Final model/runtime versions depend on measured speed, accuracy, voice quality, and build compatibility.
- Exact hotkeys and the default English voice can be selected during the working demo.
- Source is public. Packaged public release, pricing, and the project's open-source license are deferred.

The user authorized two feasibility scripts. FluidAudio 0.15.7 and Parakeet/Kokoro assets have been installed and exercised locally. Next: verify personal microphone accuracy and refine warm-up behavior before implementing the Raycast integration. The original discovery-only setup statements in the research notes are historical.
