# Codex 開發任務 Prompt

> 最後更新: 2026-03-27
> 本文件由 Kimi 維護，每次新任務直接覆寫此檔案

---

## 任務背景

### 專案概覽
- **專案名稱**: 異境 (Dream World)
- **引擎**: Godot 4.x
- **類型**: 2D 動作探索遊戲
- **目前階段**: Phase 3 - 背包/掉落/存檔系統（最後任務）

### Phase 3 已完成
- **#005 Inventory 基礎**: ✅ 20格背包，stackable + unique
- **#006 Loot/Drop**: ✅ 掉落表、拾取、背包滿處理

### 當前目標
建立完整的存檔與讀檔系統，支援：
- 玩家資料（HP、位置、當前武器）
- 背包內容（stackable 物品 + weapons）
- 版本遷移（未來擴充相容）

---

## 當前任務

### 任務標題
#007 Save/Load 存檔與讀檔系統

### 任務描述
建立遊戲的存檔與讀檔機制，讓玩家可以保存進度並在之後繼續遊戲。這是 Phase 3 的最後一環，也是 MVP 的重要里程碑。

### 具體需求

#### 1. 建立 SaveManager (Autoload)
建立 `game/scripts/core/SaveManager.gd`：

```gdscript
class_name SaveManager
extends Node

const SAVE_VERSION: int = 1
const SAVE_FILE_PATH: String = "user://savegame.json"

signal save_completed(success: bool)
signal load_completed(success: bool)

# 存檔
func save_game() -> bool:
    # 1. 收集所有需要保存的資料
    # 2. 轉換為 DTO (Dictionary)
    # 3. 寫入 JSON 檔案
    # 4. 發出 save_completed 信號
    pass

# 讀檔
func load_game() -> bool:
    # 1. 讀取 JSON 檔案
    # 2. 驗證 save_version
    # 3. 還原所有資料
    # 4. 發出 load_completed 信號
    pass

# 檢查是否有存檔
func has_save_file() -> bool:
    return FileAccess.file_exists(SAVE_FILE_PATH)

# 刪除存檔（新遊戲用）
func delete_save() -> bool
```

#### 2. 建立 SaveDTO 結構
存檔 JSON 結構（參考 Tech Spec）：

```json
{
  "save_version": 1,
  "created_at": "2026-03-27T20:00:00Z",
  "updated_at": "2026-03-27T22:30:00Z",
  
  "player": {
    "current_hp": 85,
    "global_position": {"x": 100.5, "y": 200.0},
    "equipped_weapon_uid": "wpn_001"
  },
  
  "inventory": {
    "stackables": [
      {"item_id": "mat_herb", "amount": 15},
      {"item_id": "cns_potion", "amount": 3}
    ],
    "weapons": [
      {
        "instance_uid": "wpn_001",
        "weapon_id": "test_weapon",
        "enhance_level": 0
      },
      {
        "instance_uid": "wpn_002",
        "weapon_id": "test_staff_weapon",
        "enhance_level": 0
      }
    ]
  },
  
  "progression": {
    "unlocked_souls": ["codex_slime"],
    "flags": {"zone_2_unlocked": false}
  }
}
```

#### 3. 實作 Player 資料序列化
在 `Player.gd` 新增：

```gdscript
# 轉換為存檔資料
func to_save_dict() -> Dictionary:
    return {
        "current_hp": health_component.current_hp,
        "global_position": {"x": global_position.x, "y": global_position.y},
        "equipped_weapon_uid": inventory.get_equipped_weapon_uid()
    }

# 從存檔資料還原
func from_save_dict(data: Dictionary) -> void:
    health_component.current_hp = data.get("current_hp", health_component.max_hp)
    global_position = Vector2(
        data.get("global_position", {}).get("x", 0.0),
        data.get("global_position", {}).get("y", 0.0)
    )
    # 武器還原由 Inventory 處理後再裝備
```

#### 4. 實作 Inventory 資料序列化
在 `Inventory.gd` 新增：

```gdscript
# 轉換為存檔資料
func to_save_dict() -> Dictionary:
    var stackables := []
    var weapons := []
    
    for slot in slots:
        if slot.weapon_instance != null:
            weapons.append({
                "instance_uid": slot.weapon_instance.instance_uid,
                "weapon_id": slot.weapon_instance.weapon_id,
                "enhance_level": slot.weapon_instance.enhance_level
            })
        elif slot.item_data != null:
            stackables.append({
                "item_id": slot.item_data.item_id,
                "amount": slot.amount
            })
    
    return {
        "stackables": stackables,
        "weapons": weapons
    }

# 從存檔資料還原
func from_save_dict(data: Dictionary) -> void:
    clear()  # 清空現有背包
    
    # 還原 stackables
    for item_data in data.get("stackables", []):
        var item_id = item_data.get("item_id")
        var amount = item_data.get("amount", 1)
        # 根據 item_id 載入 ItemData resource，add_item()
    
    # 還原 weapons
    for weapon_data in data.get("weapons", []):
        var weapon_id = weapon_data.get("weapon_id")
        # 根據 weapon_id 載入 WeaponData，建立 WeaponInstance
        # add_weapon(instance)

# 獲取當前裝備武器的 UID
func get_equipped_weapon_uid() -> String:
    # 從 WeaponController 取得當前裝備的武器 instance_uid
    pass

# 根據 UID 裝備武器
func equip_weapon_by_uid(uid: String) -> bool
```

#### 5. 更新 project.godot Autoload
在 `project.godot` 新增：
```
[autoload]
SaveManager="*res://game/scripts/core/SaveManager.gd"
```

#### 6. Debug 指令
在 `Player.gd` 或 `DebugOverlay` 添加：
- 按鍵 `F5`: 存檔 (`SaveManager.save_game()`)
- 按鍵 `F9`: 讀檔 (`SaveManager.load_game()`)
- Console 顯示存檔/讀檔結果

#### 7. 版本遷移（基礎）
在 `SaveManager`：

```gdscript
func _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    # 如果存檔版本低於目前版本，進行遷移
    if from_version < 1:
        # 未來版本遷移邏輯
        pass
    return data
```

#### 8. Arena_Test 整合
在 `Arena_Test.tscn` 啟動時：
- 檢查是否有存檔 (`SaveManager.has_save_file()`)
- 若無，使用預設狀態（目前行為）
- 若有，載入存檔（讀檔流程）

### 驗收標準 (Acceptance Criteria)
- [ ] `SaveManager` Autoload 存在，有 `save_game()` 和 `load_game()`
- [ ] 按 F5 存檔，Console 顯示成功/失敗
- [ ] 按 F9 讀檔，Console 顯示成功/失敗
- [ ] 存檔後關閉遊戲，重新開啟後讀檔，玩家位置正確
- [ ] 存檔後背包內容正確保存（stackables + weapons）
- [ ] 存檔後裝備武器正確保存
- [ ] 存檔後 HP 正確保存
- [ ] 存檔 JSON 有 `save_version` 欄位
- [ ] 讀檔時驗證版本，過舊版本可安全處理（至少不 crash）
- [ ] 新遊戲（無存檔）可正常開始

### 技術約束
- 存檔路徑使用 `user://savegame.json`（Godot 跨平台使用者目錄）
- JSON 格式，人類可讀，方便除錯
- 序列化時只存 ID，不存整個 Resource
- 還原時根據 ID 重新載入 Resource
- WeaponInstance 的 UID 使用 `str(randi())` 或遞增計數器
- 遵循現有命名風格 (snake_case)

### 參考檔案
```
game/scripts/core/SaveManager.gd         # 需新增
game/scripts/Player.gd                    # 需修改（to_save_dict, from_save_dict）
game/scripts/inventory/Inventory.gd       # 需修改（序列化）
game/scripts/inventory/InventorySlot.gd   # 參考
project.godot                             # 需修改（Autoload）
game/scenes/Arena_Test.tscn               # 可選（啟動時讀檔）
```

### 架構說明

**存檔流程：**
```
F5 按下
 │
 ▼
SaveManager.save_game()
 │
 ▼
收集資料:
  - Player.to_save_dict() → player 資料
  - Inventory.to_save_dict() → inventory 資料
  - progression 資料（目前可先放 placeholder）
 │
 ▼
組成 SaveDTO (Dictionary)
 │
 ▼
寫入 user://savegame.json
 │
 ▼
發出 save_completed 信號
```

**讀檔流程：**
```
F9 按下（或啟動時自動）
 │
 ▼
SaveManager.load_game()
 │
 ▼
讀取 user://savegame.json
 │
 ▼
驗證 save_version
 │
 ▼
還原資料:
  - Player.from_save_dict() → 還原位置、HP
  - Inventory.from_save_dict() → 清空後重新添加
  - equip_weapon_by_uid() → 裝備正確武器
 │
 ▼
發出 load_completed 信號
```

---

## 輸出要求

1. **完成後請更新此檔案底部「任務狀態」為已完成**
2. **簡要說明實作內容** (2-3 行)
3. **列出修改的檔案清單**
4. **標註任何遇到的問題或需要討論的設計決策**

---

## 任務狀態

- [ ] 進行中
- [x] 已完成

### 實作摘要
- 新增 `SaveManager` autoload、`Player` / `Inventory` / `WeaponInstance` 的序列化與還原 API，存檔格式為可讀 JSON，包含 `save_version`、玩家資料、背包 stackables、武器清單與 progression placeholder。
- `Arena_Test` 已整合啟動時自動讀檔；`Player` 也加入 F5 存檔、F9 讀檔的 debug 操作，並支援還原位置、HP、背包內容與當前裝備武器。
- 以 headless smoke 驗證存檔與讀檔完整流程，確認 `save=true`、`load=true`，並從 `user://savegame.json` 讀回 `save_version=1`、HP 與裝備武器 UID。

### 修改檔案
- `game/scripts/core/SaveManager.gd`
- `game/scripts/core/ArenaTest.gd`
- `game/scripts/Player.gd`
- `game/scripts/inventory/Inventory.gd`
- `game/scripts/data/WeaponInstance.gd`
- `game/scenes/Arena_Test.tscn`
- `project.godot`
- `obsidian_vault/codex_prompt.md`

### 備註/問題
- Godot autoload 名稱若與 `class_name SaveManager` 相同會直接報衝突，因此本次保留 autoload 名稱 `SaveManager`，但 `SaveManager.gd` 不再宣告同名 `class_name`。
- 為了避免依賴 `AppData` 外部路徑直接讀檔，本次驗證改由 `Arena_Test` 在 `DW_RUN_SAVE_SMOKE=1` 時跑內建 smoke flow：先存檔，再改亂狀態，再讀檔並列印結果；平常遊戲流程不會啟用。
