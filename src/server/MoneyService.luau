-- MoneyService: pay every player one second of income, once a second.

local PlayerData = require(script.Parent.PlayerData)

local MoneyService = {}

function MoneyService.payIncomeTick()
	for _, state in pairs(PlayerData.all()) do
		local income = PlayerData.calculateIncome(state)
		local folder = state.leaderstats
		if folder then
			local incomeValue = folder:FindFirstChild("Income")
			if incomeValue then
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
