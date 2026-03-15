#!/usr/bin/env bash
# 结束旧桥接进程、写日志并启动（便于排查 Cursor 无输出等问题）
cd "$(dirname "$0")"
LOG="${LOG_FILE:-./bridge.log}"
# 结束本目录启动的 app_ws.py
pkill -f "app_ws.py" 2>/dev/null || true
sleep 1
echo "日志: $LOG"
echo "启动时间: $(date -Iseconds 2>/dev/null || date)" | tee -a "$LOG"
exec ./run_ws.sh 2>&1 | tee -a "$LOG"
