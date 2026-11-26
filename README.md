# OJB Test Hub

A small, self-contained Roblox test hub: one loadstring, one Rayfield window, a
handful of client-side features. Built as a test bench for the loader + repo
pipeline, not as a production cheat.

The release artifact is a single Luau file, so the executor only ever fetches
one URL.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_GITHUB_USER/ojb-test-hub/main/release/ojb-test-hub.lua"))()
```

Swap `YOUR_GITHUB_USER` for the account you push to. The raw URL must point at
`release/`, never at `src/` — `src/` is modules, not a chunk.

## What's in the window

| Tab | Element | Backing code |
| --- | --- | --- |
| Player | Walk Speed slider (8–300) | `Humanoid.WalkSpeed`, reapplied on respawn |
| Player | Jump Power slider (50–500) | `Humanoid.JumpPower` with `UseJumpPower` |
| Player | Fly toggle + speed | `BodyVelocity` on the root, camera-relative WASD, Space/Ctrl vertical |
| Player | NoClip toggle | `Stepped` sweep over character parts, originals restored on disable |
| Player | Infinite Jump toggle | `JumpRequest` → `HumanoidStateType.Jumping` |
| Player | Reset Character | `Humanoid.Health = 0` |
| Visuals | Player ESP + color | `Highlight` per character, `AlwaysOnTop`, local-only instances |
| Visuals | Fullbright | Lighting overrides with a stored snapshot |
| Teleport | Save / go / list waypoints | `Camera.CFrame` snapshots, `Model:PivotTo` |
| Teleport | Teleport to player | dropdown fed from `Players:GetPlayers()` |
| Misc | Anti-AFK | `VirtualUser:ClickButton2` on `Idled` |
| Misc | Rejoin server | `TeleportService:Teleport` |
| Misc | Test notification | Rayfield notify round-trip |
| Misc | Destroy UI | unloads features, drops the window |
| Config | Save / Load | primitives to `OJBS-TestHub/settings.json` via `writefile` |

Every toggle is wired to a module function — the UI layer holds no logic beyond
element → module calls.

## Repo layout

```
ojb-test-hub/
├── loadstring.lua            # executor entry point (edit the owner)
├── release/ojb-test-hub.lua  # generated bundle — this is what gets served
├── src/
│   ├── init.lua              # registry bootstrap, _G.OJB_TestHub lifecycle
│   ├── util.lua              # player / character / part lookups
│   ├── config.lua            # defaults, live values, disk persistence
│   ├── ui.lua                # Rayfield window and every element
│   └── features/
│       ├── player.lua        # speed, jump, fly, noclip, infinite jump
│       ├── esp.lua           # Highlight ESP
│       ├── teleport.lua      # waypoints and player movement
│       └── misc.lua          # fullbright, anti-AFK, rejoin
├── scripts/
│   ├── build.py              # inlines src/ into the release bundle
│   └── check.py              # block-balance sanity check
└── docs/FEATURES.md
```

## Build

```bash
python scripts/build.py   # writes release/ojb-test-hub.lua
python scripts/check.py   # structural check, exits non-zero on imbalance
```

`build.py` wraps each module in a factory and registers it under a fixed order:

```
util → config → features/player → features/esp
     → features/teleport → features/misc → ui → init
```

A module may only `__require` names that come before it. `init` runs last and
returns the handle stored in `_G.OJB_TestHub`, so re-executing the loadstring
tears down the previous instance instead of stacking a second window.

## Pushing it

```bash
git init -b main
git add .
git commit -m "test hub: loadstring, rayfield ui, features"
git remote add origin https://github.com/YOUR_GITHUB_USER/ojb-test-hub.git
git push -u origin main
```

Then edit `YOUR_GITHUB_USER` in `loadstring.lua` and README, and run the line in
an executor (Delta, Wave, Solara, AWP — anything with `loadstring`, `HttpGet`,
`writefile`).

## Notes

- **Rayfield is fetched at runtime** from `https://sirius.menu/rayfield`. It is
  the only external dependency; the repo serves everything else. Pinning to a
  mirror means swapping `RAYFIELD_URL` in `src/ui.lua` — the official loader is
  the only copy that stays current.
- **The GUI is third-party.** Rayfield is [SiriusSoftwareLtd/Rayfield](https://github.com/SiriusSoftwareLtd/Rayfield),
  MIT-licensed, and its loader pulls the latest release on every execution. A
  library update can move an element API before this repo catches up; that is
  the tradeoff for not vendoring 5k lines.
- **Client-side only.** `WalkSpeed`, `Fly`, `NoClip` and `ESP` are local
  changes. Any game that authoritatively validates movement will snap you back
  or flag it. There is no anti-cheat bypass in this repo and none is planned.
- **`writefile` is optional.** Executors without filesystem access still run;
  Save/Load just reports "executor exposes no filesystem".
- **The `Highlight` ESP is local-only** by construction — the instances are
  created on the client and never replicate. Parenting tries `CoreGui` first and
  falls back to `workspace.CurrentCamera`.
- **`Fly` uses `PlatformStand`**, so the humanoid stops responding to the game's
  own movement while flying. Disabling restores it; dying while flying reattaches
  the velocity on respawn.
- **Config persists primitives only.** `Color3` values reset each session by
  design; JSON has no color type.

## License

MIT — see [LICENSE](LICENSE).
