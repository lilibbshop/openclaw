# OpenClaw 模型与 API 配置说明

## Google 免费 API（兜底）

- **用途**：主模型（硅基流动）不可用或限流时，自动回退到 Google Gemini；高级任务可选用 Gemini 3。
- **认证**：在网关环境或 `~/.openclaw/.env` 中设置 **`GEMINI_API_KEY`**（在 [Google AI Studio](https://aistudio.google.com/apikey) 创建）。
- **已配置**：
  - **对话兜底**：`agents.defaults.model.fallbacks` 末尾为 `google/gemini-2.5-flash`、`google/gemini-3-flash-preview`、`google/gemini-3-pro-preview`。
  - **语音转文本**：`tools.media.audio.models` 使用 Google Gemini（`gemini-2.5-flash`、`gemini-3-flash-preview`），免费额度内可用。

## 硅基流动免费 API（主用 + 扩展）

- **主对话 / 推理**：Qwen3-8B、DeepSeek-R1、GLM-4-9B、Qwen2.5-7B 等（见 `models.providers.siliconflow.models`）。
- **已增扩展**（与 `yinsight/y-server/services/ModelManager.js` 对齐）：
  - **翻译**：`siliconflow/tencent/Hunyuan-MT-7B`（腾讯混元翻译，免费）。
  - **视觉 / OCR**：`siliconflow/deepseek-ai/DeepSeek-OCR`、`siliconflow/THUDM/GLM-4.1V-9B-Thinking`（图文理解、文档识别）。
- **画图**：硅基流动侧有 **Kolors**（`Kwai-Kolors/Kolors`）等免费生图能力，需走 `/v1/images/generations` 类接口；当前 OpenClaw 主配置为对话/推理/翻译/视觉，生图可后续通过 Skill 或自定义工具对接该端点。

## 小结

| 能力         | 主用                     | 兜底 / 补充                    |
|--------------|--------------------------|-------------------------------|
| 对话 / 推理  | 硅基流动（Qwen/DeepSeek/GLM） | Google Gemini 2.5/3 Flash、Pro |
| 语音转文本   | Google Gemini           | -                             |
| 翻译         | 硅基流动 Hunyuan-MT-7B   | -                             |
| 视觉 / OCR   | 硅基流动 DeepSeek-OCR、GLM-4.1V | -                             |

确保已设置 **`GEMINI_API_KEY`** 后重启网关，Google 兜底与语音转文本即可生效。
