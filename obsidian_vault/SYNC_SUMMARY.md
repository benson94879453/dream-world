# 文件同步摘要

> 最後更新: 2026-03-27 (Phase 2 完成)

---

## ✅ Phase 2 全部完成

| 任務 | 狀態 | 日期 |
|------|------|------|
| #001 除錯武器切換 | ✅ | 2026-03-27 |
| #002 武器攻擊表現所有權 | ✅ | 2026-03-27 |
| #003 非投射物法術支援 | ✅ | 2026-03-27 |
| #004 Player Attack State | ✅ | 2026-03-27 |

## 🔄 Phase 3 進行中

| 任務 | 狀態 | 日期 |
|------|------|------|
| #005 Inventory 基礎 | ✅ | 2026-03-27 |
| #006 Loot/Drop | ✅ | 2026-03-27 |
| #007 Save/Load | ✅ | 2026-03-27 |

---

## 🎉 MVP 核心循環完成！

### Phase 1 (戰鬥底層) ✅
- 玩家移動、狀態機、戰鬥管線
- Sword/Staff 武器系統
- Debug 武器切換

### Phase 2 (武器完善) ✅
- AttackProfile 攻擊表現
- 非投射物法術 (Heal/Explosion)
- Player Attack State (Combo/Cancel)

### Phase 3 (物品流轉) ✅
- Inventory 背包系統
- Loot/Drop 掉落拾取
- Save/Load 存檔讀檔

---

## 下一步選項

---

## 📋 已完成同步的文件

### 驗收記錄 (reviews/)

| 檔案                                    | 狀態     |
| ------------------------------------- | ------ |
| `review_001_weapon_switch.md`         | ✅      |
| `review_001_retrospective.md`         | ✅      |
| `review_002_attack_profile.md`        | ✅      |
| `review_003_non_projectile_spells.md` | ✅      |
| `review_004_player_attack_state.md`   | ✅ (新增) |

### 進度追蹤 (0324/)

| 檔案 | 更新內容 |
|------|----------|
| `01_MVP_TODO.md.md` | Player attack state / Weapon-specific attack / Non-projectile spells 標記完成 |
| `02_Tech_Spec_Notes.md.md` | 新增 WeaponAttackProfile、SpellActor 系統章節 |
| `03_Implementation_Order.md.md` | #002, #003, #004 標記完成 |

---

## 🎯 Phase 2 最終架構

### 玩家戰鬥系統

```
Player (CharacterBody2D)
├── StateMachine
│   ├── PlayerIdleState
│   ├── PlayerWalkState
│   ├── PlayerRunState
│   ├── PlayerLockedState (控制鎖定)
│   └── PlayerAttackState (NEW #004)
│       ├── enter(): 開始攻擊
│       ├── physics_update(): 鎖定移動
│       ├── handle_input(): combo/cancel 處理
│       └── exit(): 清理
│
├── WeaponPivot/WeaponController
│   ├── SwordWeapon (三階段攻擊)
│   │   ├── startup → active (Hitbox啟用) → recovery
│   │   ├── can_combo() (active/recovery前半)
│   │   └── cancel_attack()
│   └── StaffWeapon (SpellType 分流)
│       ├── PROJECTILE: BoltSpellActor
│       ├── INSTANT: HealSpellActor, ExplosionSpellActor
│       └── CONTINUOUS: (預留)
│
└── 輸入處理
    ├── 1/2/3/4/5: 武器切換
    ├── 攻擊鍵: 進入 Attack 狀態
    └── Space (Dash): Cancel 攻擊
```

### 武器資料架構

```gdscript
WeaponData (Resource)
├── 基本屬性: weapon_id, display_name, base_atk, attack_speed, attack_range
├── attack_profile: WeaponAttackProfile
└── attack_actor_scene: PackedScene (法杖用)

WeaponAttackProfile (Resource)
├── 時機: startup_frames, active_frames, recovery_frames
├── 冷卻: cooldown_seconds
├── 視覺: animation_name, muzzle_flash_scene, hit_effect_scene
└── 聽覺: startup_audio, hit_audio

SpellActor (基類)
├── spell_type: PROJECTILE / INSTANT / CONTINUOUS
├── lifetime_seconds
└── affect_self/friends/enemies 旗標
```

---

## 🔧 新增的 Debug 功能

### Debug Overlay 現在顯示：
- Player State (Idle/Walk/Run/Locked/Attack)
- Player HP
- Player Weapon (當前裝備武器名稱)
- **Attack Phase** (idle/startup/active/recovery) #004
- **Combo Ready** (Yes/No) #004
- **Combo Queued** (Yes/No) #004
- Dummy State
- Dummy HP

### 輸入綁定：
| 按鍵 | 功能 |
|------|------|
| 1 | 裝備空手 |
| 2 | 裝備測試劍 |
| 3 | 裝備投射法杖 |
| 4 | 裝備治療法杖 |
| 5 | 裝備爆炸法杖 |
| 攻擊鍵 | 進入 Attack 狀態 |
| Space | Dash Cancel (攻擊中也可使用) |

---

## 📊 Phase 2 完成後的專案統計

### GDScript 檔案
- `scripts/player/states/`: 5 個狀態類別
- `scripts/weapons/`: WeaponController, SwordWeapon, StaffWeapon, SpellActor, BoltSpellActor
- `scripts/weapons/spells/`: HealSpellActor, ExplosionSpellActor
- `scripts/data/`: WeaponData, WeaponAttackProfile, WeaponInstance
- `scripts/combat/`: AttackContext, Hitbox, Hurtbox, DamageReceiver, HealthComponent, FeedbackReceiver
- `scripts/ui/`: DebugOverlay

### 場景檔案 (.tscn)
- Player, Enemy_Dummy, Arena_Test, DebugOverlay
- SwordWeapon, StaffWeapon, UnarmedWeapon
- spells/: HealSpellActor, ExplosionSpellActor, BoltSpellActor

### 資料資源 (.tres)
- weapons/: test_weapon, test_staff_weapon, test_heal_staff, test_explosion_staff, wpn_unarmed
- weapons/profiles/: profile_sword_basic, profile_staff_basic, profile_staff_quick

---

## 🎯 下一步選項

### 選項 A: Phase 3 - 背包/掉落/存檔
- Inventory 系統 (堆疊物 vs 獨立物件)
- 掉落機制 (LootTable)
- Save/Load 系統 (SaveManager)

### 選項 B: 敵人 AI
- Enemy 狀態機 (Idle/Chase/Attack)
- 簡單的尋路/追蹤
- 攻擊模式

### 選項 C: 戰鬥優化
- 真正的 Dash 位移
- 武器攻擊動畫 clip
- 受擊硬直 (hit stop)

### 選項 D: 關卡流程
- Hub/Zone 切換
- 場景轉場
- 存檔點

---

## ⚠️ 已知限制 / 未來改進

1. **Dash Cancel 目前只是控制鎖定**，尚未實作真正的位移
2. **Combo 接續會清掉 cooldown**，未來可能需要專用的 combo 重啟規則
3. **音效資源尚未配置**，預留節點已準備好
4. **攻擊動畫使用 idle 動畫暫代**，需要專用的攻擊動畫 clip

---

*Phase 2 武器系統完善完成，準備進入下一階段！*
