-- BaseService: the six player bases — claiming, slots, locking, placement.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)

local BaseService = {}

local owners = {} -- base index -> player (or nil)
local folders = {} -- base index -> Model folder in Workspace

function BaseService.registerBaseFolder(index, folder)
	folders[index] = folder
end

function BaseService.assignBase(state)
	for index = 1, #Config.BASES do
		if owners[index] == nil then
			owners[index] = state.player
			state.baseIndex = index
			return index
		end
	end
	return nil
end

function BaseService.releaseBase(state)
	local index = state.baseIndex
	if not index then
		return
	end
	owners[index] = nil
	state.baseIndex = nil
	local folder = folders[index]
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") then
				child:Destroy()
			end
		end
	end
end

-- Where a brainrot stands on a base: the plot centre plus its slot offset.
function BaseService.slotPosition(baseIndex, slot, slotCount)
	local plot = Config.BASES[baseIndex]
	local offsets = Config.SLOT_OFFSETS
	if slotCount > Config.BASE_SLOT_COUNT then
		offsets = Config.SLOT_OFFSETS_UPGRADED
	end
	local offset = offsets[slot] or Vector3.zero
	return Vector3.new(plot.center.X + offset.X, 0.5, plot.center.Z + offset.Z)
end

function BaseService.isInsideBase(baseIndex, position)
	if not baseIndex or not Config.BASES[baseIndex] then
		return false
	end
	local plot = Config.BASES[baseIndex]
	local half = Config.BASE_SIZE / 2
	return math.abs(position.X - plot.center.X) <= half
		and math.abs(position.Z - plot.center.Z) <= half
end

function BaseService.placeOnBase(state, model)
	if not state.baseIndex then
		return false
	end
	local slot = PlayerData.firstFreeSlot(state)
	if not slot then
		return false
	end
	local spot = BaseService.slotPosition(state.baseIndex, slot, state.slotCount)
	model:SetAttribute("State", "Placed")
	model:SetAttribute("OwnerId", state.player.UserId)
	model:SetAttribute("Slot", slot)
	model:PivotTo(CFrame.new(spot))
	local folder = folders[state.baseIndex]
	if folder then
		model.Parent = folder
	end
	state.placed[slot] = model
	state.player:SetAttribute("Carrying", "")
	PlayerData.refreshBrainrotCount(state)
	return true
end

function BaseService.removeFromBase(state, model)
	local slot = model:GetAttribute("Slot")
	if type(slot) == "number" and state.placed[slot] == model then
		state.placed[slot] = nil
		PlayerData.refreshBrainrotCount(state)
	end
end

function BaseService.lockBase(state)
	local now = os.clock()
	if now < state.lockCooldownUntil then
		return false
	end
	state.lockUntil = now + Config.LOCK_DURATION
	state.lockCooldownUntil = now + Config.LOCK_COOLDOWN
	return true
end

return BaseService
