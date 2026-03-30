# Code Review — 9A-1 任務追蹤 HUD

## 任務資訊

- **任務名稱**: 9A-1 任務追蹤 HUD（螢幕右側）
- **Codex 完成時間**: 2026-03-30
- **Kimi 驗收時間**: 2026-03-30

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 功能按預期運作 | ✅ 通過 | 顯示最多 3 筆進行中任務，含名稱與進度 |
| 無 Console 錯誤/警告 | ✅ 通過 | Godot 4.6 載入解析通過 |
| 邊界情況處理完善 | ✅ 通過 | 空任務時隱藏面板、保留完成但未交付任務 |
| 驗收標準所有項目完成 | ✅ 通過 | 接取/更新/完成/交付 四流程皆實作 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 使用現有 API，無重複造輪子 | ✅ 通過 | 使用 QuestManager Signal + get_active_quests() |
| 資料邊界正確 (Resource vs Instance) | ✅ 通過 | QuestInstance 型別正確使用 |
| 不違反 EventBus 白名單規範 | ✅ 通過 | 無 EventBus 使用 |
| 不違反 Autoload 職責邊界 | ✅ 通過 | QuestTrackerUI 純 UI，無邏輯侵入 |
| 組件化原則遵循 | ✅ 通過 | 動態條目管理、獨立場景 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | PascalCase 場景、snake_case 變數 |
| 程式碼結構清晰易讀 | ✅ 通過 | Region 組織良好、常量化顏色 |
| 適當的註解與文件 | ✅ 通過 | 函式職責明確 |
| 無多餘/未使用程式碼 | ✅ 通過 | 無冗餘 |

---

## 詳細回饋

### 優點 👍
- **Signal 驅動架構**: 完全依賴 QuestManager Signal，無輪詢，效能良好
- **動態條目管理**: 使用 Dictionary (`quest_entry_map`) 管理條目，避免重複創建與銷毀
- **平滑動畫**: Tween 顏色插值實現金色閃爍效果，過渡自然
- **細節處理**: mouse_filter = IGNORE 確保不阻擋遊戲操作、完成後保留顯示直到交付
- **配色專業**: 使用 RPG 風格配色（米白/金/深藍灰），與既有 UI 協調

### 問題/建議 🔧
- **未來擴充**: 若任務超過 3 個，可考慮顯示「+N 更多」提示（目前直接截斷）
- **交付金幣顯示**: 交付時 HUD 僅移除任務，未顯示獲得金幣數（由 9A-2 Toast 補充）

### 架構觀察 🏗️
- **職責分離**: UI 純粹負責顯示，所有狀態邏輯留在 QuestManager
- **可測試性**: 若需單元測試，可抽離 Signal 連接邏輯，注入 mock QuestManager
- **擴充性**: 條目創建邏輯封裝於 `_create_entry_widgets()`，易於新增其他任務屬性顯示

---

## 驗收結果

- [x] **通過** - 可進入下一任務

### 下一步行動
進入 **9A-2 任務通知 Toast** 實作。

---

## 相關連結

- Codex Prompt: `obsidian_vault/codex_prompt.md`
- 實作檔案:
  - `game/scenes/ui/QuestTrackerUI.tscn`
  - `game/scripts/ui/QuestTrackerUI.gd`
  - `game/scenes/levels/TownHub.tscn`
  - `game/scenes/levels/Dungeon01.tscn`
