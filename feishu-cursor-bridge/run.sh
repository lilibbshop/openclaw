#!/usr/bin/env bash
# 启动飞书 ↔ Cursor 桥接服务（需先配置 FEISHU_APP_ID、FEISHU_APP_SECRET）
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"
[[ -d .venv ]] || python3 -m venv .venv
source .venv/bin/activate
pip3 install -q -r requirements.txt 2>/dev/null || true
exec python3 app.py
