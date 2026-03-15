# OpenClaw 股票监控 + 深度分析 + 飞书推送 — 实现指南

## 一、为什么 OpenClaw 对话里说「做不到」？

- **OpenClaw 不能替你「搜索并安装」skill**  
  它没有内置「去 ClawHub/GitHub 搜索并执行 `clawhub install`」的能力，只能使用**你已经在本机安装好**的 skill。  
  所以：**装 skill 这一步必须由你在自己电脑上完成。**

- **没有装股票/财经类 skill 时**  
  它就没有获取行情、财报、技术指标的工具，只能基于你粘贴的文字做摘要，无法「自己查数据、做深度分析」。

- **飞书推送**  
  你已配置飞书通道；要「写飞书表格 + 发飞书消息」，需要对应 skill 已安装并被允许使用（例如飞书多维表格、发消息等）。

---

## 二、你要做的三步（按顺序）

### 第 1 步：在本机安装这些 skill（你执行一次即可）

在终端执行（先登录 ClawHub，再安装）：

```bash
# 登录 ClawHub（按提示在浏览器完成）
clawhub login
clawhub whoami

# 美股/行情/基础分析（无需 API Key，推荐先装）
clawhub install yahoo-finance

# 可选：更专业的行情与技术指标（需在 alphavantage.co 申请免费 API Key）
# clawhub install alpha-vantage

# 飞书：你已有 feishu 通道；若需要「发消息到指定群/人」或「写多维表格」，可再装：
# clawhub search feishu
# clawhub install feishu-send-message   # 或 feishu-im / feishu-power-skill
```

安装后确认：

```bash
clawhub list
```

说明：

- **yahoo-finance**：美股、ETF、部分指数；A 股需用 `.SS` / `.SZ` 后缀（如 `600000.SS`），且大陆访问 Yahoo 可能需要代理。
- **alpha-vantage**：需免费 API Key，数据更全、技术指标多，适合「深度分析」。
- 飞书相关 skill 按需安装，和你现有飞书通道配合使用。

### 第 2 步：在 OpenClaw 里允许这些 skill

在配置里做**显式白名单**（避免未审核插件自动加载）：

- 打开 OpenClaw 的配置（例如 `~/.openclaw/openclaw.json` 或控制台里的设置）。
- 找到 `plugins.allow`（或技能白名单），把你要用的 skill id 加进去，例如：
  - `yahoo-finance`
  - `alpha-vantage`（若装了）
  - `feishu`、`feishu-send-message` 等（按实际安装的 id 填）。

保存后重启 OpenClaw / 重新打开对话，让新 skill 生效。

### 第 3 步：给 OpenClaw 明确的「人设 + 任务说明」

这样它才知道：**一被问到投资/股票，就要用这些 skill，并推送到飞书**。

已经在你的工作区里加了说明：

- **~/.openclaw/workspace/USER.md**  
  写入了你的关注板块（能源、AI、芯片、机器人、航空）和「用飞书表格 + 飞书消息推送」的偏好。
- **~/.openclaw/workspace/TOOLS.md**  
  写入了「做股票分析时要用哪些 skill、按什么流程、输出到哪里」。

你只需在对话里**明确说一次**（例如）：

- 「用你有的 yahoo-finance（和 alpha-vantage，如果装了）查能源、AI、芯片、机器人、航空相关标的，做一轮深度分析，把结论写进飞书表格并给我飞书推送一条摘要。」

之后每次类似需求，都可以用这句话或缩短版（如「按老规矩做一次美股+A股板块分析并推送到飞书」）。

---

## 三、和 OpenClaw 对话时的「标准话术」建议

装好 skill 并配置好后，你可以这样说：

1. **一次性说明任务（推荐先说一次）**  
   「我关注能源、AI、芯片、机器人、航空。请你用 yahoo-finance（和 alpha-vantage）查这些板块里值得看的标的，做深度分析，把结果写进飞书表格，并给我飞书发一条摘要。」

2. **之后简化**  
   「按之前说的，再跑一遍板块分析并推送到飞书。」

3. **指定范围**  
   「只分析美股里的 AI 和芯片，结论推送到飞书。」

4. **若它还说「没有工具」**  
   回复：「请先检查你当前可用的工具里有没有 yahoo-finance（或 alpha-vantage、feishu）。如果有，就用它们完成上述任务；如果没有，请告诉我你当前能看到哪些工具名称。」

---

## 四、可选：定期自动分析 + 推送

若希望「定期」跑分析并推送：

- **方式 A**：用系统定时任务（cron/launchd）定期执行一条命令，用 OpenClaw CLI 触发一次「分析并推送」任务（若 OpenClaw 支持 CLI 触发指定任务）。
- **方式 B**：在 OpenClaw 的 **HEARTBEAT** 里配置周期性任务（若支持），例如「每工作日 9:00 检查能源、AI、芯片、机器人、航空板块并推送摘要到飞书」。

具体可查官方文档：Agent 定时/心跳任务配置。

---

## 五、小结

| 谁来做 | 做什么 |
|--------|--------|
| **你** | 本机执行 `clawhub login` 和 `clawhub install yahoo-finance`（及可选 alpha-vantage、飞书 skill）。 |
| **你** | 在 OpenClaw 配置里把用到的 skill 加入 `plugins.allow`。 |
| **你** | 在对话里明确说：用这些 skill 做能源/AI/芯片/机器人/航空的深度分析，并推送到飞书表格 + 飞书消息。 |
| **OpenClaw** | 在 skill 已安装且被允许的前提下，按你的说明调用 yahoo-finance/alpha-vantage 和飞书 skill，完成分析和推送。 |

按上述三步做完后，再按「标准话术」和 OpenClaw 对话，就可以实现：**监控美股和 A 股里你关心的板块 → 深度分析 → 飞书表格 + 飞书推送**。若某一步执行报错，把报错贴出来可以再针对性改。
