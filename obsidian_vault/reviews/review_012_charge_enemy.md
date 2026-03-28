# Code Review #012 - 突進型敵人 Boar

## 任務資訊

- **任務名稱**: 突進型敵人 - Boar（野豬）
- **Codex 完成時間**: 2026-03-28
- **Kimi 驗收時間**: 2026-03-28

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| `EnemyChargeState` 存在 | ✅ 通過 | 蓄力 0.8s，視覺閃爍 |
| `EnemyDashState` 存在 | ✅ 通過 | 突進 0.3s，速度 400 |
| 蓄力預警 | ✅ 通過 | sprite modulate 閃爍 |
| 突進傷害 | ✅ 通過 | DashHitbox 啟用 |
| 突進冷卻 | ✅ 通過 | 2.0s 冷卻時間 |
| Dash 無敵可躲避 | ✅ 通過 | 玩家 Dash 無敵幀 |
| 走位可躲避 | ✅ 通過 | 側向移動避開直線 |
| Boar 死亡掉落 | ✅ 通過 | DropComponent |
| F8 生成 Boar | ✅ 通過 | ArenaTest 整合 |
| DebugOverlay 顯示 | ✅ 通過 | State/HP/DashCooldown |

### ✅ 架構驗收

| 項目 | 狀態 | 備註 |
|------|------|------|
| StateMachine 模式 | ✅ | Charge/Dash 狀態 |
| 獨立 DashHitbox | ✅ | 與普通攻擊分開 |
| 視覺預警 | ✅ | play_charge_animation() |
| Coding Habits | ✅ | region、後綴 `_` |

---

## 詳細回饋

### 優點 👍

1. **三段式攻擊節奏**:
   ```
   Charge (0.8s) → Dash (0.3s) → Cooldown (2.0s)
   預警期         危險期         破綻期
   ```

2. **明顯的視覺預警**:
   ```gdscript
   # 蓄力時顏色閃爍
   sprite.modulate = Color(1.5, 1.0, 1.0) if flash else Color.WHITE
   ```

3. **獨立傷害判定**:
   ```gdscript
   # DashHitbox 與普通 Hitbox 分開
   dash_hitbox.activate()   # 突進時啟用
   dash_hitbox.deactivate() # 結束時關閉
   ```

4. **Debug 資訊完整**:
   - Boar State
   - Boar HP
   - Boar Dash Cooldown

### 設計決策記錄 📝

**蓄力方向鎖定**:
```gdscript
# 進入 Charge 時記錄方向，突進時不改變
charge_direction = (player_position - enemy_position).normalized()
```

**Idle 狀態判斷**:
```gdscript
# 檢查是否應該開始蓄力
if enemy_.should_start_charge(distance_to_player_):
    transition_to(&"Charge")
```

---

## 驗收結果

- [x] **通過** - 突進型敵人 Boar 完成！

---

## 🎉 三種敵人類型完成！

### 敵人 AI 系統現況

| 敵人 | 類型 | 核心機制 | 反制方法 |
|------|------|----------|----------|
| Slime | 近戰追擊 | 靠近碰撞 | 拉開距離 |
| Archer | 遠程保持 | 保持距離射箭 | 靠近逼迫 |
| Boar | 突進爆發 | 蓄力→突進 | Dash 無敵 |

### 戰鬥深度

1. **基礎**: Walk/Run 移動，攻擊造成傷害
2. **進階**: 
   - Dash Cancel 取消後搖
   - Dash 無敵躲避突進
   - 走位躲避 Archer 箭矢
3. **專家**:
   - 觀察 Boar 蓄力預警
   - 抓準突進冷卻輸出
   - 同時應對多種敵人

---

## 相關連結

- Prompt: `obsidian_vault/codex_prompt.md`
- 同步摘要: `obsidian_vault/SYNC_SUMMARY.md`
