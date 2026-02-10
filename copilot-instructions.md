# DevOps Copilot 指引

## 目標

本文件提供 GitHub Copilot 或類似 AI 助手的使用指南，協助開發者：

* 編寫符合 DevOps 標準的 shell script
* 部署到 Linux 伺服器
* 維護 CI/CD 流程安全與穩定性

---

## 基本規範

### Shell Script 標準

* 使用 `#!/usr/bin/env bash` 作為 shebang
* 強制開啟錯誤檢查與 pipefail：
  ```bash
  set -euo pipefail
  ```
* 每個 script 應包含：
* 說明（功能、版本、日期）
* 輸入參數說明
* 執行範例
* 使用函式封裝邏輯，避免全域變數污染
* 盡量使用絕對路徑
* 避免直接 hardcode 密碼或敏感資訊，建議從 .env 讀取
* 縮排使用 2 個空格，保持一致性

### 版本控制 Best Practice

* 所有 shell script 都應放在 scripts/ 目錄
* 對每個 script 寫簡單 README 記錄用途
* 不要將 .env 或私密憑證提交至 repository

### 安全與敏感資訊

* 所有敏感資訊應使用環境變數
* 禁止在 script 中明碼儲存密碼或 token
* CI/CD pipeline 使用 secrets 管理 key
* 日誌避免輸出敏感資訊

### CI/CD 建議

* shell script 可用於：
  * 部署程式碼
  * 建立環境（setup、install）
  * 清理舊資源（cleanup）
  * 使用 set -x 或 echo 輸出 debug 資訊
  * 任何失敗的 step 應中斷流程（利用 set -e）
  * 日誌保存於 logs/，便於追蹤


### 檔案完整性保護規則（最高優先）

* **未完整取得相關檔案時：**
  * 禁止修改
  * 禁止產生任何程式碼
* 必須回覆：
> 「內容不足，無法修正」
* 並條列仍缺少的必要檔案或資訊

## 回答與產出原則（Copilot 行為）

* 提供可直接上線的完整程式碼
* 用繁體中文回答