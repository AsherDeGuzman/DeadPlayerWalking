# Scene Files

Open the `.tscn` files from this folder in Godot to inspect each saved scene tree. These files are organized into folders by their role in the game:

```text
scenes/
|-- core/
|   |-- main.tscn
|   `-- level01.tscn
|-- actors/
|   |-- player.tscn
|   |-- basic_enemy.tscn
|   `-- previous_self.tscn
|-- ui/
|   `-- hud.tscn
|-- dungeon/
|   |-- room.tscn
|   |-- boss.tscn
|   |-- echo_grave.tscn
|   `-- healing_pickup.tscn
`-- projectiles/
	`-- crossbow_projectile.tscn
```

## Which scene to open

- `core/main.tscn` is the project entry scene. Its single root is `Main (Control)`, with `RunManager (Node)` and an instance of `Level01 (Node2D)` beneath it.
- `core/level01.tscn` contains `Rooms (Node2D)` with a room instance, an instance of `Player (CharacterBody2D)`, and an instance of `HUD (CanvasLayer)`.
- Expand `Level01 > Player` to inspect the player body and melee collision shapes.
- Expand `Level01 > Rooms > DungeonRoom > WorldGeometry` to inspect the room boundary, exit gate, and all six obstacle collision nodes. Expand `ExitTrigger` and `HealingPickup` to inspect their area collision shapes.
- `actors/player.tscn` shows the player body, sprites, melee hitbox, authored damage/healing effects, and camera.
- `actors/player.tscn` also authors the crossbow reload progress bar displayed beside the player after a shot.
- `actors/previous_self.tscn` retains the supplied PreviousSelf character art, enlarged and animated with movement/attack motion at runtime.
- `ui/hud.tscn` is the HUD CanvasLayer with a full-rect `UI` control containing a full-rect `Screen`. Its floor-transition backdrop, portal, title, and curtains are authored under `HUD > UI > Screen > FloorTransition`; other HUD controls are built by the HUD script.
- `dungeon/room.tscn` is the reusable room root. It contains the six ordinary-enemy slots, boss slot, authored boss AOE telegraphs, three `PreviousSelf` slots, three grave-marker instances, healing pickup, potion collection effect, and collision geometry in the saved scene tree. The room script configures and activates these nodes for each encounter.
- `dungeon/echo_grave.tscn` contains the supplied stone grave-marker artwork used at a saved death position.

The project starts at `core/main.tscn`. `Level01` is saved as a child of `Main`, but is not visible in-game until a run begins. The room's six obstacle collision nodes and all enemy/echo/grave placeholders are saved in the room scene; encounter scripts only enable and configure the required slots. Open `actors/basic_enemy.tscn`, `actors/previous_self.tscn`, and `dungeon/boss.tscn` to inspect each actor's own collision shape.
