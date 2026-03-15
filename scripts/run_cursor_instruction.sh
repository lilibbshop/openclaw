#!/usr/bin/env bash
# OpenClaw → Cursor 执行桥接脚本
# 用法: run_cursor_instruction.sh "让 Cursor 执行的指令"
# 或: echo "指令" | run_cursor_instruction.sh
# 输出: 打印 Cursor 的 result 文本，供 OpenClaw 取回后回复飞书
set -e

SESSION_NAME="${CURSOR_TMUX_SESSION:-cursor-openclaw}"
WORKSPACE="${OPENCLAW_CURSOR_WORKSPACE:-$PWD}"
RESULT_FILE="${TMPDIR:-/tmp}/cursor-result-$$.json"
STDERR_FILE="${TMPDIR:-/tmp}/cursor-stderr-$$.txt"
INSTRUCTION_FILE="${TMPDIR:-/tmp}/cursor-instruction-$$.txt"
TIMEOUT="${CURSOR_TASK_TIMEOUT:-300}"

# 读取指令：参数优先，否则 stdin
if [[ -n "$1" ]]; then
  printf '%s' "$*" > "$INSTRUCTION_FILE"
else
  cat > "$INSTRUCTION_FILE"
fi

cleanup() {
  rm -f "$INSTRUCTION_FILE" "$RESULT_FILE" "$STDERR_FILE"
  tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# 确保 agent 在 PATH
if ! command -v agent &>/dev/null; then
  echo "[错误] 未找到 Cursor CLI (agent)。请先安装: curl https://cursor.com/install -fsSL | bash" >&2
  exit 1
fi

# 若无 tmux，尝试直接运行（仅当有 TTY 或 --trust 时可能不挂起）
run_with_tmux() {
  tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
  tmux new-session -d -s "$SESSION_NAME" -c "$WORKSPACE"
  # 在 tmux 中执行：从文件读指令，输出 JSON 到文件
  tmux send-keys -t "$SESSION_NAME" "agent -p \"\$(cat '$INSTRUCTION_FILE')\" --output-format json --trust --workspace '$WORKSPACE' > '$RESULT_FILE' 2>'$STDERR_FILE'; echo DONE" Enter

  local waited=0
  while (( waited < TIMEOUT )); do
    sleep 5
    (( waited += 5 ))
    if [[ -f "$RESULT_FILE" ]] && grep -q '"result"' "$RESULT_FILE" 2>/dev/null; then
      return 0
    fi
    if tmux capture-pane -t "$SESSION_NAME" -p 2>/dev/null | grep -q 'DONE'; then
      return 0
    fi
  done
  echo "[超时] Cursor 执行超过 ${TIMEOUT} 秒未返回结果" >&2
  return 1
}

run_direct() {
  # 直接跑 agent；无 TTY 时（如被桥接调用）--trust 下不挂起，输出稳定
  agent -p "$(cat "$INSTRUCTION_FILE")" --output-format json --trust --workspace "$WORKSPACE" > "$RESULT_FILE" 2>"$STDERR_FILE" || true
}

# 桥接调用时无 TTY，必须用 tmux 才能让 agent 正常输出 JSON；有 TTY 时也可用 tmux
if command -v tmux &>/dev/null; then
  run_with_tmux || true
else
  run_direct
fi
# tmux 内命令刚结束可能尚未 flush，稍等再读
[[ -f "$RESULT_FILE" ]] && sleep 2

# 输出 result 字段（agent 可能先打几行日志，JSON 多为最后一行）
result=""
if [[ -f "$RESULT_FILE" ]] && [[ -s "$RESULT_FILE" ]]; then
  json_line=$(grep -E '^\s*\{' "$RESULT_FILE" | tail -1)
  [[ -z "$json_line" ]] && json_line=$(tail -1 "$RESULT_FILE")
  if [[ -n "$json_line" ]]; then
    result=$(printf '%s' "$json_line" | jq -r '.result // empty' 2>/dev/null) || true
  fi
  [[ -z "$result" ]] && result=$(grep -o '"result"[[:space:]]*:[[:space:]]*"[^"]*"' "$RESULT_FILE" | sed 's/.*: *"\(.*\)"/\1/' | head -1)
  [[ -n "$result" ]] && printf '%s' "$result"
fi

# 无 result 时把 stderr 或说明打到 stdout，方便桥接把原因回给飞书
if [[ -z "$result" ]] && [[ -f "$STDERR_FILE" ]] && [[ -s "$STDERR_FILE" ]]; then
  echo "[Cursor stderr]"
  cat "$STDERR_FILE"
fi
if [[ -z "$result" ]]; then
  # 若 RESULT_FILE 存在但无 result，可能是 JSON 格式或超时
  if [[ -f "$RESULT_FILE" ]] && [[ -s "$RESULT_FILE" ]]; then
    head -c 500 "$RESULT_FILE"
  fi
fi

if [[ -f "$STDERR_FILE" ]] && [[ -s "$STDERR_FILE" ]]; then
  echo "" >&2
  echo "Cursor stderr:" >&2
  cat "$STDERR_FILE" >&2
fi
