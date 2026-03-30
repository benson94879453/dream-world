# Code Review — 9A-2.5 任務 UI 輸入恢復整合修復

## 任務資訊

- **任務名稱**: 9A-2.5 任務 UI 輸入恢復整合修復
- **Codex 完成時間**: 2026-03-30
- **Kimi 驗收時間**: 2026-03-30

---

## 修復背景

在 **9A-1 任務追蹤 HUD** 與 **9A-2 任務通知 Toast** 完成後，實機整合測試出現以下問題：

1. 接取任務後玩家偶發無法移動或攻擊
2. 滑鼠攻擊在部分區域被 UI / 場景 Control 節點攔截
3. 任務板提供的任務完成並回報後，任務板本身無法再次以 `F` 鍵互動

本次工作將上述問題整合收斂為 **9A-2.5**，作為任務 UI 完成後的必要穩定化修復。

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 接取任務後玩家可恢復操作 | ✅ 通過 | 成功接取時不再重開阻塞式 follow-up dialog |
| 滑鼠攻擊不再被 HUD / 場景裝飾攔截 | ✅ 通過 | HUD、Label、ColorRect 改為 `MOUSE_FILTER_IGNORE` |
| 任務板在空任務狀態仍可對話 | ✅ 通過 | 無可接 / 可回報任務時顯示 fallback dialog |
| 無新增載入錯誤 | ✅ 通過 | Godot 4.6 重新載入成功 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 修復集中於 UI / Quest 組件邊界 | ✅ 通過 | 未將 UI 狀態邏輯塞回 QuestManager |
| 既有 Signal 流程保持一致 | ✅ 通過 | `quest_accepted` / `quest_turned_in` 仍由 QuestManager 發射 |
| 無破壞既有 DialogManager 職責 | ✅ 通過 | 只修正 quest giver follow-up timing 與空狀態回應 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | 沿用既有 9A review 命名格式 |
| 程式碼結構清晰易讀 | ✅ 通過 | 以 helper 函式收斂 pending dialog 與 mouse filter 遞迴 |
| 無額外警告殘留 | ✅ 通過 | 同步清除本輪 Godot warning |

---

## 問題定位

### 1. 接取任務後卡死
- `NPCQuestGiver` 會在 `dialog_ended` signal 期間同步啟動 follow-up dialog
- `DialogUI.hide_dialog()` 又在同一輪 signal 尾端執行，導致新對話被隱藏，但玩家控制重新被鎖住
- 表象上就會變成「畫面沒有對話，但無法移動」

### 2. 滑鼠攻擊被攔截
- `QuestToastUI` / `QuestTrackerUI` 內部的 `MarginContainer`、`VBoxContainer`、`Label` 等 Control 節點仍可能攔截滑鼠
- `TownHub` / `Dungeon01` 的背景 `ColorRect`
- 世界內的 `PortalSign`、`InteractionPrompt`、`NameLabel` 等 `Label`

### 3. 任務板完成後無法再次對話
- 任務板沒有 base dialog
- 任務完成且回報後，`build_runtime_dialog()` 在無可接 / 可回報 / 進行中任務時回傳 `null`
- 結果提示仍可見，但 `F` 鍵不會真正開啟任何對話

---

## 修復內容

### 1. 任務成功接取 / 回報時不再重開阻塞式回饋對話
- 檔案：`game/scripts/components/NPCQuestGiver.gd`
- 成功接取與成功回報改為只顯示 Quest Toast
- 失敗訊息與「聊聊其他事」仍保留 follow-up dialog
- pending dialog 改為 `call_deferred()` 延後啟動，避免與 `DialogUI.hide_dialog()` 互相踩到

### 2. Quest HUD 與世界提示統一放行滑鼠事件
- 檔案：
  - `game/scripts/ui/QuestToastUI.gd`
  - `game/scripts/ui/QuestTrackerUI.gd`
  - `game/scenes/levels/TownHub.tscn`
  - `game/scenes/levels/Dungeon01.tscn`
  - `game/scenes/interactables/Portal.tscn`
  - `game/scenes/interactables/Checkpoint.tscn`
  - `game/scenes/npcs/InstructorNPC.tscn`
- HUD 腳本新增遞迴 `mouse_filter` 設定
- 場景中純展示用途的 `ColorRect` / `Label` 改為 `mouse_filter = 2`

### 3. 任務板空狀態 fallback dialog
- 檔案：`game/scripts/components/NPCQuestGiver.gd`
- 當 quest giver 沒有任何可呈現任務，且沒有 base dialog 時，回傳：
  - `目前沒有新的委託，之後再來看看吧。`

### 4. 一併清除本輪 Godot warning
- 檔案：
  - `game/scripts/data/ItemData.gd`
  - `game/scripts/data/QuestInstance.gd`
  - `game/scripts/inventory/Equipment.gd`
  - `game/scripts/ui/QuestToastUI.gd`
  - `game/scripts/ui/QuestTrackerUI.gd`

---

## 驗證結果

- Godot 專案已重新載入成功
- 原本列出的 warning 未再出現
- 目前靜態驗證結果如下：
  - [x] 接取任務後不再建立隱藏的阻塞 follow-up dialog
  - [x] HUD 與世界裝飾節點不再攔截滑鼠攻擊
  - [x] 任務板在任務清空後仍可透過 `F` 顯示空狀態對話

> 註：本輪以「程式邏輯驗證 + Godot 重新載入」為主，仍建議再做一次人工實機流程測試。

---

## 驗收結果

- [x] **通過** - 列為 `9A-2.5`

### 下一步行動

進入 **9A-3 任務日誌介面（按 J 開啟）**。

---

## 相關連結

- Codex Prompt: `obsidian_vault/codex_prompt.md`
- 既有 review:
  - `obsidian_vault/reviews/review_021_quest_tracker_hud.md`
  - `obsidian_vault/reviews/review_022_quest_toast_ui.md`
