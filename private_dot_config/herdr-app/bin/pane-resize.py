#!/usr/bin/env python3
"""pane-resize.py <pane-id> <left|right|up|down> [amount]

Moves the focused pane's edge in the given direction by editing the split
weights in herdr-core's "herdr-app" document (the app follows it live).
If the pane has no neighbour that way, the opposite edge moves instead.
"""
import json
import subprocess
import sys

pane, direction = sys.argv[1], sys.argv[2]
amount = float(sys.argv[3]) if len(sys.argv) > 3 else 0.05
horizontal = direction in ("left", "right")
want = "row" if horizontal else "column"
forward = direction in ("right", "down")
MIN = 0.08


def contains(node, pid):
    return node.get("id") == pid or any(contains(c, pid) for c in node.get("children", []))


def path_to(node, pid):
    if node.get("id") == pid:
        return [node]
    for c in node.get("children", []):
        p = path_to(c, pid)
        if p:
            return [node] + p
    return None


def weights(children):
    ws = [c.get("size", {}).get("weight") for c in children]
    known = [w for w in ws if w is not None]
    fill = (sum(known) / len(known)) if known else 1.0
    ws = [w if w is not None else fill for w in ws]
    total = sum(ws)
    return [w / total for w in ws]


def resize(root):
    path = path_to(root, pane)
    if not path:
        return False
    for depth in range(len(path) - 2, -1, -1):
        parent, child = path[depth], path[depth + 1]
        if parent.get("type") != want or len(parent["children"]) < 2:
            continue
        kids = parent["children"]
        i = kids.index(child)
        ws = weights(kids)
        # The boundary between kids[a] and kids[b] moves toward `direction`.
        if forward:
            a, b = (i, i + 1) if i + 1 < len(kids) else (i - 1, i)
            grow, shrink = a, b
        else:
            a, b = (i - 1, i) if i > 0 else (i, i + 1)
            grow, shrink = b, a
        d = min(amount, ws[shrink] - MIN)
        if d <= 0:
            return True
        ws[grow] += d
        ws[shrink] -= d
        for k, w in zip(kids, ws):
            k["size"] = {"weight": w}
        return True
    return False


def main():
    p = subprocess.Popen(["hc", "connect"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)

    def call(i, method, params):
        p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": i, "method": method, "params": params}) + "\n")
        p.stdin.flush()
        return json.loads(p.stdout.readline())

    r = call(1, "doc.get", {"name": "herdr-app"})["result"]
    doc = r["value"]
    done = any(
        resize(tab["root"])
        for space in doc["spaces"]
        for tab in space["tabs"]
        if contains(tab["root"], pane)
    )
    if done:
        res = call(2, "doc.set", {"name": "herdr-app", "value": doc, "version": r["version"]})
        if "error" in res:
            print(json.dumps(res["error"]))
            sys.exit(1)
    p.stdin.close()
    p.wait()


main()
