# Local model feasibility results

Measured 2026-09-13 on the development Mac: Apple M1 Pro, 16 GB unified memory, macOS 15.7.7, Swift 6.2.4. Runtime: FluidAudio 0.15.7, source revision `41540ea237350afe5117a082b5c28eda642d0612`. Release builds, four build jobs. [Run the prototypes](../prototypes/README.md).

## Finding

Both models run locally on this Mac and are fast enough to justify the next user trial. Warm Parakeet transcription was well below one second for the synthetic samples. Warm Kokoro synthesis was below one second for a short utterance. Startup and first inference are materially slower, particularly for Kokoro. Keep the runtime alive and warm it before presenting a ready state.

This is a feasibility result, not a production accuracy claim or a full user-interaction latency measurement. No Raycast interface, focused-field insertion, or global hotkeys have been built.

## Warm measurements

Each row uses one first inference followed by 20 timed warm repetitions of the same input. Median and p95 use nearest rank. The three benchmark batches ran separately. Desktop workload was not otherwise controlled; this is not a varied speech corpus.

| Prototype | Audio duration | Warm median | Warm p95 | What the timer includes |
| --- | --- | --- | --- | --- |
| Parakeet v3, short recording | 9.625 s | 0.162 s | 0.173 s | Decode from prepared 16 kHz samples; transcript returned |
| Parakeet v3, paragraph | 25.167 s | 0.273 s | 0.307 s | Decode from prepared 16 kHz samples; transcript returned |
| Kokoro English `af_heart` | 3.250 s generated | 0.233 s | 0.323 s | Text/phonemization through complete WAV generation |

STT file preparation happens before the benchmark loop. TTS benchmark timings exclude playback and saving the WAV. Faster-than-audio processing does not imply zero delay or live streaming. Mic stop-to-transcript and audible-onset latency require separate measurements.

The STT inputs were generated with macOS `say -v Samantha`: a short three-sentence sample and a paragraph at 155 words/minute. The paragraph output matched its reference under case/punctuation normalization. The short sample normalized the spoken time into digits and changed a sentence boundary; do not interpret this as perfect formatting. These two synthetic samples do not test the user's accent, natural pauses, microphone noise, or technical vocabulary.

## Startup cost and memory

| Measurement | Parakeet | Kokoro |
| --- | --- | --- |
| Initial setup, including first download | 60.8 s | 76.9 s |
| First-ever inference observed | 0.194 s | 7.024 s |
| Cached fresh-process model initialization | 0.246 s | 2.623 s |
| First inference in cached benchmark process | 0.202 s | 2.022 s |
| Peak process RSS reported by `/usr/bin/time -l` | 87.1 MiB | 1005.7 MiB |

Initial downloads overlapped; those first-setup values describe the observed installation experience, not isolated download benchmarks. Cached fresh-process values came from the separate 21-trial batches. Core ML can allocate memory in services outside the measured process, so RSS is not the total system/model memory footprint. Measured cache sizes were approximately 469 MiB for Parakeet and 103 MiB for Kokoro/pronunciation assets, excluding build and Core ML system caches.

Kokoro's cached fresh-process load plus first synthesis was approximately **4.6 seconds**. Starting a fresh model process for every hotkey would undermine the desired responsiveness. Interactive TTS does a discarded warm-up utterance and then accepts more text in the same process. Different utterance lengths can still incur additional work.

## Verification completed

1. Release build succeeded. `swift test -c release -j 4` passed three tests covering percentile calculations, invalid CLI options, and invalid/silent/non-finite audio. Eight command-line failure cases rejected invalid input before model setup. Shell syntax, help output, microphone Info.plist validation, and local documentation links passed.
2. Parakeet completed both 21-trial file benchmarks. Kokoro completed its 21-trial synthesis benchmark.
3. Generated WAV inspection confirmed mono 24 kHz / 16-bit PCM, 78,000 samples, nonzero energy, and no clipped samples. An offline Parakeet round trip recovered the expected words from the Kokoro sample. Human voice-quality evaluation remains open.
4. Both executables succeeded under a child sandbox with `(deny network*)` after setup. STT processed the generated WAV; TTS synthesized a new sentence. This verifies those cached execution paths, not all possible recovery/download paths.
5. Interactive TTS was exercised under the same network-denying sandbox with different typed sentences and actual AVAudioPlayer playback. After a 6.17 s startup/warm-up, two new sentences synthesized in 0.379 s and 0.506 s; playback was scheduled at 0.538 s and 0.539 s respectively. These are two spot checks, not percentiles. Physical audible onset has not been instrumented.

## Reproduce

From the repository root, after building:

```sh
mkdir -p prototypes/output
say -v Samantha -o prototypes/output/reference.aiff 'The quick brown fox jumps over the lazy dog. Please schedule the project meeting for tomorrow morning at ten thirty. I would like to test local speech recognition on this computer.'
./prototypes/stt.sh --file prototypes/output/reference.aiff --repeat 21
./prototypes/tts.sh --text 'Hello. This is Speak running locally on your Mac.' --output prototypes/output/new-benchmark.wav --repeat 21
```

Use a new output filename for each TTS command. For a cached offline check, prefix a command with:

```sh
/usr/bin/sandbox-exec -p '(version 1) (allow default) (deny network*)'
```

`sandbox-exec` is a local verification tool here, not an app distribution dependency. Raw test logs/audio are in the ignored `prototypes/output/` directory and are not committed. No personal recordings were used.

## Remaining work before Raycast

- Run `./prototypes/stt.sh --mic` and evaluate the user's real voice. Microphone permissions and capture behavior are implemented but have not been exercised in this session.
- Compare new sentences and real dictation, rather than only repeated synthetic input. Choose an acceptable accuracy threshold from these trials.
- Prove target-field insertion, warm companion lifetime, cancellation, and a truthful ready/recording indicator.
- Decide whether sentence-based TTS playback is sufficient; current Kokoro trials generate a complete short utterance before playback. No live partial STT or long-text TTS queue is implemented.
- Pin downloaded model assets and handle interrupted setup before distribution. Source dependencies are locked; the upstream runtime currently resolves model assets from mutable URLs.

Repository visibility is public at the user's request. Packaged releases and Speak's source license remain separate future decisions.
