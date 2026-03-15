# Mac 作为 OpenClaw / Codex 远程节点：合盖不眠 + 屏幕可关省电

目标：**合上盖子后 Mac 不睡眠，进程和网络继续跑；屏幕可以关闭以省电、延长寿命。**

---

## 一、原则（你要的效果）

| 项目         | 目标                         |
|--------------|------------------------------|
| 合盖         | **不睡眠**（插电时）         |
| 系统 / 进程  | **一直运行**                 |
| 网络 / SSH   | **保持连接**                 |
| 屏幕         | **可以关闭**（省电、护屏）   |

---

## 二、推荐配置（按顺序做）

### 1. 插电

MacBook **必须接电源**。仅用电池时，合盖仍可能睡眠，无法仅靠软件彻底避免。

### 2. 系统级电源：pmset（可选但推荐）

让系统/磁盘不休眠、屏幕过一会儿自动关、网络保持：

```bash
cd /Users/ian/openclaw/scripts/mac-remote-node
chmod +x set_pmset_remote_node.sh
./set_pmset_remote_node.sh
```

会设置：

- `sleep 0`、`disksleep 0`：系统、磁盘不休眠  
- `displaysleep 2`：约 2 分钟后关屏（可改脚本里的数字）  
- `tcpkeepalive 1`：保持网络，SSH 不易断  

**屏幕可以关、系统不会睡**，符合你「AI 控制、不需要长亮屏」的需求。

### 3. 合盖不眠：二选一

#### 方式 A：caffeinate（本仓库脚本，推荐）

**不加 `-d`**，所以只防系统/磁盘休眠，**允许关屏**：

```bash
cd /Users/ian/openclaw/scripts/mac-remote-node
chmod +x start_caffeinate.sh
./start_caffeinate.sh
```

- 已运行会提示，不重复起多个  
- 停止：`kill $(cat ~/.caffeinate_remote_node.pid)`  
- 查看：`ps aux | grep caffeinate`  

#### 方式 B：Amphetamine（App Store）

1. 安装 **Amphetamine**  
2. 勾选：**Prevent system sleep**  
3. **不要**勾选「Allow system sleep when display closed」  
4. 触发器选 **Indefinitely**  

系统不睡；显示器仍可按系统设置或手动关屏。

### 4. 远程登录：开启 SSH

- **系统设置 → 通用 → 共享 → 远程登录** 打开  
- 本机可：`ssh $(whoami)@localhost`  
- 同一局域网：`ssh 你的用户名@Mac的IP`  

方便手机/Codex/其他机器连到这台 Mac。

### 5. 长期任务建议用 tmux

合盖、锁屏、断 SSH 后进程仍可在后台跑：

```bash
tmux new -s openclaw
# 在 tmux 里运行 OpenClaw / 其他服务
# 断开会话: Ctrl+B 然后 D
# 重连: tmux attach -t openclaw
```

---

## 三、本仓库脚本说明

| 文件 | 作用 |
|------|------|
| `scripts/mac-remote-node/setup_all.sh` | **一键配置**：依次执行 pmset + caffeinate |
| `scripts/mac-remote-node/set_pmset_remote_node.sh` | 设置 pmset（系统不眠、2 分钟关屏、tcpkeepalive），需 sudo |
| `scripts/mac-remote-node/start_caffeinate.sh` | 后台运行 `caffeinate -imsu`（不包含 -d，允许关屏） |
| `scripts/mac-remote-node/start_tmux_work.sh` | 启动 tmux 工作会话，长期任务放这里跑 |
| `scripts/mac-remote-node/install-on-login.sh` | **开机自启**：caffeinate + 传家纪 DB 隧道 + 微信发布 |
| `scripts/mac-remote-node/restart_services.sh` | 重启所有长期服务 |

---

## 四、恢复默认（不用作远程节点时）

```bash
sudo pmset -a sleep 10
sudo pmset -a displaysleep 10
sudo pmset -a disksleep 10
kill $(cat ~/.caffeinate_remote_node.pid) 2>/dev/null
```

若用 Amphetamine，在应用里关掉「Prevent system sleep」即可。

---

## 五、小结（你要的最优设置）

1. **插电**  
2. 运行 **`set_pmset_remote_node.sh`**（pmset：不眠 + 2 分钟关屏 + tcpkeepalive）  
3. 运行 **`start_caffeinate.sh`** 或 使用 **Amphetamine**（合盖不眠）  
4. 开启 **远程登录（SSH）**  
5. 长期任务放在 **tmux** 里跑  

这样：**合盖不眠、屏幕可关省电、SSH 和 OpenClaw/Codex 可持续运行。**

---

## 六、你的场景：OpenClaw + 远程控制 + 自动发布小程序

针对「跑 OpenClaw、远程控制、已有小程序自动发布脚本」这几类需求，**合盖不眠用哪种方式最合适**：

| 方式 | 结论 |
|------|------|
| **caffeinate（本仓库脚本）** | **最合适**：无需装 App、脚本已有、不加 `-d` 允许关屏省电；配合 pmset 一次设置，重启后补跑一次脚本即可。 |
| Amphetamine | 可以，适合喜欢图形开关的人；与 caffeinate 二选一即可。 |
| 仅 pmset | 不够：合盖仍可能睡，需配合 caffeinate 或 Amphetamine。 |

推荐：**pmset + caffeinate（脚本） + SSH + tmux**，不依赖第三方 App。
