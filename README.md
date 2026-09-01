# Cross-Network Project Handoff

在不同網路下的 Mac mini、MacBook Pro、Cursor Cloud Agent 之間接力開發。

## 前置條件

- 三台機器皆已加入同一 [Tailscale](https://tailscale.com) tailnet
- 專案使用同一 git remote
- （可選）Obsidian Vault 透過 iCloud / git / Syncthing 同步

## 快速開始

### 新機器首次設定

```bash
./scripts/handoff.sh init
source ~/.handoff-env   # 設定 OBSIDIAN_VAULT 路徑
```

編輯 `.handoff/config.yaml` 中各機器的 `vault` 路徑（若與預設不同）。

### 離開前（機器 A）

```bash
git add -A && git commit -m "wip: 目前進度"
./scripts/handoff.sh save -p 專案名 "做到哪、下一步什麼"
```

### 接手（機器 B）

```bash
git pull
./scripts/handoff.sh load
```

## Tailscale 節點

| 名稱 | 用途 |
|------|------|
| `andrewmac-mini` | 家中常駐 |
| `andrews-macbook-pro` | 行動開發 |
| `cursor` | Cloud Agent |

```bash
tailscale status
ping andrewmac-mini
```

## 檔案說明

| 路徑 | 說明 |
|------|------|
| `scripts/handoff.sh` | 接力主腳本 |
| `.handoff/config.yaml` | 機器與 Vault 設定 |
| `.handoff/session.md` | 最新接力狀態（git 同步） |
| `.handoff/template.md` | 狀態檔結構參考 |
