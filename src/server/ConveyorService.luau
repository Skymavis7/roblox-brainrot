-- ConveyorService: the weirdo conveyor. Brainrots spawn at the west dock, walk east
-- along the middle of the map, and despawn at the far end. A player buys one with its
-- prompt; it then follows them home, and hops onto a free slot of their base.
-- This is the heart of the collection loop: buy, carry, place, earn.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local ConveyorService = {}

local walking: { Model } = {}
local following: { [Player]: Model } = {}
local notifyRemote: RemoteEvent

local brainrotFolder: Folder

-- The prompt a brainrot carries, and what it says, depends on who looks at it.
local function refreshPrompt(model: Model, viewer: Player?)
	local prompt = model:FindFirstChildOfClass("ProximityPrompt")
	if prompt == nil then
		return
	end
	local state = model:GetAttribute("State")
	if state == "Walking" then
		local cost = model:GetAttribute("Cost")
		prompt.ActionText = "Buy"
		prompt.ObjectText = BrainrotCatalog.formatMoney(cost)
		prompt.Enabled = true
	elseif state == "Placed" then
		local ownerId = model:GetAttribute("OwnerId")
		if viewer ~= nil and ownerId ~= viewer.UserId then
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

-- Spawn one random brainrot at the west dock and set it walking east.
function ConveyorService.spawnBrainrot()
	if #walking >= GameConfig.CONVEYOR_MAX_WALKING then
		return
	end
	local entry = BrainrotCatalog.rollCharacter()
	local mutation = BrainrotCatalog.rollMutation()
	local model = BrainrotFactory.build(entry, mutation, GameConfig.CONVEYOR_START)
	model.Parent = brainrotFolder

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BrainrotPrompt"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "Buy"
	prompt.ObjectText = BrainrotCatalog.formatMoney(entry.cost)
	prompt.Parent = model.PrimaryPart

	-- Buying: pay the cost, and the brainrot starts following you home.
	prompt.Triggered:Connect(function(player)
		ConveyorService.onPromptTriggered(player, model)
	end)
	-- The prompt's wording depends on who looks at it (buy vs. steal).
	prompt.PromptShown:Connect(function(viewer)
		refreshPrompt(model, viewer)
	end)

	table.insert(walking, model)
end

-- A player pressed a brainrot's prompt: buy it off the conveyor, or steal it off a base.
function ConveyorService.onPromptTriggered(player: Player, model: Model)
	local state = PlayerData.get(player)
	if state == nil then
		return
	end
	local modelState = model:GetAttribute("State")
	if modelState == "Walking" then
		ConveyorService.buyBrainrot(player, state, model)
	elseif modelState == "Placed" then
		local stealService = require(script.Parent:WaitForChild("StealService"))
		stealService.trySteal(player, state, model)
	end
end

-- Buy a walking brainrot: check the cash, take the money, it follows you.
function ConveyorService.buyBrainrot(player: Player, state, model: Model)
	if state.carried ~= nil then
		notifyRemote:FireClient(player, "Carry one brainrot at a time! Place it on your base first.")
		return
	end
	local cost = model:GetAttribute("Cost")
	if typeof(cost) ~= "number" or state.cash < cost then
		notifyRemote:FireClient(player, "Not enough cash for " .. model.Name .. "!")
		return
	end
	PlayerData.addCash(state, -cost)
	for i, other in ipairs(walking) do
		if other == model then
			table.remove(walking, i)
			break
		end
	end
	model:SetAttribute("State", "Following")
	model:SetAttribute("OwnerId", player.UserId)
	model.Parent = brainrotFolder
	following[player] = model
	state.carried = model
	player:SetAttribute("Carrying", model.Name)
	refreshPrompt(model, nil)
	notifyRemote:FireClient(player, "You bought " .. model.Name .. "! Carry it home to your base!")
end

-- Register a model as following a player (used when a steal hands one over).
function ConveyorService.registerFollower(player: Player, model: Model)
	following[player] = model
end

-- A carried brainrot is dropped (slapped, wave-caught, or its carrier left).
-- A stolen one goes back to its old base when there is room; a bought one despawns.
function ConveyorService.dropCarried(player: Player, state, returnHome: boolean)
	local model = state.carried
	if model == nil then
		return
	end
	state.carried = nil
	following[player] = nil
	player:SetAttribute("Carrying", "")
	if returnHome then
		local homeId = model:GetAttribute("HomeOwnerId")
		local homePlayer = nil
		if typeof(homeId) == "number" then
			for other, otherState in pairs(PlayerData.all()) do
				if other.UserId == homeId then
					homePlayer = other
					break
				end
			end
		end
		local homeState = homePlayer and PlayerData.get(homePlayer) or nil
		if homeState ~= nil and homeState.baseIndex ~= nil and PlayerData.firstFreeSlot(homeState) ~= nil then
			BaseService.placeOnBase(homeState, model)
			notifyRemote:FireClient(homePlayer, model.Name .. " ran back to your base!")
			return
		end
	end
	model:Destroy()
end

-- Move every walking and following brainrot one step. Runs every heartbeat.
function ConveyorService.stepBrainrots(dt: number)
	local now = os.clock()
	-- Walking: east along the conveyor, with a little waddle.
	for i = #walking, 1, -1 do
		local model = walking[i]
		if model.Parent == nil then
			table.remove(walking, i)
		else
			local primary = model.PrimaryPart
			if primary ~= nil then
				local pos = primary.Position
				local nextX = pos.X + GameConfig.CONVEYOR_WALK_SPEED * dt
				if nextX >= GameConfig.CONVEYOR_END.X then
					model:Destroy()
					table.remove(walking, i)
				else
					local bob = math.sin(now * 6 + pos.X) * 0.25
					model:PivotTo(CFrame.new(nextX, GameConfig.CONVEYOR_START.Y + bob, pos.Z))
				end
			end
		end
	end
	-- Following: trail behind their owner; hop onto the base when they arrive.
	for player, model in pairs(following) do
		local state = PlayerData.get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if state == nil or model.Parent == nil or root == nil then
			if state ~= nil then
				ConveyorService.dropCarried(player, state, true)
			end
			following[player] = nil
		else
			local target = root.Position - root.CFrame.LookVector * 4
			local primary = model.PrimaryPart
			if primary ~= nil then
				local pos = primary.Position
				local delta = target - pos
				delta = Vector3.new(delta.X, 0, delta.Z)
				local distance = delta.Magnitude
				if distance > 1 then
					local step = math.min(GameConfig.FOLLOW_SPEED * dt, distance)
					local bob = math.sin(now * 8) * 0.3
					model:PivotTo(CFrame.new(pos + delta.Unit * step + Vector3.new(0, bob, 0)))
				end
				-- Arrived at your own base with a free slot: place it and start earning.
				if state.baseIndex ~= nil and BaseService.isInsideBase(state.baseIndex, root.Position) then
					if BaseService.placeOnBase(state, model) then
						following[player] = nil
						state.carried = nil
						notifyRemote:FireClient(player, model.Name .. " is on your base earning " ..
							BrainrotCatalog.formatMoney(model:GetAttribute("Rate")) .. "/s!")
					end
				end
			end
		end
	end
end

-- Spawn a few brainrots at once (the TOUR.json step for the conveyor screenshot).
function ConveyorService.spawnForTour(count: number)
	for _ = 1, math.min(count, 3) do
		ConveyorService.spawnBrainrot()
	end
end

function ConveyorService.start(remotes: { notify: RemoteEvent })
	notifyRemote = remotes.notify
	brainrotFolder = Instance.new("Folder")
	brainrotFolder.Name = "Brainrots"
	brainrotFolder.Parent = Workspace

	task.spawn(function()
		while true do
			task.wait(GameConfig.CONVEYOR_SPAWN_INTERVAL)
			ConveyorService.spawnBrainrot()
		end
	end)
	-- A couple of weirdos are already walking when the game starts.
	ConveyorService.spawnBrainrot()
	ConveyorService.spawnBrainrot()

	RunService.Heartbeat:Connect(function(dt)
		ConveyorService.stepBrainrots(dt)
	end)
end

return ConveyorService
