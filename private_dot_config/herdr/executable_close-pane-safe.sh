#!/bin/sh

set -eu

pane_id=${HERDR_ACTIVE_PANE_ID:-}
bin=${HERDR_BIN_PATH:-herdr}

# カスタムコマンドの実行コンテキストが取得できない場合は、安全側に倒して何もしない。
if [ -z "$pane_id" ]; then
  exit 1
fi

process_info=$("$bin" pane process-info --pane "$pane_id") || exit 1
foreground_count=$(printf '%s' "$process_info" | /usr/bin/jq -r \
  '.result.process_info.foreground_processes // [] | length')

# シェルだけが前景なら確認不要。その他のプロセスはまとめて確認する。
active_names=$(printf '%s' "$process_info" | /usr/bin/jq -r '
  .result.process_info.foreground_processes[]?.name
  | select(test("^(sh|bash|zsh|fish|dash|ksh|tcsh|csh|pwsh|powershell|nu|elvish|xonsh)$") | not)
')

# 前景プロセスを判定できない環境では、誤クローズを避けるため確認する。
if [ "$foreground_count" -eq 0 ]; then
  active_names="（前景プロセスを判定できませんでした）"
fi

if [ -z "$active_names" ]; then
  exec "$bin" pane close "$pane_id"
fi

display_names=$(printf '%s\n' "$active_names" | /usr/bin/awk 'NF { if (out != "") out = out ", "; out = out $0 } END { print out }')

# macOS の確認ダイアログ。キャンセル時は pane close を実行しない。
/usr/bin/osascript - "$display_names" <<'APPLESCRIPT'
on run argv
  set processNames to item 1 of argv
  display dialog "このペインでは次のプロセスが実行中です:\n\n" & processNames & "\n\nペインを閉じますか？" with title "Herdr" buttons {"キャンセル", "閉じる"} default button "閉じる" cancel button "キャンセル"
end run
APPLESCRIPT

exec "$bin" pane close "$pane_id"
