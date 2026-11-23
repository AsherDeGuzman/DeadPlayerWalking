# Dead Player Walking

A self-contained, landscape-first 2D action roguelike built for **Godot 4.7.2-stable (Windows x64)**. The supplied artwork is stored in `ASSETS/` and used directly by the scenes and scripts; no add-ons are required.

## Open and play

1. In Godot 4.7.2, choose **Import**.
2. Select this folder's `project.godot` file.
3. Open the project and press **F6** or **F5**.

The project is configured for a 1280 × 720 landscape viewport and the GL Compatibility renderer. The same project also runs on desktop for testing.

## Scene files in Godot

In the Godot **FileSystem** dock, expand `scenes` and open each `.tscn` file to inspect that scene's tree. Scenes are grouped by purpose:

```text
scenes/
|-- core/        main.tscn and level01.tscn
|-- actors/      player.tscn, basic_enemy.tscn, previous_self.tscn
|-- ui/          hud.tscn
|-- dungeon/     room.tscn, boss.tscn, echo_grave.tscn, healing_pickup.tscn
`-- projectiles/ crossbow_projectile.tscn
```

`main.tscn` contains `Main > RunManager` and an instanced `Level01` scene, so the gameplay hierarchy is visible in the editor even while the title menu is active. The profile chooser and tutorial controls, spotlight, and pointer are authored in this scene tree. The reusable room scene authors its ordinary enemy slots, boss slot, three PreviousSelf slots, three grave markers, and collision nodes. Room scripts configure those saved nodes rather than creating echo or grave nodes at runtime. See [`scenes/README.md`](scenes/README.md) for a scene-by-scene guide.

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD or arrow keys | Virtual stick at lower left |
| Attack with equipped weapon | Space or J | Attack button at lower right |
| Lock ranged target | Click an enemy | Tap an enemy |
| Switch weapon | Q | SWAP button above DASH |
| Dash / dodge (3-second cooldown) | Shift or K | DASH button at lower right |
| Use a potion; at an unlocked exit, leave | E or Enter | USE button at lower right |
| Pause / resume | Escape or P | II button at the top-right |

Movement and actions can be used together. Character walk cycles adjust to movement speed, while the Dungeon Edge only damages enemies during its active swing frames and uses a sweeping slash and expanding impact. The Warden Crossbow automatically aims at the nearest enemy in range; click or tap an enemy to lock on to that target, shown by a marker beneath it. Bolts leave a colored trail and burst on impact. Each weapon has its own cooldown. The dash grants a brief window of invulnerability and has a 3-second cooldown; the DASH touch button displays the remaining time and a shrinking cooldown ring.

The main character uses the supplied idle, walk, melee attack, ranged attack, hurt, dodge, and death animation strips in `ASSETS/PLAYER ASSETS/`, with the supplied damage flash on hit. Four-way movement uses matching front, left-side, right-side, and back-facing poses from the supplied direction reference without rotating the character; walk-cycle playback follows movement speed. The supplied Dungeon Edge sword and Warden Crossbow are attached to a hand-level pivot and use the matching supplied swing and firing poses during attacks; their inventory icons appear in the HUD. Normal rooms use the supplied upper/deep wall atlases, locked dungeon doors and door-state effects until enemies are defeated, then open the doorway; wall torches and room props add environmental detail. Enemy death bursts, animated healing pickups and their collection effect, boss auras and directional telegraphs, and the Floor 5 entrance/atmosphere use the supplied `ASSETS/` artwork. Menu, result-screen, and upgrade icons also use their supplied art. Dungeon floor tiles crop the atlas gutters for seamless coverage, and ordinary enemies collide with one another and the crate footprint; enemy draw order shifts behind or in front of crates based on position so the props no longer appear passable. Weapon behavior is configurable in `resources/weapons/`; the standalone crossbow projectile scene owns its movement, collision, damage, impact, and cleanup.

The gameplay camera follows the player without per-room screen locks. Connected rooms extend upward through world space as the player clears each exit, so movement into deeper rooms scrolls the map continuously; one cleared room remains visible behind the player during transitions.

Procedurally synthesized looping themes change between the title, cleared-room exploration, active combat, boss encounters, defeat, and victory. Sound cues cover attacks and impacts, crossbow fire, damage/death, healing, door locks, weapon switching, boss entrances/attacks, upgrades, UI actions, and run outcomes. Missing audio files are replaced with runtime-generated PCM streams, and audio pauses with the pause menu.

On launch, choose a saved username or create a new profile before reaching the title menu. Each profile saves its own runs, scrap, upgrades, Previous Selves, and mandatory-tutorial completion; new profiles start with no progress, and existing single-player saves are migrated to a `Survivor` profile. Each character sees the dynamic tutorial the first time they click ENTER THE DUNGEON. After completing it, later entries start directly; HOW TO PLAY remains available to replay it. The tutorial runs over a paused first-room preview, with a spotlight and pointer guiding players through health, controls, weapons, dash, potions, a live enemy, and the exit. NEXT advances each step, START RUN launches a fresh attempt, and EXIT TUTORIAL returns to the title without counting a run. Potion pickup and successful-use notices fade after two seconds. The title menu includes Settings and Exit. Settings control and persist ambience/effects volume. Pausing freezes gameplay and audio; the pause menu can resume, open settings, or return to the title after confirming that the attempt will be recorded as a defeat. HUD and touch controls scale to landscape viewports; action labels sit within their buttons, and the USE slot shows the healing-potion icon and stack count only while potions are carried. The virtual joystick, attack, swap, dash, and contextual USE control are checked at multiple viewport sizes. The joystick thumb also mirrors WASD movement.

## Dungeon progression

The run now spans ten configurable floors and 38 deterministic combat rooms. Floors 1–4 use the upper-dungeon palette; floors 5–10 use deep-dungeon palettes. Room counts and enemy pressure rise with depth. Normal rooms cycle through four deterministic obstacle layouts with visible, collidable cover; the Floor 10 boss arena stays open. Each floor has one authored, non-random potion pickup in a regular combat room. Pickups stack in the USE inventory; using one restores up to 25% of maximum health without filling the player to full. The same USE action exits a cleared room when the player is at its door. Each room is a reusable scene: enemies lock the exit, clearing all enemies unlocks it, and entering the exit plays an animated room or floor transition before loading the next connected room.

Deaths save a compact snapshot of the character’s stats, weapon archetypes, floor, room, and room-local position—not a replay of recorded actions. On later runs, up to three stronger previous selves emerge from authored grave markers at those saved death locations; each has 1.5× its source's health and damage and 1.15× its movement speed. Previous Selves keep their own supplied character artwork, enlarged and flipped as they pursue with a subtle movement/attack animation. Each entered room adds 1% of the player's current health, attack damage, and movement speed to every non-boss mob, cumulatively; permanent upgrades also raise mob stats by 0.3% per purchased level. Melee mobs move at 1.4× their archetype speed. The player's Warden Crossbow has a 1.5-second post-shot reload, shown by a progress bar beside the character; mob archers do not use this player reload indicator. Floor 5 is a regular floor rather than a fixed PreviousSelf encounter. The Floor 10 Hollow Warden has 5× the player's maximum health and deals one-fifth of it as damage; three attacks use bright beam, ground-circle, and cone telegraphs drawn above the floor to signal dodge windows. Defeating the Warden completes the run. The controlling design is [Dead_Player_Walking_GDD_Token.pdf](docs/Dead_Player_Walking_GDD_Token.pdf).

Each cleared floor awards 30 scrap; the Floor 10 boss adds 100. Death awards 10 scrap. Permanent character upgrades cost 20 scrap for +10 maximum HP, 25 for +2 base attack damage, and 20 for +10 movement speed. Dungeon Edge and Warden Crossbow upgrades cost 30 scrap per level, add 12% damage, and cap at level 5.

## Save data and validation

Progress is written to Godot's per-user `user://dead_player_walking.cfg` file. It is separate from the project folder.

No source audio files are included in this project copy, so all music themes and sound cues use runtime-generated PCM fallbacks. Music is selected by game state: menu, exploration, combat, boss, death, or victory.

The supplied GDD is included at `docs/Dead_Player_Walking_GDD_Token.pdf`. Its Sections 8.4 and 8.5 are intentionally left for the scene-tree and signal-wiring plan based on this implementation.

To run the included headless integration check without touching your normal save, first copy the project to a temporary folder and give the test copy a different application name:

```powershell
$testProject = Join-Path $env:TEMP "DeadPlayerWalking-SmokeTest"
$projectName = "Dead Player Walking Smoke Test " + [guid]::NewGuid().ToString("N")
New-Item -ItemType Directory -Force -Path $testProject | Out-Null
Copy-Item -Path ".\project.godot", ".\icon.svg", ".\scenes", ".\scripts", ".\ASSETS", ".\resources", ".\tests" -Destination $testProject -Recurse -Force
$projectFile = Join-Path $testProject "project.godot"
$config = [System.IO.File]::ReadAllText($projectFile).Replace('config/name="Dead Player Walking"', ('config/name="' + $projectName + '"'))
[System.IO.File]::WriteAllText($projectFile, $config, [System.Text.UTF8Encoding]::new($false))
$godot = "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --editor --path $testProject --quit
if ($LASTEXITCODE -eq 0) { & $godot --headless --path $testProject --script "res://tests/smoke_test.gd" }
$testExitCode = $LASTEXITCODE
$testSave = Join-Path $env:APPDATA ("Godot\app_userdata\" + $projectName)
if (Test-Path -LiteralPath $testSave) { Remove-Item -LiteralPath $testSave -Recurse -Force }
Remove-Item -LiteralPath $testProject -Recurse -Force
exit $testExitCode
```

The test exercises legacy-save migration, creation and disk reload of independent username profiles, the tutorial-before-run flow, the actual title/settings/workshop/pause flows, saved audio levels, upgrade affordability, responsive menu/touch-control layouts, WASD joystick feedback, stacked potions and conditional USE-button icon/count display, all ten floor definitions, deterministic room layouts, locked and cleared exits, animated room/floor transitions, floor and boss rewards, per-room stat scaling, melee mobility, the player's crossbow reload timing/feedback, enlarged PreviousSelves using their original art, all three high-visibility boss AOE telegraphs and dodge checks, timed melee hitbox, collision-based player and echo projectiles, saved death locations, grave emergence and echo combat, the regular Floor 5 flow, the dynamic Floor 10 boss, final-boss victory, and permanent upgrades. See [docs/TESTING.md](docs/TESTING.md) for known limitations and remaining device-level validation.
