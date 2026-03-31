# Refactor plan

## Phase 0 - Safety rails / visibility
- [ ] Document current autoload dependencies from `project.godot`
- [ ] Add dependency map comments to high-risk files:
  - [ ] `C:\Users\user\Documents\GitHub\dream-world\game\scripts\core\SaveManager.gd`
  - [ ] `C:\Users\user\Documents\GitHub\dream-world\game\scripts\core\SceneTransitionManager.gd`
  - [ ] `C:\Users\user\Documents\GitHub\dream-world\game\scripts\Player.gd`
- [ ] Add smoke tests around save/load, scene transition, quest progression, rune equip, weapon upgrade

## Phase 1 - Remove worst hidden dependencies
- [ ] Introduce `ContentCatalog` service for item/weapon/gear/rune lookup
- [ ] Change save/load APIs to accept catalog instead of pulling `SaveManager`
  - [ ] `Inventory`
  - [ ] `Equipment`
  - [ ] `WeaponInstance`
  - [ ] quest reward resolution
- [ ] Eliminate root lookup from Resource classes
  - [ ] `WeaponInstance.gd`
  - [ ] `LootTableData.gd`

## Phase 2 - Event-driven quest progression
- [ ] Introduce gameplay event hub/signals for:
  - [ ] `npc_talked`
  - [ ] `item_collected`
  - [ ] `enemy_killed`
- [ ] Remove direct QuestManager calls from:
  - [ ] `DialogManager.gd`
  - [ ] `PickupItem.gd`
  - [ ] `EnemyAIController.gd`
- [ ] Make QuestManager a subscriber instead of a callee

## Phase 3 - Split SaveManager
- [ ] Extract file IO + migration into `SaveRepository`
- [ ] Extract save-state assembly into `GameStateAssembler`
- [ ] Extract load ordering into `LoadCoordinator`
- [ ] Move resource cache/lookup out of SaveManager into `ContentCatalog`
- [ ] Keep `SaveManager` as thin façade during transition

## Phase 4 - Split SceneTransition / respawn / fade
- [ ] Extract `ScreenFadeController` from `SceneTransitionManager`
- [ ] Extract `RespawnService` from `SceneTransitionManager`
- [ ] Extract zone enter/exit notifications from `SceneTransitionManager`
- [ ] Decide whether runtime player/inventory carryover belongs in:
  - [ ] `LoadCoordinator`
  - [ ] or a dedicated `RuntimeStateTransfer` service

## Phase 5 - Centralize modal/input policy
- [ ] Add `ModalCoordinator`
- [ ] Replace duplicated modal scans in:
  - [ ] `Checkpoint.gd`
  - [ ] `Portal.gd`
  - [ ] `InstructorNPC.gd`
  - [ ] `NPCDialogTrigger.gd`
  - [ ] `InventoryUI.gd`
  - [ ] `QuestJournalUI.gd`
  - [ ] `SaveManager.gd`
- [ ] Move player lock/unlock policy out of UI classes

## Phase 6 - Break up Player.gd
- [ ] Extract `PlayerEquipmentController`
- [ ] Extract `PlayerSaveAdapter`
- [ ] Extract `PlayerDebugCommands`
- [ ] Extract `PlayerRespawnController`
- [ ] Keep `Player.gd` focused on movement/combat orchestration

## Phase 7 - UI façade cleanup
- [ ] Add façade/presenter layer for:
  - [ ] Inventory UI
  - [ ] Quest Journal UI
  - [ ] Weapon Upgrade UI
  - [ ] Rune Socket UI
- [ ] Remove direct service/root lookups from UI scripts
- [ ] Remove direct player mutation from UI where possible

## Phase 8 - NPC/dialog consolidation
- [ ] Consolidate `InstructorNPC.gd` and `NPCDialogTrigger.gd` into one NPC interaction pattern
- [ ] Keep `NPCQuestGiver` as data/provider logic only
- [ ] Separate prompt display, interaction detection, and dialog launching

## Phase 9 - Configurability over hardcoded paths
- [ ] Move hardcoded resource paths/config to exported resources:
  - [ ] upgrade tables
  - [ ] decompose defaults
  - [ ] zone reset config
  - [ ] debug loadouts
- [ ] Replace concrete preloads with interfaces/resources where feasible