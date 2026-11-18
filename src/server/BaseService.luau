-- BaseService: the six player bases. Each player claims one base when they join;
-- their brainrots sit on its slot pads and earn money there. A base can be locked
-- against stealing, and the wave only spares players standing on their own base.

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseService = {}

local takenBases: { [number]: Player } = {}
local baseFolders: { [number]: Model } = {}

-- Find the base plot for a player who just joined. Returns nil when all six are taken.
function BaseService.assignBase(state): number?
	for index = 1, #GameConfig.BASES do
		if takenBases[index] == nil then
			takenBases[index] = state.player
			state.baseIndex = index
			return index
		end
	end
	return nil
end

-- Free a base when its owner leaves, and clear the brainrots left on it.
function BaseService.releaseBase(state)
	local index = state.baseIndex
	if index == nil then
		return
	end
	takenBases[index] = nil
	state.baseIndex = nil
	local folder = baseFolders[index]
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") then
				child:Destroy()
			end
		end
	end
end

-- The world position of one slot pad on a base.
function BaseService.slotPosition(baseIndex: number, slot: number, slotCount: number): Vector3
	local base = GameConfig.BASES[baseIndex]
	local offsets = GameConfig.SLOT_OFFSETS
	if slotCount > GameConfig.BASE_SLOT_COUNT then
		offsets = GameConfig.SLOT_OFFSETS_UPGRADED
	end
	local offset = offsets[slot] or offsets[1]
	return base.position + offset + Vector3.new(0, 0.5, 0)
end

-- Is a world position inside this base's plot (the wave's safe zone)?
function BaseService.isInsideBase(baseIndex: number, position: Vector3): boolean
	local base = GameConfig.BASES[baseIndex]
	local half = GameConfig.BASE_SIZE / 2
	return math.abs(position.X - base.position.X) <= half
		and math.abs(position.Z - base.position.Z) <= half
end

-- Put a brainrot model onto a free slot of its owner's base and start it earning.
function BaseService.placeOnBase(state, model: Model): boolean
	local slot = PlayerData.firstFreeSlot(state)
	local baseIndex = state.baseIndex
	if slot == nil or baseIndex == nil then
		return false
	end
	local target = BaseService.slotPosition(baseIndex, slot, state.slotCount)
	model:SetAttribute("State", "Placed")
	model:SetAttribute("OwnerId", state.player.UserId)
	model:SetAttribute("Slot", slot)
	model:PivotTo(CFrame.new(target))
	local folder = baseFolders[baseIndex]
	if folder then
		model.Parent = folder
	end
	state.placed[slot] = model
	state.player:SetAttribute("Carrying", "")
	PlayerData.refreshBrainrotCount(state)
	return true
end

-- Take a brainrot off a base (stolen, rebirthed away, or returned after a drop).
function BaseService.removeFromBase(state, model: Model)
	local slot = model:GetAttribute("Slot")
	if typeof(slot) == "number" and state.placed[slot] == model then
		state.placed[slot] = nil
		PlayerData.refreshBrainrotCount(state)
	end
end

-- Lock this player's base against stealing for LOCK_DURATION seconds.
-- Returns false when the lock is still cooling down.
function BaseService.lockBase(state): boolean
	local now = os.clock()
	if now < state.lockCooldownUntil then
		return false
	end
	state.lockUntil = now + GameConfig.LOCK_DURATION
	state.lockCooldownUntil = now + GameConfig.LOCK_COOLDOWN
	return true
end

-- The folder in the world that holds one base's placed brainrots.
function BaseService.registerBaseFolder(index: number, folder: Model)
	baseFolders[index] = folder
end

return BaseService
