-- Hud.client: the Brainrot Lagoon HUD — cash, income, rebirth, tsunami
-- countdown, carry status, slap/lock/rebirth/shop buttons, catalog + shop,
-- and toasts from the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Config = require(ReplicatedStorage.Shared.GameConfig)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local slapRemote = remotes:WaitForChild("Slap")
local lockRemote = remotes:WaitForChild("LockBase")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local buyUpgradeRemote = remotes:WaitForChild("BuyUpgrade")
local gameState = ReplicatedStorage:WaitForChild("GameState")
local waveCountdown = gameState:WaitForChild("WaveCountdown")
local wavePhase = gameState:WaitForChild("WaveState")
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")
local incomeValue = leaderstats:WaitForChild("Income")
local rebirthsValue = leaderstats:WaitForChild("Rebirths")

local PANEL = Color3.fromRGB(20, 20, 30)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREEN = Color3.fromRGB(120, 255, 130)
local YELLOW = Color3.fromRGB(255, 230, 120)
local PURPLE = Color3.fromRGB(200, 150, 255)
local SKY = Color3.fromRGB(140, 220, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
	return ui
end

local function makeLabel(parent, text, size, font, textSize, color, position, anchor)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = color
	label.Text = text
	label.Parent = parent
	return label
end

local function makeButton(parent, text, size, position, color, textSize)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Font = Enum.Font.FredokaOne
	button.TextSize = textSize or 20
	button.TextColor3 = WHITE
	button.Text = text
	button.Parent = parent
	corner(button, 10)
	return button
end

-- ---------------------------------------------------------------- top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromOffset(520, 52)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.BackgroundColor3 = PANEL
topBar.BackgroundTransparency = 0.2
topBar.Parent = gui
corner(topBar, 10)

local cashLabel = makeLabel(topBar, "$100", UDim2.fromOffset(220, 52), Enum.Font.FredokaOne, 28, GREEN, UDim2.fromOffset(8, 0))
local incomeLabel = makeLabel(topBar, "+$0/s", UDim2.fromOffset(170, 52), Enum.Font.FredokaOne, 24, YELLOW, UDim2.fromOffset(228, 0))
local rebirthLabel = makeLabel(topBar, "Rebirth 0", UDim2.fromOffset(110, 52), Enum.Font.FredokaOne, 20, PURPLE, UDim2.fromOffset(398, 0))

-- ---------------------------------------------------------------- tsunami banner
local banner = Instance.new("Frame")
banner.Name = "WaveBanner"
banner.Size = UDim2.fromOffset(520, 44)
banner.Position = UDim2.new(0.5, 0, 0, 76)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.BackgroundColor3 = PANEL
banner.BackgroundTransparency = 0.2
banner.Parent = gui
corner(banner, 10)

local bannerLabel = makeLabel(banner, "Noodle Tsunami in 100s", UDim2.new(1, 0, 1, 0), Enum.Font.FredokaOne, 22, SKY, UDim2.new(0, 0, 0, 0))
bannerLabel.TextWrapped = true

-- ---------------------------------------------------------------- carry label
local carryLabel = makeLabel(
	gui,
	"",
	UDim2.fromOffset(400, 40),
	Enum.Font.SourceSansBold,
	18,
	WHITE,
	UDim2.new(0.5, 0, 1, -56),
	Vector2.new(0.5, 1)
)
carryLabel.BackgroundColor3 = PANEL
carryLabel.BackgroundTransparency = 0.2
carryLabel.Visible = false
corner(carryLabel, 8)

-- ---------------------------------------------------------------- right-hand buttons
local buttonStack = Instance.new("Frame")
buttonStack.Name = "ButtonStack"
buttonStack.Size = UDim2.fromOffset(190, 240)
buttonStack.Position = UDim2.new(1, -16, 0, 140)
buttonStack.AnchorPoint = Vector2.new(1, 0)
buttonStack.BackgroundTransparency = 1
buttonStack.Parent = gui

local slapButton = makeButton(buttonStack, "SLAP [F]", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 0), Color3.fromRGB(230, 80, 80))
local lockButton = makeButton(buttonStack, "LOCK BASE [L]", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 62), Color3.fromRGB(70, 130, 230))
local rebirthButton = makeButton(buttonStack, "REBIRTH", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 124), Color3.fromRGB(160, 80, 220))
local shopButton = makeButton(buttonStack, "CATALOG + SHOP", UDim2.fromOffset(190, 52), UDim2.fromOffset(0, 186), Color3.fromRGB(60, 180, 120))

-- ---------------------------------------------------------------- shop panel
local shop = Instance.new("Frame")
shop.Name = "ShopPanel"
shop.Size = UDim2.fromOffset(560, 480)
shop.Position = UDim2.new(0.5, 0, 0.5, 0)
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.BackgroundColor3 = PANEL
shop.Visible = false
shop.Parent = gui
corner(shop, 10)

makeLabel(
	shop,
	"WEIRDO CATALOG — buy them on the conveyor, place them on your base",
	UDim2.new(1, -24, 0, 36),
	Enum.Font.FredokaOne,
	18,
	WHITE,
	UDim2.fromOffset(12, 8)
)

local catalogList = Instance.new("ScrollingFrame")
catalogList.Name = "CatalogList"
catalogList.Size = UDim2.fromOffset(528, 250)
catalogList.Position = UDim2.fromOffset(16, 52)
catalogList.BackgroundTransparency = 1
catalogList.ScrollBarThickness = 6
catalogList.CanvasSize = UDim2.fromOffset(0, #Catalog.CHARACTERS * 42)
catalogList.Parent = shop

local function rarityColor(name)
	for _, rarity in ipairs(Catalog.RARITIES) do
		if rarity.name == name then
			return rarity.color
		end
	end
	return WHITE
end

for index, entry in ipairs(Catalog.CHARACTERS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.Position = UDim2.fromOffset(0, (index - 1) * 42)
	row.BackgroundTransparency = 1
	row.Parent = catalogList
	makeLabel(row, entry.name, UDim2.fromOffset(230, 42), Enum.Font.SourceSansBold, 18, rarityColor(entry.rarity), UDim2.fromOffset(4, 0))
	makeLabel(
		row,
		Catalog.formatMoney(entry.rate) .. "/s",
		UDim2.fromOffset(120, 42),
		Enum.Font.SourceSansBold,
		18,
		GREEN,
		UDim2.fromOffset(238, 0)
	)
	makeLabel(
		row,
		Catalog.formatMoney(entry.cost),
		UDim2.fromOffset(120, 42),
		Enum.Font.SourceSansBold,
		18,
		YELLOW,
		UDim2.fromOffset(362, 0)
	)
end

makeLabel(
	shop,
	"UPGRADES — spend cash, keep them forever",
	UDim2.new(1, -24, 0, 30),
	Enum.Font.FredokaOne,
	18,
	WHITE,
	UDim2.fromOffset(12, 312)
)

local upgradeOrder = { "speed", "income", "slots" }
for i, id in ipairs(upgradeOrder) do
	local upgrade = Config.UPGRADES[id]
	local button = makeButton(
		shop,
		upgrade.name .. " — " .. Catalog.formatMoney(upgrade.cost) .. "  •  " .. upgrade.description,
		UDim2.fromOffset(528, 34),
		UDim2.fromOffset(16, 344 + (i - 1) * 40),
		Color3.fromRGB(70, 120, 200),
		16
	)
	button.MouseButton1Click:Connect(function()
		buyUpgradeRemote:FireServer(id)
	end)
end

-- ---------------------------------------------------------------- toasts
local toastArea = Instance.new("Frame")
toastArea.Name = "ToastArea"
toastArea.Size = UDim2.fromOffset(560, 120)
toastArea.Position = UDim2.new(0.5, 0, 1, -128)
toastArea.AnchorPoint = Vector2.new(0.5, 1)
toastArea.BackgroundTransparency = 1
toastArea.Parent = gui

local activeToasts = {}

local function reflowToasts()
	for i, toast in ipairs(activeToasts) do
		toast.Position = UDim2.new(0, 0, 1, -i * 38)
	end
end

local function showToast(message)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 34)
	toast.BackgroundColor3 = PANEL
	toast.BackgroundTransparency = 0.15
	toast.Font = Enum.Font.SourceSansBold
	toast.TextSize = 17
	toast.TextColor3 = WHITE
	toast.Text = message
	toast.TextWrapped = true
	toast.Parent = toastArea
	corner(toast, 8)
	table.insert(activeToasts, 1, toast)
	reflowToasts()
	task.delay(4, function()
		local at = table.find(activeToasts, toast)
		if at then
			table.remove(activeToasts, at)
		end
		toast:Destroy()
		reflowToasts()
	end)
end

notifyRemote.OnClientEvent:Connect(showToast)

-- ---------------------------------------------------------------- wiring
slapButton.MouseButton1Click:Connect(function()
	slapRemote:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)
shopButton.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		slapRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.L then
		lockRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B then
		shop.Visible = not shop.Visible
	end
end)

-- ---------------------------------------------------------------- live refresh
local function refresh()
	cashLabel.Text = Catalog.formatMoney(cashValue.Value)
	incomeLabel.Text = "+" .. Catalog.formatMoney(incomeValue.Value) .. "/s"
	local rebirths = rebirthsValue.Value
	rebirthLabel.Text = "Rebirth " .. rebirths
	rebirthButton.Text = "REBIRTH — " .. Catalog.formatMoney(Config.REBIRTH_BASE_COST * 2 ^ rebirths)

	local seconds = waveCountdown.Value
	local phase = wavePhase.Value
	if phase == "Warning" then
		banner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		bannerLabel.TextColor3 = WHITE
		bannerLabel.Text = "NOODLE TSUNAMI IN " .. seconds .. "s — RUN HOME!"
	elseif phase == "Wave" then
		banner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		bannerLabel.TextColor3 = WHITE
		bannerLabel.Text = "THE NOODLE TSUNAMI IS HERE — STAY ON YOUR BASE!"
	else
		banner.BackgroundColor3 = PANEL
		bannerLabel.TextColor3 = SKY
		bannerLabel.Text = "Noodle Tsunami in " .. seconds .. "s"
	end

	local carrying = player:GetAttribute("Carrying")
	if type(carrying) == "string" and carrying ~= "" then
		carryLabel.Text = "Carrying: " .. carrying .. " — take it to YOUR base!"
		carryLabel.Visible = true
	else
		carryLabel.Visible = false
	end
end

cashValue:GetPropertyChangedSignal("Value"):Connect(refresh)
incomeValue:GetPropertyChangedSignal("Value"):Connect(refresh)
rebirthsValue:GetPropertyChangedSignal("Value"):Connect(refresh)
waveCountdown:GetPropertyChangedSignal("Value"):Connect(refresh)
wavePhase:GetPropertyChangedSignal("Value"):Connect(refresh)
player:GetAttributeChangedSignal("Carrying"):Connect(refresh)

refresh()
showToast("Welcome to Brainrot Lagoon! Buy a weirdo on the conveyor!")
