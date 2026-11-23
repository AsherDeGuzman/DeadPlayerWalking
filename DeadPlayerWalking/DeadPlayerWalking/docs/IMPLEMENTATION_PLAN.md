# Implementation Plan

## Design authority

`Dead_Player_Walking_GDD_Token.pdf` is the controlling design. Its core scope is a ten-floor mobile 2D dungeon, a fixed melee/ranged weapon pair, deterministic enemy rooms, partial healing, persistent floor/boss/death rewards, and previous-self enemies built only from final stat and weapon snapshots. Sections 8.4 and 8.5 are reserved for the scene-tree and signal-wiring plan based on the implemented project.

## Current project state

- Godot 4.7.2 project with mobile/desktop controls, player animations, health, character and weapon upgrades, save/load, two functional weapons, and an integration test.
- Dungeon foundation has ten floor resources and 38 deterministic, reusable combat rooms. Floors 1–4 use upper-dungeon themes; floors 5–10 use deep-dungeon themes. Room exits remain blocked until their enemies are defeated.
- The weapon milestone uses a timed melee `Area2D` hitbox and an independent collision-driven crossbow projectile.
- Death records store character stats, weapon archetypes, floor, room, and room-local position. On later runs, up to three stronger previous selves emerge from authored grave slots at those saved death locations and use melee or collision-based ranged attacks according to their saved weapons.
- Floor 5 is a regular floor. The fixed PreviousSelf boss/reveal is superseded by death-location encounters; Floor 10's Hollow Warden remains the final boss and victory gate.
- Main menu, workshop/defeat/victory flows, pause and abandon confirmation, persisted audio settings, responsive HUD, and viewport-fitted menus are implemented. The workshop includes data-driven character and capped weapon damage upgrades.
- The audio manager switches among separate looping menu, exploration, combat, boss, death, and victory themes and has dedicated attack/impact, healing, door, weapon-switch, boss, upgrade, and UI cues. No source audio files are included, so it synthesizes distinct PCM fallbacks and releases cached streams during shutdown.
- The audio manager switches among distinct looping menu, exploration, combat, boss, death, and victory themes; because no source audio files are supplied, each theme uses its own generated PCM fallback and is tested through the game-flow transitions.
- Supplied `ASSETS/` artwork is connected to player, ordinary enemy, and boss animations, the original PreviousSelf character art, four-way player facing, hand-anchored and direction-following sword/crossbow visuals, HUD weapon icons, weapon and projectile effects, player damage flash, enemy death burst, grave marker, animated healing pickup and collection effect, upgrade icons, menu/result backgrounds, upper/deep dungeon walls, boss-room entrance, door-state effects, boss aura and high-visibility directional attack telegraphs, animated floor-transition overlay, boss-arena backdrop, and deterministic upper/deep dungeon floor `TileMapLayer`s. Normal-room door artwork opens after combat, with supplied wall-torch props; floor atlas gutters are cropped and tile choices are distributed across rows. Ordinary enemies collide with one another for more readable combat spacing. Source art remains in place and is referenced directly.
- Static player/enemy design sheets and the standalone healing-pickup image are preserved as reference/alternate artwork; the corresponding animated runtime sheets are used in game.
- Normal rooms use four deterministic, visibly rendered obstacle layouts with crate-base collision footprints, depth-sorted enemies, supplied torches, and a locked-to-open illustrated exit; boss arenas remain open. Exit monitoring is disabled during combat and enabled only after a room is cleared.
- Cleared rooms extend upward in world space with the player's camera following smoothly and one room retained behind each transition; ordinary enemy animation sprites render above room props at a readable scale.
- Each floor has one fixed, authored potion pickup in a regular room. Potions stack in the USE inventory and restore up to 25% of maximum health when used.
- Each permanent upgrade level scales ordinary mob and PreviousSelf health, damage, and speed by 0.3%.
- Each entered room adds 1% of the player's current health, attack damage, and movement speed per room to every non-boss mob. Melee archetypes move at 1.4x configured speed; the player's crossbow has an authored indicator during its 1.5-second post-shot reload.
- The player dash has a 3-second cooldown; its remaining time and shrinking ring appear inside the DASH touch button.
- PreviousSelf enemies retain their own supplied character art, enlarge it to 140 pixels high, flip horizontally during pursuit, animate with a subtle bob/lean, and keep their health bar above the larger silhouette.
- The Hollow Warden scales to 5x player maximum health and deals 1/5 of that maximum as damage; three attacks use authored, high-contrast beam, ground-circle, and cone telegraphs above the floor draw layer.
- Each cleared floor awards 30 scrap; Floor 10 awards an additional 100-scrap boss bonus. Death awards 10 scrap.

## Confirmed GDD scope

- Preserve the current player controls, weapons, combat feedback, upgrades, save flow, and deterministic layout while expanding the run to ten floors.
- Provide configurable floor/room data, combat-room exits locked by live enemies, deterministic room-to-room progression, and fixed healing pickup locations. Do not randomize encounter or reward placement.
- Keep the Floor 10 Hollow Warden encounter; replace the fixed Floor 5 boss/reveal with saved-death-location PreviousSelf encounters.
- Replace movement/action replay with saved character-stat, weapon-archetype, and death-location data for previous selves.
- Keep permanent upgrades within the approved categories: maximum health, attack power, movement speed, Dungeon Edge, and Warden Crossbow.

## Milestones

1. **Project foundation:** already present and launch-tested.
2. **Combat foundation:** weapons, projectile collisions, enemy damage, feedback, and permanent weapon damage upgrades implemented.
3. **Dungeon foundation:** deterministic ten-floor, 38-room scene flow and enemy-locked exits implemented and validated.
4. **Progression:** replace action-history echoes with validated stat/weapon snapshots and death-site grave encounters. Implemented.
5. **Bosses:** retain the Floor 10 final boss/victory; Floor 5 remains a regular floor. Implemented.
6. **UI/mobile:** implement settings, pause and confirmation flow, complete upgrade workshop, and responsive HUD/touch controls. Implemented.
7. **Content/polish:** integrate supplied character, weapon, pickup, boss, screen, and dungeon floor artwork; add readable deterministic room layouts, authored partial healing, floor/boss rewards, combat-balance guardrails, and known-issue documentation. Core systems and the listed art are implemented and visually reviewed at 1280 × 720; manual device validation remains.

## Scene Dock implementation

- `Level01.tscn` exposes editable children for the dungeon room, player, and HUD.
- `DungeonRoom.tscn` contains every reusable runtime combat/environment placeholder directly in the Scene Dock:
  - `Enemies/Enemy01` through `Enemies/Enemy06`
  - `Enemies/PreviousSelf`, `Enemies/PreviousSelf02`, and `Enemies/PreviousSelf03`
  - `Enemies/EchoGrave01` through `Enemies/EchoGrave03`
  - `Enemies/DungeonBoss`
  - `Enemies/DungeonBoss/TargetTelegraph` and `Enemies/DungeonBoss/SweepTelegraph`
  - `Player/ReloadIndicator` (in the player scene)
  - `Enemies/PreviousSelf/Art` using the supplied PreviousSelf character image
  - `HealingPickup`
  - `HealingCollectionEffect`
  - `WorldGeometry/SuppliedWalls`
  - `WorldGeometry/Obstacles` with six static prop nodes
  - `WorldGeometry/ExitDoor`
  - `WorldGeometry/DoorStateEffect`
  - `WorldGeometry/BossRoomEntrance`
- Runtime scripts activate only the required static placeholders for the current floor/room.
- Tests distinguish active combatants from static placeholders instead of deleting or dynamically spawning the Scene Dock nodes.
- Boss rooms deactivate ordinary enemy placeholders before activating the static `DungeonBoss` node. A saved PreviousSelf can also activate in its authored slot if that boss room is its death location.
- `HUD/UI/Screen/FloorTransition` authors the transition backdrop, portal artwork, curtains, title, and subtitle.
- Full ten-floor smoke validation passed under the installed Godot 4.7.1 executable.
- Milestone 7 validation confirms supplied visual assets are referenced directly from `ASSETS/`; no source audio files are supplied, so generated fallback audio remains active.

## Verification requirements

- Import and run the Godot headless integration check in a disposable project copy. Cover the full dungeon, weapon, progression, death-site echo combat, boss, victory, UI, mobile, room-layout, reward, and healing systems.
- Verify ten floors and configured room counts; each exit stays locked with active enemies and advances only after the room is cleared.
- Verify one fixed potion pickup per floor, stacking at full health, 25% maximum-health restoration on use, and the USE/exit context.
- Verify each floor awards 30 scrap exactly once, with +100 on Floor 10 and +10 on death.
- Preserve weapon hit windows, projectile collision/cleanup, controls, persistence, and run outcomes.
- Verify death records contain no action samples, preserve floor/room/local position, and create stronger PreviousSelf enemies at those saved locations after grave emergence.
- Verify the dash's 3-second cooldown and touch-button countdown, mob upgrade and per-room current-player-stat scaling, melee pursuit speed, the player's post-shot crossbow reload countdown, PreviousSelf art and left/right movement animation, the dynamic Floor 10 boss health/damage formulas, all three visible AOE telegraphs and dodge windows, its locked exit, and victory directly after the final boss is defeated.
- Verify menu actions, saved settings, upgrade affordability and effects, pause/resume/abandon confirmation, touch attack and movement, WASD joystick feedback, and control placement across landscape viewport sizes.
- Verify separate music themes play and loop for the title, cleared-room exploration, active combat, bosses, defeat, and victory; confirm volume settings and pause behavior still apply.
- The expanded smoke test validates the complete ten-floor run, including healing and rewards.
- Skeleton, dungeon-creature, and archer enemies use measured atlas regions for idle, walk, attack, hurt, and death. Data-driven enemy archetype resources configure each one's stats and combat range; deterministic room placement includes ranged archer projectiles. The player's Warden Crossbow has a 1.5-second reload indicator; PreviousSelf uses its own supplied character art with scripted movement/attack animation. The Hollow Warden uses its supplied idle, movement, and attack frames with visible, above-floor attack telegraphs.
- Normal rooms fill a centered `TileMapLayer` with stable atlas selections from the upper-dungeon floor tileset on Floors 1–4 and the deep-dungeon floor tileset on Floors 5–10. Supplied wall torches add environmental detail, and the locked door swaps to its open artwork after a normal room is cleared. Boss rooms retain their dedicated arena artwork. The smoke test checks the floor source, coverage, doors, torches, and boss-room visibility.
- Milestone 7 added four layouts, visible/collidable cover, an obstacle-free final boss arena, combat stat guardrails, imported visual effects for damage/healing/death/boss attacks/grave emergence/transitions, and exit monitoring that is disabled during combat. Re-run the smoke test after visual-effect changes; check [docs/TESTING.md](TESTING.md) for remaining device-level validation.
- Re-run the integration suite after each milestone before marking that milestone complete.
- The latest full integration passed a fresh disposable-copy resource import and smoke test under Godot 4.7.1, including the scaling, inventory, joystick, and boss-skill mechanics. The target Godot 4.7.2 executable path recorded in `.godot/editor/project_metadata.cfg` is unavailable in this environment; repeat the same test under 4.7.2 and perform manual device/UI checks before release.
