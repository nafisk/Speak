import { Clipboard, showToast, Toast } from "@raycast/api";
import { control } from "./control";
export default async function ReadClipboard() {
  try { const text = await Clipboard.readText(); if (!text?.trim()) throw new Error("Copy some text first."); await control("read", text); await showToast({ style: Toast.Style.Success, title: "Speech queued in Speak" }); }
  catch (e) { await showToast({ style: Toast.Style.Failure, title: "Speak", message: e instanceof Error ? e.message : "Could not read clipboard" }); }
}
