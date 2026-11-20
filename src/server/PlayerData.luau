-- PlayerData: one live state table per player, plus their leaderstats.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)

local PlayerData = {}

local states = {}

-- Build a fresh state and its leaderstats for a player who just joined.
function PlayerData.create(player)
	local board = Instance.new("Folder")
	board.Name = "leaderstats"
	board.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.STARTING_CASH
	cash.Parent = board

	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = board

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = board

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = board

	local state = {
		player = player,
		baseIndex = nil,
		cash = Config.STARTING_CASH,
		rebirths = 0,
		incomeMultiplier = 1,
		placed = {},
		carried = nil,
		lockUntil = 0,
		lockCooldownUntil = 0,
		slapCooldownUntil = 0,
		upgrades = { speed = false, income = false, slots = false },
		slotCount = Config.BASE_SLOT_COUNT,
		leaderstats = board,
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
	local board = state.leaderstats
	if board then
		local cashValue = board:FindFirstChild("Cash")
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
	state.incomeMultiplier = 1 + Config.REBIRTH_MULTIPLIER_PER * count
	local board = state.leaderstats
	if board then
		local value = board:FindFirstChild("Rebirths")
		if value then
			value.Value = count
		end
	end
end

-- Dollars per second from every placed brainrot, with upgrades applied.
function PlayerData.calculateIncome(state)
	local total = 0
	for _, model in pairs(state.placed) do
		if model and model.Parent then
			total += model:GetAttribute("Rate") or 0
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
	local board = state.leaderstats
	if not board then
		return
	end
	local value = board:FindFirstChild("Brainrots")
	if value then
		value.Value = PlayerData.countPlaced(state)
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
	return math.max(0, math.floor(state.lockUntil - os.clock()))
end

return PlayerData
