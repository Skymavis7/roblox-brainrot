-- GameConfig — the tuning table every service reads from.
-- The island's top surface sits at y = 1; the bases and the conveyor ride on
-- top of it at y = 2. Change a number here and the whole game retunes.

local GameConfig = {}

GameConfig.GAME_NAME = "Brainrot Lagoon"
GameConfig.STARTING_CASH = 100
GameConfig.MAX_PLAYERS = 6

-- Bases: how many brainrots one fits, and how many after the shop extension.
GameConfig.BASE_SLOT_COUNT = 8
GameConfig.BASE_SLOT_COUNT_UPGRADED = 12
GameConfig.BASE_SIZE = 26
GameConfig.BASE_TOP_Y = 2

-- The six base plots, claimed in this order as players join. Each entry is the
-- plot centre (y is the platform top) plus the plot's colour.
local function basePlot(x: number, z: number, r: number, g: number, b: number)
	return { position = Vector3.new(x, 1.5, z), color = Color3.fromRGB(r, g, b) }
end

GameConfig.BASES = {
	basePlot(-72, -72, 255, 120, 120),
	basePlot(0, -72, 120, 180, 255),
	basePlot(72, -72, 120, 230, 140),
	basePlot(-72, 72, 255, 210, 90),
	basePlot(0, 72, 200, 130, 255),
	basePlot(72, 72, 255, 150, 210),
}

-- Where a brainrot stands on its base: two rows of four, measured from the
-- plot centre; three rows of four once the base is extended.
local function slot(dx: number, dz: number)
	return Vector3.new(dx, 0, dz)
end

GameConfig.SLOT_OFFSETS = {
	slot(-9, -6), slot(-3, -6), slot(3, -6), slot(9, -6),
	slot(-9, 6), slot(-3, 6), slot(3, 6), slot(9, 6),
}
GameConfig.SLOT_OFFSETS_UPGRADED = {
	slot(-9, -9), slot(-3, -9), slot(3, -9), slot(9, -9),
	slot(-9, 0), slot(-3, 0), slot(3, 0), slot(9, 0),
	slot(-9, 9), slot(-3, 9), slot(3, 9), slot(9, 9),
}

-- The weirdo conveyor: brainrots stroll west to east along z = -20, and a
-- bought one trails its owner home at FOLLOW_SPEED.
GameConfig.CONVEYOR_START = Vector3.new(-95, 2, -20)
GameConfig.CONVEYOR_END = Vector3.new(95, 2, -20)
GameConfig.CONVEYOR_WALK_SPEED = 6
GameConfig.CONVEYOR_SPAWN_INTERVAL = 7
GameConfig.CONVEYOR_MAX_WALKING = 8
GameConfig.FOLLOW_SPEED = 18

-- The Noodle Tsunami: one full calm stretch, a short warning, then the wall
-- rolls from the north edge of the map to the south edge.
GameConfig.WAVE_CYCLE_SECONDS = 100
GameConfig.WAVE_WARNING_SECONDS = 10
GameConfig.WAVE_SWEEP_SECONDS = 10
GameConfig.WAVE_START_Z = -130
GameConfig.WAVE_END_Z = 130

-- Base lock: how long it holds, and how long before it can be raised again.
GameConfig.LOCK_DURATION = 60
GameConfig.LOCK_COOLDOWN = 120

-- Slapping: reach, how often, and how hard the victim is thrown.
GameConfig.SLAP_RANGE = 10
GameConfig.SLAP_COOLDOWN = 3
GameConfig.SLAP_KNOCKBACK = 55

-- Rebirth: the first one costs the base price and each next one doubles it;
-- every rebirth adds this much income, forever.
GameConfig.REBIRTH_BASE_COST = 100000
GameConfig.REBIRTH_MULTIPLIER_PER = 0.5

-- The cash shop: one of each, bought once, kept forever.
GameConfig.UPGRADES = {
	speed = { name = "Speed Boots", cost = 5000, description = "Walk speed 16 -> 24" },
	income = { name = "Double Scoop", cost = 50000, description = "All income x2, forever" },
	slots = { name = "Base Extension", cost = 25000, description = "4 extra base slots (12 total)" },
}

-- Where a caught player is flung back to.
GameConfig.SPAWN_POINT = Vector3.new(0, 3, 95)

return GameConfig
