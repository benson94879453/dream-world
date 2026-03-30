# Code Review #003 - 非投射物法術支援

## 任務資訊

- **任務名稱**: 非投射物法術支援 (Non-Projectile Spell Actors)
- **Codex 完成時間**: 2026-03-27
- **Kimi 驗收時間**: 2026-03-27

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| SpellActor 有 SpellType 列舉 | ✅ 通過 | PROJECTILE/INSTANT/CONTINUOUS |
| HealSpellActor 存在且能治療 | ✅ 通過 | 自我治療實作 |
| ExplosionSpellActor 存在且能範圍傷害 | ✅ 通過 | Area2D 偵測 |
| StaffWeapon 根據 SpellType 處理 | ✅ 通過 | 分流邏輯實作 |
| 兩個新武器資料存在且可切換 | ✅ 通過 | test_heal_staff / test_explosion_staff |
| 按 4/5 可切換到新法杖 | ✅ 通過 | debug_equip_4/5 |
| 治療不造成傷害，爆炸造成範圍傷害 | ✅ 通過 | 功能分離正確 |
| Console 有 Debug log | ✅ 通過 | spell type log |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| Heal/Explosion 繼承 SpellActor | ✅ 通過 | 正確繼承 |
| 使用 AttackContext 傳遞傷害 | ✅ 通過 | ExplosionSpellActor |
| Area2D + get_overlapping_bodies() | ✅ 通過 | 爆炸範圍偵測 |
| 正確清理避免記憶體洩漏 | ✅ 通過 | queue_free() 處理 |
| 新增 spells/ 子目錄 | ✅ 通過 | 良好的組織 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | snake_case |
| 程式碼結構清晰 | ✅ 通過 | 基類擴充良好 |

---

## 詳細回饋

### 優點 👍

1. **SpellType 架構** - 三種類型（投射物/立即/持續）為未來擴充打下基礎

2. **生命週期管理** - `lifetime_seconds` 和 `affect_*` 旗標設計完整

3. **物理幀延遲處理** - ExplosionSpellActor 延遲到下一 physics frame 套用傷害，確保 Area2D 重疊資訊正確

4. **目錄組織** - 新增 `spells/` 子目錄存放特定法術，維護性佳

5. **快速切換 Profile** - 新增 `profile_staff_quick.tres` 供治療法杖使用

### 問題/建議 🔧

**無重大問題**

小建議：
- 音效資源尚未配置，預留節點已準備好，後續只需掛上 AudioStream

### 架構觀察 🏗️

**SpellActor 現在是完整的多型基類**：
- PROJECTILE: BoltSpellActor (移動+碰撞)
- INSTANT: HealSpellActor (立即效果), ExplosionSpellActor (範圍傷害)
- CONTINUOUS: 預留給未來護盾/光環類法術

**StaffWeapon 統一處理所有類型**，不需知道具體法術實作細節。

---

## 驗收結果

- [x] **通過** - 可進入下一任務
- [ ] 有條件通過
- [ ] 需要重做

### 下一步行動

進入 **Phase 3** 或決定 Player Attack State。

根據 `planning/implementation_order.md`，Next Tasks 剩下：
- [ ] Decide when attack timing pressure is high enough to promote attack into a dedicated player state

---

## 相關連結

- Task Prompt: `task_prompt.md`
- 修改檔案: 12 個 (見 task_prompt.md 實作摘要)
