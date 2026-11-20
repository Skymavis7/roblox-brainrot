-- StealService: stealing brainrots off unlocked bases, and slapping thieves.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local StealService = {}

local notifyRemote = nil

local function notify(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function StealService.trySteal(thief, thiefState, model)
	local ownerId = model:GetAttribute("OwnerId")
	if type(ownerId) ~= "number" or ownerId == thief.UserId then
		return
	end
	if thiefState.carried then
		notify(thief, "You are already carrying a brainrot!")
		return
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	if not owner then
		return
	end
	local ownerState = PlayerData.get(owner)
	if not ownerState then
		return
	end
	if PlayerData.isBaseLocked(ownerState) then
		notify(thief, owner.DisplayName .. "'s base is LOCKED! Come back later.")
		return
	end
	BaseService.removeFromBase(ownerState, model)
	model:SetAttribute("HomeOwnerId", ownerId)
	model:SetAttribute("State", "Following")
	model:SetAttribute("OwnerId", thief.UserId)
	thiefState.carried = model
	thief:SetAttribute("Carrying", model.Name)
	-- Lazy require: ConveyorService requires this module back.
	local ConveyorService = require(script.Parent.ConveyorService)
	ConveyorService.registerFollower(thief, model)
	notify(thief, "You stole " .. model.Name .. "! RUN home before they slap you!")
	notify(owner, thief.DisplayName .. " is stealing your " .. model.Name .. "! SLAP them!")
end

function StealService.slap(player, state)
	local now = os.clock()
	if now < state.slapCooldownUntil then
		return
	end
	state.slapCooldownUntil = now + Config.SLAP_COOLDOWN

	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return
	end
	local nearest, nearestDistance = nil, Config.SLAP_RANGE
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local distance = (root.Position - myRoot.Position).Magnitude
				if distance <= nearestDistance then
					nearest, nearestDistance = other, distance
				end
			end
		end
	end
	if not nearest then
		notify(player, "Slap! ...nobody in range.")
		return
	end

	local victimRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
	local away = (victimRoot.Position - myRoot.Position)
	if away.Magnitude < 0.01 then
		away = Vector3.new(0, 0, 1)
	end
	away = away.Unit
	victimRoot.AssemblyLinearVelocity = away * Config.SLAP_KNOCKBACK + Vector3.new(0, 25, 0)

	local humanoid = nearest.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local victimState = PlayerData.get(nearest)
		local restoreSpeed = 16
		if victimState and victimState.upgrades.speed then
			restoreSpeed = 24
		end
		humanoid.WalkSpeed = 0
		task.delay(1, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = restoreSpeed
			end
		end)
	end

	local victimState = PlayerData.get(nearest)
	if victimState and victimState.carried then
		local ConveyorService = require(script.Parent.ConveyorService)
		ConveyorService.dropCarried(nearest, victimState, true)
		notify(nearest, "You got SLAPPED and dropped the brainrot!")
	end
	notify(player, "SLAP! You sent " .. nearest.DisplayName .. " flying!")
end

function StealService.start(remotes)
	notifyRemote = remotes.Notify
	remotes.Slap.OnServerEvent:Connect(function(player)
		local state = PlayerData.get(player)
		if state then
			StealService.slap(player, state)
		end
	end)
end

return StealService
