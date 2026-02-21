# Killer Walls - Game Development Plan

## 1. Environment & Setup (Indoors)
- **Structure:** The game takes place in an enclosed hallway. The floor, ceiling, and side walls will be procedurally generated to match the length required for 19 walls.
- **Lighting:** Dark, indoor ambiance (low brightness, dark fog) with the walls providing localized neon illumination to create an intimidating atmosphere.

## 2. Wall Generation & Probability Logic
- **Wall Placements:** Generates exactly 19 walls spaced evenly along the hallway.
- **Killer Logic:** 
  - Each wall has `Touched` event logic.
  - The base death probability for Wall 1 is 5% (`0.05`).
  - Each subsequent wall increases the death probability by 5%.
  - Wall 19 will have a 95% death probability.
  - We will track which walls a player has already crossed during their current life to prevent multiple triggers on a single wall passage.

## 3. Spawning & Orientation
- **Initial Spawn Location:** The main SpawnLocation will be placed at the start of the hallway.
- **Orientation:** To ensure the player is facing the first wall on spawn, we will either calculate and apply the correct orientation to the `SpawnLocation.CFrame` (if Roblox's default spawning allows), or upon the `CharacterAdded` event, explicitly set the character's `PrimaryPart.CFrame` to look toward the end of the hallway (e.g., looking down the positive/negative Z-axis, depending on corridor orientation).

## 4. Checkpoint System
- **Checkpoint Placement:** We will generate invisible or visible checkpoint pads in the safe zones between each of the 19 walls. 
- **Tracking Progress:**
  - The server will maintain a `playerCheckpoints` dictionary `[UserId] -> CheckpointNumber`.
  - When a player touches a checkpoint pad, we verify if its number is strictly greater than their currently saved checkpoint number. If so, we safely update their saved checkpoint.
- **Respawn Logic:**
  - When `Player.CharacterAdded` fires, we retrieve their highest saved checkpoint.
  - Instead of spawning at the beginning, we will teleport the character's `HumanoidRootPart.CFrame` to the CFrame of their latest checkpoint pad + a height offset.
  - Just like the initial spawn, the respawn CFraming will ensure their character is correctly oriented to face the *next* wall.

## 5. Win Condition
- **Victory Pad:** A distinct, green neon pad is placed after the 19th wall.
- **Completion:** Touching this pad will announce the player's victory to the server, and could optionally reset their progress if they wish to play again.
