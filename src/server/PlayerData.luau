-- PlayerData: the one place that holds a player's live state.
-- Cash lives in leaderstats (so the HUD can read it); everything else lives here.
-- No other service keeps its own copy of these numbers.

local Players = game:GetService("Players")

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))

local PlayerData = {}

export type PlayerState = {
	player: Player,
	baseIndex: number?,
	cash: number,
	rebirths: number,
	incomeMultiplier: number,
	placed: { [number]: Model }, -- slot index -> brainrot model on the base
	carried: Model?, -- brainrot currently following the player
	lockUntil: number,
	lockCooldownUntil: number,
	slapCooldownUntil: number,
	upgrades: { speed: boolean, income: boolean, slots: boolean },
	slotCount: number,
}

local states: { [Player]: PlayerState } = {}

-- Create the state for a player who just joined, with their leaderstats.
function PlayerData.create(player: Player): PlayerState
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = GameConfig.STARTING_CASH
	cash.Parent = leaderstats

	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	local brainrots = Instance.new("IntValue")
	brainrots.Name = "Brainrots"
	brainrots.Value = 0
	brainrots.Parent = leaderstats

	local state: PlayerState = {
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
	}
	states[player] = state
	return state
end

function PlayerData.get(player: Player): PlayerState?
	return states[player]
end

-- Drop the state when a player leaves (their brainrots go with them).
function PlayerData.remove(player: Player)
	states[player] = nil
end

function PlayerData.all(): { [Player]: PlayerState }
	return states
end

-- Cash and leaderstats always move together.
function PlayerData.setCash(state: PlayerState, amount: number)
	state.cash = math.max(0, math.floor(amount))
	local leaderstats = state.player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashValue = leaderstats:FindFirstChild("Cash")
		if cashValue and cashValue:IsA("IntValue") then
			cashValue.Value = state.cash
		end
	end
end

function PlayerData.addCash(state: PlayerState, amount: number)
	PlayerData.setCash(state, state.cash + amount)
end

function PlayerData.setRebirths(state: PlayerState, count: number)
	state.rebirths = count
	state.incomeMultiplier = 1 + GameConfig.REBIRTH_MULTIPLIER_PER * count
	local leaderstats = state.player:FindFirstChild("leaderstats")
	if leaderstats then
		local value = leaderstats:FindFirstChild("Rebirths")
		if value and value:IsA("IntValue") then
			value.Value = count
		end
	end
end

-- Dollars per second from everything sitting on this player's base.
function PlayerData.calculateIncome(state: PlayerState): number
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

-- How many brainrots sit on the player's base right now.
function PlayerData.countPlaced(state: PlayerState): number
	local count = 0
	for _ in pairs(state.placed) do
		count += 1
	end
	return count
end

function PlayerData.refreshBrainrotCount(state: PlayerState)
	local leaderstats = state.player:FindFirstChild("leaderstats")
	if leaderstats then
		local value = leaderstats:FindFirstChild("Brainrots")
		if value and value:IsA("IntValue") then
			value.Value = PlayerData.countPlaced(state)
		end
	end
end

-- First free slot on the player's base, or nil when it is full.
function PlayerData.firstFreeSlot(state: PlayerState): number?
	for slot = 1, state.slotCount do
		if state.placed[slot] == nil then
			return slot
		end
	end
	return nil
end

-- Is this player's base locked against stealing right now?
function PlayerData.isBaseLocked(state: PlayerState): boolean
	return os.clock() < state.lockUntil
end

-- Seconds left on the base lock, or 0.
function PlayerData.lockSecondsLeft(state: PlayerState): number
	return math.max(0, math.floor(state.lockUntil - os.clock()))
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.remove(player)
end)

return PlayerData
