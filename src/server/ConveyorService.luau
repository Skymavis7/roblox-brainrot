-- ConveyorService: spawn brainrots, walk them along the conveyor, let
-- players buy them and carry them home. The trailing/follow loop lives here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local ConveyorService = {}

local walking = {}
local trailing = {}
local notifyRemote = nil
local brainrotFolder = nil

local function tell(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function ConveyorService.spawnBrainrot()
	if #walking >= GameConfig.CONVEYOR_MAX_WALKING then
		return
	end
	local entry = Catalog.rollCharacter()
	local mutation = Catalog.rollMutation()
	local model = BrainrotFactory.build(entry, mutation, GameConfig.CONVEYOR_START)
	model.Parent = brainrotFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BrainrotPrompt"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "Buy"
	prompt.ObjectText = Catalog.formatMoney(entry.cost)
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		ConveyorService.onPromptTriggered(player, model)
	end)
	prompt.PromptShown:Connect(function(player)
		ConveyorService.updatePrompt(model, player)
	end)

	table.insert(walking, model)
end

function ConveyorService.updatePrompt(model, viewer)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	local prompt = primary:FindFirstChild("BrainrotPrompt")
	if not prompt then
		return
	end
	local state = model:GetAttribute("State")
	if state == "Walking" then
		prompt.ActionText = "Buy"
		local cost = model:GetAttribute("Cost")
		if typeof(cost) == "number" then
			prompt.ObjectText = Catalog.formatMoney(cost)
		end
		prompt.Enabled = true
	elseif state == "Placed" then
		local ownerId = model:GetAttribute("OwnerId")
		if typeof(ownerId) == "number" and viewer.UserId ~= ownerId then
			prompt.ActionText = "Steal"
			prompt.ObjectText = model.Name
			prompt.Enabled = true
		else
			prompt.Enabled = false
		end
	else
		prompt.Enabled = false
	end
end

function ConveyorService.onPromptTriggered(player, model)
	local state = model:GetAttribute("State")
	if state == "Walking" then
		local playerState = PlayerData.get(player)
		if playerState then
			ConveyorService.buyBrainrot(player, playerState, model)
		end
	elseif state == "Placed" then
		local StealService = require(script.Parent.StealService)
		local playerState = PlayerData.get(player)
		if playerState then
			StealService.trySteal(player, playerState, model)
		end
	end
end

function ConveyorService.buyBrainrot(player, state, model)
	if state.carried then
		tell(player, "Carry one brainrot at a time! Place it on your base first.")
		return
	end
	local cost = model:GetAttribute("Cost")
	if typeof(cost) ~= "number" or state.cash < cost then
		tell(player, "Not enough cash for " .. model.Name .. "!")
		return
	end
	PlayerData.addCash(state, -cost)
	for index, other in ipairs(walking) do
		if other == model then
			table.remove(walking, index)
			break
		end
	end
	model:SetAttribute("State", "Following")
	model:SetAttribute("OwnerId", player.UserId)
	trailing[player] = model
	state.carried = model
	player:SetAttribute("Carrying", model.Name)
	ConveyorService.updatePrompt(model, player)
	tell(player, "You bought " .. model.Name .. "! Carry it home to your base!")
end

function ConveyorService.registerFollower(player, model)
	trailing[player] = model
end

function ConveyorService.dropCarried(player, state, returnHome)
	local model = state.carried
	if not model then
		return
	end
	state.carried = nil
	trailing[player] = nil
	player:SetAttribute("Carrying", "")
	if returnHome then
		local homeOwnerId = model:GetAttribute("HomeOwnerId")
		if typeof(homeOwnerId) == "number" then
			for _, otherState in pairs(PlayerData.all()) do
				if otherState.player.UserId == homeOwnerId and otherState.baseIndex then
					if BaseService.placeOnBase(otherState, model) then
						tell(otherState.player, model.Name .. " ran back to your base!")
						return
					end
				end
			end
		end
	end
	model:Destroy()
end

function ConveyorService.stepBrainrots(dt)
	local now = os.clock()
	for index = #walking, 1, -1 do
		local model = walking[index]
		local primary = model.PrimaryPart
		if not primary then
			table.remove(walking, index)
		else
			local nextX = primary.Position.X + GameConfig.CONVEYOR_WALK_SPEED * dt
			if nextX >= GameConfig.CONVEYOR_END.X then
				model:Destroy()
				table.remove(walking, index)
			else
				local waddle = math.sin(now * 6 + index) * 0.25
				primary.CFrame = CFrame.new(nextX, primary.Position.Y + waddle * 0.1, GameConfig.CONVEYOR_START.Z)
			end
		end
	end

	for player, model in pairs(trailing) do
		local playerState = PlayerData.get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local primary = model.PrimaryPart
		if not playerState or not root or not primary then
			if playerState then
				ConveyorService.dropCarried(player, playerState, true)
			end
			trailing[player] = nil
		else
			local target = root.Position - root.CFrame.LookVector * 4
			local direction = target - primary.Position
			local distance = direction.Magnitude
			if distance > 0.5 then
				local step = math.min(GameConfig.CONVEYOR_FOLLOW_SPEED * dt, distance)
				local bob = math.sin(now * 8) * 0.3
				local nextPos = primary.Position + direction.Unit * step
				primary.CFrame = CFrame.new(nextPos.X, nextPos.Y + bob * 0.1, nextPos.Z)
			end
			if playerState.baseIndex and playerState.carried == model then
				if BaseService.isInsideBase(playerState.baseIndex, root.Position) then
					if BaseService.placeOnBase(playerState, model) then
						trailing[player] = nil
						playerState.carried = nil
						local rate = model:GetAttribute("Rate")
						if typeof(rate) == "number" then
							tell(player, model.Name .. " is on your base earning " .. Catalog.formatMoney(rate) .. "/s!")
						end
					end
				end
			end
		end
	end
end

function ConveyorService.spawnForTour(count)
	local spawned = 0
	for _ = 1, count do
		if #walking >= GameConfig.CONVEYOR_MAX_WALKING then
			break
		end
		ConveyorService.spawnBrainrot()
		spawned += 1
		if spawned >= 3 then
			break
		end
	end
end

function ConveyorService.start(remotes)
	notifyRemote = remotes.Notify
	brainrotFolder = Instance.new("Folder")
	brainrotFolder.Name = "Brainrots"
	brainrotFolder.Parent = workspace
	ConveyorService.spawnBrainrot()
	ConveyorService.spawnBrainrot()
	task.spawn(function()
		while true do
			task.wait(GameConfig.CONVEYOR_SPAWN_INTERVAL)
			ConveyorService.spawnBrainrot()
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		ConveyorService.stepBrainrots(dt)
	end)
end

return ConveyorService
