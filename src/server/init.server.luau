-- Brainrot Lagoon — server bootstrap.
-- Creates the remotes and shared values, claims a base per player, and starts every service:
-- MoneyService (the income tick), ConveyorService (buy, carry, place), StealService
-- (stealing and slapping), WaveService (the Noodle Tsunami), RebirthService (rebirths,
-- upgrades, base lock) and DataService (saves). Nothing here runs the game on its own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local PlayerData = require(script:WaitForChild("PlayerData"))
local BaseService = require(script:WaitForChild("BaseService"))
local MoneyService = require(script:WaitForChild("MoneyService"))
local ConveyorService = require(script:WaitForChild("ConveyorService"))
local StealService = require(script:WaitForChild("StealService"))
local WaveService = require(script:WaitForChild("WaveService"))
local RebirthService = require(script:WaitForChild("RebirthService"))
local DataService = require(script:WaitForChild("DataService"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))

print("[Brainrot Lagoon] server starting...")

-- Shared values the HUD reads: the wave countdown and the wave's current phase.
local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState.Parent = ReplicatedStorage

local waveCountdown = Instance.new("IntValue")
waveCountdown.Name = "WaveCountdown"
waveCountdown.Value = GameConfig.WAVE_CYCLE_SECONDS
waveCountdown.Parent = gameState

local waveState = Instance.new("StringValue")
waveState.Name = "WaveState"
waveState.Value = "Calm"
waveState.Parent = gameState

-- RemoteEvents: client -> server (slap, rebirth, upgrades, lock) and server -> client (toasts).
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name: string): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local notifyRemote = makeRemote("Notify")
local slapRemote = makeRemote("Slap")
local rebirthRemote = makeRemote("Rebirth")
local buyUpgradeRemote = makeRemote("BuyUpgrade")
local lockBaseRemote = makeRemote("LockBase")

-- One folder per base to hold the brainrots placed on it.
for index = 1, #GameConfig.BASES do
	local folder = Instance.new("Model")
	folder.Name = "Base" .. index .. "Brainrots"
	folder.Parent = Workspace
	BaseService.registerBaseFolder(index, folder)
end

-- A new player: state, save, a base, and their walk speed back if they own the boots.
local function onPlayerAdded(player: Player)
	local state = PlayerData.create(player)
	DataService.loadSave(state)
	local baseIndex = BaseService.assignBase(state)
	if baseIndex ~= nil then
		notifyRemote:FireClient(player, "Welcome to Brainrot Lagoon! Your base is BASE " .. baseIndex .. ".")
	else
		notifyRemote:FireClient(player, "Welcome! All bases are taken — spectate and steal nothing... yet.")
	end
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		if state.upgrades.speed then
			humanoid.WalkSpeed = 24
		end
	end)
end

-- A leaving player: drop what they carry, free their base, save.
local function onPlayerRemoving(player: Player)
	local state = PlayerData.get(player)
	if state ~= nil then
		if state.carried ~= nil then
			ConveyorService.dropCarried(player, state, false)
		end
		BaseService.releaseBase(state)
		DataService.saveSave(state)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

WorldBuilder.build()

ConveyorService.start({ notify = notifyRemote })
StealService.start({ notify = notifyRemote, slap = slapRemote })
WaveService.start({ gameState = gameState, notify = notifyRemote })
RebirthService.start({
	notify = notifyRemote,
	rebirth = rebirthRemote,
	buyUpgrade = buyUpgradeRemote,
	lockBase = lockBaseRemote,
})
MoneyService.start()

print("[Brainrot Lagoon] server ready: 6 bases, conveyor running, tsunami armed.")
