#!/usr/bin/env bash
# =============================================================================
# Mac 远程节点电源设置（OpenClaw / Codex 合盖不眠 + 屏幕可关省电）
# 需要 sudo 执行
# =============================================================================

set -e

echo "当前电源配置："
pmset -g

echo ""
echo "将应用以下设置（合盖不眠、屏幕可关、网络保持）："
echo "  sleep 0         - 系统永不休眠"
echo "  disksleep 0     - 磁盘不休眠（保证服务稳定）"
echo "  displaysleep 2  - 2 分钟后关闭屏幕（省电、延长屏幕寿命）"
echo "  tcpkeepalive 1  - 保持 TCP 连接，防止网络断开"
echo ""

# 系统永不休眠
sudo pmset -a sleep 0
# 磁盘不休眠
sudo pmset -a disksleep 0
# 屏幕 2 分钟后关闭（可改 1~10，单位分钟）
sudo pmset -a displaysleep 2
# 插电时也遵守上述设置
sudo pmset -a womp 1
# 保持网络活跃，SSH 等不会因空闲断开
sudo pmset -a tcpkeepalive 1

echo "已应用。当前配置："
pmset -g

echo ""
echo "注意："
echo "  1. 合盖不眠需「外接电源」；仅电池时合盖仍可能睡眠。"
echo "  2. 仍需配合 caffeinate 或 Amphetamine 才能合盖不眠。"
echo "  3. 恢复默认： sudo pmset -a sleep 10 displaysleep 10 disksleep 10"
