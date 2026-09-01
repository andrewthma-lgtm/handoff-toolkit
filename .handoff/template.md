# 專案接力 — {{PROJECT}}

> 自動產生於 {{TIMESTAMP}}，來源機器：**{{HOST}}**

## 環境快照

| 欄位 | 值 |
|------|-----|
| 時間 | {{TIMESTAMP}} |
| 來源機器 | {{HOST}} ({{HOST_LABEL}}) |
| Tailscale IP | {{TS_IP}} |
| Git 分支 | {{BRANCH}} |
| 最後 commit | {{LAST_COMMIT}} |
| 未提交變更 | {{DIRTY_STATUS}} |

## 專案 / 任務

**專案名稱：** {{PROJECT}}

**目前進度：**

{{NOTE}}

## 相關 AI Brief

{{AI_BRIEFS}}

## Vault 近期異動（{{VAULT_PATH}}）

{{VAULT_CHANGES}}

## 禁止事項 / 已做決策

- （接力時補充：例如「不要改 schema」「已選 Streamlit 不用 Dash」）

## 下一步待辦

- [ ] `git pull && ./scripts/handoff.sh load`
- [ ] 開啟 AI Brief：`{{PRIMARY_BRIEF}}`
- [ ] {{NEXT_STEP_1}}
- [ ] {{NEXT_STEP_2}}

## Tailscale 快速連線

```bash
tailscale status
ping andrewmac-mini
ping andrews-macbook-pro
ping cursor
```
