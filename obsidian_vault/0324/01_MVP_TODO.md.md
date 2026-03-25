# 異境開發｜MVP TODO

## 0. 開工前規範

### ID 命名規範
- [ ] 制定 `item_id` 規則
- [ ] 制定 `weapon_id` 規則
- [ ] 制定 `enemy_id` 規則
- [ ] 制定 `codex_id` 規則
- [ ] 制定 `quest_id` 規則
- [ ] 制定 `instance_uid` 規則

### Enum / 常數
- [ ] 建立 `Faction` enum
- [ ] 建立 `DamageType` enum
- [ ] 建立 `Rarity` enum
- [ ] 建立 `WeaponType` enum
- [ ] 建立 `QuestState` enum

### 存檔基礎規範
- [ ] 定義 `save_version`
- [ ] 定義 migration 規則
- [ ] 定義 missing ID fallback 規則
- [ ] 定義讀檔失敗處理規則

---

## 1. 戰鬥底層

### AttackContext
- [ ] 建立 `AttackContext.gd`
- [ ] 定義 `source_node`
- [ ] 定義 `attacker_faction`
- [ ] 定義 `base_damage`
- [ ] 定義 `damage_type`
- [ ] 定義 `poise_damage`
- [ ] 定義 `knockback_force`
- [ ] 定義 `hitstop_scale`
- [ ] 定義 `tags`
- [ ] 定義 `can_trigger_on_hit`

### Combat Components
- [ ] 建立 `Hitbox.gd`
- [ ] 建立 `Hurtbox.gd`
- [ ] 建立 `DamageReceiver.gd`
- [ ] 建立 `HealthComponent.gd`
- [ ] 建立 `FeedbackReceiver.gd`

### Damage Pipeline
- [ ] 完成 `Hitbox -> Hurtbox -> DamageReceiver`
- [ ] 完成傷害計算入口
- [ ] 完成扣血流程
- [ ] 完成死亡流程
- [ ] 完成擊退流程
- [ ] 完成受擊閃爍
- [ ] 預留 hit stop 接口
- [ ] 加入 damage log

### 驗證
- [ ] 同一次攻擊不重複命中
- [ ] 無敵幀期間不受傷
- [ ] 陣營判定正確
- [ ] 擊退方向正確
- [ ] Dummy 受擊穩定

---

## 2. 玩家控制與狀態機

### Player 場景
- [ ] 建立 `Player.tscn`
- [ ] 掛載 `CharacterBody2D`
- [ ] 建立 `StateMachine`
- [ ] 建立 `WeaponPivot`
- [ ] 建立 `Hurtbox`
- [ ] 建立 `HealthComponent`
- [ ] 建立 `FeedbackReceiver`
- [ ] 掛載 `Camera2D`

### 玩家控制
- [ ] 8 方向移動
- [ ] 面向更新
- [ ] 移動動畫切換
- [ ] Dash 輸入
- [ ] Dash 位移
- [ ] Dash I-frames
- [ ] Dash 冷卻
- [ ] Dash 能量消耗預留

### Player FSM
- [ ] `Idle`
- [ ] `Run`
- [ ] `Dash`
- [ ] `Attack`
- [ ] `Hurt`（預留）
- [ ] `Dead`（預留）

### 驗證
- [ ] 手感無明顯延遲
- [ ] Dash 有爽感
- [ ] 攻擊與移動切換流暢
- [ ] 不會卡狀態

---

## 3. 武器系統

### 靜態資料
- [ ] 建立 `ItemData.gd`
- [ ] 建立 `WeaponData.gd`
- [ ] 建立測試武器 `.tres`

### Runtime Instance
- [ ] 建立 `WeaponInstance.gd`
- [ ] 支援 `weapon_id -> WeaponData` 查表
- [ ] 支援 `enhance_level`
- [ ] 支援 `temporary_enchants`
- [ ] 預留 `socketed_gems`

### 近戰攻擊
- [ ] 普攻 hitbox 啟閉
- [ ] 攻擊時序控制
- [ ] 攻速控制
- [ ] 攻擊範圍控制
- [ ] 攻擊動畫綁定

### 驗證
- [ ] 模板與實例完全分離
- [ ] 武器實例狀態可獨立變動
- [ ] 普攻命中時機穩定

---

## 4. 敵人系統

### Enemy 基底
- [ ] 建立 `Enemy_Base.tscn`
- [ ] 建立 `StateMachine`
- [ ] 建立 `Hurtbox`
- [ ] 建立 `Hitbox`
- [ ] 建立 `HealthComponent`
- [ ] 建立 `FeedbackReceiver`
- [ ] 建立 `DropManager`

### EnemyData
- [ ] 建立 `EnemyData.gd`
- [ ] 定義 `enemy_id`
- [ ] 定義 `base_hp`
- [ ] 定義 `move_speed`
- [ ] 定義 `loot_table`
- [ ] 定義 `codex_id`
- [ ] 定義 `contact_damage`
- [ ] 定義 `aggro_range`
- [ ] 定義 `attack_range`
- [ ] 定義 `stagger_resistance`

### Dummy / 測試怪
- [ ] 建立 `Enemy_Dummy.tscn`
- [ ] 建立第一隻測試怪
- [ ] 實作最小 AI

### Enemy FSM
- [ ] `Idle`
- [ ] `Chase`
- [ ] `Attack`
- [ ] `Stagger`
- [ ] `Dead`

### 驗證
- [ ] 受擊不壞狀態
- [ ] 死亡流程正確
- [ ] 可共用組件

---

## 5. Debug Tooling

### Debug Overlay
- [ ] 建立 `DebugOverlay.tscn`
- [ ] F3 開關顯示
- [ ] 顯示玩家 FSM state
- [ ] 顯示怪物 FSM state
- [ ] 顯示玩家 HP
- [ ] 顯示最近一次受擊傷害

### Debug 功能
- [ ] 一鍵補滿 HP
- [ ] 一鍵生成測試怪
- [ ] 一鍵清場
- [ ] 一鍵切換無敵
- [ ] 一鍵拿測試武器
- [ ] 顯示碰撞盒說明

### 驗證
- [ ] 不干擾正式流程
- [ ] 可快速重現 bug

---

## 6. Arena 白模測試場

### 場景配置
- [ ] 建立 `Arena_Test.tscn`
- [ ] 玩家出生點
- [ ] Dummy 出生點
- [ ] 測試怪出生點
- [ ] Debug UI
- [ ] 基本封閉地形

### 驗證目標
- [ ] 玩家可進場
- [ ] Dummy 可受擊
- [ ] 怪物可死亡
- [ ] 流程不卡住
- [ ] 有基本爽感

---

## 7. Inventory 與掉落

### Inventory
- [ ] 建立 `InventoryManager.gd`
- [ ] 建立 `InventorySlot.gd`
- [ ] 區分 stackable / unique
- [ ] 實作新增物品
- [ ] 實作移除物品
- [ ] 實作查詢數量
- [ ] 實作堆疊上限處理

### Drop / Pickup
- [ ] 建立 `LootTableData.gd`
- [ ] 完成掉落抽選邏輯
- [ ] 建立掉落物場景
- [ ] 建立撿取互動
- [ ] 撿取後發送 `inventory_updated`

### UI
- [ ] 最小背包 UI
- [ ] 顯示素材數量
- [ ] 顯示武器實例資訊

### 驗證
- [ ] 堆疊正常
- [ ] Unique 武器不堆疊
- [ ] 撿取不重複
- [ ] UI 更新正確

---

## 8. Progression / 吸魂 / Quest

### ProgressionManager
- [ ] 建立 `ProgressionManager.gd`
- [ ] 建立 `unlocked_souls`
- [ ] 建立首次吸魂判定
- [ ] 防止重複吸魂
- [ ] 發送 `soul_absorbed`

### Quest / Flags
- [ ] 建立 `quest_states`
- [ ] 建立 `flags`
- [ ] 建立查詢 API
- [ ] 建立更新 API
- [ ] 發送 `quest_state_changed`

### 驗證
- [ ] 同怪不重複給獎勵
- [ ] quest 與 flags 不混用
- [ ] 讀檔可正確還原

---

## 9. Save / Load

### SaveManager
- [ ] 建立 `SaveManager.gd`
- [ ] 實作 `save_game()`
- [ ] 實作 `load_game()`
- [ ] 實作 `new_game()`
- [ ] 實作 `migrate_save_data()`

### Save Schema
- [ ] `save_version`
- [ ] `created_at`
- [ ] `updated_at`
- [ ] `player_profile`
- [ ] `inventory.stackables`
- [ ] `inventory.unique_equipment`
- [ ] `progression.unlocked_souls`
- [ ] `progression.quest_states`
- [ ] `progression.flags`

### 驗證
- [ ] 存檔後可還原
- [ ] 舊版可遷移
- [ ] 壞資料不 crash

---

## 10. Hub / Flow / Scene Transition

### GameManager
- [ ] 建立 `GameManager.gd`
- [ ] 管理 `scene_transition_requested`
- [ ] 管理 Hub -> Arena / Zone
- [ ] 管理回 Hub 流程

### 場景流
- [ ] 建立 `Hub_Test.tscn`
- [ ] 建立 `Zone_01.tscn`
- [ ] 串接 Hub / Arena / Zone

### 驗證
- [ ] 切場後資料保留
- [ ] 讀檔可回正確場景
- [ ] 不殘留舊物件

---

## 里程碑

### Milestone 1：白模戰鬥成立
- [ ] 玩家可移動 / Dash / 攻擊
- [ ] Dummy 可受擊
- [ ] 測試怪可死亡
- [ ] Hit feedback 成立

### Milestone 2：資源流轉成立
- [ ] 掉落成立
- [ ] 拾取成立
- [ ] 背包成立

### Milestone 3：成長閉環成立
- [ ] 吸魂成立
- [ ] 存檔成立
- [ ] Hub 操作成立

### Milestone 4：最小遊戲循環成立
- [ ] Hub -> Zone -> 戰鬥 -> 掉落 -> 回 Hub
- [ ] 基本任務 / 對話可跑