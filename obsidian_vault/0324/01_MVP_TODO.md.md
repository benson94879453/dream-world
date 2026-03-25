# 01 MVP TODO

## Prototype Closed Loop
- [x] Build `Player.tscn`
- [x] Build `Enemy_Dummy.tscn`
- [x] Build `DebugOverlay.tscn`
- [x] Build `Arena_Test.tscn`
- [x] Add 8-direction movement
- [x] Add walk and run states
- [x] Add owner-driven state machine startup
- [x] Add player melee attack input
- [x] Add player attack hitbox
- [x] Add dummy damage receiving
- [x] Add HP display in debug overlay
- [x] Verify the full loop in `Arena_Test`

## Player
- [x] `Idle`
- [x] `Walk`
- [x] `Run`
- [x] `Locked`
- [x] `PlayerCollision` shape
- [x] `Hurtbox` shape
- [x] Basic melee attack from `WeaponPivot`
- [x] Expose current HP to debug tools

## Combat Foundation
- [x] `AttackContext.gd`
- [x] `Hitbox.gd`
- [x] `Hurtbox.gd`
- [x] `DamageReceiver.gd`
- [x] `HealthComponent.gd`
- [x] `FeedbackReceiver.gd`
- [x] Damage flow works end to end

## Dummy Target
- [x] Placeholder visual
- [x] `HealthComponent`
- [x] `DamageReceiver`
- [x] `FeedbackReceiver`
- [x] Reach zero HP cleanly

## Debug
- [x] Show player state
- [x] Show player HP
- [x] Show dummy HP

## Deferred Until Later
- [ ] Player attack state
- [ ] Enemy AI
- [ ] Inventory
- [ ] Save / Load
- [ ] Hub / Zone flow
