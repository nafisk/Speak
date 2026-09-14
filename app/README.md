# Speak Mac companion

Swift/SwiftUI menu-bar app; Parakeet v3 dictation and Kokoro Heart speech run locally through the existing pinned FluidAudio runtime. Development requires Apple silicon, macOS 14+, and Swift 6.2 / the macOS 26 SDK. The current device check uses macOS 15.7.7.

## Build and run

From the repository root:

```sh
app/build.sh
open app/build/Speak.app
```

Quit the running app before rebuilding and reopen afterwards. This is an ad-hoc signed development bundle, not a notarized release; a rebuild may require renewing its macOS permissions. Build outputs and model assets stay out of Git.

Provision models using the [prototype setup](../prototypes/README.md) first. The app loads the cached Parakeet model on launch. First TTS use initializes Kokoro and may download missing assets; later inference is local. Offline operation still needs a disconnected-device check.

## Use

- Open Settings once to enable microphone and text insertion (macOS Accessibility).
- In a text field, press Control–Option–Space, speak, then press it again. Escape cancels. Settings also offers Control–Shift–Space.
- The nonactivating waveform shows input levels. Recording is capped at 120 seconds. The main window can remain closed.
- Text inserts only if the original application, focused field, contents, and selection still match. Unsupported or changed fields show recovery with an explicit Copy action. Password fields are excluded.
- In the reader, enter up to 20,000 characters and choose Listen. Pause/resume and the 0.5–2× speed slider control the current audio. Audio preparation has a five-second timeout; if an output device stalls, Speak reports an error and keeps its controls responsive. Check the output device before retrying; a still-blocked device call prevents additional preparations until it returns or Speak restarts. Longer text is split into bounded passages; one passage is prepared ahead. Closing the window leaves the menu-bar app running. Quit Speak stops it.

Settings include explicit spoken list cues, two shortcut presets, speed memory, appearance, model readiness, and permission actions. List cues preserve wording and use “start a list”, “next item”, and “end list”; semantic list detection is not implemented.

Audio uses a private temporary directory and is removed after processing/cancellation. Unexpected process termination can leave a temporary recording behind; crash cleanup is a remaining validation item. Latest text stays in memory until the next dictation, cancellation, or quitting. No history is persisted. Automatic insertion does not replace the clipboard; Copy does so intentionally.

## Local controller

```sh
app/.build/release/speakctl status
printf '%s' 'A short local speech example.' | app/.build/release/speakctl read
app/.build/release/speakctl speed 1.5
app/.build/release/speakctl pause
app/.build/release/speakctl resume
app/.build/release/speakctl stop
```

Commands also include `open`, `toggleDictation`, and `cancelDictation`. The controller requires the running companion. Transport uses newline-framed JSON over `~/Library/Application Support/Speak/control.sock`: directory mode 700, socket mode 600, and same-user peer validation. Text is passed literally through stdin, never interpreted as shell syntax. Status replies exclude transcripts. There is no HTTP server or remote endpoint.

## Verification

```sh
swift test --package-path app -c release -j 4
SPEAK_AUDIO_TESTS=1 swift test --package-path prototypes -c release -j 4
```

See [implementation tracker](../docs/implementation-plan.md) and [native results](../docs/native-mvp-results.md) for evidence and remaining device checks.
