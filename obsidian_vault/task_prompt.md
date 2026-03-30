# Task Prompt — 排查讀檔後流程卡住問題

---

## 1. 問題背景

目前專案在觸發讀檔（F10 -> `SaveManager.load_game()`）後會出現「流程卡住」現象。

已知狀況：
- `SaveManager.load_game()` 已串接：
  - `inventory_.from_save_dict(...)`
  - `player_.from_save_dict(...)`
  - `dialog_manager_.from_save_dict(...)`
  - `quest_manager_.from_save_dict(...)`
  - `hotbar_manager_.from_save_dict(...)`
  - `scene_state_manager_.from_save_dict(...)`
  - `zone_reset_manager_.from_save_dict(...)`
  - `scene_state_manager_.reapply_current_scene_state()`
- `load_completed` signal 目前看不到外部訂閱者
- `Player.gd` 是直接在 `_try_handle_debug_save_load()` 裡呼叫 `save_manager_.load_game()`
- 目前症狀不是 parse error，而是「讀檔後遊戲流程停住 / 卡住」

本任務目標是：
1. 釐清卡住點發生在 `load_game()` 的哪一段
2. 找出是資料恢復、場景狀態重套、玩家狀態、UI / modal 狀態，還是輸入鎖定造成
3. 做最小修復，讓讀檔後能正常回到可操作狀態

---

## 2. 需要優先檢查的懷疑點

### A. Player / UI 狀態沒有在讀檔後恢復
重點檢查：
- `Player.gd`
  - `controls_locked`
  - `transient_lock_time_remaining`
  - `inventory_ui_open`
  - `is_dashing`
  - `is_respawning`
- 讀檔後是否還停留在不可操作狀態
- 讀檔時如果某個 UI 正開著，是否把玩家鎖住但沒有清掉

### B. SceneStateManager.reapply_current_scene_state() 卡住或造成異常狀態
重點檢查：
- `SceneStateManager.gd: reapply_current_scene_state()`
- `PersistentObject.reload_persistent_state()`
- 是否有節點在 reload 過程中：
  - queue_free 自己
  - 觸發新的場景邏輯
  - 進入等待 / 不完整狀態
- 是否在 current scene 的 persistent object 重新套用時導致流程停住

### C. SaveManager.load_game() 呼叫順序造成不一致
目前順序是：
1. inventory
2. player
3. dialog
4. quest
5. hotbar
6. scene_state
7. zone_reset
8. reapply_current_scene_state

需要檢查：
- `player_.from_save_dict()` 是否依賴 inventory 已完成
- `hotbar_manager_.from_save_dict()` 是否依賴 inventory / UI 當前狀態
- `scene_state_manager_.reapply_current_scene_state()` 是否應該晚一點，或需要 deferred
- 是否有任一 `from_save_dict()` 在 emit signal 時觸發額外流程，導致卡住

### D. 讀檔後其實不是「程式卡住」，而是輸入 / modal 被鎖住
重點檢查：
- `InventoryUI`
- `QuestJournalUI`
- `DialogUI`
- `WeaponUpgradeUI`
- `modal_ui` 群組內是否有 visible 節點殘留
- NPC / Portal / Checkpoint 是否因 modal 判定導致看起來像卡住
- Player 是否還能 `_physics_process`，只是 `_input` 或 `_unhandled_input` 被阻斷

### E. SceneTransitionManager 與 SaveManager 的責任邊界不一致
目前 `SaveManager.load_game()` 沒有處理跨場景讀檔，只是把資料套到當前場景。
若存檔內容與當前場景不一致，可能導致：
- player 位置 / scene state / respawn state 不一致
- 某些 persistent object 狀態重套到錯場景
- 看起來像讀檔後壞掉或卡住

請確認目前卡住是否發生在：
- TownHub 存檔 -> TownHub 讀檔
- Dungeon01 存檔 -> Dungeon01 讀檔
- 或跨重啟 / 跨場景情境

---

## 3. 排查步驟

### Step 1: 在 SaveManager.load_game() 各階段加入精準 log
請在以下節點前後加入 log，確認卡在哪一步：
- 開始 load_game
- inventory.from_save_dict 前後
- player.from_save_dict 前後
- dialog.from_save_dict 前後
- quest.from_save_dict 前後
- hotbar.from_save_dict 前後
- scene_state.from_save_dict 前後
- zone_reset.from_save_dict 前後
- reapply_current_scene_state 前後
- load_completed.emit(true) 前

目標：
- 明確知道是否真的卡在某個函式內
- 還是 load_game 已完成，但讀檔後場景/輸入卡住

### Step 2: 針對 Player 狀態做讀檔後檢查
請在讀檔完成後印出：
- `controls_locked`
- `transient_lock_time_remaining`
- `inventory_ui_open`
- `is_dashing`
- `get_current_state_name()`
- `velocity`
- `global_position`

目標：
- 確認玩家是否其實仍在鎖定態或異常 state

### Step 3: 檢查 modal UI 殘留
讀檔完成後列出：
- `get_tree().get_nodes_in_group("modal_ui")`
- 哪些節點 `visible == true`

目標：
- 確認是否 UI 殘留導致玩家無法互動

### Step 4: 檢查 PersistentObject 重套流程
請找出：
- `PersistentObject.gd`
- `reload_persistent_state()` 實作
- 所有使用 `persistent_object` 群組的場景物件

目標：
- 確認 `reapply_current_scene_state()` 是否會觸發卡住、錯誤隱藏、或物件狀態不一致

### Step 5: 確認 load_game 是否完成但沒有恢復到 Idle / 可操作狀態
如果 `load_game()` 本體已成功跑完，請檢查是否需要在結尾補做最小恢復，例如：
- 將玩家 state reset 到 `Idle`
- 清理 UI / modal
- 重設 velocity
- 清掉暫時控制鎖
- deferred reapply scene state

但在確認根因前不要先大改。

---

## 4. 需要重點閱讀的檔案

### 必讀
- `game/scripts/core/SaveManager.gd`
- `game/scripts/Player.gd`
- `game/scripts/core/SceneStateManager.gd`
- `game/scripts/core/SceneTransitionManager.gd`

### 高關聯
- `game/scripts/ui/InventoryUI.gd`
- `game/scripts/ui/DialogUI.gd`
- `game/scripts/ui/QuestJournalUI.gd`
- `game/scripts/ui/WeaponUpgradeUI.gd`

### 若有使用 persistent state
- `game/scripts/**/PersistentObject.gd`
- 任何 `reload_persistent_state()` 的實作位置

---

## 5. 修復要求

- 先定位，再修
- 優先做最小修復
- 不要順手重構整個 Save / SceneTransition 架構
- 若根因是呼叫順序問題，只調整必要順序
- 若根因是 UI / Player 鎖定狀態殘留，只清理必要狀態
- 若根因是 `reapply_current_scene_state()`，優先考慮 deferred 或保護條件，而不是大改場景系統

---

## 6. 驗收標準

### 功能驗收
- [ ] F10 後流程不再卡住
- [ ] 讀檔後玩家可移動 / 攻擊 / 互動
- [ ] 讀檔後 UI 不會殘留在錯誤狀態
- [ ] 讀檔後 Hotbar / Quest / SceneState 仍正常恢復
- [ ] 無新增 parse error / warning

### 排查輸出
- [ ] 明確指出卡住點
- [ ] 說明根因
- [ ] 說明為何該修復是最小正確修復
- [ ] 列出修改檔案

---

## 7. 補充觀察

目前從程式結構看，優先懷疑：
1. `reapply_current_scene_state()` 相關物件重套
2. 玩家 / UI 鎖定狀態未恢復
3. `from_save_dict()` 某個 signal/回調在讀檔中途觸發額外流程

請先用 log 把卡點抓出來，再決定修法。

---
