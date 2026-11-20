-- Effects.client: screen flashes and camera shakes for the big moments.
-- Client-side feedback only; the server decides everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gameState = ReplicatedStorage:WaitForChild("GameState")
local waveState = gameState:WaitForChild("WaveState")
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

local shaking = false

local function shake(strength, duration)
	if shaking then
		return
	end
	shaking = true
	local camera = workspace.CurrentCamera
	local started = os.clock()
	task.spawn(function()
		while os.clock() - started < duration do
			if camera then
				local offset = Vector3.new(
					(math.random() - 0.5) * strength,
					(math.random() - 0.5) * strength,
					0
				)
				camera.CFrame = camera.CFrame * CFrame.new(offset)
			end
			RunService.RenderStepped:Wait()
		end
		shaking = false
	end)
end

local function flashPulse(color, target, hold)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0
	task.delay(hold, function()
		flash.BackgroundTransparency = 1
	end)
	-- fade back out smoothly after the hold
	task.spawn(function()
		task.wait(hold)
		local steps = 12
		for step = 1, steps do
			flash.BackgroundTransparency = target + (1 - target) * (step / steps)
			task.wait(0.05)
		end
		flash.BackgroundTransparency = 1
	end)
end

waveState.Changed:Connect(function()
	local state = waveState.Value
	if state == "Warning" then
		flashPulse(Color3.fromRGB(255, 40, 40), 0.75, 0.4)
		shake(0.6, 0.8)
	elseif state == "Wave" then
		flashPulse(Color3.fromRGB(255, 120, 40), 0.85, 1.5)
		shake(1.2, 2.5)
	end
end)

local lastBrainrots = brainrotsValue.Value
brainrotsValue.Changed:Connect(function()
	if brainrotsValue.Value > lastBrainrots then
		flashPulse(Color3.fromRGB(255, 215, 0), 0.8, 0.3)
	end
	lastBrainrots = brainrotsValue.Value
end)
