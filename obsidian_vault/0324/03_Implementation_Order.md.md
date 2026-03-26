# 03 Implementation Order

## Current Status
- [x] Create `Player.tscn` with a `CharacterBody2D` root
- [x] Add `StateMachine`, `WeaponPivot`, `Hurtbox`, `HealthComponent`, `FeedbackReceiver`, and `Camera2D` to `Player.tscn`
- [x] Create `Enemy_Dummy.tscn` with a simple enemy component layout
- [x] Create `DebugOverlay.tscn` as a HUD/debug root
- [x] Create `Arena_Test.tscn` and instance the player, dummy container, and debug overlay
- [x] Add 8-direction movement input handling
- [x] Add the player walk sheet and left/right facing
- [x] Build the player FSM skeleton with `Idle`, `Walk`, `Run`, and `Locked`
- [x] Move state machine startup to owner-driven lifecycle
- [x] Add a minimal equipped weapon flow backed by `WeaponData`, `WeaponInstance`, and `wpn_unarmed.tres`
- [x] Promote weapons into category scenes instantiated from `WeaponData.weapon_scene`
- [x] Split weapon category logic into `SwordWeapon` and `StaffWeapon`
- [x] Move staff attack payload selection into `WeaponData.attack_actor_scene`
- [x] Add `SpellActor` base and `BoltSpellActor` projectile implementation
- [x] Move weapon sprite offset resolution into `WeaponController`

## Prototype Goal
- [x] Use `Arena_Test.tscn` as the main prototype loop
- [x] Keep the prototype focused on player movement, melee attacks, dummy damage, and readable debug info
- [x] Do not implement dash in this phase

## Next Tasks
- [x] Add `PlayerCollision` and `Hurtbox` shapes to the player scene
- [x] Add a minimal melee attack from `WeaponPivot -> Hitbox`
- [x] Add `AttackContext.gd`
- [x] Add `Hitbox.gd`
- [x] Add `Hurtbox.gd`
- [x] Add `DamageReceiver.gd`
- [x] Add `HealthComponent.gd`
- [x] Add `FeedbackReceiver.gd`
- [x] Wire `Hitbox -> Hurtbox -> DamageReceiver -> HealthComponent -> FeedbackReceiver`
- [x] Give `Enemy_Dummy` a visible placeholder body and HP
- [x] Show player state, player HP, and dummy HP in `DebugOverlay`
- [x] Verify the hit flow in the editor
- [x] Decide whether the prototype needs a dedicated player attack state or should stay input-driven for now
- [ ] Add a debug-visible way to equip and swap between sword and staff in `Arena_Test`
- [ ] Define weapon attack presentation ownership: animation, cast timing, muzzle flash, and audio
- [ ] Define how non-projectile spell actors plug into the same `StaffWeapon -> SpellActor` chain
- [ ] Decide when attack timing pressure is high enough to promote attack into a dedicated player state

## Refactoring Trigger
- [x] Keep the current prototype attack as input-driven for now
- [ ] Promote attack into a dedicated player state only when one of these needs appears:
  - attack startup / recovery timing
  - movement lock during attack
  - combo chaining
  - cancel rules
  - tighter animation-window control of hitbox timing

## Acceptance Checklist
- [x] Player can walk and run in `Arena_Test`
- [x] Player can trigger a melee attack
- [x] Dummy takes damage from the player hitbox
- [x] Dummy HP decreases to zero without scene errors
- [x] Debug overlay shows player state, player HP, and dummy HP
- [x] State machine only starts after the owner is ready
- [x] Player equips weapons via `WeaponData -> WeaponInstance -> WeaponController`
- [x] `SwordWeapon` owns melee hitbox/cooldown lifecycle
- [x] `StaffWeapon` spawns a `SpellActor` selected from `WeaponData.attack_actor_scene`
