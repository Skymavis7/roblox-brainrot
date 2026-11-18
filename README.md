# Brainrot Lagoon — a 3D Roblox brainrot game

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Skymavis7/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Skymavis7/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Lagoon** is my entry for make.fun's "Make the best AI Roblox brainrot game"
bounty (roblox-brainrot-01). You spawn on a lagoon island, buy absurd meme-born
characters off the weirdo conveyor, carry them home to your base, and watch the cash
tick up — while other players try to steal them and a Noodle Tsunami sweeps the map
every 100 seconds.

## The game

**The cast (12 original characters, 6 rarities)** — Soggy Sock Sam, Toaster Terry and
Chairman Chair (Common); Banana Bus Barry, Sir Puddles III and DJ Fridge (Rare);
Captain Crunchwrap and The Forbidden Leftovers (Epic); Quantum Pickle and El Gato WiFi
(Legendary); Grandma's Router (Mythic); Chungus Prime (Secret). Each earns $/s and has
its own buy cost, body shape, accessory and joke. Mutations (Frozen x2, Golden x3,
Spicy x5, Rainbow x8) roll on spawn.

**The loop**
1. Brainrots walk the conveyor west to east. Buy one with its prompt (hold E).
2. It follows you home. Step onto your base and it hops onto a free slot and starts
   earning $/s — your cash ticks up every second.
3. Climb the ladder: rarer brainrots cost more and earn more. Rebirth at $100k (cost
   doubles each time) for +50% income forever. Shop upgrades: Speed Boots, Double
   Scoop income, 4 extra base slots.
4. **Stealing:** brainrots on an unlocked base can be stolen — the thief must run home
   before the owner slaps them (F key / SLAP button) and makes the brainrot run back.
   Lock your base for 60s (L key / LOCK BASE button, 120s cooldown).
5. **The Noodle Tsunami:** every 100s a 10s warning sounds, then a giant pink wave
   sweeps the map north to south. Anyone caught outside their own base is flung back
   to spawn and drops what they were carrying.

**The world** — a 3D lagoon island built from real Roblox parts: water, sand, grass,
a conveyor across the middle, six coloured player bases with 8 slot pads each, the
Weirdo Mart, the Rebirth Portal, trees, lamps, clouds and the tsunami wall. Signs are
BillboardGuis hung at runtime by `WorldBuilder`. The HUD is a ScreenGui over the 3D
world: cash / income / rebirths, the tsunami countdown banner, action buttons, the
character catalog and upgrade shop, and toast notifications. The player moves in 3D
with WASD and the camera; the game is not drawn on a flat screen.

## Layout

- `main.ts` (Node 22, stdlib only) — hands the entry in: copies `game.rbxl`, `src/`,
  `screenshots/`, `PLAY.json` to `/output` and writes `dossier.json`.
- `vendor/makefun-roblox.ts` — the kit's copy, unchanged.
- `game.rbxl` — the place, built with Rojo (see below).
- `src/` — every script of the place, as `.luau` files:
  - `src/shared/` — `BrainrotCatalog` (cast, rarities, mutations), `GameConfig` (tuning, map layout)
  - `src/server/` — `init` (bootstrap), `PlayerData` (the one source of truth for
    player state), `ConveyorService` (spawn, walk, buy, carry, place), `BaseService`
    (bases, slots, locks), `StealService` (stealing, slapping), `WaveService` (the
    tsunami), `MoneyService` (the 1-second income tick), `RebirthService` (rebirths,
    upgrades, base lock), `DataService` (DataStore saves), `BrainrotFactory` (builds
    the 3D character models), `WorldBuilder` (signs)
  - `src/client/` — `Hud` (the ScreenGui: top bar, wave banner, buttons, catalog,
    shop, toasts), `Effects` (wave flash, camera shake, gold place flash)
- `screenshots/` — 4 preview renders (see Honest limits below); `1-thumbnail.jpg`
  is the cover and the picture to upload as the game's first thumbnail on Roblox.
- `TOUR.json` — the optional reviewer tour.
- `tools/` — `gen-project.mjs` (generates `default.project.json`, the map),
  `render-screenshots.py` (renders the screenshots), `inspect-place.mjs` (dumps the
  built place for verification).

## Build

```sh
node tools/gen-project.mjs
rojo build default.project.json --output game.rbxl   # Rojo 7.7.1
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Verified: Rojo builds clean; the place holds 155 instances and 15 scripts, and
`src/` matches 100% of the place's script bytes (checked with the vendored reader).
All 15 scripts compile with the real Luau compiler (luau 0.747).

## Honest limits

1. **Roblox Studio does not run on this Linux VM**, so the game could not be
   play-tested in Studio and no Studio captures exist. The screenshots are faithful
   **preview renders** of the game's own world and characters — drawn from the same
   map layout (`GameConfig`) and the same character catalog (`BrainrotCatalog`) — and
   each is labelled "PREVIEW RENDER — not a Studio capture". They are not faked
   Roblox client screenshots.
2. **The game is not published yet.** Publishing needs the human's Roblox account
   (2+ days old, age-verified). `PLAY.json` still holds the starter placeholder
   (`place_id` 0). Before submitting, the human must publish the place on Roblox,
   set it Public, put the make.fun play code in its description, upload the icon
   and `1-thumbnail.jpg` as the first thumbnail, and update `PLAY.json` with the
   real place and universe ids. No Roblox place URL is invented here.
