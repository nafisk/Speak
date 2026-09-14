import { showToast, Toast } from "@raycast/api";
import { control } from "./control";
export default async function StopSpeaking() {
  try { await control("stop"); await showToast({ style: Toast.Style.Success, title: "Speech stopped" }); }
  catch (e) { await showToast({ style: Toast.Style.Failure, title: "Speak", message: e instanceof Error ? e.message : "Command failed" }); }
}
