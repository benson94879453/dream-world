# 01_MVP_TODO

> 最小可交付任務清單
> Godot 4.x / 單人開發
> 最後更新: 2026-03-30

---

## 已完成 ✅（Phase 1–8 + Hub Vertical Slice）

### 核心戰鬥系統
- [x] Build `Player.tscn` - 角色控制器、狀態機
- [x] Build `Enemy_Dummy.tscn` - 基礎敵人
- [x] Add 8-direction movement - 八方向移動
- [x] Add walk and run states - 走/跑狀態
- [x] Add player melee attack input - 近戰攻擊
- [x] Add player attack hitbox - 攻擊判定
- [x] `AttackContext.gd` - 攻擊上下文
- [x] `Hitbox.gd` / `Hurtbox.gd` - 碰撞系統
- [x] `DamageReceiver.gd` / `HealthComponent.gd` - 傷害管線
- [x] `PlayerAttackState.gd` - 攻擊狀態（Combo/Cancel）
- [x] 滑鼠左鍵攻擊 + 法術朝滑鼠方向發射

### 武器系統
- [x] `WeaponData` / `WeaponInstance` - 武器資料與實例
- [x] `SwordWeapon` / `StaffWeapon` - 劍/法杖武器類型
- [x] `SpellActor` 系統 - 投射/即時/持續法術
- [x] 數字鍵 1-5 武器切換

### 物品與背包
- [x] `ItemData` / `GearData` / `GearInstance` - 物品與裝備資料模型
- [x] `Inventory` v2 - 20格 slot-based 背包（item/weapon/gear 三型態）
- [x] `Equipment.gd` - 5槽裝備欄（武器/頭/胸/腿/靴）
- [x] `InventorySlot` 擴充 - 三型態統一容器
- [x] `PickupItem` - 掉落物與撿取（保留 UID）
- [x] `LootTableData` - 掉落表配置
- [x] `HotbarManager` - 5格快捷欄（綁定/使用）

### 存檔系統
- [x] `SaveManager` - Autoload 存檔管理
- [x] Save v7 + SHA256 checksum + 版本遷移（v1→v7）
- [x] F5存檔 / F10讀檔

### 敵人 AI 系統
- [x] `EnemyAIController` - 敵人 AI 控制器
- [x] `EnemyStateMachine` - 敵人狀態機
- [x] **Slime** - 近戰追擊型
- [x] **Archer** - 遠程保持距離型
- [x] **Boar** - 突進爆發型（Charge→Dash）

### Dash 系統
- [x] `PlayerDashState` - Dash 狀態（120px / 0.15s）
- [x] Dash 無敵幀 + Cancel 攻擊 + 冷卻顯示

### Phase 5A: NPC 對話系統
- [x] `DialogData` / `DialogNodeData` / `DialogChoiceData` - 對話資料模型
- [x] `DialogManager` - Autoload 對話管理（flags、條件選項）
- [x] `DialogUI` - 逐字顯示、選項分支
- [x] `NPCDialogTrigger` - 互動觸發
- [x] Save v2 整合 - 對話 flags 保存

### Phase 5B: 武器升級系統
- [x] `AffixData` / `AffixTable` - 詞綴定義與抽選
- [x] `UpgradeManager` - 升級邏輯 (Autoload)
- [x] `WeaponUpgradeUI` - 升級介面（雙頁籤）
- [x] 6個基礎詞綴（鋒利、沉重、迅捷、專注、吸血、暈眩）
- [x] 星級系統（0★→5★，每級+5%攻擊）+ 符文槽（1★=1槽, 5★=5槽）
- [x] Save v3 整合 - 星級與詞綴保存

### Phase 6A: 符文鑲嵌系統
- [x] `RuneData` / `RuneSlot` / `RuneInstance` - 符文資料模型
- [x] `RuneManager` - Autoload 符文管理
- [x] 12個符文石（8普通+4核心）
- [x] `RuneSocketUI` - 鑲嵌/拆卸介面
- [x] Save v4 整合

### Phase 7: 經濟循環 + 符文效果 + Hit Stop
- [x] 金幣系統（Save v5）
- [x] `DecomposeManager` - 武器分解
- [x] 4個核心符文機制（無盡之刃/雙重打擊/元素共鳴/吸血渴望）
- [x] `HitStopManager` - 局部時間暫停 + 閃白/音效/特效
- [x] Arena 測試驗證（機率統計正確）

### Phase 8: 背包架構重整
- [x] P8.1 `GearData` / `GearInstance`
- [x] P8.2 `ItemData.get_stack_key()`
- [x] P8.3 `InventorySlot` 三型態支援
- [x] P8.4 `Inventory` v2 slot-based 存檔 + v1→v2 migration
- [x] P8.5 `Equipment.gd` 裝備欄系統
- [x] P8.6 Player 協調 API（穿脫/rollback）
- [x] P8.7 `PickupItem` 唯一實例掉落
- [x] P8.8 Hotbar 綁定規則定稿
- [x] P8.9 UI 擴充（Equipment UI、Chest UI、Shift+Click）
- [x] RPG 風格統一 + 左右分欄佈局

### Hub-based Vertical Slice
- [x] `SceneTransitionManager` - 淡入淡出、玩家狀態暫存/還原、重生點管理
- [x] `Portal.tscn` - 雙向傳送門（F鍵互動）
- [x] `Checkpoint.tscn` - 營火（自動/F鍵觸發、回血、存檔）
- [x] `SceneStateManager` - 場景物件狀態持久化
- [x] `ZoneResetManager` - 區域重置策略（ON_REENTER / NEVER）
- [x] `PersistentObject` - 自動保存/載入物件狀態（Boss 永久死亡）
- [x] `TownHub.tscn` - 城鎮安全區（鐵匠/教官/任務板/傳送門）
- [x] `Dungeon01.tscn` - 地城（Checkpoint × 2、敵人配置、Boss）
- [x] `InstructorNPC.tscn` - 依 Boss 狀態切換對話
- [x] Save v6 整合（Equipment + checksum）
- [x] Save v7 整合（Quest 欄位 + migration）

### 任務系統（後端）
- [x] `QuestData.gd` - 任務資料模型（KILL / COLLECT / TALK / DELIVER）
- [x] `QuestInstance.gd` - 執行期實例（進度/狀態/時間戳）
- [x] `QuestManager` - Autoload（接取/放棄/交付/進度推送/存讀檔）
- [x] `NPCQuestGiver` - 動態任務選單（接取/回報整合 DialogUI）
- [x] 進度觸發鏈（EnemyAIController → report_enemy_killed、PickupItem → report_item_collected、DialogManager → report_npc_talked）
- [x] 前置任務鏈（`prerequisite_quest_id`）
- [x] 4 筆任務資料（quest_talk_blacksmith / kill_slime / collect_herb / clear_dungeon01）

---

## 🎉 目前已達成的完整遊玩閉環

```
Town Hub
  ├─ 接任務（鐵匠 × 3 / 任務板 × 1）
  ├─ 與教官對話
  └─ 進入傳送門
         ▼
    Dungeon 01
      ├─ Checkpoint（入口回血/存檔）
      ├─ 戰鬥（Slime / Archer / Boar）
      ├─ Checkpoint（Boss 前）
      └─ Boss（Boar）擊敗 → 任務自動完成
         ▼
    返回 Town Hub
      ├─ 向任務板/鐵匠回報 → 領獎勵
      └─ 教官對話切換（Boss 後版本）
```

---

## 已知限制（待後續處理）

| # | 問題 | 影響 | 對應排程 |
|---|------|------|---------|
| L1 | 任務系統無任何 UI（無日誌/HUD/通知） | 玩家無法得知任務狀態 | Phase 9A |
| L2 | Hotbar 綁定不進存檔 | 重新讀檔後需重綁 | Phase 9B |
| L3 | Checkpoint 重生點不跨重啟 | 重開遊戲後回 TownHub | Phase 9B |
| L4 | Boss 死亡無掉落/表演 | 體驗缺乏收尾感 | Phase 9C |
| L5 | 消耗品效果硬編碼（heal 25） | 無法擴充藥水種類 | Phase 9B |
| L6 | 玩家無等級屬性（minimum_level 形同虛設） | 任務等級限制無效 | 低優先，暫不排 |
| L7 | 無任何自動化測試 | 回歸測試全靠手動 | 持續欠債 |

---

---

# 後續排程

> 優先級：P1（必做）> P2（應做）> P3（可做）

---

## Phase 9A：任務系統 UI（P1 — 最高優先）

> **背景**：QuestManager 後端已完整，4 個 Signal（`quest_accepted` / `quest_progress_updated` / `quest_completed` / `quest_turned_in`）目前完全無訂閱者。玩家進行中的任務在畫面上完全不可見，是目前最大的體驗缺口。

### 9A-1 任務追蹤 HUD（螢幕右側）

**目標**：玩家在戰鬥中隨時能看到進行中任務的進度。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `QuestTrackerUI.tscn` + `QuestTrackerUI.gd` | 小(4-6h) | - | 右側顯示最多 3 筆進行中任務，每筆含名稱 + 進度（3/5） |
| 訂閱 `quest_accepted` / `quest_progress_updated` / `quest_turned_in` | 小(2h) | 上 | Signal 觸發後 HUD 自動更新，無需手動刷新 |
| 完成動畫（任務達標時閃金色） | 小(2h) | 上 | `quest_completed` 觸發時，該行文字短暫變色 |
| 加入 TownHub.tscn + Dungeon01.tscn | 小(1h) | 上 | 兩個場景均可見 HUD |

**驗收**：
- [ ] 接任務後 HUD 立即顯示該任務與進度
- [ ] 擊殺敵人/撿取物品後進度數字即時更新
- [ ] 任務達標時文字變色提示
- [ ] 交付任務後從 HUD 移除

---

### 9A-2 任務通知 Toast

**目標**：接取、完成、交付任務時顯示短暫的浮動通知。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `QuestToastUI.tscn` + `QuestToastUI.gd` | 小(3-4h) | - | 畫面頂端或中央顯示 2 秒浮動文字 |
| 接取通知（`quest_accepted`） | 小(1h) | 上 | 顯示「已接取：{任務名稱}」 |
| 完成通知（`quest_completed`） | 小(1h) | 上 | 顯示「任務完成：{任務名稱}」 |
| 交付通知（`quest_turned_in`） | 小(1h) | 上 | 顯示「任務回報：{任務名稱} +{金幣} 金」 |

**驗收**：
- [ ] 三種通知各有對應文字與顏色區分
- [ ] Toast 不堆疊（佇列播放，前一則結束後才顯示下一則）
- [ ] 不影響對話 UI / 背包 UI 的正常操作

---

### 9A-2.5 任務 UI 輸入恢復整合修復

**目標**：在 9A-1 / 9A-2 完成後，修復任務 UI 導入造成的輸入攔截、隱藏對話鎖定，以及任務板空狀態無法互動問題。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| 修復 `NPCQuestGiver` follow-up dialog 鎖定問題 | 小(1-2h) | 9A-2 | 接取/回報任務後玩家立即恢復操作 |
| HUD / 世界裝飾節點 `mouse_filter` 清理 | 小(2-3h) | 9A-1, 9A-2 | 滑鼠攻擊不再被 Toast / Tracker / Label / ColorRect 攔截 |
| 任務板空狀態 fallback dialog | 小(0.5h) | 上 | 任務回報完畢後任務板仍可用 `F` 互動 |
| Godot warning 清理 | 小(0.5-1h) | 上 | 無新增 warning / load error |

**驗收**：
- [x] 接取任務後可立即恢復移動與攻擊
- [x] Toast / Tracker / 世界提示不再擋滑鼠攻擊
- [x] 任務板在無任務時仍可顯示空狀態對話
- [x] Godot 專案可正常重新載入

---

### 9A-3 任務日誌介面（按 J 開啟）

**目標**：玩家可查看所有進行中任務的完整描述與進度，以及已完成任務清單。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `QuestJournalUI.tscn` + `QuestJournalUI.gd` | 中(1-2d) | - | 左側任務列表 + 右側詳情面板 |
| 進行中任務列表（含進度） | 小(4h) | 上 | 列出所有 active quest，顯示進度 bar |
| 已完成任務列表 | 小(2h) | 上 | 顯示 completed_quests（灰色）|
| 任務詳情面板 | 小(3h) | 上 | 點擊任務後右側顯示 `quest_description` + 目標 + 獎勵預覽 |
| J 鍵開關 + 加入 modal_ui 群組 | 小(1h) | 上 | 開啟時暫停其他輸入，關閉時還原 |
| project.godot 新增 `ui_quest_journal` 輸入動作 | 小(0.5h) | - | 按 J 觸發 |
| 加入 TownHub.tscn + Dungeon01.tscn | 小(1h) | 上 | 兩場景均可用 |

**驗收**：
- [ ] 按 J 可開關日誌，對話/背包開啟時不能同時打開
- [ ] 進行中任務顯示正確進度
- [ ] 點擊任務顯示完整描述與獎勵
- [ ] 已完成任務可在另一分頁或灰色區塊查閱

---

## Phase 9B：品質修復（P1 — 與 9A 並行或緊接）

> 修正 L2、L3、L5 已知限制，皆為獨立小任務，可單獨指派。

### 9B-1 Hotbar 綁定進存檔（Save v8）

**目標**：讀檔後快捷欄綁定自動還原。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `HotbarManager.to_save_dict()` / `from_save_dict()` | 小(2-3h) | - | 將 `hotbar_inventory_indices[5]` 序列化至存檔 |
| `SaveManager` 新增 `hotbar` 欄位 | 小(1h) | 上 | save_data 增加 `"hotbar": hotbar_manager_.to_save_dict()` |
| Save v8 migration（v7→v8） | 小(1h) | 上 | 舊存檔讀入時 hotbar 欄位預設為全 -1 |
| 讀檔後套用綁定 | 小(1h) | 上 | `from_save_dict` 呼叫時更新 HotbarRuntime，UI 自動重繪 |

**驗收**：
- [ ] F5 存檔後 F10 讀檔，快捷欄綁定完全還原
- [ ] 舊存檔（v7）正常讀入，快捷欄為空（不報錯）

---

### 9B-2 Checkpoint 重生點跨重啟（Save v8 附加）

**目標**：重開遊戲後在最後觸發的 Checkpoint 位置重生，而非強制回 TownHub。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:------|:------:|----------|
| `SceneTransitionManager` 新增 `to_save_dict()` / `from_save_dict()` | 小(2-3h) | - | 儲存 `{ scene_path, spawn_point_id, spawn_position }` |
| `SaveManager` 新增 `respawn` 欄位 | 小(1h) | 上 | 觸發 Checkpoint 時同步更新 respawn 資料 |
| 讀檔後自動切換至存檔場景 | 中(4-6h) | 上 | `load_game()` 成功後，若 respawn.scene_path ≠ 當前場景，執行場景切換 |
| Save v8 migration | 小(0.5h) | 上 | 舊存檔 respawn 預設為 TownHub Spawn_default |

**驗收**：
- [ ] 在 Dungeon01 Checkpoint 存檔，重開遊戲後在該 Checkpoint 附近重生
- [ ] 若存檔時在 TownHub，重開後仍在 TownHub

---

### 9B-3 消耗品系統擴充（ConsumableEffect）

**目標**：移除硬編碼的 `heal 25 HP`，改由資料驅動。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `ItemData` 新增 `consumable_effect` 欄位（enum：HEAL / BUFF_SPEED / ...） | 小(2h) | - | `ItemData.gd` 增加 `@export var consumable_effect: ConsumableEffect` |
| `consumable_heal_amount: float` 欄位 | 小(0.5h) | 上 | 藥水資源可設定回血量 |
| `Player.use_consumable()` 改讀資料 | 小(2h) | 上 | 依 `consumable_effect` 分派邏輯，移除 magic number 25 |
| 更新 `consumable_potion.tres` | 小(0.5h) | 上 | 設定 `consumable_effect = HEAL, consumable_heal_amount = 50` |

**驗收**：
- [ ] 使用藥水回血量由 `.tres` 資料決定，而非硬編碼
- [ ] 空格子不報錯，效果不同的道具可共存於背包

---

## Phase 9C：Boss Event Chain（P2）

> **背景**：Boss 死亡後目前無任何表演，缺乏收尾感。本階段讓擊殺 Boss 成為明確的「時刻」。

### 9C-1 Boss 死亡掉落

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `en_boar.tres` 補充 `loot_table`（必掉金幣500 + 機率裝備） | 小(1h) | - | 擊敗野豬王掉落可撿取物 |
| 驗證 `DropComponent` 在 Boss 死亡時正常觸發 | 小(1h) | 上 | 場景上出現 PickupItem |

**驗收**：
- [ ] 擊敗 Boss 後地上有掉落物

---

### 9C-2 Boss 死亡視覺演出

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| Boss 死亡時 HitStop 延長（0.5s） + 螢幕閃白 | 小(2-3h) | - | 最後一擊有明顯打擊感停頓 |
| 死亡動畫播完後淡出消失（tween） | 小(2h) | 上 | Boss 不是瞬間消失 |
| 播放 Boss 死亡音效 | 小(1h) | 上 | 有區別於普通敵人的音效 |

**驗收**：
- [ ] Boss 死亡有停頓感 + 淡出動畫
- [ ] 不影響 PersistentObject 的狀態儲存（死亡後重進不重生）

---

### 9C-3 Boss 死亡後傳送門高亮

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:------|:------:|----------|
| `Portal.gd` 新增 `activate_on_state_id` 屬性 | 小(2-3h) | - | 可監聽指定 SceneState 變為 defeated，Portal 視覺切換為「開啟」狀態 |
| Dungeon01 返回傳送門設定監聽 `dungeon01_boss_boar` | 小(0.5h) | 上 | Boss 死前傳送門顯示「尚未開放」，死後變為「前往城鎮」|

**驗收**：
- [ ] Boss 死亡前後傳送門視覺有明顯差異

---

## Phase 9D：存檔 v8 整合（P2，配合 9B-1 + 9B-2）

> 9B-1（Hotbar）、9B-2（Respawn）共同升版為 Save v8，統一在此任務完成。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `SAVE_VERSION = 8` | 小(0.5h) | 9B-1, 9B-2 | SaveManager 常數更新 |
| `_migrate_save_data` 新增 v7→v8 | 小(1h) | 上 | 補 `hotbar` 預設值 + `respawn` 預設值 |
| checksum 重新計算（移除舊 checksum 再算新） | 小(0.5h) | 上 | migration 後 erase checksum 觸發重算 |
| 5 次 Save/Load 循環驗收測試 | 小(1-2h) | 上 | 每次讀檔後 hotbar + respawn + quest 全部正確還原 |

**驗收**：
- [ ] v7 存檔讀入無錯誤
- [ ] v8 新存檔含 `hotbar` 與 `respawn` 欄位
- [ ] 所有欄位讀後一致

---

## Phase 10A：Dungeon 02（P2）

> **前置**：Phase 9A-1（HUD）建議完成後再做，確保新地城有任務追蹤支援。

### 10A-1 新敵人

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| 設計並實作第 4 種敵人（建議：魔法師型，有護盾/召喚） | 大(2-3d) | - | 有獨立 AI 狀態、攻擊方式與前 3 種明顯不同 |
| 新敵人資料（`en_mage.tres`）+ 掉落表 | 小(2h) | 上 | 有對應資料檔與掉落 |

---

### 10A-2 Dungeon 02 場景

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| `Dungeon02.tscn` 場景建立（2 Checkpoint + 新敵配置） | 中(1d) | - | 場景可從 TownHub 傳送到達 |
| TownHub 新增第二傳送門 | 小(2h) | 上 | 選擇 Dungeon01 或 Dungeon02 |
| `ZoneResetManager` 新增 Dungeon02 配置 | 小(1h) | 上 | ON_REENTER 普通敵人，NEVER Boss |

---

### 10A-3 Dungeon 02 任務

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| 新增 2-3 筆任務資料（.tres） | 小(2-3h) | - | 至少包含一個 KILL + 一個 COLLECT 任務 |
| 更新 TownHub 任務板可接任務清單 | 小(0.5h) | 上 | `available_quest_ids` 補入新任務 ID |

---

## Phase 10B：群體 AI（P3）

> 低優先，等 Dungeon 02 完成後視內容需求決定是否實作。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| Slime 群體包圍行為 | 中(1-2d) | - | 多隻 Slime 同時追擊時嘗試從不同方向包圍玩家 |
| 敵人間簡單通訊（廣播警報） | 中(1d) | 上 | 一隻發現玩家後，附近同類進入 Chase 狀態 |

**驗收**：
- [ ] 3 隻以上 Slime 同框時有包圍傾向，不全擠同一側
- [ ] 任一敵人被攻擊後，半徑 200px 內同類進入追擊

---

## Phase 10C：多階段 Boss（P3 — 長期）

> 長期目標，需先有 Dungeon 02 場景才有意義。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| Boss 血量閾值觸發第二階段 | 大(2-3d) | - | HP < 50% 時 AI 切換為強化模式（更快/新技能） |
| Boss 階段專屬技能 | 大(1-2d) | 上 | 至少一個第二階段特有攻擊 |
| Boss 視覺反饋（顏色/特效） | 中(1d) | 上 | 進入第二階段有明顯視覺變化 |

---

## 排程總覽

```
優先  Phase    內容                          相依性
────  ──────   ──────────────────────────   ──────────────────
P1    9A-1     任務追蹤 HUD                  無
P1    9A-2     任務通知 Toast                無
P1    9A-3     任務日誌介面（J 鍵）          無
P1    9B-1     Hotbar 進存檔                 無
P1    9B-2     Checkpoint 跨重啟重生         無
P1    9B-3     消耗品系統擴充                無
P1    9D       Save v8 整合                  9B-1, 9B-2
────  ──────   ──────────────────────────   ──────────────────
P2    9C-1     Boss 掉落                     無
P2    9C-2     Boss 死亡演出                 無
P2    9C-3     Boss 後傳送門高亮             9C-2
P2    10A-1    新敵人（第4種）               無
P2    10A-2    Dungeon 02 場景               10A-1
P2    10A-3    Dungeon 02 任務               10A-2
────  ──────   ──────────────────────────   ──────────────────
P3    10B      群體 AI                       10A-2（建議）
P3    10C      多階段 Boss                   10A-2
```

---

## 驗收格式參考

```markdown
### Task: 9A-1 任務追蹤 HUD
**Priority**: P1
**Effort**: 小(6-8h)
**Dependencies**: 無

#### Acceptance Criteria
- [ ] 右側 HUD 顯示最多 3 筆進行中任務（名稱 + 進度）
- [ ] 訂閱 quest_accepted / quest_progress_updated / quest_turned_in
- [ ] 任務達標時文字短暫閃金色
- [ ] TownHub + Dungeon01 均可見

#### 參考檔案
- `game/scripts/core/QuestManager.gd` — signal 定義
- `game/scripts/data/QuestInstance.gd` — get_progress_text()
- `game/scenes/ui/` — UI 場景放置位置
```

---

## 注意事項

- 每個 Resource 以 `.tres` 儲存並放在 `res://game/data/` 對應資料夾
- Save schema 請包含 `save_version`，升版時在 `_migrate_save_data` 補對應 migration
- 參考 `planning/tech_spec_notes.md` 的架構規範（Resource vs Instance vs DTO）
- UI 場景需加入 `modal_ui` 群組，確保開啟時 Portal / NPC Trigger 不誤觸
- 新 Autoload 請同步更新 `project.godot`
