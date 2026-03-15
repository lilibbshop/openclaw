# OpenClaw 本地模型：Ollama 安装说明（Apple Silicon 最适配）

OpenClaw 官方最适配的本地方案是 **Ollama**，支持工具调用、自动发现模型、无 token 额度限制。

---

## 一、安装 Ollama（本机）

```bash
# 官方一键安装（macOS）
curl -fsSL https://ollama.com/install.sh | sh
```

安装后 Ollama 会在菜单栏/后台运行，默认地址 `http://127.0.0.1:11434`。

---

## 二、按你内存选一个模型并拉取

| 本机内存 | 推荐模型 | 说明 |
|----------|----------|------|
| **8GB** | `llama3.2:3b` | 最轻，能跑工具调用 |
| **16GB** | **`qwen2.5-coder:7b`**（推荐） | 工具/代码表现好，已写入你配置 |
| **24GB+** | `qwen2.5-coder:32b` 或 `llama3.3:70b` | 更强，适合复杂任务 |

在终端执行（先选一个）：

```bash
# 16GB 推荐（已在你 openclaw 里配好）
ollama pull qwen2.5-coder:7b

# 8GB 用更小
# ollama pull llama3.2:3b

# 24GB+ 用更大
# ollama pull qwen2.5-coder:32b
ollama list
```

---

## 三、让 OpenClaw 识别 Ollama

**不要**在 `openclaw.json` 里写死 `models.providers.ollama`（会关掉自动发现）。用环境变量即可：

在 `~/.zshrc` 末尾加一行：

```bash
export OLLAMA_API_KEY="ollama-local"
```

保存后执行：

```bash
source ~/.zshrc
```

之后**从终端启动 OpenClaw / gateway** 时，会带上这个变量，OpenClaw 会自动发现本机 Ollama 模型。

若你用 **LaunchAgent 后台跑 gateway**，需要让服务也带上该环境变量（在 LaunchAgent plist 的 `EnvironmentVariables` 里加 `OLLAMA_API_KEY` = `ollama-local`），否则只有从终端开 OpenClaw 时才会用上 Ollama。

---

## 四、当前配置含义

已在 `~/.openclaw/openclaw.json` 里为你加了：

- **兜底模型**：`ollama/qwen2.5-coder:7b`（在 Google 三个模型之后）
- **可选模型**：`ollama/qwen2.5-coder:7b` 出现在模型列表里

即：**先用 Gemini → 额度用完后自动切到本机 Ollama**，无额外 token 限制。

你先执行 `ollama pull qwen2.5-coder:7b`，再在终端里 `export OLLAMA_API_KEY=ollama-local` 并重启/启动 OpenClaw，然后在界面里选模型或等自动 fallback 即可。

---

## 五、换用别的 Ollama 模型

若你拉的是别的型号（例如 `llama3.2:3b` 或 `qwen2.5-coder:32b`），在 OpenClaw 里把默认/兜底改成对应 id 即可，例如：

- `ollama/llama3.2:3b`
- `ollama/qwen2.5-coder:32b`

id 以 `ollama list` 显示的名字为准，格式为 `ollama/<名字>:<标签>`。

---

## 六、验证

```bash
ollama list
openclaw models list   # 应能看到 ollama/... 模型
openclaw status
```

在 Control UI 里把模型选成 `ollama/qwen2.5-coder:7b` 发一条消息，能回复即表示本地模型已接通。
