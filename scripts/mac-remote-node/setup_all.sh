#!/usr/bin/env bash
# =============================================================================
# 一键配置：合盖不眠 + 屏幕可关省电
# 运行此脚本即可完成 pmset + caffeinate 全部配置
# =============================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Mac 合盖不眠 - 一键配置"
echo "=========================================="
echo ""

# 1. pmset（需要 sudo）
echo "[1/2] 配置系统电源 (pmset)..."
chmod +x set_pmset_remote_node.sh
./set_pmset_remote_node.sh
echo ""

# 2. caffeinate
echo "[2/2] 启动 caffeinate（合盖不眠）..."
chmod +x start_caffeinate.sh
./start_caffeinate.sh
echo ""

echo "=========================================="
echo "  配置完成！"
echo "=========================================="
echo ""
echo "提醒："
echo "  - 必须插电，合盖才不会睡眠"
echo "  - 长期任务请用 tmux: ./start_tmux_work.sh"
echo "  - 恢复默认: sudo pmset -a sleep 10 displaysleep 10 disksleep 10"
echo ""
