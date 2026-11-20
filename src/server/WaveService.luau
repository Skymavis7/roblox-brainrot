-- WaveService: the Noodle Tsunami — calm, warning, then a wall sweeping
-- the map north to south, catching anyone outside their own base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local WaveService = {}

local waveCountdown = nil
local waveStateValue = nil
local waveWall = nil
local notifyRemote = nil

local function tell(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function WaveService.catchPlayer(player, state)
	if state.carried then
		local ConveyorService = require(script.Parent.ConveyorService)
		ConveyorService.dropCarried(player, state, true)
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(GameConfig.SPAWN_POINT)
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
	tell(player, "The Noodle Tsunami got you! Dash home next time!")
end

function WaveService.sweepStep()
	for _, state in pairs(PlayerData.all()) do
		local player = state.player
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local safe = false
			if state.baseIndex then
				safe = BaseService.isInsideBase(state.baseIndex, root.Position)
			end
			if not safe then
				WaveService.catchPlayer(player, state)
			end
		end
	end
end

function WaveService.runWaveLoop()
	while true do
		waveStateValue.Value = "Calm"
		for count = GameConfig.WAVE_CYCLE_SECONDS, 1, -1 do
			waveCountdown.Value = count
			task.wait(1)
		end
		waveStateValue.Value = "Warning"
		for count = GameConfig.WAVE_WARNING_SECONDS, 1, -1 do
			waveCountdown.Value = count
			task.wait(1)
		end
		waveStateValue.Value = "Wave"
		waveCountdown.Value = 0
		waveWall.Transparency = 0.15
		local steps = 50
		local stepTime = GameConfig.WAVE_SWEEP_SECONDS / steps
		local span = GameConfig.WAVE_END_Z - GameConfig.WAVE_START_Z
		for step = 1, steps do
			local z = GameConfig.WAVE_START_Z + span * (step / steps)
			waveWall.Position = Vector3.new(0, 12, z)
			WaveService.sweepStep()
			task.wait(stepTime)
		end
		waveWall.Transparency = 1
		waveWall.Position = Vector3.new(0, 12, GameConfig.WAVE_START_Z)
	end
end

function WaveService.start(state)
	notifyRemote = state.notify
	waveCountdown = state.waveCountdown
	waveStateValue = state.waveState
	waveWall = workspace:FindFirstChild("WaveWall")
	task.spawn(function()
		WaveService.runWaveLoop()
	end)
end

return WaveService
