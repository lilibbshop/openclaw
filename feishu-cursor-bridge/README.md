# 飞书 ↔ Cursor 直连桥接

**不经过 OpenClaw**：单独一个飞书机器人，只负责把你说的话转发给本机 Cursor 执行，再把结果回给你。适合「远程控制 Cursor、稳定执行指定项目代码」的场景。

---

## 推荐：长连接模式（本地运行，无需域名）

和 OpenClaw 一样，用**飞书长连接（WebSocket）**接收事件，**不需要公网 IP、域名或 ngrok**，本机启动即可。

### 流程

```
飞书（你发消息）→ 本机长连接收到事件 → Cursor CLI 执行 → 结果回飞书
```

### 1. 飞书侧：新建一个「只给 Cursor 用」的机器人

1. 打开 [飞书开放平台](https://open.feishu.cn/app) → 创建**企业自建应用**（长连接仅支持自建应用）。
2. **权限**：在「权限管理」中开通：
   - `im:message`、`im:message:readonly`、`im:message:send_as_bot`
   - `im:message.p2p_msg:readonly`、`im:message.group_at_msg:readonly`（按需）
3. **机器人**：在「应用能力」→「机器人」中启用，设置名称（如「Cursor 执行器」）。
4. **事件订阅**：
   - **先在本机启动下面的桥接服务**（见第 2 步），保持运行。
   - 在开放平台：**事件订阅** → 选择 **「通过长连接接收事件（WebSocket）」**，并保存。
   - 添加事件：`im.message.receive_v1`。
   - ⚠️ 必须本机客户端已连接成功，后台才能保存「长连接」方式。
5. **发布应用**并安装到你的企业/自己。

### 2. 本机：安装依赖并启动（长连接）

```bash
cd feishu-cursor-bridge
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip3 install -r requirements.txt
```

配置环境变量后启动**长连接**：

```bash
export FEISHU_APP_ID="你的 App ID"
export FEISHU_APP_SECRET="你的 App Secret"
# 可选：Cursor 执行的工作目录
export CURSOR_WORKSPACE="/Users/ian/openclaw"
python3 app_ws.py
```

或使用脚本（会自动把 `~/.local/bin` 加入 PATH，便于找到 Cursor `agent`）：

```bash
./run_ws.sh
```

看到控制台打印类似 `connected to wss://...` 即表示长连接已建立，飞书发消息给该机器人即可触发 Cursor 执行。

**注意**：桥接需在**本机终端**运行（不要在不支持 tmux 的沙箱里跑），否则 Cursor 脚本无法拿到 agent 输出。若需查日志，可执行：`./start_with_log.sh`（会结束旧进程并写入 `bridge.log`）。

### 3. Cursor 认证（必做一次）

桥接会把你的话交给本机 **Cursor CLI（agent）** 执行，因此本机必须先完成 Cursor 认证，二选一：

- **推荐**：在本机终端执行一次：
  ```bash
  export PATH="$HOME/.local/bin:$PATH"
  agent login
  ```
  会打开浏览器，用你当前登录的 Cursor 账号授权即可；完成后 CLI 与飞书桥接共用同一认证。
- **或**：用 Cursor API Key（适合无浏览器环境）  
  - 获取：打开 [Cursor 设置](https://cursor.com/settings) 或 Cursor 客户端 **Settings → Account / API**，或 [Dashboard](https://cursor.com/dashboard) 的 API Keys 相关入口。  
  - 在 `feishu-cursor-bridge/.env` 里增加：`CURSOR_API_KEY=你的API Key`

未认证时飞书里会收到报错：`Authentication required. Please run 'agent login' first...`。

### 4. 使用方式

在飞书里找到该机器人（私聊或拉进群），**发一句文本**，例如：

- 「用一句话说：当前项目是 openclaw，测试成功」
- 「列出当前目录下的前 10 个文件」

机器人会先回复「正在交给 Cursor 执行，请稍候…」，执行完成后把 Cursor 的**结果**再发一条回复。

---

## 备选：Webhook 模式（需要公网地址）

若你不想用长连接，可以用 HTTP Webhook：飞书把事件 POST 到你的服务器，需要**公网 URL**（如 ngrok）。

- 启动：`python3 app.py`（监听 `0.0.0.0:9876`）。
- 飞书后台事件订阅选择「将回调发送至开发者服务器」，请求地址填 `https://你的公网地址/webhook`。
- 详见此前文档或 `app.py` 注释。

---

## 依赖

- **本机已安装**：Cursor CLI（`agent`）、tmux、Python 3
- **项目根目录** 的 `scripts/run_cursor_instruction.sh`（与 openclaw 共用同一脚本）
- **长连接** 需安装 `lark-oapi`（已写在 `requirements.txt`）

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `FEISHU_APP_ID` | 是 | 飞书应用 App ID |
| `FEISHU_APP_SECRET` | 是 | 飞书应用 App Secret |
| `CURSOR_WORKSPACE` | 否 | Cursor 执行时的工作目录（默认当前目录） |
| `CURSOR_SCRIPT` | 否 | `run_cursor_instruction.sh` 的完整路径 |
| `CURSOR_TASK_TIMEOUT` | 否 | 单次 Cursor 任务超时秒数，默认 300 |
| `CURSOR_API_KEY` | 否 | Cursor API Key（不设则需本机已执行过 `agent login`） |
| `PORT` | 否 | 仅 Webhook 模式：本服务端口，默认 9876 |

## 与 OpenClaw 的区别

- **OpenClaw**：功能多（多技能、多通道、控制台），但相对重，可能不稳定。
- **本桥接**：只做一件事——飞书消息 ↔ Cursor 执行结果，无 OpenClaw、无技能栈；**长连接模式与 OpenClaw 一样本地即可，不需域名**。
