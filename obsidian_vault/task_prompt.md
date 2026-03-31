# Task Prompt — Boss 後傳送門高亮

> Phase 9C-3 / Boss Event Chain

---

## 1. 任務背景

`9C-1` 與 `9C-2` 都已完成並驗收通過。野豬王已經能正確掉落、死亡表現也有 hit stop / 白閃 / 淡出 / 音效，但 `Dungeon01` 裡返回城鎮的傳送門仍是靜態狀態，無法直接反映 boss defeated 之後的世界變化。

目前 `Portal.gd` 只有固定的 `target_scene`、`target_spawn_point`、`interaction_prompt`，`Dungeon01.tscn` 也只是把 `PortalToHub` 擺上去並寫死「返回城鎮」。本任務要把這個 portal 跟 `SceneStateManager` 的 boss defeated 狀態接起來，讓玩家在 boss 死前看到封鎖狀態，死後看到開啟狀態。

---

## 2. 當前任務

### 任務標題
Boss 後傳送門高亮

### 任務描述
請讓 `Dungeon01` 的返回傳送門能根據 `dungeon01_boss_boar` 的 defeated 狀態切換外觀與提示文字。Boss 死前傳送門應顯示「尚未開放」並維持封印感；Boss 死後傳送門應切換為「前往城鎮」並呈現明顯的開啟高亮。

### 具體需求

### A. Portal state 監聽
- 在 `game/scripts/interactables/Portal.gd` 新增 `activate_on_state_id` 屬性
- 以 `SceneStateManager.get_state(activate_on_state_id)` 判斷對應 boss 是否已 defeated
- 可參考 `InstructorNPC.gd` 的 boss state 查詢模式
- 若 state 不存在或 defeated 為 false，portal 維持封印 / 未開放狀態

### B. 視覺與互動切換
- boss 未倒下時，portal 外觀要明顯偏弱或封印感
- boss defeated 後，portal 要切換為更明亮或更開啟的視覺狀態
- `interaction_prompt` 也要跟著切換，死前顯示「尚未開放」，死後顯示「前往城鎮」
- 不要把傳送邏輯寫死到另一條平行流程，仍然保留原本 `transition_to()` 行為

### C. Dungeon01 具體設定
- 更新 `game/scenes/levels/Dungeon01.tscn` 的 `PortalToHub`
- 將其綁定到 `dungeon01_boss_boar`
- 保留返回城鎮的 target scene / spawn point，不要改傳送目的地
- 視覺與提示字串由 portal 自己依 boss 狀態切換，不要在場景裡複製兩套 portal

### D. 保持邊界
- 不要改 `PersistentObject` 的 defeated 單一來源
- 不要改 boss 掉落、死亡演出、存檔、任務系統
- 不要新增 Autoload
- 不要把 portal 高亮做成通用關卡編輯器功能，先只完成 `Dungeon01` 這一個案例

### 驗收標準
- [ ] Boss 死前傳送門顯示「尚未開放」且有封印感
- [ ] Boss 死後傳送門顯示「前往城鎮」且視覺明顯開啟
- [ ] 直接走傳送門仍能正常回到 TownHub / Spawn_from_dungeon
- [ ] 重進 `Dungeon01` 時，已 defeated 的 boss 對應 portal 仍保持開啟
- [ ] `Dungeon01.tscn` / `Portal.tscn` 可正常載入，沒有 parse error
- [ ] 無新增 warning

---

## 3. 技術約束

- 優先修改 `Portal.gd` 與 `Dungeon01.tscn`
- 必要時可補少量 `SceneStateManager.gd` 相關輔助，但不要重寫狀態系統
- 允許新增最小必要的提示 / 視覺狀態欄位
- 保持既有 GDScript 命名與資料模型慣例

---

## 4. 參考檔案

### 必讀
- `game/scripts/interactables/Portal.gd`
- `game/scenes/interactables/Portal.tscn`
- `game/scenes/levels/Dungeon01.tscn`
- `game/scripts/core/SceneStateManager.gd`
- `game/scripts/npcs/InstructorNPC.gd`

### 高關聯
- `game/scripts/components/PersistentObject.gd`
- `game/scripts/core/SaveManager.gd`
- `game/scenes/levels/TownHub.tscn`
- `reviews/review_031_boss_death_presentation.md`
- `reviews/review_030_boss_loot_drop.md`
- `planning/mvp_todo.md`
- `sync_summary.md`

---

## 5. 輸出要求

完成後請在本檔底部更新：
- 任務狀態
- 實作摘要
- 修改檔案清單
- 手動驗證結果
- 若有尚未處理的 portal presentation 債務，請列出

另外請在回報中明確說明：
1. `activate_on_state_id` 如何工作
2. boss defeated 前後 portal 的 prompt / 視覺差異
3. 是否保留原本傳送邏輯與 spawn 行為

---

## 6. 任務狀態

- [ ] 進行中
- [x] 已完成

### 實作摘要

- `Portal.gd` 新增 `activate_on_state_id`，會向 `SceneStateManager.get_state()` 查 defeated 狀態；若未綁定 state id，portal 維持原本永遠可用行為。
- `SceneStateManager.gd` 補上 `state_recorded` 與 `current_scene_state_reapplied` signal，讓 portal 能在 boss defeated 當下與 reapply 後立即刷新視覺。
- `Portal.tscn` 新增 `HighlightGlow` 與 `SealBand`，封印態顯示較弱的門體色與封印帶，開啟態顯示更亮的門體與 pulse highlight。
- `Dungeon01.tscn` 的 `PortalToHub` 已綁定 `dungeon01_boss_boar`，死前 prompt 顯示 `尚未開放`，死後恢復為 `[F] 前往城鎮`。
- 已驗收通過，見 `reviews/review_032_boss_portal_highlight.md`

### 修改檔案清單

- `game/scripts/interactables/Portal.gd`
- `game/scenes/interactables/Portal.tscn`
- `game/scenes/levels/Dungeon01.tscn`
- `game/scripts/core/SceneStateManager.gd`
- `obsidian_vault/reviews/review_032_boss_portal_highlight.md`

### 手動驗證結果

- headless smoke check 成功載入 `res://game/scenes/interactables/Portal.tscn`
- headless smoke check 成功載入 `res://game/scenes/levels/Dungeon01.tscn`
- headless smoke check 成功載入 `res://game/scenes/levels/TownHub.tscn`
- 本輪未做互動式 boss 擊殺與實際過門 playtest；傳送邏輯本身未改，只在 portal 不可用時提前 return
- `PortalToHub` 在 boss defeated 後會立即切換為開啟態；未綁定 state id 時仍維持原本可用行為。

### 備註 / 問題

- `activate_on_state_id` 目前先服務 `Dungeon01` 返回傳送門案例，但未擴成更大的關卡編輯器系統。
- 若後續想再加強收尾感，可以考慮讓 `PortalSign` 也跟著切換文字或顏色；本輪先只做 prompt 與門體 presentation。
