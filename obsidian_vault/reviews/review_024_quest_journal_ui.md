# Code Review — 9A-3 任務日誌介面

## 任務資訊

- **任務名稱**: 9A-3 任務日誌介面（按 J 開啟）
- **Codex 完成時間**: 2026-03-30
- **驗收者驗收時間**: 2026-03-30

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 按 J 開關任務日誌 | ✅ 通過 | J 鍵輸入動作已加入 project.godot |
| 顯示進行中任務列表 | ✅ 通過 | 左側列表含進度顯示 |
| 顯示已完成任務列表 | ✅ 通過 | 已完成任務灰色顯示 |
| 點擊任務顯示詳情 | ✅ 通過 | 右側顯示描述/目標/獎勵 |
| Modal 互斥機制 | ✅ 通過 | InventoryUI/DialogUI 加入 modal_ui 群組 |
| 場景整合 | ✅ 通過 | TownHub + Dungeon01 皆有掛載 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 使用現有 API | ✅ 通過 | QuestManager Signal / get_active_quests() |
| 資料邊界正確 | ✅ 通過 | 不修改 QuestManager/QuestInstance |
| Modal UI 群組 | ✅ 通過 | 正確加入 modal_ui 並檢查互斥 |
| 獨立場景 | ✅ 通過 | QuestJournalUI.tscn 可獨立運作 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合慣例 | ✅ 通過 | PascalCase 類別、snake_case 變數 |
| 左右分欄佈局 | ✅ 通過 | 左 35% / 右 65% 設計 |
| 顏色區分正確 | ✅ 通過 | 進行中白 / 已完成灰 / 標題金 |
| CanvasLayer 層級 | ✅ 通過 | layer = 15（高於 InventoryUI）|

---

## 詳細回饋

### 優點 👍
- **Modal 互斥完善**: 不只實作 QuestJournalUI 的 modal 檢查，還補齊了 InventoryUI 與 DialogUI 的 modal_ui 群組加入，確保三者不會同時開啟
- **整合度高**: 同時更新 project.godot 輸入動作、兩個場景檔案（TownHub/Dungeon01），以及相關 UI 腳本
- **架構一致**: 遵循 InventoryUI 的 CanvasLayer 模式，使用 `_input()` 處理 J 鍵，與既有系統協調
- **資料驅動**: 正確使用 QuestManager API 取得進行中與已完成任務，不硬編碼

### 問題/建議 🔧
- **建議**: 未來可考慮在日誌開啟時暫停遊戲時間（若後續有時間系統），但目前非必要
- **建議**: 已完成任務列表若過長，可考慮加入捲動（ScrollContainer），但目前 4 個任務應無此問題

### 架構觀察 🏗️
- **Phase 9A 完整**: 任務 UI 三部曲（HUD/Toast/Journal）皆已完成，玩家現在可以完整追蹤任務狀態
- **擴充性**: QuestJournalUI 的左右分欄架構易於擴充（如加入「任務分類」頁籤）
- **維護性**: 集中使用 QuestManager Signal 更新，無輪詢，效能良好

---

## 驗收結果

- [x] **通過** - 列為 `9A-3`

### 下一步行動

進入 **Phase 9B** 品質修復：
- **9B-1**: Hotbar 綁定進存檔（Save v8）
- **9B-2**: Checkpoint 重生點跨重啟（Save v8 附加）
- **9B-3**: 消耗品系統擴充

建議優先進行 9B-1 與 9B-2，因為都涉及 Save v8 升版，可一併處理。

---

## 相關連結

- Task Prompt: `obsidian_vault/task_prompt.md`
- 既有 review:
  - `obsidian_vault/reviews/review_021_quest_tracker_hud.md`
  - `obsidian_vault/reviews/review_022_quest_toast_ui.md`
  - `obsidian_vault/reviews/review_023_quest_ui_input_recovery.md`

### 實作檔案
- `game/scenes/ui/QuestJournalUI.tscn`
- `game/scripts/ui/QuestJournalUI.gd`
- `game/scenes/levels/TownHub.tscn`
- `game/scenes/levels/Dungeon01.tscn`
- `game/scripts/ui/InventoryUI.gd`（加入 modal_ui 群組）
- `game/scripts/ui/DialogUI.gd`（加入 modal_ui 群組）
- `project.godot`（新增 ui_quest_journal 輸入動作）

---

*Review 建立時間: 2026-03-30*
