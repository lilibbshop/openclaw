#!/usr/bin/env bash
# =============================================================================
# 重启所有长期服务（合盖不眠、PostgreSQL 隧道、微信自动发布）
# =============================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  重启长期服务"
echo "=========================================="
echo ""

# 1. caffeinate 先停掉旧的（可能由 start_caffeinate.sh 启动）
if [ -f "$HOME/.caffeinate_remote_node.pid" ]; then
  OLD_PID=$(cat "$HOME/.caffeinate_remote_node.pid" 2>/dev/null)
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[1] 停止旧的 caffeinate (PID $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    rm -f "$HOME/.caffeinate_remote_node.pid"
  fi
fi

# 2. caffeinate（由 LaunchAgent 管理，reload 即可）
echo "[1] 重启 caffeinate（合盖不眠）..."
PLIST="$HOME/Library/LaunchAgents/com.openclaw.caffeinate.plist"
if [ -f "$PLIST" ]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  echo "  ✓"
else
  echo "  未安装 LaunchAgent，运行 start_caffeinate.sh..."
  "$SCRIPT_DIR/start_caffeinate.sh"
fi
echo ""

# 3. 传家纪 DB 隧道
echo "[2] 重启 chuanjiaji PostgreSQL 隧道..."
if [ -f "/Users/ian/chuanjiaji/scripts/install-db-tunnel-agent.sh" ]; then
  DB_PLIST="$HOME/Library/LaunchAgents/com.chuanjiaji.db-tunnel.plist"
  if [ -f "$DB_PLIST" ]; then
    launchctl unload "$DB_PLIST" 2>/dev/null || true
    launchctl load "$DB_PLIST"
    echo "  ✓"
  else
    echo "  未安装，执行 install-db-tunnel-agent..."
    cd /Users/ian/chuanjiaji && bash scripts/install-db-tunnel-agent.sh
  fi
else
  echo "  ⚠ 未找到 chuanjiaji"
fi
echo ""

# 4. yinsight DB 隧道
echo "[3] 重启 yinsight PostgreSQL 隧道..."
if [ -f "/Users/ian/chuanjiaji/scripts/install-yinsight-db-tunnel-agent.sh" ]; then
  YINSIGHT_PLIST="$HOME/Library/LaunchAgents/com.chuanjiaji.yinsight-db-tunnel.plist"
  if [ -f "$YINSIGHT_PLIST" ]; then
    launchctl unload "$YINSIGHT_PLIST" 2>/dev/null || true
    launchctl load "$YINSIGHT_PLIST"
    echo "  ✓"
  else
    cd /Users/ian/chuanjiaji && bash scripts/install-yinsight-db-tunnel-agent.sh
  fi
else
  echo "  ⚠ 未找到 chuanjiaji"
fi
echo ""

# 5. 传家纪微信自动发布
echo "[4] 重启微信自动发布..."
if [ -f "/Users/ian/chuanjiaji/scripts/install-local-wechat-release-agent.sh" ]; then
  WX_PLIST="$HOME/Library/LaunchAgents/com.chuanjiaji.wechat-experience-release.plist"
  if [ -f "$WX_PLIST" ]; then
    launchctl unload "$WX_PLIST" 2>/dev/null || true
    launchctl load "$WX_PLIST"
    echo "  ✓"
  else
    echo "  未安装，执行 install-local-wechat-release-agent..."
    cd /Users/ian/chuanjiaji && bash scripts/install-local-wechat-release-agent.sh
  fi
else
  echo "  ⚠ 未找到 chuanjiaji"
fi
echo ""

echo "=========================================="
echo "  当前状态"
echo "=========================================="
launchctl list | grep -E "openclaw|chuanjiaji|yinsight" || true
echo ""
echo "提醒："
echo "  - 合盖不眠需插电"
echo "  - DB 隧道需能访问 114.55.134.16，网络不通时会自动重试"
echo "  - 微信发布每 60 秒检查 main 分支"
echo ""
