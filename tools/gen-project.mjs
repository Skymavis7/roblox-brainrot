// gen-project.mjs — builds default.project.json for Brainrot Lagoon.
// Run: node tools/gen-project.mjs
// then: rojo build default.project.json --output game.rbxl   (Rojo 7.7.1)
//
// The map is plain parts in the project file, so Rojo puts real 3D instances
// into game.rbxl. Signs are BillboardGuis hung at runtime by WorldBuilder
// (src/server/WorldBuilder.luau), so they are not listed here.
//
// FUNCTIONAL CONTRACT — do not break it. The Luau scripts in src/ depend on
// the layout in src/shared/GameConfig.luau: the island top is y = 1, base tops
// are y = 2, the conveyor walks west to east at z = -20 with its top at y = 2,
// the tsunami wall sweeps z = -130 to +130, and players spawn at (0, 3, 95).
// Every part the scripts find by name (WaveWall, SpawnArchBeam, DockSign,
// MartSign, PortalSign, BasePlate1..6, SpawnLocation, the Conveyor, the six
// BaseN platforms/walls/slots, Water, Sand, Island, Plaza, SpawnPad, the dock,
// mart and portal pieces) keeps its exact name, position and size here.
// Only Material / Color / Transparency of those parts may change, and only
// where the gameplay surface stays put. All decoration added below uses new
// names, sits outside the conveyor band (z -24..-16), outside the six base
// rectangles and outside the spawn pad, and is CanCollide false wherever it
// sits above a walkable surface, so nothing new can block a player or a
// brainrot. Lights are kept to four PointLights total (three tiki torches
// plus the lighthouse lamp) so the place stays light.

import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');

// 0-255 RGB to Rojo's 0-1 Color3 array.
const c = (r, g, b) => [+(r / 255).toFixed(5), +(g / 255).toFixed(5), +(b / 255).toFixed(5)];

// A lighter tint of an RGB colour, for base trims (mix toward white).
const tint = (rgb, amount) =>
	c(
		Math.round(rgb[0] + (255 - rgb[0]) * amount),
		Math.round(rgb[1] + (255 - rgb[1]) * amount),
		Math.round(rgb[2] + (255 - rgb[2]) * amount),
	);

const world = {};

// Add one part. Throws on a duplicate name so a decoration can never
// silently overwrite a functional part.
function add(name, pos, size, color, opts = {}) {
	if (world[name] !== undefined) throw new Error(`duplicate part name: ${name}`);
	const node = {
		$className: 'Part',
		$properties: {
			Anchored: true,
			Position: pos,
			Size: size,
			Color: color,
			Material: opts.material ?? 'SmoothPlastic',
			CanCollide: opts.canCollide ?? true,
			Transparency: opts.transparency ?? 0,
			...(opts.shape ? { Shape: opts.shape } : {}),
			...(opts.orientation ? { Orientation: opts.orientation } : {}),
		},
	};
	if (opts.light) {
		node[opts.light.name] = {
			$className: 'PointLight',
			$properties: {
				Color: opts.light.color,
				Range: opts.light.range,
				Brightness: opts.light.brightness,
			},
		};
	}
	world[name] = node;
	return node;
}

// A warm point light, for torches and the lighthouse lamp.
const warmLight = (range, brightness) => ({
	name: 'PointLight',
	color: c(255, 180, 90),
	range,
	brightness,
});

// ---------------------------------------------------------------------------
// Ground: lagoon water, beach sand, grass island, central plaza.
// ---------------------------------------------------------------------------
add('Water', [0, -0.5, 0], [500, 1, 500], c(25, 140, 235), { material: 'Glass', transparency: 0.3, canCollide: false });
add('Sand', [0, 0.4, 0], [240, 1, 240], c(240, 215, 155), { material: 'Sand' });
add('Island', [0, 0.5, 0], [220, 1, 220], c(75, 185, 85), { material: 'Grass' });
add('Plaza', [0, 1.1, 20], [34, 0.6, 34], c(218, 198, 158), { material: 'Cobblestone' });

// ---------------------------------------------------------------------------
// Spawn arch (south). SpawnLocation itself is added with the project tree
// below; it must stay at (0, 1.5, 95), 10x1x10, Neutral, Anchored.
// ---------------------------------------------------------------------------
add('SpawnPad', [0, 1.2, 95], [14, 0.5, 14], c(250, 225, 140));
add('SpawnArchPostL', [-8, 6, 88], [2, 10, 2], c(255, 205, 55), { material: 'Neon' });
add('SpawnArchPostR', [8, 6, 88], [2, 10, 2], c(255, 205, 55), { material: 'Neon' });
add('SpawnArchBeam', [0, 11, 88], [20, 2, 2], c(255, 205, 55), { material: 'Neon' });
// Gold orbs resting on top of the arch beam.
add('SpawnOrbL', [-8, 12.8, 88], [1.6, 1.6, 1.6], c(255, 220, 100), { shape: 'Ball', material: 'Neon', canCollide: false });
add('SpawnOrbR', [8, 12.8, 88], [1.6, 1.6, 1.6], c(255, 220, 100), { shape: 'Ball', material: 'Neon', canCollide: false });

// ---------------------------------------------------------------------------
// The weirdo conveyor (west dock to east exit, across the middle).
// Dark belt, neon edges, pale chevrons on top (all CanCollide false so the
// walking brainrots are never tripped by the decoration).
// ---------------------------------------------------------------------------
add('Conveyor', [0, 1.5, -20], [190, 1, 8], c(45, 48, 58), { material: 'SmoothPlastic' });
add('ConveyorRailN', [0, 2.4, -24.4], [190, 1, 0.6], c(90, 95, 110), { material: 'Metal' });
add('ConveyorRailS', [0, 2.4, -15.6], [190, 1, 0.6], c(90, 95, 110), { material: 'Metal' });
add('ConveyorEdgeN', [0, 2.06, -23.6], [190, 0.18, 0.7], c(255, 210, 60), { material: 'Neon', canCollide: false });
add('ConveyorEdgeS', [0, 2.06, -16.4], [190, 0.18, 0.7], c(255, 210, 60), { material: 'Neon', canCollide: false });
for (let i = 0; i < 10; i++) {
	const x = -81 + i * 18;
	add(`ConveyorStripe${i + 1}`, [x, 2.03, -20], [1.6, 0.06, 5], c(255, 235, 120), { material: 'Neon', canCollide: false });
}
add('DockPlatform', [-102, 1.5, -20], [14, 1, 14], c(165, 120, 75), { material: 'Wood' });
add('DockSign', [-102, 7.5, -20], [8, 4, 0.6], c(40, 50, 70));
add('DockPost', [-102, 4, -20], [1, 4, 1], c(90, 65, 40), { material: 'Wood' });
// A red flag on the dock's far corner.
add('DockFlagPole', [-108, 4.5, -26], [0.6, 7, 0.6], c(80, 80, 90), { shape: 'Cylinder', material: 'Metal' });
add('DockFlag', [-105.8, 7, -26], [4, 2, 0.3], c(255, 80, 80), { canCollide: false });

// ---------------------------------------------------------------------------
// Six player bases. Platforms keep their GameConfig colours; each gets a
// lighter trim frame lying flat on top (CanCollide false, on the rim only,
// so the eight slot pads stay clear) and a translucent back wall.
// ---------------------------------------------------------------------------
const BASES = [
	{ x: -72, z: -72, rgb: [255, 120, 120] },
	{ x: 0, z: -72, rgb: [120, 180, 255] },
	{ x: 72, z: -72, rgb: [120, 230, 140] },
	{ x: -72, z: 72, rgb: [255, 210, 90] },
	{ x: 0, z: 72, rgb: [200, 130, 255] },
	{ x: 72, z: 72, rgb: [255, 150, 210] },
];
const SLOT_OFFSETS = [
	[-9, -6], [-3, -6], [3, -6], [9, -6],
	[-9, 6], [-3, 6], [3, 6], [9, 6],
];
BASES.forEach((base, i) => {
	const n = i + 1;
	const color = c(...base.rgb);
	const wallZ = base.z - 12.5 * Math.sign(base.z);
	add(`Base${n}Platform`, [base.x, 1.5, base.z], [26, 1, 26], color);
	add(`Base${n}Wall`, [base.x, 4.5, wallZ], [26, 7, 1], color, { transparency: 0.15 });
	add(`BasePlate${n}`, [base.x, 9, base.z], [2, 2, 2], c(255, 255, 255), { transparency: 1, canCollide: false });
	SLOT_OFFSETS.forEach(([dx, dz], s) => {
		add(`Base${n}Slot${s + 1}`, [base.x + dx, 2.15, base.z + dz], [4, 0.3, 4], c(245, 245, 250), { transparency: 0.25 });
	});
	// Lighter trim frame around the platform rim.
	const trim = tint(base.rgb, 0.45);
	add(`Base${n}TrimN`, [base.x, 2.08, base.z - 12.5], [26, 0.15, 1], trim, { canCollide: false });
	add(`Base${n}TrimS`, [base.x, 2.08, base.z + 12.5], [26, 0.15, 1], trim, { canCollide: false });
	add(`Base${n}TrimW`, [base.x - 12.5, 2.08, base.z], [1, 0.15, 24], trim, { canCollide: false });
	add(`Base${n}TrimE`, [base.x + 12.5, 2.08, base.z], [1, 0.15, 24], trim, { canCollide: false });
});

// ---------------------------------------------------------------------------
// Weirdo Mart (west) and Rebirth Portal (east).
// ---------------------------------------------------------------------------
add('MartFloor', [-85, 1.5, 30], [20, 1, 16], c(205, 170, 115), { material: 'Wood' });
add('MartBackWall', [-85, 5, 22], [20, 8, 1], c(255, 150, 210));
add('MartSideWallL', [-95, 5, 30], [1, 8, 16], c(255, 150, 210));
add('MartSideWallR', [-75, 5, 30], [1, 8, 16], c(255, 150, 210));
add('MartRoof', [-85, 9.5, 30], [22, 1, 18], c(225, 70, 110));
add('MartCounter', [-85, 3, 26], [12, 2, 2], c(150, 110, 70), { material: 'Wood' });
add('MartSign', [-85, 12, 30], [10, 4, 0.6], c(40, 50, 70));
// Pink awning over the mart entrance, held by two posts.
add('MartAwning', [-85, 7.2, 39], [14, 0.4, 5], c(255, 90, 130), { canCollide: false });
add('MartAwningPostL', [-91, 4, 41], [0.6, 6, 0.6], c(110, 75, 40), { material: 'Wood' });
add('MartAwningPostR', [-79, 4, 41], [0.6, 6, 0.6], c(110, 75, 40), { material: 'Wood' });

add('PortalPostL', [80, 6, 30], [1, 10, 1], c(190, 130, 255), { material: 'Neon' });
add('PortalPostR', [90, 6, 30], [1, 10, 1], c(190, 130, 255), { material: 'Neon' });
add('PortalBeam', [85, 11, 30], [11, 1, 1], c(190, 130, 255), { material: 'Neon' });
add('PortalPanel', [85, 6, 30], [9, 9, 0.5], c(170, 90, 255), { material: 'Neon', transparency: 0.5, canCollide: false });
add('PortalBase', [85, 1.5, 30], [14, 1, 14], c(125, 95, 205));
add('PortalSign', [85, 13.5, 30], [10, 4, 0.6], c(40, 50, 70));
// Two glow orbs floating beside the portal.
add('PortalOrbL', [77, 5, 38], [2, 2, 2], c(200, 140, 255), { shape: 'Ball', material: 'Neon', canCollide: false });
add('PortalOrbR', [93, 5, 38], [2, 2, 2], c(200, 140, 255), { shape: 'Ball', material: 'Neon', canCollide: false });

// ---------------------------------------------------------------------------
// Round trees (upgraded: cylinder trunks, brighter grass tops).
// ---------------------------------------------------------------------------
const TREES = [[-40, -50], [40, -50], [-105, -60], [105, -60], [-105, 60], [105, 60], [-40, 50], [40, 50], [-100, 0], [100, 0]];
TREES.forEach(([x, z], i) => {
	add(`Tree${i + 1}Trunk`, [x, 4, z], [2, 6, 2], c(120, 80, 40), { shape: 'Cylinder', material: 'Wood' });
	add(`Tree${i + 1}Top`, [x, 9, z], [8, 8, 8], c(50, 190, 80), { shape: 'Ball', material: 'Grass' });
});

// ---------------------------------------------------------------------------
// Lamps along the conveyor (south side, clear of the walk path).
// ---------------------------------------------------------------------------
[-60, -30, 0, 30, 60].forEach((x, i) => {
	add(`Lamp${i + 1}Pole`, [x, 4, -27], [0.8, 6, 0.8], c(50, 50, 60), { material: 'Metal' });
	add(`Lamp${i + 1}Bulb`, [x, 7.5, -27], [2, 2, 2], c(255, 230, 120), { shape: 'Ball', material: 'Neon', canCollide: false });
});

// ---------------------------------------------------------------------------
// Clouds.
// ---------------------------------------------------------------------------
const CLOUDS = [
	[-60, 40, -60, 16], [60, 48, -40, 20], [0, 38, 60, 14], [-80, 45, 40, 18], [80, 42, 70, 15],
	[-30, 55, -90, 18], [30, 58, 90, 20], [-110, 50, 0, 16], [110, 52, -10, 17], [0, 60, -110, 22],
];
CLOUDS.forEach(([x, y, z, s], i) => {
	add(`Cloud${i + 1}`, [x, y, z], [s, s * 0.6, s], c(255, 255, 255), { shape: 'Ball', transparency: 0.2, canCollide: false });
});

// ---------------------------------------------------------------------------
// The Noodle Tsunami wall (hidden until the wave sweeps; WaveService moves it).
// ---------------------------------------------------------------------------
add('WaveWall', [0, 12, -130], [220, 24, 4], c(255, 80, 170), { material: 'Neon', transparency: 1, canCollide: false });

// ===========================================================================
// NEW DECORATION — the tropical upgrade. Everything below is new, uses new
// names, and stays out of the conveyor band, the base rectangles and spawn.
// ===========================================================================

// ---- Palm trees: cylinder trunk, five flat leaves fanning out (pure Y
// rotation, so each leaf's long axis points away from the trunk), one
// coconut cluster on top. Eight palms around the island edge and beach. ----
const PALMS = [[-98, -48], [98, -48], [-98, 48], [98, 48], [-58, 98], [70, 100], [-108, 14], [108, 14]];
PALMS.forEach(([x, z], i) => {
	const n = i + 1;
	add(`Palm${n}Trunk`, [x, 5.5, z], [2.2, 9, 2.2], c(150, 105, 55), { shape: 'Cylinder', material: 'Wood' });
	for (let leaf = 0; leaf < 5; leaf++) {
		const angle = (leaf * 72 * Math.PI) / 180;
		const lx = x + Math.cos(angle) * 2.6;
		const lz = z + Math.sin(angle) * 2.6;
		const yaw = (-leaf * 72) % 360;
		add(`Palm${n}Leaf${leaf + 1}`, [+lx.toFixed(2), 10.6, +lz.toFixed(2)], [7, 0.35, 2.2], c(60, 200, 90), {
			orientation: [0, yaw, 0],
			canCollide: false,
		});
	}
	add(`Palm${n}Coconut`, [x + 0.9, 9.6, z + 0.4], [1.8, 1.8, 1.8], c(120, 80, 40), { shape: 'Ball', material: 'Wood' });
});

// ---- Rocks: grey slate balls, half-buried around the shoreline. ----
const ROCKS = [
	[-108, -95, 5], [108, -95, 6], [-108, 95, 4], [108, 95, 5], [0, -108, 4],
	[-60, -108, 3], [60, -108, 3.5], [-115, -40, 4], [115, 40, 4.5], [0, 115, 4],
];
ROCKS.forEach(([x, z, s], i) => {
	add(`Rock${i + 1}`, [x, +(0.1 + s / 2).toFixed(2), z], [s, s, s], c(130, 130, 135), { shape: 'Ball', material: 'Slate' });
});

// ---- Two beach huts on the south beach: floor, four posts, a shallow
// two-slab gable roof (single-axis X tilt on each slab). ----
[[-45, 92], [45, 92]].forEach(([x, z], i) => {
	const n = i + 1;
	add(`Hut${n}Floor`, [x, 1.4, z], [12, 0.8, 10], c(190, 150, 95), { material: 'Wood' });
	[[-5, -4], [5, -4], [-5, 4], [5, 4]].forEach(([dx, dz], p) => {
		add(`Hut${n}Post${p + 1}`, [x + dx, 4, z + dz], [0.8, 5, 0.8], c(120, 85, 45), { material: 'Wood' });
	});
	add(`Hut${n}RoofN`, [x, 7, z - 2.6], [13, 0.5, 6], c(215, 170, 85), { material: 'Wood', orientation: [10, 0, 0] });
	add(`Hut${n}RoofS`, [x, 7, z + 2.6], [13, 0.5, 6], c(215, 170, 85), { material: 'Wood', orientation: [-10, 0, 0] });
});

// ---- Tiki torches: wooden pole, neon flame ball. Three of them carry a
// warm PointLight; the other three are unlit decoration. ----
const TORCHES = [[-18, 40, true], [18, 40, true], [-18, 2, false], [18, 2, false], [-70, 44, true], [70, 44, false]];
TORCHES.forEach(([x, z, lit], i) => {
	const n = i + 1;
	add(`Torch${n}Pole`, [x, 3.25, z], [0.7, 4.5, 0.7], c(110, 75, 40), { material: 'Wood' });
	add(`Torch${n}Flame`, [x, 5.8, z], [1.6, 1.6, 1.6], c(255, 150, 40), {
		shape: 'Ball',
		material: 'Neon',
		canCollide: false,
		...(lit ? { light: warmLight(16, 2) } : {}),
	});
});

// ---- Flowers: a green stem and one bright head, scattered on open grass. ----
const FLOWERS = [
	[-30, -45, [255, 120, 180]], [30, -45, [255, 220, 80]], [-30, 45, [255, 255, 255]],
	[30, 45, [255, 120, 180]], [-50, 10, [255, 150, 60]], [50, 10, [255, 220, 80]],
	[-20, -55, [255, 120, 180]], [20, -55, [255, 255, 255]], [-55, -38, [255, 150, 60]], [55, -38, [255, 220, 80]],
];
FLOWERS.forEach(([x, z, rgb], i) => {
	const n = i + 1;
	add(`Flower${n}Stem`, [x, 1.6, z], [0.4, 1.2, 0.4], c(40, 160, 60), { shape: 'Cylinder', canCollide: false });
	add(`Flower${n}Head`, [x, 2.4, z], [1.1, 1.1, 1.1], c(...rgb), { shape: 'Ball', canCollide: false });
});

// ---- Crates and barrels by the dock and the mart. ----
const CRATES = [[-112, -32], [-112, -10], [-96, -32], [-98, 42]];
CRATES.forEach(([x, z], i) => {
	add(`Crate${i + 1}`, [x, 2.6, z], [3.2, 3.2, 3.2], c(175, 130, 80), { material: 'Wood', orientation: [0, i * 15, 0] });
});
const BARRELS = [[-64, 42], [96, 44], [-60, 44], [-108, 38]];
BARRELS.forEach(([x, z], i) => {
	add(`Barrel${i + 1}`, [x, 2.7, z], [2.6, 3.4, 2.6], c(150, 100, 55), { shape: 'Cylinder', material: 'Wood' });
});

// ---- Buoys bobbing in the lagoon, outside the sand ring. ----
[[-135, -135], [135, -135], [-135, 135], [135, 135], [-145, 0], [145, 0]].forEach(([x, z], i) => {
	add(`Buoy${i + 1}`, [x, 0.7, z], [2.4, 2.4, 2.4], c(255, 120, 40), { shape: 'Ball', material: 'Neon', canCollide: false });
});

// ---- Starfish and shells on the sand ring. ----
const STARFISH = [
	[-115, -100, [255, 130, 160]], [115, -100, [255, 150, 60]], [-115, 100, [255, 130, 160]],
	[115, 100, [255, 150, 60]], [-100, 115, [255, 130, 160]], [100, 115, [255, 150, 60]],
	[-115, 0, [255, 130, 160]], [115, 0, [255, 150, 60]],
];
STARFISH.forEach(([x, z, rgb], i) => {
	add(`Starfish${i + 1}`, [x, 1.05, z], [2.2, 0.3, 2.2], c(...rgb), { orientation: [0, i * 40, 0], canCollide: false });
});
const SHELLS = [[-105, 115], [105, -115], [-118, 60], [118, -60], [60, 115], [-60, -115]];
SHELLS.forEach(([x, z], i) => {
	add(`Shell${i + 1}`, [x, 1.0, z], [1.4, 1.0, 1.4], c(250, 245, 235), { shape: 'Ball', canCollide: false });
});

// ---- Beach umbrellas on the south beach: pole plus a wide flat canopy. ----
const UMBRELLAS = [[-30, 95, [255, 80, 80]], [30, 95, [255, 210, 70]], [-95, 90, [90, 160, 255]]];
UMBRELLAS.forEach(([x, z, rgb], i) => {
	const n = i + 1;
	add(`Umbrella${n}Pole`, [x, 4, z], [0.7, 6, 0.7], c(240, 240, 240), { shape: 'Cylinder' });
	add(`Umbrella${n}Canopy`, [x, 7.2, z], [9, 0.6, 9], c(...rgb), { shape: 'Cylinder', canCollide: false });
});

// ---- Wooden plank paths (flat, CanCollide false) from the plaza to the
// spawn, the mart, the portal and the three northern bases; a low fence
// runs along the south path. ----
add('PathSouth', [0, 1.06, 45.5], [6, 0.12, 27], c(200, 165, 110), { material: 'WoodPlanks', canCollide: false });
add('PathEast', [50, 1.06, 30], [44, 0.12, 6], c(200, 165, 110), { material: 'WoodPlanks', canCollide: false });
add('PathWest', [-50, 1.06, 30], [44, 0.12, 6], c(200, 165, 110), { material: 'WoodPlanks', canCollide: false });
add('PathNorth1', [-72, 1.06, -37], [6, 0.12, 42], c(200, 165, 110), { material: 'WoodPlanks', canCollide: false });
add('PathNorth2', [0, 1.06, -37], [6, 0.12, 42], c(200, 165, 110), { material: 'WoodPlanks', canCollide: false });
add('PathNorth3', [72, 1.06, -37], [6, 0.12, 42], c(200, 165, 110), { material: 'WoodPlanks', canCollide: false });
[[-4.5, 40], [4.5, 40], [-4.5, 52], [4.5, 52]].forEach(([x, z], i) => {
	add(`FencePost${i + 1}`, [x, 2.2, z], [0.8, 2.4, 0.8], c(150, 105, 60), { material: 'Wood' });
});
add('FenceRailW', [-4.5, 3.0, 44], [0.5, 0.5, 22], c(150, 105, 60), { material: 'Wood' });
add('FenceRailE', [4.5, 3.0, 44], [0.5, 0.5, 22], c(150, 105, 60), { material: 'Wood' });

// ---- Lighthouse on the north-west corner of the island, well away from
// every base, the conveyor and spawn. Striped tower, neon lamp room with a
// warm PointLight, dome roof. ----
add('LighthouseBase', [-108, 2, -108], [10, 2, 10], c(240, 240, 240), { shape: 'Cylinder' });
add('LighthouseTowerLow', [-108, 7, -108], [6, 8, 6], c(220, 60, 60), { shape: 'Cylinder' });
add('LighthouseTowerMid', [-108, 15, -108], [5, 8, 5], c(245, 245, 245), { shape: 'Cylinder' });
add('LighthouseTowerTop', [-108, 20.5, -108], [6, 3, 6], c(220, 60, 60), { shape: 'Cylinder' });
add('LighthouseLamp', [-108, 23.5, -108], [4.5, 3, 4.5], c(255, 230, 120), {
	shape: 'Cylinder',
	material: 'Neon',
	light: { name: 'PointLight', color: c(255, 220, 130), range: 30, brightness: 3 },
});
add('LighthouseRoof', [-108, 25.8, -108], [6, 3, 6], c(220, 60, 60), { shape: 'Ball' });

// ---- Seagulls high over the island: two tilted wings each (single-axis
// Z rotation, forming a V), white and non-colliding. ----
const GULLS = [[-40, 34, -80], [20, 36, 80], [60, 32, -60], [-70, 35, 60], [0, 38, 0]];
GULLS.forEach(([x, y, z], i) => {
	const n = i + 1;
	add(`Gull${n}WingL`, [x - 1.3, y, z], [3, 0.25, 1.1], c(255, 255, 255), { orientation: [0, 0, 25], canCollide: false });
	add(`Gull${n}WingR`, [x + 1.3, y, z], [3, 0.25, 1.1], c(255, 255, 255), { orientation: [0, 0, -25], canCollide: false });
});

// ---- Sandcastle on the south beach, east of the second hut. ----
add('SandcastleBase', [62, 1.8, 96], [6, 1.6, 6], c(240, 215, 155), { shape: 'Cylinder', material: 'Sand' });
add('SandcastleTower', [62, 3.4, 96], [3, 3, 3], c(240, 215, 155), { shape: 'Cylinder', material: 'Sand' });
add('SandcastlePole', [62, 5.6, 96], [0.4, 2.5, 0.4], c(120, 80, 40), { shape: 'Cylinder', material: 'Wood', canCollide: false });
add('SandcastleFlag', [63, 6.4, 96], [1.8, 1, 0.2], c(255, 80, 80), { canCollide: false });

// ---------------------------------------------------------------------------
// Project tree. Lighting is warm tropical daylight at 10:00 with a pale
// blue haze; the Atmosphere child adds the soft sky tint.
// ---------------------------------------------------------------------------
const project = {
	name: 'brainrot-lagoon',
	tree: {
		$className: 'DataModel',
		Players: {
			$properties: { CharacterAutoLoads: true },
		},
		ReplicatedStorage: {
			Shared: { $path: 'src/shared' },
		},
		ServerScriptService: {
			Server: { $path: 'src/server' },
		},
		StarterPlayer: {
			StarterPlayerScripts: {
				Client: { $path: 'src/client' },
			},
		},
		Workspace: {
			$properties: { FilteringEnabled: true },
			SpawnLocation: {
				$className: 'SpawnLocation',
				$properties: {
					Anchored: true,
					Position: [0, 1.5, 95],
					Size: [10, 1, 10],
					Color: c(120, 200, 255),
					Material: 'Neon',
					Neutral: true,
					Duration: 0,
				},
			},
			...world,
		},
		Lighting: {
			$properties: {
				Ambient: [0.45, 0.38, 0.3],
				OutdoorAmbient: [0.55, 0.7, 0.85],
				Brightness: 2,
				ClockTime: 10,
				TimeOfDay: '10:00:00',
				FogColor: [0.75, 0.85, 0.95],
				FogStart: 500,
				FogEnd: 2000,
				GlobalShadows: true,
				Outlines: false,
				Technology: 'Voxel',
			},
			Atmosphere: {
				$className: 'Atmosphere',
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
			$properties: { RespectFilteringEnabled: true },
		},
	},
};

writeFileSync(join(root, 'default.project.json'), JSON.stringify(project, null, 2) + '\n');
console.log(`wrote default.project.json with ${Object.keys(world).length + 1} world instances`);
