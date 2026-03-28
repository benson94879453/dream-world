# Code Review #010 - 遠程敵人 AI

## 任務資訊

- **任務名稱**: 遠程敵人 AI - Goblin Archer
- **Codex 完成時間**: 2026-03-28
- **Kimi 驗收時間**: 2026-03-28

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| `EnemyProjectile` 存在 | ✅ 通過 | 可以飛行並對玩家造成傷害 |
| `EnemyKeepDistanceState` 存在 | ✅ 通過 | 保持 preferred_distance 範圍 |
| Archer 保持距離（不追擊） | ✅ 通過 | 100-180 距離控制 |
| Archer 發射投射物 | ✅ 通過 | perform_ranged_attack() |
| 投射物命中玩家造成傷害 | ✅ 通過 | damage=8.0 |
| 投射物超時消失 | ✅ 通過 | lifetime=3.0 |
| 玩家可以走位躲避 | ✅ 通過 | 投射物有飛行軌跡 |
| Archer 死亡掉落 | ✅ 通過 | 使用現有 DropComponent |
| F7 生成 Archer | ✅ 通過 | ArenaTest 整合 |
| DebugOverlay 顯示資訊 | ✅ 通過 | State/HP/Distance/Visibility |

### ✅ 架構驗收

| 項目 | 狀態 | 備註 |
|------|------|------|
| 沿用 EnemyAIController | ✅ | AttackType enum 擴充 |
| 使用 AttackContext | ✅ | 投射物傷害傳遞 |
| Coding Habits 遵守 | ✅ | assert、後綴 `_`、region |
| Debug 工具 | ✅ | F6 Slime / F7 Archer |

---

## 詳細回饋

### 優點 👍

1. **兩種敵人類型對比鮮明**:
   | 特性 | Slime | Archer |
   |------|-------|--------|
   | 攻擊 | 近戰碰撞 | 遠程投射物 |
   | 移動 | Chase | KeepDistance |
   | HP | 60 | 40 |
   | 速度 | 快 | 慢 |

2. **KeepDistance AI 邏輯**:
   ```gdscript
   if distance < preferred_distance_min:
       # 後退
   elif distance > preferred_distance_max:
       # 接近
   else:
       # 橫向移動（繞著玩家走）
   ```

3. **投射物系統**:
   - 使用 Area2D 檢測碰撞
   - 使用 AttackContext 傳遞傷害
   - 有生命週期防止無限飛行

4. **Debug 支援**:
   - F6: 生成 Slime
   - F7: 生成 Archer
   - Overlay 區分顯示兩種敵人

### 設計決策記錄 📝

**AttackType 分離**:
```gdscript
enum AttackType { MELEE, RANGED }
# Slime: MELEE, use Hitbox
# Archer: RANGED, use Projectile
```

**投射物生成位置**:
```gdscript
# 根據面向調整 spawn offset
spawn_offset_.x *= -1.0 if facing_left else 1.0
```

---

## 驗收結果

- [x] **通過** - 遠程敵人 AI 系統完成！

---

## 🎉 Phase 4 第二個任務完成！

### 敵人 AI 系統現況

| 敵人 | 類型 | 狀態 |
|------|------|------|
| Slime | 近戰追擊 | ✅ 完成 |
| Goblin Archer | 遠程保持距離 | ✅ 完成 |

### 玩家現在需要學會

1. **對付 Slime**: 保持距離，用遠程武器或攻擊後閃避
2. **對付 Archer**: 
   - 靠近逼迫它移動
   - 走位躲避箭矢
   - 利用地形阻擋投射物

### 下一個敵人類型建議

- **快速突進型**: 短暫蓄力後快速衝向玩家
- **群體型**: 多個 Slime 一起行動，有簡單的群體行為

---

## 相關連結

- Prompt: `obsidian_vault/codex_prompt.md`
- 同步摘要: `obsidian_vault/SYNC_SUMMARY.md`
