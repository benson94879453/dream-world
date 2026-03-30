# Review #019: Minecraft 風格背包 UI

## 驗收結果: ✅ 通過

**日期**: 2026-03-28  
**實作者**: 已完成並回填 task_prompt.md

---

## 功能驗收

| 檢查項 | 狀態 | 實作位置 |
|--------|:----:|---------|
| 20格背包方格 | ✅ | InventoryUI.gd |
| 分類標籤過濾 | ✅ | 全部/素材/消耗品/武器/符文/鑰匙 |
| Tooltip 提示 | ✅ | 0.5秒延遲顯示 |
| 拖曳換位 | ✅ | Godot D&D 實現 |
| Hotbar 綁定 | ✅ | 背包拖到快捷欄 |
| 1-5 快捷使用 | ✅ | HotbarManager.gd |
| 武器快速裝備 | ✅ | 按數字鍵裝備武器 |
| 消耗品治療 | ✅ | 通用 heal 25 HP |
| E/I 開關背包 | ✅ | Player.gd |
| Debug 顯示 | ✅ | DebugOverlay.gd |
| Console 無新錯誤 | ✅ | headless 通過 |

---

## 已知限制

| 項目 | 說明 | 建議後續處理 |
|------|------|------------|
| Hotbar 未存檔 | 綁定狀態重開遊戲會重置 | Save v6 加入 hotbar_slots |
| 消耗品通用治療 | 目前固定 heal 25 HP | 擴充 ConsumableData 定義效果 |
| UID Warning | 既存問題，非本次引入 | 獨立任務修復 Player.tscn |

---

## 修改檔案清單

```
[NEW] game/scenes/ui/InventoryUI.tscn
[NEW] game/scenes/ui/ItemSlotUI.tscn
[NEW] game/scripts/ui/InventoryUI.gd
[NEW] game/scripts/ui/ItemSlotUI.gd
[NEW] game/scripts/core/HotbarManager.gd

game/scripts/inventory/Inventory.gd       # 新增 get_slot/swap_slots
game/scripts/Player.gd                    # E/I 開關背包，1-5 快捷欄
game/scripts/ui/DebugOverlay.gd           # 顯示 hotbar 綁定
game/scenes/DebugOverlay.tscn
game/scenes/Arena_Test.tscn               # 掛載 InventoryUI
project.godot                             # HotbarRuntime autoload, input actions
obsidian_vault/task_prompt.md
```

---

## 設計決策確認

### ✅ Hotbar 簡化實現
- 消耗品效果：通用 heal 25 HP
- 可後續擴充 `ConsumableData` 定義不同效果（回復 MP、Buff 等）

### ✅ 存檔取捨
- Hotbar 綁定尚未進存檔
- 建議 Save v6 加入 `hotbar_slots` 欄位

---

## 完整背包系統達成 🎉

**功能清單**：
- ✅ 視覺化方格背包（20格）
- ✅ 分類瀏覽（6種類型）
- ✅ 拖曳整理
- ✅ 物品詳情提示
- ✅ 快捷欄綁定（5格）
- ✅ 數字鍵快速使用

**操作方式**：
- `E` / `I`：開關背包
- 拖曳：整理物品 / 綁定快捷欄
- 滑鼠懸停：查看物品詳情
- `1-5`：使用快捷欄物品

---

## 下一步建議

**存檔擴充（Save v6）**
- Hotbar 綁定狀態保存

**消耗品系統擴充**
- ConsumableData 定義使用效果
- 支援回復 HP/MP、Buff、傳送等

**其他**
- Phase 7C: Hit Stop / FX
- 商店系統
- 更多敵人/Boss

*Review by Kimi*
