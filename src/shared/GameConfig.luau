-- GameConfig: the tuning numbers and map layout every service shares.
-- Island top surface is y = 1. Bases and the conveyor sit on top of it.

local GameConfig = {}

GameConfig.GAME_NAME = "Brainrot Lagoon"
GameConfig.STARTING_CASH = 100
GameConfig.MAX_PLAYERS = 6
GameConfig.BASE_SLOT_COUNT = 8
GameConfig.BASE_SLOT_COUNT_UPGRADED = 12

-- The six base plots around the island, in the order players claim them.
GameConfig.BASES = {
	{ position = Vector3.new(-72, 1.5, -72), color = Color3.fromRGB(255, 120, 120) },
	{ position = Vector3.new(0, 1.5, -72), color = Color3.fromRGB(120, 180, 255) },
	{ position = Vector3.new(72, 1.5, -72), color = Color3.fromRGB(120, 230, 140) },
	{ position = Vector3.new(-72, 1.5, 72), color = Color3.fromRGB(255, 210, 90) },
	{ position = Vector3.new(0, 1.5, 72), color = Color3.fromRGB(200, 130, 255) },
	{ position = Vector3.new(72, 1.5, 72), color = Color3.fromRGB(255, 150, 210) },
}
GameConfig.BASE_SIZE = 26
GameConfig.BASE_TOP_Y = 2

-- Brainrot slot pads on a base: two rows of four, relative to the base centre.
GameConfig.SLOT_OFFSETS = {
	Vector3.new(-9, 0, -6), Vector3.new(-3, 0, -6), Vector3.new(3, 0, -6), Vector3.new(9, 0, -6),
	Vector3.new(-9, 0, 6), Vector3.new(-3, 0, 6), Vector3.new(3, 0, 6), Vector3.new(9, 0, 6),
}
GameConfig.SLOT_OFFSETS_UPGRADED = {
	Vector3.new(-9, 0, -9), Vector3.new(-3, 0, -9), Vector3.new(3, 0, -9), Vector3.new(9, 0, -9),
	Vector3.new(-9, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(3, 0, 0), Vector3.new(9, 0, 0),
	Vector3.new(-9, 0, 9), Vector3.new(-3, 0, 9), Vector3.new(3, 0, 9), Vector3.new(9, 0, 9),
}

-- The weirdo conveyor: brainrots walk west to east along the middle of the map.
GameConfig.CONVEYOR_START = Vector3.new(-95, 2, -20)
GameConfig.CONVEYOR_END = Vector3.new(95, 2, -20)
GameConfig.CONVEYOR_WALK_SPEED = 6
GameConfig.CONVEYOR_SPAWN_INTERVAL = 7
GameConfig.CONVEYOR_MAX_WALKING = 8
GameConfig.FOLLOW_SPEED = 18

-- The Noodle Tsunami: warning, then a wall sweeps the map north to south.
GameConfig.WAVE_CYCLE_SECONDS = 100
GameConfig.WAVE_WARNING_SECONDS = 10
GameConfig.WAVE_SWEEP_SECONDS = 10
GameConfig.WAVE_START_Z = -130
GameConfig.WAVE_END_Z = 130

-- Base lock: how long a lock lasts and how long before it can be used again.
GameConfig.LOCK_DURATION = 60
GameConfig.LOCK_COOLDOWN = 120

-- Stealing and slapping.
GameConfig.SLAP_RANGE = 10
GameConfig.SLAP_COOLDOWN = 3
GameConfig.SLAP_KNOCKBACK = 55

-- Rebirth: cost doubles each time; each rebirth adds +50% income.
GameConfig.REBIRTH_BASE_COST = 100000
GameConfig.REBIRTH_MULTIPLIER_PER = 0.5

-- Cash shop upgrades (bought from the HUD).
GameConfig.UPGRADES = {
	speed = { name = "Speed Boots", cost = 5000, description = "Walk speed 16 -> 24" },
	income = { name = "Double Scoop", cost = 50000, description = "All income x2, forever" },
	slots = { name = "Base Extension", cost = 25000, description = "4 extra base slots (12 total)" },
}

GameConfig.SPAWN_POINT = Vector3.new(0, 3, 95)

return GameConfig
