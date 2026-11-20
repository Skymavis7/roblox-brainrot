-- Hud.client: the whole player HUD — top bar, tsunami banner, carry label,
-- action buttons, catalog + shop panel, and toasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameState = ReplicatedStorage:WaitForChild("GameState")

local PANEL = Color3.fromRGB(20, 20, 30)
local WHITE = Color3.fromRGB(255, 255, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, size, position, text, color, font, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundColor3 = PANEL
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.Font = font
	label.TextSize = textSize
	label.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return label
end

local function makeButton(parent, name, size, position, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = WHITE
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 20
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromOffset(520, 52)
topBar.Position = UDim2.new(0.5, -260, 0, 12)
topBar.BackgroundTransparency = 1
topBar.Parent = gui

local cashLabel = makeLabel(topBar, "Cash", UDim2.fromOffset(220, 52), UDim2.fromOffset(0, 0), "$100", Color3.fromRGB(120, 255, 130), Enum.Font.FredokaOne, 28)
local incomeLabel = makeLabel(topBar, "Income", UDim2.fromOffset(170, 52), UDim2.fromOffset(230, 0), "+$0/s", Color3.fromRGB(255, 230, 120), Enum.Font.FredokaOne, 24)
local rebirthLabel = makeLabel(topBar, "Rebirth", UDim2.fromOffset(110, 52), UDim2.fromOffset(410, 0), "Rebirth 0", Color3.fromRGB(200, 150, 255), Enum.Font.FredokaOne, 20)

-- Tsunami banner
local waveBanner = makeLabel(gui, "WaveBanner", UDim2.fromOffset(520, 44), UDim2.new(0.5, -260, 0, 76), "Noodle Tsunami in 100s", Color3.fromRGB(140, 220, 255), Enum.Font.SourceSansBold, 22)

-- Carry label
local carryLabel = makeLabel(gui, "Carry", UDim2.fromOffset(400, 40), UDim2.new(0.5, -200, 1, -60), "", WHITE, Enum.Font.SourceSansBold, 20)
carryLabel.Visible = false

-- Right-hand button stack
local stack = Instance.new("Frame")
stack.Name = "Actions"
stack.Size = UDim2.fromOffset(190, 250)
stack.Position = UDim2.new(1, -206, 0, 140)
stack.BackgroundTransparency = 1
stack.Parent = gui

local slapButton = makeButton(stack, "Slap", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 0), "SLAP [F]", Color3.fromRGB(230, 80, 80))
local lockButton = makeButton(stack, "Lock", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 62), "LOCK BASE [L]", Color3.fromRGB(70, 130, 230))
local rebirthButton = makeButton(stack, "Rebirth", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 124), "REBIRTH", Color3.fromRGB(160, 80, 220))
local shopButton = makeButton(stack, "Shop", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 186), "CATALOG + SHOP", Color3.fromRGB(60, 180, 120))

-- Shop panel
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.Size = UDim2.fromOffset(560, 480)
shopPanel.Position = UDim2.new(0.5, -280, 0.5, -240)
shopPanel.BackgroundColor3 = PANEL
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -24, 0, 30)
shopTitle.Position = UDim2.fromOffset(12, 10)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "WEIRDO CATALOG — buy them on the conveyor, place them on your base"
shopTitle.TextColor3 = WHITE
shopTitle.Font = Enum.Font.FredokaOne
shopTitle.TextSize = 16
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shopPanel

local catalogList = Instance.new("ScrollingFrame")
catalogList.Size = UDim2.new(1, -32, 0, 250)
catalogList.Position = UDim2.fromOffset(16, 48)
catalogList.BackgroundTransparency = 1
catalogList.ScrollBarThickness = 6
catalogList.CanvasSize = UDim2.new(0, 0, 0, #Catalog.CHARACTERS * 42)
catalogList.Parent = shopPanel

for index, entry in ipairs(Catalog.CHARACTERS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.Position = UDim2.fromOffset(0, (index - 1) * 42)
	row.BackgroundTransparency = 1
	row.Parent = catalogList

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 230, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Catalog.rarityColor(entry.rarity)
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Size = UDim2.new(0, 120, 1, 0)
	rateLabel.Position = UDim2.fromOffset(230, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Catalog.formatMoney(entry.rate) .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextSize = 16
	rateLabel.TextXAlignment = Enum.TextXAlignment.Left
	rateLabel.Parent = row

	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(0, 120, 1, 0)
	costLabel.Position = UDim2.fromOffset(350, 0)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = Catalog.formatMoney(entry.cost)
	costLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	costLabel.Font = Enum.Font.SourceSansBold
	costLabel.TextSize = 16
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = row
end

local upgradeTitle = Instance.new("TextLabel")
upgradeTitle.Size = UDim2.new(1, -24, 0, 26)
upgradeTitle.Position = UDim2.fromOffset(12, 306)
upgradeTitle.BackgroundTransparency = 1
upgradeTitle.Text = "UPGRADES — spend cash, keep them forever"
upgradeTitle.TextColor3 = WHITE
upgradeTitle.Font = Enum.Font.FredokaOne
upgradeTitle.TextSize = 16
upgradeTitle.TextXAlignment = Enum.TextXAlignment.Left
upgradeTitle.Parent = shopPanel

local upgradeIds = { "speed", "income", "slots" }
for index, id in ipairs(upgradeIds) do
	local upgrade = GameConfig.UPGRADES[id]
	local button = makeButton(shopPanel, "Upgrade_" .. id, UDim2.new(1, -32, 0, 34), UDim2.fromOffset(16, 336 + (index - 1) * 42), upgrade.name .. " — " .. Catalog.formatMoney(upgrade.cost) .. "  •  " .. upgrade.description, Color3.fromRGB(70, 120, 200))
	button.TextSize = 15
	button.MouseButton1Click:Connect(function()
		remotes.BuyUpgrade:FireServer(id)
	end)
end

-- Toasts
local toastArea = Instance.new("Frame")
toastArea.Name = "Toasts"
toastArea.Size = UDim2.fromOffset(560, 120)
toastArea.Position = UDim2.new(0.5, -280, 1, -140)
toastArea.BackgroundTransparency = 1
toastArea.Parent = gui

local function showToast(message)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 34)
	toast.Position = UDim2.new(0, 0, 1, -34)
	toast.BackgroundColor3 = PANEL
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 0
	toast.Text = message
	toast.TextColor3 = WHITE
	toast.Font = Enum.Font.SourceSansBold
	toast.TextSize = 16
	toast.Parent = toastArea
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	for _, other in ipairs(toastArea:GetChildren()) do
		if other ~= toast and other:IsA("TextLabel") then
			other.Position = other.Position - UDim2.fromOffset(0, 38)
		end
	end
	task.delay(4, function()
		toast:Destroy()
	end)
end

remotes.Notify.OnClientEvent:Connect(showToast)

-- Wiring
slapButton.MouseButton1Click:Connect(function()
	remotes.Slap:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	remotes.LockBase:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	remotes.Rebirth:FireServer()
end)
shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		remotes.Slap:FireServer()
	elseif input.KeyCode == Enum.KeyCode.L then
		remotes.LockBase:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B then
		shopPanel.Visible = not shopPanel.Visible
	end
end)

-- Live refresh
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local incomeValue = leaderstats:WaitForChild("Income")
local rebirthValue = leaderstats:WaitForChild("Rebirths")
local waveCountdown = gameState:WaitForChild("WaveCountdown")
local waveState = gameState:WaitForChild("WaveState")

local function refresh()
	cashLabel.Text = Catalog.formatMoney(cashValue.Value)
	incomeLabel.Text = "+" .. Catalog.formatMoney(incomeValue.Value) .. "/s"
	rebirthLabel.Text = "Rebirth " .. rebirthValue.Value
	rebirthButton.Text = "REBIRTH — " .. Catalog.formatMoney(GameConfig.REBIRTH_BASE_COST * (2 ^ rebirthValue.Value))
	local seconds = waveCountdown.Value
	local state = waveState.Value
	if state == "Warning" then
		waveBanner.Text = "NOODLE TSUNAMI IN " .. seconds .. "s — RUN HOME!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		waveBanner.TextColor3 = WHITE
	elseif state == "Wave" then
		waveBanner.Text = "THE NOODLE TSUNAMI IS HERE — STAY ON YOUR BASE!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		waveBanner.TextColor3 = WHITE
	else
		waveBanner.Text = "Noodle Tsunami in " .. seconds .. "s"
		waveBanner.BackgroundColor3 = PANEL
		waveBanner.TextColor3 = Color3.fromRGB(140, 220, 255)
	end
	local carrying = player:GetAttribute("Carrying")
	if typeof(carrying) == "string" and carrying ~= "" then
		carryLabel.Text = "Carrying: " .. carrying .. " — take it to YOUR base!"
		carryLabel.Visible = true
	else
		carryLabel.Visible = false
	end
end

cashValue.Changed:Connect(refresh)
incomeValue.Changed:Connect(refresh)
rebirthValue.Changed:Connect(refresh)
waveCountdown.Changed:Connect(refresh)
waveState.Changed:Connect(refresh)
player:GetAttributeChangedSignal("Carrying"):Connect(refresh)

refresh()
showToast("Welcome to Brainrot Lagoon! Buy a weirdo on the conveyor!")
