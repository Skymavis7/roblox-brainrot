-- MoneyService: pays every player one second of income, every second.
local PlayerData = require(script.Parent.PlayerData)

local MoneyService = {}

function MoneyService.payIncomeTick()
	for _, state in pairs(PlayerData.all()) do
		local income = PlayerData.calculateIncome(state)
		local board = state.leaderstats
		if board then
			local value = board:FindFirstChild("Income")
			if value then
				value.Value = math.floor(income)
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
