# 03 Implementation Order

## Current Status
- [x] Create `Player.tscn` with a `CharacterBody2D` root
- [x] Add `StateMachine`, `WeaponPivot`, `Hurtbox`, `HealthComponent`, `FeedbackReceiver`, and `Camera2D` to `Player.tscn`
- [x] Create `Enemy_Dummy.tscn` with a simple enemy component layout
- [x] Create `DebugOverlay.tscn` as a HUD/debug root
- [x] Create `Arena_Test.tscn` and instance the player, dummy container, and debug overlay
- [x] Add 8-direction movement input handling
- [x] Add the player walk sheet and left/right facing
- [x] Build the player FSM skeleton with `Idle`, `Walk`, `Run`, and `Locked`
- [x] Move state machine startup to owner-driven lifecycle
- [x] Add a minimal equipped weapon flow backed by `WeaponData`, `WeaponInstance`, and `wpn_unarmed.tres`
- [x] Promote weapons into category scenes instantiated from `WeaponData.weapon_scene`
- [x] Split weapon category logic into `SwordWeapon` and `StaffWeapon`
- [x] Move staff attack payload selection into `WeaponData.attack_actor_scene`
- [x] Add `SpellActor` base and `BoltSpellActor` projectile implementation
- [x] Move weapon sprite offset resolution into `WeaponController`

## Prototype Goal
- [x] Use `Arena_Test.tscn` as the main prototype loop
- [x] Keep the prototype focused on player movement, melee attacks, dummy damage, and readable debug info
- [x] Do not implement dash in this phase

## Next Tasks
- [x] Add `PlayerCollision` and `Hurtbox` shapes to the player scene
- [x] Add a minimal melee attack from `WeaponPivot -> Hitbox`
- [x] Add `AttackContext.gd`
- [x] Add `Hitbox.gd`
- [x] Add `Hurtbox.gd`
- [x] Add `DamageReceiver.gd`
- [x] Add `HealthComponent.gd`
- [x] Add `FeedbackReceiver.gd`
- [x] Wire `Hitbox -> Hurtbox -> DamageReceiver -> HealthComponent -> FeedbackReceiver`
- [x] Give `Enemy_Dummy` a visible placeholder body and HP
- [x] Show player state, player HP, and dummy HP in `DebugOverlay`
- [x] Verify the hit flow in the editor
- [x] Decide whether the prototype needs a dedicated player attack state or should stay input-driven for now
- [x] Add a debug-visible way to equip and swap between sword and staff in `Arena_Test`
- [x] Define weapon attack presentation ownership: animation, cast timing, muzzle flash, and audio
- [x] Define how non-projectile spell actors plug into the same `StaffWeapon -> SpellActor` chain
- [x] Decide when attack timing pressure is high enough to promote attack into a dedicated player state

## Refactoring Trigger ✅ 已完成
- [x] Keep the current prototype attack as input-driven for now
- [x] Promote attack into a dedicated player state only when one of these needs appears:
  - [x] attack startup / recovery timing
  - [x] movement lock during attack
  - [x] combo chaining
  - [x] cancel rules
  - [x] tighter animation-window control of hitbox timing

---

## Phase 4 敵人 AI 實作 (已完成 #009)

### 資料層
- [x] Create `EnemyData.gd` - 敵人模板資源
- [x] Create `EnemyInstance.gd` - 敵人執行期實例

### 狀態機層
- [x] Create `EnemyState.gd` - 敵人狀態基類
- [x] Create `EnemyStateMachine.gd` - 敵人狀態機
- [x] Create `EnemyIdleState.gd` - 待機狀態
- [x] Create `EnemyChaseState.gd` - 追擊狀態
- [x] Create `EnemyAttackState.gd` - 攻擊狀態
- [x] Create `EnemyDeadState.gd` - 死亡狀態

### 控制器層
- [x] Create `EnemyAIController.gd` - 敵人 AI 控制器
  - [x] 整合 DetectionArea + RayCast2D 視線偵測
  - [x] 動態 Hitbox 位置調整（根據面向）
  - [x] 動畫系統（Idle/Move/Attack/Dead）

### 場景與資料
- [x] Create `Enemy_Slime.tscn` - 史萊姆敵人場景
- [x] Create `en_slime_basic.tres` - 史萊姆資料資源

### Arena 整合
- [x] Update `ArenaTest.gd` - 添加 F6 生成敵人
- [x] Update `DebugOverlay.tscn` - 添加 Slime 資訊顯示

---

## Phase 4 遠程敵人實作 (已完成 #010)

### 投射物系統
- [x] Create `EnemyProjectile.gd` - 敵人投射物
- [x] Create `EnemyProjectile.tscn` - 投射物場景

### 新敵人狀態
- [x] Create `EnemyKeepDistanceState.gd` - 保持距離狀態

### 控制器擴充
- [x] Update `EnemyAIController.gd` - 新增 AttackType enum
- [x] Update `EnemyAIController.gd` - 新增 perform_ranged_attack()
- [x] Update `EnemyAIController.gd` - 新增 can_attack()

### Goblin Archer 場景與資料
- [x] Create `Enemy_GoblinArcher.tscn` - 弓箭手場景
- [x] Create `en_goblin_archer.tres` - 弓箭手資料
- [x] Create `lt_goblin_archer.tres` - 掉落表
- [x] Create `material_arrowhead.tres` - 素材
- [x] Create `material_bowstring.tres` - 素材

### Arena 整合
- [x] Update `ArenaTest.gd` - 新增 F7 生成 Archer
- [x] Update `DebugOverlay` - 顯示 Archer 資訊

## Phase 4+ Boar 突進型敵人 (已完成 #012)

### 新狀態
- [x] Create `EnemyChargeState.gd` - 蓄力狀態
- [x] Create `EnemyDashState.gd` - 突進狀態

### Boar 場景與資料
- [x] Create `Enemy_Boar.tscn` - 野豬場景
- [x] Create `en_boar.tres` - 野豬資料
- [x] Create `lt_boar.tres` - 掉落表

### Arena 整合
- [x] Update `ArenaTest.gd` - F8 生成 Boar
- [x] Update `DebugOverlay` - Boar 資訊顯示

## Phase 4+ Dash 實作 (已完成 #011)

### Dash 系統
- [x] Create `PlayerDashState.gd` - Dash 狀態
- [x] Update `Player.gd` - Dash 參數與方法
  - [x] start_dash()
  - [x] perform_dash_movement()
  - [x] end_dash()
  - [x] set_invincible()
  - [x] enable_dash_ghost()
  - [x] can_perform_dash()
- [x] Update `PlayerIdleState` - Dash 輸入
- [x] Update `PlayerWalkState` - Dash 輸入
- [x] Update `PlayerRunState` - Dash 輸入
- [x] Update `PlayerAttackState` - Dash Cancel
- [x] Update `DebugOverlay` - Dash 冷卻顯示

## Phase 5A: NPC 對話系統 (已完成 #013)

### 對話資料模型
- [x] Create `DialogData.gd` - 對話資料
- [x] Create `DialogNodeData.gd` - 對話節點
- [x] Create `DialogChoiceData.gd` - 對話選項

### 對話管理與 UI
- [x] Create `DialogManager.gd` - Autoload 對話管理
- [x] Create `DialogUI.gd` - 對話 UI
- [x] Create `DialogUI.tscn` - 對話場景
- [x] Create `NPCDialogTrigger.gd` - NPC 觸發器

### 對話資料
- [x] Create `dlg_blacksmith_intro.tres` - 鐵匠對話範例

### Save 整合
- [x] Update `SaveManager.gd` - Save v2，保存對話 flags

## Phase 5B: 武器升級系統 (已完成 #014)

### 詞綴系統
- [x] Create `AffixData.gd` - 詞綴資料
- [x] Create `AffixTable.gd` - 詞綴表
- [x] Create `affix_table_basic.tres` - 基礎詞綴表

### 升級系統
- [x] Create `UpgradeManager.gd` - Autoload 升級管理
- [x] Create `WeaponUpgradeUI.gd` - 升級 UI
- [x] Create `WeaponUpgradeUI.tscn` - 升級場景
- [x] Create `upgrade_costs.tres` - 升級成本表

### Weapon 擴充
- [x] Update `WeaponInstance.gd` - 新增 star_level, affixes
- [x] Update `WeaponData.gd` - 新增 weapon_category

### Save 整合
- [x] Update `SaveManager.gd` - Save v3，保存星級與詞綴
- [x] Update `Player.gd` - 保存/還原武器升級狀態

### Debug 工具
- [x] Update `DebugOverlay.gd` - 顯示武器星級、L 鍵素材包

## Acceptance Checklist
- [x] Player can walk and run in `Arena_Test`
- [x] Player can trigger a melee attack
- [x] Dummy takes damage from the player hitbox
- [x] Dummy HP decreases to zero without scene errors
- [x] Debug overlay shows player state, player HP, and dummy HP
- [x] State machine only starts after the owner is ready
- [x] Player equips weapons via `WeaponData -> WeaponInstance -> WeaponController`
- [x] `SwordWeapon` owns melee hitbox/cooldown lifecycle
- [x] `StaffWeapon` spawns a `SpellActor` selected from `WeaponData.attack_actor_scene`
- [x] Dash displacement works (Space key)
- [x] Dash can cancel attack
- [x] Dash has invincibility frames
- [x] Dash has cooldown display
- [x] NPC dialog system works (F key interaction)
- [x] Dialog choices affect flags
- [x] Dialog flags save and load correctly (save_version=2)
- [x] Weapon upgrade system works (star level 0-5)
- [x] Weapon affixes are granted on upgrade
- [x] Upgrade state saves and loads correctly (save_version=3)
- [x] Blacksmith dialog opens upgrade UI
- [x] Rune data structure (RuneData, RuneSlot, RuneInstance)
- [x] 12 rune stone resources (8 common + 4 core)
- [x] Three slot types (FREE, TYPED, CORE) with restrictions
- [x] Rune equip/unequip with gold cost calculation
- [x] RuneSocketUI with slot display and rune list
- [x] WeaponUpgradeUI tabbed interface (Upgrade/Runes)
- [x] Rune state saves and loads correctly (save_version=4)
- [x] Debug K key gives test rune stones
