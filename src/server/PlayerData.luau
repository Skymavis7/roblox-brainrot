-- PlayerData: one live state table per player, plus the leaderstats mirror.
-- Nothing here talks to the network; other services read and mutate states.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlayerData = {}
local states = {}

function PlayerData.create(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = GameConfig.STARTING_CASH
	cash.Parent = folder

	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = folder

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = folder

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = folder

	local state = {
		player = player,
		baseIndex = nil,
		cash = GameConfig.STARTING_CASH,
		rebirths = 0,
		incomeMultiplier = 1,
		placed = {},
		carried = nil,
		lockUntil = 0,
		lockCooldownUntil = 0,
		slapCooldownUntil = 0,
		upgrades = { speed = false, income = false, slots = false },
		slotCount = GameConfig.BASE_SLOT_COUNT,
		leaderstats = folder,
	}
	states[player] = state
	return state
end

function PlayerData.get(player)
	return states[player]
end

function PlayerData.remove(player)
	states[player] = nil
end

function PlayerData.all()
	return states
end

function PlayerData.setCash(state, amount)
	local value = math.floor(amount)
	if value < 0 then
		value = 0
	end
	state.cash = value
	local folder = state.leaderstats
	if folder then
		local cashValue = folder:FindFirstChild("Cash")
		if cashValue then
			cashValue.Value = value
		end
	end
end

function PlayerData.addCash(state, amount)
	PlayerData.setCash(state, state.cash + amount)
end

function PlayerData.setRebirths(state, count)
	state.rebirths = count
	state.incomeMultiplier = 1 + GameConfig.REBIRTH_MULTIPLIER_PER * count
	local folder = state.leaderstats
	if folder then
		local rebirthValue = folder:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = count
		end
	end
end

function PlayerData.calculateIncome(state)
	local total = 0
	for _, model in pairs(state.placed) do
		local rate = model:GetAttribute("Rate")
		if typeof(rate) == "number" then
			total += rate
		end
	end
	if state.upgrades.income then
		total *= 2
	end
	return total * state.incomeMultiplier
end

function PlayerData.countPlaced(state)
	local count = 0
	for _ in pairs(state.placed) do
		count += 1
	end
	return count
end

function PlayerData.refreshBrainrotCount(state)
	local folder = state.leaderstats
	if folder then
		local value = folder:FindFirstChild("Brainrots")
		if value then
			value.Value = PlayerData.countPlaced(state)
		end
	end
end

function PlayerData.firstFreeSlot(state)
	for slot = 1, state.slotCount do
		if state.placed[slot] == nil then
			return slot
		end
	end
	return nil
end

function PlayerData.isBaseLocked(state)
	return os.clock() < state.lockUntil
end

function PlayerData.lockSecondsLeft(state)
	local left = state.lockUntil - os.clock()
	if left <= 0 then
		return 0
	end
	return math.floor(left)
end

return PlayerData
