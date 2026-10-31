import { View, div } from "gpui-kit";
import { exec, focused, props, closeOverlay } from "herdr";

// Splits right, then swaps the new (focused) pane to the left.
export default class SplitLeft extends View {
  init(_props, cx) {
    const pane = focused()?.pane;
    const overlay = props()?.overlay;
    cx.spawn(async (cx) => {
      try {
        if (pane) {
          await exec("herdr-app", ["do", "pane.split", "--direction", "right", "--pane", pane]);
          await exec("herdr-app", ["do", "pane.swap", "--direction", "left"]);
        }
      } finally {
        if (overlay) closeOverlay(overlay);
      }
    });
  }

  render() {
    return div();
  }
}
