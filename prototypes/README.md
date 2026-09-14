# Local speech prototypes

Two scripts exercise real local models on macOS. These are feasibility tools, not the Raycast app.

## Build once

Requires Apple Silicon, macOS 14+, and the Xcode Swift 6.2 toolchain. Verified on M1 Pro / macOS 15.7.7 / Swift 6.2.4. From the Speak repository:

```sh
cd prototypes
swift build -c release -j 4
swift test -c release -j 4
cd ..
```

The scripts execute the last release build; rebuild after changing Swift files. FluidAudio is pinned to 0.15.7 and its exact source revision is in `Package.resolved`. No Python environment or cloud API key is needed.

## Try speech-to-text

```sh
./prototypes/stt.sh --mic
```

Wait for model setup and grant macOS microphone access to the terminal if requested. Press Enter to start, speak, and press Enter again to stop. The transcript appears in the terminal. Repeat without reloading the model; type `q` between trials to exit. Recording is limited to 120 seconds; after the limit, press Enter to process it.

This captures the default microphone and transcribes after stopping. It does not show partial transcripts, bind a global hotkey, or paste into another app. In default `plain` mode, wording and punctuation come directly from Parakeet; no LLM rewrite is applied. Names, punctuation, and number formatting still need personal evaluation. Microphone setup/recording has not been tested with the user's voice.

### Spoken bullet lists

```sh
./prototypes/stt.sh --mic --format lists
```

Say **“Start a list. Buy apples. Next item. Buy bananas. End list.”** The `text` field becomes Markdown bullets:

```text
- Buy apples.
- Buy bananas.
```

Capitalization/punctuation within each item still comes from the recognizer. `raw_text` always contains the unformatted recognition result. These three cue phrases are reserved commands when list mode is enabled, even if quoted; use `--format plain` to dictate them literally. Lists need an end cue. Empty, incomplete, or nested lists are left unchanged. Prose outside a valid list is retained, with blank lines around the bullets.

This is deterministic formatting with no extra model or network call. It does not infer bullet lists from ordinary prose or rewrite what you meant. File benchmarks accept `--format lists` too; `formatting_seconds` reports its cost separately, while total processing time includes formatting.

Or benchmark a file, using an absolute path or one relative to your current directory:

```sh
./prototypes/stt.sh --file /absolute/path/to/recording.wav --repeat 21
```

Use 0.25–120 seconds of audible audio. File decoding/resampling happens before the timed inference loop. Microphone trial timing starts at stop, including recorder finalization and resampling. Neither timing includes insertion into another application. The `recording_started` timing measures the recording API call, not a physical microphone latency measurement.

## Try text-to-speech

```sh
./prototypes/tts.sh --interactive
```

After setup and one discarded warm-up sentence, type a short sentence and press Enter. Kokoro reads it aloud. Audio stays in memory. You can enter these controls **while it is speaking**:

| Command | Effect |
| --- | --- |
| `:speed 1.5` | Change to 1.5× speed; valid range 0.5–2.0× |
| `:faster` / `:slower` | Increase/decrease by 0.1× |
| `:stop` | Stop the current utterance |
| `:quit` | Stop playback and exit |

Each command takes effect after Enter. Speed changes ease over roughly 150 ms on the same player, without seeking, restarting, or resynthesizing the audio. macOS rate adjustment preserves pitch. The selected speed persists for subsequent sentences within this session. An invalid speed leaves playback unchanged. Enter new text after playback finishes, or use `:stop` first. Starting another sentence does not interrupt the previous one automatically.

Set an initial rate with `./prototypes/tts.sh --interactive --speed 1.25`. Changes during synthesis are handled when synthesis returns; changes during playback are handled immediately. The terminal control ramp is not a sample-accurate guarantee against every audible artifact; voice quality at different rates still needs listening feedback.

To save a WAV or benchmark one phrase:

```sh
mkdir -p prototypes/output
./prototypes/tts.sh --text 'Hello. This is Speak running locally on your Mac.' \
  --output prototypes/output/my-first-test.wav --play
./prototypes/tts.sh --text 'A short sentence for testing.' \
  --output prototypes/output/my-benchmark.wav --repeat 21
```

Output files must not already exist. The first trial's WAV is saved; later trials measure the same phrase without saving copies. `--play` plays every trial, so omit it for timing batches. `--speed 1.25` also sets the initial playback rate with `--play`; live terminal commands are available in interactive mode only. Saved WAVs retain the model's normal speed. Text can also be piped into stdin when `--text` is omitted. The prototype uses English `af_heart` and a 300-character input limit. It generates the whole short utterance before playback; it does not yet queue or stream long documents.

## Read timings correctly

Both tools emit JSON lines to stdout and status to stderr. `model_ready` reports initialization, including downloads if needed. `first_inference` is separate from subsequent `warm` trials. `--repeat 21` produces one first inference and 20 warm samples; the summary uses nearest-rank median and p95.

`realtime_factor` is processing seconds divided by audio seconds; below 1 means faster than the audio duration. It is not the delay of a complete user interaction. `playback_scheduled_seconds` ends when AVAudioPlayer accepts playback, not when a microphone detects sound. New text/sequence lengths and competing applications can change latency even with a warm model. See [measured results](../docs/feasibility-results.md).

## Downloads and local data

First runs download public model assets using FluidAudio into its normal cache locations:

- STT: `~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3/`
- TTS and pronunciation assets: `~/.cache/fluidaudio/`

All Speak source stays in this repository. The runtime's caches and macOS Core ML compilation caches are data, not additional development projects. Model downloads follow the runtime's upstream `main` asset URLs; weights are not revision-pinned by these scripts. The Swift dependency is pinned. Do not treat these prototypes as a reproducible release installer yet.

The optional NeMo text-normalization trait is disabled to keep the runtime path minimal; number/abbreviation pronunciation is a known evaluation gap. SwiftPM nevertheless fetched the upstream checksum-verified NeMo binary archive while resolving the package. It is not enabled in the prototype targets.

Microphone mode uses a temporary WAV and deletes it after each completed/error-handled trial. Abrupt termination can leave that temporary file behind. Transcripts are printed to stdout, so terminal scrollback or redirected output can retain them. The scripts do not send speech/text to a cloud service. Release-mode runtime diagnostics may still use macOS Unified Logging; no promise of zero OS-level diagnostic retention is made.

`prototypes/output/`, audio files, model weights, and build products are ignored by Git. Initial tests used synthetic speech only. Use personal recordings locally, and do not commit them. Public source visibility does not itself assign an open-source license to Speak; license selection is still pending.
