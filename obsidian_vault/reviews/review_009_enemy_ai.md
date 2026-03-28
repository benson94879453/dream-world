# Code Review #009 - 敵人 AI 系統

## 任務資訊

- **任務名稱**: 敵人 AI 系統 - Slime 基礎敵人
- **Codex 完成時間**: 2026-03-28
- **Kimi 驗收時間**: 2026-03-28

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| `EnemyData` 和 `EnemyInstance` 存在 | ✅ 通過 | 與 Weapon 模式一致 |
| `EnemyAIController` 有完整狀態機 | ✅ 通過 | Idle/Chase/Attack/Dead |
| Slime Idle 原地待機 | ✅ 通過 | 播放 idle 動畫 |
| 玩家進入偵測範圍，Slime 切換 Chase | ✅ 通過 | 使用 DetectionArea + RayCast |
| 玩家進入攻擊範圍，Slime 攻擊 | ✅ 通過 | 停止移動，啟用 Hitbox |
| Slime 攻擊造成玩家傷害 | ✅ 通過 | base_damage=12.0 |
| Slime HP 歸零進入 Dead 狀態 | ✅ 通過 | 觸發掉落，停用碰撞 |
| 死亡後不再移動或攻擊 | ✅ 通過 | has_died 標記保護 |
| DebugOverlay 顯示 Slime 資訊 | ✅ 通過 | State/HP/Distance |
| F6 生成測試 Slime | ✅ 通過 | `_spawn_enemy()` |

### ✅ 架構驗收

| 項目 | 狀態 | 備註 |
|------|------|------|
| 沿用 StateMachine 模式 | ✅ | 與 Player 一致 |
| 沿用 DamagePipeline | ✅ | Hitbox → Hurtbox → ... |
| 使用 AttackContext | ✅ | 敵人攻擊也使用相同系統 |
| Coding Habits 遵守 | ✅ | assert、後綴 `_`、型別標註 |

---

## 詳細回饋

### 優點 👍

1. **資料與邏輯分離** - `EnemyData` (Resource) + `EnemyInstance` (Runtime)，與武器系統一致

2. **狀態機設計完整**:
   - Idle: 待機，檢測玩家
   - Chase: 追蹤，距離檢查
   - Attack: 攻擊，冷卻計時
   - Dead: 死亡，觸發掉落

3. **視線偵測系統**:
   ```gdscript
   # DetectionArea 檢測範圍 + RayCast2D 視線遮擋
   can_see_player() -> bool
   ```

4. **動畫系統** - 支援 4 種動畫狀態，frame-based 播放

5. **Debug 支援**:
   - F6 生成測試敵人
   - Overlay 顯示狀態、HP、距離

### 設計決策記錄 📝

**Hitbox 位置動態調整**:
```gdscript
# 根據面向調整 hitbox 位置
hitbox_position_.x = -absf(hitbox_forward_offset) if facing_left else absf(hitbox_forward_offset)
```

**敵人攻擊冷卻**:
```gdscript
# AttackState 內計時，冷卻結束後檢查狀態轉換
attack_timer += delta_
if attack_timer >= enemy_.attack_cooldown:
    # 檢查繼續追擊或回到 Idle
```

---

## 驗收結果

- [x] **通過** - 敵人 AI 系統完成！

---

## 🎉 Phase 4 第一個任務完成！

### 新增系統

| 系統 | 檔案 |
|------|------|
| 敵人資料 | `EnemyData.gd`, `EnemyInstance.gd` |
| 敵人狀態機 | `EnemyStateMachine.gd`, `EnemyState.gd` |
| 敵人狀態 | `EnemyIdleState`, `EnemyChaseState`, `EnemyAttackState`, `EnemyDeadState` |
| 敵人控制器 | `EnemyAIController.gd` |
| 敵人場景 | `Enemy_Slime.tscn` |
| 敵人資料 | `en_slime_basic.tres` |

### 狀態流程

```
┌─────────┐    偵測到玩家    ┌─────────┐    進入攻擊範圍    ┌─────────┐
│  Idle   │ ───────────────► │  Chase  │ ───────────────► │ Attack  │
│  (待機)  │                  │ (追蹤)  │                  │ (攻擊)  │
└─────────┘◄─────────────────└─────────┘◄─────────────────┘    │
     ▲                      失去目標                      冷卻結束│
     │                                                           │
     │                              ┌─────────┐                  │
     └─────────────────────────────│  Dead   │◄─────────────────┘
                                   │ (死亡)  │     HP=0
                                   └─────────┘
```

---

## 相關連結

- Prompt: `obsidian_vault/codex_prompt.md`
- 同步摘要: `obsidian_vault/SYNC_SUMMARY.md`
