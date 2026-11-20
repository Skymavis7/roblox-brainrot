-- DataService: persist cash, rebirths and upgrades in a DataStore.
-- In Studio without API access the store is nil and everything is a no-op.

local DataStoreService = game:GetService("DataStoreService")
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)

local DataService = {}

local STORE_NAME = "BrainrotLagoonSaveV1"
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	end
end

local function keyFor(state)
	return "player_" .. state.player.UserId
end

function DataService.loadSave(state)
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync(keyFor(state))
	end)
	if not ok or typeof(data) ~= "table" then
		return
	end
	if typeof(data.cash) == "number" then
		PlayerData.setCash(state, data.cash)
	end
	if typeof(data.rebirths) == "number" then
		PlayerData.setRebirths(state, data.rebirths)
	end
	if typeof(data.upgrades) == "table" then
		for _, id in ipairs({ "speed", "income", "slots" }) do
			if data.upgrades[id] == true then
				state.upgrades[id] = true
			end
		end
		if state.upgrades.slots then
			state.slotCount = GameConfig.BASE_SLOT_COUNT_UPGRADED
		end
	end
end

function DataService.saveSave(state)
	if not store then
		return
	end
	pcall(function()
		store:SetAsync(keyFor(state), {
			cash = state.cash,
			rebirths = state.rebirths,
			upgrades = state.upgrades,
		})
	end)
end

return DataService
