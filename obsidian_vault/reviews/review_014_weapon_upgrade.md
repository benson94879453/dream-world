# Code Review #014 - 武器升級系統

## 任務資訊

- **任務名稱**: 武器升級系統（核心）
- **Codex 完成時間**: 2026-03-28
- **Kimi 驗收時間**: 2026-03-28

---

## 驗收檢查清單

### ✅ 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|------|------|
| WeaponInstance star_level (0-5) | ✅ 通過 | 0★=0槽, 5★=5槽 |
| WeaponInstance affixes | ✅ 通過 | Array[AffixInstance] |
| 攻擊加成計算 | ✅ 通過 | 每級+5% + 詞綴加成 |
| AffixData / AffixTable | ✅ 通過 | 6個基礎詞綴，權重抽選 |
| UpgradeManager Autoload | ✅ 通過 | 材料檢查、升級、給詞綴 |
| WeaponUpgradeUI | ✅ 通過 | 顯示資訊、材料、升級按鈕 |
| 鐵匠對話整合 | ✅ 通過 | 「我想升級武器」開啟UI |
| Save schema v3 | ✅ 通過 | 保存星級與詞綴 |
| DebugOverlay 星級顯示 | ✅ 通過 | 實時顯示當前武器星級 |
| L 鍵 Debug 素材包 | ✅ 通過 | 方便測試升級 |

### ✅ 驗證結果

| 測試 | 結果 |
|------|------|
| Godot headless --import | ✅ 通過 |
| Godot headless --quit-after 60 | ✅ 通過 |
| Save smoke | ✅ version=3, saved_stars=2/restored_stars=2, saved_affixes=1/restored_affixes=1 |

---

## 詳細回饋

### 優點 👍

1. **完整的升級鏈路**:
   ```
   鐵匠對話 → 開啟UI → 檢查材料 → 升級成功 → 獲得詞綴 → 保存
   ```

2. **星級與詞綴分離設計**:
   - 星級提供基礎加成和符文槽
   - 詞綴提供額外屬性變化
   - 兩者都保存，打造獨特武器

3. **6個基礎詞綴**:
   | 詞綴 | 效果 |
   |------|------|
   | 鋒利 | 暴擊率 +5% |
   | 沉重 | 攻擊+10%, 攻速-5% |
   | 迅捷 | 攻速 +10% |
   | 專注 | 法術傷害 +10% |
   | 吸血 | 回復 3% 傷害HP |
   | 暈眩 | 5%機率暈眩 |

4. **Debug 工具**:
   - L 鍵素材包方便測試
   - DebugOverlay 實時顯示星級

### 設計決策記錄 📝

**攻擊加成計算**:
```gdscript
# 基礎攻擊力 * (1 + 星級*0.05) * 詞綴加成
star_bonus = 1.0 + (star_level * 0.05)  # 0★=1.0, 5★=1.25
```

**詞綴抽取**:
```gdscript
# 根據武器類型過濾適用詞綴
# 權重隨機抽選
```

---

## 驗收結果

- [x] **通過** - 武器升級系統完成！

---

## 🎉 Phase 5B 完成！完整可玩循環達成！

### 完整循環驗證

```
對話 → 戰鬥 → 掉落 → 撿取 → 裝備 → 強化 → 存檔
  ✅      ✅      ✅      ✅      ✅      ✅      ✅
```

| 階段 | 狀態 | 說明 |
|------|:----:|------|
| **對話** | ✅ | NPC 對話系統、逐字顯示 |
| **戰鬥** | ✅ | Slime/Archer/Boar + Dash |
| **掉落** | ✅ | LootTable + PickupItem |
| **撿取** | ✅ | Inventory 自動撿取 |
| **裝備** | ✅ | 數字鍵切換武器 |
| **強化** | ✅ | 升級+詞綴+符文槽 |
| **存檔** | ✅ | SaveManager v3 |

### 系統架構圖

```
Player
├── 裝備 WeaponInstance
│   ├── star_level (0-5)
│   ├── affixes (隨機詞綴)
│   └── rune_slots (5個槽位)
├── Inventory (素材)
└── 與 UpgradeManager 互動

NPC (鐵匠)
└── 對話 → 開啟 WeaponUpgradeUI

UpgradeManager
├── 檢查材料
├── 抽取詞綴 (AffixTable)
└── 升級武器
```

---

## 下一步建議

### Phase 6: 周邊系統擴充

| 優先級 | 項目 | 說明 |
|:---:|------|------|
| ⭐⭐ | **符文鑲嵌** | 把符文石放入符文槽 |
| ⭐⭐ | **素材來源** | 敵人掉落、武器分解 |
| ⭐⭐ | **Hit Stop/FX** | 戰鬥手感優化 |
| ⭐ | **武器重置** | 高代價重置詞綴 |
| ⭐ | **群體 AI** | 敵人協同行為 |

---

## 相關連結

- Prompt: `obsidian_vault/task_prompt.md`
- 同步摘要: `obsidian_vault/sync_summary.md`
- 企劃文件: `obsidian_vault/planning/project_goals.md`
- 任務清單: `obsidian_vault/planning/mvp_todo.md`
