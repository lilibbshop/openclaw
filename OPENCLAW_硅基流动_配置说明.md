# OpenClaw 使用硅基流动免费额度

已为你在 OpenClaw 里加好 **硅基流动（SiliconFlow）** 提供商，使用你在平台上的免费模型额度。

---

## 一、已写入的配置

在 **`~/.openclaw/openclaw.json`** 中已添加：

1. **models.providers.siliconflow**
   - **baseUrl**：`https://api.siliconflow.cn/v1`（官方 OpenAI 兼容接口）
   - **api**：`openai-completions`
   - **models**：已配置 3 个常用模型：
     - `Qwen/Qwen2.5-72B-Instruct`（通义千问 2.5 72B）
     - `deepseek-ai/DeepSeek-V3`
     - `deepseek-ai/DeepSeek-R1`（推理模型）

2. **agents.defaults.model**
   - **fallbacks** 中已加入硅基流动模型（在 Google 之后、Ollama 之前）：
     - `siliconflow/Qwen/Qwen2.5-72B-Instruct`
     - `siliconflow/deepseek-ai/DeepSeek-V3`
   - **models** 列表里也加入了上述两个，便于在 Control UI 里直接选择。

---

## 二、你需要做的：填 API Key

1. **获取 API Key**  
   登录 [硅基流动控制台](https://cloud.siliconflow.cn/account/ak) → 新建 API 密钥，复制 `sk-...`。

2. **二选一**：

   **方式 A：环境变量（推荐）**  
   在 `~/.zshrc` 里加一行（把下面的 key 换成你的）：

   ```bash
   export SILICONFLOW_API_KEY="sk-你的硅基流动API密钥"
   ```

   保存后执行 `source ~/.zshrc`，再从终端启动 OpenClaw / gateway。

   **方式 B：直接写在配置里**  
   若 OpenClaw 未解析 `${SILICONFLOW_API_KEY}`，可改为在 `openclaw.json` 里写死 key：

   找到 `"apiKey": "${SILICONFLOW_API_KEY}"`，改成：

   ```json
   "apiKey": "sk-你的硅基流动API密钥"
   ```

   （注意不要将含 key 的配置文件提交到公开仓库。）

---

## 三、使用方式

- **自动兜底**：当 Google 额度用尽或失败时，会按顺序尝试硅基流动（72B / DeepSeek-V3），再尝试 Ollama。
- **手动选模型**：在 OpenClaw Control UI 里把模型选成 `siliconflow/Qwen/Qwen2.5-72B-Instruct` 或 `siliconflow/deepseek-ai/DeepSeek-V3` 即可用你的免费额度。

---

## 四、更多模型

硅基流动其他模型可在 [模型广场](https://cloud.siliconflow.cn/models) 查看；要加到 OpenClaw：

1. 在 `models.providers.siliconflow.models` 里增加一项，例如：
   ```json
   { "id": "厂商/模型名", "name": "显示名", "contextWindow": 数字, "input": ["text"] }
   ```
2. 在 `agents.defaults.models` 里加上 `"siliconflow/厂商/模型名": {}`，需要兜底时再在 `fallbacks` 里加上同名的 `siliconflow/厂商/模型名`。

配置改完后重启 OpenClaw 或 gateway 使配置生效。
