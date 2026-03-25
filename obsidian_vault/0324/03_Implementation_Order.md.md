# 03 Implementation Order

## Phase 1: Scene Skeleton
- [ ] Create `Player.tscn` with a `CharacterBody2D` root
- [ ] Add `StateMachine`, `WeaponPivot`, `Hurtbox`, `HealthComponent`, `FeedbackReceiver`, and `Camera2D` to `Player.tscn`
- [ ] Create `Enemy_Dummy.tscn` with a simple enemy component layout
- [ ] Add `StateMachine`, `Hurtbox`, `Hitbox`, `HealthComponent`, `FeedbackReceiver`, and `DropManager` to `Enemy_Dummy.tscn`
- [ ] Create `DebugOverlay.tscn` as a HUD/debug root
- [ ] Create `Arena_Test.tscn` and instance the player, dummy container, and debug overlay

## Phase 2: Combat Foundation
- [ ] Create `AttackContext.gd`
- [ ] Create `HealthComponent.gd`
- [ ] Create `DamageReceiver.gd`
- [ ] Create `Hitbox.gd`
- [ ] Create `Hurtbox.gd`
- [ ] Create `FeedbackReceiver.gd`
- [ ] Wire the basic flow `Hitbox -> Hurtbox -> DamageReceiver -> HealthComponent`

## Phase 3: Player Prototype
- [ ] Add 8-direction movement input handling
- [ ] Add dash state and cooldown
- [ ] Add a basic attack trigger from `WeaponPivot`
- [ ] Show current player state in the debug overlay

## Phase 4: Test Loop
- [ ] Spawn one dummy in `Arena_Test`
- [ ] Verify player movement and camera follow
- [ ] Verify dummy can receive damage events
- [ ] Verify debug overlay can be toggled and updated

## Small Tasks To Start Now
- [ ] Open `Arena_Test.tscn` and confirm the scene instances load cleanly
- [ ] Decide whether the player root should keep all combat components directly attached or grouped under a `Components` node
- [ ] Add placeholder visuals to player and dummy so the test arena is readable
- [ ] Set `Arena_Test.tscn` as the main test entry scene when ready
