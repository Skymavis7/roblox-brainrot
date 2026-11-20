-- BaseService: the six player bases — claiming, slots, placing, locking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)

local BaseService = {}

local owners = { nil, nil, nil, nil, nil, nil }
local folders = {}

function BaseService.registerBaseFolder(index, folder)
	folders[index] = folder
end

function BaseService.assignBase(state)
	for index = 1, 6 do
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
			child:Destroy()
		end
	end
end

function BaseService.slotPosition(baseIndex, slot, slotCount)
	local base = GameConfig.BASES[baseIndex]
	local offsets = GameConfig.SLOT_OFFSETS
	if slotCount > GameConfig.BASE_SLOT_COUNT then
		offsets = GameConfig.SLOT_OFFSETS_UPGRADED
	end
	local offset = offsets[slot] or Vector3.new(0, 0, 0)
	return base.center + offset + Vector3.new(0, 0.5, 0)
end

function BaseService.isInsideBase(baseIndex, position)
	local base = GameConfig.BASES[baseIndex]
	local half = GameConfig.BASE_SIZE / 2
	return math.abs(position.X - base.center.X) <= half
		and math.abs(position.Z - base.center.Z) <= half
end

function BaseService.placeOnBase(state, model)
	if not state.baseIndex then
		return false
	end
	local slot = PlayerData.firstFreeSlot(state)
	if not slot then
		return false
	end
	model:SetAttribute("State", "Placed")
	model:SetAttribute("OwnerId", state.player.UserId)
	model:SetAttribute("Slot", slot)
	local target = BaseService.slotPosition(state.baseIndex, slot, state.slotCount)
	local primary = model.PrimaryPart
	if primary then
		model:PivotTo(CFrame.new(target))
	end
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
	if typeof(slot) == "number" and state.placed[slot] == model then
		state.placed[slot] = nil
		PlayerData.refreshBrainrotCount(state)
	end
end

function BaseService.lockBase(state)
	local now = os.clock()
	if now < state.lockCooldownUntil then
		return false
	end
	state.lockUntil = now + GameConfig.LOCK_DURATION
	state.lockCooldownUntil = now + GameConfig.LOCK_COOLDOWN
	return true
end

return BaseService
