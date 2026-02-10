# Devops

此專案包含維運相關的 shell scripts，統一放在 scripts/ 目錄。

## scripts

### start-feature.sh

用途：從指定來源 branch 建立 feature branch，必要時執行單元測試，並推送至遠端。

範例：
```bash
./scripts/start-feature.sh
```

### to-master.sh

用途：合併 release 到 master，更新版本號，可選擇是否進行 build。

範例：
```bash
./scripts/to-master.sh
```
