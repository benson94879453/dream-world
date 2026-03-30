# 輸入與快捷鍵清單

本文件是目前專案的按鍵與操作清單總表。

## 管理原則

- 一般遊玩、UI、常駐 debug action 以 `project.godot` 的 `InputMap` 為主。
- 場景限定或臨時測試快捷鍵若必須寫死在腳本中，必須記錄在本文件。
- 變更鍵位時，請同時修改程式與本文件，避免文件落後。
- 在 Godot 編輯器內執行時，要避開編輯器保留快捷鍵，尤其是 `F9`。

## 主要來源

- `project.godot`
- `game/scripts/Player.gd`
- `game/scripts/core/ArenaTest.gd`
- `game/scripts/ui/DialogUI.gd`
- `game/scripts/ui/InventoryUI.gd`
- `game/scripts/ui/QuestJournalUI.gd`
- `game/scripts/ui/WeaponUpgradeUI.gd`
- `game/scripts/ui/ItemSlotUI.gd`
- `game/scripts/ui/EquipmentSlotUI.gd`
- `game/scripts/interactables/Portal.gd`
- `game/scripts/interactables/Checkpoint.gd`
- `game/scripts/components/NPCDialogTrigger.gd`
- `game/scripts/npcs/InstructorNPC.gd`

## 玩家通用操作

| 類別 | 動作 | 鍵位 | 來源 | 備註 |
| --- | --- | --- | --- | --- |
| 移動 | 左移 | `A` / `←` | `move_left` | `project.godot` |
| 移動 | 右移 | `D` / `→` | `move_right` | `project.godot` |
| 移動 | 上移 | `W` / `↑` | `move_up` | `project.godot` |
| 移動 | 下移 | `S` / `↓` | `move_down` | `project.godot` |
| 移動 | 跑步 | `Shift` | `move_run` | `project.godot` |
| 戰鬥 | 攻擊 | 滑鼠左鍵 | `attack_mouse` | `project.godot` |
| 戰鬥 | 翻滾 / Dash | `Space` | `dash` | `project.godot` |
| 互動 | 互動、對話開始、對話推進 | `F` | `interact` | `Portal`、`Checkpoint`、NPC、`DialogUI` 共用 |
| UI | 開關背包 | `E` / `I` | `ui_inventory` | `InventoryUI` |
| UI | 開關任務日誌 | `J` | `ui_quest_journal` | `QuestJournalUI` |
| UI | 關閉目前 UI / 取消 | `Esc` | `ui_cancel` | `InventoryUI`、`QuestJournalUI`、`WeaponUpgradeUI` |
| 快捷欄 | 使用快捷欄 1 | `1` | `hotbar_use_1` | `project.godot` |
| 快捷欄 | 使用快捷欄 2 | `2` | `hotbar_use_2` | `project.godot` |
| 快捷欄 | 使用快捷欄 3 | `3` | `hotbar_use_3` | `project.godot` |
| 快捷欄 | 使用快捷欄 4 | `4` | `hotbar_use_4` | `project.godot` |
| 快捷欄 | 使用快捷欄 5 | `5` | `hotbar_use_5` | `project.godot` |

## UI 與滑鼠操作

| 介面 | 操作 | 輸入 | 來源 | 備註 |
| --- | --- | --- | --- | --- |
| 背包格 | 點擊格子 | 滑鼠左鍵 | `ItemSlotUI.gd` | 主要用於拖放起點 |
| 背包格 | 快速移動物品 | `Shift` + 滑鼠左鍵 | `ItemSlotUI.gd` | 從背包快速裝備 / 移動 |
| 快捷欄格 | 綁定物品到快捷欄 | 拖放 | `ItemSlotUI.gd` | 從背包拖到快捷欄 |
| 快捷欄格 | 交換快捷欄順序 | 拖放 | `ItemSlotUI.gd` | 快捷欄彼此可互換 |
| 背包格 | 交換背包格順序 | 拖放 | `ItemSlotUI.gd` | 背包格彼此可互換 |
| 裝備欄 | 卸下裝備到背包 | `Shift` + 滑鼠左鍵 | `EquipmentSlotUI.gd` | `EquipmentUI` 有實作 |
| 寶箱 | 取出物品 | 滑鼠左鍵 | `ChestUI.gd` | 會移到玩家背包 |
| 寶箱 | 快速取出物品 | `Shift` + 滑鼠左鍵 | `ChestUI.gd` | 目前與左鍵效果相同 |

## Debug 操作

### 全域 Debug

| 動作 | 鍵位 | 來源 | 備註 |
| --- | --- | --- | --- |
| 存檔 | `F5` | `Player.gd` | 硬寫快捷鍵 |
| 讀檔 | `F10` | `Player.gd` | 硬寫快捷鍵；在 debugger 暫停狀態下可能撞到 Step Over |

### Numeric Keypad Debug Action

以下按鍵來自 `project.godot` 的 `InputMap`，使用的是數字鍵盤，不是主鍵盤上排數字。

| 動作 | 鍵位 | Action 名稱 | 備註 |
| --- | --- | --- | --- |
| 列印背包內容 | `Numpad .` | `debug_print_inventory` | 顯示目前背包內容 |
| 加 1000 金幣 | `Numpad 0` | `debug_add_gold` | `Player.gd` |
| 裝備測試武器 1 | `Numpad 1` | `debug_equip_1` | `Player.gd` |
| 裝備測試武器 2 | `Numpad 2` | `debug_equip_2` | `Player.gd` |
| 裝備測試武器 3 | `Numpad 3` | `debug_equip_3` | `Player.gd` |
| 裝備測試武器 4 | `Numpad 4` | `debug_equip_4` | `Player.gd` |
| 裝備測試武器 5 | `Numpad 5` | `debug_equip_5` | `Player.gd` |
| 加 5 個 Herb | `Numpad 6` | `debug_add_herb` | `Player.gd` |
| 加 3 個 Potion | `Numpad 7` | `debug_add_potion` | `Player.gd` |
| 加全部 Rune 石 | `Numpad 8` | `debug_add_runes` | `Player.gd` |
| 加強化素材 | `Numpad 9` | `debug_add_upgrade_materials` | `Player.gd` |

## ArenaTest 專用快捷鍵

以下按鍵只在 `ArenaTest.gd` 內處理，不屬於全域玩家操作。

| 動作 | 鍵位 | 來源 | 備註 |
| --- | --- | --- | --- |
| 切換 Rune Test Mode | `T` | `ArenaTest.gd` | 開啟後才可用下列 Rune 測試 |
| Rune 機率測試 | `Y` | `ArenaTest.gd` | 需先開啟 Rune Test Mode |
| Rune 屬性傷害測試 | `U` | `ArenaTest.gd` | 需先開啟 Rune Test Mode |
| Shield 吸收測試 | `P` | `ArenaTest.gd` | 需先開啟 Rune Test Mode |
| 生成 Slime | `F6` | `ArenaTest.gd` | 場景限定 |
| 生成 Archer | `F7` | `ArenaTest.gd` | 場景限定 |
| 生成 Boar | `F8` | `ArenaTest.gd` | 場景限定 |

## 已知衝突與注意事項

- `F10` 目前是讀檔鍵；Godot 編輯器的 debugger 暫停狀態下，`F10` 同時也是 `Step Over`。
- 如果要把讀檔改成 `F6`，會和 `ArenaTest.gd` 的「生成 Slime」撞鍵。
- `interact` 目前同時負責互動與對話推進，這是刻意共用，不是重複綁定錯誤。
- `attack` action 目前存在於 `project.godot`，但沒有綁定事件，也沒有實際使用。

## 後續維護建議

1. 一般遊玩與常駐 debug 鍵位，盡量都改為 `InputMap` action，不要直接硬寫 `KEY_F*`。
2. 場景限定測試鍵位可以暫時寫死，但要限制在測試場景，並維持本文件同步。
3. 變更任何快捷鍵前，先檢查本文件的「已知衝突與注意事項」。
4. 舊文件若仍提到 `F9` 讀檔，請以本文件與實際程式碼為準；目前已改為 `F10`。

## 參考

- Godot 官方 `@GlobalScope` Key enum 文件可用來對照 `project.godot` 內的 `physical_keycode` 數值。
- 本文件建立時，`Numpad` 對照表以 Godot 官方文件中的 `KEY_KP_*` 常數為準。
