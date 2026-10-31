import { View, div } from "gpui-kit";
import { exec, focused, nextCommand } from "herdr";

// Key commands ("pane-ops.<command>" in keys.json): resize-<dir>, split-left, split-up.
const STEP = 0.05;
const MIN = 0.08;

async function rpc(method, params) {
  const req = JSON.stringify({ jsonrpc: "2.0", id: 1, method, params });
  const r = await exec("sh", ["-c", 'printf "%s\\n" "$1" | hc connect', "_", req]);
  return JSON.parse(r.stdout.split("\n")[0]);
}

function pathTo(node, id) {
  if (node.id === id) return [node];
  for (const c of node.children ?? []) {
    const p = pathTo(c, id);
    if (p) return [node, ...p];
  }
  return null;
}

function normalized(kids) {
  const ws = kids.map((k) => k.size?.weight);
  const known = ws.filter((w) => w != null);
  const fill = known.length ? known.reduce((a, b) => a + b, 0) / known.length : 1;
  const all = ws.map((w) => w ?? fill);
  const total = all.reduce((a, b) => a + b, 0);
  return all.map((w) => w / total);
}

// Moves the pane's edge toward `dir`; with no neighbour that way, the opposite edge moves.
function resizeTree(root, pane, dir) {
  const path = pathTo(root, pane);
  if (!path) return false;
  const want = dir === "left" || dir === "right" ? "row" : "column";
  const forward = dir === "right" || dir === "down";
  for (let d = path.length - 2; d >= 0; d--) {
    const parent = path[d];
    const kids = parent.children;
    if (parent.type !== want || kids.length < 2) continue;
    const i = kids.indexOf(path[d + 1]);
    const ws = normalized(kids);
    // The boundary between siblings a and b moves: forward grows a, backward grows b.
    let a, b;
    if (forward) [a, b] = i + 1 < kids.length ? [i, i + 1] : [i - 1, i];
    else [a, b] = i > 0 ? [i - 1, i] : [i, i + 1];
    const [grow, shrink] = forward ? [a, b] : [b, a];
    const delta = Math.min(STEP, ws[shrink] - MIN);
    if (delta <= 0) return false;
    ws[grow] += delta;
    ws[shrink] -= delta;
    kids.forEach((k, n) => (k.size = { weight: ws[n] }));
    return true;
  }
  return false;
}

async function resize(dir) {
  const pane = focused()?.pane;
  if (!pane) return;
  const got = (await rpc("doc.get", { name: "herdr-app" })).result;
  const doc = got.value;
  const changed = doc.spaces.some((s) => s.tabs.some((t) => pathTo(t.root, pane) && resizeTree(t.root, pane, dir)));
  if (changed) await rpc("doc.set", { name: "herdr-app", value: doc, version: got.version });
}

async function splitThenSwap(dir, swap) {
  const pane = focused()?.pane;
  if (!pane) return;
  await exec("herdr-app", ["do", "pane.split", "--direction", dir, "--pane", pane]);
  await exec("herdr-app", ["do", "pane.swap", "--direction", swap]);
}

export default class PaneOps extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const cmd = await nextCommand();
        try {
          if (cmd.startsWith("resize-")) await resize(cmd.slice(7));
          else if (cmd === "split-left") await splitThenSwap("right", "left");
          else if (cmd === "split-up") await splitThenSwap("down", "up");
        } catch (e) {
          console.log("pane-ops:", cmd, String(e));
        }
      }
    });
  }

  render() {
    return div();
  }
}
