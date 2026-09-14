import { showToast, Toast } from "@raycast/api";
import { control } from "./control";

export default async function OpenDictation() {
  try {
    await control("open");
    await showToast({ style: Toast.Style.Success, title: "Speak dictation", message: "Use your dictation shortcut in the text field you want to write into." });
  } catch (e) {
    await showToast({ style: Toast.Style.Failure, title: "Speak", message: e instanceof Error ? e.message : "Command failed" });
  }
}
