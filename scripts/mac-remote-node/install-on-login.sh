#!/usr/bin/env bash
# =============================================================================
# 安装开机/登录自启动：合盖不眠 + 传家纪（PostgreSQL 隧道 + 微信小程序监控发布）
# 执行后，下次重启/登录会自动启动所有服务
# =============================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  安装开机自启动任务"
echo "=========================================="
echo ""

# 1. OpenClaw caffeinate（合盖不眠）
echo "[1/4] 安装 caffeinate 自启（合盖不眠）..."
PLIST="$HOME/Library/LaunchAgents/com.openclaw.caffeinate.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cp "$SCRIPT_DIR/com.openclaw.caffeinate.plist" "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
echo "  ✓ 已安装: $PLIST"
echo ""

# 2. 传家纪 DB 隧道（PostgreSQL SSH 隧道）
echo "[2/4] 安装传家纪 PostgreSQL 隧道自启..."
if [ -f "/Users/ian/chuanjiaji/scripts/install-db-tunnel-agent.sh" ]; then
  cd /Users/ian/chuanjiaji
  bash scripts/install-db-tunnel-agent.sh
  cd "$SCRIPT_DIR"
else
  echo "  ⚠ 未找到 chuanjiaji，跳过 install-db-tunnel-agent"
fi
echo ""

# 3. yinsight DB 隧道（同机 PostgreSQL）
echo "[3/4] 安装 yinsight PostgreSQL 隧道自启..."
if [ -f "/Users/ian/chuanjiaji/scripts/install-yinsight-db-tunnel-agent.sh" ]; then
  cd /Users/ian/chuanjiaji
  bash scripts/install-yinsight-db-tunnel-agent.sh
  cd "$SCRIPT_DIR"
else
  echo "  ⚠ 未找到 install-yinsight-db-tunnel-agent.sh，跳过"
fi
echo ""

# 4. 传家纪微信体验版自动发布（GitHub main 监控）
echo "[4/4] 安装传家纪微信自动发布自启..."
if [ -f "/Users/ian/chuanjiaji/scripts/install-local-wechat-release-agent.sh" ]; then
  cd /Users/ian/chuanjiaji
  bash scripts/install-local-wechat-release-agent.sh
  cd "$SCRIPT_DIR"
else
  echo "  ⚠ 未找到 chuanjiaji，跳过 install-local-wechat-release-agent"
fi
echo ""

echo "=========================================="
echo "  安装完成"
echo "=========================================="
echo ""
echo "自启动任务（登录后自动运行）："
echo "  - com.openclaw.caffeinate    合盖不眠"
echo "  - com.chuanjiaji.db-tunnel    chuanjiaji PostgreSQL (127.0.0.1:5433)"
echo "  - com.chuanjiaji.yinsight-db-tunnel  yinsight PostgreSQL (127.0.0.1:5434)"
echo "  - com.chuanjiaji.wechat-experience-release  GitHub main 监控 + 微信发布"
echo ""
echo "查看状态: launchctl list | grep -E 'openclaw|chuanjiaji'"
echo "手动重启: ./restart_services.sh"
echo ""
echo "⚠ pmset（系统电源）需 sudo，重启后若恢复默认，请手动执行一次："
echo "   sudo ./set_pmset_remote_node.sh"
echo ""
