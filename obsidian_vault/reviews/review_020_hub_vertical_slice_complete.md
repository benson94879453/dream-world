# Review 020: Hub-based Vertical Slice 完成

> 日期: 2026-03-29
> 類型: 階段完成記錄

---

## 概述

Hub-based Vertical Slice 三個批次全部完成，建立了第一個可運作的端到端遊玩閉環。

---

## 完成內容

### Batch 1: 場景基礎與切換

| 項目 | 狀態 | 備註 |
|------|:----:|------|
| SceneTransitionManager | ✅ | 淡入淡出、玩家狀態暫存/還原、重生點管理 |
| Portal | ✅ | F鍵互動、防止重複觸發、對話/模態UI防衝突 |
| TownHub | ✅ | 城鎮安全區、鐵匠NPC、傳送門 |
| Dungeon01 | ✅ | 地城場景、敵人配置 |

**技術亮點**：
- Godot 4.6 `class_name` + Autoload 同名問題處理（不加 class_name）
- `_cache_player_runtime_state()` / `_restore_player_runtime_state()` 確保切場景不遺失裝備

---

### Batch 2: 狀態持久化

| 項目 | 狀態 | 備註 |
|------|:----:|------|
| SceneStateManager | ✅ | State ID 格式、場景桶分離、存檔整合 |
| ZoneResetManager | ✅ | ResetStrategy enum、ON_REENTER/NEVER 策略 |
| PersistentObject | ✅ | 自動ID生成、HealthComponent死亡監聽、停用邏輯 |
| SaveManager 整合 | ✅ | scene_state、zone_reset 存檔/讀檔 |

**技術亮點**：
- `_extract_scene_path_from_state_id`：處理 scene path 包含冒號的 edge case
- `_disable_subtree`：完整的節點停用邏輯（physics、collision、visibility）
- Boss 固定 `state_id = "dungeon01_boss_boar"` 供 Hub 端查詢

---

### Batch 3: Checkpoint & NPC

| 項目 | 狀態 | 備註 |
|------|:----:|------|
| Checkpoint | ✅ | 自動/F鍵觸發、回血、設重生點、存檔、視覺反饋 |
| 玩家重生 | ✅ | `_on_health_depleted` → `_respawn_at_checkpoint`、HP回滿 |
| InstructorNPC | ✅ | 依 Boss 狀態切換對話 |
| QuestBoard | ✅ | 提供 `quest_clear_dungeon01` 任務 |
| 對話資源 | ✅ | `dlg_instructor_default` + `dlg_instructor_post_boss` |

**技術亮點**：
- Checkpoint 啟用狀態寫入 SceneStateManager，重進場景保留視覺狀態
- 任務完成沿用既有 `EnemyAIController.die() -> QuestManager.report_enemy_killed()`，避免重複計數
- `Spawn_checkpoint_*` markers 與 Checkpoint ID 對應

---

## 驗收標準檢查

### 功能驗收
- [x] TownHub 主場景可正常載入
- [x] 玩家可從 TownHub 傳送到 Dungeon01
- [x] 切換場景有淡入淡出效果
- [x] 玩家狀態（裝備/背包）跨場景保留
- [x] Boss 死亡後不再重生
- [x] 普通敵人重新進入 Dungeon 會重置
- [x] Checkpoint 可觸發、回血、設重生點
- [x] 玩家死亡後在 Checkpoint 重生
- [x] 教官 NPC 根據 Boss 狀態顯示不同對話
- [x] 任務板提供地城清除任務
- [x] 擊敗 Boss 自動完成任務

### 架構驗收
- [x] 所有 Manager 均為 Autoload singleton
- [x] 正確使用現有 API，無重複造輪子
- [x] 與 SaveManager、QuestManager 正確整合
- [x] Godot headless --import 和 --quit-after 60 通過

### 風格驗收
- [x] 命名符合專案慣例（snake_case）
- [x] 適當的註解與邊界檢查
- [x] 輸出訊息使用統一前綴

---

## 遊玩閉環驗證

```
[Town Hub]
    ├─ 與任務板接取「清除地城威脅」
    ├─ 與教官對話（預設對話）
    └─ 進入傳送門 ───┐
                     ▼
[Dungeon 01] ◄──── Checkpoint 入口（回血、設重生點）
    ├─ 戰鬥區域（Slime/Archer/Boar）
    ├─ Checkpoint Boss前
    └─ Boss戰（Boar）──┐
                       ▼
           擊敗後自動完成任務、保存Boss狀態
                       │
    ┌──────────────────┘
    ▼
[返回 Town Hub]
    ├─ 與任務板回報任務
    └─ 與教官對話（擊敗Boss後對話）
```

✅ **完整閉環已達成**

---

## 已知限制

1. **Checkpoint 重生點跨重啟**：目前存檔不保存「當前場景+最後重生點」，重開遊戲後會回到 TownHub
2. **Boss Event Chain**：Boss 死亡後無特殊表演、無掉落、離開傳送門始終開啟
3. **端到端自動化測試**：尚未建立場景切換 + Boss擊殺 + 讀檔 的完整自動化測試

---

## 下一階段建議

| 優先級 | 選項 | 說明 |
|:------:|------|------|
| P1 | Playtest + 修復 | 實機測試、收集反饋、問題修復 |
| P2 | 存檔 v8 | 保存當前場景+重生點，支援跨重啟恢復 |
| P3 | Boss Event Chain | Boss死亡表演、掉落道具、動態傳送門 |
| P4 | Dungeon 02 | 新地城設計、新敵人配置 |

---

## 文件更新

- [x] `obsidian_vault/sync_summary.md` - 更新 Hub-based Vertical Slice 完成狀態
- [x] `obsidian_vault/planning/mvp_todo.md` - 標記 Checkpoint/NPC 完成
- [x] `obsidian_vault/task_prompt.md` - 重置為待決策狀態
- [x] `obsidian_vault/reviews/review_020_hub_vertical_slice_complete.md` - 本文件

---

*驗收完成 - 2026-03-29*
