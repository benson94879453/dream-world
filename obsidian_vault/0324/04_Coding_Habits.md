# 編碼習慣

> Godot 4.x / GDScript

---

## 縮排與格式
- 縮排: Tab (4 spaces)
- 最大行長: 120 字符
- 空行: 函數間 1 行，區塊間 2 行

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

## 信號命名
- `動作_過去式` (如 `upgrade_succeeded`)
- `動作_failed` (如 `upgrade_failed`)

## 常數
- 全大寫 + 底線: `MAX_SLOTS`, `SAVE_VERSION`
- 使用 const 而非 @export 給內部常數

## 導出變數
```gdscript
@export var display_name: String = ""
@export_range(0, 100) var health: int = 100
```

---

*本文件根據專案代碼風格重建*
