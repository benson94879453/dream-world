# Retrospective #001 - 自我迭代檢視

> 這份文件記錄 #001 驗收後發現的潛在改進點，供未來任務參考

---

## ✅ 已確認正確

| 項目 | 確認結果 |
|------|----------|
| 功能完整性 | ✅ 5/5 驗收標準達成 |
| 架構正確性 | ✅ 使用現有 API，無違規 |
| 資料邊界 | ✅ Resource/Instance 分離正確 |

---

## 🔍 潛在缺陷與改進點

### 1. 狀態安全問題 ⚠️ 低優先
**觀察**: 目前攻擊中（按攻擊鍵時）可以直接切換武器

**潛在風險**:
```
玩家按下攻擊 → SwordWeapon 進入攻擊動畫
玩家按下 3 切換法杖 → SwordWeapon 被移除，但攻擊判定可能還在進行
```

**建議改進**:
- 未來加入「攻擊中不可切換武器」的檢查
- 或在切換武器時強制中斷當前攻擊（呼叫 unequip 時清理狀態）

**影響範圍**: 目前只是 Debug 功能，風險低。正式武器切換流程時需處理。

---

### 2. 輸入處理位置 🤔 架構考量
**觀察**: 輸入處理直接寫在 `Player.gd`

**替代方案**:
```
選項 A: 維持現狀 (Player.gd 處理)
  - 優點: 簡單直接
  - 缺點: Player.gd 會累積 debug 邏輯

選項 B: 獨立 DebugWeaponSwitcher component
  - 優點: 正式發布時可直接移除該 component
  - 缺點: 需要額外一個檔案
```

**結論**: 維持現狀合理，但 #003+ 若有更多 debug 功能，建議抽離。

---

### 3. Debug Overlay 更新機制 📊 性能
**觀察**: 需確認 DebugOverlay 是如何讀取武器名稱

**理想做法**:
```gdscript
# DebugOverlay.gd - 建議使用 signal 而非每幀輪詢
# 目前可能是:
func _process(delta):
    weapon_label.text = player.current_weapon.display_name  # 每幀讀取

# 更好的做法:
func _ready():
    player.weapon_changed.connect(_on_weapon_changed)  # 事件驅動

func _on_weapon_changed(new_weapon):
    weapon_label.text = new_weapon.display_name
```

**實際狀況**: 待確認，如果目前是每幀輪詢，建議未來改為事件驅動。

---

### 4. Prompt 品質改進 📝
**發現的錯誤**:
- Prompt 寫 `WeaponController.equip_weapon()`，實際是 `PlayerController.equip_weapon_data()`

**改進措施**:
- 未來撰寫 Prompt 前，應先讀取關鍵檔案確認 API 名稱
- 在 Prompt 中加上「若 API 名稱不符，請使用實際存在的等價方法」

---

### 5. UnarmedWeapon 設計 🎯
**觀察**: Codex 主動建立了 `UnarmedWeapon.tscn`

**疑問**: 
- 這個 scene 的內容是什麼？是繼承 WeaponController 的空實現嗎？
- 是否有預留空手的攻擊可能性（例如拳擊）？

**建議**: 
- 確認 `UnarmedWeapon.gd` 是否正確處理 `try_attack()`（應該是空實現或 print log）
- 若未來要支援「空手拳擊」，現在的架構是否支援？

---

## 📋 對 #002 的影響

### 需要注意
1. **AttackProfile 的幀計時**: 若 #001 的輸入處理是每幀檢查，#002 的攻擊階段計時也要考慮 process frame 的一致性

2. **武器切換中斷攻擊**: #002 實作三階段攻擊時，需確保切換武器能正確中斷（清理 timers/connections）

3. **UnarmedWeapon 的 AttackProfile**: 空手是否需要 AttackProfile？還是 `attack_profile = null`？
   - 建議: 允許為 null，在 SwordWeapon/StaffWeapon 中做防護 `if weapon_data.attack_profile:`

---

## 🎯 對 #002 Prompt 的即時調整

在原本 #002 Prompt 基礎上，新增以下提醒：

```
[新增於技術約束]
- 武器切換時需能安全中斷當前攻擊（清理正在進行的 attack timer）
- AttackProfile 允許為 null（用於 UnarmedWeapon），武器腳本需做防護
```

是否需要在 #002 開始前更新 Prompt？
