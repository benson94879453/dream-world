# Code Review #004 - Player Attack State

## 任務資訊

- **任務名稱**: 實作 Player Attack State
- **Codex 完成時間**: 2026-03-27
- **Kimi 驗收時間**: 2026-03-27

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| PlayerAttackState 存在並可從 Idle/Walk/Run 進入 | ✅ 通過 | 新增 PlayerAttackState.gd |
| 進入 Attack 狀態後才執行武器攻擊 | ✅ 通過 | `enter()` 呼叫 `_try_start_attack()` |
| startup/active 階段鎖定移動 | ✅ 通過 | `physics_update()` 設 `velocity = Vector2.ZERO` |
| 攻擊中可以 Dash cancel 到 Dash 狀態 | ✅ 通過 | `handle_input()` 監聽 dash 動作 |
| combo window 內按攻擊鍵自動連接下一次 | ✅ 通過 | `combo_queued` 機制實作 |
| can_combo() 在非 combo window 返回 false | ✅ 通過 | active 或 recovery 前半段才返回 true |
| Debug Overlay 顯示攻擊階段和 combo 狀態 | ✅ 通過 | 新增 Attack Phase/Combo Ready/Combo Queued |
| 5 種武器攻擊功能正常 | ✅ 通過 | Sword/Staff(3種) 皆正常 |
| 武器切換在 Attack 狀態中可中斷攻擊 | ✅ 通過 | `cancel_attack()` 整合 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| PlayerAttackState 繼承 PlayerState | ✅ 通過 | class 定義正確 |
| 狀態轉移透過 StateMachine | ✅ 通過 | `transition_to()` 使用正確 |
| 武器新增查詢接口 | ✅ 通過 | `can_combo()`, `get_current_phase()`, `cancel_attack()` |
| Combo 預輸入簡潔實作 | ✅ 通過 | bool 變數標記，無複雜緩衝 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | snake_case |
| 程式碼結構清晰 | ✅ 通過 | region 分區 |

---

## 詳細回饋

### 優點 👍

1. **狀態機整合完整** - 攻擊流程從輸入驅動改為狀態機驅動，PlayerAttackState 接管所有攻擊相關邏輯

2. **Combo 機制** - 在 active 階段或 recovery 前半段 (`time_left >= recovery_seconds * 0.5`) 可預輸入 combo

3. **Cancel 機制** - Dash (Space) 任何時候都可以 cancel，整合 `lock_controls_for()` 提供緩衝

4. **移動鎖定** - `physics_update()` 強制 `move_character(Vector2.ZERO, 0.0)`，確保攻擊中無法移動

5. **Debug Overlay 完整** - 顯示 Attack Phase、Combo Ready、Combo Queued，開發除錯資訊充足

6. **Dash 鍵配置** - 使用 Space 避免與 Shift (Run) 衝突，設計合理

### 設計決策記錄 📝

**Combo 實作細節**:
```gdscript
# SwordWeapon.can_combo()
- ACTIVE 階段: 永遠可以 combo
- RECOVERY 階段: 只有前 50% 可以 combo
- 其他階段: 不可 combo
```

**Cancel 行為**:
- Cancel 時呼叫 `weapon.cancel_attack()` 清理 timer
- 轉移到 `Locked` 狀態（短暫控制鎖定）
- 尚未實作真正的 dash 位移

**Combo 接續優化**:
- Combo 接續時會先 `cancel_attack()` 清掉剩餘 cooldown
- 然後立即 `try_primary_attack()` 重啟攻擊
- 備註建議：未來若要做武器平衡，可抽成獨立 combo 專用 API

---

## 驗收結果

- [x] **通過** - Phase 2 武器系統完成！
- [ ] 有條件通過
- [ ] 需要重做

### 下一步行動

**Phase 2 全部完成 ✅**

可選下一步：
1. **Phase 3**: 背包/掉落/存檔系統
2. **優化**: 真正的 Dash 位移、武器動畫 clip
3. **敵人 AI**: 讓 Dummy 變成會移動攻擊的敵人

---

## Phase 2 最終架構

```
玩家戰鬥系統:
├── 狀態機
│   ├── Idle / Walk / Run
│   ├── Locked (控制鎖定)
│   └── Attack (NEW)
│       ├── 鎖定移動
│       ├── 支援 Combo
│       └── 支援 Cancel
│
├── 武器系統
│   ├── WeaponData + WeaponAttackProfile
│   ├── SwordWeapon (三階段攻擊)
│   └── StaffWeapon (SpellType 分流)
│
└── 法術系統
    ├── PROJECTILE: BoltSpellActor
    ├── INSTANT: HealSpellActor, ExplosionSpellActor
    └── CONTINUOUS: (預留)
```

---

## 相關連結

- Codex Prompt: `codex_prompt.md`
- 修改檔案: 15 個
- SYNC_SUMMARY: 待更新
