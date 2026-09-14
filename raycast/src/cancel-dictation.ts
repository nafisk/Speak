import { showToast, Toast } from "@raycast/api";
import { control } from "./control";
export default async function CancelDictation() {
  try { await control("cancelDictation"); await showToast({ style: Toast.Style.Success, title: "Dictation cancelled" }); }
  catch (e) { await showToast({ style: Toast.Style.Failure, title: "Speak", message: e instanceof Error ? e.message : "Command failed" }); }
}
