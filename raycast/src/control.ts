import { getPreferenceValues } from "@raycast/api";
import { spawn } from "node:child_process";
import { isAbsolute } from "node:path";

export type Status = { ok: boolean; message: string; reading: boolean; paused: boolean; speed: number; dictation: string };
export type Command = "status" | "read" | "pause" | "resume" | "stop" | "speed" | "cancelDictation" | "open";
export function control(command: Command, text?: string, speed?: number): Promise<Status> {
  const path = getPreferenceValues<{ controlPath: string }>().controlPath;
  if (!isAbsolute(path)) return Promise.reject(new Error("Set an absolute Speak Control Path in extension preferences."));
  if (command === "speed" && (speed === undefined || !Number.isFinite(speed) || speed < 0.5 || speed > 2)) return Promise.reject(new Error("Speed must be 0.5–2.0."));
  return new Promise((resolve, reject) => {
    // Literal argv and stdin only: user text is never interpreted as shell code.
    const child = spawn(path, command === "speed" ? [command, String(speed)] : [command], { shell: false, stdio: ["pipe", "pipe", "pipe"] });
    let stdout = "", stderr = "", settled = false;
    const timeout = setTimeout(() => { child.kill(); finish(new Error("Speak did not respond. Open the companion and retry.")); }, 5000);
    function finish(error?: Error, result?: Status) {
      if (settled) return; settled = true; clearTimeout(timeout);
      if (error) reject(error); else resolve(result!);
    }
    child.on("error", (error) => finish(error));
    child.stdin.on("error", () => { /* A failed launch/closed pipe is reported by error or close. */ });
    child.stdout.on("data", (data: Buffer) => { stdout += data.toString(); if (stdout.length > 16384) { child.kill(); finish(new Error("Invalid control response.")); } });
    child.stderr.on("data", (data: Buffer) => { stderr = (stderr + data.toString()).slice(0, 4096); });
    child.on("close", (code) => {
      try {
        if (code !== 0) {
          let message = stderr.trim();
          if (!message) { try { message = (JSON.parse(stdout) as Status).message; } catch { /* no response */ } }
          throw new Error(message || "Open Speak first, then retry.");
        }
        const result = JSON.parse(stdout) as Status;
        if (typeof result.ok !== "boolean" || typeof result.reading !== "boolean" || typeof result.paused !== "boolean" || typeof result.speed !== "number" || typeof result.message !== "string") throw new Error("Invalid control response.");
        if (!result.ok) throw new Error(result.message);
        finish(undefined, result);
      } catch (error) { finish(error instanceof Error ? error : new Error("Invalid control response.")); }
    });
    child.stdin.end(command === "read" ? text ?? "" : undefined);
  });
}
