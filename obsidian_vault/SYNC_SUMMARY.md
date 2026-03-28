# 文件同步摘要

> 最後更新: 2026-03-28 (MVP 完成)

---

## ✅ MVP 全部完成

### Phase 1 (戰鬥底層) ✅
| 任務 | 狀態 | 日期 |
|------|------|------|
| #001 除錯武器切換 | ✅ | 2026-03-27 |
| #002 武器攻擊表現所有權 | ✅ | 2026-03-27 |
| #003 非投射物法術支援 | ✅ | 2026-03-27 |
| #004 Player Attack State | ✅ | 2026-03-27 |

### Phase 2 (武器完善) ✅
- AttackProfile 攻擊表現
- SpellActor 法術系統
- Combo/Cancel 機制

### Phase 3 (物品流轉) ✅
| 任務 | 狀態 | 日期 |
|------|------|------|
| #005 Inventory 基礎 | ✅ | 2026-03-27 |
| #006 Loot/Drop | ✅ | 2026-03-27 |
| #007 Save/Load | ✅ | 2026-03-27 |

### Phase 4 (敵人 AI + 戰鬥優化) ✅ 完成
| 任務 | 狀態 | 日期 |
|------|------|------|
| #009 Slime 基礎敵人 AI | ✅ | 2026-03-28 |
| #010 Goblin Archer 遠程 AI | ✅ | 2026-03-28 |
| #011 Dash 位移實作 | ✅ | 2026-03-28 |
| #012 Boar 突進型敵人 | ✅ | 2026-03-28 |

---

## 🎉 MVP 核心循環完成！

```
戰鬥 → 掉落 → 拾取 → 背包 → 存檔 → 讀檔
```

### 完整功能列表
- ✅ 8方向移動、走/跑狀態
- ✅ 近戰攻擊（劍）與法術攻擊（法杖）
- ✅ 攻擊階段：startup → active → recovery
- ✅ Combo 連擊與 Dash Cancel 取消
- ✅ 敵人死亡掉落物品
- ✅ 拾取系統自動加入背包
- ✅ 20格背包（stackable + unique）
- ✅ F5存檔 / F9讀檔
- ✅ 存檔包含位置、HP、裝備武器、背包內容

---

## 🎯 下一階段選項

### ✅ Phase 4 完成！
| 任務 | 狀態 |
|------|------|
| #009 Slime 基礎敵人 AI | ✅ 完成 |
| #010 Goblin Archer 遠程 AI | ✅ 完成 |
| #011 Dash 位移實作 | ✅ 完成 |
| #012 Boar 突進型敵人 | ✅ 完成 |

### 三種敵人類型對比
| 敵人 | 類型 | 機制 | 反制 |
|------|------|------|------|
| Slime (F6) | 近戰 | 追擊碰撞 | 拉開距離 |
| Archer (F7) | 遠程 | 保持距離射箭 | 靠近逼迫 |
| Boar (F8) | 突進 | 蓄力→突進 | Dash 無敵 |

### Dash 系統
| 參數 | 數值 |
|------|------|
| 距離 | 120px |
| 持續時間 | 0.15s |
| 冷卻時間 | 0.8s |
| 無敵 | ✅ |
| 殘影 | ✅ |
| 取消攻擊 | ✅ |

### 兩種敵人類型對比
| 特性 | Slime | Archer |
|------|-------|--------|
| 攻擊類型 | 近戰 | 遠程投射物 |
| 移動策略 | Chase（追擊） | KeepDistance（保持距離）|
| HP | 60 | 40 |
| Debug 鍵 | F6 | F7 |

### ✅ 三種敵人類型已完成！
| 類型 | 敵人 | Debug 鍵 |
|------|------|----------|
| 近戰追擊 | Slime | F6 |
| 遠程保持 | Archer | F7 |
| 突進爆發 | Boar | F8 |

### 選項 A: 進階敵人機制 ⭐ 推薦
- 群體行為（史萊姆群體）
- 法術型敵人（追蹤彈）
- Boss 多階段戰鬥

### 選項 B: 戰鬥優化
- 真正的 Dash 位移
- 受擊硬直 (hit stop)
- 攻擊頓幀 (hit pause)
- 武器攻擊動畫 clip

### 選項 C: 關卡與場景
- Hub/Zone 切換系統
- 場景轉場機制
- 存檔點設置

### 選項 D: 裝備與強化
- 武器強化系統 UI
- 素材合成
- 裝備屬性隨機詞綴

---

## 📋 已完成同步的文件

### 驗收記錄 (reviews/)

| 檔案 | 狀態 |
|------|------|
| `review_001_weapon_switch.md` | ✅ |
| `review_001_retrospective.md` | ✅ |
| `review_002_attack_profile.md` | ✅ |
| `review_003_non_projectile_spells.md` | ✅ |
| `review_004_player_attack_state.md` | ✅ |
| `review_005_inventory.md` | ✅ |
| `review_006_loot_drop.md` | ✅ |
| `review_007_save_load.md` | ✅ |
| `review_009_enemy_ai.md` | ✅ |
| `review_010_ranged_enemy.md` | ✅ |
| `review_011_dash.md` | ✅ |
| `review_012_charge_enemy.md` | ✅ |

### 進度追蹤 (0324/)

| 檔案 | 更新內容 |
|------|----------|
| `01_MVP_TODO.md.md` | 所有 MVP 項目標記完成 |
| `02_Tech_Spec_Notes.md.md` | 包含所有系統設計 |
| `03_Implementation_Order.md.md` | 所有任務標記完成 |

---

## 📊 MVP 完成後的專案統計

### GDScript 檔案結構
```
scripts/
├── core/
│   ├── SaveManager.gd              # 存檔管理
│   └── ArenaTest.gd                # 測試場景
├── player/
│   ├── states/
│   │   ├── PlayerIdleState.gd
│   │   ├── PlayerWalkState.gd
│   │   ├── PlayerRunState.gd
│   │   ├── PlayerLockedState.gd
│   │   ├── PlayerAttackState.gd    # 攻擊狀態
│   │   └── PlayerDashState.gd      # Dash 狀態 ⭐ NEW
│   └── Player.gd
├── weapons/
│   ├── WeaponController.gd
│   ├── SwordWeapon.gd              # 近戰武器
│   ├── StaffWeapon.gd              # 法杖武器
│   ├── SpellActor.gd               # 法術基類
│   ├── BoltSpellActor.gd           # 投射法術
│   ├── HealSpellActor.gd           # 治療法術
│   └── ExplosionSpellActor.gd      # 爆炸法術
├── data/
│   ├── WeaponData.gd               # 武器資料
│   ├── WeaponAttackProfile.gd      # 攻擊表現
│   ├── WeaponInstance.gd           # 武器實例
│   ├── ItemData.gd                 # 物品資料
│   ├── LootTableData.gd            # 掉落表
│   ├── InventorySlot.gd            # 背包欄位
│   ├── EnemyData.gd                # 敵人資料 ⭐ NEW
│   └── EnemyInstance.gd            # 敵人實例 ⭐ NEW
├── inventory/
│   └── Inventory.gd                # 背包管理
├── combat/
│   ├── AttackContext.gd
│   ├── Hitbox.gd
│   ├── Hurtbox.gd
│   ├── DamageReceiver.gd
│   ├── HealthComponent.gd
│   ├── FeedbackReceiver.gd
│   └── EnemyProjectile.gd          # 敵人投射物 ⭐ NEW
├── enemies/
│   ├── components/
│   │   ├── DropComponent.gd        # 掉落組件
│   │   └── DeathComponent.gd       # 死亡組件
│   ├── EnemyDummy.gd               # 靜態假人
│   ├── EnemyAIController.gd        # AI 控制器
│   ├── EnemyState.gd               # 敵人狀態基類
│   ├── EnemyStateMachine.gd        # 敵人狀態機
│   └── states/
│       ├── EnemyIdleState.gd       # 待機
│       ├── EnemyChaseState.gd      # 追擊
│       ├── EnemyAttackState.gd     # 攻擊
│       ├── EnemyDeadState.gd       # 死亡
│       ├── EnemyKeepDistanceState.gd  # 保持距離
│       ├── EnemyChargeState.gd     # 蓄力 ⭐ NEW
│       └── EnemyDashState.gd       # 突進 ⭐ NEW
├── pickups/
│   └── PickupItem.gd               # 拾取物品
└── ui/
    └── DebugOverlay.gd             # Debug 介面
```

### 場景檔案 (.tscn)
- Player, Enemy_Dummy, Arena_Test, DebugOverlay
- SwordWeapon, StaffWeapon, UnarmedWeapon
- PickupItem, PickupItemManager
- spells/: HealSpellActor, ExplosionSpellActor, BoltSpellActor
- enemies/: Enemy_Slime, Enemy_GoblinArcher, Enemy_Boar ⭐ NEW
- combat/: EnemyProjectile ⭐ NEW

### 資料資源 (.tres)
- weapons/: test_weapon, test_staff_weapon, test_heal_staff, test_explosion_staff, wpn_unarmed
- weapons/profiles/: profile_sword_basic, profile_staff_basic, profile_staff_quick
- items/: mat_herb, cns_potion, key_test, material_arrowhead, material_bowstring ⭐ NEW
- loot_tables/: lt_test_slime, loot_dummy_basic, lt_goblin_archer ⭐ NEW
- enemies/: en_slime_basic, en_goblin_archer, en_boar ⭐ NEW

---

## ⚠️ 已知限制 / 未來改進

1. **Dash Cancel 目前只是控制鎖定**，尚未實作真正的位移
2. **Combo 接續會清掉 cooldown**，未來可能需要專用的 combo 重啟規則
3. **音效資源尚未配置**，預留節點已準備好
4. **攻擊動畫使用 idle 動畫暫代**，需要專用的攻擊動畫 clip
5. **Dummy 只是靜態目標**，沒有 AI 行為
6. **沒有場景切換系統**，只能在 Arena_Test 中測試

---

## 🚀 建議下一步

### 短期（下一個 Sprint）✅ 已完成
**~~選項 A: 敵人 AI 系統~~** ✅ Slime + Archer 已完成
**~~Dash 位移~~** ✅ 已完成

**~~選項 B - 更多敵人類型~~** ✅ 已完成（Slime + Archer + Boar）

**新的建議：選項 C - 進階敵人機制**
理由：
- 三種基礎敵人類型已完成
- Dash 讓玩家可以躲避攻擊
- 可加入群體行為增加策略性
- 可加入 Boss 多階段戰鬥

### 中期
- 戰鬥優化（hit stop、動畫 clip、Dash 位移）
- 關卡切換系統

### 長期
- 裝備強化與合成
- 完整的關卡設計

---

*MVP 完成！準備進入下一階段開發！*
