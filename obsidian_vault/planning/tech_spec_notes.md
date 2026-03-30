# 技術規範筆記

> Godot 4.x / GDScript
> 最後更新: 2026-03-29

---

## 核心架構原則

### Resource vs Instance
- **Resource (.tres)**: 靜態模板資料，作為 Sources of Truth
- **Instance/RefCounted**: 執行期動態資料，唯一實例模型
- **DTO (Dictionary)**: 存檔交換格式

```
WeaponData (Resource) ──建立──> WeaponInstance (RefCounted)
                                     ↓
                              to_save_dict() ──> 存檔
```

### 資料流向
```
讀取：Resource → Instance → 遊戲邏輯 → 存檔
恢復：存檔 → Instance → 遊戲邏輯
```

---

## 背包/裝備架構 (Phase 8)

### 三型態系統
| 類型 | 堆疊 | 識別方式 | 儲存位置 |
|-----|:----:|----------|---------|
| Item | ✅ 可堆疊 | stack_key | InventorySlot.item_data + amount |
| Weapon | ❌ 唯一實例 | instance_uid | InventorySlot.weapon_instance |
| Gear | ❌ 唯一實例 | instance_uid | InventorySlot.gear_instance |

### 存檔版本
- **Inventory v2**: slot-based 格式 `{"version": 2, "slots": [...]}`
- **Equipment**: 整合在 player.equipment 中
- **Save v6**: 含 checksum 驗證

---

## EventBus 規範
- 使用 Autoload Singleton 作為系統間通訊
- Signal 命名: `動作_過去式` (如 `upgrade_succeeded`)
- 避免直接跨系統呼叫

---

## 命名規範
- 類別: PascalCase (`WeaponInstance`)
- 檔案: PascalCase.gd (`WeaponInstance.gd`)
- 方法/變數: snake_case (`weapon_instance`)
- 參數: 結尾加 `_` (`weapon_instance_`)
- StringName: `&"string"` 語法

---

## 錯誤處理
- 使用 `assert()` 檢查關鍵假設
- 方法回傳 `bool` 或 `Result` 表示成功/失敗
- 失敗時保持原狀態 (rollback)

---

*本文件根據專案代碼重建*
