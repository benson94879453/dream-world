# Code Review #002 - 武器攻擊表現所有權

## 任務資訊

- **任務名稱**: 定義武器攻擊表現所有權 (Attack Presentation Ownership)
- **Codex 完成時間**: 2026-03-27
- **Kimi 驗收時間**: 2026-03-27

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| WeaponAttackProfile Resource 類別存在 | ✅ 通過 | 14 行，欄位完整 |
| WeaponData 包含 attack_profile 欄位 | ✅ 通過 | 使用 preload 避免循環依賴 |
| SwordWeapon 三階段攻擊 | ✅ 通過 | startup → active → recovery |
| SwordWeapon Hitbox 只在 active 啟用 | ✅ 通過 | 第 100 行 `attack_hitbox.activate()` 在 active phase |
| StaffWeapon startup 後生成 SpellActor | ✅ 通過 | 第 76 行 `_spawn_spell_actor()` 在 active phase |
| 兩種武器都有 profile .tres | ✅ 通過 | sword_basic (0/5/10) / staff_basic (10/0/15) |
| 攻擊時輸出階段 log | ✅ 通過 | `[SwordWeapon] Phase: startup/active/recovery` |
| 現有攻擊功能不受影響 | ✅ 通過 | 劍可傷害、法杖可發射 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 使用現有 API，無重複造輪子 | ✅ 通過 | 擴充既有 WeaponController |
| 資料邊界正確 | ✅ 通過 | AttackProfile 是 Resource，由 WeaponData 持有 |
| 武器切換安全中斷 | ✅ 通過 | `on_unequipped()` → `_cancel_attack()` 清理 timers |
| AttackProfile null 防護 | ✅ 通過 | 多處 `if attack_profile_ != null` 檢查 |
| 組件化原則遵循 | ✅ 通過 | 攻擊表現與邏輯分離 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | snake_case，StringName 使用 `&""` |
| 程式碼結構清晰 | ✅ 通過 | region 分區明確 |
| 適當的註解 | ✅ 通過 | 關鍵函數有文件 |
| 無多餘程式碼 | ✅ 通過 | 精簡有效率 |

---

## 詳細回饋

### 優點 👍

1. **preload 型別別名處理** - 備註中提到的 `const WeaponAttackProfileResource = preload(...)` 是良好的 Godot 循環依賴處理方式

2. **完整的 Phase 狀態機** - SwordWeapon 和 StaffWeapon 都實作了相同的 phase 流程，一致性佳：
   ```gdscript
   PHASE_STARTUP → PHASE_ACTIVE → PHASE_RECOVERY → PHASE_IDLE
   ```

3. **武器切換安全中斷** - `on_unequipped()` 正確清理 timers，解決了 #001 retrospective 中提到的狀態安全問題

4. **靈活的配置** - profile_sword_basic (0/5/10) 和 profile_staff_basic (10/0/15) 展現了不同武器的節奏差異

5. **向後相容** - 所有 `attack_profile` null 檢查確保沒有 profile 時不會 crash

### 問題/建議 🔧

**無重大問題**

小建議（非阻擋）：
- StaffWeapon 的 `PHASE_ACTIVE` 有 0 幀（因為 profile 設定 active_frames=0），這是預期的設計（法杖只在 startup 結束時生成 spell，不需要 active 判定時間）

### 架構觀察 🏗️

**AttackProfile 架構已就緒**：
- 未來加入「攻速提升」功能時，只需修改 `_get_attack_phase_duration_seconds()` 乘上倍率
- 命中音效和 hit effect 透過 AttackContext 傳遞，FeedbackReceiver 可以播放

**WeaponController 責任邊界清晰**：
- 父類：提供共用工具 (`_get_attack_profile()`, `_play_audio_stream()`)
- 子類：實作具體攻擊邏輯 (SwordWeapon 管理 Hitbox, StaffWeapon 生成 SpellActor)

---

## 驗收結果

- [x] **通過** - 可進入下一任務
- [ ] 有條件通過 - 小修正後即可通過
- [ ] 需要重做 - 需重新實作

### 下一步行動

進入任務 #003: **非投射物法術支援 (Non-Projectile Spell Actors)**

根據 `03_Implementation_Order.md` 的 Next Tasks：
- [x] Add a debug-visible way to equip and swap between sword and staff in `Arena_Test`
- [x] Define weapon attack presentation ownership
- [ ] **Define how non-projectile spell actors plug into the same `StaffWeapon -> SpellActor` chain**

---

## 相關連結

- Codex Prompt: `codex_prompt.md` (將更新為任務 #003)
- 修改檔案: 14 個 (見 codex_prompt.md 實作摘要)
- Retrospective: `review_001_retrospective.md`
