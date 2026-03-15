#!/usr/bin/env bash
# 启动飞书 ↔ Cursor 桥接（长连接模式，本地无需域名）
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"
# 加载 .env（不提交到 git，含 App ID/Secret）
set -a
[[ -f .env ]] && source .env
set +a
# 无 venv 时先创建，避免系统 pip 受限于 externally-managed-environment
[[ -d .venv ]] || python3 -m venv .venv
source .venv/bin/activate
pip3 install -q -r requirements.txt 2>/dev/null || true
exec python3 app_ws.py
