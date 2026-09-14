import { Action, ActionPanel, Form, showToast, Toast } from "@raycast/api";
import { useEffect, useState } from "react";
import { control, Status } from "./control";

export default function ReadText() {
  const [text, setText] = useState("");
  const [status, setStatus] = useState<Status>();
  const [error, setError] = useState<string>();
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    let live = true, pending = false;
    async function refresh() {
      if (pending) return; pending = true;
      try { const next = await control("status"); if (live) { setStatus(next); setError(undefined); } }
      catch (e) { if (live) setError(e instanceof Error ? e.message : "Open Speak first."); }
      finally { pending = false; }
    }
    void refresh(); const timer = setInterval(refresh, 1000);
    return () => { live = false; clearInterval(timer); };
  }, []);
  async function act(operation: () => Promise<Status>) {
    if (busy) return; setBusy(true);
    try { setStatus(await operation()); setError(undefined); }
    catch (e) { await showToast({ style: Toast.Style.Failure, title: "Speak", message: e instanceof Error ? e.message : "Command failed" }); }
    finally { setBusy(false); }
  }
  const playing = status?.reading ?? false;
  return <Form navigationTitle="Speak · Read Text" isLoading={busy} actions={<ActionPanel>
    {playing ? <Action title={status?.paused ? "Resume" : "Pause"} onAction={() => act(() => control(status?.paused ? "resume" : "pause"))} />
      : <Action.SubmitForm title="Listen" onSubmit={() => act(() => control("read", text))} />}
    <Action title="Stop Speaking" shortcut={{ modifiers: ["cmd"], key: "." }} onAction={() => act(() => control("stop"))} />
    <Action title="Faster" shortcut={{ modifiers: ["cmd"], key: "]" }} onAction={() => act(() => control("speed", undefined, Math.min(2, (status?.speed ?? 1) + 0.1)))} />
    <Action title="Slower" shortcut={{ modifiers: ["cmd"], key: "[" }} onAction={() => act(() => control("speed", undefined, Math.max(0.5, (status?.speed ?? 1) - 0.1)))} />
    <Action title="Open Speak" onAction={() => act(() => control("open"))} />
  </ActionPanel>}>
    <Form.TextArea id="text" title="Text" placeholder="Paste text to read aloud…" value={text} onChange={setText} error={text.length > 20000 ? "Maximum 20,000 characters" : undefined} />
    <Form.Dropdown id="speed" title="Speed" value={(status?.speed ?? 1).toFixed(1)} onChange={(value) => { if (Math.abs(Number(value) - (status?.speed ?? 1)) > 0.001) void act(() => control("speed", undefined, Number(value))); }}>
      {Array.from({ length: 16 }, (_, i) => (0.5 + i / 10).toFixed(1)).map((value) => <Form.Dropdown.Item key={value} value={value} title={`${value}×`} />)}
    </Form.Dropdown>
    <Form.Description title="Status" text={error ?? status?.message ?? "Connecting to Speak…"} />
    <Form.Description title="Voice" text="Heart · English · On your Mac" />
  </Form>;
}
