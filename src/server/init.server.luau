-- init.server: bootstrap. Builds the shared folders and remotes, hands every
-- player a base and their save, then starts the world and all services.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)
local MoneyService = require(script.Parent.MoneyService)
local ConveyorService = require(script.Parent.ConveyorService)
local StealService = require(script.Parent.StealService)
local WaveService = require(script.Parent.WaveService)
local RebirthService = require(script.Parent.RebirthService)
local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)

-- Shared state the HUD reads.
local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState.Parent = ReplicatedStorage

local waveCountdown = Instance.new("IntValue")
waveCountdown.Name = "WaveCountdown"
waveCountdown.Value = Config.WAVE_CYCLE_SECONDS
waveCountdown.Parent = gameState

local wavePhase = Instance.new("StringValue")
wavePhase.Name = "WaveState"
wavePhase.Value = "Calm"
wavePhase.Parent = gameState

-- Remotes the client fires and the server answers on.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local remoteList = {}
for _, name in ipairs({ "Notify", "Slap", "Rebirth", "BuyUpgrade", "LockBase" }) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	remoteList[name] = remote
end

-- One folder per base, holding the brainrots standing on it.
for index = 1, #Config.BASES do
	local folder = Instance.new("Model")
	folder.Name = "Base" .. index .. "Brainrots"
	folder.Parent = Workspace
	BaseService.registerBaseFolder(index, folder)
end

local function notifyPlayer(player, message)
	remoteList.Notify:FireClient(player, message)
end

local function setupPlayer(player)
	local state = PlayerData.create(player)
	DataService.loadSave(state)
	local baseIndex = BaseService.assignBase(state)
	if baseIndex then
		notifyPlayer(player, "Welcome to Brainrot Lagoon! Your base is BASE " .. baseIndex .. ".")
	else
		notifyPlayer(player, "Welcome! All bases are taken — spectate and steal nothing... yet.")
	end

	local function applySpeed(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and state.upgrades.speed then
			humanoid.WalkSpeed = 24
		end
	end
	player.CharacterAdded:Connect(applySpeed)
	if player.Character then
		applySpeed(player.Character)
	end
end

local function removePlayer(player)
	local state = PlayerData.get(player)
	if not state then
		return
	end
	ConveyorService.dropCarried(player, state, false)
	BaseService.releaseBase(state)
	DataService.saveSave(state)
	PlayerData.remove(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

WorldBuilder.build()

ConveyorService.start(remoteList)
StealService.start(remoteList)
WaveService.start({
	countdown = waveCountdown,
	phase = wavePhase,
	wall = Workspace:WaitForChild("WaveWall"),
	notify = remoteList.Notify,
})
RebirthService.start(remoteList)
MoneyService.start()

print("[Brainrot Lagoon] ready — " .. Config.GAME_NAME .. " is live.")
