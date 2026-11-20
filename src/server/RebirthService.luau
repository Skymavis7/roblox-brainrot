-- RebirthService: rebirths and the cash shop (upgrades + base lock).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.GameConfig)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local RebirthService = {}

local notifyRemote = nil

local function notify(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function RebirthService.rebirthCost(state)
	return Config.REBIRTH_BASE_COST * 2 ^ state.rebirths
end

function RebirthService.rebirth(player, state)
	local cost = RebirthService.rebirthCost(state)
	if state.cash < cost then
		notify(player, "Rebirth costs " .. Catalog.formatMoney(cost) .. ". Keep earning!")
		return
	end
	-- Everything goes: placed brainrots and whatever is carried.
	for _, model in pairs(state.placed) do
		if model then
			model:Destroy()
		end
	end
	table.clear(state.placed)
	if state.carried then
		local ConveyorService = require(script.Parent.ConveyorService)
		ConveyorService.dropCarried(player, state, false)
	end
	PlayerData.setCash(state, 0)
	PlayerData.setRebirths(state, state.rebirths + 1)
	PlayerData.refreshBrainrotCount(state)
	notify(
		player,
		"REBIRTH #" .. state.rebirths .. "! Income x" .. string.format("%.1f", state.incomeMultiplier) .. " forever. The grind begins again!"
	)
end

function RebirthService.buyUpgrade(player, state, upgradeId)
	local upgrade = Config.UPGRADES[upgradeId]
	if not upgrade then
		return
	end
	if state.upgrades[upgradeId] then
		notify(player, "You already own " .. upgrade.name .. "!")
		return
	end
	if state.cash < upgrade.cost then
		notify(player, upgrade.name .. " costs " .. Catalog.formatMoney(upgrade.cost) .. "!")
		return
	end
	PlayerData.setCash(state, state.cash - upgrade.cost)
	state.upgrades[upgradeId] = true
	if upgradeId == "speed" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 24
		end
	elseif upgradeId == "slots" then
		state.slotCount = Config.BASE_SLOT_COUNT_UPGRADED
	end
	notify(player, "Bought " .. upgrade.name .. "! " .. upgrade.description)
end

function RebirthService.start(remotes)
	notifyRemote = remotes.Notify
	remotes.Rebirth.OnServerEvent:Connect(function(player)
		local state = PlayerData.get(player)
		if state then
			RebirthService.rebirth(player, state)
		end
	end)
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		if type(upgradeId) ~= "string" then
			return
		end
		local state = PlayerData.get(player)
		if state then
			RebirthService.buyUpgrade(player, state, upgradeId)
		end
	end)
	remotes.LockBase.OnServerEvent:Connect(function(player)
		local state = PlayerData.get(player)
		if not state then
			return
		end
		if BaseService.lockBase(state) then
			notify(player, "Base LOCKED for 60s! Nobody can steal from you.")
		else
			local left = math.ceil(state.lockCooldownUntil - os.clock())
			notify(player, "Base lock is cooling down (" .. left .. "s left).")
		end
	end)
end

return RebirthService
