-- Effects.client: client-side feedback only (the server decides everything).
-- Screen flashes and a camera shake when the tsunami warns or hits, and a
-- gold flash when the player's brainrot count goes up.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gameState = ReplicatedStorage:WaitForChild("GameState")
local wavePhase = gameState:WaitForChild("WaveState")
local leaderstats = player:WaitForChild("leaderstats")
local brainrotsValue = leaderstats:WaitForChild("Brainrots")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotEffects"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local shakeUntil = 0
local shakeStrength = 0

local function flashPulse(color, targetTransparency, holdSeconds)
	flash.BackgroundColor3 = color
	local fadeIn = TweenService:Create(flash, TweenInfo.new(0.15), { BackgroundTransparency = targetTransparency })
	fadeIn:Play()
	fadeIn.Completed:Wait()
	task.wait(holdSeconds)
	local fadeOut = TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
	fadeOut:Play()
end

local function shake(strength, durationSeconds)
	shakeStrength = strength
	shakeUntil = os.clock() + durationSeconds
end

-- Applied after the engine places the camera each frame, so it never drifts.
RunService.RenderStepped:Connect(function()
	if os.clock() < shakeUntil and camera then
		local ox = (math.random() * 2 - 1) * 0.25 * shakeStrength
		local oy = (math.random() * 2 - 1) * 0.25 * shakeStrength
		camera.CFrame = camera.CFrame * CFrame.new(ox, oy, 0)
	end
end)

wavePhase:GetPropertyChangedSignal("Value"):Connect(function()
	local phase = wavePhase.Value
	if phase == "Warning" then
		task.spawn(flashPulse, Color3.fromRGB(255, 40, 40), 0.75, 0.4)
		shake(0.6, 0.8)
	elseif phase == "Wave" then
		task.spawn(flashPulse, Color3.fromRGB(255, 120, 40), 0.85, 1.5)
		shake(1.2, 2.5)
	end
end)

local lastCount = brainrotsValue.Value
brainrotsValue:GetPropertyChangedSignal("Value"):Connect(function()
	local now = brainrotsValue.Value
	if now > lastCount then
		task.spawn(flashPulse, Color3.fromRGB(255, 215, 0), 0.8, 0.3)
	end
	lastCount = now
end)
