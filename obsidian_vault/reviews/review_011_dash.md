# Code Review #011 - Dash 位移實作

## 任務資訊

- **任務名稱**: Dash 位移實作
- **Codex 完成時間**: 2026-03-28
- **Kimi 驗收時間**: 2026-03-28

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| Dash 位移 | ✅ 通過 | 距離 120px，持續 0.15s |
| Dash 方向 | ✅ 通過 | 優先輸入方向，否則面向 |
| Dash 期間無敵 | ✅ 通過 | 關閉 Hurtbox monitoring |
| Dash 期間鎖定控制 | ✅ 通過 | 無法改變方向或攻擊 |
| Dash Cancel | ✅ 通過 | Attack → Dash 取消攻擊 |
| Dash 冷卻 | ✅ 通過 | 0.8s 冷卻時間 |
| 殘影效果 | ✅ 通過 | 最多 3 個，淡出動畫 |
| DebugOverlay 顯示 | ✅ 通過 | READY/ACTIVE/冷卻時間 |
| 所有狀態整合 Dash | ✅ 通過 | Idle/Walk/Run/Attack |
| 參數可配置 | ✅ 通過 | @export 參數 |

### ✅ 架構驗收

| 項目 | 狀態 | 備註 |
|------|------|------|
| StateMachine 模式 | ✅ | PlayerDashState 繼承 PlayerState |
| 無敵機制 | ✅ | set_invincible() 控制 Hurtbox |
| 殘影實作 | ✅ | _create_ghost() + Tween |
| Coding Habits | ✅ | region、assert、後綴 `_` |

---

## 詳細回饋

### 優點 👍

1. **完整的 Dash 系統**:
   - 位移：velocity = direction * (distance/duration)
   - 無敵：hurtbox.monitoring = false
   - 殘影：Sprite2D + Tween 淡出
   - 冷卻：cooldown_timer 計時

2. **Dash Cancel**:
   ```gdscript
   # AttackState 中
   if player_.can_perform_dash() and Input.is_action_just_pressed("dash"):
       player_.weapon_controller.cancel_attack()
       transition_to(&"Dash")
   ```

3. **殘影效果**:
   ```gdscript
   ghost_.modulate = Color(1.0, 1.0, 1.0, 0.45)  # 半透明
   tween_.tween_property(ghost_, "modulate:a", 0.0, 0.2)  # 淡出
   ```

4. **Debug 資訊**:
   - READY: 可以使用
   - ACTIVE: Dash 進行中
   - 0.7s: 冷卻剩餘時間

### 設計決策記錄 📝

**Dash 方向決定**:
```gdscript
# 優先輸入方向，無輸入時使用面向
if input_direction_ != Vector2.ZERO:
    dash_direction = input_direction_.normalized()
else:
    dash_direction = Vector2.LEFT if facing_left else Vector2.RIGHT
```

**無敵實作**:
```gdscript
# 關閉 Hurtbox 的 monitoring 和 monitorable
hurtbox.monitoring = false if invincible_ else default
hurtbox.monitorable = false if invincible_ else default
```

---

## 驗收結果

- [x] **通過** - Dash 位移實作完成！

---

## 🎉 戰鬥核心機制完成！

### 現在的戰鬥循環

```
攻擊 → Dash Cancel → 躲避敵人攻擊 → 反擊
   ↑                              ↓
   └──────────────────────────────┘
```

### 玩家技巧

1. **基礎**:
   - Walk/Run 移動
   - 攻擊造成傷害
   - Space Dash 躲避

2. **進階**:
   - Dash Cancel 取消攻擊後搖
   - 無敵幀穿過敵人攻擊
   - 走位躲避 Archer 箭矢

### Dash 參數（可調整）

| 參數 | 值 | 說明 |
|------|-----|------|
| dash_distance | 120.0 | 衝刺距離（像素） |
| dash_duration | 0.15 | 持續時間（秒） |
| dash_cooldown | 0.8 | 冷卻時間（秒） |
| dash_invincible | true | 是否無敵 |
| dash_ghost_count | 3 | 殘影數量 |
| dash_ghost_interval | 0.05 | 殘影間隔 |

---

## 相關連結

- Prompt: `obsidian_vault/codex_prompt.md`
- 同步摘要: `obsidian_vault/SYNC_SUMMARY.md`
