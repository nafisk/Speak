# Speak for Raycast

A development extension controlling the [Speak companion](../app/README.md). Speech continues in the companion independently of the Raycast window.

## Develop

Build and open the companion first. From the repository root:

```sh
npm ci --prefix raycast --ignore-scripts
npm run dev --prefix raycast
```

Run **Speak → Read Text** in Raycast. Set **Speak Control Path** to the absolute path of `app/.build/release/speakctl` in your checkout. On the current development Mac this is `/Users/nafiskhan/Developer/Speak/app/.build/release/speakctl`. Press Command–Return to save the setup form.

Read Text provides a text box, shared playback status, a live speed selector, and actions for Listen, Pause/Resume, Stop, Faster, Slower, and Open Speak. Read Clipboard, Stop Speaking, and Cancel Dictation also run as standalone commands. Configure aliases/hotkeys in Raycast's extension preferences.

Use the companion's global Control–Option–Space shortcut to start/stop dictation directly in your target field. The extension intentionally does not start dictation while Raycast owns keyboard focus.

## Verify

```sh
npm run typecheck --prefix raycast
npm run build --prefix raycast
npm audit --prefix raycast
```

The official SDK is pinned at 2.3.1. Its optional React debugger is omitted; it is not needed to run the extension. The lockfile is committed. The extension is installed locally for development, not published to the Raycast Store. See [native results](../docs/native-mvp-results.md) for actual device coverage.
