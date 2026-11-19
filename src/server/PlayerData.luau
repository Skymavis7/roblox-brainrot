-- PlayerData — the single place that holds a player's live state.
-- Cash is mirrored in leaderstats so the HUD can watch it; everything else
-- lives only here. No other service keeps its own copy of these numbers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local PlayerData = {}

export type PlayerState = {
	player: Player,
	baseIndex: number?,
	cash: number,
	rebirths: number,
	incomeMultiplier: number,
	placed: { [number]: Model }, -- slot index -> brainrot model standing on the base
	carried: Model?, -- brainrot currently trailing the player
	lockUntil: number,
	lockCooldownUntil: number,
	slapCooldownUntil: number,
	upgrades: { speed: boolean, income: boolean, slots: boolean },
	slotCount: number,
}

local byPlayer: { [Player]: PlayerState } = {}

-- Set one leaderstat IntValue on a player, when it exists and is the right class.
local function setLeaderstat(player: Player, name: string, value: number)
	local folder = player:FindFirstChild("leaderstats")
	if folder == nil then
		return
	end
	local entry = folder:FindFirstChild(name)
	if entry ~= nil and entry:IsA("IntValue") then
		entry.Value = value
	end
end

-- Build a fresh state for a player who just joined, leaderstats included.
function PlayerData.create(player: Player): PlayerState
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local function stat(name: string, start: number)
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = start
		value.Parent = folder
	end
	stat("Cash", GameConfig.STARTING_CASH)
	stat("Income", 0)
	stat("Rebirths", 0)
	stat("Brainrots", 0)

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
	byPlayer[player] = state
	return state
end

function PlayerData.get(player: Player): PlayerState?
	return byPlayer[player]
end

-- Forget a player entirely when they leave (their brainrots go with them).
function PlayerData.remove(player: Player)
	byPlayer[player] = nil
end

function PlayerData.all(): { [Player]: PlayerState }
	return byPlayer
end

-- Cash and its leaderstat always move together; cash never goes below zero.
function PlayerData.setCash(state: PlayerState, amount: number)
	state.cash = math.max(0, math.floor(amount))
	setLeaderstat(state.player, "Cash", state.cash)
end

function PlayerData.addCash(state: PlayerState, amount: number)
	PlayerData.setCash(state, state.cash + amount)
end

-- Rebirths set the income multiplier too: +50% per rebirth, on top of x1.
function PlayerData.setRebirths(state: PlayerState, count: number)
	state.rebirths = count
	state.incomeMultiplier = 1 + GameConfig.REBIRTH_MULTIPLIER_PER * count
	setLeaderstat(state.player, "Rebirths", count)
end

-- Dollars per second from everything on this player's base, after the
-- Double Scoop upgrade and the rebirth multiplier.
function PlayerData.calculateIncome(state: PlayerState): number
	local perSecond = 0
	for _, model in pairs(state.placed) do
		local rate = model:GetAttribute("Rate")
		if typeof(rate) == "number" then
			perSecond += rate
		end
	end
	if state.upgrades.income then
		perSecond *= 2
	end
	return perSecond * state.incomeMultiplier
end

-- How many brainrots are standing on the player's base right now.
function PlayerData.countPlaced(state: PlayerState): number
	local count = 0
	for _ in pairs(state.placed) do
		count += 1
	end
	return count
end

function PlayerData.refreshBrainrotCount(state: PlayerState)
	setLeaderstat(state.player, "Brainrots", PlayerData.countPlaced(state))
end

-- The first free slot on the player's base, or nil when it is full.
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

-- Whole seconds left on the base lock, or 0.
function PlayerData.lockSecondsLeft(state: PlayerState): number
	return math.max(0, math.floor(state.lockUntil - os.clock()))
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.remove(player)
end)

return PlayerData
