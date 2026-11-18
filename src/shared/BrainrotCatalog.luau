-- BrainrotCatalog: every collectible weirdo in Brainrot Lagoon.
-- All characters, names and jokes are original to this game.
-- Each entry: id, display name, rarity, dollars earned per second, buy cost,
-- body colour, body shape, accessory and a one-line joke shown in the catalog.

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

-- Rarity ladder, cheapest first. Rarity colours are used by the labels and the HUD.
BrainrotCatalog.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(120, 220, 120), spawnWeight = 46 },
	Rare = { order = 2, color = Color3.fromRGB(90, 170, 255), spawnWeight = 26 },
	Epic = { order = 3, color = Color3.fromRGB(190, 110, 255), spawnWeight = 15 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 205, 60), spawnWeight = 8 },
	Mythic = { order = 5, color = Color3.fromRGB(255, 90, 90), spawnWeight = 4 },
	Secret = { order = 6, color = Color3.fromRGB(255, 120, 220), spawnWeight = 1 },
}

BrainrotCatalog.MUTATIONS = {
	{ name = "Normal", multiplier = 1, chance = 70, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Frozen", multiplier = 2, chance = 14, color = Color3.fromRGB(150, 220, 255) },
	{ name = "Golden", multiplier = 3, chance = 9, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Spicy", multiplier = 5, chance = 5, color = Color3.fromRGB(255, 90, 40) },
	{ name = "Rainbow", multiplier = 8, chance = 2, color = Color3.fromRGB(255, 120, 220) },
}

BrainrotCatalog.CHARACTERS = {
	{ id = "sock_sam", name = "Soggy Sock Sam", rarity = "Common", rate = 2, cost = 25,
		color = Color3.fromRGB(150, 160, 190), shape = "Box", accessory = "none",
		joke = "Left in the rain since 2019. Still damp. Still vibing." },
	{ id = "toaster_terry", name = "Toaster Terry", rarity = "Common", rate = 4, cost = 75,
		color = Color3.fromRGB(200, 200, 205), shape = "Box", accessory = "antenna",
		joke = "Pops up when nobody asks. Burns everything on purpose." },
	{ id = "chairman_chair", name = "Chairman Chair", rarity = "Common", rate = 7, cost = 150,
		color = Color3.fromRGB(160, 110, 60), shape = "Box", accessory = "crown",
		joke = "CEO of sitting down. Holds meetings. Never stands." },
	{ id = "banana_bus", name = "Banana Bus Barry", rarity = "Rare", rate = 15, cost = 400,
		color = Color3.fromRGB(255, 220, 40), shape = "Box", accessory = "wheels",
		joke = "A bus. A banana. No brakes, no license, no regrets." },
	{ id = "sir_puddles", name = "Sir Puddles III", rarity = "Rare", rate = 25, cost = 800,
		color = Color3.fromRGB(90, 160, 255), shape = "Ball", accessory = "crown",
		joke = "Third of his name, first of his puddle. Very damp royalty." },
	{ id = "dj_fridge", name = "DJ Fridge", rarity = "Rare", rate = 40, cost = 1500,
		color = Color3.fromRGB(220, 235, 255), shape = "Box", accessory = "antenna",
		joke = "Drops beats and leftovers. The hum is the bassline." },
	{ id = "crunchwrap", name = "Captain Crunchwrap", rarity = "Epic", rate = 80, cost = 4000,
		color = Color3.fromRGB(230, 170, 60), shape = "Cylinder", accessory = "hat",
		joke = "Sailed the seven salsas. Crunchy on the outside, hero inside." },
	{ id = "leftovers", name = "The Forbidden Leftovers", rarity = "Epic", rate = 140, cost = 8000,
		color = Color3.fromRGB(120, 200, 90), shape = "Box", accessory = "none",
		joke = "Do NOT eat after midnight. Do NOT eat at all. It earns, though." },
	{ id = "quantum_pickle", name = "Quantum Pickle", rarity = "Legendary", rate = 300, cost = 20000,
		color = Color3.fromRGB(80, 200, 80), shape = "Cylinder", accessory = "antenna",
		joke = "In two fridges at once until you look at it." },
	{ id = "gato_wifi", name = "El Gato WiFi", rarity = "Legendary", rate = 500, cost = 35000,
		color = Color3.fromRGB(255, 170, 60), shape = "Ball", accessory = "hat",
		joke = "The password is 'meow'. The signal is purrfect." },
	{ id = "grandma_router", name = "Grandma's Router", rarity = "Mythic", rate = 1200, cost = 90000,
		color = Color3.fromRGB(255, 255, 255), shape = "Box", accessory = "antenna",
		joke = "Blinking since 2007. Unplug it and the whole lagoon dies." },
	{ id = "chungus_prime", name = "Chungus Prime", rarity = "Secret", rate = 3000, cost = 250000,
		color = Color3.fromRGB(255, 120, 220), shape = "Ball", accessory = "crown",
		joke = "He does not walk. The lagoon moves for him." },
}

-- Look a character up by its id. Returns nil for an unknown id.
function BrainrotCatalog.getById(id: string): BrainrotEntry?
	for _, entry in ipairs(BrainrotCatalog.CHARACTERS) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Weighted random pick over the rarity ladder, then a random character of it.
function BrainrotCatalog.rollCharacter(): BrainrotEntry
	local total = 0
	for _, rarity in pairs(BrainrotCatalog.RARITIES) do
		total += rarity.spawnWeight
	end
	local roll = math.random(1, total)
	local pickedRarity: RarityName? = nil
	for name, rarity in pairs(BrainrotCatalog.RARITIES) do
		roll -= rarity.spawnWeight
		if roll <= 0 then
			pickedRarity = name :: RarityName
			break
		end
	end
	local pool = {}
	for _, entry in ipairs(BrainrotCatalog.CHARACTERS) do
		if entry.rarity == pickedRarity then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.CHARACTERS[1]
	end
	return pool[math.random(1, #pool)]
end

-- Weighted random mutation roll. Most spawns are Normal.
function BrainrotCatalog.rollMutation(): { name: string, multiplier: number, color: Color3 }
	local roll = math.random(1, 100)
	local acc = 0
	for _, mutation in ipairs(BrainrotCatalog.MUTATIONS) do
		acc += mutation.chance
		if roll <= acc then
			return mutation
		end
	end
	return BrainrotCatalog.MUTATIONS[1]
end

-- "$1,234" style money text for the HUD and labels.
function BrainrotCatalog.formatMoney(amount: number): string
	local whole = math.floor(amount + 0.5)
	local text = tostring(whole)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, #text - 3)
	end
	return "$" .. text .. out
end

return BrainrotCatalog
