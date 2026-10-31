import { View, div } from "gpui-kit";
import { exec, focused, props, closeOverlay, appHome } from "herdr";

export default class ResizeDown extends View {
  init(_p, cx) {
    const pane = focused()?.pane;
    const overlay = props()?.overlay;
    cx.spawn(async (cx) => {
      try {
        if (pane) await exec("python3", [`${appHome()}/bin/pane-resize.py`, pane, "down"]);
      } finally {
        if (overlay) closeOverlay(overlay);
      }
    });
  }
  render() { return div(); }
}
