# Prototype formatting and live speed controls

Implemented 2026-09-13 in the existing local prototypes. No dependencies or network behavior were added. [Usage](../prototypes/README.md).

## Behavior

STT `--format lists` converts complete lists with explicit spoken start/next/end cues to Markdown bullets. Default `plain` retains the existing behavior. `raw_text` is always available, while `text` is the selected format. Nested, empty, and incomplete lists are not transformed. These cues are reserved in list mode, including inside quoted speech; this parser does not interpret intent. Automatic natural-speech list inference is deferred pending the user's preference.

TTS interactive mode accepts rate commands while an utterance plays. Speed is limited to 0.5–2.0× and retained for subsequent utterances in the session. A 150 ms smoothstep ramp updates the current AVAudioPlayer rate without replacing the player, seeking, or regenerating speech. New speed requests cancel the previous ramp and start from the currently applied rate. Invalid speeds do not affect playback. `:stop` and `:quit` cancel the ramp and playback.

The implementation uses Apple's built-in [enableRate](https://developer.apple.com/documentation/avfaudio/avaudioplayer/enablerate) and [rate](https://developer.apple.com/documentation/avfaudio/avaudioplayer/rate) APIs; Apple documents pitch-preserving rate adjustment. No model-level resynthesis is involved in a live change. Saved WAVs remain at normal synthesis speed.

## Verification

- `SPEAK_AUDIO_TESTS=1 swift test -c release -j 4` passed all eight tests, including formatter behavior, malformed input preservation, Unicode, rate validation, and an actual muted AVAudioPlayer continuity test.
- The playback test changes rates repeatedly, checks `isPlaying`, detects backward position jumps larger than 5 ms, verifies continued net progress, and tests a new rate request during an unfinished ramp. AVAudioPlayer showed a 0.58 ms reporting jitter in the initial strict test; the 5 ms allowance accommodates this timestamp approximation while still rejecting a restart. This is not an acoustic dropout measurement.
- A synthetic 6.667 s recording went through Parakeet and list formatting with networking denied. It produced the expected three bullets. Total processing was 0.257 s on the first inference and 0.147 s on the second; formatting alone took 1.17 ms then 0.11 ms. These are spot checks, not a new benchmark distribution.
- Interactive Kokoro playback was exercised offline. Four commands (`:speed 1.5`, `:speed 0.7`, `:faster`, `:slower`) were handled while `playing` remained true, at increasing reported audio positions of 0.573, 1.414, 1.933, and 2.402 seconds. Stop and quit were also exercised.

The generated recording and raw transcript logs remain in ignored `prototypes/output/`. No personal microphone recording was captured. Subjective smoothness and formatting accuracy with the user's voice still need feedback. TTS input handling during synthesis remains serialized; live control responsiveness applies to active playback. Raycast controls and sliders have not been built yet.
