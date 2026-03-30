# 文件同步摘要

> 最後更新: 2026-03-30

> 入口請先看 `README.md`

---

## 目前完成狀態

### 已完成系統總覽

| 系統 | 狀態 | 說明 |
|------|:----:|------|
| 戰鬥系統 | ✅ | 8方向、Combo、Dash + Hit Stop |
| 武器系統 | ✅ | 劍/法杖、星級、詞綴、符文槽 |
| 符文效果 | ✅ | 4個核心符文機制 |
| 裝備系統 | ✅ | Weapon + Gear 5槽，唯一實例 |
| 背包系統 | ✅ | 三型態 v2 + Hotbar |
| 敵人 AI | ✅ | Slime / Archer / Boar |
| NPC 對話 | ✅ | DialogManager + flags |
| 任務系統（後端） | ✅ | QuestManager 全功能，4筆資料 |
| 任務系統（前端） | ❌ | **HUD / 日誌 / 通知 全部缺失** |
| 場景系統 | ✅ | TownHub ↔ Dungeon01 |
| Checkpoint | ✅ | 營火 + 重生點 |
| 存檔系統 | ✅ | Save v7 + checksum + migration |
| Hotbar 存檔 | ❌ | 綁定不進存檔（待 Save v8） |
| 跨重啟重生點 | ❌ | 重開遊戲回 TownHub（待 Save v8） |
| 消耗品效果 | ⚠️ | 硬編碼 heal 25，待資料驅動 |

---

## 完整遊玩閉環

```
[Town Hub]
    ├─ 接任務（鐵匠 × 3 / 任務板 × 1）
    ├─ 教官對話（預設）
    └─ 進入傳送門
             ▼
[Dungeon 01]
    ├─ Checkpoint 入口（回血/存檔/重生點）
    ├─ 戰鬥（Slime / Archer / Boar）
    ├─ Checkpoint Boss 前
    └─ Boss（野豬王）擊敗 → 任務自動完成
             ▼
[返回 Town Hub]
    ├─ 任務板/鐵匠回報 → 領獎勵
    └─ 教官對話（擊敗 Boss 後版本）
```

---

## 後續排程摘要

| 優先 | Phase | 內容 | 狀態 |
|:----:|-------|------|:----:|
| P1 | 9A-1 | 任務追蹤 HUD（螢幕右側） | ⬜ |
| P1 | 9A-2 | 任務通知 Toast | ⬜ |
| P1 | 9A-3 | 任務日誌介面（J 鍵） | ⬜ |
| P1 | 9B-1 | Hotbar 綁定進存檔 | ⬜ |
| P1 | 9B-2 | Checkpoint 重生點跨重啟 | ⬜ |
| P1 | 9B-3 | 消耗品系統資料驅動 | ⬜ |
| P1 | 9D   | Save v8 整合 | ⬜ |
| P2 | 9C-1 | Boss 死亡掉落 | ⬜ |
| P2 | 9C-2 | Boss 死亡演出 | ⬜ |
| P2 | 9C-3 | Boss 後傳送門高亮 | ⬜ |
| P2 | 10A  | Dungeon 02 + 新敵人 | ⬜ |
| P3 | 10B  | 群體 AI | ⬜ |
| P3 | 10C  | 多階段 Boss | ⬜ |

詳細任務規格見 `planning/mvp_todo.md`

---

## 存檔版本歷程

| 版本 | 新增內容 | 狀態 |
|------|---------|:----:|
| v1 | 基礎存檔 | ✅ |
| v2 | Dialog flags | ✅ |
| v3 | 武器星級/詞綴 | ✅ |
| v4 | 符文槽 | ✅ |
| v5 | 金幣 | ✅ |
| v6 | Equipment + checksum | ✅ |
| v7 | Quest + SceneState + ZoneReset | ✅ |
| v8 | Hotbar 綁定 + Respawn 場景 | ⬜ Phase 9D |

---

## 📁 主要文件

| 檔案 | 更新日期 | 狀態 |
|------|---------|:----:|
| README.md | 2026-03-30 | ✅ 入口 |
| workflow_template.md | 2026-03-30 | ✅ 三角色流程 |
| task_prompt.md | 2026-03-30 | ✅ 當前任務 |
| task_backlog.md | 2026-03-30 | ✅ 任務池 |
| code_review_template.md | 2026-03-30 | ✅ 驗收模板 |
| specs/input_keymap.md | 2026-03-30 | ✅ 操作總表 |
| planning/project_goals.md | 2026-03-29 | ✅ |
| planning/mvp_todo.md | 2026-03-30 | ✅ 最新 |
| planning/tech_spec_notes.md | 2026-03-29 | ✅ |
| planning/implementation_order.md | 2026-03-29 | ✅ |
| planning/coding_habits.md | 2026-03-27 | ✅ |

---

歷史文件已歸檔至 `archive/`，詳見 `README.md`。

*文件已同步 - 2026-03-30*
