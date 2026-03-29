# Codex Task Prompt

## 1. 任務背景

### 專案概覽
- **專案名稱**：異境 (Dream World)
- **引擎**：Godot 4.x
- **當前階段**：NPC 任務系統 — 玩法循環完整

### 已完成基礎
- ✅ NPC 對話系統（DialogManager、DialogUI）
- ✅ 敵人 AI（Slime/Archer/Boar）
- ✅ 背包系統（Inventory）
- ✅ 裝備系統（Equipment）
- ✅ 存檔系統（Save v6）

### 目標
建立完整的任務系統，讓玩家可以：
1. 從 NPC 接取任務
2. 追蹤任務進度（擊殺敵人、收集物品、對話）
3. 回報任務獲得獎勵
4. 任務狀態正確存檔

---

## 2. 當前任務

### 任務標題
NPC 任務系統

### 具體需求

#### 2.1 建立 QuestData（任務模板）

**檔案**：`game/scripts/data/QuestData.gd`

```gdscript
class_name QuestData
extends Resource

enum QuestType {
    KILL,       # 擊殺敵人
    COLLECT,    # 收集物品
    TALK,       # 與 NPC 對話
    DELIVER     # 交付物品
}

enum QuestStatus {
    NOT_STARTED,
    ACTIVE,
    COMPLETED,      # 完成但未回報
    TURNED_IN       # 已回報
}

@export var quest_id: StringName = &""
@export var quest_name: String = ""
@export_multiline var quest_description: String = ""
@export var quest_type: QuestType = QuestType.KILL

# 任務目標
@export var target_enemy_id: StringName = &""        # KILL 類型
@export var target_item_id: StringName = &""        # COLLECT/DELIVER 類型
@export var target_npc_id: StringName = &""         # TALK/DELIVER 類型
@export var target_amount: int = 1                  # 目標數量

# 獎勵
@export var reward_gold: int = 0
@export var reward_item_id: StringName = &""
@export var reward_item_amount: int = 0
@export var reward_weapon_id: StringName = &""      # 可選：獎勵武器

# 前置條件
@export var prerequisite_quest_id: StringName = &"" # 需先完成哪個任務
@export var minimum_level: int = 1                   # 最低等級要求
```

#### 2.2 建立 QuestInstance（任務實例）

**檔案**：`game/scripts/data/QuestInstance.gd`

```gdscript
class_name QuestInstance
extends RefCounted

var quest_id: StringName = &""
var quest_data: QuestData = null
var status: QuestData.QuestStatus = QuestData.QuestStatus.NOT_STARTED

# 進度追蹤
var current_progress: int = 0      # 當前進度（擊殺數/收集數）
var target_amount: int = 1         # 目標數量（從 quest_data 複製）

# 元資料
var accepted_at: String = ""       # ISO8601 時間戳
var completed_at: String = ""      # 完成時間
var turned_in_at: String = ""      # 回報時間

static func create_from_data(quest_data_: QuestData) -> QuestInstance
static func create_from_save_dict(quest_data_: QuestData, data_: Dictionary) -> QuestInstance
func to_save_dict() -> Dictionary

func is_completed() -> bool
func get_progress_text() -> String  # 如 "3/5"
```

#### 2.3 建立 QuestManager

**檔案**：`game/scripts/core/QuestManager.gd`

```gdscript
class_name QuestManager
extends Node

signal quest_accepted(quest_id: StringName)
signal quest_progress_updated(quest_id: StringName, current: int, target: int)
signal quest_completed(quest_id: StringName)      # 目標達成
signal quest_turned_in(quest_id: StringName)      # 已回報

var active_quests: Dictionary = {}      # quest_id -> QuestInstance
var completed_quests: Array[StringName] = []  # 已完成的任務 ID

# 任務模板快取
var quest_data_cache: Dictionary = {}   # quest_id -> QuestData

func _ready():
    _load_quest_data_from_files()

# 任務生命週期
func accept_quest(quest_id_: StringName) -> bool
func abandon_quest(quest_id_: StringName) -> bool
func turn_in_quest(quest_id_: StringName) -> bool  # 回報任務獲得獎勵

# 進度更新（由其他系統呼叫）
func report_enemy_killed(enemy_id_: StringName, count_: int = 1)
func report_item_collected(item_id_: StringName, count_: int = 1)
func report_npc_talked(npc_id_: StringName)

# 查詢
func get_active_quests() -> Array[QuestInstance]
func get_quest_by_id(quest_id_: StringName) -> QuestInstance
func has_active_quest(quest_id_: StringName) -> bool
func has_completed_quest(quest_id_: StringName) -> bool
func can_accept_quest(quest_data_: QuestData) -> bool

# 存檔
func to_save_dict() -> Dictionary
func from_save_dict(data_: Dictionary) -> bool
```

#### 2.4 任務進度追蹤整合

**A. 擊殺敵人追蹤**

在 `EnemyAIController` 或 `HealthComponent` 死亡時：
```gdscript
# EnemyAIController.gd 或 DeathComponent.gd
func _on_died() -> void:
    var quest_manager_ = _get_quest_manager()
    if quest_manager_ != null:
        quest_manager_.report_enemy_killed(enemy_data.enemy_id, 1)
```

**B. 收集物品追蹤**

在 `PickupItem` 被撿取時：
```gdscript
# PickupItem.gd
func _on_picked_up(player_: Player) -> void:
    # 原有邏輯...
    
    # 新增：回報任務
    var quest_manager_ = _get_quest_manager()
    if quest_manager_ != null and item_data != null:
        quest_manager_.report_item_collected(item_data.item_id, amount)
```

**C. 對話追蹤**

在 `DialogManager` 對話完成時：
```gdscript
# DialogManager.gd
func finish_dialog() -> void:
    # 原有邏輯...
    
    # 新增：回報任務
    if current_npc_id != &"":
        var quest_manager_ = _get_quest_manager()
        if quest_manager_ != null:
            quest_manager_.report_npc_talked(current_npc_id)
```

#### 2.5 NPC 對話整合任務

**檔案**：`game/scripts/components/NPCQuestGiver.gd`（新增）

```gdscript
class_name NPCQuestGiver
extends Node

@export var npc_id: StringName = &""
@export var available_quest_ids: Array[StringName] = []

# 檢查此 NPC 是否有任務可給
func get_available_quests() -> Array[QuestData]:
    var quest_manager_ = _get_quest_manager()
    var result_: Array[QuestData] = []
    
    for quest_id_ in available_quest_ids:
        var quest_data_ = quest_manager_.get_quest_data(quest_id_)
        if quest_data_ == null:
            continue
        if quest_manager_.can_accept_quest(quest_data_):
            result_.append(quest_data_)
    
    return result_

# 檢查此 NPC 是否有任務可回報
func get_turn_in_quests() -> Array[QuestInstance]:
    var quest_manager_ = _get_quest_manager()
    var active_quests_ = quest_manager_.get_active_quests()
    var result_: Array[QuestInstance] = []
    
    for quest_ in active_quests_:
        # 任務已完成（目標達成）且未回報，且回報對象是此 NPC
        if quest_.status == QuestData.QuestStatus.COMPLETED:
            if quest_.quest_data.target_npc_id == npc_id:
                result_.append(quest_)
    
    return result_
```

#### 2.6 任務獎勵發放

在 `QuestManager.turn_in_quest()` 中：
```gdscript
func turn_in_quest(quest_id_: StringName) -> bool:
    var quest_ = active_quests.get(quest_id_) as QuestInstance
    if quest_ == null or quest_.status != QuestData.QuestStatus.COMPLETED:
        return false
    
    var player_ = _get_player()
    if player_ == null:
        return false
    
    var quest_data_ = quest_.quest_data
    
    # 1. 發放金幣
    if quest_data_.reward_gold > 0:
        player_.add_gold(quest_data_.reward_gold)
    
    # 2. 發放物品
    if quest_data_.reward_item_id != &"" and quest_data_.reward_item_amount > 0:
        var item_data_ = _resolve_item_data(quest_data_.reward_item_id)
        if item_data_ != null:
            player_.inventory.add_item(item_data_, quest_data_.reward_item_amount)
    
    # 3. 發放武器（可選）
    if quest_data_.reward_weapon_id != &"":
        var weapon_data_ = _resolve_weapon_data(quest_data_.reward_weapon_id)
        if weapon_data_ != null:
            var weapon_instance_ = WeaponInstance.create_from_data(weapon_data_)
            player_.inventory.add_weapon(weapon_instance_)
    
    # 標記為已回報
    quest_.status = QuestData.QuestStatus.TURNED_IN
    quest_.turned_in_at = _get_iso8601_now()
    completed_quests.append(quest_id_)
    active_quests.erase(quest_id_)
    
    quest_turned_in.emit(quest_id_)
    return true
```

#### 2.7 存檔整合

**SaveManager 更新**：
```gdscript
# SaveManager.gd save_game()
var save_data_ = {
    "save_version": SAVE_VERSION,
    # ... 其他欄位 ...
    "quest": quest_manager.to_save_dict() if quest_manager != null else {}
}

# SaveManager.gd load_game()
var quest_manager_ = _get_quest_manager()
if quest_manager_ != null:
    quest_manager_.from_save_dict(migrated_data_.get("quest", {}))
```

#### 2.8 建立測試任務

**檔案**：`game/data/quests/`

建立 2-3 個測試任務：

```gdscript
# quest_kill_slime.tres
[gd_resource type="Resource" script_class="QuestData"]
script = ExtResource("quest_data_script")
quest_id = &"quest_kill_slime"
quest_name = "史萊姆清除計畫"
quest_description = "幫我消滅 5 隻史萊姆，牠們太煩人了！"
quest_type = 0  # KILL
target_enemy_id = &"en_slime"
target_amount = 5
reward_gold = 100
reward_item_id = &"consumable_potion"
reward_item_amount = 3

# quest_collect_herb.tres
[gd_resource type="Resource" script_class="QuestData"]
quest_id = &"quest_collect_herb"
quest_name = "採集草藥"
quest_description = "我需要 10 個草藥來製作藥水。"
quest_type = 1  # COLLECT
target_item_id = &"material_herb"
target_amount = 10
reward_gold = 50

# quest_talk_blacksmith.tres
quest_id = &"quest_talk_blacksmith"
quest_name = "拜訪鐵匠"
quest_description = "去和鐵匠打聲招呼，他可能有工作給你。"
quest_type = 2  # TALK
target_npc_id = &"npc_blacksmith"
target_amount = 1
reward_gold = 25
```

---

## 3. 技術約束

### 需要建立的檔案
```
game/scripts/data/QuestData.gd           [新建]
game/scripts/data/QuestInstance.gd       [新建]
game/scripts/core/QuestManager.gd        [新建]
game/scripts/components/NPCQuestGiver.gd [新建]
game/data/quests/quest_*.tres            [新建 2-3 個測試任務]
```

### 需要修改的檔案
```
game/scripts/core/SaveManager.gd         [修改 - 整合 quest 存檔]
game/scripts/core/DialogManager.gd       [修改 - 回報對話]
game/scripts/components/DropComponent.gd 或 EnemyAIController.gd [修改 - 擊殺回報]
game/scripts/items/PickupItem.gd         [修改 - 收集回報]
project.godot                            [修改 - QuestManager Autoload]
```

---

## 4. UI（可選，最小版本）

**最小 UI**：只在對話中顯示任務選項，無需獨立任務面板

**進階 UI**（未來擴充）：
- QuestTrackerUI：畫面側邊顯示進行中任務
- QuestLogUI：完整任務列表與詳情

本任務先完成**最小版本**，UI 僅使用對話系統整合。

---

## 5. 輸出要求

### 完成後標記
1. 更新下方「任務狀態」
2. 填寫「實作摘要」
3. 列出「修改檔案清單」
4. 描述測試方式（如何測試接取、進度、回報任務）

---

## 6. 任務狀態

- [x] **進行中** → [x] **已完成**

### 實作摘要
- 已新增 `QuestData`、`QuestInstance`、`QuestManager`，支援任務模板、任務實例、進度更新、回報獎勵與存檔序列化。
- 已整合敵人擊殺、物品撿取、NPC 對話結束等事件來源，讓 KILL / COLLECT / TALK 類型任務能自動推進。
- 已新增 `NPCQuestGiver` 並接到 `NPCDialogTrigger`，黑鐵匠現在可透過對話接取任務、查看進度、回報任務，且保留原本聊天流程入口。

### 修改檔案清單
- `game/scripts/data/QuestData.gd`
- `game/scripts/data/QuestInstance.gd`
- `game/scripts/core/QuestManager.gd`
- `game/scripts/components/NPCQuestGiver.gd`
- `game/scripts/core/DialogManager.gd`
- `game/scripts/components/NPCDialogTrigger.gd`
- `game/scripts/items/PickupItem.gd`
- `game/scripts/enemies/EnemyAIController.gd`
- `game/scripts/core/SaveManager.gd`
- `game/scenes/Arena_Test.tscn`
- `project.godot`
- `game/data/quests/quest_talk_blacksmith.tres`
- `game/data/quests/quest_kill_slime.tres`
- `game/data/quests/quest_collect_herb.tres`

### 測試驗證
- 已執行 Godot `--headless --path . --import`，確認 quest 相關腳本與資源能被掃描、註冊與載入。
- 手動測試建議：
  1. 進入 `Arena_Test`，與鐵匠對話接取 `初次拜訪鐵匠`，結束對話後再次交談確認可回報。
  2. 回報後再次與鐵匠對話，接取 `史萊姆清除計畫`，擊殺場景中的史萊姆後回來確認進度與回報獎勵。
  3. 回報後用既有 debug 補道具方式取得草藥，接取 `採集草藥`，確認收集進度與回報獎勵。
  4. 使用既有存檔流程（F5/F9）確認任務狀態、進度與已回報任務能正確保存與讀回。

### 備註/問題
- `--headless --path . --quit-after 60` 在這個環境仍會直接 crash，沒有額外輸出 quest 相關 script error；目前可確認 import/腳本註冊正常，但完整執行階段仍建議在本機 Godot 編輯器或非 sandbox 環境再驗一次。
