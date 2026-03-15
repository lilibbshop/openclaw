#!/usr/bin/env bash
# =============================================================================
# 在 tmux 中启动长期任务（PostgreSQL、GitHub 监控、微信小程序发布等）
# 合盖、断 SSH 后进程继续运行
#
# 用法：先编辑下方 TASKS 数组，填入你的脚本路径，再执行此脚本
# =============================================================================

SESSION_NAME="${1:-work}"

# ---------- 在这里添加你的长期任务 ----------
# 格式：每项为 "窗口名|启动命令"
# 示例：
#   "pgsql|cd /path/to/your/project && python your_pgsql_script.py"
#   "github-miniprogram|cd /path/to/monitor && node watch_github_publish.js"
TASKS=(
  # "pgsql|cd /Users/ian/你的项目 && python pgsql_script.py"
  # "github-miniprogram|cd /Users/ian/你的监控项目 && npm run watch"
)

# ---------- 若 TASKS 为空，只开一个空 tmux 会话 ----------
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "tmux 会话 '$SESSION_NAME' 已存在，正在附加..."
  exec tmux attach -t "$SESSION_NAME"
fi

# 过滤掉注释和空项
ACTIVE_TASKS=()
for t in "${TASKS[@]}"; do
  [[ -n "$t" && "$t" != "#"* ]] && ACTIVE_TASKS+=("$t")
done

if [[ ${#ACTIVE_TASKS[@]} -eq 0 ]]; then
  echo "未配置任务。请编辑此脚本，在 TASKS 数组里添加你的脚本。"
  echo "示例："
  echo '  TASKS=('
  echo '    "pgsql|cd /Users/ian/xxx && python pgsql_script.py"'
  echo '    "github-miniprogram|cd /Users/ian/yyy && npm run watch"'
  echo '  )'
  echo ""
  exec tmux new -s "$SESSION_NAME"
fi

# 创建会话并启动第一个任务
first="${ACTIVE_TASKS[0]}"
name="${first%%|*}"
cmd="${first#*|}"
tmux new-session -d -s "$SESSION_NAME" -n "$name"
tmux send-keys -t "$SESSION_NAME:$name" "$cmd" Enter

# 其余任务开新窗口
for i in "${!ACTIVE_TASKS[@]}"; do
  [[ $i -eq 0 ]] && continue
  item="${ACTIVE_TASKS[$i]}"
  name="${item%%|*}"
  cmd="${item#*|}"
  tmux new-window -t "$SESSION_NAME" -n "$name"
  tmux send-keys -t "$SESSION_NAME:$name" "$cmd" Enter
done

echo "已启动 tmux 会话 '$SESSION_NAME'，包含 ${#ACTIVE_TASKS[@]} 个任务"
echo "附加: tmux attach -t $SESSION_NAME"
echo "断开: Ctrl+B 然后 D"
exec tmux attach -t "$SESSION_NAME"
