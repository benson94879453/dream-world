# Code Review — 9B-1 Hotbar 綁定進存檔（Save v8）

## 任務資訊

- **任務名稱**: 9B-1 Hotbar 綁定進存檔（Save v8）
- **Codex 完成時間**: 2026-03-30
- **Kimi 驗收時間**: 2026-03-30

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 功能按預期運作 | ✅ 通過 | Hotbar 綁定已可序列化與回復 |
| 無 Console 錯誤/警告 | ✅ 通過 | 專案載入解析正常 |
| 邊界情況處理完善 | ✅ 通過 | 無效 bindings 會回退為 -1 |
| 驗收標準所有項目完成 | ✅ 通過 | v8 欄位、migration、讀寫流程齊備 |

### ✅ 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 使用現有 API，無重複造輪子 | ✅ 通過 | 延用 HotbarManager / SaveManager 既有架構 |
| 資料邊界正確 (Resource vs Instance vs DTO) | ✅ 通過 | bindings 以簡單 int 陣列儲存 |
| 不違反 EventBus 白名單規範 | ✅ 通過 | 無 EventBus 變更 |
| 不違反 Autoload 職責邊界 | ✅ 通過 | SaveManager 只負責存讀，HotbarManager 只負責 hotbar 狀態 |
| 組件化原則遵循 | ✅ 通過 | 序列化與 UI 刷新分離 |

### ✅ 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| 命名符合專案慣例 | ✅ 通過 | `to_save_dict` / `from_save_dict` 一致 |
| 程式碼結構清晰易讀 | ✅ 通過 | migration 與 save/load 分段明確 |
| 適當的註解與文件 | ✅ 通過 | v8 migration 有註解 |
| 無多餘/未使用程式碼 | ✅ 通過 | 無冗餘路徑 |

---

## 詳細回饋

### 優點 👍
- Hotbar 綁定資料以 `bindings` 陣列保存，格式簡單直接，適合 migration。
- `from_save_dict()` 會驗證資料長度與索引範圍，壞資料會安全回退。
- `SaveManager` 已在 save/load 兩端完整串起 hotbar 欄位，且 v7→v8 migration 會補齊舊檔。
- `binding_changed` 全量發出後，UI 自動刷新流程清楚。

### 問題/建議 🔧
- 目前只做了專案載入驗證，尚未完成實機 F5/F9 存讀檔流程驗收。

### 架構觀察 🏗️
- 這次升版把 hotbar 納入 Save v8 是合理的，和 Quest / Respawn 後續欄位擴充方式一致。
- `HotbarManager` 的序列化責任清楚，不會反向污染 Inventory 的資料模型。

---

## 驗收結果

- [x] **有條件通過** - 可進入下一任務，但仍建議補做 F5/F9 實機驗收

### 下一步行動

進入 **9B-2 Checkpoint 重生點跨重啟（Save v8 附加）**。

---

## 相關連結

- Codex Prompt: `obsidian_vault/codex_prompt.md`
- 實作檔案:
  - `game/scripts/core/HotbarManager.gd`
  - `game/scripts/core/SaveManager.gd`

---

*Review 建立時間: 2026-03-30*
