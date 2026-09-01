#!/bin/bash
# 跨網路專案接力：Tailscale + Git + Obsidian Vault / AI Brief
#
# 用法:
#   ./scripts/handoff.sh save [-p 專案名] "進度備註"   # 離開前
#   ./scripts/handoff.sh load                          # 接手
#   ./scripts/handoff.sh status                        # 檢查本機環境
#   ./scripts/handoff.sh init                          # 新機器首次設定

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HANDOFF_DIR="$REPO_ROOT/.handoff"
CONFIG_FILE="$HANDOFF_DIR/config.yaml"
STATE_FILE="$HANDOFF_DIR/session.md"
TEMPLATE_FILE="$HANDOFF_DIR/template.md"

HOST_SHORT="$(hostname -s 2>/dev/null || hostname)"
TS_IP="$(tailscale ip -4 2>/dev/null || echo 'offline')"
TS_NAME="$(tailscale status --self --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('Self',{}).get('DNSName','').rstrip('.'))" 2>/dev/null || echo "$HOST_SHORT")"

resolve_vault_path() {
  local raw="${OBSIDIAN_VAULT:-}"
  if [[ -z "$raw" ]] && [[ -f "$CONFIG_FILE" ]]; then
    raw="$(python3 - "$CONFIG_FILE" "$TS_NAME" "$HOST_SHORT" <<'PY'
import sys, os, yaml
cfg_path, ts_name, host = sys.argv[1:4]
try:
    import yaml
except ImportError:
    sys.exit(0)
with open(cfg_path) as f:
    cfg = yaml.safe_load(f) or {}
machines = cfg.get("machines", {})
for key in (ts_name, host, host.lower()):
    m = machines.get(key) or machines.get(key.replace("_", "-"))
    if m and m.get("vault"):
        print(os.path.expanduser(m["vault"]))
        break
PY
)"
  fi
  if [[ -z "$raw" ]]; then
    for candidate in \
      "$HOME/Developer/ObsidianVault" \
      "$HOME/Documents/ObsidianVault" \
      "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ObsidianVault"; do
      [[ -d "$candidate" ]] && raw="$candidate" && break
    done
  fi
  echo "${raw:-}"
}

vault_recent_changes() {
  local vault="$1"
  local hours="${2:-24}"
  if [[ -z "$vault" || ! -d "$vault" ]]; then
    echo "_（本機未找到 Obsidian Vault）_"
    return
  fi
  local dirs=()
  if [[ -f "$CONFIG_FILE" ]]; then
    mapfile -t dirs < <(python3 - "$CONFIG_FILE" <<'PY'
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f) or {}
for d in cfg.get("vault_watch", ["01-Projects"]):
    print(d)
PY
)
  else
    dirs=("01-Projects" "03-Resources/AI-Workflow")
  fi
  local found=0
  for rel in "${dirs[@]}"; do
    local dir="$vault/$rel"
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' f; do
      echo "- \`$rel/${f#"$dir/"/}\`"
      found=1
    done < <(find "$dir" -type f \( -name "*.md" -o -name "*.py" -o -name "*.ts" -o -name "*.tsx" \) -mtime -"$hours"h -print0 2>/dev/null | head -z -n 15)
  done
  [[ "$found" -eq 1 ]] || echo "_（過去 ${hours}h 無異動）_"
}

find_ai_briefs() {
  local vault="$1"
  local project="${2:-}"
  if [[ -z "$vault" || ! -d "$vault" ]]; then
    echo "_（跳過：無 Vault）_"
    return
  fi
  local pattern="*-AI-Brief.md"
  if [[ -f "$CONFIG_FILE" ]]; then
    pattern="$(python3 - "$CONFIG_FILE" <<'PY'
import yaml, sys
with open(sys.argv[1]) as f:
    print((yaml.safe_load(f) or {}).get("ai_brief_glob", "*-AI-Brief.md"))
PY
)"
  fi
  local found=0
  if [[ -n "$project" ]]; then
    while IFS= read -r -d '' f; do
      echo "- [[$(basename "$f" .md)]] → \`$f\`"
      found=1
    done < <(find "$vault" -type f -iname "*${project}*AI-Brief*" -print0 2>/dev/null | head -z -n 5)
  fi
  while IFS= read -r -d '' f; do
    echo "- \`$f\`"
    found=1
  done < <(find "$vault/03-Resources/AI-Workflow" "$vault/01-Projects" -type f -name "$pattern" 2>/dev/null -print0 | head -z -n 8)
  [[ "$found" -eq 1 ]] || echo "_（未找到 AI Brief，可於 01-Projects 或 03-Resources/AI-Workflow 建立）_"
}

host_label() {
  python3 - "$CONFIG_FILE" "$TS_NAME" "$HOST_SHORT" <<'PY' 2>/dev/null || echo "$HOST_SHORT"
import sys, yaml
cfg_path, ts, host = sys.argv[1:4]
try:
    with open(cfg_path) as f:
        machines = (yaml.safe_load(f) or {}).get("machines", {})
    for k in (ts, host, host.lower()):
        if k in machines:
            print(machines[k].get("label", k))
            break
    else:
        print(host)
except Exception:
    print(host)
PY
}

git_dirty_status() {
  if git -C "$REPO_ROOT" diff --quiet 2>/dev/null && git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    local untracked
    untracked="$(git -C "$REPO_ROOT" ls-files --others --exclude-standard | wc -l | tr -d ' ')"
    if [[ "$untracked" -gt 0 ]]; then
      echo "${untracked} 個未追蹤檔案"
    else
      echo "乾淨"
    fi
  else
    echo "有未提交變更"
  fi
}

cmd_save() {
  local project="" note=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--project) project="$2"; shift 2 ;;
      *) note="$1"; shift ;;
    esac
  done
  [[ -z "$project" ]] && project="$(basename "$REPO_ROOT")"

  local vault branch last_commit dirty label briefs changes
  vault="$(resolve_vault_path)"
  branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  last_commit="$(git -C "$REPO_ROOT" log -1 --oneline 2>/dev/null || echo none)"
  dirty="$(git_dirty_status)"
  label="$(host_label)"
  briefs="$(find_ai_briefs "$vault" "$project")"
  changes="$(vault_recent_changes "$vault" 48)"
  local ts now primary_brief
  now="$(date '+%Y-%m-%d %H:%M %Z')"
  primary_brief="$(echo "$briefs" | head -1 | sed 's/^- //' || echo '（見下方列表）')"

  mkdir -p "$HANDOFF_DIR"
  cat > "$STATE_FILE" <<EOF
# 專案接力 — ${project}

> 自動產生於 ${now}，來源機器：**${HOST_SHORT}**

## 環境快照

| 欄位 | 值 |
|------|-----|
| 時間 | ${now} |
| 來源機器 | ${HOST_SHORT} (${label}) |
| Tailscale | ${TS_NAME} @ ${TS_IP} |
| Git 分支 | ${branch} |
| 最後 commit | ${last_commit} |
| 未提交變更 | ${dirty} |
| Vault 路徑 | ${vault:-（未設定）} |

## 專案 / 任務

**專案名稱：** ${project}

**目前進度：**

${note:-（請在 save 時附上備註，例：./scripts/handoff.sh save -p myapp "完成登入 API，待寫測試")}

## 相關 AI Brief

${briefs}

## Vault 近期異動（48h）

${changes}

## 禁止事項 / 已做決策

- （手動補充或於 AI Brief 維護）

## 下一步待辦

- [ ] 接手機執行：\`git pull && ./scripts/handoff.sh load\`
- [ ] 開啟 AI Brief：${primary_brief}
- [ ] 確認 Tailscale：\`tailscale status\`
- [ ] 繼續開發並完成後 \`handoff save\`

## 跨機器連線

\`\`\`bash
tailscale status
ping andrewmac-mini      # Mac mini
ping andrews-macbook-pro # MacBook Pro
ping cursor              # Cloud Agent
\`\`\`

## SSH 接力（可選，需目標機開啟「遠端登入」）

\`\`\`bash
ssh andrewm@andrewmac-mini
ssh andrewm@andrews-macbook-pro
\`\`\`
EOF

  git -C "$REPO_ROOT" add "$STATE_FILE" 2>/dev/null || true
  if ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    git -C "$REPO_ROOT" commit -m "handoff: ${project} from ${HOST_SHORT}"
  fi
  if git -C "$REPO_ROOT" push origin "$branch" 2>/dev/null; then
    echo "✓ 已 push 接力狀態"
  else
    echo "⚠ 請手動：git push origin ${branch}"
  fi
  echo "✓ ${STATE_FILE}"
  echo "  另一台機器：git pull && ./scripts/handoff.sh load"
}

cmd_load() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "找不到 ${STATE_FILE}"
    echo "請先在另一台執行：./scripts/handoff.sh save \"進度備註\""
    exit 1
  fi
  echo "╔══════════════════════════════════════╗"
  echo "║       專案接力 — 接手檢查清單        ║"
  echo "╚══════════════════════════════════════╝"
  echo ""
  cat "$STATE_FILE"
  echo ""
  echo "─── 本機環境 ───"
  echo "機器:     $(host_label) (${HOST_SHORT})"
  echo "Tailscale: ${TS_NAME} @ ${TS_IP}"
  echo "Git:      $(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null) @ $(git -C "$REPO_ROOT" log -1 --oneline 2>/dev/null)"
  local vault
  vault="$(resolve_vault_path)"
  echo "Vault:    ${vault:-（未找到，可 export OBSIDIAN_VAULT=~/path）}"
  echo ""
  if [[ "$TS_IP" != "offline" ]]; then
    echo "─── Tailscale 節點 ───"
    tailscale status 2>/dev/null | grep -E '^(100\.|[0-9])' || tailscale status 2>/dev/null | head -5
  else
    echo "⚠ Tailscale 離線，請先：sudo tailscale up"
  fi
}

cmd_status() {
  local vault
  vault="$(resolve_vault_path)"
  echo "機器:      $(host_label) (${HOST_SHORT})"
  echo "Tailscale: ${TS_NAME} @ ${TS_IP}"
  echo "Git:       $(git -C "$REPO_ROOT" status -sb 2>/dev/null | head -1)"
  echo "Vault:     ${vault:-未設定}"
  echo "接力檔:    ${STATE_FILE}"
  [[ -f "$STATE_FILE" ]] && echo "" && head -20 "$STATE_FILE"
}

cmd_init() {
  cat > "$HOME/.handoff-env" <<'ENV'
# 本機 Obsidian Vault 路徑（依機器修改）
export OBSIDIAN_VAULT="$HOME/Developer/ObsidianVault"
ENV
  local rc="$HOME/.zshrc"
  grep -q 'handoff-env' "$rc" 2>/dev/null || echo '[ -f "$HOME/.handoff-env" ] && source "$HOME/.handoff-env"' >> "$rc"
  echo "✓ 已建立 ~/.handoff-env"
  echo "  請編輯 Vault 路徑後執行：source ~/.handoff-env"
  echo "✓ 已加入 ~/.zshrc 自動載入"
  cmd_status
}

case "${1:-}" in
  save) shift; cmd_save "$@" ;;
  load) cmd_load ;;
  status) cmd_status ;;
  init) cmd_init ;;
  *)
    cat <<'HELP'
用法:
  ./scripts/handoff.sh save [-p 專案名] "進度備註"   離開前存檔並 push
  ./scripts/handoff.sh load                          接手並顯示檢查清單
  ./scripts/handoff.sh status                        本機環境一覽
  ./scripts/handoff.sh init                          新 Mac 首次設定 Vault 路徑

範例:
  ./scripts/handoff.sh save -p tailscale-setup "Mac CLI 完成，cursor 已上線"
  ./scripts/handoff.sh load
HELP
    ;;
esac
