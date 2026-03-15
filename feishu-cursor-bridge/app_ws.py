#!/usr/bin/env python3
"""
飞书 ↔ Cursor 直连桥接（长连接模式，本地运行无需域名）
- 使用飞书 SDK 长连接（WebSocket）接收消息，与 OpenClaw 一样不需公网/ngrok
- 飞书机器人收到消息 → 转发给 Cursor CLI 执行 → 把结果回复到飞书
"""
import json
import os
import subprocess
import threading
import time
from pathlib import Path

import requests

# 长连接依赖 lark-oapi
import lark_oapi as lark

# 与 app.py 共用配置
FEISHU_APP_ID = os.environ.get("FEISHU_APP_ID", "")
FEISHU_APP_SECRET = os.environ.get("FEISHU_APP_SECRET", "")
CURSOR_SCRIPT = os.environ.get(
    "CURSOR_SCRIPT",
    str(Path(__file__).resolve().parent.parent / "scripts" / "run_cursor_instruction.sh"),
)
CURSOR_WORKSPACE = os.environ.get("CURSOR_WORKSPACE", os.getcwd())
CURSOR_TIMEOUT = int(os.environ.get("CURSOR_TASK_TIMEOUT", "300"))

_token_cache = {"token": None, "expire": 0}


def get_tenant_access_token():
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
    token = get_tenant_access_token()
    url = f"https://open.feishu.cn/open-apis/im/v1/messages/{message_id}/reply"
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
    env = os.environ.copy()
    env["OPENCLAW_CURSOR_WORKSPACE"] = CURSOR_WORKSPACE
    env["CURSOR_TASK_TIMEOUT"] = str(CURSOR_TIMEOUT)
    # 透传 Cursor 认证：若在 .env 中设置了 CURSOR_API_KEY 会一并传入
    if os.environ.get("CURSOR_API_KEY"):
        env["CURSOR_API_KEY"] = os.environ["CURSOR_API_KEY"]
    home_bin = os.path.expanduser("~/.local/bin")
    if "PATH" in env and home_bin not in env["PATH"]:
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


def _do_cursor_and_reply(message_id: str, instruction: str):
    """后台线程：执行 Cursor 并回复（长连接要求 3 秒内返回，所以实际执行放后台）"""
    try:
        result = run_cursor(instruction)
        if len(result) > 4000:
            result = result[:3900] + "\n\n…（已截断）"
        reply_message(message_id, result)
    except Exception as e:
        try:
            reply_message(message_id, f"执行或回复失败: {e}")
        except Exception:
            pass


def _do_p2_im_message_read_v1(_data) -> None:
    """消息已读回执，忽略即可，避免 SDK 报 processor not found"""
    pass


def do_p2_im_message_receive_v1(data: lark.im.v1.P2ImMessageReceiveV1) -> None:
    """接收消息 v2.0：仅做快速校验并回复「执行中」，实际执行在后台线程"""
    # P2 事件结构：data 内有 event，event 内有 message
    raw = lark.JSON.marshal(data)
    if isinstance(raw, str):
        obj = json.loads(raw)
    else:
        obj = raw
    event = obj.get("event") or obj
    msg = event.get("message") or {}
    message_id = msg.get("message_id") or ""
    message_type = msg.get("message_type") or ""
    content = msg.get("content")
    if message_type != "text":
        if message_id:
            try:
                reply_message(message_id, "当前仅支持文本指令，请直接发一句话说明要让 Cursor 执行的任务。")
            except Exception:
                pass
        return
    if isinstance(content, str):
        try:
            content = json.loads(content)
        except json.JSONDecodeError:
            content = {}
    text = (content or {}).get("text", "").strip()
    if not text:
        if message_id:
            try:
                reply_message(message_id, "请直接发一句话说明要让 Cursor 执行的任务。")
            except Exception:
                pass
        return
    # 先 3 秒内回复「执行中」
    try:
        reply_message(message_id, "正在交给 Cursor 执行，请稍候…")
    except Exception:
        pass
    # 实际执行放后台，避免长连接超时重推
    t = threading.Thread(target=_do_cursor_and_reply, args=(message_id, text))
    t.daemon = True
    t.start()


def main():
    if not FEISHU_APP_ID or not FEISHU_APP_SECRET:
        print("请设置环境变量 FEISHU_APP_ID 和 FEISHU_APP_SECRET")
        raise SystemExit(1)
    event_handler = (
        lark.EventDispatcherHandler.builder("", "")
        .register_p2_im_message_receive_v1(do_p2_im_message_receive_v1)
        .register_p2_im_message_message_read_v1(_do_p2_im_message_read_v1)
        .build()
    )
    cli = lark.ws.Client(
        FEISHU_APP_ID,
        FEISHU_APP_SECRET,
        event_handler=event_handler,
        log_level=lark.LogLevel.INFO,
    )
    print("启动飞书长连接（本地无需域名），收到消息后将转发给 Cursor 执行…")
    cli.start()


if __name__ == "__main__":
    main()
