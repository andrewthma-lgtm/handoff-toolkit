#!/bin/bash
# 在 Mac 上一鍵建立 handoff-toolkit（無需先 git clone）
# 用法: bash bootstrap-local.sh

set -euo pipefail

ROOT="$HOME/Projects/handoff-toolkit"
mkdir -p "$ROOT"/{.handoff,scripts}

echo "→ 建立 $ROOT"

cat > "$ROOT/.handoff/config.yaml" <<'EOF'
machines:
  andrewmac-mini:
    label: Mac mini（常駐）
    tailscale: andrewmac-mini
    vault: ~/Developer/ObsidianVault
  andrews-macbook-pro:
    label: MacBook Pro（行動）
    tailscale: andrews-macbook-pro
    vault: ~/Developer/ObsidianVault
  cursor:
    label: Cursor Cloud Agent
    tailscale: cursor
    vault: ""

vault_watch:
  - 01-Projects
  - 03-Resources/AI-Workflow
  - 02-Areas/DailyNotes/Journal

ai_brief_glob: "*-AI-Brief.md"
EOF

cat > "$ROOT/.handoff/session.md" <<'EOF'
# 專案接力狀態

尚未儲存。請執行：

    ./scripts/handoff.sh save -p 專案名 "目前進度"
EOF

cp "$(dirname "$0")/handoff.sh" "$ROOT/scripts/handoff.sh" 2>/dev/null || {
  echo "請在 handoff-toolkit repo 內執行，或先 git clone 專案"
  exit 1
}

chmod +x "$ROOT/scripts/handoff.sh"

if [[ ! -d "$ROOT/.git" ]]; then
  git -C "$ROOT" init -q
  git -C "$ROOT" add -A
  git -C "$ROOT" commit -q -m "bootstrap: local handoff toolkit"
fi

cat > "$HOME/.handoff-env" <<'EOF'
export OBSIDIAN_VAULT="$HOME/Developer/ObsidianVault"
EOF

grep -q 'handoff-env' "$HOME/.zshrc" 2>/dev/null || \
  echo '[ -f "$HOME/.handoff-env" ] && source "$HOME/.handoff-env"' >> "$HOME/.zshrc"

echo ""
echo "✓ 安裝完成: $ROOT"
echo ""
echo "下一步（逐行執行，不要貼 # 註解行）："
echo "  cd $ROOT"
echo "  source ~/.handoff-env"
echo "  ./scripts/handoff.sh status"
echo "  ./scripts/handoff.sh save -p test \"第一次設定完成\""
