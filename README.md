# Epic 每周免费游戏 · 中国大陆网络 Docker 版

在 Docker 里自动领取 Epic 每周免费游戏，并修掉**中国大陆 IP 被 Cloudflare 拦在页面上、导致「找不到领取按钮」**的问题。

上游项目：[P-Adamiec/Free-Games-Claimer-Remaster](https://github.com/P-Adamiec/Free-Games-Claimer-Remaster)（Python + 反检测 Chromium + noVNC）。
本仓库只做两件事：一份补丁，一份开箱即用的 compose 与一键脚本。

## 为什么需要补丁

从中国大陆家宽 IP 访问 `store.epicgames.com`，**每个商品页都会先撞 Cloudflare Turnstile**。浏览器能过，但页面要 20~45 秒才把右侧的 `Get` 按钮渲染出来。

上游 v1.18 的 `_page_state()` 只等 15 秒就判定页面没有按钮：

```
Page state for flotsam-266287: button='' flow=unknown
WARNING  No purchase/claim button found for 'Flotsam'.
```

结果就是：6 个免费游戏全部失败，领取数 0。

补丁改了三处（`patches/epic-cn-cloudflare.patch`）：

1. `_page_state` 等待从 15 秒放宽到 45 秒，并在第 5、15 秒检查是否出现 Cloudflare 挑战，出现就等它自动通过后再继续读。
2. `_open_game_page` 打开页面后的等待从 4 秒改到 7 秒。
3. 区服不可用判断从只看 `<h1>` 改成看整页可见文本，`This content is currently unavailable in your platform or region.` 这类页面会正确归为 `skipped:region`，不再每周重试。

补丁通过 compose 把 `./src/stores` 挂进容器生效，上游镜像不用重新构建。

## 快速开始

需要 Docker（Docker Desktop / colima / podman 都行）。

```bash
git clone https://github.com/hjtr7mymht-dot/epic-claimer-cn.git
cd epic-claimer-cn
bash scripts/setup.sh
```

脚本会：检查 Docker → 从 GitHub 取上游源码到 `src/` → 打补丁 → 生成 `.env` → 拉镜像（国内默认走 `ghcr.nju.edu.cn` 南大源再 tag 回 ghcr.io）→ 起容器。

想手动来也可以：

```bash
docker compose up -d --no-build
```

### 首次登录

浏览器打开 <http://localhost:7080/?autoconnect=true>，在容器里的 Chromium 里正常登录 Epic。登录态保存在 `fgc_data` 卷里，之后不用再登。

不填账号密码也可以，这是推荐做法——凭据不会明文落到 `.env` 里。

## 实测

2026-11-07，中国大陆移动家宽，`STORES=epic`：

```
✓ Claimed 'Flotsam' successfully!
✓ Claimed 'GMH - Good Morning Human' successfully!
✓ Claimed 'Highway Driving' successfully!
✓ Claimed 'Dark Mystery' successfully!
✓ Claimed 'Horse Racing' successfully!
✓ Claimed 'Epic World - Hunt For Quest' successfully!
✓ Claimed 'Quiztopia : The Ultimate Trivia' successfully!
✓ Claimed 'Idle Champions of the Forgotten Realms (Android)' successfully!
✓ Claimed 'Idle Champions of the Forgotten Realms (iOS)' successfully!
'Chants of Sennaar (Android)' is not available in your region on Epic, skipping.
```

一轮 9 款进库。补丁前同一环境是 0 领取。

## 常见问题

**noVNC 打开是黑屏** — 一轮跑完浏览器会自己关掉，正常。等下一轮或 `docker restart fgc-remaster` 立刻跑一轮。

**日志里出现 `behind a Cloudflare / captcha human-check`** — 机器人会在 VNC 里等你点一下复选框，`VNC_LOGIN_TIMEOUT`（默认 1200 秒）内有效，过了它自己继续领。

**每轮开头卡好几分钟** — 容器访问 `gamerpower.com` 常超时，它在逐个尝试额外 giveaway。只影响额外发现，不影响 Epic 本体。

**手机版领不到** — Epic 手机 SKU（Android/iOS 分开）在中国区大量是「currently unavailable in your platform or region」，属正常，跳过即可。

**想改频率** — `.env` 里 `SCHEDULER_HOURS=12`（默认 12 小时一轮），或 `SCHEDULER_HOURS=0` + `SCHEDULER_FIXED_TIMES=23:30` 改成每天/每周固定时间。改完 `docker compose up -d --force-recreate`。

**别删 `fgc_data` 卷** — 登录态和浏览器 profile 在里面，新 profile 更容易被 Cloudflare 盯上。

## 原理

Epic 对「领取免费游戏」强制了人机校验，早期只调 GraphQL 接口的方案（如 epicgames-freebies-claimer）已经失效。现在必须在真浏览器里点 `Get` → `Add to library` 走结账流程。

上游用 nodriver 驱动打了反检测补丁的 Chromium，所以能做的不是绕过校验，而是**等对时间、认对页面**。

## 许可

AGPL-3.0，与上游一致。本仓库不包含上游完整源码，`scripts/setup.sh` 在部署时从上游获取；补丁与部署文件同样以 AGPL-3.0 发布。来源与版权说明见 [NOTICE.md](NOTICE.md)。
