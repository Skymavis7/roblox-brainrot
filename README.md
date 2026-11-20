# Brainrot Lagoon — a 3D Roblox brainrot game

![make.fun](https://img.shields.io/badge/make.fun-roblox--brainrot--01-blue)
![Roblox](https://img.shields.io/badge/Roblox-Luau-red)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

An entry for make.fun's **"Make the best AI Roblox brainrot game"** bounty
(`roblox-brainrot-01`). A lagoon island full of absurd original meme
characters — buy them off a conveyor, carry them home, and let them earn cash
for you while you guard your base from thieves and outrun the Noodle Tsunami.

## The cast

12 original characters across 6 rarities:

| Rarity | Characters |
| --- | --- |
| Common | Soggy Sock Sam, Toaster Terry, Chairman Chair |
| Rare | Banana Bus Barry, Sir Puddles III, DJ Fridge |
| Epic | Captain Crunchwrap, The Forbidden Leftovers |
| Legendary | Quantum Pickle, El Gato WiFi |
| Mythic | Grandma's Router |
| Secret | Chungus Prime |

Every brainrot can also roll a mutation — Normal, Frozen (x2), Golden (x3),
Spicy (x5) or Rainbow (x8) — that multiplies its income and re-skins its body.

## The loop

1. **Buy** — weirdos walk the conveyor from the sea. Spend cash to grab one.
2. **Carry home** — carry it to your base and it starts earning dollars every
   second. Up to 8 slots (12 with the Base Extension upgrade).
3. **Steal or be stolen from** — snatch brainrots off unlocked bases, slap
   thieves to make them drop their loot, lock your base for 60 seconds when
   things get spicy.
4. **Survive the wave** — every 100 seconds the Noodle Tsunami sweeps the map.
   Caught outside your base? You get flung back to spawn and drop whatever
   you were carrying.
5. **Rebirth and shop** — cash out at 100k for +50% income forever, and spend
   cash on permanent upgrades (Speed Boots, Double Scoop, Base Extension).
6. **Save** — cash, rebirths and upgrades persist in a DataStore between
   sessions.

## The world

A lagoon island with a conveyor dock, six coloured player bases, a Weirdo
Mart, a Rebirth Portal, a lighthouse, palm trees, torches, a spawn arch, and
a full HUD (cash, income, rebirth, tsunami countdown, catalog + shop, slap
and lock buttons, toasts).

## Build

```sh
node tools/gen-project.mjs   # writes default.project.json
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts   # writes out/dossier.json
```

Play it in Roblox Studio from `game.rbxl` (place 103555962459584).
