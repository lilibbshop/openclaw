# OpenClaw 技能安装与配置 — 族谱 OCR、小红书、公众号、自我学习、搜索、热门

本说明覆盖：**族谱图片/扫描件 OCR**、**小红书/微信公众号运营**、**自我学习与持续改进**、**搜索与深度调研**、**热门通用技能**。

---

## 一、一键安装（推荐）

在项目目录下执行：

```bash
# 若未登录 ClawHub，先执行一次
clawhub login
clawhub whoami

# 执行一键安装脚本
chmod +x install_openclaw_skills.sh
./install_openclaw_skills.sh
```

或手动按需安装（见下一节）。

---

## 二、安装的技能清单

### 族谱 / OCR（图片 → 可编辑族谱书）

| 技能 | 命令 | 说明 |
|------|------|------|
| **image-ocr** | `clawhub install image-ocr` | 图片 OCR，适合族谱照片、单页扫描 |
| **pdf-ocr-tool** | `clawhub install pdf-ocr-tool` | 扫描版 PDF OCR，适合整本族谱扫描件批量转文字 |
| **smar** (smart_ocr) | `clawhub install smar` | 多语言/手写增强 OCR |

**典型用法**：把族谱图片或扫描 PDF 给 OpenClaw，说「用 image-ocr / pdf-ocr-tool 把这几页识别成文字，按世系整理成一份族谱文档」。

### 小红书运营

| 技能 | 命令 | 说明 |
|------|------|------|
| **xiaohongshu-publish** | `clawhub install xiaohongshu-publish` | 小红书长文发布 |
| **xiaohongshu-mcporter-publish** | `clawhub install xiaohongshu-mcporter-publish` | 小红书图文发布 |
| **xiaohongshu-mcp** | `clawhub install xiaohongshu-mcp` | 小红书自动化（笔记、分析等） |

**典型用法**：用 xiaohongshu-publish / xiaohongshu-mcporter-publish 发长文或图文；用 xiaohongshu-mcp 做笔记与数据分析（注意合规）。

### 微信公众号运营

| 技能 | 命令 | 说明 |
|------|------|------|
| **wechat-article-search** | `clawhub install wechat-article-search` | 搜索公众号文章，做选题与参考 |
| **wechat-mp-cn** | `clawhub install wechat-mp-cn` | 微信公众号（MP）中文运营 |

**典型用法**：用 wechat-article-search 找同领域文章；用 wechat-mp-cn 做公众号内容与发布（需配置公众号权限）。

### 自我学习 / 持续改进

| 技能 | 说明 |
|------|------|
| **self-improving-agent** | 捕获错误与用户纠正，持续改进（失败时、用户说「不对」时、发现更好做法时自动记录） |
| **find-skills** | 用户问「怎么做 X」「有没有能做 X 的 skill」时，发现并推荐可安装技能 |
| **proactive-agent** | 主动式 Agent、WAL 协议、定时任务，从「等指令」变为「主动推进」 |

### 搜索与调研

| 技能 | 说明 |
|------|------|
| **tavily-search** | AI 优化网页搜索（需 Tavily API Key，结果适合 LLM 消费） |
| **brave-search** | Brave 搜索 API，无需浏览器 |
| **multi-search-engine** | 17 引擎（8 国内+9 国际），无需 API Key |
| **summarize** | 总结 URL/文件：网页、PDF、图片、音频、YouTube |
| **deep-research-pro** | 多源深度调研，带引用报告，无需 API Key |

### 热门通用

| 技能 | 说明 |
|------|------|
| **github** | GitHub `gh` CLI：issue、PR、CI、api |
| **agent-browser** | 无头浏览器自动化（导航、点击、快照） |
| **skill-vetter** | 安装任意 skill 前做安全审计，检查可疑模式 |
| **clawdhub** | ClawHub CLI：搜索/安装/更新/发布 skill |
| **markdown-converter** | 文档转 Markdown（PDF/Word/Excel/图片等） |
| **weather** | 天气查询，无需 API Key |

---

## 三、让 OpenClaw 识别这些技能（重点）

这些通过 `clawhub install` 安装的都是 **skills，不是 plugins**，它们会从你的 workspace 自动加载，**不需要**也**不应该**写进 `plugins.allow`。

- 你当前已经在 `~/.openclaw/openclaw.json` 里配置了：
  ```json
  "skills": {
    "load": {
      "extraDirs": [
        "/Users/ian/.openclaw/workspace/skills"
      ]
    }
  }
  ```
- 上面这个目录就是刚才脚本安装所有 skill 的位置，所以 **OpenClaw 会自动发现并加载这些 skills**。
- `plugins.allow` 是给像 `feishu` 这种 **内置插件** 用的，不能把 skill 名称（如 `image-ocr`、`tavily-search`）放进去，否则就会出现你刚看到的 `plugin not found` 错误。

因此：

- **保持 `plugins.allow` 里只放真正的插件**（目前保留 `feishu` 即可）。
- skill 相关的白名单/控制，按需在 OpenClaw 的「工具/skills 设置界面」里管理即可，不再手动改 JSON。
- **技能目录**：只认 `extraDirs` 里的目录（你当前是 `~/.openclaw/workspace/skills`）。不要把技能装到或写到 `~/.openclaw/skills`（没有 workspace），否则不会被加载。

---

## 四、对话时怎么说（让 OpenClaw 用对技能）

- **族谱 OCR**  
  「用 image-ocr 把这张族谱图片识别成文字，按世系整理成一份族谱文档。」  
  或：「用 pdf-ocr-tool 把这本族谱扫描 PDF 转成可编辑文字，保留章节结构。」

- **小红书**  
  「用 xiaohongshu-publish 发这篇长文到小红书。」  
  或：「用 xiaohongshu-mcp 查一下 [某类] 笔记的热门标题，给我做一份选题建议。」

- **微信公众号**  
  「用 wechat-article-search 搜一下 [某主题] 的公众号文章，整理 5 篇参考。」  
  「用 wechat-mp-cn 把这份内容发到公众号草稿箱。」

- **自我学习 / 搜索**  
  自我改进会在失败或你纠正时自动记录；可以说「有没有能做 XXX 的 skill」让 find-skills 推荐；说「用 multi-search-engine / deep-research-pro 调研一下 [主题]」。

若 OpenClaw 说「没有工具」：回复「请先列出你当前可用的工具名称」，确认上述技能是否在列表中；若不在，检查 `plugins.allow`、**技能目录是否在 extraDirs** 与重启是否生效。部分技能（如 xiaohongshu-publish）仅有 SKILL.md 说明、不提供可调用工具名，AI 会按 SKILL 里的步骤用浏览器等现有工具完成，可直接说「按小红书长文发布技能的步骤，用浏览器帮我发一篇…」。

**重要**：搜索/安装技能时使用内置工具 **`clawhub`**。若出现「Tool clawhub not found」或「没有找到 clawhub 工具」：
1. **路径**：OpenClaw 只从 `skills.load.extraDirs` 加载技能，你当前配置的是 **`/Users/ian/.openclaw/workspace/skills`**。技能必须装在这个目录（用 `clawhub install xxx` 会装到这里）；若技能被装到或误写到 **`~/.openclaw/skills`**（没有 `workspace`），则**不会被加载**，请勿使用该路径。
2. **clawhub 工具**：该工具由 **clawdhub** 技能提供。若 `openclaw.json` 里 `skills.entries.clawdhub.enabled` 为 `false`，会报「Tool clawhub not found」，请改为 `true` 并重启 Gateway。
3. **会话**：工具列表在会话创建时确定。修改配置或安装新技能后，需**重启 OpenClaw Gateway**，并**新开一个会话**再试，旧会话内仍可能提示找不到工具。
4. **飞书**：在飞书里要和机器人「新开一个会话」= **新开一个对话/新聊天**，而不是在同一条对话里继续回复；否则工具列表仍是旧的，会一直报「找不到 clawhub / xiaohongshu-publish」。

### AI 能自己安装技能吗？

- **只有当当前会话里已经能看到 `clawhub` 工具时**，AI 才能通过调用该工具帮你执行 `clawhub search` / `clawhub install`，相当于「自己安装」。
- 若当前会话里**看不到** clawhub（例如飞书里没新开会话、或 clawdhub 技能被关掉），AI **无法**自己安装技能；只能由你**在本机终端**执行 `clawhub install xxx`，安装完成后**重启 Gateway**，并在**飞书里新开一个对话**再试。
- **xiaohongshu-publish**：该技能只有 SKILL.md 说明，**没有**名为 `xiaohongshu-publish` 的可调用工具。AI 应通过阅读该技能的 SKILL.md，用**浏览器**（或 agent-browser）按步骤完成发布；用户可以说「按小红书长文发布技能的步骤，用浏览器帮我发一篇关于天赋测试的给宝妈看的文章」。

---

## 五、小结

| 场景 | 安装的技能 |
|------|------------|
| 族谱 OCR | image-ocr, pdf-ocr-tool, smar |
| 小红书/公众号 | xiaohongshu-*, wechat-article-search, wechat-mp-cn |
| 自我学习 | self-improving-agent, find-skills, proactive-agent |
| 搜索/调研 | tavily-search, brave-search, multi-search-engine, summarize, deep-research-pro |
| 热门通用 | github, agent-browser, skill-vetter, clawdhub, markdown-converter, weather |

安装用 **`./install_openclaw_skills.sh`** 即可；skills 会从 **`/Users/ian/.openclaw/workspace/skills`** 自动加载。重启 OpenClaw 后，在对话里**明确说「用 xxx 技能做 xxx」**即可。
