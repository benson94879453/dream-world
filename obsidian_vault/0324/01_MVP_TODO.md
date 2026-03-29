# 01_MVP_TODO

> 最小可交付任務清單
> Godot 4.x / 單人開發

---

## 已完成 ✅（Phase 1-5）完整循環達成

### 核心戰鬥系統
- [x] Build `Player.tscn` - 角色控制器、狀態機
- [x] Build `Enemy_Dummy.tscn` - 基礎敵人
- [x] Add 8-direction movement - 八方向移動
- [x] Add walk and run states - 走/跑狀態
- [x] Add player melee attack input - 近戰攻擊
- [x] Add player attack hitbox - 攻擊判定
- [x] `AttackContext.gd` - 攻擊上下文
- [x] `Hitbox.gd` / `Hurtbox.gd` - 碰撞系統
- [x] `DamageReceiver.gd` / `HealthComponent.gd` - 傷害管線
- [x] `PlayerAttackState.gd` - 攻擊狀態（Combo/Cancel）

### 武器系統
- [x] `WeaponData` / `WeaponInstance` - 武器資料與實例
- [x] `SwordWeapon` / `StaffWeapon` - 劍/法杖武器類型
- [x] `SpellActor` 系統 - 投射/即時/持續法術
- [x] 數字鍵 1-5 武器切換

### 物品與背包
- [x] `ItemData` - 物品資料定義
- [x] `Inventory` - 20格背包系統
- [x] stackable + unique 支援
- [x] `PickupItem` - 掉落物與撿取
- [x] `LootTableData` - 掉落表配置

### 存檔系統
- [x] `SaveManager` - Autoload 存檔管理
- [x] Save/Load DTO 結構
- [x] `save_version` + 版本遷移
- [x] F5存檔 / F9讀檔

### 敵人 AI 系統
- [x] `EnemyAIController` - 敵人 AI 控制器
- [x] `EnemyStateMachine` - 敵人狀態機
- [x] **Slime** (F6) - 近戰追擊型
- [x] **Archer** (F7) - 遠程保持距離型
- [x] **Boar** (F8) - 突進爆發型（Charge→Dash）

### Dash 系統
- [x] `PlayerDashState` - Dash 狀態
- [x] 衝刺位移（120px / 0.15s）
- [x] Dash 無敵幀
- [x] Dash Cancel 攻擊
- [x] Dash 冷卻顯示

### Phase 5A: NPC 對話系統
- [x] `DialogData` / `DialogNodeData` / `DialogChoiceData` - 對話資料模型
- [x] `DialogManager` - Autoload 對話管理
- [x] `DialogUI` - 逐字顯示、選項分支
- [x] `NPCDialogTrigger` - 互動觸發
- [x] Save v2 整合 - 對話 flags 保存

### Phase 5B: 武器升級系統
- [x] `AffixData` / `AffixTable` - 詞綴定義與抽選
- [x] `UpgradeManager` - 升級邏輯 (Autoload)
- [x] `WeaponUpgradeUI` - 升級介面
- [x] 6個基礎詞綴（鋒利、沉重、迅捷、專注、吸血、暈眩）
- [x] 星級系統（0★→5★，每級+5%攻擊）
- [x] 符文槽（1★=1槽, 5★=5槽）
- [x] Save v3 整合 - 星級與詞綴保存
- [x] 鐵匠對話整合

---

## 🎉 完整可玩循環已達成

```
對話 → 戰鬥 → 掉落 → 撿取 → 裝備 → 強化 → 存檔
  ✅      ✅      ✅      ✅      ✅      ✅      ✅
```

**驗收結果**：
- NPC 對話：save_version=2, dialog_flag saved=true restored=true
- 武器升級：save_version=3, stars=2/2, affixes=1/1

---

## ✅ Phase 6A: 符文鑲嵌系統（已完成）

| 任務 | 工時 | 相依性 | 狀態 |
|------|:---:|:------:|:----:|
| RuneData / RuneSlot / RuneInstance | 小(4h) | - | ✅ |
| RuneManager | 中(1d) | R1 | ✅ |
| 12個符文石資源 | 小(4h) | - | ✅ |
| RuneSocketUI | 中(1-2d) | R2 | ✅ |
| WeaponUpgradeUI 雙頁籤 | 小(4h) | R4 | ✅ |
| Save v4 整合 | 小(4h) | R5 | ✅ |

**驗收結果**：
- ✅ 三種槽位類型（自由/類型/核心）
- ✅ 12個基礎符文石（8普通+4核心）
- ✅ 鑲嵌/拆卸功能（拆卸成本計算）
- ✅ Save v4：saved=["rune_fire","",""], restored=[&"rune_fire",&"",&""]
- ⚠️ 拆卸金幣扣減：UI已做，待貨幣系統實裝

---

## 進行中 🔄（下一階段重點）

### ✅ Phase 7B: 符文效果實裝 已完成
讓核心符文的特殊機制真正影響戰鬥

| 任務 | 工時 | 相依性 | 驗收標準 | 狀態 |
|------|:---:|:------:|----------|:----:|
| R7.1 無盡之刃 | 中(1d) | - | 10%機率不消耗攻擊冷卻 | ✅ |
| R7.2 雙重打擊 | 中(1d) | - | 15%機率造成兩次傷害 | ✅ |
| R7.3 元素共鳴 | 小(4h) | - | 元素傷害+25% | ✅ |
| R7.4 吸血渴望 | 中(1d) | - | 攻擊回復5%傷害HP，滿血轉護盾 | ✅ |

---

### ✅ Phase 7B+: Arena 測試流程 已完成
驗證符文效果機率與數值正確性

| 任務 | 工時 | 相依性 | 驗收標準 | 狀態 |
|------|:---:|:------:|----------|:----:|
| T/Y/U/I 測試按鍵 | 小(4h) | - | 開啟/機率/元素/護盾 | ✅ |
| RuneTestManager | 小(4h) | - | Autoload 統計管理 | ✅ |
| DebugOverlay 面板 | 小(4h) | - | 顯示測試結果 | ✅ |
| 火焰傷害計算 | 小(2h) | - | 10% 元素傷害實裝 | ✅ |

**測試結果**：
```
無盡之刃: 11/100 (11.0%) | 期望: 10% ✓
雙重打擊: 15/100 (15.0%) | 期望: 15% ✓
元素共鳴: 20 → 22 (+10%) → 27.5 (+25%) ✓
護盾測試: ✓ 護盾先於 HP 扣除
```

**Arena 測試操作**：
- 按 `T` 開啟/關閉測試模式
- 按 `Y` 執行 100 次攻擊機率統計
- 按 `U` 顯示元素傷害對比
- 按 `I` 驗證護盾吸收順序

---

### Phase 7 總結 🎉

**完整經濟+符文循環達成**：
```
戰鬥 → 掉落金幣/符文 → 強化武器 → 調整符文（扣金幣）
  ↑                                    ↓
  └────── 分解多餘武器 ─────────────────┘
```

**核心系統**：
- ✅ 金幣系統（Save v5）
- ✅ 武器分解（DecomposeManager）
- ✅ 敵人掉落擴充（金幣+符文）
- ✅ 符文拆卸扣款
- ✅ 4 個核心符文機制
- ✅ Arena 測試驗證

---

**實作摘要**：
- 無盡之刃：SwordWeapon/StaffWeapon 攻擊結束時判定，重置冷卻
- 雙重打擊：SwordWeapon 命中後延遲0.05s補第二下（僅近戰）
- 元素共鳴：DamageReceiver 計算傷害時套用+25%
- 吸血渴望：DamageReceiver 統一處理，HealthComponent 護盾系統
- 元素Tag：WeaponInstance/WeaponController/SpellActor 協同注入

---

### ✅ #018 滑鼠攻擊模式 已完成
攻擊控制方式改進

| 任務 | 工時 | 相依性 | 驗收標準 | 狀態 |
|------|:---:|:------:|----------|:----:|
| 滑鼠左鍵輸入 | 小(2h) | - | project.godot 新增 attack_mouse | ✅ |
| 角色面向滑鼠 | 小(2h) | - | 依滑鼠位置切換左右 | ✅ |
| Combo 續接 | 小(2h) | - | PlayerAttackState 接受 attack_mouse | ✅ |

**已知問題**：
- ⚠️ 投射物只往左/右飛，非朝滑鼠位置（#018+ 修復中）
- 📝 既存 Player.tscn UID warning（非本次引入）

---

### ✅ #018+ 投射物方向修復 已完成
讓 StaffWeapon 法術朝滑鼠位置發射

| 任務 | 工時 | 相依性 | 驗收標準 | 狀態 |
|------|:---:|:------:|----------|:----:|
| StaffWeapon 方向計算 | 小(2h) | - | 計算朝滑鼠向量 | ✅ |
| 滑鼠重疊 fallback | 小(1h) | - | 零向量處理 | ✅ |

**實作重點**：
- StaffWeapon 直接計算朝滑鼠的方向向量
- 滑鼠與施法點重疊時 fallback 到既有左右方向
- SpellActor/BoltSpellActor 原本就支援任意方向，無需修改

---

### ✅ #019 Minecraft 風格背包 UI 已完成
完整背包介面系統

| 任務 | 工時 | 相依性 | 驗收標準 | 狀態 |
|------|:---:|:------:|----------|:----:|
| InventoryUI | 中(1d) | - | 20格、分類、拖曳 | ✅ |
| ItemSlotUI | 中(1d) | - | 格子、tooltip | ✅ |
| HotbarManager | 中(1d) | - | 綁定、1-5使用 | ✅ |
| 整合輸入 | 小(4h) | - | E/I、Player | ✅ |

**功能清單**：
- ✅ 5x4 方格背包（20格）
- ✅ 6種分類標籤過濾
- ✅ 0.5秒延遲 tooltip
- ✅ 拖曳換位
- ✅ 快捷欄綁定（5格）
- ✅ 數字鍵 1-5 使用
- ✅ 武器快速裝備
- ✅ 消耗品治療

**操作**：E/I 開關背包，拖曳整理/綁定，1-5 快捷使用

**已知限制**：
- ⚠️ Hotbar 綁定尚未進存檔（建議與新版 Inventory / Equipment schema 一併規劃）
- ⚠️ 消耗品效果為通用 heal 25 HP（可擴充 ConsumableData）
- ⚠️ `Inventory` 仍混有裝備責任，尚未拆出 `Equipment` / `GearInstance` / 多容器快速移動

---

### Phase 8: 物品 / 武器 / 裝備 / 背包架構重整（規格已定稿）
**目標**：在不推翻現有雛形的前提下，將背包、裝備、快捷欄、掉落物與存檔正式拆分，支援單機、多容器、唯一實例裝備與版本化存檔。

| 任務 | 工時 | 相依性 | 驗收標準 | 狀態 |
|------|:---:|:------:|----------|:----:|
| P8.1 `GearData` / `GearInstance` | 小(4-6h) | - | 裝備改為唯一實例模型 | ⬜ |
| P8.2 `ItemData.get_stack_key()` | 小(1-2h) | - | 一般 item 改用 stack key 判斷堆疊 | ⬜ |
| P8.3 `InventorySlot` 擴充 | 小(2-4h) | P8.1, P8.2 | 同時支援 item / weapon / gear 三型態 | ⬜ |
| P8.4 `Inventory` 重構 | 中(1-2d) | P8.3 | 支援 gear、多容器、slot-based save/load、v1→v2 migration | ⬜ |
| P8.5 `Equipment.gd` | 中(1d) | P8.1 | `weapon_main/helmet/chestplate/leggings/boots` 可裝卸與交換 | ⬜ |
| P8.6 Player 協調 API | 中(1d) | P8.4, P8.5 | 背包↔裝備切換、卸裝回包、Shift+Left 行為落地 | ⬜ |
| P8.7 `PickupItem` 保留 UID | 小(4-6h) | P8.1, P8.4 | 武器/裝備掉落與撿取不重建 instance | ⬜ |
| P8.8 Hotbar 綁定規則定稿 | 小(2-4h) | P8.4 | 武器永遠可綁、一般 item 看 tag、gear 不可綁 | ⬜ |
| P8.9 UI 擴充 | 中(1-2d) | P8.4, P8.5, P8.8 | `ItemSlotUI` 顯示 gear、Equipment UI、Chest UI、Shift+Click | ⬜ |

**本輪核心決策**：
- 一般 item 可堆疊，並以 `stack_key` 取代單純 `item_id` 判斷
- `WeaponInstance` / `GearInstance` 都是唯一實例，不可堆疊，掉落與撿取保留 UID
- `Inventory` 專注通用容器；`Equipment` 專注裝備欄；`Hotbar` 只綁定背包 slot
- `Player` 作為協調者，處理 equip/unequip、快捷欄使用、Shift+Left 快速移動
- `Inventory` 存檔升級為 `version + 明確 slot 內容`，並保留 v1 migration

**實作分期**：
- Phase 1：資料層 (`GearData`, `GearInstance`, `stack_key`, `InventorySlot`)
- Phase 2：容器邏輯 (`Inventory` item/weapon/gear、多容器、save/load)
- Phase 3：裝備邏輯 (`Equipment`, Player equip/unequip API、自動交換)
- Phase 4：互動 (`PickupItem`, Shift+Left, Hotbar tag 規則)
- Phase 5：UI（Equipment UI、Chest UI、gear tooltip）

---

### Phase 7C: Hit Stop / FX（中優先）
**目標**：加入局部 hit stop 與命中視覺反饋，提升打擊感。

| 任務 | 工時 | 相依性 | 驗收標準 |
|------|:---:|:------:|----------|
| F1 FeedbackReceiver 擴充 | 小(6-10h) | - | 局部 hit stop 實作 |
| F2 命中 FX | 小(4-8h) | F1 | 閃白、粒子、音效 |

**驗收準則**：
- 命中時短暫暫停受擊目標行為
- 播放 FX，無副作用

---

## 待規劃 📋（中期目標）

### D. NPC 任務系統（中優先）
- [ ] QuestManager skeleton
- [ ] 任務旗標與追蹤
- [ ] NPC 回報邏輯（交付素材/消滅敵人）
- [ ] 獎勵發放（素材/強化券）

### E. 群體 AI（低優先）
- [ ] Slime 群體協作（包圍、支援）
- [ ] 敵人之間的簡單通訊

### ✅ F. Hub / Zone 系統（已完成）
- [x] 場景轉場機制（SceneTransitionManager）
- [x] Portal 傳送門系統
- [x] Town Hub 場景
- [x] Dungeon 01 場景
- [x] 場景狀態持久化（Batch 2 - SceneStateManager、ZoneResetManager、PersistentObject）
- [x] 存檔點設置（Checkpoint）
- [x] 教官 NPC 與動態對話
- [x] 地城清除任務

**Hub-based Vertical Slice 已完成！**
```
Town Hub → Portal → Dungeon 01 → Checkpoint → Boss → 返回 Hub → 教官對話/任務回報
```

### G. Boss 戰鬥（長期）
- [ ] 多階段戰鬥設計
- [ ] Boss 特殊機制

---

## Sprint 建議（2 週週期）

### Sprint 1（NPC 對話基礎）
**目標**：玩家能與 NPC 對話並保存對話旗標

- [ ] A1 Dialog 資料模型
- [ ] A2 DialogManager
- [ ] A3 Dialog UI（基礎版本）
- [ ] A4 NPC Trigger（基礎版本）

**驗收**：玩家能與 NPC 對話，對話狀態保存/讀取正常

### Sprint 2（武器強化 + Hit Stop）
**目標**：完整循環（對話→戰鬥→掉落→撿取→裝備→強化→存檔）

- [ ] E1-E3 武器強化系統
- [ ] E4 強化狀態保存
- [ ] F1-F2 Hit Stop + FX
- [ ] 整合測試與 Playtest

**驗收**：完整循環可執行，所有狀態正確保存

---

## 任務卡格式範例

```markdown
### Task: A3 Dialog UI
**Priority**: High  
**Effort**: 中 (1-2d)  
**Dependencies**: A1, A2

#### Acceptance Criteria
- [ ] 支援逐字顯示與跳過
- [ ] 選項能選擇，並回傳選項 id 給 DialogManager
- [ ] 對話 UI 可由 NPC Trigger 控制顯示/關閉
- [ ] 與現有 SaveManager 整合

#### 參考檔案
- `game/scripts/dialog/DialogData.gd`
- `game/scripts/core/DialogManager.gd`
- `game/scenes/ui/DialogUI.tscn`
```

---

## 注意事項

- 每個 Resource 以 `.tres` 儲存並放在 `res://data/` 對應資料夾
- Save schema 請包含 `save_version` 與 `created_at/updated_at` 欄位
- 參考 `02_Tech_Spec_Notes.md` 的架構規範
