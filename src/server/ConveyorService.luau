-- ConveyorService: brainrots walk the conveyor, get bought, follow their
-- owner home, and drop back when their owner leaves or is slapped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local ConveyorService = {}

local walking = {} -- models strolling the conveyor, west to east
local trailing = {} -- player -> model following them home
local notifyRemote = nil
local folder = nil

local function notify(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function ConveyorService.spawnBrainrot()
	if #walking >= Config.CONVEYOR_MAX_WALKING then
		return
	end
	local entry = Catalog.rollCharacter()
	local mutation = Catalog.rollMutation()
	local model = BrainrotFactory.build(entry, mutation, Config.CONVEYOR_START)
	model.Parent = folder

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

-- The prompt wording depends on the model's state and who is looking.
function ConveyorService.updatePrompt(model, viewer)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local prompt = body:FindFirstChild("BrainrotPrompt")
	if not prompt then
		return
	end
	local state = model:GetAttribute("State")
	if state == "Walking" then
		prompt.ActionText = "Buy"
		prompt.ObjectText = Catalog.formatMoney(model:GetAttribute("Cost") or 0)
		prompt.Enabled = true
	elseif state == "Placed" then
		local ownerId = model:GetAttribute("OwnerId")
		if viewer and ownerId == viewer.UserId then
			prompt.Enabled = false
		else
			prompt.ActionText = "Steal"
			prompt.ObjectText = model.Name
			prompt.Enabled = true
		end
	else
		prompt.Enabled = false
	end
end

function ConveyorService.onPromptTriggered(player, model)
	local state = PlayerData.get(player)
	if not state then
		return
	end
	local modelState = model:GetAttribute("State")
	if modelState == "Walking" then
		ConveyorService.buyBrainrot(player, state, model)
	elseif modelState == "Placed" then
		-- Lazy require: StealService requires this module back.
		local StealService = require(script.Parent.StealService)
		StealService.trySteal(player, state, model)
	end
end

function ConveyorService.buyBrainrot(player, state, model)
	if state.carried then
		notify(player, "Carry one brainrot at a time! Place it on your base first.")
		return
	end
	local cost = model:GetAttribute("Cost")
	if type(cost) ~= "number" or state.cash < cost then
		notify(player, "Not enough cash for " .. model.Name .. "!")
		return
	end
	PlayerData.setCash(state, state.cash - cost)
	for i, other in ipairs(walking) do
		if other == model then
			table.remove(walking, i)
			break
		end
	end
	model:SetAttribute("State", "Following")
	model:SetAttribute("OwnerId", player.UserId)
	trailing[player] = model
	state.carried = model
	player:SetAttribute("Carrying", model.Name)
	ConveyorService.updatePrompt(model, nil)
	notify(player, "You bought " .. model.Name .. "! Carry it home to your base!")
end

function ConveyorService.registerFollower(player, model)
	trailing[player] = model
end

-- Drop what a player carries. With returnHome, a stolen brainrot runs back
-- to its real owner's base when it has a free slot; otherwise it is gone.
function ConveyorService.dropCarried(player, state, returnHome)
	local model = state.carried
	if not model then
		return
	end
	state.carried = nil
	trailing[player] = nil
	player:SetAttribute("Carrying", "")
	if returnHome then
		local homeId = model:GetAttribute("HomeOwnerId")
		if type(homeId) == "number" then
			local homePlayer = Players:GetPlayerByUserId(homeId)
			if homePlayer then
				local homeState = PlayerData.get(homePlayer)
				if homeState and homeState.baseIndex then
					if BaseService.placeOnBase(homeState, model) then
						notify(homePlayer, model.Name .. " ran back to your base!")
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

	-- Walkers: east along the belt, gentle waddle, off the end they vanish.
	for i = #walking, 1, -1 do
		local model = walking[i]
		if not model or not model.Parent then
			table.remove(walking, i)
		else
			local pivot = model:GetPivot()
			local nextX = pivot.Position.X + Config.CONVEYOR_WALK_SPEED * dt
			if nextX >= Config.CONVEYOR_END.X then
				model:Destroy()
				table.remove(walking, i)
			else
				local waddle = math.sin(now * 6) * 0.25
				model:PivotTo(
					CFrame.new(nextX, pivot.Position.Y, Config.CONVEYOR_START.Z + waddle)
						* CFrame.Angles(0, math.rad(-90), 0)
				)
			end
		end
	end

	-- Followers: trail behind their owner, bobbing; home when they arrive.
	for player, model in pairs(trailing) do
		local state = PlayerData.get(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not state or not model or not model.Parent or not root then
			if state then
				ConveyorService.dropCarried(player, state, true)
			end
			trailing[player] = nil
		else
			local target = root.Position - root.CFrame.LookVector * 4
			local pivot = model:GetPivot()
			local pos = pivot.Position
			local dx = target.X - pos.X
			local dz = target.Z - pos.Z
			local distance = math.sqrt(dx * dx + dz * dz)
			local step = Config.CONVEYOR_FOLLOW_SPEED * dt
			local nextX, nextZ = target.X, target.Z
			if distance > step then
				nextX = pos.X + (dx / distance) * step
				nextZ = pos.Z + (dz / distance) * step
			end
			local bob = target.Y + math.sin(now * 8) * 0.3
			model:PivotTo(CFrame.new(nextX, bob, nextZ) * root.CFrame.Rotation)

			if state.baseIndex and BaseService.isInsideBase(state.baseIndex, root.Position) then
				if PlayerData.firstFreeSlot(state) then
					if BaseService.placeOnBase(state, model) then
						trailing[player] = nil
						state.carried = nil
						notify(
							player,
							model.Name .. " is on your base earning " .. (model:GetAttribute("Rate") or 0) .. "/s!"
						)
					end
				end
			end
		end
	end
end

-- The TOUR.json step: a few brainrots at once for the camera.
function ConveyorService.spawnForTour(count)
	local amount = math.min(count, 3)
	for _ = 1, amount do
		ConveyorService.spawnBrainrot()
	end
end

function ConveyorService.start(remotes)
	notifyRemote = remotes.Notify
	folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	folder.Parent = Workspace
	ConveyorService.spawnBrainrot()
	ConveyorService.spawnBrainrot()
	task.spawn(function()
		while true do
			task.wait(Config.CONVEYOR_SPAWN_INTERVAL)
			ConveyorService.spawnBrainrot()
		end
	end)
	RunService.Heartbeat:Connect(ConveyorService.stepBrainrots)
end

return ConveyorService
