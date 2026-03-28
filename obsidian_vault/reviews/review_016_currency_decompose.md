# Review #016: 素材來源系統（金幣 + 武器分解 + 敵人掉落擴充）

## 驗收結果: ✅ 通過

**日期**: 2026-03-28  
**Codex**: 已完成並回填 codex_prompt.md

---

## 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|:----:|------|
| 金幣系統正常運作 | ✅ | Player.gold 有 add/spend/can_spend API |
| 存檔 v5 正確保存/讀取 gold | ✅ | smoke: saved=4321, restored=4321 |
| Debug G 鍵給予 1000 金幣 | ✅ | 已實作 |
| 武器分解計算回報正確 | ✅ | DecomposeManager 依星級計算 |
| 分解 UI 顯示預覽和確認 | ✅ | WeaponUpgradeUI 三頁籤 |
| 敵人掉金幣 | ✅ | LootTableData 支援金幣範圍 |
| 敵人掉符文 | ✅ | 低機率隨機符文石 |
| 符文拆卸扣款 | ✅ | RuneManager + RuneSocketUI 整合 |
| Console 無錯誤 | ✅ | headless smoke 通過 |

---

## 架構驗收

| 檢查項 | 狀態 | 備註 |
|--------|:----:|------|
| 使用現有 API | ✅ | 整合現有 Inventory, SaveManager |
| 資料邊界正確 | ✅ | Player gold 為 runtime state |
| Save 遷移處理 | ✅ | v4→v5 自動補 gold=0 |
| Autoload 職責清晰 | ✅ | DecomposeManager 獨立職責 |

---

## 風格驗收

| 檢查項 | 狀態 | 備註 |
|--------|:----:|------|
| 命名符合慣例 | ✅ | snake_case 與後綴 `_` |
| 程式碼結構清晰 | ✅ | 註解與分區明確 |
| 適當的註解 | ✅ | 設計決策有說明 |

---

## 設計決策確認

### ✅ 武器類型素材映射
- `sword -> 鐵礦石 (mat_iron_ore)`
- `staff -> 靈魂碎片 (mat_soul_shard)`

如需調整，修改 `DecomposeManager.WEAPON_TYPE_MATERIAL_IDS`。

### ✅ 分解後自動切換武器
- 避免玩家分解裝備中武器後無武器可用
- 自動切換回 `wpn_unarmed`

---

## 修改檔案清單

```
game/scripts/Player.gd
game/scripts/inventory/Inventory.gd
game/scripts/core/SaveManager.gd
game/scripts/core/DecomposeManager.gd          [NEW]
game/scripts/core/RuneManager.gd
game/scripts/core/ArenaTest.gd
game/scripts/data/LootTableData.gd
game/scripts/components/DropComponent.gd
game/scripts/ui/RuneSocketUI.gd
game/scripts/ui/WeaponUpgradeUI.gd
game/scripts/ui/DebugOverlay.gd
game/scripts/debug/LootDropSmokeCheck.gd
game/scenes/ui/RuneSocketUI.tscn
game/scenes/ui/WeaponUpgradeUI.tscn
game/scenes/DebugOverlay.tscn
game/data/loot_tables/loot_dummy_basic.tres
game/data/loot_tables/lt_goblin_archer.tres
game/data/loot_tables/lt_boar.tres
project.godot
```

---

## 完整經濟循環達成 🎉

```
戰鬥 → 獲得金幣/素材/符文 → 強化武器 → 調整符文（扣金幣）
  ↑                                                              ↓
  └──────── 分解多餘武器 ────────────────────────────────────────┘
```

---

## 下一步

**Phase 7B: 符文效果實裝** - 讓核心符文（無盡之刃、雙重打擊等）真正影響戰鬥

*Review by Kimi*
