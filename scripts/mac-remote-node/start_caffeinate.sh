#!/usr/bin/env bash
# =============================================================================
# 后台运行 caffeinate：合盖不眠，但允许关屏（省电）
# 不加 -d，所以「显示器可以关闭」，只防止系统/磁盘/网络休眠
# =============================================================================

CAFF_PID_FILE="${CAFF_PID_FILE:-$HOME/.caffeinate_remote_node.pid}"

if [[ -f "$CAFF_PID_FILE" ]]; then
  OLD_PID=$(cat "$CAFF_PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "caffeinate 已在运行 (PID $OLD_PID)。若要重启，先执行: kill $OLD_PID"
    exit 0
  fi
  rm -f "$CAFF_PID_FILE"
fi

# -i 防止 idle 休眠  -m 防止磁盘休眠  -s 插电时不睡眠  -u 保持活跃
# 故意不加 -d，让屏幕可以自动关闭，省电且延长屏幕寿命
nohup caffeinate -imsu >> /tmp/caffeinate_remote_node.log 2>&1 &
echo $! > "$CAFF_PID_FILE"
echo "已启动 caffeinate（合盖不眠、允许关屏），PID: $(cat $CAFF_PID_FILE)"
echo "查看进程: ps aux | grep caffeinate"
echo "停止: kill \$(cat $CAFF_PID_FILE)"
