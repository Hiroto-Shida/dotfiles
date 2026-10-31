import { View, div } from "gpui-kit";
import { exec, focused, props, closeOverlay } from "herdr";

// Splits down, then swaps the new (focused) pane up.
export default class SplitUp extends View {
  init(_props, cx) {
    const pane = focused()?.pane;
    const overlay = props()?.overlay;
    cx.spawn(async (cx) => {
      try {
        if (pane) {
          await exec("herdr-app", ["do", "pane.split", "--direction", "down", "--pane", pane]);
          await exec("herdr-app", ["do", "pane.swap", "--direction", "up"]);
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
