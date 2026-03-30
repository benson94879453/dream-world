# Code Review #007 - Save/Load 存檔與讀檔系統

## 任務資訊

- **任務名稱**: Save/Load 存檔與讀檔系統
- **Codex 完成時間**: 2026-03-27
- **Kimi 驗收時間**: 2026-03-27

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| SaveManager Autoload 存在 | ✅ 通過 | save_game() / load_game() |
| F5 存檔 | ✅ 通過 | Console 顯示結果 |
| F10 讀檔 | ✅ 通過 | Console 顯示結果 |
| 存檔後重開讀檔，位置正確 | ✅ 通過 | global_position 保存 |
| 存檔後背包內容正確 | ✅ 通過 | stackables + weapons |
| 存檔後裝備武器正確 | ✅ 通過 | UID 保存與還原 |
| 存檔後 HP 正確 | ✅ 通過 | current_hp |
| 存檔 JSON 有 save_version | ✅ 通過 | version=1 |
| 版本過舊可安全處理 | ✅ 通過 | _migrate_save_data() 預留 |
| 新遊戲可正常開始 | ✅ 通過 | 無存檔時預設狀態 |

### ✅ 額外加分項

| 項目 | 狀態 | 備註 |
|------|------|------|
| Arena_Test 啟動時自動讀檔 | ✅ | 有存檔時自動載入 |
| headless smoke 驗證 | ✅ | DW_RUN_SAVE_SMOKE=1 |
| 可讀 JSON 格式 | ✅ | 方便除錯 |
| progression placeholder | ✅ | 未來擴充準備 |

---

## 詳細回饋

### 優點 👍

1. **Autoload 設計** - SaveManager 作為全局單例，任何時候都可存取

2. **序列化完整**:
   - Player: 位置、HP
   - Inventory: stackables (ID+amount)、weapons (UID+ID+enhance)
   - WeaponInstance: UID 對應裝備

3. **版本控制** - `save_version` 欄位 + `_migrate_save_data()` 預留

4. **Smoke 測試** - `Arena_Test` 內建驗證流程，CI 友善

5. **自動讀檔** - 啟動時有存檔自動載入，無縫體驗

### 設計決策記錄 📝

**Autoload 名稱衝突處理**:
```gdscript
# Godot autoload 名稱若與 class_name 相同會報衝突
# 解決: 保留 autoload 名稱 SaveManager，但 .gd 檔不宣告 class_name
```

**驗證方式**:
```gdscript
# Arena_Test 在 DW_RUN_SAVE_SMOKE=1 時跑內建 flow
# 1. 存檔
# 2. 改亂狀態
# 3. 讀檔並驗證
```

---

## 驗收結果

- [x] **通過** - Save/Load 系統完成！
- [ ] 有條件通過
- [ ] 需要重做

---

## 🎉 Phase 3 完成！

| # | 任務 | 狀態 |
|---|------|------|
| #005 | Inventory 基礎 | ✅ |
| #006 | Loot/Drop | ✅ |
| #007 | Save/Load | ✅ |

### Phase 3 完整物品流轉循環

```
戰鬥
 │
 ▼
Enemy 死亡 → DropComponent → LootTable → PickupItem
 │
 ▼
Player 接觸 PickupItem → Inventory.add_item() → 背包
 │
 ▼
F5 存檔 → SaveManager → user://savegame.json
 │
 ▼
重開遊戲 → F10 讀檔 → 還原狀態
```

---

## 相關連結

- Phase 3 規劃: `archive/plans/phase_3_plan.md`
- 完整同步摘要: `sync_summary.md`
