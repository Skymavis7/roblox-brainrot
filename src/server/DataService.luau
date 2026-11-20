-- DataService: cash, rebirths and upgrades persist in a DataStore between
-- sessions. In Studio without API access the store is nil and everything
-- silently does nothing.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)
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

local function saveKey(state)
	return "player_" .. state.player.UserId
end

function DataService.loadSave(state)
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync(saveKey(state))
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	if type(data.cash) == "number" then
		PlayerData.setCash(state, data.cash)
	end
	if type(data.rebirths) == "number" then
		PlayerData.setRebirths(state, data.rebirths)
	end
	if type(data.upgrades) == "table" then
		for _, key in ipairs({ "speed", "income", "slots" }) do
			if data.upgrades[key] == true then
				state.upgrades[key] = true
			end
		end
		if state.upgrades.slots then
			state.slotCount = Config.BASE_SLOT_COUNT_UPGRADED
		end
	end
end

function DataService.saveSave(state)
	if not store then
		return
	end
	local payload = {
		cash = state.cash,
		rebirths = state.rebirths,
		upgrades = {
			speed = state.upgrades.speed,
			income = state.upgrades.income,
			slots = state.upgrades.slots,
		},
	}
	pcall(function()
		store:SetAsync(saveKey(state), payload)
	end)
end

return DataService
