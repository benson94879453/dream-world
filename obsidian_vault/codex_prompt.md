# Codex Task Prompt — 待決策

## 狀態

**Hub-based Vertical Slice 已完成！**

Batch 1 → Batch 2 → Batch 3 全部驗收通過。

---

## 已完成內容總覽

### Batch 1: 場景基礎與切換 ✅
- SceneTransitionManager（Autoload）
- Portal 傳送門系統
- TownHub.tscn（城鎮）
- Dungeon01.tscn（地城）

### Batch 2: 狀態持久化 ✅
- SceneStateManager（場景狀態管理）
- ZoneResetManager（區域重置策略）
- PersistentObject（持久化組件）
- Boss 死亡狀態保存

### Batch 3: Checkpoint & NPC ✅
- Checkpoint（營火系統）
- 玩家死亡重生機制
- InstructorNPC（教官）
- quest_clear_dungeon01（地城清除任務）

---

## 完整遊玩閉環

```
Town Hub → Portal → Dungeon 01 → Checkpoint → Boss → 返回 Hub → 教官對話/任務回報
```

---

## 下一階段選項（等待決策）

| 選項 | 內容 | 預估工作量 |
|-----|------|-----------|
| **A. Playtest + 修復** | 實機測試、收集反饋、問題修復 | 持續 |
| **B. Boss Event Chain** | Boss死亡表演、掉落道具、動態傳送門 | 1 天 |
| **C. 存檔 v8** | 保存當前場景+重生點，支援跨重啟恢復 | 1 天 |
| **D. Dungeon 02** | 新地城設計、新敵人配置 | 2-3 天 |

---

## 已知限制（待後續處理）

1. **Checkpoint 重生點跨重啟**：目前存檔不保存「當前場景+最後重生點」，重開遊戲後會回到 TownHub
2. **Boss Event Chain**：Boss 死亡後無特殊表演、無掉落、離開傳送門始終開啟
3. **端到端自動化測試**：尚未建立場景切換 + Boss擊殺 + 讀檔 的完整自動化測試

---

*等待 Kimi 決策下一階段任務*
