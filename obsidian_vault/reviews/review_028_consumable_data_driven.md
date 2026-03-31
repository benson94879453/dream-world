# Code Review — 9B-3 消耗品系統資料驅動

## 任務資訊

- **任務名稱**: 9B-3 消耗品系統資料驅動
- **Codex 完成時間**: 2026-03-31
- **驗收者驗收時間**: 2026-03-31

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 藥水回血量由資料決定 | ✅ 通過 | `consumable_potion.tres = HEAL 50.0` |
| hotbar 不再硬編碼 heal 25 | ✅ 通過 | `HotbarManager.use_hotbar_slot()` 已移除 magic number |
| 空槽 / 非消耗品 / 無效 effect 安全處理 | ✅ 通過 | 不會誤扣道具 |
| 武器 / 裝備 hotbar 行為不受影響 | ✅ 通過 | 原有分支保留 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 使用現有 API，無重複造輪子 | ✅ 通過 | 仍走 `Player.use_consumable()` |
| 資料邊界正確 | ✅ 通過 | effect 進 `ItemData`，不是塞進 hotbar |
| 不違反 Autoload 職責邊界 | ✅ 通過 | 無新增 Autoload |
| 組件化原則遵循 | ✅ 通過 | Player 驗證效果，Hotbar 只負責觸發 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | `ConsumableEffect` / snake_case 一致 |
| 程式碼結構清晰易讀 | ✅ 通過 | 預覽、套用、觸發流程分開 |
| 適當的註解與文件 | ✅ 通過 | 變更意圖清楚 |
| 無多餘/未使用程式碼 | ✅ 通過 | 未見冗餘路徑 |

---

## 詳細回饋

### 優點 👍
- `ItemData` 已完成最小但可擴充的 consumable schema
- `Player.use_consumable()` 先預覽再扣物，避免滿血或無效狀況誤消耗
- hotbar 行為維持原有流程，只替換效果來源，變更範圍乾淨

### 問題/建議 🔧
- 目前只有 `HEAL`，未來若加 buff 類 effect，建議沿用同一組 preview / apply 模式擴充

### 架構觀察 🏗️
- 這次把消耗品資料化，已把「物品定義」與「使用行為」切開，後續擴充成本低

---

## 驗收結果

- [x] **通過** - 可進入下一任務

### 下一步行動

進入下一個待指派任務。

---

## 相關連結

- Task Prompt: `obsidian_vault/task_prompt.md`
- 實作檔案:
  - `game/scripts/data/ItemData.gd`
  - `game/scripts/Player.gd`
  - `game/scripts/core/HotbarManager.gd`
  - `game/data/items/consumable_potion.tres`
