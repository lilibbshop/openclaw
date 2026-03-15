#!/usr/bin/env bash
# =============================================================================
# 启动 tmux 工作会话：长期任务（PostgreSQL、GitHub 监控、微信小程序等）放这里跑
# 合盖、断 SSH 后进程仍会继续运行
# =============================================================================

SESSION_NAME="${1:-work}"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "tmux 会话 '$SESSION_NAME' 已存在，正在附加..."
  exec tmux attach -t "$SESSION_NAME"
else
  echo "创建新 tmux 会话: $SESSION_NAME"
  echo ""
  echo "用法："
  echo "  - 在 tmux 里运行你的脚本（PostgreSQL、GitHub 监控等）"
  echo "  - 断开但保持运行: Ctrl+B 然后按 D"
  echo "  - 重连: tmux attach -t $SESSION_NAME"
  echo "  - 或直接: $0 $SESSION_NAME"
  echo ""
  exec tmux new -s "$SESSION_NAME"
fi
