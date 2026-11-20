-- init.server: bootstrap. Build the shared state, remotes and base folders,
-- wire player join/leave, then start every service.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)
local MoneyService = require(script.Parent.MoneyService)
local ConveyorService = require(script.Parent.ConveyorService)
local StealService = require(script.Parent.StealService)
local WaveService = require(script.Parent.WaveService)
local RebirthService = require(script.Parent.RebirthService)
local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local gameStateFolder = Instance.new("Folder")
gameStateFolder.Name = "GameState"
gameStateFolder.Parent = ReplicatedStorage

local waveCountdown = Instance.new("IntValue")
waveCountdown.Name = "WaveCountdown"
waveCountdown.Value = GameConfig.WAVE_CYCLE_SECONDS
waveCountdown.Parent = gameStateFolder

local waveStateValue = Instance.new("StringValue")
waveStateValue.Name = "WaveState"
waveStateValue.Value = "Calm"
waveStateValue.Parent = gameStateFolder

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local remotes = {}
for _, name in ipairs({ "Notify", "Slap", "Rebirth", "BuyUpgrade", "LockBase" }) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	remotes[name] = remote
end

for index = 1, 6 do
	local folder = Instance.new("Model")
	folder.Name = "Base" .. index .. "Brainrots"
	folder.Parent = Workspace
	BaseService.registerBaseFolder(index, folder)
end

local function onPlayerAdded(player)
	local state = PlayerData.create(player)
	DataService.loadSave(state)
	local baseIndex = BaseService.assignBase(state)
	if baseIndex then
		remotes.Notify:FireClient(player, "Welcome to Brainrot Lagoon! Your base is BASE " .. baseIndex .. ".")
	else
		remotes.Notify:FireClient(player, "Welcome! All bases are taken — spectate and steal nothing... yet.")
	end
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		if state.upgrades.speed then
			humanoid.WalkSpeed = 24
		end
	end)
end

local function onPlayerRemoving(player)
	local state = PlayerData.get(player)
	if state then
		ConveyorService.dropCarried(player, state, false)
		BaseService.releaseBase(state)
		DataService.saveSave(state)
		PlayerData.remove(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

WorldBuilder.build()
ConveyorService.start(remotes)
StealService.start(remotes)
WaveService.start({
	gameState = gameStateFolder,
	notify = remotes.Notify,
	waveCountdown = waveCountdown,
	waveState = waveStateValue,
})
RebirthService.start(remotes)
MoneyService.start()

print("[Brainrot Lagoon] ready — " .. GameConfig.GAME_NAME .. " is live.")
