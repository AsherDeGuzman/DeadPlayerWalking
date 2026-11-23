# Project Structure

The project keeps the existing scene and script layout because its reusable actors, dungeon rooms, and progression systems already map cleanly to the game's responsibilities. Canonical source art remains in `ASSETS/` and is referenced directly; exact duplicate copies were removed without changing gameplay assets.

```text
ASSETS/
|-- BOSS ASSETS/
|-- DUNGEON ENVIRONMENT ASSETS/
|-- Floor 5 Reveal Cutscenes/
|-- ORDINARY ENEMY ASSETS/
|-- PICKUPS AND GAMEPLAY ASSETS/
|-- PLAYER ASSETS/
|-- UI ASSETS/
|-- VISUAL EFFECTS ASSETS/
`-- WEAPON ASSETS/
scenes/
|-- actors/
|-- core/
|-- dungeon/
|-- projectiles/
`-- ui/
scripts/
|-- dungeon/
|-- weapons/
`-- core gameplay and UI scripts
resources/
|-- enemies/
|-- dungeon/
`-- weapons/
docs/
tests/
```

## Ownership

- `scenes/core/main.tscn` is the project entry point. Its `Main` root owns the run manager and the preloaded level scene.
- `scenes/core/level01.tscn` is the run's gameplay composition: player, HUD, room container, and an editor-visible preview room.
- `scenes/actors/` contains the reusable player, ordinary enemy, and previous-self scenes. The player scene authors its healing-use effect.
- `scenes/dungeon/` contains the reusable room, healing pickup, boss, and authored grave-marker scenes. The room authors the potion collection effect; the boss authors separate beam, target-circle, and sweep-cone telegraphs.
- `DungeonRoom` uses a `FloorLayer` `TileMapLayer` for its deterministic upper/deep dungeon floor atlas, supplied locked/open door states and wall torches; boss rooms keep their dedicated arena background.
- `scenes/dungeon/room.tscn` exposes six ordinary-enemy slots, a boss slot, three PreviousSelf slots, and three grave slots in the saved Scene Dock tree. Room logic configures these placeholders rather than dynamically creating echo/grave nodes.
- `scenes/actors/player.tscn` authors the crossbow reload progress bar shown beside the player; mob archer scenes do not contain this indicator.
- `scenes/actors/previous_self.tscn` keeps the supplied PreviousSelf character artwork, which is enlarged and animated by its movement script.
- `BasicEnemy` and `DungeonBoss` scenes use supplied sprite sheets for animated combat states; previous selves retain their corrupted-player portrait.
- `RunManager` persists each death's floor, room, and room-local position so a later run places that PreviousSelf at its grave site instead of a fixed floor.
- `resources/enemies/` configures the deterministic skeleton, aggressive-creature, and ranged-archer archetypes and their combat tuning.
- `scenes/projectiles/` contains the independent crossbow projectile scene.
- `scenes/ui/` contains the HUD CanvasLayer and its `UI > Screen` grouping, including the authored animated floor-transition subtree.
- `scripts/` separates player, enemy, run, room, weapon, audio, HUD, and touch-control behavior.
- `resources/dungeon/`, `resources/enemies/`, and `resources/weapons/` hold configurable floor, enemy, and weapon data.
- `tests/smoke_test.gd` is the integration test for the playable run.

No audio source files are present in this project copy; `AudioManager` synthesizes runtime fallback streams. Character, weapon, pickup, boss, screen, dungeon-wall, door, and gameplay-effect artwork is loaded directly from the supplied capitalized `ASSETS/` source folders. Static player/enemy design sheets and the standalone healing-pickup image are retained as reference/alternate artwork while the matching animation sheets are used in game.

## Structural guardrails

- Keep reusable gameplay behavior in actor or room scripts rather than adding it to `Main`.
- Keep run-level transitions and persistent progression separate from room combat.
- Preserve the `Main > Level01` composition and the nested HUD grouping unless a tested change updates all dependent node paths.
- Do not move or duplicate supplied source images just to normalize their names; use explicit resource paths.
