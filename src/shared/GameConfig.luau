-- GameConfig: every number the game runs on, in one place.

local Config = {}

Config.GAME_NAME = "Brainrot Lagoon"
Config.STARTING_CASH = 100
Config.MAX_PLAYERS = 6

Config.BASE_SLOT_COUNT = 8
Config.BASE_SLOT_COUNT_UPGRADED = 12
Config.BASE_SIZE = 26
Config.BASE_TOP_Y = 2

-- Six plots, claimed in this order as players join.
Config.BASES = {
	{ center = Vector3.new(-72, 0, -72), color = Color3.fromRGB(255, 120, 120) },
	{ center = Vector3.new(0, 0, -72), color = Color3.fromRGB(120, 180, 255) },
	{ center = Vector3.new(72, 0, -72), color = Color3.fromRGB(120, 230, 140) },
	{ center = Vector3.new(-72, 0, 72), color = Color3.fromRGB(255, 210, 90) },
	{ center = Vector3.new(0, 0, 72), color = Color3.fromRGB(200, 130, 255) },
	{ center = Vector3.new(72, 0, 72), color = Color3.fromRGB(255, 150, 210) },
}

-- Slot offsets from the plot centre: two rows of four.
Config.SLOT_OFFSETS = {
	Vector3.new(-9, 0, -6),
	Vector3.new(-3, 0, -6),
	Vector3.new(3, 0, -6),
	Vector3.new(9, 0, -6),
	Vector3.new(-9, 0, 6),
	Vector3.new(-3, 0, 6),
	Vector3.new(3, 0, 6),
	Vector3.new(9, 0, 6),
}

-- Upgraded slots: three rows of four.
Config.SLOT_OFFSETS_UPGRADED = {
	Vector3.new(-9, 0, -9),
	Vector3.new(-3, 0, -9),
	Vector3.new(3, 0, -9),
	Vector3.new(9, 0, -9),
	Vector3.new(-9, 0, 0),
	Vector3.new(-3, 0, 0),
	Vector3.new(3, 0, 0),
	Vector3.new(9, 0, 0),
	Vector3.new(-9, 0, 9),
	Vector3.new(-3, 0, 9),
	Vector3.new(3, 0, 9),
	Vector3.new(9, 0, 9),
}

-- Conveyor
Config.CONVEYOR_START = Vector3.new(-95, 2, -20)
Config.CONVEYOR_END = Vector3.new(95, 2, -20)
Config.CONVEYOR_WALK_SPEED = 6
Config.CONVEYOR_SPAWN_INTERVAL = 7
Config.CONVEYOR_MAX_WALKING = 8
Config.CONVEYOR_FOLLOW_SPEED = 18

-- Noodle Tsunami
Config.WAVE_CYCLE_SECONDS = 100
Config.WAVE_WARNING_SECONDS = 10
Config.WAVE_SWEEP_SECONDS = 10
Config.WAVE_START_Z = -130
Config.WAVE_END_Z = 130

-- Base lock
Config.LOCK_DURATION = 60
Config.LOCK_COOLDOWN = 120

-- Slap
Config.SLAP_RANGE = 10
Config.SLAP_COOLDOWN = 3
Config.SLAP_KNOCKBACK = 55

-- Rebirth
Config.REBIRTH_BASE_COST = 100000
Config.REBIRTH_MULTIPLIER_PER = 0.5

-- Cash shop upgrades
Config.UPGRADES = {
	speed = {
		name = "Speed Boots",
		cost = 5000,
		description = "Walk speed 16 -> 24",
	},
	income = {
		name = "Double Scoop",
		cost = 50000,
		description = "All income x2, forever",
	},
	slots = {
		name = "Base Extension",
		cost = 25000,
		description = "4 extra base slots (12 total)",
	},
}

Config.SPAWN_POINT = Vector3.new(0, 3, 95)

return Config
