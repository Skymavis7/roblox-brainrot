-- WaveService: the Noodle Tsunami. Calm, warning, then a wall sweeps the
-- map north to south; anyone caught outside their own base is flung home.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local WaveService = {}

local gameState = nil

local function notify(player, message)
	if gameState and gameState.notify then
		gameState.notify:FireClient(player, message)
	end
end

function WaveService.catchPlayer(player, state)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- Already at spawn: nothing to do (keeps the wave from spamming toasts).
	if (root.Position - Config.SPAWN_POINT).Magnitude < 4 then
		return
	end
	if state.carried then
		local ConveyorService = require(script.Parent.ConveyorService)
		ConveyorService.dropCarried(player, state, true)
	end
	root.CFrame = CFrame.new(Config.SPAWN_POINT)
	root.AssemblyLinearVelocity = Vector3.zero
	notify(player, "The Noodle Tsunami got you! Dash home next time!")
end

function WaveService.sweepStep()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerData.get(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if state and root then
			if not BaseService.isInsideBase(state.baseIndex, root.Position) then
				WaveService.catchPlayer(player, state)
			end
		end
	end
end

function WaveService.runWaveLoop()
	local countdown = gameState.countdown
	local phase = gameState.phase
	local wall = gameState.wall
	while true do
		-- Calm: the countdown ticks down.
		phase.Value = "Calm"
		for left = Config.WAVE_CYCLE_SECONDS, 1, -1 do
			countdown.Value = left
			task.wait(1)
		end
		-- Warning: run home.
		phase.Value = "Warning"
		for left = Config.WAVE_WARNING_SECONDS, 1, -1 do
			countdown.Value = left
			task.wait(1)
		end
		-- Wave: the wall sweeps north to south.
		phase.Value = "Wave"
		countdown.Value = 0
		wall.Transparency = 0.15
		local steps = 50
		for step = 1, steps do
			local z = Config.WAVE_START_Z
				+ (Config.WAVE_END_Z - Config.WAVE_START_Z) * (step / steps)
			wall.Position = Vector3.new(0, 12, z)
			WaveService.sweepStep()
			task.wait(Config.WAVE_SWEEP_SECONDS / steps)
		end
		wall.Transparency = 1
		wall.Position = Vector3.new(0, 12, Config.WAVE_START_Z)
	end
end

function WaveService.start(state)
	gameState = state
	task.spawn(WaveService.runWaveLoop)
end

return WaveService
