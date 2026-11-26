# Features

Every feature is a module function; the UI only forwards element events.

## player.lua

| Function | Effect |
| --- | --- |
| `setWalkSpeed(n)` | Writes `Humanoid.WalkSpeed`, stores the value in config. |
| `setJumpPower(n)` | Forces `UseJumpPower = true`, then writes `JumpPower`. |
| `setFly(bool)` | Builds a `BodyVelocity` (max force `1e5` per axis) on the root, sets `PlatformStand`, and drives velocity each `RenderStepped` from camera-relative WASD + Space/Ctrl. Rebuilds the attachment if the character respawns mid-flight. |
| `setNoClip(bool)` | `Stepped` sweep sets `CanCollide = false` on every character part; originals are recorded and restored when disabled. |
| `setInfiniteJump(bool)` | `JumpRequest` forces `HumanoidStateType.Jumping` while alive. |
| `resetCharacter()` | `Health = 0`. |
| `bind()` | `CharacterAdded` re-applies speed, jump and any enabled fly/noclip. |

Fly input is read with `UserInputService:IsKeyDown` — it will not fire while a
text box has focus, which is the behavior you want in a Rayfield window.

## esp.lua

`Highlight` per other player, `DepthMode = AlwaysOnTop`, fill transparency 0.55.
A `Heartbeat` sweep attaches/detaches as players join, leave, respawn or lose
their character. Instances live under a `DoloHook_ESP` folder — `CoreGui` first,
`CurrentCamera` as fallback.

## teleport.lua

Waypoints are `Camera.CFrame * CFrame.new(0, 0, -6)` — six studs ahead of the
camera, so a saved point never lands inside the wall you were looking at.
Player teleport pivots to the target root plus three studs on Y.

## misc.lua

- **Fullbright** snapshots `Ambient`, `OutdoorAmbient`, `Brightness`, `ClockTime`,
  `FogEnd`, `GlobalShadows` and restores all six on disable.
- **Anti-AFK** fires `VirtualUser:ClickButton2` from `Idled`.
- **Rejoin** calls `TeleportService:Teleport(game.PlaceId, LocalPlayer)`.

## config.lua

`defaults` is the single source of truth for initial element values. `save()`
skips `Color3` and instance values (JSON has no type for them), `load()` only
applies keys whose type matches the default.

## Failure modes

| Symptom | Cause |
| --- | --- |
| "failed to build UI" in console | `sirius.menu` unreachable, or the loader changed shape. |
| Fly does nothing | Character has no `HumanoidRootPart` yet — respawn and toggle again. |
| Game snaps movement back | Server-side position validation; client features cannot win that. |
| ESP missing players | Player joined while ESP was off; toggle to re-sweep. |
| Load Settings does nothing | Executor has no `readfile`/`isfile`, or no file saved yet. |
