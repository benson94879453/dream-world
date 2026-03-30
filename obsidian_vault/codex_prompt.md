# Codex Prompt — 9B-1 Hotbar 綁定進存檔（Save v8）

---

## 1. 任務背景

### 專案概覽
這是一款 Godot 4.x 開發的 2D ARPG。目前已完成 Phase 9A（任務追蹤 HUD、通知 Toast、日誌介面），現在進入 Phase 9B 品質修復階段。

### 已知問題
Hotbar（快捷欄）綁定目前**不進存檔**，導致：
- 讀檔後快捷欄為空，需重新綁定物品
- 玩家體驗中斷，每次重開遊戲都要重新配置快捷欄

### 已完成基礎
- **HotbarManager** (`game/scripts/core/HotbarManager.gd`) — Autoload，管理 5 格快捷欄綁定
- **HotbarRuntime** — 執行期快捷欄資料，含 `hotbar_inventory_indices[5]` 陣列
- **SaveManager** (`game/scripts/core/SaveManager.gd`) — 存檔管理，目前版本 v7
- **Save v7** — 已支援 Equipment、Quest、Gold 等欄位
- **InventoryUI** — 快捷欄 UI 顯示，可拖曳綁定物品

---

## 2. 當前任務

### 任務標題
**9B-1: Hotbar 綁定進存檔（Save v8）**

### 任務描述
將快捷欄綁定資料序列化至存檔，使玩家讀檔後快捷欄配置自動還原。

### 具體需求

#### 2.1 HotbarManager 序列化方法
| 項目 | 規格 |
|------|------|
| 方法 | `to_save_dict() -> Dictionary` |
| 回傳 | `{"bindings": [0, 5, -1, 3, -1]}` — 5 個整數陣列，-1 表示未綁定 |
| 方法 | `from_save_dict(data: Dictionary) -> bool` |
| 參數 | 上述格式的 Dictionary |
| 行為 | 更新 `hotbar_inventory_indices`，觸發 UI 刷新 |

**範例資料結構**：
```gdscript
# to_save_dict 回傳範例
{
    "bindings": [0, 5, -1, 12, 3]
    # 索引 0: 綁定至 Inventory 第 0 格
    # 索引 1: 綁定至 Inventory 第 5 格
    # 索引 2: 未綁定（-1）
    # 索引 3: 綁定至 Inventory 第 12 格
    # 索引 4: 綁定至 Inventory 第 3 格
}
```

#### 2.2 SaveManager 整合
在 `save_game()` 中新增 hotbar 欄位：
```gdscript
# SaveManager.gd
var hotbar_manager = _get_hotbar_manager()
if hotbar_manager != null:
    save_data["hotbar"] = hotbar_manager.to_save_dict()
```

#### 2.3 Save v8 Migration
- 更新 `SAVE_VERSION = 8`
- 在 `_migrate_save_data` 新增 v7→v8 遷移：
  ```gdscript
  if from_version < 8:
      # 舊存檔無 hotbar 欄位，設為全 -1（空）
      if not data.has("hotbar"):
          data["hotbar"] = {"bindings": [-1, -1, -1, -1, -1]}
  ```

#### 2.4 讀檔套用
在 `load_game()` 成功後：
```gdscript
# 從存檔資料讀取 hotbar
var hotbar_data = loaded_data.get("hotbar", {})
if hotbar_manager != null:
    hotbar_manager.from_save_dict(hotbar_data)
```

#### 2.5 UI 自動刷新
- `HotbarManager` 在 `from_save_dict` 成功後，需發出 Signal 或呼叫 `binding_changed`
- 確保 InventoryUI / HotbarUI 自動重繪顯示正確綁定

---

## 3. 技術約束

### 必須使用的現有 API
```gdscript
# HotbarManager (game/scripts/core/HotbarManager.gd)
- hotbar_inventory_indices: Array[int] — 長度為 5 的陣列，值為 Inventory slot index 或 -1
- get_bound_inventory_index(hotbar_index: int) -> int
- bind_slot(hotbar_index: int, inventory_index: int) -> bool
- unbind_slot(hotbar_index: int) -> bool
- binding_changed: Signal(hotbar_index: int, inventory_index: int)

# SaveManager (game/scripts/core/SaveManager.gd)
- SAVE_VERSION: int — 需更新為 8
- _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary
- to_save_dict() -> Dictionary — 需加入 hotbar 欄位
- from_save_dict(data: Dictionary) -> bool — 需讀取 hotbar 欄位

# Inventory (game/scripts/inventory/Inventory.gd)
- slots: Array[InventorySlot] — 確認綁定索引有效性（0 <= index < slots.size()）
- max_slots: int — 最大格子數，用於驗證綁定索引
```

### 禁止做的事
- ❌ 不要直接存 `InventorySlot` 的 UID 或其他複雜識別碼，使用簡單的 int 索引
- ❌ 不要修改 Inventory 的資料結構
- ❌ 不要在綁定索引無效時報錯，應優雅處理（設為 -1）
- ❌ 不要忘記更新 `SAVE_VERSION` 常數

### 命名/風格規範
- 方法命名：`to_save_dict()` / `from_save_dict()`（與其他 Manager 一致）
- 欄位命名：`bindings`（陣列鍵名）
- 無效值：`-1`（表示該快捷欄未綁定）
- Migration 註解：標註版本號與變更內容

---

## 4. 參考檔案

### 必須讀取
- `game/scripts/core/HotbarManager.gd` — 快捷欄管理邏輯
- `game/scripts/core/SaveManager.gd` — 存檔管理與 migration
- `game/scripts/inventory/Inventory.gd` — Inventory slot 結構

### 可參考實作
- `game/scripts/inventory/Inventory.gd` — `to_save_dict()` / `from_save_dict()` 範例
- `game/scripts/inventory/Equipment.gd` — 裝備序列化範例
- `game/scripts/core/QuestManager.gd` — quest 序列化範例

### 存檔相關檔案
- `game/data/save_slot_*.json` — 實際存檔檔案（測試用）

---

## 5. 輸出要求

### 完成標記
將下方 Checkbox 標記為完成：
```markdown
- [x] HotbarManager.to_save_dict() / from_save_dict() 實作
- [x] SaveManager 整合 hotbar 欄位
- [x] SAVE_VERSION 更新為 8
- [x] Save v7→v8 migration 實作
- [x] 讀檔後自動套用綁定
- [x] UI 自動刷新驗證
- [x] F5/F9 測試通過
- [x] 無 Console 錯誤
```

### 實作摘要
簡述實作方式（2-3 句）：

### 修改檔案清單
列出所有修改的檔案：

### 備註/問題
如有任何疑問或遇到的問題，在此記錄：

---

## 6. 任務狀態

**狀態**: 🔄 進行中  
**開始時間**: 2026-03-30  
**預估工時**: 4-5 小時  
**優先級**: P1（最高）

### 驗收清單（實作後勾選）

#### 功能驗收
- [ ] F5 存檔後 F9 讀檔，快捷欄綁定完全還原
- [ ] 舊存檔（v7）正常讀入，快捷欄為空（不報錯）
- [ ] 綁定物品使用後（消耗品），存檔讀檔後顯示正確（空格子或下一個物品）
- [ ] 重新排列 Inventory 後，快捷欄仍指向正確 slot（依索引）

#### 架構驗收
- [ ] HotbarManager 提供標準 to_save_dict / from_save_dict API
- [ ] SaveManager 正確整合 migration（v7→v8）
- [ ] SAVE_VERSION 更新為 8
- [ ] 綁定索引使用簡單 int，不依賴複雜 UID

#### 風格驗收
- [ ] 命名符合專案慣例
- [ ] Migration 邏輯清晰有註解
- [ ] 無效索引優雅處理（不報錯）

---

## 7. 測試步驟

### 測試 1: 基本存讀檔
1. 開啟 TownHub
2. 開啟背包（I），將藥水拖曳至快捷欄 1-3 格
3. 按 F5 存檔
4. 按 F9 讀檔
5. 驗證：快捷欄仍顯示藥水圖示

### 測試 2: 舊存檔相容
1. 手動建立 v7 存檔（或備份現有存檔並移除 hotbar 欄位）
2. 載入遊戲
3. 驗證：無錯誤，快捷欄為空
4. 按 F5 存檔
5. 驗證：存檔檔案出現 hotbar 欄位，版本為 8

### 測試 3: 索引驗證
1. 將 Inventory 第 5 格綁定至快捷欄 1
2. 使用物品使第 5 格變空（消耗品）
3. F5/F9
4. 驗證：快捷欄 1 顯示空或下一個移至第 5 格的物品（依 Inventory 實作）

---

## 8. 實作提示

### 8.1 HotbarManager 建議修改
```gdscript
# game/scripts/core/HotbarManager.gd

const HOTBAR_SIZE: int = 5

func to_save_dict() -> Dictionary:
    return {
        "bindings": hotbar_inventory_indices.duplicate()
    }

func from_save_dict(data: Dictionary) -> bool:
    var bindings = data.get("bindings", [])
    if typeof(bindings) != TYPE_ARRAY or bindings.size() != HOTBAR_SIZE:
        # 無效資料，重置為全 -1
        hotbar_inventory_indices = [-1, -1, -1, -1, -1]
        _notify_bindings_changed()
        return false
    
    # 驗證每個索引有效性
    var inventory = _get_player_inventory()
    var max_slots = inventory.max_slots if inventory != null else 20
    
    for i in range(HOTBAR_SIZE):
        var idx = int(bindings[i])
        if idx < -1 or idx >= max_slots:
            idx = -1
        hotbar_inventory_indices[i] = idx
    
    _notify_bindings_changed()
    return true

func _notify_bindings_changed() -> void:
    for i in range(HOTBAR_SIZE):
        binding_changed.emit(i, hotbar_inventory_indices[i])
```

### 8.2 SaveManager 建議修改
```gdscript
# game/scripts/core/SaveManager.gd

const SAVE_VERSION: int = 8

func _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    # ... 既有 migration ...
    
    if from_version < 8:
        # v8: 新增 hotbar 欄位
        if not data.has("hotbar"):
            data["hotbar"] = {
                "bindings": [-1, -1, -1, -1, -1]
            }
    
    return data

func to_save_dict() -> Dictionary:
    var save_data = {
        "save_version": SAVE_VERSION,
        # ... 既有欄位 ...
    }
    
    # 加入 hotbar
    var hotbar_manager = _get_hotbar_manager()
    if hotbar_manager != null:
        save_data["hotbar"] = hotbar_manager.to_save_dict()
    
    return save_data

func from_save_dict(data: Dictionary) -> bool:
    # ... 既有載入邏輯 ...
    
    # 載入 hotbar
    var hotbar_manager = _get_hotbar_manager()
    if hotbar_manager != null and data.has("hotbar"):
        hotbar_manager.from_save_dict(data["hotbar"])
    
    return true

func _get_hotbar_manager() -> Node:
    return get_node_or_null("/root/HotbarRuntime")
```

---

*Prompt 產出時間: 2026-03-30*  
*對應排程: 01_MVP_TODO.md §9B-1*
