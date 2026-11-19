-- Effects — client-side feedback for the big moments.
-- A red flash and a shake when the tsunami warning starts, a softer pulse while
-- the wave rolls through, and a gold flash when you place a brainrot on your
-- base. Purely visual: the server decides everything that matters.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gameState = ReplicatedStorage:WaitForChild("GameState")
local wavePhase = gameState:WaitForChild("WaveState") :: StringValue

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotEffects"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = playerGui

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local shaking = false
local shakeStrength = 0

-- One camera shake burst: small random offsets for a short time.
local function shakeCamera(strength: number, duration: number)
	if shaking then
		return
	end
	shaking = true
	shakeStrength = strength
	local camera = Workspace.CurrentCamera
	local started = os.clock()
	while os.clock() - started < duration and camera ~= nil do
		local offset = Vector3.new(
			(math.random() - 0.5) * shakeStrength,
			(math.random() - 0.5) * shakeStrength,
			0
		)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
		RunService.RenderStepped:Wait()
	end
	shaking = false
end

-- Fade the full-screen flash in and out once.
local function pulseFlash(targetTransparency: number, holdSeconds: number)
	flash.BackgroundTransparency = 0
	task.wait(0.12)
	flash.BackgroundTransparency = targetTransparency
	task.wait(holdSeconds)
	flash.BackgroundTransparency = 1
end

-- Wave phases drive the feedback: the warning flashes red and shakes, the
-- wave itself pulses orange.
wavePhase:GetPropertyChangedSignal("Value"):Connect(function()
	if wavePhase.Value == "Warning" then
		flash.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
		task.spawn(pulseFlash, 0.75, 0.4)
		task.spawn(shakeCamera, 0.6, 0.8)
	elseif wavePhase.Value == "Wave" then
		flash.BackgroundColor3 = Color3.fromRGB(255, 120, 40)
		task.spawn(pulseFlash, 0.85, 1.5)
		task.spawn(shakeCamera, 1.2, 2.5)
	end
end)

-- Gold flash when a brainrot lands on your base (your Brainrots leaderstat
-- went up).
local leaderstats = player:WaitForChild("leaderstats")
local brainrotsValue = leaderstats:WaitForChild("Brainrots") :: IntValue
local lastCount = brainrotsValue.Value
brainrotsValue:GetPropertyChangedSignal("Value"):Connect(function()
	if brainrotsValue.Value > lastCount then
		flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		task.spawn(pulseFlash, 0.8, 0.3)
	end
	lastCount = brainrotsValue.Value
end)
