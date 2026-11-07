#!/usr/bin/env bash
# 一键部署：取上游源码 -> 打中国网络补丁 -> 拉镜像 -> 起容器
set -euo pipefail
cd "$(dirname "$0")/.."

UPSTREAM_REPO="P-Adamiec/Free-Games-Claimer-Remaster"
IMAGE="ghcr.io/p-adamiec/free-games-claimer-remaster:latest"
MIRROR_IMAGE="ghcr.nju.edu.cn/p-adamiec/free-games-claimer-remaster:latest"

echo "==> 1/5 检查 Docker daemon"
docker info --format '{{.ServerVersion}}' >/dev/null 2>&1 \
  || { echo "Docker 没运行，先启动 Docker Desktop（或 colima start）"; exit 1; }

echo "==> 2/5 取上游源码"
if [ ! -f src/stores/epic.py ]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/up.tar.gz" "https://api.github.com/repos/${UPSTREAM_REPO}/tarball/main"
  mkdir -p "$tmp/x"
  tar xzf "$tmp/up.tar.gz" -C "$tmp/x" --strip-components=1
  rm -rf src
  cp -R "$tmp/x/src" src
  rm -rf "$tmp"
  echo "    src/ 已就位"
else
  echo "    src/ 已存在，跳过下载"
fi

echo "==> 3/5 应用补丁"
if grep -q "pageText.includes" src/stores/epic.py 2>/dev/null; then
  echo "    补丁已应用，跳过"
else
  patch -p1 < patches/epic-cn-cloudflare.patch
fi

echo "==> 4/5 准备 .env"
if [ -f .env ]; then
  echo "    .env 已存在，保持不动"
else
  cp .env.example .env
  echo "    已从 .env.example 生成"
fi

echo "==> 5/5 拉镜像并启动"
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  if docker pull "$MIRROR_IMAGE"; then
    docker tag "$MIRROR_IMAGE" "$IMAGE"
  else
    echo "    镜像源不可用，直连 ghcr.io 拉取（可能很慢）"
    docker pull "$IMAGE"
  fi
fi
docker compose up -d --no-build
docker ps --filter name=fgc-remaster --format '    {{.Names}}  {{.Status}}  {{.Ports}}'

PORT="$(grep -E '^NOVNC_PORT=' .env | cut -d= -f2)"
echo
echo "下一步：浏览器打开 http://localhost:${PORT:-7080}/?autoconnect=true 登录 Epic"
echo "看日志：docker logs -f fgc-remaster"
