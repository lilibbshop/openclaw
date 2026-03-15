#!/usr/bin/env python3
"""
飞书 ↔ Cursor 直连桥接（不经过 OpenClaw）
- 飞书机器人收到消息 → 转发给 Cursor CLI 执行 → 把结果回复到飞书
- 仅需一个飞书应用（机器人）+ 本服务 + Cursor CLI，稳定、简单
"""
import json
import os
import subprocess
import time
from pathlib import Path

import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

# 配置（环境变量）
FEISHU_APP_ID = os.environ.get("FEISHU_APP_ID", "")
FEISHU_APP_SECRET = os.environ.get("FEISHU_APP_SECRET", "")
FEISHU_VERIFICATION_TOKEN = os.environ.get("FEISHU_VERIFICATION_TOKEN", "")
CURSOR_SCRIPT = os.environ.get(
    "CURSOR_SCRIPT",
    str(Path(__file__).resolve().parent.parent / "scripts" / "run_cursor_instruction.sh"),
)
CURSOR_WORKSPACE = os.environ.get("CURSOR_WORKSPACE", os.getcwd())
CURSOR_TIMEOUT = int(os.environ.get("CURSOR_TASK_TIMEOUT", "300"))
PATH_EXTRA = os.environ.get("PATH", "")  # 可设 PATH 包含 ~/.local/bin 以便找到 agent

_token_cache = {"token": None, "expire": 0}


def get_tenant_access_token():
    """获取并缓存 tenant_access_token"""
    now = time.time()
    if _token_cache["token"] and _token_cache["expire"] > now + 60:
        return _token_cache["token"]
    url = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
    r = requests.post(
        url,
        json={"app_id": FEISHU_APP_ID, "app_secret": FEISHU_APP_SECRET},
        timeout=10,
    )
    data = r.json()
    if data.get("code") != 0:
        raise RuntimeError(f"获取 token 失败: {data}")
    _token_cache["token"] = data["tenant_access_token"]
    _token_cache["expire"] = now + data.get("expire", 7200)
    return _token_cache["token"]


def reply_message(message_id: str, text: str):
    """回复飞书消息"""
    token = get_tenant_access_token()
    url = f"https://open.feishu.cn/open-apis/im/v1/messages/{message_id}/reply"
    # 飞书要求 content 为 JSON 字符串，内部 text 可含转义
    content = json.dumps({"text": text}, ensure_ascii=False)
    r = requests.post(
        url,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        json={"content": content, "msg_type": "text"},
        timeout=10,
    )
    if r.status_code != 200 or r.json().get("code") != 0:
        raise RuntimeError(f"回复消息失败: {r.status_code} {r.text}")


def run_cursor(instruction: str) -> str:
    """调用 Cursor 脚本执行指令，返回 result 文本"""
    env = os.environ.copy()
    env["OPENCLAW_CURSOR_WORKSPACE"] = CURSOR_WORKSPACE
    env["CURSOR_TASK_TIMEOUT"] = str(CURSOR_TIMEOUT)
    # 确保能找到 agent（Cursor CLI）
    if "PATH" in env:
        home_bin = os.path.expanduser("~/.local/bin")
        if home_bin not in env["PATH"]:
            env["PATH"] = f"{home_bin}:{env['PATH']}"
    try:
        out = subprocess.run(
            ["bash", CURSOR_SCRIPT],
            input=instruction.encode("utf-8"),
            capture_output=True,
            timeout=CURSOR_TIMEOUT + 30,
            cwd=Path(CURSOR_SCRIPT).parent.parent,
            env=env,
        )
        result = (out.stdout or b"").decode("utf-8", errors="replace").strip()
        if not result and out.stderr:
            result = f"[Cursor 无输出]\nstderr: {out.stderr.decode('utf-8', errors='replace')[:1000]}"
        if not result:
            result = "Cursor 未返回内容（可能超时或未安装 agent/tmux）。"
        return result
    except subprocess.TimeoutExpired:
        return "Cursor 执行超时，请缩短指令或稍后重试。"
    except Exception as e:
        return f"执行 Cursor 出错: {e}"


def extract_text_from_message(event: dict) -> str | None:
    """从 im.message.receive_v1 事件里取出用户发送的文本"""
    msg = event.get("message", {})
    if msg.get("message_type") != "text":
        return None
    content = msg.get("content", "{}")
    if isinstance(content, str):
        try:
            content = json.loads(content)
        except json.JSONDecodeError:
            return content
    return (content or {}).get("text", "").strip()


@app.route("/webhook", methods=["POST"])
def webhook():
    body = request.get_json(silent=True) or {}
    # URL 校验（飞书首次配置请求体验证）
    if body.get("type") == "url_verification":
        return jsonify({"challenge": body.get("challenge", "")})

    # 事件回调
    if body.get("type") != "event":
        return jsonify({})

    event = body.get("event", {})
    if event.get("type") != "im.message.receive_v1":
        return jsonify({})

    text = extract_text_from_message(event)
    if not text:
        reply_message(
            event["message"]["message_id"],
            "当前仅支持文本指令，请直接发一句话说明要让 Cursor 执行的任务。",
        )
        return jsonify({})

    message_id = event["message"]["message_id"]
    # 先回复“执行中”，避免用户等太久没反馈
    try:
        reply_message(message_id, "正在交给 Cursor 执行，请稍候…")
    except Exception:
        pass

    result = run_cursor(text)
    # 飞书单条消息有长度限制，过长可截断或分条
    if len(result) > 4000:
        result = result[:3900] + "\n\n…（已截断）"
    try:
        reply_message(message_id, result)
    except Exception as e:
        reply_message(message_id, f"回复失败: {e}")

    return jsonify({})


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "9876"))
    app.run(host="0.0.0.0", port=port, debug=False)
