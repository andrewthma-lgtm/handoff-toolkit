# 專案接力 — tailscale-handoff

> 自動產生於 2026-09-01 16:07 UTC，來源機器：**cursor**

## 環境快照

| 欄位 | 值 |
|------|-----|
| 時間 | 2026-09-01 16:07 UTC |
| 來源機器 | cursor (Cursor Cloud Agent) |
| Tailscale | cursor.tail1c4ff3.ts.net @ 100.73.66.121 |
| Git 分支 | main |
| 最後 commit | 36ec310 Add handoff script for cross-machine project relay |
| 未提交變更 | 有未提交變更 |
| Vault 路徑 | （未設定） |

## 專案 / 任務

**專案名稱：** tailscale-handoff

**目前進度：**

增強版接力腳本：整合 AI Brief、Vault 異動掃描、三台機器設定

## 相關 AI Brief

_（跳過：無 Vault）_

## Vault 近期異動（48h）

_（本機未找到 Obsidian Vault）_

## 禁止事項 / 已做決策

- （手動補充或於 AI Brief 維護）

## 下一步待辦

- [ ] 接手機執行：`git pull && ./scripts/handoff.sh load`
- [ ] 開啟 AI Brief：_（跳過：無 Vault）_
- [ ] 確認 Tailscale：`tailscale status`
- [ ] 繼續開發並完成後 `handoff save`

## 跨機器連線

```bash
tailscale status
ping andrewmac-mini      # Mac mini
ping andrews-macbook-pro # MacBook Pro
ping cursor              # Cloud Agent
```

## SSH 接力（可選，需目標機開啟「遠端登入」）

```bash
ssh andrewm@andrewmac-mini
ssh andrewm@andrews-macbook-pro
```
