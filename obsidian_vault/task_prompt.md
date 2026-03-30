# Task Prompt — 前端 UI 視覺重構與文案清理

---

## 1. 任務背景

目前專案的主要前端 UI 已經具備可用功能，至少包含：
- `InventoryUI`
- `EquipmentUI`
- `DialogUI`
- `WeaponUpgradeUI`
- `RuneSocketUI`
- `QuestTrackerUI`
- `QuestToastUI`
- `QuestJournalUI`
- `ChestUI`

目前問題不是功能缺失，而是「視覺語言與文案品質不一致」：
- 不同介面的面板底色、邊框、留白、標題層級不一致
- 部分預設文字仍帶有 placeholder / 開發說明感，例如：
  - `game/scenes/ui/DialogUI.tscn`：`Speaker`、`Dialog text.`
  - `game/scenes/ui/InventoryUI.tscn`：`經典 RPG 分欄檢視`
  - `game/scenes/ui/QuestJournalUI.tscn`：過長的操作說明句
- 有些畫面上的輔助文字像註解，而不是玩家真正需要閱讀的 UI 文案
- 現有 Quest / Inventory / Upgrade UI 各自可用，但整體觀看時仍缺少統一的 ARPG 視覺風格

本任務目標是：
1. 重構 / 優化現有 UI 視覺效果，提升整體一致性與閱讀性
2. 去除或改寫意義不明、placeholder、開發感過重的文字註解
3. 在不破壞既有操作流程的前提下，完成最小且可驗收的 UI polish

---

## 2. 當前任務

### 任務標題
前端 UI 視覺重構與文案清理

### 任務描述
請針對目前已落地的主要 UI 介面做一輪集中整理，目標不是新增功能，而是把「看得出來是不同時期做出來的 UI」整理成同一套視覺語言，並清掉不像正式遊戲介面文案的文字。

### 具體需求

### A. 盤點並整理核心 UI 範圍
本次至少要涵蓋：
- `game/scenes/ui/InventoryUI.tscn`
- `game/scenes/ui/EquipmentUI.tscn`
- `game/scenes/ui/DialogUI.tscn`
- `game/scenes/ui/WeaponUpgradeUI.tscn`
- `game/scenes/ui/RuneSocketUI.tscn`
- `game/scenes/ui/QuestTrackerUI.tscn`
- `game/scenes/ui/QuestToastUI.tscn`
- `game/scenes/ui/QuestJournalUI.tscn`

若共用樣式或文字邏輯有關聯，可一併處理：
- `game/scenes/ui/ChestUI.tscn`
- 對應的 `game/scripts/ui/*.gd`

### B. 統一視覺語言
請整理以下項目，使各 UI 看起來屬於同一個遊戲：
- 面板底色、邊框色、強調色的使用規則
- 標題 / 次標 / 內文 / 狀態 / 提示 的字級與對比層級
- 面板圓角、留白、區塊間距、按鈕尺寸與排列
- Modal 視窗與 HUD 類 UI 的視覺權重區分
- 資訊密度：移除多餘裝飾與重複資訊，讓主要互動更醒目

建議方向：
- 維持目前偏深色、金色 accent 的 ARPG 風格
- 優先加強可讀性與層級，不要為了「更花」而犧牲辨識度
- `QuestTrackerUI` / `QuestToastUI` 應比 `InventoryUI` / `QuestJournalUI` 更輕量
- 保持 `Backdrop`、`layer`、`mouse_filter`、modal 開關行為不變

### C. 清理意義不明的文字註解
請移除、縮短或改寫以下類型文字：
- placeholder 英文預設文案
- 開發時期的說明句
- 玩家不需要看的介面註解式文字
- 重複描述同一件事的提示文字

優先處理示例：
- `game/scenes/ui/DialogUI.tscn`
  - `Speaker`
  - `Dialog text.`
- `game/scenes/ui/InventoryUI.tscn`
  - `經典 RPG 分欄檢視`
- `game/scenes/ui/QuestJournalUI.tscn`
  - `按 J 開啟或關閉，查看目前進度與已回報紀錄。`

清理原則：
- 保留真正幫助玩家操作的資訊，例如快捷鍵、進度、消耗、確認警告
- 若文字只是「像註解」，但不提升決策或操作效率，就應刪除或改寫
- 若保留操作提示，請使用一致、精簡的格式，不要每個畫面都寫成長句說明

### D. 最小重構原則
- 優先調整既有 scene 文字、theme override、樣式 helper、節點排版
- 優先重用現有 `_style_ui()` / `_apply_theme()` / `_apply_style()` 之類的整理點
- 不要為了這次 polish 新建大型 UI framework / global theme system，除非現況真的無法維護
- 不要順手改 Quest / Inventory / Upgrade / Save 的核心邏輯
- 不要更動輸入綁定與互動規則，只能在必要時修正與視覺整理直接相關的 UI 行為

### E. 自我驗證
請至少手動確認以下情境：
- `TownHub.tscn` 內開啟 `DialogUI`
- `TownHub.tscn` 內開啟 `InventoryUI`
- `TownHub.tscn` 內開啟 `WeaponUpgradeUI`
- `TownHub.tscn` / `Dungeon01.tscn` 中顯示 `QuestTrackerUI` / `QuestToastUI`
- `QuestJournalUI` 的列表與右側詳情在 1920x1080 下無文字裁切、重疊、超出版面
- modal 開關後，玩家輸入與 UI 關閉流程維持原本行為

---

## 3. 技術約束

- 維持現有場景與 script 的責任邊界
- 維持既有輸入動作與快捷鍵顯示語意：
  - `ui_inventory`
  - `ui_quest_journal`
  - `ui_cancel`
  - 互動鍵與數字鍵 hotbar
- 可調整文案、配色、間距、樣式、節點布局
- 可移除無意義的畫面文字與無價值的 UI placeholder
- 若要改 script，請以 UI 呈現相關程式為限
- 保留有結構價值的 `#region`；若 UI script 內有明顯占位、無幫助的註解，可一併清理
- 遵守 `planning/coding_habits.md` 的 GDScript 風格

### 禁止事項
- 不要新增 Autoload
- 不要改 Save schema
- 不要更動 QuestManager / Inventory / UpgradeManager 的資料模型
- 不要把這次任務擴張成整體設計系統重寫

---

## 4. 參考檔案

### 必讀
- `game/scenes/ui/InventoryUI.tscn`
- `game/scenes/ui/EquipmentUI.tscn`
- `game/scenes/ui/DialogUI.tscn`
- `game/scenes/ui/WeaponUpgradeUI.tscn`
- `game/scenes/ui/RuneSocketUI.tscn`
- `game/scenes/ui/QuestTrackerUI.tscn`
- `game/scenes/ui/QuestToastUI.tscn`
- `game/scenes/ui/QuestJournalUI.tscn`

### 高關聯
- `game/scripts/ui/InventoryUI.gd`
- `game/scripts/ui/EquipmentUI.gd`
- `game/scripts/ui/DialogUI.gd`
- `game/scripts/ui/WeaponUpgradeUI.gd`
- `game/scripts/ui/RuneSocketUI.gd`
- `game/scripts/ui/QuestTrackerUI.gd`
- `game/scripts/ui/QuestToastUI.gd`
- `game/scripts/ui/QuestJournalUI.gd`
- `game/scenes/ui/ChestUI.tscn`
- `game/scripts/ui/ChestUI.gd`

### 驗證相關
- `game/scenes/levels/TownHub.tscn`
- `game/scenes/levels/Dungeon01.tscn`
- `project.godot`
- `obsidian_vault/specs/input_keymap.md`

---

## 5. 驗收標準

### 視覺驗收
- [ ] 上述核心 UI 的配色、面板樣式、字級層級明顯更一致
- [ ] 主要互動區塊比次要說明更醒目，版面不顯得雜亂
- [ ] `HUD` 與 `Modal` 的視覺重量區分清楚

### 文案驗收
- [ ] 不再保留 `Speaker`、`Dialog text.` 這類 placeholder 文案
- [ ] 不再保留「像開發備註」或「意義不明」的畫面文字
- [ ] 保留的操作提示更精簡且格式一致
- [ ] 沒有誤刪重要資訊（例如快捷鍵、進度、金額、確認提示）

### 功能驗收
- [ ] `InventoryUI` / `QuestJournalUI` / `WeaponUpgradeUI` / `DialogUI` 仍可正常開關
- [ ] `QuestTrackerUI` / `QuestToastUI` 正常顯示，不影響滑鼠與攻擊輸入
- [ ] 1920x1080 下關鍵畫面無明顯裁切、重疊、溢出
- [ ] 無新增 parse error / warning

### 回報驗收
- [ ] 列出清掉或改寫了哪些「意義不明文字」
- [ ] 說明這輪 UI 整理的主要視覺規則
- [ ] 列出修改檔案
- [ ] 說明是否有尚未納入本輪的 UI 債務

---

## 6. 輸出要求

完成後請在本檔底部更新：
- 任務狀態
- 實作摘要
- 修改檔案清單
- 手動驗證結果
- 若有無法在本輪處理的 UI 問題，請列在備註

另外請在回報中明確說明：
1. 哪些畫面文字被刪除
2. 哪些畫面文字被改寫
3. 哪些 UI 只做視覺統一、沒有改動文案

---

## 7. 任務狀態

- [x] 進行中
- [x] 已完成

### 實作摘要

#### 新增檔案
- `game/scripts/ui/UIColors.gd` — 統一色彩常數與 `build_panel_style()` helper

#### 刪除的畫面文字
- `DialogUI.tscn`: `Speaker` → `""`
- `DialogUI.tscn`: `Dialog text.` → `""`
- `InventoryUI.tscn`: `經典 RPG 分欄檢視` → `""` (節點隱藏)
- `InventoryUI.tscn`: `整理背包、查看裝備、拖曳綁定快捷欄。` → `""` (節點隱藏)
- `QuestJournalUI.tscn` + `.gd`: `按 J 開啟或關閉，查看目前進度與已回報紀錄。` → `""` (節點隱藏)
- `RuneSocketUI.gd`: `背包裡沒有符文，按 K 可給予測試符文。` → `背包裡沒有符文。`

#### 改寫的畫面文字
- `InventoryUI.gd`: info_label `[E / I] 開關背包 [1-5] 使用快捷欄 拖曳整理/綁定 Shift+左鍵 快速裝備或分堆` → `[E / I] 背包 [1-5] 快捷欄 Shift+左鍵 快裝`

#### 只做視覺統一、沒有改動文案的 UI
- `EquipmentUI` — panel style 改用 UIColors
- `QuestTrackerUI` — 色彩常數改用 UIColors
- `QuestToastUI` — 色彩常數改用 UIColors
- `ChestUI` — panel style 改用 UIColors

#### 主要視覺規則
| 元素 | 規則 |
|---|---|
| Modal panel | `PANEL_BG`, `PANEL_BORDER` 金色, 3px, 8px 圓角 |
| Sub-panel | `PANEL_BG_LIGHT`, `PANEL_BORDER_SUBTLE`, 2px, 6px 圓角 |
| HUD element | 更透明 bg (α 0.82), 2px, 6px 圓角 |
| Backdrop | `BACKDROP` `Color(0.03, 0.03, 0.04, 0.64)` |
| Title | 24-30px, `TITLE_COLOR` |
| Body | 14-16px, `BODY_TEXT` |
| Muted | 12-13px, `MUTED_TEXT` |
| Accent | `ACCENT` 金色 |

### 修改檔案
- `game/scripts/ui/UIColors.gd` [NEW]
- `game/scenes/ui/DialogUI.tscn`
- `game/scripts/ui/DialogUI.gd`
- `game/scenes/ui/InventoryUI.tscn`
- `game/scripts/ui/InventoryUI.gd`
- `game/scripts/ui/EquipmentUI.gd`
- `game/scenes/ui/WeaponUpgradeUI.tscn`
- `game/scripts/ui/WeaponUpgradeUI.gd`
- `game/scripts/ui/RuneSocketUI.gd`
- `game/scenes/ui/QuestJournalUI.tscn`
- `game/scripts/ui/QuestJournalUI.gd`
- `game/scripts/ui/QuestTrackerUI.gd`
- `game/scripts/ui/QuestToastUI.gd`
- `game/scripts/ui/ChestUI.gd`

### 手動驗證
- Godot MCP 未連接，validate_script 返回 mock 結果
- 需用戶在 Godot 編輯器中執行以下驗證：
  1. TownHub 場景開啟 DialogUI / InventoryUI / WeaponUpgradeUI
  2. QuestTrackerUI / QuestToastUI 正常顯示
  3. QuestJournalUI 1920×1080 無裁切
  4. 所有 modal 開關正常

### 備註 / 問題
- 本任務以「視覺重構 + 文案清理」為主，不含新功能需求
- `EquipmentUI.tscn` 的 HintLabel `Shift+左鍵可快速卸下` 保留（有操作指引價值）
- `ChestUI.tscn` 的 HintLabel `點擊或 Shift+左鍵可快速移至玩家背包` 保留
- `RuneSocketUI.tscn` 的 `請先選擇槽位` 保留（是有意義的操作指示）
- 尚未納入本輪的 UI 債務：`EquipmentSlotUI.tscn`、`ItemSlotUI.tscn` 的細部樣式可在後續統一

---
