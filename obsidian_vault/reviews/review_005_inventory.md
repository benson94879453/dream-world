# Code Review #005 - Inventory 基礎系統

## 任務資訊

- **任務名稱**: Inventory 基礎系統
- **Codex 完成時間**: 2026-03-27
- **Kimi 驗收時間**: 2026-03-27

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| ItemData Resource 存在 | ✅ 通過 | item_id, display_name, max_stack 等 |
| InventorySlot 存在 | ✅ 通過 | RefCounted，支援 stackable + unique |
| Inventory 存在 | ✅ 通過 | max_slots=20，slots 陣列 |
| add_item() 自動堆疊 | ✅ 通過 | 同 item_id 合併 |
| add_item() 滿背包回傳剩餘 | ✅ 通過 | 回傳無法添加的數量 |
| add_weapon() 存放 WeaponInstance | ✅ 通過 | 獨立 weapon_instance 欄位 |
| get_item_count() 跨欄位計算 | ✅ 通過 | 正確加總 |
| remove_item() 支援部分移除 | ✅ 通過 | 跨多個 slot 移除 |
| 3 個測試 ItemData 存在 | ✅ 通過 | herb, potion, key |
| Debug 按鍵 (H/J/K) | ✅ 通過 | H=草藥, J=藥水, K=顯示內容 |
| Console 輸出 | ✅ 通過 | debug_print_contents() |

---

## Minecraft 教科書級別背包比對

### ✅ 已具備的基礎（Phase 1）

| Minecraft 特性 | 我們的實作 | 狀態 |
|---------------|-----------|------|
| Grid-based slots | `slots: Array[InventorySlot]` (20格) | ✅ |
| Stackable items | `max_stack` + `amount` | ✅ |
| Non-stackable (tools/weapons) | `weapon_instance` 獨立欄位 | ✅ |
| Slot-based storage | `InventorySlot` 管理單格 | ✅ |
| Item ID system | `item_id: StringName` | ✅ |
| Add/Remove API | `add_item()`, `remove_item()` | ✅ |
| Signals for UI | `slot_changed`, `item_added/removed` | ✅ |

### 📝 第二階段可擴充（暫不實作）

| Minecraft 特性 | 說明 | 第二階段建議 |
|---------------|------|-------------|
| Hotbar (快捷欄) | 9格可選擇的快捷欄 | **已確認不需要** |
| Armor/Equipment slots | 4格裝備欄（頭/胸/腿/腳）| 可擴充 `EquipmentSlot` 類別 |
| Crafting grid | 2x2 合成網格 | 可擴充 `CraftingSystem` |
| Item drag & drop | 拖曳物品移動 | UI 層實作 |
| Item split/merge | 右鍵分割、左鍵合併 | UI 層實作 |
| Durability bar | 工具耐久度顯示 | 擴充 `ItemInstance` |

---

## 詳細回饋

### 優點 👍

1. **架構清晰** - InventorySlot 作為 RefCounted，Inventory 作為 Node，職責分明

2. **自動堆疊** - `_find_slot_for_item()` 先找同 item_id 的欄位，再找空格

3. **武器分離** - 武器獨立使用 `weapon_instance` 欄位，不走 stackable 邏輯

4. **Signal 設計** - `slot_changed`, `item_added/removed` 讓 UI 可以監聽

5. **Debug 友善** - `debug_print_contents()` 清楚列出所有欄位狀態

### 設計決策記錄 📝

**輸入衝突處理**: `J` 鍵與原本 `attack` 綁定衝突，Codex 將 `attack` 從 `J` 改為 `F`

**武器欄位**: 目前只有 weapons，若未來要讓 EQUIPMENT 也具備獨立實例資料，建議新增對應 instance 類型

### Minecraft 風格評估

目前的實作已經具備 Minecraft 背包的核心精神：
- ✅ Slots array (grid-based)
- ✅ Stackable with max_stack
- ✅ Unique items (weapons)
- ✅ Slot-level operations

**符合「教科書級別」的基礎架構**。

---

## 驗收結果

- [x] **通過** - Inventory 基礎完成！
- [ ] 有條件通過
- [ ] 需要重做

---

## Phase 3 下一步

| # | 任務 | 說明 |
|---|------|------|
| #006 | Loot/Drop 系統 | 怪物掉落、玩家拾取 |
| #007 | Save/Load 系統 | 存檔讀檔 |

---

## 相關連結

- Codex Prompt: `codex_prompt.md`
- Phase 3 規劃: `PHASE3_PLAN.md`
