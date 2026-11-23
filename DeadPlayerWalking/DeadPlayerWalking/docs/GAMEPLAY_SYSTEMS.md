# Gameplay Systems

## Run and progression

`Main` (`scripts/main.gd`) presents a profile chooser before the title, followed by settings, workshop, pause, and run-result screens. Its `RunManager` child (`scripts/run_manager.gd`) stores currency, attempts, upgrades, and PreviousSelf records independently by username; new profiles start at zero, and an older single-profile save is migrated to `Survivor`. The project autoload `AudioManager` owns music and sound playback.

The audio manager selects separate looping menu, exploration, combat, boss, death, and victory themes from game-flow events. It also provides separate cues for melee and projectile attacks/impacts, enemy hits, healing, door states, weapon switching, boss entrances/attacks, upgrades, and UI actions. Missing audio assets use generated PCM fallbacks; music and sound-effect volume settings persist, and gameplay audio pauses with the pause menu. The gameplay level explicitly uses the pausable process mode so its player, enemies, physics, and animations stop while the always-responsive menu remains available.

`Level01Controller` (`scripts/level01.gd`) coordinates a run: it configures the player, tracks floor and room progression, creates encounters, updates the HUD, and reports run outcomes to `Main`. Floor definitions in `resources/dungeon/` provide the ordered deterministic room counts, themes, enemy pressure, healing location, and boss configuration.

Each purchased permanent upgrade level multiplies ordinary mob and PreviousSelf health, damage, and speed by 1.003. For every room entered, each non-boss mob also gains 1% of the player's current maximum health, attack damage, and movement speed, cumulatively from run start. Melee archetypes move at 1.4× their configured pursuit speed; ranged archetypes keep their configured speed.

## Combat

- `RunnerController` (`scripts/player.gd`) handles movement, health, melee timing, weapon switching, dodge, and the player's run snapshot.
- Dash grants a brief invulnerability window, then enters a 3-second cooldown. The touch DASH button overlays the remaining seconds and a shrinking ring, driven by the same player cooldown timer.
- The player's Warden Crossbow applies a 1.5-second post-shot reload and displays its countdown beside the character; melee weapons and mob archers do not use this player reload indicator.
- Player and enemy walk cycles scale their playback rate with movement speed. Previous Selves retain their own supplied character artwork, enlarged to 140 pixels high, flipped to face pursuit, and animated with a subtle bob/lean while moving and attacking. Crossbow bolts leave a short colored trail and expand into the supplied impact art on collision; boss auras pulse and telegraphs intensify during the attack wind-up.
- Player facing uses distinct supplied front, left-side, right-side, and back-facing poses; the character does not rotate. The equipped weapon follows the selected direction and movement.
- Crossbow shots automatically aim at the nearest enemy within range. Tapping or clicking an enemy locks the target until another enemy is selected or the locked enemy is defeated.
- `WeaponConfig` resources in `resources/weapons/` define weapon-specific cooldowns, damage multipliers, melee timing, and projectile behavior.
- `CrossbowProjectile` (`scripts/weapons/crossbow_projectile.gd`) owns projectile motion, collision, impact, and cleanup.
- `FacilityEnemy` (`scripts/enemy.gd`) handles ordinary and previous-self pursuit, attacks, damage, and defeat.
- `EnemyArchetype` resources in `resources/enemies/` configure the skeleton melee fighter, aggressive dungeon creature, and ranged archer, including stats, detection, attack range/cooldown, and animation profile. Rooms assign these archetypes in a deterministic floor/room order.
- `DungeonBoss` (`scripts/dungeon/dungeon_boss.gd`) scales to five times the current player's maximum health and deals one-fifth of that maximum as damage. Its rotating Rift Volley, Sigil Burst, and Sanguine Sweep attacks telegraph a bright beam lane, marked circle, or directional cone above the floor layer using the supplied boss-telegraph artwork.
- `DungeonRoom` (`scripts/dungeon/room.gd`) configures authored enemy, boss, PreviousSelf, and grave slots; it counts active enemies, keeps the exit locked until the last defeat, and emits room/floor progression signals.

Previous-self records preserve character stats, weapon archetypes, and the floor/room/local position where the player died. Up to three saved selves emerge from their authored grave slots when a later run reaches those locations; they retain their own supplied character artwork, 1.5× health/damage and 1.15× speed snapshot bonuses, then receive the same cumulative room-entry stat bonus as other non-boss mobs. Records do not store movement, action, or route histories. Floor 5 is a regular floor, not a fixed PreviousSelf encounter.

Healing pickups add stackable potions to the player inventory instead of healing on contact. Pressing USE consumes one potion for up to 25% maximum health; at an unlocked exit, USE prioritizes leaving the room. The potion count is shown on the touch USE button, and the player-authored healing effect plays on use.

## UI and input

The profile chooser and tutorial overlay are authored in `scenes/core/main.tscn`. Each profile stores its own entry-tutorial completion state. The first ENTER THE DUNGEON opens a frozen first-room preview with a moving spotlight and pointer; NEXT walks through the HUD, player, action controls, a named live enemy, and the exit. Completing the tutorial records the state for that profile, so later dungeon entries start directly. HOW TO PLAY always reopens the guide. START RUN discards the preview and starts a fresh attempt, while EXIT TUTORIAL returns to the title without recording a run. The HUD scene is `HUD (CanvasLayer) > UI (Control) > Screen (Control)`. The animated floor-transition backdrop, portal, curtains, title, and subtitle are authored under `Screen > FloorTransition`; `scripts/hud.gd` creates the other HUD controls, and `scripts/touch_controls.gd` handles the virtual joystick and action controls. Touch action labels are centered inside their artwork, and the USE slot displays the supplied healing-potion icon and stack count only when inventory is nonempty. The joystick thumb mirrors keyboard movement without feeding that input back into player motion. Potion pickup/use notices disappear after two seconds. Floor changes use the longer animated transition; room changes use a shorter fade.

## Supplied art

Gameplay and menu visuals use images directly from `ASSETS/`: player, skeleton, dungeon-creature, archer, and boss animation sheets; weapon and previous-self art; grave-marker and healing-pickup art; menu/result backgrounds; and the supplied boss-arena background. Normal rooms use deterministic `TileMapLayer`s backed by the supplied upper-dungeon and deep-dungeon floor atlases; floors 1–4 use the upper theme, and floors 5–10 use the deep theme. Since no audio files are present in this project copy, `AudioManager` generates context-specific PCM music loops and sound cues at runtime. See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for the full organization.

## Validation

`tests/smoke_test.gd` exercises the entry scene and the complete ten-floor progression, including combat, room locks, rewards, healing, death-location persistence, grave-bound PreviousSelf emergence, animated transitions, the final boss, save flow, menus, and responsive touch controls. Run it in a disposable project copy using the procedure in [TESTING.md](TESTING.md).
