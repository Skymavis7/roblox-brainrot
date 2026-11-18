-- RebirthService: rebirths and the cash shop. A rebirth costs more every time
-- (100k, then double), wipes your cash and brainrots, and adds +50% income forever.
-- The shop sells Speed Boots, Double Scoop income and a 4-slot base extension.

local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local RebirthService = {}

local notifyRemote: RemoteEvent

-- What the next rebirth costs for this player.
function RebirthService.rebirthCost(state): number
	return GameConfig.REBIRTH_BASE_COST * (2 ^ state.rebirths)
end

-- Rebirth: wipe cash and brainrots, add +50% income, count it.
function RebirthService.rebirth(player: Player, state)
	local cost = RebirthService.rebirthCost(state)
	if state.cash < cost then
		notifyRemote:FireClient(player, "Rebirth costs " .. BrainrotCatalog.formatMoney(cost) .. ". Keep earning!")
		return
	end
	-- Clear the base and anything carried.
	for _, model in pairs(state.placed) do
		model:Destroy()
	end
	state.placed = {}
	if state.carried ~= nil then
		state.carried:Destroy()
		state.carried = nil
	end
	PlayerData.setCash(state, 0)
	PlayerData.setRebirths(state, state.rebirths + 1)
	PlayerData.refreshBrainrotCount(state)
	notifyRemote:FireClient(player, "REBIRTH #" .. state.rebirths .. "! Income x" ..
		string.format("%.1f", state.incomeMultiplier) .. " forever. The grind begins again!")
end

-- Buy one shop upgrade with cash. Each can only be bought once.
function RebirthService.buyUpgrade(player: Player, state, upgradeId: string)
	local upgrade = GameConfig.UPGRADES[upgradeId]
	if upgrade == nil then
		return
	end
	if state.upgrades[upgradeId] == true then
		notifyRemote:FireClient(player, "You already own " .. upgrade.name .. "!")
		return
	end
	if state.cash < upgrade.cost then
		notifyRemote:FireClient(player, upgrade.name .. " costs " .. BrainrotCatalog.formatMoney(upgrade.cost) .. "!")
		return
	end
	PlayerData.addCash(state, -upgrade.cost)
	state.upgrades[upgradeId] = true
	if upgradeId == "speed" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.WalkSpeed = 24
		end
	elseif upgradeId == "slots" then
		state.slotCount = GameConfig.BASE_SLOT_COUNT_UPGRADED
	end
	notifyRemote:FireClient(player, "Bought " .. upgrade.name .. "! " .. upgrade.description)
end

function RebirthService.start(remotes: { notify: RemoteEvent, rebirth: RemoteEvent, buyUpgrade: RemoteEvent, lockBase: RemoteEvent })
	notifyRemote = remotes.notify
	remotes.rebirth.OnServerEvent:Connect(function(player)
		local state = PlayerData.get(player)
		if state ~= nil then
			RebirthService.rebirth(player, state)
		end
	end)
	remotes.buyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		local state = PlayerData.get(player)
		if state ~= nil and typeof(upgradeId) == "string" then
			RebirthService.buyUpgrade(player, state, upgradeId)
		end
	end)
	remotes.lockBase.OnServerEvent:Connect(function(player)
		local state = PlayerData.get(player)
		if state == nil then
			return
		end
		if BaseService.lockBase(state) then
			notifyRemote:FireClient(player, "Base LOCKED for " .. GameConfig.LOCK_DURATION .. "s! Nobody can steal from you.")
		else
			local left = math.ceil(state.lockCooldownUntil - os.clock())
			notifyRemote:FireClient(player, "Base lock is cooling down (" .. left .. "s left).")
		end
	end)
end

return RebirthService
