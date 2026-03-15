# 飞书与 Cursor 对接方式

## 方式一：飞书直连 Cursor（推荐，更稳定）

**不经过 OpenClaw**：单独配置一个飞书机器人，只做「收消息 → 交给 Cursor 执行 → 结果回飞书」。适合远程控制 Cursor、稳定执行指定项目代码。

- 实现位置：**`feishu-cursor-bridge/`**（独立小服务，Python）
- **长连接模式（推荐）**：与 OpenClaw 一样用飞书长连接接收事件，**本地运行即可，无需域名/ngrok**。  
  运行 `python app_ws.py` 或 `./run_ws.sh`，飞书后台事件订阅选择「**通过长连接接收事件**」并保存（需先启动本机服务）。
- **Webhook 模式**：事件订阅选「将回调发送至开发者服务器」，请求地址填公网 URL + `/webhook`，本机运行 `python app.py`。
- 详见：**`feishu-cursor-bridge/README.md`**

---

## 方式二：经 OpenClaw 转发（功能多但依赖 OpenClaw 稳定性）

当前流程：**飞书发消息 → OpenClaw 接收并处理 → 需要把「执行指令」交给 Cursor → 拿到 Cursor 结果 → 在飞书回复**。  
这里只差两件事：**怎么通知 Cursor 运行**、**怎么获取 Cursor 的运行结果**。

---

## 一、结论概览

| 环节 | 做法 |
|------|------|
| **通知 Cursor 运行** | 用 **Cursor CLI** 的**非交互模式**：`agent -p "指令" --output-format json --trust`。在 OpenClaw 所在环境（无 TTY）下需通过 **tmux** 跑，否则会挂起。 |
| **获取 Cursor 结果** | 同上命令加上 `--output-format json`，标准输出会得到**一个 JSON**，其中 **`result`** 字段即为 Cursor 的完整回复文本，解析该字段即可。 |

本仓库已提供一个桥接脚本，用 tmux + 上述命令完成「通知 Cursor + 写结果到文件 + 解析 result」。

---

## 二、用 Cursor CLI 通知执行并拿到结果

### 2.1 命令形式

Cursor 官方支持用 CLI **非交互**跑一条指令并拿到结构化结果：

```bash
agent -p "你的指令，例如：优化 src/utils.js 的代码" --output-format json --trust
```

- **`-p` / `--print`**：非交互模式，执行完把回复打到标准输出。
- **`--output-format json`**：输出一个 JSON，便于程序解析。
- **`--trust`**：无头/脚本环境下不弹 workspace 信任确认，避免卡住。

成功时 stdout 会是一行 JSON，例如：

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "duration_ms": 12345,
  "result": "这里是 Cursor 的完整回复文本...",
  "session_id": "..."
}
```

**获取结果**：从这行 JSON 里取 **`result`** 字段即可，这就是要回给飞书的内容（或再让 OpenClaw 的 AI 做摘要/润色）。

可选：

- **`--workspace /path/to/project`**：指定 Cursor 工作目录（要优化哪个仓库的代码就填哪个路径）。
- **`--force`**：自动同意执行命令/改文件，适合自动化。

### 2.2 在「无 TTY」环境（OpenClaw 网关/脚本）里运行

在 AI 助手、后台服务、脚本里**直接**执行 `agent -p "..."` 时，没有真实 TTY，Cursor CLI 会一直挂起。  
官方/社区做法是：**用 tmux 提供一个伪终端**，在 tmux 里跑 `agent`，再用文件或 capture-pane 取输出。

本仓库提供的脚本就是按这个思路做的：用 tmux 跑 `agent -p ... --output-format json --trust`，把 stdout 重定向到临时文件，再解析 JSON 的 `result` 并打印，供 OpenClaw 读取。

---

## 三、本仓库的桥接脚本用法

路径：**`scripts/run_cursor_instruction.sh`**。

### 3.1 安装与依赖

- 已安装 **Cursor CLI**（命令名：`agent`）：  
  `curl https://cursor.com/install -fsSL | bash`，并保证 `agent` 在 PATH。
- 已安装 **tmux**（推荐）：  
  `brew install tmux`（macOS）或 `sudo apt install tmux`（Linux）。
- 可选：**jq**，用于可靠解析 JSON；没有则脚本会尝试用 grep/sed 简单截取 `result`。

### 3.2 使用方式

```bash
# 在项目根目录或任意目录
chmod +x scripts/run_cursor_instruction.sh

# 方式一：参数传指令
./scripts/run_cursor_instruction.sh "优化项目里的 src/utils.js 代码，加注释"

# 方式二：stdin 传指令
echo "优化项目里的 src/utils.js 代码" | ./scripts/run_cursor_instruction.sh
```

脚本会：

1. 用 **tmux** 在后台跑：`agent -p "指令" --output-format json --trust ...`；
2. 把 JSON 写到临时文件并轮询等待包含 `result` 或超时（默认 300 秒，可设 `CURSOR_TASK_TIMEOUT`）；
3. 解析 JSON，把 **`result`** 打印到 **stdout**。

因此：**通知 Cursor = 调用该脚本并传入指令**；**获取结果 = 读脚本的 stdout**。

### 3.3 环境变量（可选）

| 变量 | 含义 | 默认 |
|------|------|------|
| `OPENCLAW_CURSOR_WORKSPACE` | Cursor 工作目录（要改代码的项目路径） | 当前目录 `$PWD` |
| `CURSOR_TASK_TIMEOUT` | 等待 Cursor 返回的秒数 | 300 |
| `CURSOR_TMUX_SESSION` | tmux 会话名 | `cursor-openclaw` |

示例：

```bash
export OPENCLAW_CURSOR_WORKSPACE=/Users/ian/openclaw
./scripts/run_cursor_instruction.sh "检查 README 里的错别字"
```

---

## 四、在 OpenClaw 里接上这条链路

OpenClaw 侧需要：**在收到飞书消息后，在合适的时机调用上述脚本，并把脚本 stdout 作为「Cursor 的执行结果」参与回复**。具体有两种常见做法（二选一或组合）。

### 4.1 方式 A：用能「执行本地命令」的 Skill

若 OpenClaw 已有或你安装了能**执行本地命令/脚本**的 Skill（例如提供 `run_shell`、`execute_command` 之类工具）：

1. 在 Skill 里配置或说明：当用户意图是「让 Cursor 执行 / 优化代码 / 在 Cursor 里做 XXX」时，调用本机上的 `run_cursor_instruction.sh`，并把**用户原话或转写后的指令**作为参数传入。
2. 工具返回 = 脚本的 stdout = Cursor 的 **`result`** 文本。
3. OpenClaw 的 Agent 把这个返回值作为工具结果，组织成对用户的回复，通过飞书通道发回。

这样：**通知 Cursor = 调用脚本**，**获取结果 = 使用该工具返回值**。

### 4.2 方式 B：安装 cursor-agent Skill + 让 Agent 按步骤调用脚本

若使用 OpenClaw 的 **cursor-agent** Skill（ClawHub 上可搜到），该 Skill 主要提供「如何用 Cursor CLI、如何在 tmux 里跑」的说明，**不会自动替你执行**。你可以：

1. 在 Skill 描述或规则中写明：当用户说「让 Cursor 执行 / 用 Cursor 优化代码」时，应调用本机脚本：  
   `脚本路径/run_cursor_instruction.sh "用户指令"`，  
   并把脚本的 stdout 作为 Cursor 执行结果回复给用户（包括在飞书里回复）。

2. 若 OpenClaw 没有现成的「执行本地命令」工具，就需要一个能执行 shell 的 Skill 或插件，其内部实际执行的就是上面的脚本；逻辑上仍是：**通知 Cursor = 执行该脚本**，**获取结果 = 读取脚本 stdout**。

---

## 五、流程小结

1. **飞书** → 用户发：「让 Cursor 优化一下当前项目的代码」
2. **OpenClaw** → 收到消息，由 Agent 解析意图，识别为「需要 Cursor 执行」。
3. **通知 Cursor** → 通过本地执行：  
   `run_cursor_instruction.sh "优化当前项目的代码"`（或带 `OPENCLAW_CURSOR_WORKSPACE` 指定项目路径）。
4. **获取结果** → 脚本在 tmux 里跑 `agent -p "..." --output-format json --trust`，解析 JSON 的 **`result`** 并打印到 stdout；OpenClaw 用该 stdout 作为「Cursor 运行结果」。
5. **飞书回复** → OpenClaw 把该结果（或经 AI 摘要/润色后）通过飞书通道发回用户。

这样就把「OpenClaw 接到信息后怎么通知 Cursor」和「怎么获取 Cursor 的运行结果」都串起来了；你这边只需在 OpenClaw 里接上「执行 `run_cursor_instruction.sh` 并读取其 stdout」这一步即可（通过现有或新加的「执行本地命令」类 Skill/工具）。
