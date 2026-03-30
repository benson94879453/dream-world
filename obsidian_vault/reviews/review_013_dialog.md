# Code Review #013 - NPC 對話系統

## 任務資訊

- **任務名稱**: NPC 對話系統基礎
- **Codex 完成時間**: 2026-03-28
- **Kimi 驗收時間**: 2026-03-28

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| DialogData 資源定義 | ✅ 通過 | 對話樹結構 |
| DialogNodeData / DialogChoiceData | ✅ 通過 | 節點與選項資料 |
| DialogManager Autoload | ✅ 通過 | 控制對話流程 |
| 逐字顯示 | ✅ 通過 | 50 字/秒，可配置 |
| 選項分支 | ✅ 通過 | 選擇後跳轉正確節點 |
| NPCDialogTrigger 觸發 | ✅ 通過 | 區域檢測 + F 鍵互動 |
| 互動優先級處理 | ✅ 通過 | NPC 範圍內優先攔截 F 鍵 |
| 對話 flags 保存 | ✅ 通過 | SaveManager 整合 |
| 讀檔還原 | ✅ 通過 | flags 正確還原 |
| Headless smoke 通過 | ✅ 通過 | version=2, saved=true, restored=true |

### ✅ 架構驗收

| 項目 | 狀態 | 備註 |
|------|------|------|
| Resource 資料模型 | ✅ | .tres 儲存對話 |
| Autoload singleton | ✅ | DialogManager |
| Signals 通訊 | ✅ | 解耦 UI 與邏輯 |
| Save schema v2 | ✅ | 向後相容 |
| Coding Habits | ✅ | region、assert、後綴 `_` |

---

## 詳細回饋

### 優點 👍

1. **完整的對話系統**:
   ```
   DialogData (Resource)
   ├── DialogNodeData (TEXT/CHOICE/END)
   └── DialogChoiceData (選項 + flags)
   ```

2. **互動優先級設計**:
   ```gdscript
   # NPC 觸發器在範圍內優先攔截 F 鍵
   # 避免對話和攻擊同時觸發
   ```

3. **Save 整合**:
   ```gdscript
   # Save schema v2
   {
     "save_version": 2,
     "dialog": {
       "dialog_flags": { "knows_upgrade": true }
     }
   }
   ```

4. **逐字顯示效果**:
   ```gdscript
   # 文字逐字出現，支援跳過
   text_timer += delta * text_speed
   char_index = int(text_timer)
   ```

### 設計決策記錄 📝

**Interact 鍵與 Attack 鍵共用 F**:
```gdscript
# NPCDialogTrigger 在範圍內優先攔截
func _process(_delta: float) -> void:
    if player_in_range and Input.is_action_just_pressed(interaction_key):
        _start_dialog()  # 優先處理對話
```

**對話狀態保存**:
```gdscript
# 只保存 flags，不保存進行中對話
func to_save_dict() -> Dictionary:
    return { "dialog_flags": dialog_flags }
```

---

## 驗收結果

- [x] **通過** - NPC 對話系統完成！

---

## 🎉 Phase 5A 完成！

### 完整可玩循環進度

```
對話 → 戰鬥 → 掉落 → 撿取 → 裝備 → 強化 → 存檔
  ✅      ✅      ✅      ✅      ✅      ⬜      ✅
```

| 階段 | 狀態 |
|------|------|
| 對話 | ✅ 完成 |
| 戰鬥 | ✅ 完成 |
| 掉落 | ✅ 完成 |
| 撿取 | ✅ 完成 |
| 裝備 | ✅ 完成 |
| 強化 | ⬜ 下一個目標 |
| 存檔 | ✅ 完成 |

### 下一個目標

**Phase 5B: 武器強化系統**
- Upgrade Definition Resource
- UpgradeManager
- Upgrade UI
- Save 整合

---

## 相關連結

- Prompt: `obsidian_vault/task_prompt.md`
- 同步摘要: `obsidian_vault/sync_summary.md`
- 企劃文件: `obsidian_vault/planning/project_goals.md`
- 任務清單: `obsidian_vault/planning/mvp_todo.md`
