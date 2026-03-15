#!/usr/bin/env bash
# OpenClaw 技能一键安装脚本
# 用途：族谱图片 OCR、小红书运营、微信公众号运营 + 常用通用技能
# 使用：在终端执行 ./install_openclaw_skills.sh 或 bash install_openclaw_skills.sh

set -e

echo "=========================================="
echo "  OpenClaw Skills 安装（OCR/小红书/公众号 + 自我学习 + 搜索 + 热门）"
echo "=========================================="

# 检查 clawhub 是否已安装
if ! command -v clawhub &> /dev/null; then
    echo "未检测到 clawhub，请先安装："
    echo "  npm i -g clawhub"
    exit 1
fi

# 建议先登录（若未登录，部分 install 可能失败）
echo ""
echo ">>> 请确保已登录 ClawHub（若未登录会提示）："
clawhub whoami 2>/dev/null || true
echo "若未登录，请先执行: clawhub login"
echo ""

# ---------- 1. 族谱 / OCR 相关 ----------
echo ">>> [1/6] 安装 OCR / 族谱相关技能..."
clawhub install image-ocr --force       # 图片 OCR，适合族谱照片、单页扫描
clawhub install pdf-ocr-tool --force    # 扫描版 PDF OCR
clawhub install smar --force            # smart_ocr，多语言/手写增强

# ---------- 2. 小红书运营 ----------
echo ""
echo ">>> [2/6] 安装小红书运营技能..."
clawhub install xiaohongshu-publish --force
clawhub install xiaohongshu-mcporter-publish --force
clawhub install xiaohongshu-mcp --force

# ---------- 3. 微信公众号运营 ----------
echo ""
echo ">>> [3/6] 安装微信公众号运营技能..."
clawhub install wechat-article-search --force
clawhub install wechat-mp-cn --force

# ---------- 4. 自我学习 / 持续改进 ----------
echo ""
echo ">>> [4/6] 安装自我学习与持续改进技能..."
clawhub install self-improving-agent --force   # 捕获错误与纠正，持续改进（97k 下载）
clawhub install find-skills --force            # 发现并安装新技能，用户问「怎么做 X」时找 skill
clawhub install proactive-agent --force        # 主动式 Agent、WAL、定时任务（52k 下载）

# ---------- 5. 搜索技能 ----------
echo ""
echo ">>> [5/6] 安装搜索与调研技能..."
clawhub install tavily-search --force          # AI 优化网页搜索（Tavily API，82k 下载）
clawhub install brave-search --force           # Brave 搜索 API，无需浏览器
clawhub install multi-search-engine --force    # 17 引擎（8 国内+9 国际），无需 API Key
clawhub install summarize --force              # 总结 URL/文件（网页、PDF、图片、音频、YouTube）
clawhub install deep-research-pro --force      # 多源深度调研，无需 API Key

# ---------- 6. 热门通用 ----------
echo ""
echo ">>> [6/6] 安装热门通用技能..."
clawhub install github --force                 # GitHub gh CLI（issue、PR、CI、api）
clawhub install agent-browser --force         # 无头浏览器自动化（导航、点击、快照）
clawhub install skill-vetter --force          # 安装前安全审计，检查可疑 skill
clawhub install clawdhub --force              # ClawHub CLI：搜索/安装/更新/发布 skill
clawhub install markdown-converter --force    # 文档转 Markdown（PDF/Word/Excel/图片等）
clawhub install weather --force               # 天气查询，无需 API Key

echo ""
echo "=========================================="
echo "  安装完成。请执行以下操作："
echo "  1. 运行 clawhub list 查看已安装技能"
echo "  2. 在 OpenClaw 配置中把上述技能加入 plugins.allow"
echo "  3. 参考 OPENCLAW_Skills_安装与配置.md 配置白名单与用法"
echo "=========================================="
clawhub list
