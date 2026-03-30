# Review #018: 滑鼠攻擊模式

## 驗收結果: ✅ 通過（待修復投射物方向）

**日期**: 2026-03-28  
**實作者**: 已完成並回填 task_prompt.md

---

## 功能驗收

| 檢查項 | 狀態 | 備註 |
|--------|:----:|------|
| 滑鼠左鍵攻擊 | ✅ | project.godot 新增 attack_mouse |
| 角色面向滑鼠 | ✅ | Player.gd 依滑鼠位置切換左右 |
| 鍵盤攻擊保留 | ✅ | 向後相容 |
| Combo 續接 | ✅ | PlayerAttackState 接受 attack_mouse |
| 左右翻轉正確 | ✅ | 滑鼠在左朝左，右側朝右 |
| Console 無新錯誤 | ✅ | headless 通過 |

---

## 已知問題

| 問題 | 嚴重度 | 說明 |
|------|:------:|------|
| 投射物方向 | 🔴 高 | StaffWeapon 法術只往左/右飛，非朝滑鼠位置 |
| 既存 UID Warning | 🟡 低 | Player.tscn ext_resource invalid UID，非本次引入 |

---

## 修改檔案清單

```
project.godot
game/scripts/Player.gd
game/scripts/player/states/PlayerAttackState.gd
obsidian_vault/task_prompt.md
```

---

## 下一步

**#018+ 投射物方向修復**：讓 StaffWeapon 法術朝滑鼠位置發射

*Review by Kimi*
