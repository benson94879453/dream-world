# Phase 3 規劃：背包/掉落/存檔系統

> 建立完整的物品流轉循環：掉落 → 拾取 → 背包 → 存檔

---

## Phase 3 任務分解

```
#005 Inventory 基礎
    │
    ▼
#006 Loot/Drop 系統
    │
    ▼
#007 Save/Load 系統
```

---

## #005 Inventory 基礎

**目標**: 建立背包資料結構與核心操作（無 UI）

**產出**:
- ItemData Resource（物品模板）
- InventorySlot（欄位資料）
- Inventory（背包管理器）
- 測試物品：草藥、藥水、鑰匙

**驗收**:
- [ ] 可添加/移除 stackable 物品（自動堆疊）
- [ ] 可添加/移除 unique 物品（武器）
- [ ] Debug 按鍵可測試功能

---

## #006 Loot/Drop 系統

**目標**: 怪物死亡掉落物品，玩家可拾取

**依賴**: #005 Inventory（需要有背包才能拾取）

**產出**:
- LootTableData（掉落表配置）
- DropComponent（怪物掛載，死亡時生成掉落物）
- PickupItem（場景物件，玩家接觸後加入背包）
- Enemy_Dummy 更新（死亡時觸發掉落）

**驗收**:
- [ ] 殺死 Dummy 會掉落物品
- [ ] 玩家走過掉落物會自動拾取
- [ ] 背包滿時掉落物不消失（留在地上）

---

## #007 Save/Load 系統

**目標**: 存檔與讀檔，支援版本遷移

**依賴**: #005 Inventory + #006 Loot（需要存物品）

**產出**:
- SaveManager（Autoload，管理存檔檔案）
- SaveDTO（存檔資料結構）
- 玩家資料存檔（HP、位置、裝備武器）
- 背包資料存檔（stackable + unique 物品）
- 進度資料存檔（吸魂解鎖、任務狀態）
- Debug 指令：F5 存檔、F9 讀檔

**驗收**:
- [ ] F5 存檔，F9 讀檔後狀態一致
- [ ] 武器強化等級正確保存
- [ ] 背包物品正確保存
- [ ] 存檔格式有 version 欄位

---

## 資料流圖

```
戰鬥
 │
 ▼
Enemy 死亡 ──► DropComponent ──► 生成 PickupItem（場景物件）
                                  │
                                  ▼
Player 接觸 ──► Inventory.add_item() ──► 加入背包
                                            │
                                            ▼
                                       SaveManager.save()
                                            │
                                            ▼
                                       寫入 JSON 檔案
```

---

## 關鍵設計決策

### 1. Inventory 位置
- **選項 A**: Player 子節點（選擇此方案）
- **選項 B**: Autoload Singleton

**理由**: 未來可能有多角色，每個角色有自己的背包

### 2. Stackable vs Unique 儲存
```gdscript
# Stackable（草藥 x 50）
InventorySlot:
  item_data: ItemData（指向草藥模板）
  amount: 50

# Unique（強化+2 鐵劍）
InventorySlot:
  weapon_instance: WeaponInstance（包含 enhance_level=2）
```

### 3. Save Schema 初步規劃
```json
{
  "save_version": 1,
  "timestamp": "2026-03-27T...",
  "player": {
    "current_hp": 85,
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
        "weapon_id": "wpn_rusty_sword",
        "enhance_level": 2
      }
    ]
  },
  "progression": {
    "unlocked_souls": ["codex_slime"],
    "flags": {"zone_2_unlocked": true}
  }
}
```

---

## 當前任務

**#005 Inventory 基礎** - Prompt 已就緒，等待執行

---

*規劃由 Kimi 維護，隨任務進展更新*
