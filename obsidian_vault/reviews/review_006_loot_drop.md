# Code Review #006 - Loot/Drop 掉落與拾取系統

## 任務資訊

- **任務名稱**: Loot/Drop 掉落與拾取系統
- **Codex 完成時間**: 2026-03-27
- **Kimi 驗收時間**: 2026-03-27

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| LootTableData Resource 存在 | ✅ 通過 | 可配置多個掉落項目 |
| DropComponent 存在 | ✅ 通過 | 死亡時生成 PickupItem |
| PickupItem 場景存在 | ✅ 通過 | 可顯示物品圖示 |
| PickupItem 有 Area2D | ✅ 通過 | 玩家進入自動拾取 |
| 拾取成功後消失 | ✅ 通過 | queue_free() |
| 背包滿時留在原地 | ✅ 通過 | 不消失 |
| 測試 LootTable 存在 | ✅ 通過 | Dummy 掉草藥/藥水 |
| 5 次掉落測試 | ✅ 通過 | 隨機性驗證 |
| Debug Overlay 顯示拾取記錄 | ✅ 通過 | 最近拾取 + 背包格數 |

### ✅ 額外加分項

| 項目 | 狀態 | 備註 |
|------|------|------|
| PickupItem 拾取延遲 | ✅ | 避免戰鬥中誤拾 |
| PickupItem 浮動動畫 | ✅ | 吸引注意力 |
| LootEntryData 獨立 Resource | ✅ | 更好的 .tres 序列化 |

---

## 詳細回饋

### 優點 👍

1. **LootEntryData 設計** - 為了穩定序列化拆出獨立 Resource，良好的資料設計

2. **PickupItem 完整功能**:
   - 拾取延遲 (避免戰鬥誤拾)
   - 浮動動畫 (視覺回饋)
   - 背包滿檢查 (滿時留在原地)

3. **掉落隨機性** - 80% 草藥 (1-3個) + 30% 藥水，有變化性

4. **Debug 整合** - Overlay 顯示最近拾取和背包使用狀況

### 設計決策記錄 📝

**LootEntryData 拆分**:
```gdscript
# 原本: LootTableData 內嵌 class LootEntry
# 改為: 獨立 LootEntryData.gd extends Resource
# 原因: Godot .tres 序列化更穩定
```

**Smoke Check 環境限制**:
- Godot 4.6.1 Mono `--script` 會 crash
- 改以主場景 headless 載入驗證 + 規則抽測

---

## 驗收結果

- [x] **通過** - Loot/Drop 系統完成！
- [ ] 有條件通過
- [ ] 需要重做

---

## Phase 3 進度

| # | 任務 | 狀態 |
|---|------|------|
| #005 | Inventory 基礎 | ✅ |
| #006 | Loot/Drop | ✅ |
| **#007** | **Save/Load** | ⏳ **下一個** |

---

## 完整物品流轉循環 ✅

```
戰鬥
 │
 ▼
Enemy 死亡
 │
 ▼
DropComponent → LootTable → 生成 PickupItem
 │
 ▼
Player 接觸 PickupItem
 │
 ▼
Inventory.add_item() → 加入背包
 │
 ▼
(未來 #007) SaveManager.save()
```

---

## 相關連結

- Task Prompt: `task_prompt.md` (將更新為 #007)
- Phase 3 規劃: `archive/plans/phase_3_plan.md`
