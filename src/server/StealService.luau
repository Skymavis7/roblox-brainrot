-- StealService: stealing brainrots off unlocked bases, and slapping thieves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local StealService = {}

local notifyRemote = nil

local function tell(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function StealService.trySteal(thief, thiefState, model)
	local ownerId = model:GetAttribute("OwnerId")
	if typeof(ownerId) ~= "number" or ownerId == thief.UserId then
		return
	end
	if thiefState.carried then
		tell(thief, "You are already carrying a brainrot!")
		return
	end
	local ownerPlayer = nil
	local ownerState = nil
	for _, otherState in pairs(PlayerData.all()) do
		if otherState.player.UserId == ownerId then
			ownerPlayer = otherState.player
			ownerState = otherState
			break
		end
	end
	if not ownerPlayer or not ownerState then
		return
	end
	if PlayerData.isBaseLocked(ownerState) then
		tell(thief, ownerPlayer.Name .. "'s base is LOCKED! Come back later.")
		return
	end
	BaseService.removeFromBase(ownerState, model)
	model:SetAttribute("HomeOwnerId", ownerId)
	model:SetAttribute("State", "Following")
	model:SetAttribute("OwnerId", thief.UserId)
	thiefState.carried = model
	thief:SetAttribute("Carrying", model.Name)
	local ConveyorService = require(script.Parent.ConveyorService)
	ConveyorService.registerFollower(thief, model)
	tell(thief, "You stole " .. model.Name .. "! RUN home before they slap you!")
	tell(ownerPlayer, thief.Name .. " is stealing your " .. model.Name .. "! SLAP them!")
end

function StealService.slap(player, state)
	local now = os.clock()
	if now < state.slapCooldownUntil then
		return
	end
	state.slapCooldownUntil = now + GameConfig.SLAP_COOLDOWN
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local nearest = nil
	local nearestDistance = GameConfig.SLAP_RANGE
	for _, otherState in pairs(PlayerData.all()) do
		local other = otherState.player
		if other ~= player then
			local otherCharacter = other.Character
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance <= nearestDistance then
					nearest = other
					nearestDistance = distance
				end
			end
		end
	end
	if not nearest then
		tell(player, "Slap! ...nobody in range.")
		return
	end
	local victimCharacter = nearest.Character
	local victimRoot = victimCharacter and victimCharacter:FindFirstChild("HumanoidRootPart")
	local victimHumanoid = victimCharacter and victimCharacter:FindFirstChildOfClass("Humanoid")
	if not victimRoot then
		return
	end
	local away = (victimRoot.Position - root.Position).Unit
	victimRoot.AssemblyLinearVelocity = away * GameConfig.SLAP_KNOCKBACK + Vector3.new(0, 25, 0)
	if victimHumanoid then
		local oldSpeed = victimHumanoid.WalkSpeed
		victimHumanoid.WalkSpeed = 0
		task.delay(1, function()
			if victimHumanoid.Parent then
				victimHumanoid.WalkSpeed = oldSpeed
			end
		end)
	end
	local victimState = PlayerData.get(nearest)
	if victimState and victimState.carried then
		local ConveyorService = require(script.Parent.ConveyorService)
		ConveyorService.dropCarried(nearest, victimState, true)
		tell(nearest, "You got SLAPPED and dropped the brainrot!")
	end
	tell(player, "SLAP! You sent " .. nearest.Name .. " flying!")
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
