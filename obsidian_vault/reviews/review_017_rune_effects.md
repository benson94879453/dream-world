# Review #017: 符文效果實裝（核心符文特殊機制）

## 驗收結果: ✅ 通過

**日期**: 2026-03-28  
**Codex**: 已完成核心符文機制接入

---

## 功能驗收

| 檢查項 | 狀態 | 實作位置 |
|--------|:----:|---------|
| 無盡之刃（10%冷卻返還） | ✅ | SwordWeapon.gd / StaffWeapon.gd |
| 雙重打擊（15%兩次傷害） | ✅ | SwordWeapon.gd（近戰限定） |
| 元素共鳴（+25%元素傷害） | ✅ | DamageReceiver.gd |
| 吸血渴望（5%回復→護盾） | ✅ | DamageReceiver.gd + HealthComponent.gd |
| 護盾系統 | ✅ | HealthComponent.gd（暫時HP） |
| 元素Tag注入 | ✅ | WeaponInstance/WeaponController/SpellActor |
| 存檔整合（shield） | ✅ | Player.gd + SaveManager |
| Debug顯示 | ✅ | DebugOverlay.gd |
| Console無錯誤 | ✅ | headless --import & --quit-after 60 通過 |

---

## 架構驗收

| 檢查項 | 狀態 | 說明 |
|--------|:----:|------|
| AttackContext擴充 | ✅ | 帶上攻擊者與武器資訊 |
| 共通傷害資料流 | ✅ | DamageReceiver統一處理元素/吸血 |
| 武器端效果觸發 | ✅ | SwordWeapon/StaffWeapon處理無盡之刃 |
| 職責分離 | ✅ | 劍=雙重打擊，共通=吸血，法術=元素 |

---

## 設計決策確認

### ✅ 雙重打擊限定近戰
- 僅 SwordWeapon 可觸發
- StaffWeapon 法術攻擊不觸發

### ✅ 吸血效果共通
- SwordWeapon 和 StaffWeapon 均可觸發
- 放在 DamageReceiver 統一處理

### ✅ 護盾機制
- 暫時性額外 HP
- 受傷時優先扣除
- 存檔時一併保存

---

## 待驗證項目（建議補充測試）

| 測試項 | 說明 |
|--------|------|
| 10%/15% 機率驗證 | 大量攻擊統計實際觸發率 |
| 元素加成倍率 | 驗證+25%正確套用 |
| 護盾吸收順序 | 確認護盾先於HP扣除 |
| 雙重打擊延遲 | 確認0.05s延遲視覺效果 |

---

## 修改檔案清單

```
game/scripts/weapons/SwordWeapon.gd
game/scripts/weapons/StaffWeapon.gd
game/scripts/weapons/WeaponController.gd
game/scripts/weapons/SpellActor.gd
game/scripts/combat/Hitbox.gd
game/scripts/combat/DamageReceiver.gd
game/scripts/combat/HealthComponent.gd
game/scripts/combat/AttackContext.gd
game/scripts/data/WeaponInstance.gd
game/scripts/Player.gd
game/scripts/ui/DebugOverlay.gd
```

---

## 下一步建議

**選項 A**: 補充 Arena 測試流程（機率驗證）  
**選項 B**: 進入 Phase 7C - Hit Stop / FX（戰鬥打擊感優化）

*Review by Kimi*
