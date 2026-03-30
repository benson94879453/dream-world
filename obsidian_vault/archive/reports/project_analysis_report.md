# 異境 (Dream World) 專案完整分析報告

> 已歸檔，僅供歷史分析參考。

---

## 一、整體技術棧

|層面|技術|
|---|---|
|**引擎**|Godot 4.6（`config/features=PackedStringArray("4.6", "Forward Plus")`）|
|**語言**|GDScript（純 GDScript，無 C# 混用，雖然 `project.godot` 有 `[dotnet]` 區塊但未實際使用）|
|**渲染**|Forward Plus / D3D12（Windows）|
|**物理**|Jolt Physics（3D）+ Godot 2D 物理|
|**存檔格式**|JSON（`user://savegame.json`）|
|**資料格式**|Godot Resource（`.tres`）作為靜態模板|
|**文件系統**|Obsidian Vault（含 Markdown 設計文件、devlog、review）|

---

## 二、專案整體架構

```
dream-world/
├── game/                    # 遊戲主體
│   ├── assets/              # 素材（characters/entities/weapon）
│   ├── audio/               # 音效（目錄存在，內容未讀）
│   ├── autoload/            # 空目錄（autoload 腳本在 scripts/core/）
│   ├── data/                # .tres 資源檔（Sources of Truth）
│   │   ├── affixes/         # 詞綴表
│   │   ├── dialogs/         # 對話資源（3個）
│   │   ├── enemies/         # 敵人資料（3種）
│   │   ├── gears/           # 裝備（4件鐵製裝備）
│   │   ├── items/           # 物品（12個）
│   │   ├── loot_tables/     # 掉落表
│   │   ├── quests/          # 任務資料（4個）
│   │   ├── runes/           # 符文（12個）
│   │   ├── upgrades/        # 升級成本表
│   │   └── weapons/         # 武器（6個，多數是測試用）
│   ├── scenes/              # 場景 .tscn
│   │   ├── levels/          # TownHub.tscn、Dungeon01.tscn
│   │   ├── npcs/            # InstructorNPC.tscn
│   │   ├── ui/              # 8個 UI 場景
│   │   ├── enemies/         # 敵人場景
│   │   ├── interactables/   # Portal.tscn、Checkpoint.tscn
│   │   └── ...
│   ├── scripts/             # GDScript 腳本
│   │   ├── core/            # 12個 Autoload 管理器
│   │   ├── data/            # 23個資料模型
│   │   ├── combat/          # 戰鬥組件（7個）
│   │   ├── player/          # 玩家狀態機（7個狀態）
│   │   ├── enemies/         # 敵人 AI（9個）
│   │   ├── inventory/       # 背包/裝備（3個）
│   │   ├── ui/              # UI 腳本（9個）
│   │   ├── components/      # 可掛載組件（4個）
│   │   ├── interactables/   # Portal/Checkpoint
│   │   ├── npcs/            # InstructorNPC
│   │   ├── items/           # PickupItem
│   │   ├── weapons/         # 武器邏輯（6個）
│   │   ├── effects/         # HitEffect
│   │   └── debug/           # 測試工具（2個）
│   └── ui/                  # 空目錄（UI 場景在 scenes/ui/）
├── obsidian_vault/          # 設計文件與 devlog
└── project.godot            # 引擎設定，12個 Autoload
```

### Autoload 清單（全局單例）

|Autoload|功能|
|---|---|
|`SaveManager`|存檔/讀檔，版本遷移，Save v7|
|`DialogManager`|對話流程控制，flags 管理|
|`QuestManager`|任務接取/追蹤/回報|
|`UpgradeManager`|武器升級（星級/詞綴）|
|`RuneManager`|符文鑲嵌/拆卸|
|`DecomposeManager`|武器分解，經濟獎勵|
|`RuneTestManager`|Debug 符文測試（僅開發用）|
|`HotbarRuntime`|快捷欄綁定邏輯|
|`HitStopManager`|打擊暫停（局部時間暫停）|
|`SceneTransitionManager`|場景切換，淡入淡出，重生點管理|
|`SceneStateManager`|場景物件狀態持久化|
|`ZoneResetManager`|區域重置策略（敵人/普通/Boss）|

---

## 三、任務系統（Quest System）完整分析

### 3.1 任務相關檔案清單

|檔案路徑|角色|
|---|---|
|`game/scripts/data/QuestData.gd`|任務資料模型（Resource）|
|`game/scripts/data/QuestInstance.gd`|任務執行期實例（RefCounted）|
|`game/scripts/core/QuestManager.gd`|Autoload，核心管理器|
|`game/scripts/components/NPCQuestGiver.gd`|NPC 任務發布/回報組件|
|`game/scripts/components/NPCDialogTrigger.gd`|NPC 互動觸發器（整合 QuestGiver）|
|`game/scripts/core/DialogManager.gd`|對話結束後自動呼叫 `report_npc_talked`|
|`game/scripts/enemies/EnemyAIController.gd`|死亡時呼叫 `report_enemy_killed`|
|`game/scripts/items/PickupItem.gd`|撿取時呼叫 `report_item_collected`|
|`game/scripts/core/SaveManager.gd`|存/讀任務狀態（quest 欄位）|
|`game/data/quests/*.tres`|4 個任務資源檔|
|`game/scenes/levels/TownHub.tscn`|含鐵匠NPC（3個任務）+任務板（1個任務）|
|`game/scenes/levels/Dungeon01.tscn`|Boss 配置有 PersistentObject（任務完成觸發）|

### 3.2 資料模型

**QuestData（靜態模板，存成 .tres）**

```
class_name QuestData extends Resource

enum QuestType { KILL, COLLECT, TALK, DELIVER }
enum QuestStatus { NOT_STARTED, ACTIVE, COMPLETED, TURNED_IN }

@export var quest_id: StringName
@export var quest_name: String
@export var quest_description: String
@export var quest_type: QuestType

@export var target_enemy_id: StringName   # 用於 KILL
@export var target_item_id: StringName    # 用於 COLLECT / DELIVER
@export var target_npc_id: StringName     # 用於 TALK，也決定向哪個NPC回報
@export var target_amount: int

@export var reward_gold: int
@export var reward_item_id: StringName
@export var reward_item_amount: int
@export var reward_weapon_id: StringName  # 可以獎勵武器實例

@export var prerequisite_quest_id: StringName  # 前置任務
@export var minimum_level: int = 1             # 等級限制
```

**QuestInstance（執行期動態資料）**

```
class_name QuestInstance extends RefCounted

var quest_id: StringName
var quest_data: QuestData
var status: QuestStatus              # NOT_STARTED / ACTIVE / COMPLETED / TURNED_IN
var current_progress: int
var target_amount: int
var accepted_at: String              # ISO 8601 UTC 時間戳
var completed_at: String
var turned_in_at: String
```

### 3.3 任務 CRUD 操作

|操作|方法|說明|
|---|---|---|
|**Create（接取）**|`QuestManager.accept_quest(quest_id)`|建立 QuestInstance，加入 active_quests，同步 COLLECT/DELIVER 初始進度|
|**Read（查詢）**|`get_quest_by_id(quest_id)` / `get_active_quests()` / `get_quest_data(quest_id)`|讀取進行中任務或任務模板|
|**Update（更新進度）**|`report_enemy_killed()` / `report_item_collected()` / `report_npc_talked()`|由各系統主動推送，自動判定完成條件|
|**Delete（放棄）**|`abandon_quest(quest_id)`|從 active_quests 移除，無任何 penalty|
|**Complete（交付）**|`turn_in_quest(quest_id)`|發放獎勵（金幣/物品/武器），移至 completed_quests|

### 3.4 任務狀態機

```
NOT_STARTED  ──accept_quest()──►  ACTIVE
                                   │
                                   │ 進度達標（_set_progress）
                                   ▼
                               COMPLETED ◄── 進度退回（自動降回 ACTIVE）
                                   │
                                   │ turn_in_quest()（DELIVER 需扣物品）
                                   ▼
                               TURNED_IN
                                   │
                                   │ 從 active_quests 移除
                                   │ 加入 completed_quests
                                   ▼
                             （歷史紀錄保留）
```

**COLLECT 型特別設計**：進度只增不減（取 `max(current, inventory_count)`） **DELIVER 型特別設計**：進度與背包數量同步（可因物品減少而退回 ACTIVE）

### 3.5 任務進度觸發鏈

```
敵人死亡
  └─ EnemyAIController.die()
       └─ QuestManager.report_enemy_killed(enemy_id, 1)
            └─ _set_progress() → 自動完成/回報 Signal

物品撿取
  └─ PickupItem._on_pickup_success()
       └─ QuestManager.report_item_collected(item_id)
            └─ _sync_item_progress() → 讀背包數量

NPC 對話結束
  └─ DialogManager.end_dialog()
       └─ QuestManager.report_npc_talked(npc_id)
            └─ _set_progress(+1) → 完成 TALK 任務
```

### 3.6 任務相關 Signal

|Signal|定義位置|說明|是否有訂閱者|
|---|---|---|---|
|`quest_accepted(quest_id)`|QuestManager|接任務|**無任何 UI/腳本訂閱**|
|`quest_progress_updated(quest_id, current, target)`|QuestManager|進度更新|**無任何 UI/腳本訂閱**|
|`quest_completed(quest_id)`|QuestManager|任務達成條件|**無任何 UI/腳本訂閱**|
|`quest_turned_in(quest_id)`|QuestManager|交付完成|**無任何 UI/腳本訂閱**|

### 3.7 現有任務資料

|quest_id|名稱|類型|目標|前置|獎勵|
|---|---|---|---|---|---|
|`quest_talk_blacksmith`|初次拜訪鐵匠|TALK|`npc_blacksmith` x1|無|25 金|
|`quest_kill_slime`|史萊姆清除計畫|KILL|`en_slime_basic` x5|`quest_talk_blacksmith`|100金 + 藥水x2|
|`quest_collect_herb`|採集草藥|COLLECT|`mat_herb` x10|`quest_kill_slime`|80金 + 藥水x3|
|`quest_clear_dungeon01`|清除地城威脅|KILL|`en_boar` x1|無|500 金|

### 3.8 NPC 任務架構

**鐵匠（Blacksmith）**：

- 使用 `NPCDialogTrigger`（`npc_id = "npc_blacksmith"`）整合 `NPCQuestGiver`
- 可接任務：`quest_talk_blacksmith`、`quest_kill_slime`、`quest_collect_herb`
- 有對話資源：`dlg_blacksmith_intro.tres`
- 任務回報目標：`target_npc_id = "npc_blacksmith"`（需對鐵匠回報 kill/collect）

**任務板（QuestBoard）**：

- 使用 `NPCDialogTrigger`（`npc_id = "npc_quest_board"`）整合 `NPCQuestGiver`
- 可接任務：`quest_clear_dungeon01`
- **無對話資源**（`dialog_data` 為 null）—— 靠 NPCQuestGiver 動態生成選單對話

**教官（InstructorNPC）**：

- 使用獨立腳本 `InstructorNPC.gd`，根據 Boss 狀態切換對話
- 不是 QuestGiver，純對話 NPC

### 3.9 存檔整合

任務狀態在 Save v7 中完整保存：

```
"quest": {
  "active_quests": [
    {
      "quest_id": "quest_kill_slime",
      "status": 1,
      "current_progress": 3,
      "target_amount": 5,
      "accepted_at": "2026-03-29T10:00:00Z",
      "completed_at": "",
      "turned_in_at": ""
    }
  ],
  "completed_quests": ["quest_talk_blacksmith"]
}
```

---

## 四、已實作功能

### 任務系統

- **4種任務類型**：KILL / COLLECT / TALK / DELIVER（前三種有實際資料，DELIVER 邏輯完整但無範例資料）
- **完整生命週期**：接取 → 進行 → 完成條件判定 → 交付 → 獎勵發放
- **3種進度觸發**：敵人擊殺、物品撿取、NPC 對話
- **前置任務鏈**：`prerequisite_quest_id` 機制，任務板顯示鏈式依存
- **等級限制**：`minimum_level`（但 Player 無 level 屬性，永遠返回 1）
- **動態 NPC 對話選單**：`NPCQuestGiver.build_runtime_dialog()` 動態組合接取/回報選項
- **存檔/讀檔**：完整序列化至 JSON，`create_from_save_dict` 正確還原
- **放棄任務**：`abandon_quest()` 實作但無 UI 入口
- **COLLECT 特殊邏輯**：接任務時立即同步背包數量
- **DELIVER 特殊邏輯**：交任務時扣除背包物品，物品不足則失敗
- **時間戳記錄**：ISO 8601 格式記錄接受/完成/交付時間
- **版本遷移**：Save v6→v7 的 quest 欄位遷移

### 整體遊戲系統（已完成）

- 核心 ARPG 戰鬥（8方向、Combo、Dash）
- Hit Stop 打擊感
- 3種敵人 AI（Slime/Archer/Boar）
- 武器系統（劍/法杖、星級升級、詞綴、符文槽）
- 12種符文石（含4種核心符文機制）
- 武器分解經濟循環
- 20格背包（三型態：物品/武器/裝備）
- 裝備系統（5個槽位：武器/頭/胸/腿/靴）
- NPC 對話系統（逐字顯示、選項分支、flags）
- 場景切換（淡入淡出、重生點管理）
- Checkpoint 存檔點（自動觸發、視覺反饋）
- 場景狀態持久化（Boss 永久死亡、Checkpoint 啟用狀態）
- 區域重置策略（普通敵人重置、Boss 不重置）
- 存檔系統（Save v7 + SHA256 checksum + 版本遷移）

---

## 五、缺失或不完整的功能

### 任務系統缺失

|缺失項目|嚴重性|說明|
|---|:-:|---|
|**任務日誌 UI（Quest Journal）**|高|QuestManager 有完整 Signal，但**完全沒有**任何 UI 訂閱這些 Signal。玩家進行中的任務沒有任何畫面顯示。|
|**任務追蹤 HUD**|高|沒有螢幕上顯示「目前任務進度」的元素（如右側追蹤欄）|
|**任務接取/完成通知**|中|`quest_accepted`、`quest_completed`、`quest_turned_in` 4個 Signal 全部無訂閱者，無任何視覺/音效通知|
|**DELIVER 型任務資料**|中|DELIVER 類型的邏輯完整，但 `game/data/quests/` 中**零個** DELIVER 類型任務|
|**放棄任務的 UI 入口**|低|`abandon_quest()` 有實作，但玩家無法從任何 UI 操作放棄任務|
|**玩家等級系統**|低|`QuestData.minimum_level` 有欄位，`QuestManager._get_player_level()` 有完整實作（含 fallback），但 `PlayerController` 根本沒有 `level` 屬性，永遠回傳 1，等級限制形同虛設|
|**任務 NPC 互動標示**|低|地圖上沒有「!」「?」等標準 RPG 任務可用標示（雖有對話提示，但無視覺化任務狀態）|
|**多目標任務**|低|每個任務只有一個目標（一種敵人/物品/NPC），不支援「殺 3 隻史萊姆 + 收集 5 個草藥」複合任務|

### 整體遊戲缺失

|項目|說明|
|---|---|
|**Hotbar 綁定不進存檔**|`01_MVP_TODO.md` 明確標注：`⚠️ Hotbar 綁定尚未進存檔`|
|**Checkpoint 重生點跨重啟**|重開遊戲後回到 TownHub，不保存最後重生場景|
|**Boss Event Chain**|Boss 死亡後無掉落、無特殊表演|
|**消耗品效果硬編碼**|`⚠️ 消耗品效果為通用 heal 25 HP`|
|**自動化測試**|場景切換 + Boss 擊殺 + 讀檔 的完整自動化測試尚未建立|
|**武器資料完整度**|只有測試用武器（`test_weapon.tres`、`test_staff_weapon.tres` 等），無正式遊戲用武器（除了 `wpn_unarmed`）|
|**商人/治療師 NPC**|設計文件中列為待規劃|
|**群體 AI**|Slime 群體協作（包圍、支援）列為低優先|
|**多階段 Boss**|設計文件列為長期目標|
|**Dungeon 02**|目前只有 Dungeon01|
|**音效資源**|`game/audio/` 目錄存在但未檢視內容|
|**存檔 v8**|保存當前場景+重生點（列為下一階段選項）|
|**世界/devlog 文件**|`obsidian_vault/world/` 和 `obsidian_vault/devlog/` 是空目錄|
|**design/specs 目錄空白**|`obsidian_vault/design/` 和 `obsidian_vault/specs/` 均為空目錄|

---

## 六、TODO / FIXME / 已知問題標記

程式碼中**沒有任何** `TODO`、`FIXME`、`HACK` 標記（搜尋結果為空），代碼品質相對整潔。

所有待辦事項都集中記錄在 Obsidian 文件中：

|文件位置|未完成項目|
|---|---|
|`obsidian_vault/0324/01_MVP_TODO.md` 第 103 行|`⚠️ 拆卸金幣扣減：UI已做，待貨幣系統實裝`（但實際上已完成？需確認）|
|`01_MVP_TODO.md` 第 185-186 行|`⚠️ 投射物只往左/右飛`（標記為已修復 #018+）|
|`01_MVP_TODO.md` 第 228-230 行|`⚠️ Hotbar 綁定尚未進存檔` / `⚠️ 消耗品效果為通用 heal 25 HP` / `⚠️ Inventory 仍混有裝備責任`|
|`01_MVP_TODO.md` 第 281-284 行（D節）|QuestManager skeleton（但實際已完成，文件未更新）|
|`codex_prompt.md`|3個已知限制：Checkpoint跨重啟、Boss Event Chain、自動化測試缺失|
|`review_020_hub_vertical_slice_complete.md`|同上3個已知限制|
|`SYNC_SUMMARY.md` 下一階段選項|A.Playtest / B.Boss Event Chain / C.存檔v8 / D.Dungeon02 / E.存檔點啟用恢復|

**注意**：`01_MVP_TODO.md` 第 281-284 行的「D. NPC 任務系統」仍顯示為 `[ ]` 未完成狀態，但實際上 QuestManager 已完整實作。這是**文件與程式碼不同步**的問題。

---

## 七、架構優點與亮點

1. **Data-Driven 設計徹底**：所有 QuestData 以 `.tres` 儲存，新增任務只需加資源檔，無需改程式碼
2. **Signal 解耦良好**：QuestManager 定義了4個完整 Signal，各系統透過推送方式更新進度（無直接依賴）
3. **存檔版本化**：Save v7 含 `save_version` + `checksum` + 完整遷移函式，向後相容性強
4. **防禦性程式設計**：所有方法都有 null 檢查、邊界保護、assert 斷言
5. **命名一致性**：嚴格遵循「參數名結尾加底線」、`snake_case`、`#region`/`#endregion` 區塊
6. **時間戳完整**：任務實例記錄接受/完成/交付的 ISO 8601 UTC 時間，有助 debug 和未來分析

---

## 八、總結

**任務系統後端實作完整度**：約 **90%**

核心邏輯（4種類型、前置依存、進度追蹤、交付獎勵、存讀檔）均已完整實作，架構設計乾淨。

**任務系統前端（UI）實作完整度**：約 **20%**

NPC 對話中的動態任務選單（接取/回報）已實作，但缺少**任務日誌介面**、**進度追蹤 HUD**、**任務通知**。4個 QuestManager Signal 完全無人訂閱，是最明顯的待補空缺。
