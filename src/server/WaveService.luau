-- WaveService: the Noodle Tsunami. Every cycle a giant wave of noodles sweeps the map
-- north to south. Ten seconds of warning, then the wall rolls through: anyone caught
-- outside their own base is flung back to spawn and drops whatever they were carrying.
-- Dash home with the catch — that is the game's tension.

local Workspace = game:GetService("Workspace")

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local WaveService = {}

local waveWall: Part
local gameState: Folder
local countdownValue: IntValue
local stateValue: StringValue
local notifyRemote: RemoteEvent

-- Fling one caught player back to spawn and make them drop their brainrot.
local function catchPlayer(player: Player, state)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local conveyor = require(script.Parent:WaitForChild("ConveyorService"))
	if state.carried ~= nil then
		conveyor.dropCarried(player, state, true)
	end
	root.CFrame = CFrame.new(GameConfig.SPAWN_POINT)
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	notifyRemote:FireClient(player, "The Noodle Tsunami got you! Dash home next time!")
end

-- During the sweep, anyone not standing on their own base gets caught.
local function sweepStep()
	for player, state in pairs(PlayerData.all()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root ~= nil then
			local safe = false
			if state.baseIndex ~= nil then
				safe = BaseService.isInsideBase(state.baseIndex, root.Position)
			end
			if not safe then
				catchPlayer(player, state)
			end
		end
	end
end

-- One full wave cycle: calm countdown, warning, sweep, calm again.
function WaveService.runWaveLoop()
	while true do
		-- Calm: the countdown ticks down for everyone to see.
		stateValue.Value = "Calm"
		for t = GameConfig.WAVE_CYCLE_SECONDS, 1, -1 do
			countdownValue.Value = t
			task.wait(1)
		end
		-- Warning: ten seconds to get home.
		stateValue.Value = "Warning"
		for t = GameConfig.WAVE_WARNING_SECONDS, 1, -1 do
			countdownValue.Value = t
			task.wait(1)
		end
		-- Sweep: the wall rolls north to south across the whole island.
		stateValue.Value = "Wave"
		countdownValue.Value = 0
		waveWall.Transparency = 0.15
		local startZ = GameConfig.WAVE_START_Z
		local endZ = GameConfig.WAVE_END_Z
		local steps = 50
		for i = 0, steps do
			local z = startZ + (endZ - startZ) * (i / steps)
			waveWall.Position = Vector3.new(0, 12, z)
			sweepStep()
			task.wait(GameConfig.WAVE_SWEEP_SECONDS / steps)
		end
		waveWall.Transparency = 1
		waveWall.Position = Vector3.new(0, 12, startZ)
	end
end

function WaveService.start(state: { gameState: Folder, notify: RemoteEvent })
	gameState = state.gameState
	notifyRemote = state.notify
	countdownValue = gameState:WaitForChild("WaveCountdown") :: IntValue
	stateValue = gameState:WaitForChild("WaveState") :: StringValue
	waveWall = Workspace:WaitForChild("WaveWall") :: Part
	task.spawn(WaveService.runWaveLoop)
end

return WaveService
