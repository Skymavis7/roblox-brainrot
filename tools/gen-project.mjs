// gen-project.mjs — generates default.project.json for Brainrot Lagoon.
// Run: node tools/gen-project.mjs
// The map is plain parts in the project file (so Rojo puts real 3D instances in
// game.rbxl); signs are BillboardGuis hung at runtime by WorldBuilder.
// Everything I place here is my own original map: a lagoon island with a weirdo
// conveyor across the middle, six player bases, a shop, a rebirth portal and a beach.

import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');

// 0-255 RGB to Rojo's 0-1 Color3 array.
const c = (r, g, b) => [+(r / 255).toFixed(5), +(g / 255).toFixed(5), +(b / 255).toFixed(5)];

const parts = {};

function part(name, pos, size, color, extra = {}) {
	parts[name] = {
		$className: 'Part',
		$properties: {
			Anchored: true,
			Position: pos,
			Size: size,
			Color: color,
			Material: extra.material ?? 'SmoothPlastic',
			CanCollide: extra.canCollide ?? true,
			Transparency: extra.transparency ?? 0,
			...(extra.shape ? { Shape: extra.shape } : {}),
			...(extra.locked ? { Locked: true } : {}),
		},
	};
}

// ---- Water, sand, island ----
part('Water', [0, -0.5, 0], [500, 1, 500], c(40, 130, 230), { material: 'Glass', transparency: 0.35, canCollide: false });
part('Sand', [0, 0.4, 0], [240, 1, 240], c(235, 210, 150), { material: 'Sand' });
part('Island', [0, 0.5, 0], [220, 1, 220], c(90, 180, 80), { material: 'Grass' });
part('Plaza', [0, 1.1, 20], [34, 0.6, 34], c(220, 200, 160), { material: 'Sand' });

// ---- Spawn arch (south) ----
part('SpawnPad', [0, 1.2, 95], [14, 0.5, 14], c(200, 200, 210));
part('SpawnArchPostL', [-8, 6, 88], [2, 10, 2], c(255, 210, 60), { material: 'Neon' });
part('SpawnArchPostR', [8, 6, 88], [2, 10, 2], c(255, 210, 60), { material: 'Neon' });
part('SpawnArchBeam', [0, 11, 88], [20, 2, 2], c(255, 210, 60), { material: 'Neon' });

// ---- The weirdo conveyor (west dock to east exit, across the middle) ----
part('Conveyor', [0, 1.5, -20], [190, 1, 8], c(180, 180, 190), { material: 'Metal' });
part('ConveyorRailN', [0, 2.4, -24.4], [190, 1, 0.6], c(120, 120, 130), { material: 'Metal' });
part('ConveyorRailS', [0, 2.4, -15.6], [190, 1, 0.6], c(120, 120, 130), { material: 'Metal' });
part('DockPlatform', [-102, 1.5, -20], [14, 1, 14], c(150, 110, 70), { material: 'Wood' });
part('DockSign', [-102, 7.5, -20], [8, 4, 0.6], c(40, 50, 70));
part('DockPost', [-102, 4, -20], [1, 4, 1], c(60, 60, 60));

// ---- Six player bases ----
const BASES = [
	{ x: -72, z: -72, color: c(255, 120, 120) },
	{ x: 0, z: -72, color: c(120, 180, 255) },
	{ x: 72, z: -72, color: c(120, 230, 140) },
	{ x: -72, z: 72, color: c(255, 210, 90) },
	{ x: 0, z: 72, color: c(200, 130, 255) },
	{ x: 72, z: 72, color: c(255, 150, 210) },
];
const SLOT_OFFSETS = [
	[-9, -6], [-3, -6], [3, -6], [9, -6],
	[-9, 6], [-3, 6], [3, 6], [9, 6],
];
BASES.forEach((base, i) => {
	const n = i + 1;
	const wallZ = base.z - 12.5 * Math.sign(base.z);
	part(`Base${n}Platform`, [base.x, 1.5, base.z], [26, 1, 26], base.color);
	part(`Base${n}Wall`, [base.x, 4.5, wallZ], [26, 7, 1], base.color, { transparency: 0.15 });
	part(`BasePlate${n}`, [base.x, 9, base.z], [2, 2, 2], c(255, 255, 255), { transparency: 1, canCollide: false });
	SLOT_OFFSETS.forEach(([dx, dz], s) => {
		part(`Base${n}Slot${s + 1}`, [base.x + dx, 2.15, base.z + dz], [4, 0.3, 4], c(240, 240, 245), { transparency: 0.25 });
	});
});

// ---- Weirdo Mart (west) ----
part('MartFloor', [-85, 1.5, 30], [20, 1, 16], c(200, 170, 120), { material: 'Wood' });
part('MartBackWall', [-85, 5, 22], [20, 8, 1], c(255, 150, 210));
part('MartSideWallL', [-95, 5, 30], [1, 8, 16], c(255, 150, 210));
part('MartSideWallR', [-75, 5, 30], [1, 8, 16], c(255, 150, 210));
part('MartRoof', [-85, 9.5, 30], [22, 1, 18], c(220, 80, 120));
part('MartCounter', [-85, 3, 26], [12, 2, 2], c(150, 110, 70), { material: 'Wood' });
part('MartSign', [-85, 12, 30], [10, 4, 0.6], c(40, 50, 70));

// ---- Rebirth portal (east) ----
part('PortalPostL', [80, 6, 30], [1, 10, 1], c(190, 130, 255), { material: 'Neon' });
part('PortalPostR', [90, 6, 30], [1, 10, 1], c(190, 130, 255), { material: 'Neon' });
part('PortalBeam', [85, 11, 30], [11, 1, 1], c(190, 130, 255), { material: 'Neon' });
part('PortalPanel', [85, 6, 30], [9, 9, 0.5], c(160, 80, 255), { material: 'Neon', transparency: 0.5, canCollide: false });
part('PortalBase', [85, 1.5, 30], [14, 1, 14], c(120, 90, 200));
part('PortalSign', [85, 13.5, 30], [10, 4, 0.6], c(40, 50, 70));

// ---- Trees ----
const TREES = [[-40, -50], [40, -50], [-105, -60], [105, -60], [-105, 60], [105, 60], [-40, 50], [40, 50], [-100, 0], [100, 0]];
TREES.forEach(([x, z], i) => {
	part(`Tree${i + 1}Trunk`, [x, 4, z], [2, 6, 2], c(120, 80, 40), { material: 'Wood' });
	part(`Tree${i + 1}Top`, [x, 9, z], [8, 8, 8], c(60, 170, 70), { shape: 'Ball', material: 'Grass' });
});

// ---- Lamps along the conveyor ----
[-60, -30, 0, 30, 60].forEach((x, i) => {
	part(`Lamp${i + 1}Pole`, [x, 4, -27], [0.8, 6, 0.8], c(50, 50, 60), { material: 'Metal' });
	part(`Lamp${i + 1}Bulb`, [x, 7.5, -27], [2, 2, 2], c(255, 230, 120), { shape: 'Ball', material: 'Neon', canCollide: false });
});

// ---- Clouds ----
const CLOUDS = [[-60, 40, -60, 16], [60, 48, -40, 20], [0, 38, 60, 14], [-80, 45, 40, 18], [80, 42, 70, 15]];
CLOUDS.forEach(([x, y, z, s], i) => {
	part(`Cloud${i + 1}`, [x, y, z], [s, s * 0.6, s], c(255, 255, 255), { shape: 'Ball', transparency: 0.2, canCollide: false });
});

// ---- The Noodle Tsunami wall (hidden until the wave sweeps) ----
part('WaveWall', [0, 12, -130], [220, 24, 4], c(255, 90, 160), { material: 'Neon', transparency: 1, canCollide: false });

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
			...parts,
		},
		Lighting: {
			$properties: {
				Ambient: [0.1, 0.1, 0.1],
				Brightness: 2,
				ClockTime: 14,
				GlobalShadows: true,
				Outlines: false,
				Technology: 'Voxel',
			},
		},
		SoundService: {
			$properties: { RespectFilteringEnabled: true },
		},
	},
};

writeFileSync(join(root, 'default.project.json'), JSON.stringify(project, null, 2) + '\n');
console.log(`wrote default.project.json with ${Object.keys(parts).length + 1} world instances`);
