# 編碼習慣

> Godot 4.x / GDScript

---

## 縮排與格式
- 縮排: Tab (4 spaces)
- 最大行長: 120 字符
- 空行: 函數間 1 行，區塊間 2 行
- 盡量將過長表達式拆行，避免為了省行數犧牲可讀性

## 註解風格
```gdscript
# 單行註解

#region 區塊名稱
func some_function() -> void:
    pass
#endregion
```

## 型別標註
- 參數: `func method(param_: Type) -> ReturnType`
- 變數: `var variable: Type = value`
- 優先使用具體型別而非 `Variant`
- 空值檢查優先使用 `assert`，避免用 `if null` 後只 `print_error`
- 成員變數一律標註型別；區域變數也盡量明寫型別，只有在非常明確時才用 `:=`
- 函式回傳型別一律標註，包含 `void`

## 信號命名
- `動作_過去式` (如 `upgrade_succeeded`)
- `動作_failed` (如 `upgrade_failed`)

## 常數別名
- preload / 類型別名使用 PascalCase: `InventoryResource`, `ItemSlotUIScene`, `UIColorsResource`

## 常數
- 全大寫 + 底線: `MAX_SLOTS`, `SAVE_VERSION`
- 使用 const 而非 @export 給內部常數

## 錯誤處理
- 必要依賴缺失時使用 `assert`
- 可恢復的執行期異常使用 `push_warning`
- 只在真正不可繼續時使用 `push_error` / `printerr`

## 導出變數
```gdscript
@export var display_name: String = ""
@export_range(0, 100) var health: int = 100
```
## 模塊化準則（摘要）  
- 每個模塊只負責一件事（單一職責）。場景只裝配，邏輯放 Service/Domain。  
- 資料使用 Resource（ItemData, WeaponData 等），並由 Domain/Service 消費。  
- 模塊公開 API 與 signals；內部實作不應被外部直接取用。  
- 跨模塊通訊以 signals / EventBus 為主；避免直接 get_node() 到不該訪問的 node。  
- 使用 Autoload 作全域協調者（GameState, SaveManager, InventoryService），但僅作協調者角色。  
- 所有 Service/Domain 要有 unit tests；所有 PR 都必須通過 lint 與測試。  
-  使用 DI 或注入避免硬編碼全域依賴，便於替換/mock。
---
