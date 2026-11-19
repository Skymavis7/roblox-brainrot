-- MoneyService — the money tick. Every second, each player's base earns the
-- sum of its brainrots' dollars-per-second, times their rebirth and upgrade
-- multipliers. The HUD reads the leaderstats this writes, so the cash counter
-- visibly ticks up.

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local MoneyService = {}

-- Pay every player one second of income, and refresh their Income leaderstat.
function MoneyService.payIncomeTick()
	for player, state in pairs(PlayerData.all()) do
		local income = PlayerData.calculateIncome(state)
		local folder = player:FindFirstChild("leaderstats")
		if folder ~= nil then
			local incomeValue = folder:FindFirstChild("Income")
			if incomeValue ~= nil and incomeValue:IsA("IntValue") then
				incomeValue.Value = math.floor(income)
			end
		end
		if income > 0 then
			PlayerData.addCash(state, income)
		end
	end
end

function MoneyService.start()
	task.spawn(function()
		while true do
			task.wait(1)
			MoneyService.payIncomeTick()
		end
	end)
end

return MoneyService
