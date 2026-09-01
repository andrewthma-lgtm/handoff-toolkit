#!/bin/bash
# 在 Mac 上執行：建立 handoff-toolkit 並 push 到 GitHub
# 用法: bash scripts/install-and-push-github.sh

set -euo pipefail

GITHUB_URL="${1:-https://github.com/andrewthma-lgtm/handoff-toolkit.git}"
INSTALL_DIR="$HOME/Projects/handoff-toolkit"

echo "→ 目標: $GITHUB_URL"
echo "→ 安裝目錄: $INSTALL_DIR"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "目錄已存在，進入並 pull"
  cd "$INSTALL_DIR"
  git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  if git ls-remote "$GITHUB_URL" HEAD &>/dev/null; then
    git clone "$GITHUB_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
  else
    echo "⚠ 遠端 repo 不存在或無法存取，請先到 GitHub 建立空 repo"
    echo "  https://github.com/new  → 名稱 handoff-toolkit"
    exit 1
  fi
fi

if [[ ! -f scripts/handoff.sh ]]; then
  echo "⚠ repo 是空的，請在 Cursor Cloud Agents → Preferences → Repository"
  echo "  選擇 handoff-toolkit，然後請 Agent push 程式碼"
  echo "  或從已設定好的機器 git pull"
  exit 1
fi

chmod +x scripts/handoff.sh
./scripts/handoff.sh init
source ~/.handoff-env 2>/dev/null || true
./scripts/handoff.sh status

echo ""
echo "✓ 安裝完成"
echo "  日常使用: cd $INSTALL_DIR && git pull && ./scripts/handoff.sh load"
