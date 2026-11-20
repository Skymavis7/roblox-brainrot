-- RebirthService: rebirths and the cash shop (upgrades), plus base locking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local RebirthService = {}

local notifyRemote = nil

local function tell(player, message)
	if notifyRemote then
		notifyRemote:FireClient(player, message)
	end
end

function RebirthService.rebirthCost(state)
	return GameConfig.REBIRTH_BASE_COST * (2 ^ state.rebirths)
end

function RebirthService.rebirth(player, state)
	local cost = RebirthService.rebirthCost(state)
	if state.cash < cost then
		tell(player, "Rebirth costs " .. Catalog.formatMoney(cost) .. ". Keep earning!")
		return
	end
	for _, model in pairs(state.placed) do
		model:Destroy()
	end
	table.clear(state.placed)
	if state.carried then
		state.carried:Destroy()
		state.carried = nil
		player:SetAttribute("Carrying", "")
	end
	PlayerData.setCash(state, 0)
	PlayerData.setRebirths(state, state.rebirths + 1)
	PlayerData.refreshBrainrotCount(state)
	tell(player, string.format("REBIRTH #%d! Income x%.1f forever. The grind begins again!", state.rebirths, state.incomeMultiplier))
end

function RebirthService.buyUpgrade(player, state, upgradeId)
	local upgrade = GameConfig.UPGRADES[upgradeId]
	if not upgrade then
		return
	end
	if state.upgrades[upgradeId] then
		tell(player, "You already own " .. upgrade.name .. "!")
		return
	end
	if state.cash < upgrade.cost then
		tell(player, upgrade.name .. " costs " .. Catalog.formatMoney(upgrade.cost) .. "!")
		return
	end
	PlayerData.addCash(state, -upgrade.cost)
	state.upgrades[upgradeId] = true
	if upgradeId == "speed" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 24
		end
	elseif upgradeId == "slots" then
		state.slotCount = GameConfig.BASE_SLOT_COUNT_UPGRADED
	end
	tell(player, "Bought " .. upgrade.name .. "! " .. upgrade.description)
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
		if typeof(upgradeId) ~= "string" then
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
			tell(player, "Base LOCKED for 60s! Nobody can steal from you.")
		else
			local left = math.ceil(state.lockCooldownUntil - os.clock())
			if left < 0 then
				left = 0
			end
			tell(player, "Base lock is cooling down (" .. left .. "s left).")
		end
	end)
end

return RebirthService
