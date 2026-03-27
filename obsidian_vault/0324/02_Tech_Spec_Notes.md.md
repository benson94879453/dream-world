# 異境開發｜Tech Spec Notes

## 一、資料邊界（Sources of Truth）

### 1. Static Data
用途：
- 存放唯讀模板
- 位於 `res://data/`
- 使用 Godot `Resource`

包含：
- `ItemData.gd`
- `WeaponData.gd`
- `EnemyData.gd`
- `SkillData.gd`
- `RecipeData.gd`
- `LootTableData.gd`

原則：
- 不可直接承載執行期變動
- 不可直接作為玩家持有物件狀態
- 不可把臨時 Buff / 強化等級寫回模板

---

### 2. Runtime Instance
用途：
- 管理遊戲執行中的動態狀態
- 存於 Scene Tree 或記憶體物件中

包含：
- `WeaponInstance.gd`
- `EnemyInstance.gd`
- `InventorySlot.gd`
- `HealthComponent.gd`

原則：
- 執行期狀態只改 runtime object
- 可從 ID 回查 Resource 模板
- 不直接污染 `.tres`

---

### 3. Save DTO
用途：
- 只保存最小必要資料
- 可序列化成 JSON

保存內容：
- 玩家當前狀態
- 背包內容
- 武器實例變動欄位
- 吸魂解鎖
- 任務進度
- 世界旗標

原則：
- 存最小資料，不存整個 scene object
- 所有可還原資料都應以 ID + runtime fields 表示
- 必須包含 `save_version`

---

## 二、目錄結構

```text
res://
 ├─ core/
 │   ├─ game_manager.gd
 │   ├─ event_bus.gd
 │   └─ save_manager.gd
 ├─ data/
 │   ├─ definitions/
 │   └─ instances/
 ├─ entities/
 │   ├─ components/
 │   ├─ player/
 │   └─ enemies/
 ├─ systems/
 │   ├─ combat/
 │   ├─ inventory/
 │   └─ progression/
 └─ ui/
````

目標：

- 依功能模組拆分
    
- 避免把所有腳本堆在場景資料夾
    
- 提升可維護性與搜尋效率
    

---

## 三、WeaponData 與 WeaponInstance 規範

### WeaponData

用途：

- 作為唯讀模板
    

最小欄位：

- `weapon_id`
- `display_name`
- `base_atk`
- `attack_speed`
- `attack_range`
- `weapon_type`
- `weapon_scene`
- `attack_profile`  # WeaponAttackProfile，攻擊表現配置
- `attack_actor_scene`  # 法術/遠程武器的投射物場景
    

---

### WeaponInstance

用途：

- 代表玩家實際持有的一把武器
    

最小欄位：

- `instance_uid`
    
- `weapon_id`
    
- `enhance_level`
    
- `temporary_enchants`
    
- `socketed_gems`
    

---

### WeaponAttackProfile

用途：

- 定義武器攻擊的表現層配置
- 時機控制 (startup/active/recovery frames)
- 視覺/聽覺表現 (animation, muzzle_flash, hit_effect, audio)
- 冷卻時間

原則：

- 純配置，無執行邏輯
- SwordWeapon/StaffWeapon 讀取並執行
- 允許為 null (如 UnarmedWeapon)

---

### 映射規則

- `WeaponInstance` 初始化時只接收 `weapon_id`
- 透過查表載入對應 `WeaponData`
- 變動欄位由 `WeaponInstance` 自己持有
- 存檔時只序列化變動欄位與 ID
- 讀檔時：
  1. 用 `weapon_id` 建立 `WeaponInstance`
  2. 載入 `WeaponData`
  3. 覆蓋 runtime fields
        

---

## 四、Inventory 分流規範

### Stackable Item

對象：

- 素材
    
- 消耗品
    

儲存形式：

```json
{ "item_id": "itm_iron_ore", "amount": 15 }
```

特性：

- 可堆疊
    
- 遵守 `max_stack`
    
- 背包內通常只追蹤數量
    

---

### Unique Item

對象：

- 武器
    
- 裝備
    
- 帶有強化 / 鑲嵌 / 附魔狀態的物件
    

儲存形式：

- 存放 `WeaponInstance` 類物件
    
- 存檔時轉為獨立 JSON 結構
    

原則：

- 不可與 stackable 共用資料結構
    
- 不可被單純用 `item_id + amount` 取代
    

---

## 五、戰鬥管線

## AttackContext

用途：

- 統一所有攻擊資料的傳遞格式
    
- 供近戰、技能、遠程、陷阱共用
    

建議結構：

```gdscript
class_name AttackContext
extends RefCounted

var source_node: Node2D
var attacker_faction: int
var base_damage: float
var damage_type: int
var poise_damage: float
var knockback_force: float
var hitstop_scale: float
var tags: Array[String] = []
var can_trigger_on_hit: bool = true
```

---

### Damage Pipeline

資料流：

```text
Hitbox -> Hurtbox -> DamageReceiver -> HealthComponent -> FeedbackReceiver
```

職責：

- `Hitbox`
    
    - 發起攻擊碰撞
        
    - 攜帶 `AttackContext`
        
- `Hurtbox`
    
    - 接收攻擊碰撞
        
    - 驗證是否可受擊
        
- `DamageReceiver`
    
    - 接收 `AttackContext`
        
    - 判定陣營 / 無敵 / 受擊條件
        
    - 計算最終傷害
        
    - 通知 `HealthComponent`
        
- `HealthComponent`
    
    - 管理 `max_hp / current_hp`
        
    - 處理扣血與死亡
        
    - 發出 `health_changed / died`
        
- `FeedbackReceiver`
    
    - 處理受擊視覺表現
        
    - Hit flash
        
    - Knockback
        
    - 後續可擴充 hit stop / camera shake

---

### SpellActor 系統

用途：

- 統一法術效果的執行單位
- 由 StaffWeapon 生成並管理生命週期

類型：

```gdscript
enum SpellType {
    PROJECTILE,    # 投射物 (如 BoltSpellActor)
    INSTANT,       # 立即生效 (如 HealSpellActor, ExplosionSpellActor)
    CONTINUOUS     # 持續性 (如護盾、光環)
}
```

生命週期：

- PROJECTILE: 物理移動直到碰撞或超時
- INSTANT: 生成後立即執行效果，然後清理
- CONTINUOUS: 持續作用直到 lifetime 結束

責任：

- SpellActor: 定義法術類型和生命週期
- 子類 (Bolt/Heal/Explosion): 實作具體效果
- StaffWeapon: 根據 SpellType 決定生成後的行為
        

---

## 六、Autoload 邊界

### GameManager

責任：

- 管理場景切換
    
- 管理高層流程狀態
    
- 不負責背包、戰鬥細節、任務內容
    

### SaveManager

責任：

- 新遊戲
    
- 存檔
    
- 讀檔
    
- 存檔遷移
    

### EventBus

責任：

- 只做跨系統高層事件廣播
    
- 不處理高頻戰鬥事件
    

### ProgressionManager / QuestManager

責任：

- 記錄圖鑑、吸魂、任務、旗標
    
- 提供查詢與更新 API
    

---

## 七、EventBus 白名單

允許事件：

- `scene_transition_requested(target_scene_path: String)`
    
- `game_state_changed(new_state: String)`
    
- `player_died()`
    
- `inventory_updated()`
    
- `soul_absorbed(enemy_codex_id: String)`
    
- `quest_state_changed(quest_id: String, state: int)`
    

禁止事件：

- 每次命中
    
- 每顆子彈飛行
    
- 每幀角色狀態同步
    
- FSM 內部切換細節
    

原則：

- 局部事件局部解決
    
- 跨系統事件才進 Bus
    

---

## 八、Save Schema

```json
{
  "save_version": 1,
  "created_at": "2026-03-23T15:22:00Z",
  "updated_at": "2026-03-23T18:00:00Z",
  "player_profile": {
    "current_hp": 100,
    "last_saved_hub": "hub_village_01"
  },
  "inventory": {
    "stackables": [
      {"id": "itm_slime_mucus", "amount": 24},
      {"id": "itm_iron_ore", "amount": 5}
    ],
    "unique_equipment": [
      {
        "instance_uid": "wpn_1001",
        "weapon_id": "wpn_rusty_sword",
        "enhance_level": 2,
        "socketed_gems": ["gem_hp_1"]
      }
    ]
  },
  "progression": {
    "unlocked_souls": ["codex_slime_basic", "codex_goblin_fighter"],
    "quest_states": {
      "qst_blacksmith_intro": 2
    },
    "flags": {
      "zone_2_unlocked": true
    }
  }
}
```

---

### 存檔失敗策略

- 找不到 `weapon_id`：回退預設武器並記錄 warning
    
- 找不到 `item_id`：跳過並記錄 warning
    
- version 過舊：執行 migration
    
- migration 失敗：回退新檔或備份檔
    
- 不允許因單筆資料失敗導致整份存檔 crash
    

---

## 九、組件化規範

### 場景只做組裝

- 場景主要負責掛載 component
    
- 不把大量規則直接塞進單一 script
    

### Component 優先

共用模組優先拆成：

- `HealthComponent`
    
- `DamageReceiver`
    
- `FeedbackReceiver`
    
- `Hitbox`
    
- `Hurtbox`
    

### 命名與 NodePath 固定

共用節點名稱固定：

- `StateMachine`
    
- `Hurtbox`
    
- `Hitbox`
    
- `HealthComponent`
    
- `FeedbackReceiver`
    
- `WeaponPivot`
    

目標：

- 避免 NodePath 到處寫死不同名字
    
- 降低組件重用成本
    

---

## 十、Debug Tooling 原則

### 開發期必備

- F3 開啟 Debug Overlay
    
- 顯示 FSM state
    
- 顯示 HP
    
- 顯示最近受擊傷害
    
- 一鍵補血
    
- 一鍵生成測試怪
    
- 一鍵無敵
    
- 一鍵拿測試武器
    

### 原則

- 工具先行
    
- 功能能被快速測試
    
- bug 能被快速重現
    
- 不讓測試成本拖慢開發
    

---

## 十一、MVP 不做的事

- 真開放世界流式載入
    
- 正式小地圖 / 世界地圖
    
- 大量分支任務
    
- 複雜 Boss 表現系統
    
- 完整遠程武器物件池
    
- 大量內容量產
    

---

## 十二、建議開工順序

1. `AttackContext.gd`
    
2. `HealthComponent.gd`
    
3. `DamageReceiver.gd`
    
4. `Hitbox.gd`
    
5. `Hurtbox.gd`
    
6. `FeedbackReceiver.gd`
    
7. `Enemy_Dummy.tscn`
    
8. `Arena_Test.tscn`
    
9. `Player.tscn`
    
10. `DebugOverlay.tscn`
    

目標：

- 先把戰鬥底座釘死
    
- 再接背包、掉落、進度、存檔
    

```

---

如果你要，我下一步可以直接接著幫你做 **`03_Implementation_Order.md`**，把每個腳本的建立順序和依賴關係也拆成 Obsidian 可打勾版本。
```