-- StealService: stealing from other players' bases, and the slap that stops it.
-- A brainrot on an unlocked base can be stolen: it follows the thief home, and if the
-- thief reaches their own base it becomes theirs. The owner (or anyone) can slap the
-- thief to knock them back and make the brainrot run home. A locked base cannot be stolen from.

local Players = game:GetService("Players")

local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local StealService = {}

local notifyRemote: RemoteEvent

-- Try to steal a brainrot off someone's base. The lock and the carrier rule decide it.
function StealService.trySteal(thief: Player, thiefState, model: Model)
	local ownerId = model:GetAttribute("OwnerId")
	if typeof(ownerId) ~= "number" or ownerId == thief.UserId then
		return
	end
	if thiefState.carried ~= nil then
		notifyRemote:FireClient(thief, "You are already carrying a brainrot!")
		return
	end
	local owner: Player? = nil
	local ownerState = nil
	for other, otherState in pairs(PlayerData.all()) do
		if other.UserId == ownerId then
			owner = other
			ownerState = otherState
			break
		end
	end
	if owner == nil or ownerState == nil then
		return
	end
	if PlayerData.isBaseLocked(ownerState) then
		notifyRemote:FireClient(thief, owner.DisplayName .. "'s base is LOCKED! Come back later.")
		return
	end
	-- Off the slot, onto the thief's trail. HomeOwnerId remembers where it belongs.
	BaseService.removeFromBase(ownerState, model)
	model:SetAttribute("HomeOwnerId", ownerId)
	model:SetAttribute("State", "Following")
	model:SetAttribute("OwnerId", thief.UserId)
	thiefState.carried = model
	thief:SetAttribute("Carrying", model.Name)
	local conveyor = require(script.Parent:WaitForChild("ConveyorService"))
	-- Hand the follower over to the conveyor's following loop via the shared table.
	conveyor.registerFollower(thief, model)
	notifyRemote:FireClient(thief, "You stole " .. model.Name .. "! RUN home before they slap you!")
	notifyRemote:FireClient(owner, thief.DisplayName .. " is stealing your " .. model.Name .. "! SLAP them!")
end

-- Slap the nearest other player in range: knock them back and drop what they carry.
function StealService.slap(player: Player, state)
	local now = os.clock()
	if now < state.slapCooldownUntil then
		return
	end
	state.slapCooldownUntil = now + GameConfig.SLAP_COOLDOWN
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local best: Player? = nil
	local bestDistance = GameConfig.SLAP_RANGE
	for other in pairs(PlayerData.all()) do
		if other ~= player then
			local otherCharacter = other.Character
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			if otherRoot ~= nil then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = other
				end
			end
		end
	end
	if best == nil then
		notifyRemote:FireClient(player, "Slap! ...nobody in range.")
		return
	end
	local victimCharacter = best.Character
	local victimRoot = victimCharacter and victimCharacter:FindFirstChild("HumanoidRootPart")
	local victimHumanoid = victimCharacter and victimCharacter:FindFirstChildOfClass("Humanoid")
	if victimRoot == nil then
		return
	end
	local direction = (victimRoot.Position - root.Position).Unit
	victimRoot.AssemblyLinearVelocity = direction * GameConfig.SLAP_KNOCKBACK + Vector3.new(0, 25, 0)
	if victimHumanoid ~= nil then
		victimHumanoid.WalkSpeed = 0
		task.delay(1, function()
			if victimHumanoid.Parent ~= nil then
				victimHumanoid.WalkSpeed = 16
			end
		end)
	end
	-- A slapped thief drops the brainrot, which runs back to its real home.
	local victimState = PlayerData.get(best)
	if victimState ~= nil and victimState.carried ~= nil then
		local conveyor = require(script.Parent:WaitForChild("ConveyorService"))
		conveyor.dropCarried(best, victimState, true)
		notifyRemote:FireClient(best, "You got SLAPPED and dropped the brainrot!")
	end
	notifyRemote:FireClient(player, "SLAP! You sent " .. best.DisplayName .. " flying!")
end

function StealService.start(remotes: { notify: RemoteEvent, slap: RemoteEvent })
	notifyRemote = remotes.notify
	remotes.slap.OnServerEvent:Connect(function(player)
		local state = PlayerData.get(player)
		if state ~= nil then
			StealService.slap(player, state)
		end
	end)
end

return StealService
