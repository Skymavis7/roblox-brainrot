-- BrainrotCatalog: the 12 original characters, 6 rarities and 5 mutations.
-- Pure data plus the two rolls and a money formatter. No Roblox services.

local Catalog = {}

Catalog.RARITIES = {
	{ name = "Common", order = 1, color = Color3.fromRGB(120, 220, 120), weight = 46 },
	{ name = "Rare", order = 2, color = Color3.fromRGB(90, 170, 255), weight = 26 },
	{ name = "Epic", order = 3, color = Color3.fromRGB(190, 110, 255), weight = 15 },
	{ name = "Legendary", order = 4, color = Color3.fromRGB(255, 205, 60), weight = 8 },
	{ name = "Mythic", order = 5, color = Color3.fromRGB(255, 90, 90), weight = 4 },
	{ name = "Secret", order = 6, color = Color3.fromRGB(255, 120, 220), weight = 1 },
}

Catalog.MUTATIONS = {
	{ name = "Normal", multiplier = 1, chance = 70, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Frozen", multiplier = 2, chance = 14, color = Color3.fromRGB(150, 220, 255) },
	{ name = "Golden", multiplier = 3, chance = 9, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Spicy", multiplier = 5, chance = 5, color = Color3.fromRGB(255, 90, 40) },
	{ name = "Rainbow", multiplier = 8, chance = 2, color = Color3.fromRGB(255, 120, 220) },
}

Catalog.CHARACTERS = {
	{
		id = "sock_sam",
		name = "Soggy Sock Sam",
		rarity = "Common",
		rate = 2,
		cost = 25,
		color = Color3.fromRGB(150, 160, 190),
		shape = "Box",
		accessory = "none",
		joke = "Left in the rain since 2019. Still damp. Still vibing.",
	},
	{
		id = "toaster_terry",
		name = "Toaster Terry",
		rarity = "Common",
		rate = 4,
		cost = 75,
		color = Color3.fromRGB(200, 200, 205),
		shape = "Box",
		accessory = "antenna",
		joke = "Pops up when nobody asks. Burns everything on purpose.",
	},
	{
		id = "chairman_chair",
		name = "Chairman Chair",
		rarity = "Common",
		rate = 7,
		cost = 150,
		color = Color3.fromRGB(160, 110, 60),
		shape = "Box",
		accessory = "crown",
		joke = "CEO of sitting down. Holds meetings. Never stands.",
	},
	{
		id = "banana_bus",
		name = "Banana Bus Barry",
		rarity = "Rare",
		rate = 15,
		cost = 400,
		color = Color3.fromRGB(255, 220, 40),
		shape = "Box",
		accessory = "wheels",
		joke = "A bus. A banana. No brakes, no license, no regrets.",
	},
	{
		id = "sir_puddles",
		name = "Sir Puddles III",
		rarity = "Rare",
		rate = 25,
		cost = 800,
		color = Color3.fromRGB(90, 160, 255),
		shape = "Ball",
		accessory = "crown",
		joke = "Third of his name, first of his puddle. Very damp royalty.",
	},
	{
		id = "dj_fridge",
		name = "DJ Fridge",
		rarity = "Rare",
		rate = 40,
		cost = 1500,
		color = Color3.fromRGB(220, 235, 255),
		shape = "Box",
		accessory = "antenna",
		joke = "Drops beats and leftovers. The hum is the bassline.",
	},
	{
		id = "crunchwrap",
		name = "Captain Crunchwrap",
		rarity = "Epic",
		rate = 80,
		cost = 4000,
		color = Color3.fromRGB(230, 170, 60),
		shape = "Cylinder",
		accessory = "hat",
		joke = "Sailed the seven salsas. Crunchy on the outside, hero inside.",
	},
	{
		id = "leftovers",
		name = "The Forbidden Leftovers",
		rarity = "Epic",
		rate = 140,
		cost = 8000,
		color = Color3.fromRGB(120, 200, 90),
		shape = "Box",
		accessory = "none",
		joke = "Do NOT eat after midnight. Do NOT eat at all. It earns, though.",
	},
	{
		id = "quantum_pickle",
		name = "Quantum Pickle",
		rarity = "Legendary",
		rate = 300,
		cost = 20000,
		color = Color3.fromRGB(80, 200, 80),
		shape = "Cylinder",
		accessory = "antenna",
		joke = "In two fridges at once until you look at it.",
	},
	{
		id = "gato_wifi",
		name = "El Gato WiFi",
		rarity = "Legendary",
		rate = 500,
		cost = 35000,
		color = Color3.fromRGB(255, 170, 60),
		shape = "Ball",
		accessory = "hat",
		joke = "The password is 'meow'. The signal is purrfect.",
	},
	{
		id = "grandma_router",
		name = "Grandma's Router",
		rarity = "Mythic",
		rate = 1200,
		cost = 90000,
		color = Color3.fromRGB(255, 255, 255),
		shape = "Box",
		accessory = "antenna",
		joke = "Blinking since 2007. Unplug it and the whole lagoon dies.",
	},
	{
		id = "chungus_prime",
		name = "Chungus Prime",
		rarity = "Secret",
		rate = 3000,
		cost = 250000,
		color = Color3.fromRGB(255, 120, 220),
		shape = "Ball",
		accessory = "crown",
		joke = "He does not walk. The lagoon moves for him.",
	},
}

local function rarityByName(name)
	for _, rarity in ipairs(Catalog.RARITIES) do
		if rarity.name == name then
			return rarity
		end
	end
	return Catalog.RARITIES[1]
end

function Catalog.getById(id)
	for _, entry in ipairs(Catalog.CHARACTERS) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

function Catalog.rollCharacter()
	local total = 0
	for _, rarity in ipairs(Catalog.RARITIES) do
		total += rarity.weight
	end
	local roll = math.random(1, total)
	local picked = Catalog.RARITIES[1]
	for _, rarity in ipairs(Catalog.RARITIES) do
		roll -= rarity.weight
		if roll <= 0 then
			picked = rarity
			break
		end
	end
	local pool = {}
	for _, entry in ipairs(Catalog.CHARACTERS) do
		if entry.rarity == picked.name then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return Catalog.CHARACTERS[1]
	end
	return pool[math.random(1, #pool)]
end

function Catalog.rollMutation()
	local roll = math.random(1, 100)
	local running = 0
	for _, mutation in ipairs(Catalog.MUTATIONS) do
		running += mutation.chance
		if roll <= running then
			return mutation
		end
	end
	return Catalog.MUTATIONS[1]
end

function Catalog.rarityColor(name)
	return rarityByName(name).color
end

function Catalog.formatMoney(amount)
	local whole = math.floor(amount + 0.5)
	local text = tostring(whole)
	local grouped = ""
	while #text > 3 do
		grouped = "," .. string.sub(text, -3) .. grouped
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. grouped
end

return Catalog
