# 武器強化與裝備系統規格

> 已歸檔，僅供歷史規格參考。

> Phase 8 完整架構規格
> 最後更新: 2026-03-29

---

## 1. 系統目標

### 1.1 支援的內容類型

系統第一版需支援三類內容：

| 類型 | 特性 | 儲存方式 |
|-----|------|---------|
| **一般物品 Item** | 可堆疊，使用自定義 stack_key | InventorySlot.item_data + amount |
| **武器 Weapon** | 唯一實例，不可堆疊，掉落/撿取保留 UID | InventorySlot.weapon_instance |
| **裝備 Gear** | 唯一實例，不可堆疊，採獨立 GearInstance | InventorySlot.gear_instance |

### 1.2 支援的容器與系統

需支援以下子系統：
- **Inventory**：通用容器（玩家背包、箱子、商店）
- **Equipment**：玩家裝備欄
- **Hotbar**：快捷欄綁定
- **PickupItem**：世界掉落物
- **Player**：協調 Inventory / Equipment / Hotbar

---

## 2. 武器強化系統

### 2.1 星級系統

| 星級 | 攻擊加成 | 符文槽 | 詞綴數 |
|:----:|:--------:|:------:|:------:|
| 0★ | 0% | 0 | 0 |
| 1★ | +5% | 1 | 0-1 |
| 2★ | +10% | 2 | 1 |
| 3★ | +15% | 3 | 1-2 |
| 4★ | +20% | 4 | 2 |
| 5★ | +25% | 5 | 2-3 |

### 2.2 詞綴系統
- 詞綴表: `AffixTable`
- 隨機抽取，受星級限制
- 屬性: 攻擊/防禦/速度/暴擊等

### 2.3 符文槽類型
- **FREE (0-1)**: 任意普通符文
- **TYPED (2-3)**: 需匹配標籤 (ATTACK/DEFENSE/ELEMENT/UTILITY)
- **CORE (4)**: 僅限核心符文

---

## 3. 架構分層

### 3.1 Inventory

**角色**：通用容器
**適用對象**：玩家背包、箱子、商店、NPC 容器

**職責**
- 儲存格內容
- 新增 / 移除 item
- 新增 / 移除 weapon instance
- 新增 / 移除 gear instance
- 堆疊判定（找空格 / 找可堆疊格）
- 快速移動到另一個 Inventory
- 拆分堆疊
- save/load
- 發送 UI 更新 signal

**非職責**
- 不處理 equip/unequip 規則
- 不決定角色目前裝備哪把武器
- 不套用角色屬性加成

### 3.2 Equipment

**角色**：玩家裝備欄系統

**第一版裝備欄位**
- weapon_main
- helmet
- chestplate
- leggings
- boots

**職責**
- 管理每個裝備欄位內容
- 驗證某個 instance 是否可裝到某欄
- 處理裝備 / 卸下
- 支援自動交換（舊裝備回背包）
- save/load
- 發 signal 給 UI / Player

**非職責**
- 不管理背包堆疊
- 不直接負責世界掉落
- 不管理箱子

### 3.3 Hotbar

**角色**：背包格綁定器，不持有獨立物品內容

**職責**
- 綁定 Inventory 某個 slot index
- 提供熱鍵對應
- 執行綁定物的使用 / 裝備 / 切換行為

**規則**
- Hotbar 不持有實體物品
- 只記錄「綁到哪個背包格」

### 3.4 Player

**角色**：協調者

**職責**
- Inventory ↔ Equipment 間的操作
- 熱鍵觸發行為
- 角色目前裝備武器切換
- 裝備屬性套用到角色
- Shift+Click 快速移動判定

---

## 4. 資料模型

### 4.1 ItemData

**基礎物品資料**

```gdscript
class_name ItemData
extends Resource

@export var item_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var item_type: ItemType = ItemType.MATERIAL
@export var max_stack: int = 1
@export var tags: Array[StringName] = []

func get_stack_key(instance_data_: Dictionary = {}) -> StringName:
    return item_id
```

### 4.2 WeaponInstance

**沿用目前設計**

武器為唯一實例，保存：
- instance_uid
- weapon_id
- enhance_level
- star_level
- temporary_enchants
- socketed_gems
- affixes
- rune_slots
- weapon_data

**規則**
- 不可堆疊
- 掉落時保留 UID
- save/load 用 to_save_dict() / create_from_save_dict()

### 4.3 GearData / GearInstance

**新增，裝備走唯一實例模型**

```gdscript
class_name GearData
extends ItemData

@export var gear_slot: StringName = &"helmet"
@export var armor: float = 0.0
@export var stat_bonuses: Dictionary = {}
@export var gear_sprite_texture: Texture2D = null

# gear_slot 允許值: helmet, chestplate, leggings, boots
```

```gdscript
class_name GearInstance
extends RefCounted

var instance_uid: String = ""
var gear_id: StringName = &""
var enhance_level: int = 0
var affixes: Array = []
var gear_data: GearData = null

static func create_from_data(gear_data_: GearData) -> GearInstance
static func create_from_save_dict(gear_data_: GearData, data_: Dictionary) -> GearInstance
func to_save_dict() -> Dictionary
```

### 4.4 InventorySlot

**背包 / 箱子共用格子**

```gdscript
class_name InventorySlot
extends RefCounted

var item_data: ItemData = null
var item_instance_data: Dictionary = {}
var amount: int = 0

var weapon_instance: WeaponInstance = null
var gear_instance: GearInstance = null
```

**規則**
- 一格只能有一種內容（stackable item / weapon instance / gear instance）
- is_empty() 必須同時檢查以上三類

---

## 5. 堆疊規則

### 5.1 可堆疊對象
只有一般 item 可堆疊。

### 5.2 不可堆疊對象
- WeaponInstance
- GearInstance

### 5.3 堆疊判定

兩個 item 可堆疊條件：
1. 兩者都是一般 item
2. get_stack_key(instance_data) 相同
3. 未超過 max_stack

```gdscript
var current_key := slot.item_data.get_stack_key(slot.item_instance_data)
var incoming_key := item_data_.get_stack_key(item_instance_data_)
if current_key != incoming_key:
    return false
```

---

## 6. API 規格

### 6.1 Inventory API

**Signals**
```gdscript
signal slot_changed(slot_index: int)
signal item_added(item_data: ItemData, amount: int)
signal item_removed(item_data: ItemData, amount: int)
signal weapon_added(weapon_instance: WeaponInstance)
signal weapon_removed(weapon_instance: WeaponInstance)
signal gear_added(gear_instance: GearInstance)
signal gear_removed(gear_instance: GearInstance)
```

**Public Methods**
```gdscript
# Item
func add_item(item_data_: ItemData, amount_: int, item_instance_data_: Dictionary = {}) -> int
func remove_item(item_data_: ItemData, amount_: int, item_instance_data_: Dictionary = {}) -> int

# Weapon
func add_weapon(weapon_instance_: WeaponInstance) -> bool
func remove_weapon(weapon_instance_: WeaponInstance) -> bool

# Gear
func add_gear(gear_instance_: GearInstance) -> bool
func remove_gear(gear_instance_: GearInstance) -> bool

# Slot 操作
func get_slot(slot_index_: int) -> InventorySlot
func swap_slots(from_index_: int, to_index_: int) -> bool
func split_stack(from_index_: int, amount_: int) -> int
func quick_move_slot_to_inventory(from_index_: int, target_inventory_: Inventory) -> bool
```

### 6.2 Equipment API

**Signals**
```gdscript
signal slot_changed(slot_id: StringName)
signal equipped(slot_id: StringName)
signal unequipped(slot_id: StringName)
signal equipment_changed()
```

**Public Methods**
```gdscript
func equip_weapon(slot_id_: StringName, weapon_instance_: WeaponInstance) -> WeaponInstance
func equip_gear(slot_id_: StringName, gear_instance_: GearInstance) -> GearInstance
func unequip_weapon(slot_id_: StringName) -> WeaponInstance
func unequip_gear(slot_id_: StringName) -> GearInstance
func get_slot(slot_id_: StringName) -> Variant
```

**回傳規則**
- equip_weapon() / equip_gear()：若原欄位已有裝備，回傳舊裝備 instance，由 Player 負責把舊裝備塞回背包

### 6.3 Player 協調 API

```gdscript
func try_equip_from_inventory(slot_index_: int) -> bool
func try_unequip_to_inventory(slot_id_: StringName) -> bool
func quick_move_from_inventory(slot_index_: int, external_inventory_: Inventory = null) -> bool
```

---

## 7. Shift + Left Click 規格

### 7.1 只有玩家背包開啟
背包格 Shift+Left：
- 若是 WeaponInstance / GearInstance → 優先嘗試裝備
- 若是一般 item → 不動

### 7.2 玩家背包 + 箱子同時開啟
- 從箱子格 Shift+Left → 直接移到玩家背包
- 從玩家背包格 Shift+Left → 先嘗試裝備，若裝備失敗嘗試移到箱子

### 7.3 從裝備欄 Shift+Left
- 嘗試卸到玩家背包
- 背包放不下則失敗

---

## 8. Hotbar 規格

**本質**：Hotbar 只綁定 Inventory 的 slot index

**綁定條件**
- 武器：永遠允許綁定
- 一般 item：必須 tags 含 hotbar_bindable
- gear：第一版不允許綁定

```gdscript
func can_bind_slot(slot_: InventorySlot) -> bool:
    if slot_.weapon_instance != null:
        return true
    if slot_.gear_instance != null:
        return false
    if slot_.item_data == null:
        return false
    return slot_.item_data.tags.has(&"hotbar_bindable")
```

---

## 9. PickupItem 規格

**世界掉落內容類型**
- stackable item
- weapon instance
- gear instance

**撿取規則**
- item：能放多少放多少，剩餘數量保留在世界
- weapon / gear：成功即刪掉掉落物，失敗則保留

**關鍵**：盡可能放進背包，放不下的保留在世界

---

## 10. Save / Load Schema

### 10.1 Inventory Save

```json
{
    "version": 2,
    "max_slots": 20,
    "slots": [
        {"content_type": "empty"},
        {"content_type": "item", "item_id": "mat_wood", "amount": 12},
        {"content_type": "weapon", "weapon": {...}},
        {"content_type": "gear", "gear": {...}}
    ]
}
```

### 10.2 Equipment Save

```json
{
    "version": 1,
    "slots": {
        "weapon_main": {"content_type": "weapon", "weapon": {...}},
        "helmet": {"content_type": "gear", "gear": {...}},
        "chestplate": {"content_type": "empty"}
    }
}
```

### 10.3 Migration 規則

所有 from_save_dict() 都採版本入口：
```gdscript
func from_save_dict(data_: Dictionary) -> bool:
    var version := int(data_.get("version", 1))
    match version:
        1: return _load_v1(data_)
        2: return _load_v2(data_)
        _: push_warning("Unsupported save version"); return false
```

---

## 11. 核心決策摘要

| 決策 | 內容 |
|-----|------|
| 武器 | 不可堆疊，唯一實例 |
| 裝備 | 不可堆疊，唯一實例 |
| Item | 自定義 stack_key |
| 掉落 | 保留 UID |
| 背包與裝備 | 系統分離 |
| Hotbar | 只綁定背包格，依 tag 控制 |
| 裝備替換 | 自動交換，舊裝備回背包 |
| 存檔 | version + 明確 slot 內容 |

---

*本規格已完整實作於 Phase 8*
