-- BrainrotCatalog — the whole cast of Brainrot Lagoon.
-- Every character, name and joke here is original to this game. An entry holds
-- its id, display name, rarity, dollars per second, buy cost, body colour,
-- body shape, accessory and the one-line joke the catalog shows.

local BrainrotCatalog = {}

export type RarityName = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type BrainrotEntry = {
	id: string,
	name: string,
	rarity: RarityName,
	rate: number,
	cost: number,
	color: Color3,
	shape: string,
	accessory: string,
	joke: string,
}

-- The rarity ladder, cheapest first. The colour shows on labels and in the HUD;
-- the weight decides how often the rarity is rolled.
local function rarity(order: number, r: number, g: number, b: number, weight: number)
	return { order = order, color = Color3.fromRGB(r, g, b), spawnWeight = weight }
end

BrainrotCatalog.RARITIES = {
	Common = rarity(1, 120, 220, 120, 46),
	Rare = rarity(2, 90, 170, 255, 26),
	Epic = rarity(3, 190, 110, 255, 15),
	Legendary = rarity(4, 255, 205, 60, 8),
	Mythic = rarity(5, 255, 90, 90, 4),
	Secret = rarity(6, 255, 120, 220, 1),
}

-- What a spawn can come out as. The chances add to 100; most spawns are Normal.
BrainrotCatalog.MUTATIONS = {
	{ name = "Normal", multiplier = 1, chance = 70, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Frozen", multiplier = 2, chance = 14, color = Color3.fromRGB(150, 220, 255) },
	{ name = "Golden", multiplier = 3, chance = 9, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Spicy", multiplier = 5, chance = 5, color = Color3.fromRGB(255, 90, 40) },
	{ name = "Rainbow", multiplier = 8, chance = 2, color = Color3.fromRGB(255, 120, 220) },
}

local function character(id: string, name: string, rarityName: RarityName, rate: number, cost: number,
		r: number, g: number, b: number, shape: string, accessory: string, joke: string): BrainrotEntry
	return {
		id = id,
		name = name,
		rarity = rarityName,
		rate = rate,
		cost = cost,
		color = Color3.fromRGB(r, g, b),
		shape = shape,
		accessory = accessory,
		joke = joke,
	}
end

BrainrotCatalog.CHARACTERS = {
	character("sock_sam", "Soggy Sock Sam", "Common", 2, 25,
		150, 160, 190, "Box", "none",
		"Left in the rain since 2019. Still damp. Still vibing."),
	character("toaster_terry", "Toaster Terry", "Common", 4, 75,
		200, 200, 205, "Box", "antenna",
		"Pops up when nobody asks. Burns everything on purpose."),
	character("chairman_chair", "Chairman Chair", "Common", 7, 150,
		160, 110, 60, "Box", "crown",
		"CEO of sitting down. Holds meetings. Never stands."),
	character("banana_bus", "Banana Bus Barry", "Rare", 15, 400,
		255, 220, 40, "Box", "wheels",
		"A bus. A banana. No brakes, no license, no regrets."),
	character("sir_puddles", "Sir Puddles III", "Rare", 25, 800,
		90, 160, 255, "Ball", "crown",
		"Third of his name, first of his puddle. Very damp royalty."),
	character("dj_fridge", "DJ Fridge", "Rare", 40, 1500,
		220, 235, 255, "Box", "antenna",
		"Drops beats and leftovers. The hum is the bassline."),
	character("crunchwrap", "Captain Crunchwrap", "Epic", 80, 4000,
		230, 170, 60, "Cylinder", "hat",
		"Sailed the seven salsas. Crunchy on the outside, hero inside."),
	character("leftovers", "The Forbidden Leftovers", "Epic", 140, 8000,
		120, 200, 90, "Box", "none",
		"Do NOT eat after midnight. Do NOT eat at all. It earns, though."),
	character("quantum_pickle", "Quantum Pickle", "Legendary", 300, 20000,
		80, 200, 80, "Cylinder", "antenna",
		"In two fridges at once until you look at it."),
	character("gato_wifi", "El Gato WiFi", "Legendary", 500, 35000,
		255, 170, 60, "Ball", "hat",
		"The password is 'meow'. The signal is purrfect."),
	character("grandma_router", "Grandma's Router", "Mythic", 1200, 90000,
		255, 255, 255, "Box", "antenna",
		"Blinking since 2007. Unplug it and the whole lagoon dies."),
	character("chungus_prime", "Chungus Prime", "Secret", 3000, 250000,
		255, 120, 220, "Ball", "crown",
		"He does not walk. The lagoon moves for him."),
}

-- Find one character by id; nil when the id is unknown.
function BrainrotCatalog.getById(id: string): BrainrotEntry?
	for _, entry in ipairs(BrainrotCatalog.CHARACTERS) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Roll a rarity by its weight, then a random character of that rarity.
-- The ladder is walked in order so the roll is the same every run.
function BrainrotCatalog.rollCharacter(): BrainrotEntry
	local ladder: { RarityName } = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
	local total = 0
	for _, name in ipairs(ladder) do
		total += BrainrotCatalog.RARITIES[name].spawnWeight
	end
	local roll = math.random(1, total)
	local picked: RarityName = "Common"
	for _, name in ipairs(ladder) do
		roll -= BrainrotCatalog.RARITIES[name].spawnWeight
		if roll <= 0 then
			picked = name
			break
		end
	end
	local pool = {}
	for _, entry in ipairs(BrainrotCatalog.CHARACTERS) do
		if entry.rarity == picked then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.CHARACTERS[1]
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation by its chance. Falls back to the first entry (Normal).
function BrainrotCatalog.rollMutation(): { name: string, multiplier: number, color: Color3 }
	local roll = math.random(1, 100)
	local seen = 0
	for _, mutation in ipairs(BrainrotCatalog.MUTATIONS) do
		seen += mutation.chance
		if roll <= seen then
			return mutation
		end
	end
	return BrainrotCatalog.MUTATIONS[1]
end

-- "$1,234" style money text, for the HUD and the floating labels.
function BrainrotCatalog.formatMoney(amount: number): string
	local digits = tostring(math.floor(amount + 0.5))
	local grouped = ""
	while #digits > 3 do
		grouped = "," .. string.sub(digits, -3) .. grouped
		digits = string.sub(digits, 1, #digits - 3)
	end
	return "$" .. digits .. grouped
end

return BrainrotCatalog
