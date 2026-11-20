// tools/gen-project.mjs — generates default.project.json for Brainrot Lagoon.
// Node, stdlib only. Run from the repo root:  node tools/gen-project.mjs
// The map is plain parts in Workspace; the scripts live in src/ and are
// wired in through the project tree. Functional contract: the island top is
// y = 1, base tops are y = 2, the conveyor runs west to east at z = -20 with
// its top at y = 2, the tsunami wall sweeps z = -130 to +130, and players
// spawn at (0, 3, 95). Decoration never sits in the conveyor band, inside a
// base rectangle, or on the spawn pad, and at most four PointLights exist.

import { writeFileSync } from "node:fs";

const round5 = (n) => Math.round(n * 100000) / 100000;
// 0-255 RGB to Rojo's 0-1 colour arrays, five decimals.
const c = (r, g, b) => [round5(r / 255), round5(g / 255), round5(b / 255)];
// Mix a colour toward white by `amount` (0 keeps it, 1 is pure white).
const tint = (rgb, amount) => rgb.map((v) => Math.round(v + (255 - v) * amount));

const world = {};

// Register one Part. Throws on a duplicate name so a typo can never silently
// overwrite a piece of the map.
function add(name, pos, size, color, opts = {}) {
  if (world[name]) throw new Error(`gen-project: duplicate part name ${name}`);
  const node = {
    $className: "Part",
    $properties: {
      Anchored: true,
      Position: pos,
      Size: size,
      Color: c(color[0], color[1], color[2]),
      Material: opts.material ?? "SmoothPlastic",
      CanCollide: opts.collide ?? true,
      Transparency: opts.transparency ?? 0,
    },
  };
  if (opts.shape) node.$properties.Shape = opts.shape;
  if (opts.orientation) node.$properties.Orientation = opts.orientation;
  if (opts.light) {
    node[opts.light.name] = {
      $className: "PointLight",
      $properties: {
        Color: c(opts.light.color[0], opts.light.color[1], opts.light.color[2]),
        Range: opts.light.range,
        Brightness: opts.light.brightness,
      },
    };
  }
  world[name] = node;
}

// A warm (255,180,90) PointLight.
const warmLight = (range, brightness) => ({ name: "Light", color: [255, 180, 90], range, brightness });

// ---------------------------------------------------------------- ground
add("Water", [0, -0.5, 0], [500, 1, 500], [25, 140, 235], { material: "Glass", transparency: 0.3, collide: false });
add("Sand", [0, 0.4, 0], [240, 1, 240], [240, 215, 155], { material: "Sand" });
add("Island", [0, 0.5, 0], [220, 1, 220], [75, 185, 85], { material: "Grass" });
add("Plaza", [0, 1.1, 20], [34, 0.6, 34], [218, 198, 158], { material: "Cobblestone" });

// ---------------------------------------------------------------- spawn (south)
add("SpawnPad", [0, 1.2, 95], [14, 0.5, 14], [250, 225, 140]);
add("SpawnArchPostL", [-8, 6, 88], [2, 10, 2], [255, 205, 55], { material: "Neon" });
add("SpawnArchPostR", [8, 6, 88], [2, 10, 2], [255, 205, 55], { material: "Neon" });
add("SpawnArchBeam", [0, 11, 88], [20, 2, 2], [255, 205, 55], { material: "Neon" });
add("SpawnOrbL", [-8, 12.8, 88], [1.6, 1.6, 1.6], [255, 220, 100], { shape: "Ball", material: "Neon", collide: false });
add("SpawnOrbR", [8, 12.8, 88], [1.6, 1.6, 1.6], [255, 220, 100], { shape: "Ball", material: "Neon", collide: false });

// ---------------------------------------------------------------- conveyor
add("Conveyor", [0, 1.5, -20], [190, 1, 8], [45, 48, 58]);
add("ConveyorRailN", [0, 2.4, -24.4], [190, 1, 0.6], [90, 95, 110], { material: "Metal" });
add("ConveyorRailS", [0, 2.4, -15.6], [190, 1, 0.6], [90, 95, 110], { material: "Metal" });
add("ConveyorEdgeN", [0, 2.06, -23.6], [190, 0.18, 0.7], [255, 210, 60], { material: "Neon", collide: false });
add("ConveyorEdgeS", [0, 2.06, -16.4], [190, 0.18, 0.7], [255, 210, 60], { material: "Neon", collide: false });
for (let n = 1; n <= 10; n++) {
  add(`ConveyorStripe${n}`, [-81 + (n - 1) * 18, 2.03, -20], [1.6, 0.06, 5], [255, 235, 120], { material: "Neon", collide: false });
}
add("DockPlatform", [-102, 1.5, -20], [14, 1, 14], [165, 120, 75], { material: "Wood" });
add("DockSign", [-102, 7.5, -20], [8, 4, 0.6], [40, 50, 70]);
add("DockPost", [-102, 4, -20], [1, 4, 1], [90, 65, 40], { material: "Wood" });
add("DockFlagPole", [-108, 4.5, -26], [0.6, 7, 0.6], [80, 80, 90], { shape: "Cylinder", material: "Metal" });
add("DockFlag", [-105.8, 7, -26], [4, 2, 0.3], [255, 80, 80], { collide: false });

// ---------------------------------------------------------------- six bases
const BASES = [
  { x: -72, z: -72, color: [255, 120, 120] },
  { x: 0, z: -72, color: [120, 180, 255] },
  { x: 72, z: -72, color: [120, 230, 140] },
  { x: -72, z: 72, color: [255, 210, 90] },
  { x: 0, z: 72, color: [200, 130, 255] },
  { x: 72, z: 72, color: [255, 150, 210] },
];
const SLOT_OFFSETS = [
  [-9, -6], [-3, -6], [3, -6], [9, -6],
  [-9, 6], [-3, 6], [3, 6], [9, 6],
];
BASES.forEach((base, i) => {
  const n = i + 1;
  const { x, z, color } = base;
  const wallZ = z - 12.5 * Math.sign(z);
  add(`Base${n}Platform`, [x, 1.5, z], [26, 1, 26], color);
  add(`Base${n}Wall`, [x, 4.5, wallZ], [26, 7, 1], color, { transparency: 0.15 });
  add(`BasePlate${n}`, [x, 9, z], [2, 2, 2], [255, 255, 255], { transparency: 1, collide: false });
  SLOT_OFFSETS.forEach(([dx, dz], m) => {
    add(`Base${n}Slot${m + 1}`, [x + dx, 2.15, z + dz], [4, 0.3, 4], [245, 245, 250], { transparency: 0.25 });
  });
  const trim = tint(color, 0.45);
  add(`Base${n}TrimN`, [x, 2.08, z - 12.5], [26, 0.15, 1], trim, { collide: false });
  add(`Base${n}TrimS`, [x, 2.08, z + 12.5], [26, 0.15, 1], trim, { collide: false });
  add(`Base${n}TrimW`, [x - 12.5, 2.08, z], [1, 0.15, 24], trim, { collide: false });
  add(`Base${n}TrimE`, [x + 12.5, 2.08, z], [1, 0.15, 24], trim, { collide: false });
});

// ---------------------------------------------------------------- mart (west)
add("MartFloor", [-85, 1.5, 30], [20, 1, 16], [205, 170, 115], { material: "Wood" });
add("MartBackWall", [-85, 5, 22], [20, 8, 1], [255, 150, 210]);
add("MartSideWallL", [-95, 5, 30], [1, 8, 16], [255, 150, 210]);
add("MartSideWallR", [-75, 5, 30], [1, 8, 16], [255, 150, 210]);
add("MartRoof", [-85, 9.5, 30], [22, 1, 18], [225, 70, 110]);
add("MartCounter", [-85, 3, 26], [12, 2, 2], [150, 110, 70], { material: "Wood" });
add("MartSign", [-85, 12, 30], [10, 4, 0.6], [40, 50, 70]);
add("MartAwning", [-85, 7.2, 39], [14, 0.4, 5], [255, 90, 130], { collide: false });
add("MartAwningPostL", [-91, 4, 41], [0.6, 6, 0.6], [110, 75, 40], { material: "Wood" });
add("MartAwningPostR", [-79, 4, 41], [0.6, 6, 0.6], [110, 75, 40], { material: "Wood" });

// ---------------------------------------------------------------- portal (east)
add("PortalPostL", [80, 6, 30], [1, 10, 1], [190, 130, 255], { material: "Neon" });
add("PortalPostR", [90, 6, 30], [1, 10, 1], [190, 130, 255], { material: "Neon" });
add("PortalBeam", [85, 11, 30], [11, 1, 1], [190, 130, 255], { material: "Neon" });
add("PortalPanel", [85, 6, 30], [9, 9, 0.5], [170, 90, 255], { material: "Neon", transparency: 0.5, collide: false });
add("PortalBase", [85, 1.5, 30], [14, 1, 14], [125, 95, 205]);
add("PortalSign", [85, 13.5, 30], [10, 4, 0.6], [40, 50, 70]);
add("PortalOrbL", [77, 5, 38], [2, 2, 2], [200, 140, 255], { shape: "Ball", material: "Neon", collide: false });
add("PortalOrbR", [93, 5, 38], [2, 2, 2], [200, 140, 255], { shape: "Ball", material: "Neon", collide: false });

// ---------------------------------------------------------------- trees
const TREE_SPOTS = [
  [-40, -50], [40, -50], [-105, -60], [105, -60], [-105, 60],
  [105, 60], [-40, 50], [40, 50], [-100, 0], [100, 0],
];
TREE_SPOTS.forEach(([x, z], i) => {
  const n = i + 1;
  add(`Tree${n}Trunk`, [x, 4, z], [2, 6, 2], [120, 80, 40], { shape: "Cylinder", material: "Wood" });
  add(`Tree${n}Top`, [x, 9, z], [8, 8, 8], [50, 190, 80], { shape: "Ball", material: "Grass" });
});

// ---------------------------------------------------------------- lamps
for (let n = 1; n <= 5; n++) {
  const x = -60 + (n - 1) * 30;
  add(`Lamp${n}Pole`, [x, 4, -27], [0.8, 6, 0.8], [50, 50, 60], { material: "Metal" });
  add(`Lamp${n}Bulb`, [x, 7.5, -27], [2, 2, 2], [255, 230, 120], { shape: "Ball", material: "Neon", collide: false });
}

// ---------------------------------------------------------------- clouds
const CLOUDS = [
  [-60, 40, -60, 16], [60, 48, -40, 20], [0, 38, 60, 14], [-80, 45, 40, 18],
  [80, 42, 70, 15], [-30, 55, -90, 18], [30, 58, 90, 20], [-110, 50, 0, 16],
  [110, 52, -10, 17], [0, 60, -110, 22],
];
CLOUDS.forEach(([x, y, z, s], i) => {
  add(`Cloud${i + 1}`, [x, y, z], [s, s * 0.6, s], [255, 255, 255], { shape: "Ball", transparency: 0.2, collide: false });
});

// ---------------------------------------------------------------- tsunami wall
add("WaveWall", [0, 12, -130], [220, 24, 4], [255, 80, 170], { material: "Neon", transparency: 1, collide: false });

// ---------------------------------------------------------------- palms
const PALM_SPOTS = [
  [-98, -48], [98, -48], [-98, 48], [98, 48],
  [-58, 98], [70, 100], [-108, 14], [108, 14],
];
PALM_SPOTS.forEach(([x, z], i) => {
  const n = i + 1;
  add(`Palm${n}Trunk`, [x, 5.5, z], [2.2, 9, 2.2], [150, 105, 55], { shape: "Cylinder", material: "Wood" });
  for (let leaf = 1; leaf <= 5; leaf++) {
    const yaw = leaf * 72;
    const rad = (yaw * Math.PI) / 180;
    const lx = x + 2.6 * Math.cos(rad);
    const lz = z + 2.6 * Math.sin(rad);
    add(`Palm${n}Leaf${leaf}`, [round5(lx), 10.6, round5(lz)], [7, 0.35, 2.2], [60, 200, 90], { orientation: [0, yaw, 0], collide: false });
  }
  add(`Palm${n}Coconut`, [x + 0.9, 9.6, z + 0.4], [1.8, 1.8, 1.8], [120, 80, 40], { shape: "Ball", material: "Wood" });
});

// ---------------------------------------------------------------- rocks
const ROCKS = [
  [-108, -95, 5], [108, -95, 6], [-108, 95, 4], [108, 95, 5], [0, -108, 4],
  [-60, -108, 3], [60, -108, 3.5], [-115, -40, 4], [115, 40, 4.5], [0, 115, 4],
];
ROCKS.forEach(([x, z, s], i) => {
  add(`Rock${i + 1}`, [x, 0.1 + s / 2, z], [s, s, s], [135, 135, 140], { shape: "Ball", material: "Slate" });
});

// ---------------------------------------------------------------- huts
const HUT_SPOTS = [[-45, 92], [45, 92]];
HUT_SPOTS.forEach(([x, z], i) => {
  const n = i + 1;
  add(`Hut${n}Floor`, [x, 1.4, z], [12, 0.8, 10], [190, 150, 95], { material: "Wood" });
  const posts = [[-5, -4], [5, -4], [-5, 4], [5, 4]];
  posts.forEach(([dx, dz], p) => {
    add(`Hut${n}Post${p + 1}`, [x + dx, 4, z + dz], [0.8, 5, 0.8], [120, 85, 45], { material: "Wood" });
  });
  add(`Hut${n}RoofN`, [x, 7, z - 2.6], [13, 0.5, 6], [215, 170, 85], { material: "Wood", orientation: [10, 0, 0] });
  add(`Hut${n}RoofS`, [x, 7, z + 2.6], [13, 0.5, 6], [215, 170, 85], { material: "Wood", orientation: [-10, 0, 0] });
});

// ---------------------------------------------------------------- torches (3 lit = 3 of the 4 PointLights)
const TORCHES = [
  [-18, 40, true], [18, 40, true], [-18, 2, false],
  [18, 2, false], [-70, 44, true], [70, 44, false],
];
TORCHES.forEach(([x, z, lit], i) => {
  const n = i + 1;
  add(`Torch${n}Pole`, [x, 3.25, z], [0.7, 4.5, 0.7], [110, 75, 40], { material: "Wood" });
  add(`Torch${n}Flame`, [x, 5.8, z], [1.6, 1.6, 1.6], [255, 150, 40], {
    shape: "Ball",
    material: "Neon",
    collide: false,
    ...(lit ? { light: warmLight(16, 2) } : {}),
  });
});

// ---------------------------------------------------------------- flowers
const FLOWERS = [
  [-30, -45, [255, 120, 180]], [30, -45, [255, 220, 80]], [-30, 45, [255, 255, 255]],
  [30, 45, [255, 120, 180]], [-50, 10, [255, 150, 60]], [50, 10, [255, 220, 80]],
  [-20, -55, [255, 120, 180]], [20, -55, [255, 255, 255]], [-55, -38, [255, 150, 60]],
  [55, -38, [255, 220, 80]],
];
FLOWERS.forEach(([x, z, rgb], i) => {
  const n = i + 1;
  add(`Flower${n}Stem`, [x, 1.6, z], [0.4, 1.2, 0.4], [40, 160, 60], { shape: "Cylinder", collide: false });
  add(`Flower${n}Head`, [x, 2.4, z], [1.1, 1.1, 1.1], rgb, { shape: "Ball", collide: false });
});

// ---------------------------------------------------------------- crates
const CRATES = [[-112, -32], [-112, -10], [-96, -32], [-98, 42]];
CRATES.forEach(([x, z], i) => {
  add(`Crate${i + 1}`, [x, 2.6, z], [3.2, 3.2, 3.2], [175, 130, 80], { material: "Wood", orientation: [0, (i + 1) * 15, 0] });
});

// ---------------------------------------------------------------- barrels
const BARRELS = [[-64, 42], [96, 44], [-60, 44], [-108, 38]];
BARRELS.forEach(([x, z], i) => {
  add(`Barrel${i + 1}`, [x, 2.7, z], [2.6, 3.4, 2.6], [150, 100, 55], { shape: "Cylinder", material: "Wood" });
});

// ---------------------------------------------------------------- buoys
const BUOYS = [[-135, -135], [135, -135], [-135, 135], [135, 135], [-145, 0], [145, 0]];
BUOYS.forEach(([x, z], i) => {
  add(`Buoy${i + 1}`, [x, 0.7, z], [2.4, 2.4, 2.4], [255, 120, 40], { shape: "Ball", material: "Neon", collide: false });
});

// ---------------------------------------------------------------- starfish
const STARFISH = [
  [-115, -100, [255, 130, 160]], [115, -100, [255, 150, 60]], [-115, 100, [255, 130, 160]],
  [115, 100, [255, 150, 60]], [-100, 115, [255, 130, 160]], [100, 115, [255, 150, 60]],
  [-115, 0, [255, 130, 160]], [115, 0, [255, 150, 60]],
];
STARFISH.forEach(([x, z, rgb], i) => {
  add(`Starfish${i + 1}`, [x, 1.05, z], [2.2, 0.3, 2.2], rgb, { orientation: [0, (i + 1) * 40, 0], collide: false });
});

// ---------------------------------------------------------------- shells
const SHELLS = [[-105, 115], [105, -115], [-118, 60], [118, -60], [60, 115], [-60, -115]];
SHELLS.forEach(([x, z], i) => {
  add(`Shell${i + 1}`, [x, 1.0, z], [1.4, 1.0, 1.4], [250, 245, 235], { shape: "Ball", collide: false });
});

// ---------------------------------------------------------------- umbrellas
const UMBRELLAS = [
  [-30, 95, [255, 80, 80]], [30, 95, [255, 210, 70]], [-95, 90, [90, 160, 255]],
];
UMBRELLAS.forEach(([x, z, rgb], i) => {
  const n = i + 1;
  add(`Umbrella${n}Pole`, [x, 4, z], [0.7, 6, 0.7], [240, 240, 240], { shape: "Cylinder" });
  add(`Umbrella${n}Canopy`, [x, 7.2, z], [9, 0.6, 9], rgb, { shape: "Cylinder", collide: false });
});

// ---------------------------------------------------------------- paths + fence
add("PathSouth", [0, 1.06, 45.5], [6, 0.12, 27], [200, 165, 110], { material: "WoodPlanks", collide: false });
add("PathEast", [50, 1.06, 30], [44, 0.12, 6], [200, 165, 110], { material: "WoodPlanks", collide: false });
add("PathWest", [-50, 1.06, 30], [44, 0.12, 6], [200, 165, 110], { material: "WoodPlanks", collide: false });
add("PathNorth1", [-72, 1.06, -37], [6, 0.12, 42], [200, 165, 110], { material: "WoodPlanks", collide: false });
add("PathNorth2", [0, 1.06, -37], [6, 0.12, 42], [200, 165, 110], { material: "WoodPlanks", collide: false });
add("PathNorth3", [72, 1.06, -37], [6, 0.12, 42], [200, 165, 110], { material: "WoodPlanks", collide: false });
const FENCE_POSTS = [[-4.5, 40], [4.5, 40], [-4.5, 52], [4.5, 52]];
FENCE_POSTS.forEach(([x, z], i) => {
  add(`FencePost${i + 1}`, [x, 2.2, z], [0.8, 2.4, 0.8], [150, 105, 60], { material: "Wood" });
});
add("FenceRailW", [-4.5, 3.0, 44], [0.5, 0.5, 22], [150, 105, 60], { material: "Wood" });
add("FenceRailE", [4.5, 3.0, 44], [0.5, 0.5, 22], [150, 105, 60], { material: "Wood" });

// ---------------------------------------------------------------- lighthouse
add("LighthouseBase", [-108, 2, -108], [10, 2, 10], [240, 240, 240], { shape: "Cylinder" });
add("LighthouseTowerLow", [-108, 7, -108], [6, 8, 6], [220, 60, 60], { shape: "Cylinder" });
add("LighthouseTowerMid", [-108, 15, -108], [5, 8, 5], [245, 245, 245], { shape: "Cylinder" });
add("LighthouseTowerTop", [-108, 20.5, -108], [6, 3, 6], [220, 60, 60], { shape: "Cylinder" });
add("LighthouseLamp", [-108, 23.5, -108], [4.5, 3, 4.5], [255, 230, 120], {
  shape: "Cylinder",
  material: "Neon",
  light: warmLight(30, 3),
});
add("LighthouseRoof", [-108, 25.8, -108], [6, 3, 6], [220, 60, 60], { shape: "Ball" });

// ---------------------------------------------------------------- seagulls
const GULLS = [[-40, 34, -80], [20, 36, 80], [60, 32, -60], [-70, 35, 60], [0, 38, 0]];
GULLS.forEach(([x, y, z], i) => {
  const n = i + 1;
  add(`Seagull${n}WingL`, [x - 1.3, y, z], [3, 0.25, 1.1], [255, 255, 255], { orientation: [0, 0, 25], collide: false });
  add(`Seagull${n}WingR`, [x + 1.3, y, z], [3, 0.25, 1.1], [255, 255, 255], { orientation: [0, 0, -25], collide: false });
});

// ---------------------------------------------------------------- sandcastle
add("SandcastleBase", [62, 1.8, 96], [6, 1.6, 6], [240, 215, 155], { shape: "Cylinder", material: "Sand" });
add("SandcastleTower", [62, 3.4, 96], [3, 3, 3], [240, 215, 155], { material: "Sand" });
add("SandcastlePole", [62, 5.6, 96], [0.4, 2.5, 0.4], [120, 80, 40], { shape: "Cylinder", material: "Wood", collide: false });
add("SandcastleFlag", [63, 6.4, 96], [1.8, 1, 0.2], [255, 80, 80], { collide: false });

// ---------------------------------------------------------------- project tree
const project = {
  name: "BrainrotLagoon",
  tree: {
    $className: "DataModel",
    Players: {
      $className: "Players",
      $properties: { CharacterAutoLoads: true },
    },
    ReplicatedStorage: {
      $className: "ReplicatedStorage",
      Shared: { $path: "src/shared" },
    },
    ServerScriptService: {
      $className: "ServerScriptService",
      Server: { $path: "src/server" },
    },
    StarterPlayer: {
      $className: "StarterPlayer",
      StarterPlayerScripts: {
        $className: "StarterPlayerScripts",
        Client: { $path: "src/client" },
      },
    },
    Workspace: {
      $className: "Workspace",
      $properties: { FilteringEnabled: true },
      SpawnLocation: {
        $className: "SpawnLocation",
        $properties: {
          Anchored: true,
          Position: [0, 1.5, 95],
          Size: [10, 1, 10],
          Color: c(120, 200, 255),
          Material: "Neon",
          Neutral: true,
          Duration: 0,
        },
      },
      ...world,
    },
    Lighting: {
      $className: "Lighting",
      $properties: {
        Ambient: [0.45, 0.38, 0.3],
        OutdoorAmbient: [0.55, 0.7, 0.85],
        Brightness: 2,
        ClockTime: 10,
        TimeOfDay: "10:00:00",
        FogColor: [0.75, 0.85, 0.95],
        FogStart: 500,
        FogEnd: 2000,
        GlobalShadows: true,
        Outlines: false,
        Technology: "Voxel",
      },
      Atmosphere: {
        $className: "Atmosphere",
        $properties: {
          Density: 0.25,
          Offset: 0,
          Color: [0.75, 0.85, 0.95],
          Decay: [0.6, 0.75, 0.9],
          Glare: 0,
          Haze: 0,
        },
      },
    },
    SoundService: {
      $className: "SoundService",
      $properties: { RespectFilteringEnabled: true },
    },
  },
};

writeFileSync("default.project.json", JSON.stringify(project, null, 2) + "\n");
console.log(`Wrote default.project.json with ${Object.keys(world).length} world instances.`);
