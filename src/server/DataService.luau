-- DataService: saves a player's cash, rebirths and upgrades between sessions.
-- Everything is wrapped in pcall: in Studio without API access it simply does nothing.

local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local DataService = {}

local store: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore("BrainrotLagoonSaveV1")
end)

-- Load a returning player's save into their state. Silently keeps the fresh start on any failure.
function DataService.loadSave(state)
	if store == nil then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync("player_" .. state.player.UserId)
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
		for key, value in pairs(data.upgrades) do
			if state.upgrades[key] ~= nil then
				state.upgrades[key] = value == true
			end
		end
		if state.upgrades.slots then
			state.slotCount = GameConfig.BASE_SLOT_COUNT_UPGRADED
		end
	end
end

-- Save a leaving player's cash, rebirths and upgrades. Fails silently.
function DataService.saveSave(state)
	if store == nil then
		return
	end
	pcall(function()
		store:SetAsync("player_" .. state.player.UserId, {
			cash = state.cash,
			rebirths = state.rebirths,
			upgrades = state.upgrades,
		})
	end)
end

return DataService
