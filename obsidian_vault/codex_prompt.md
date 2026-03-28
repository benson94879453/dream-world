# Codex 開發任務 Prompt

> 最後更新: 2026-03-28
> 本文件由 Kimi 維護，每次新任務直接覆寫此檔案

---

## 任務背景

### 專案概覽
- **專案名稱**: 異境 (Dream World)
- **引擎**: Godot 4.x
- **類型**: 2D 動作探索遊戲
- **目前階段**: Phase 4 - 更多敵人類型

### 已完成 ✅
- **敵人 AI**: Slime（近戰追擊）、Goblin Archer（遠程保持距離）
- **玩家 Dash**: 衝刺位移、無敵、取消攻擊

### 當前目標
建立第一個**突進型敵人**，考驗玩家的 Dash 反應：
- 敵人會短暫**蓄力**（有預警提示）
- 然後**快速突進**向玩家衝刺
- 玩家必須用 Dash 無敵幀躲避，或走位避開

這將是對玩家反應速度的第一次真正考驗。

---

## 當前任務

### 任務標題
#012 突進型敵人 - Boar（野豬）

### 任務描述
建立一個突進型敵人：野豬。與 Slime 和 Archer 不同，Boar 會：
1. 看到玩家後進入蓄力狀態（有明顯預警）
2. 短暫蓄力後快速向玩家方向突進
3. 突進過程中對碰撞到的目標造成傷害
4. 突進結束後有冷卻時間

玩家必須學會：
- 觀察蓄力預警（準備躲避）
- 用 Dash 無敵幀穿過突進
- 或側向走位避開直線突進

### 具體需求

#### 1. 建立新敵人狀態

**EnemyChargeState.gd** (`game/scripts/enemies/states/EnemyChargeState.gd`):
```gdscript
class_name EnemyChargeState
extends EnemyState

@export var charge_duration: float = 0.8  # 蓄力時間（給玩家反應）
@export var charge_animation_fps: float = 15.0

var charge_timer: float = 0.0

func enter(_previous_state: StringName = &"") -> void:
    var enemy_: EnemyAIController = get_actor()
    charge_timer = 0.0
    enemy_.stop_movement()
    enemy_.play_charge_animation(0.0)
    
    # 面向玩家（鎖定突進方向）
    var player_pos := enemy_.get_player_position()
    enemy_.face_direction((player_pos - enemy_.global_position).normalized())

func physics_update(delta_: float) -> void:
    var enemy_: EnemyAIController = get_actor()
    
    if enemy_.is_dead():
        transition_to(&"Dead")
        return
    
    charge_timer += delta_
    enemy_.play_charge_animation(delta_)
    
    # 蓄力完成，開始突進
    if charge_timer >= charge_duration:
        transition_to(&"Dash")
```

**EnemyDashState.gd** (`game/scripts/enemies/states/EnemyDashState.gd`):
```gdscript
class_name EnemyDashState
extends EnemyState

@export var dash_speed: float = 400.0  # 突進速度（很快）
@export var dash_duration: float = 0.3  # 突進持續時間
@export var dash_cooldown: float = 1.5  # 突進後冷卻

var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func enter(_previous_state: StringName = &"") -> void:
    var enemy_: EnemyAIController = get_actor()
    dash_timer = 0.0
    
    # 記錄突進方向（進入時面向的方向）
    var player_pos := enemy_.get_player_position()
    dash_direction = (player_pos - enemy_.global_position).normalized()
    
    # 啟用突進傷害（類似攻擊判定）
    enemy_.start_dash_attack()

func physics_update(delta_: float) -> void:
    var enemy_: EnemyAIController = get_actor()
    
    if enemy_.is_dead():
        enemy_.end_dash_attack()
        transition_to(&"Dead")
        return
    
    # 執行突進位移
    enemy_.velocity = dash_direction * dash_speed
    enemy_.move_and_slide()
    
    dash_timer += delta_
    
    # 突進結束
    if dash_timer >= dash_duration:
        enemy_.end_dash_attack()
        transition_to(&"Idle")  # 回到 Idle 冷卻

func exit() -> void:
    var enemy_: EnemyAIController = get_actor()
    enemy_.velocity = Vector2.ZERO
    enemy_.end_dash_attack()
    enemy_.start_dash_cooldown()
```

#### 2. 更新 EnemyAIController

**EnemyAIController.gd** 新增：
```gdscript
# 突進攻擊用 Hitbox
@onready var dash_hitbox: Hitbox = get_node_or_null("DashHitbox")

var dash_cooldown_timer: float = 0.0

func start_dash_attack() -> void:
    if dash_hitbox != null:
        dash_hitbox.activate()
    # 可選：突進時改變碰撞層，或無視某些碰撞

func end_dash_attack() -> void:
    if dash_hitbox != null:
        dash_hitbox.deactivate()

func start_dash_cooldown() -> void:
    dash_cooldown_timer = dash_cooldown  # 從 enemy_data 讀取

func can_dash_attack() -> bool:
    return dash_cooldown_timer <= 0.0

func _physics_process(delta_: float) -> void:
    # ... 現有邏輯
    
    # 更新突進冷卻
    if dash_cooldown_timer > 0.0:
        dash_cooldown_timer -= delta_
```

新增視覺方法：
```gdscript
func play_charge_animation(delta_: float) -> void:
    # 蓄力動畫：快速閃爍或縮小後放大
    animation_time += delta_ * charge_animation_fps
    var frame_: int = int(animation_time) % animation_frame_count
    sprite.frame_coords = Vector2i(frame_, charge_animation_row)
    
    # 可選：顏色閃爍提示
    var flash := sin(animation_time * PI * 2) > 0
    sprite.modulate = Color(1.5, 1.0, 1.0) if flash else Color.WHITE

func reset_charge_visual() -> void:
    sprite.modulate = Color.WHITE
```

#### 3. 更新 EnemyIdleState（Boar 版本）

Boar 的 Idle 邏輯與 Slime 不同：
```gdscript
# EnemyIdleState.gd - 檢查是否可以突進
func physics_update(delta_: float) -> void:
    var enemy_: EnemyAIController = get_actor()
    enemy_.stop_movement()
    
    if enemy_.is_dead():
        transition_to(&"Dead")
        return
    
    if not enemy_.can_see_player():
        return
    
    var player_pos := enemy_.get_player_position()
    var distance := enemy_.global_position.distance_to(player_pos)
    
    # Boar：在突進範圍內且冷卻結束就蓄力
    if enemy_.can_dash_attack() and distance <= enemy_.dash_attack_range:
        transition_to(&"Charge")
        return
    
    # 太遠就追擊（可選）
    if distance > enemy_.detection_radius * 0.5:
        transition_to(&"Chase")
```

#### 4. 建立 Boar 場景與資料

**Enemy_Boar.tscn**:
```
EnemyAIController (root)
├── Visual/Sprite2D
├── StateMachine
│   ├── EnemyIdleState      # 檢測玩家，決定突進或追擊
│   ├── EnemyChaseState     # 追擊（可選）
│   ├── EnemyChargeState    # 蓄力預警 ⭐ NEW
│   ├── EnemyDashState      # 突進攻擊 ⭐ NEW
│   └── EnemyDeadState
├── DetectionArea
├── Hurtbox                 # 受擊判定
├── DashHitbox              # 突進攻擊判定 ⭐ NEW
├── HealthComponent
├── FeedbackReceiver
└── DropComponent
```

**en_boar.tres**:
```gdscript
[resource]
script = ExtResource("EnemyData")
enemy_id = &"en_boar"
display_name = "野豬"
max_hp = 80
move_speed = 80.0
chase_speed = 120.0
detection_radius = 200.0
attack_range = 50.0  # 近戰範圍（備用）
dash_attack_range = 180.0  # 突進啟動範圍
attack_cooldown = 0.5  # 近戰冷卻
dash_cooldown = 2.0    # 突進冷卻
charge_duration = 0.8  # 蓄力時間
enemy_scene = ExtResource("Enemy_Boar")
loot_table = ExtResource("lt_boar")
```

#### 5. 行為流程

```
         Idle（原地待機）
            │
            │ 看到玩家 + 在突進範圍內 + 冷卻結束
            ▼
      Charge（蓄力 0.8s）
      - 停止移動
      - 面向玩家
      - 視覺閃爍預警
            │
            │ 蓄力完成
            ▼
       Dash（突進 0.3s）
       - 高速直線衝刺
       - 啟用 DashHitbox
       - 碰撞造成傷害
            │
            │ 突進結束
            ▼
         Idle（冷卻 2.0s）
         - 短暫眩暈或減速
```

#### 6. Arena_Test 整合

- **按 F8**: 生成 Boar（在玩家位置附近）
- DebugOverlay 顯示：
  - Boar 狀態
  - Boar HP
  - 突進冷卻時間

#### 7. 平衡考量

| 參數 | 值 | 理由 |
|------|-----|------|
| charge_duration | 0.8s | 給玩家足夠反應時間 |
| dash_speed | 400 | 很快，必須用 Dash 躲避 |
| dash_duration | 0.3s | 短暫但有威脅 |
| dash_cooldown | 2.0s | 突進後有破綻可攻擊 |
| HP | 80 | 比 Slime 硬，需要多次攻擊 |

### 驗收標準 (Acceptance Criteria)
- [ ] `EnemyChargeState` 存在，敵人會停止並蓄力
- [ ] 蓄力期間有明顯視覺提示（閃爍/動畫）
- [ ] `EnemyDashState` 存在，敵人會高速直線突進
- [ ] 突進過程中啟用 DashHitbox，玩家接觸會受傷
- [ ] 突進結束後有冷卻時間（無法連續突進）
- [ ] 玩家可以用 Dash 無敵幀穿過突進不受傷
- [ ] 玩家可以側向走位避開直線突進
- [ ] Boar HP 歸零時正常死亡並掉落
- [ ] 按 F8 可以生成測試 Boar
- [ ] DebugOverlay 顯示 Boar 狀態和突進冷卻

### 技術約束
- 沿用現有 EnemyAIController 架構
- Charge/Dash 狀態與現有狀態（Idle/Chase/Attack/Dead）共存
- 突進傷害使用獨立的 DashHitbox（與普通攻擊 Hitbox 分開）
- 蓄力時間必須足夠長（>0.5s），給玩家反應時間

### ⚠️ 必須遵守的 Coding Habits
詳見 `obsidian_vault/0324/04_Coding_Habits.md.md`：

1. **Fail Fast, Not Softly** - 使用 `assert()` 檢查必要節點
2. **Underscore Rules** - 局部變數使用後綴 `_`
3. **Type Annotation Rules** - 明確標註型別
4. **Region Style** - 使用 `#region` 分區

### 參考檔案
```
game/scripts/enemies/states/EnemyChargeState.gd     # 需新增
game/scripts/enemies/states/EnemyDashState.gd       # 需新增
game/scripts/enemies/EnemyAIController.gd           # 需修改（+ Dash 方法）
game/scripts/enemies/states/EnemyIdleState.gd       # 可能需修改（Boar 邏輯）
game/scenes/enemies/Enemy_Boar.tscn                 # 需新增
game/data/enemies/en_boar.tres                      # 需新增
game/data/loot_tables/lt_boar.tres                  # 需新增
game/scripts/core/ArenaTest.gd                      # 需修改（+ F8 生成）
game/scripts/ui/DebugOverlay.gd                     # 需修改（+ Boar 資訊）
```

### 三種敵人對比

| 特性 | Slime | Archer | Boar |
|------|-------|--------|------|
| **類型** | 近戰追擊 | 遠程保持 | 突進爆發 |
| **攻擊** | 碰撞 | 投射物 | 直線突進 |
| **預警** | 無 | 無 | 蓄力閃爍 |
| **反制** | 拉開距離 | 靠近逼迫 | Dash 無敵 |
| **HP** | 60 | 40 | 80 |
| **Debug** | F6 | F7 | F8 |

---

## 輸出要求

1. **完成後請更新此檔案底部「任務狀態」為已完成**
2. **簡要說明實作內容** (2-3 行)
3. **列出修改的檔案清單**
4. **標註任何遇到的問題或需要討論的設計決策**

---

## 任務狀態

- [ ] 進行中
- [x] 已完成

### 實作摘要
- 新增 `EnemyChargeState` 與 `EnemyDashState`，讓 Boar 會先蓄力預警，再沿鎖定方向高速直線突進；突進期間啟用獨立 `DashHitbox` 對玩家造成傷害。
- `EnemyAIController` 與 `EnemyData` 已擴充突進參數、冷卻、視覺閃爍與除錯欄位，並保持與 Slime / Archer 共用同一套敵人骨架。
- 建立 `Enemy_Boar.tscn`、`en_boar.tres`、專屬掉落表與素材資源，Arena_Test 支援預放與 `F8` 生成 Boar，DebugOverlay 會顯示 Boar 狀態、HP 與突進冷卻。

### 修改檔案
- `game/scripts/data/EnemyData.gd`
- `game/scripts/enemies/EnemyAIController.gd`
- `game/scripts/enemies/states/EnemyIdleState.gd`
- `game/scripts/enemies/states/EnemyChaseState.gd`
- `game/scripts/enemies/states/EnemyChargeState.gd`
- `game/scripts/enemies/states/EnemyDashState.gd`
- `game/scenes/enemies/Enemy_Boar.tscn`
- `game/data/enemies/en_boar.tres`
- `game/data/loot_tables/lt_boar.tres`
- `game/data/items/material_boar_tusk.tres`
- `game/data/items/material_boar_hide.tres`
- `game/scripts/core/ArenaTest.gd`
- `game/scenes/Arena_Test.tscn`
- `game/scripts/ui/DebugOverlay.gd`
- `game/scenes/DebugOverlay.tscn`

### 備註/問題
- Boar 目前沿用現有 `spider_boss_sheet.png` 做棕色暫時視覺，重點先放在蓄力提示、突進路徑與 DashHitbox 行為；正式野豬美術可後續直接替換。
- 突進邏輯特別避免落回一般 `Attack` state，因為 Boar 的主要威脅是蓄力後直線突進，不是近身揮擊；`Chase` 也已補上 state 檢查，避免跳到不存在的普通攻擊狀態。
