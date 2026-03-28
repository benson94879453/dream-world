# Codex 開發任務 Prompt

> 最後更新: 2026-03-28
> 本文件由 Kimi 維護，每次新任務直接覆寫此檔案

---

## 任務背景

### 專案概覽
- **專案名稱**: 異境 (Dream World)
- **引擎**: Godot 4.x
- **類型**: 2D 動作探索遊戲
- **目前階段**: Bug 修復 - 背包 UI 調試

### 問題回報 🐛
#019 Minecraft 風格背包 UI 實作後發現以下問題：

| 問題 | 嚴重度 | 描述 |
|------|:------:|------|
| 格子點擊區域 | 🔴 高 | 僅能點擊邊框一圈，中心區塊無法點擊 |
| 快捷鍵失效 | 🔴 高 | E/I 鍵無法開啟/關閉背包 |
| 1-5 武器切換失效 | 🔴 高 | 數字鍵無法呼叫測試用武器 |
| 預覽框過大 | 🟡 中 | 背包道具預覽框（Drag Preview）大小過大 |

---

## 當前任務

### 任務標題
#019+ 背包 UI Bug 修復（點擊區域/快捷鍵/預覽框）

### 任務描述
調試並修復背包 UI 的操作問題，確保格子可正常點擊、快捷鍵正常運作。

---

## 具體需求

### 1. 格子點擊區域修復 🔲

**問題分析**：
- 可能是 ItemSlotUI 的 TextureRect 或 Button 的 `mouse_filter` 設定錯誤
- 可能是中心圖示遮擋了點擊事件
- 可能是 Control 節點的 `mouse_default_cursor_shape` 或 `input_pass_on_modal_close_click` 問題

**修復方案**：

**ItemSlotUI.tscn 結構檢查**：
```
ItemSlotUI (Control)
├── Background (Panel/TextureRect)  <- mouse_filter = IGNORE
├── Icon (TextureRect)              <- mouse_filter = IGNORE
├── AmountLabel (Label)             <- mouse_filter = IGNORE
└── ClickArea (Button/Area2D)       <- mouse_filter = STOP，負責接收點擊
```

**正確設定**：
```gdscript
# ItemSlotUI.gd
func _ready() -> void:
    # 確保所有子節點不攔截點擊
    for child in get_children():
        if child is Control:
            child.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # 確保 ClickArea 接收點擊
    if click_area:
        click_area.mouse_filter = Control.MOUSE_FILTER_STOP
```

**或者使用 Button 作為基底**：
```
ItemSlotUI (Button)                   <- 整個按鈕可點擊
├── Background (TextureRect)          <- 視覺背景
├── Icon (TextureRect)                <- 物品圖示
└── AmountLabel (Label)               <- 堆疊數量
```

---

### 2. 快捷鍵 E/I 修復 ⌨️

**問題分析**：
- 可能是 `ui_inventory` input action 未正確綁定
- 可能是 Player.gd 的 `_unhandled_input` 沒有處理
- 可能是背包開啟時輸入被攔截

**檢查項目**：

**project.godot**：
```ini
[input]

ui_inventory={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":69,"physical_keycode":0,"key_label":0,"unicode":101,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":73,"physical_keycode":0,"key_label":0,"unicode":105,"echo":false,"script":null)
]
}
```

**Player.gd**：
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # 檢查 E/I 鍵
    if event.is_action_pressed("ui_inventory"):
        toggle_inventory()
        get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
    var inventory_ui := _get_inventory_ui()
    if inventory_ui == null:
        return
    
    inventory_ui.visible = not inventory_ui.visible
    
    # 暫停/恢復遊戲
    get_tree().paused = inventory_ui.visible
```

**InventoryUI.tscn**：
- 確保 `process_mode = WHEN_PAUSED`（才能在暫停時接收輸入）
- 或者使用 `CanvasLayer` 並設定正確的 `layer`

---

### 3. 1-5 武器切換修復 🔢

**問題分析**：
- 可能是快捷欄輸入與武器切換輸入衝突
- 可能是 HotbarManager 優先處理了 1-5，但沒有正確裝備武器
- 可能是武器切換的 input action 被移除或覆蓋

**檢查項目**：

**project.godot**：
```ini
[input]

ui_hotbar_1={...}
ui_hotbar_2={...}
ui_hotbar_3={...}
ui_hotbar_4={...}
ui_hotbar_5={...}

# 原有武器切換（如果還需要）
weapon_slot_1={...}
weapon_slot_2={...}
...
```

**Player.gd 輸入優先級**：
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # 背包開啟時不處理其他輸入
    if _is_inventory_open():
        return
    
    # 優先處理快捷欄
    if event.is_action_pressed("ui_hotbar_1"):
        _use_hotbar_slot(0)
        return
    # ... 2-5
    
    # 原有武器切換（如果與快捷欄分開）
    if event.is_action_pressed("weapon_slot_1"):
        switch_to_weapon_slot(0)
```

**HotbarManager 武器裝備**：
```gdscript
# HotbarManager.gd
func use_hotbar_slot(index: int) -> void:
    var item := hotbar_slots[index]
    if item == null:
        return
    
    match item.item_type:
        ItemData.ItemType.WEAPON:
            # 呼叫 Player 裝備武器
            _get_player().equip_weapon_by_data(item)
        ItemData.ItemType.CONSUMABLE:
            use_consumable(item)
```

---

### 4. 預覽框大小修復 🖼️

**問題分析**：
- Drag Preview 使用了原始圖示大小，可能過大
- 需要縮小到適合格子的大小（例如 32x32 或 40x40）

**修復方案**：

**ItemSlotUI.gd**：
```gdscript
func _get_drag_data(at_position: Vector2) -> Variant:
    if current_item == null:
        return null
    
    # 建立預覽
    var preview := TextureRect.new()
    preview.texture = current_item.icon
    preview.custom_minimum_size = Vector2(32, 32)  # 固定大小
    preview.size = Vector2(32, 32)
    preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview.modulate = Color(1, 1, 1, 0.8)  # 80% 透明度
    
    # 加入背景框（可選）
    var panel := Panel.new()
    panel.custom_minimum_size = Vector2(36, 36)
    panel.add_child(preview)
    preview.position = Vector2(2, 2)
    
    set_drag_preview(panel)
    
    return {
        "slot_index": slot_index,
        "item": current_item,
        "amount": current_amount
    }
```

---

## 驗收標準

- [ ] **格子全區域可點擊**：中心區塊也能正常點擊
- [ ] **E/I 鍵開關背包**：按鍵正常開啟/關閉背包
- [ ] **1-5 武器切換**：數字鍵能呼叫測試用武器
- [ ] **預覽框大小適中**：拖曳時預覽框為 32x32 或類似大小
- [ ] **Console 無錯誤**：無新的 warning/error
- [ ] **原有功能保留**：拖曳、tooltip、分類過濾正常運作

---

## 技術約束

### 輸入處理
- 使用 `_unhandled_input` 處理全局快捷鍵
- 使用 `get_viewport().set_input_as_handled()` 防止重複觸發
- 背包開啟時可選擇暫停遊戲或不暫停

### UI 點擊
- 使用 `mouse_filter = MOUSE_FILTER_IGNORE` 讓子節點不攔截點擊
- 或使用 Button 作為 ItemSlotUI 基底

### 快捷鍵衝突
- 確保 `ui_inventory` 和 `ui_hotbar_*` 沒有重複綁定
- 優先處理順序：背包開關 > 快捷欄 > 武器切換

---

## 參考檔案

### 需檢查/修復
```
game/scenes/ui/ItemSlotUI.tscn          # 點擊區域結構
game/scripts/ui/ItemSlotUI.gd           # 預覽框大小
game/scripts/Player.gd                  # E/I 鍵處理
game/scripts/core/HotbarManager.gd      # 1-5 快捷欄
game/scenes/ui/InventoryUI.tscn         # process_mode 設定
project.godot                           # input actions 檢查
```

### 參考現有
```
game/scripts/core/ArenaTest.gd          # 原有 1-5 武器切換邏輯
```

---

## 架構說明

### 輸入流程
```
玩家按鍵
    ↓
Player._unhandled_input()
    ├── E/I → toggle_inventory()
    ├── 1-5 → HotbarManager.use_hotbar_slot()
    └── （原有）數字鍵武器切換
```

### UI 點擊流程
```
滑鼠點擊
    ↓
ItemSlotUI._gui_input() 或 Button.pressed
    ↓
處理點擊/拖曳邏輯
```

---

## 輸出要求

1. **完成後請更新此檔案底部「任務狀態」為已完成**
2. **簡要說明實作內容** (2-3 行)
3. **列出修改的檔案清單**
4. **標註修復的 Bug 和原因**
5. 滿足 `0324/04_Coding_Habits.md.md`

---

## 任務狀態

- [ ] 進行中
- [x] 已完成

### 實作摘要
- `ItemSlotUI` 現在會把所有子 Control 設成 `MOUSE_FILTER_IGNORE`，由根節點統一吃滑鼠事件，拖曳與 hover 不再只剩邊框可用。
- `InventoryUI` 改成自己在 `_input()` 處理 `E / I` 開關，避免 UI 開啟後 `_unhandled_input` 被 Control 節點截走導致無法關閉。
- `Player` 的 `1-5` 先嘗試 hotbar，再 fallback 到 debug 武器切換；drag preview 也縮成 32x32 等級，操作手感恢復正常。

### 修改檔案
- `game/scripts/ui/ItemSlotUI.gd`
- `game/scripts/ui/InventoryUI.gd`
- `game/scripts/Player.gd`
- `game/scenes/Arena_Test.tscn`
- `game/scenes/ui/InventoryUI.tscn`
- `obsidian_vault/codex_prompt.md`

### 修復的 Bug
| Bug | 原因 | 修復方式 |
|-----|------|---------|
| 格子中心無法點擊 | `Icon/Label/MarginContainer` 等子節點仍用預設滑鼠過濾，導致 root slot 收不到中心區域事件 | `ItemSlotUI` 在 `_ready()` 遞迴把子 Control 設為 `MOUSE_FILTER_IGNORE`，root 保持 `STOP` |
| E/I 鍵失效 | 背包 UI 開啟後，`Player._unhandled_input()` 會被 UI Control 節點截斷，無法再收到同 action 關閉背包 | 改由 `InventoryUI._input()` 直接處理 `ui_inventory`，並呼叫 `set_input_as_handled()` |
| 1-5 武器失效 | `Arena_Test` 關掉了 debug 武器切換，且 hotbar 空綁定時數字鍵沒有 fallback | 恢復 `enable_debug_weapon_switching`，並讓 `Player` 先嘗試 hotbar，失敗再 fallback 到 debug 裝備 |
| 預覽框過大 | drag preview 外框與內容都用 56/40 尺寸，明顯超過格子視覺比例 | 調整為 36 外框 + 32 圖示的 preview 尺寸 |

### 備註/問題
- Godot headless 啟動驗證通過，這輪修復後只剩既有的 `game/scenes/Player.tscn` ext_resource UID warning。
- `1-5` 目前行為為「有 hotbar 綁定就使用 hotbar，否則 fallback 到 debug 武器切換」，方便測 UI 同時保留測試武器流。
