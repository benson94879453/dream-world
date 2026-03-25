### One-Line Summary

必要依賴可以 fallback，但不能靜默失敗；命名衝突優先靠清楚命名與後綴 `_` 解決。

## Fail Fast, Not Softly

### 可以接受 fallback，但不能靜默失敗

以下這類寫法不可接受：

```gdscript
current_state = get_node_or_null(initial_state) as PlayerState
if current_state == null:
	current_state = _find_first_state()
if current_state == null:
	return
```

理由：
- fallback 失敗後又直接 `return`，會讓系統停在半初始化狀態
- 把結構錯誤或配置錯誤悄悄吞掉
- 問題不會提早暴露，只會在更後面變得更難追

### 規範

- fallback 可以存在，但必須有明確目的
- fallback 失敗後不能靜默 `return`
- 必要依賴不存在時，要明確 `assert()`
- 不要用「先找不到就算了」當成初始化策略

最低底線：

```gdscript
var current_state_ := get_node_or_null(initial_state) as PlayerState
if current_state_ == null:
	current_state_ = _find_first_state()
assert(current_state_ != null, "StateMachine failed to resolve initial state")
current_state = current_state_
```

## Underscore Rules

### `_` 前綴的用途

`_` 前綴只用在以下情況：
- Godot callback，例如 `_ready()`、`_physics_process()`
- 明確的 internal helper，例如 `_update_facing()`
- 暫時未使用的參數，例如 `_delta`

不建議：
- 把一般公開方法都加上 `_`
- 把一般成員變數一律加 `_`
- 用 `_` 掩蓋設計邊界不清

### 後綴 `_` 的用途

為了避免成員、參數、局部變數撞名，統一用後綴 `_` 做消歧義。

適用在：
- 函式傳入參數
- 由 `NodePath` / `get_node()` 取回的局部變數
- 和成員變數同名或語意很接近的區域變數

例子：

```gdscript
var health: int = 100

func set_health(health_: int) -> void:
	health = health_
```

```gdscript
var state_machine_ := get_node_or_null(state_machine_path) as PlayerStateMachine
assert(state_machine_ != null, "state_machine_path must point to PlayerStateMachine")
```

不優先依賴 `self.health` 來解決命名問題；先改好命名。

## Type Annotation Rules

### `:=` 的使用限制

只有在右側已經透過 `as Type` 明確表達型別時，才允許使用 `:=`。

可接受：

```gdscript
var current_state_ := get_node_or_null(initial_state) as PlayerState
```

不可接受：

```gdscript
var speed := 120.0
var player_ := get_parent()
```

### 其他情況都要直接寫型別

除了 `as Type` 這類情況外，其他變數宣告都必須明確標型別。

可接受：

```gdscript
var speed: float = 120.0
var player_: PlayerController = get_parent() as PlayerController
var input_vector_: Vector2 = player_.get_move_input()
```

規範目的：
- 減少型別推導不透明
- 讓閱讀時一眼看出資料型別
- 降低後續重構時的歧義

## State Machine Rules

對於 state machine：
- `initial_state` 是正式配置，不是可有可無
- 可以 fallback，但 fallback 只能是明確設計的一部分
- fallback 失敗後必須報錯
- 不允許半初始化後直接 `return`
- 需要的節點型別不對時，直接報錯

## Region Style

GDScript 允許使用 `#region` / `#endregion` 做結構分區。

目前統一使用這種思路：
- `#region Public`
- `#region Core Lifecycle`
- `#region State Management`
- `#region Animation`
- `#region Helpers`

目的：
- 讓檔案長大後還能快速掃描
- 把 lifecycle、狀態切換、輔助函式分開
- 降低閱讀成本

## One-Line Summary

必要依賴可以 fallback，但不能靜默失敗；命名衝突優先靠清楚命名與後綴 `_` 解決。
