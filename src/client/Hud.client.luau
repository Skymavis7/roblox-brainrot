-- Brainrot Lagoon — client HUD.
-- A ScreenGui over the 3D world: cash and income up top, the tsunami countdown banner,
-- Slap / Lock / Rebirth / Shop buttons on the right, the character catalog, the upgrade
-- shop, and toast notifications for everything the server tells you. The player still
-- moves with WASD and the camera in 3D; this is only the interface over that world.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gameState = ReplicatedStorage:WaitForChild("GameState")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local slapRemote = remotes:WaitForChild("Slap")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local buyUpgradeRemote = remotes:WaitForChild("BuyUpgrade")
local lockBaseRemote = remotes:WaitForChild("LockBase")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, position, size, text, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = font or Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.3
	label.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	return label
end

local function makeButton(parent, name, position, size, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.TextStrokeTransparency = 0.3
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- Top bar: cash, income per second, rebirths. Centred, clear of the Roblox menu buttons.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.fromOffset(520, 52)
topBar.BackgroundTransparency = 1
topBar.Parent = gui

local cashLabel = makeLabel(topBar, "CashLabel", UDim2.fromOffset(0, 0), UDim2.fromOffset(220, 52),
	"$100", 28, Color3.fromRGB(120, 255, 130), Enum.Font.FredokaOne)
local incomeLabel = makeLabel(topBar, "IncomeLabel", UDim2.fromOffset(230, 0), UDim2.fromOffset(170, 52),
	"+$0/s", 24, Color3.fromRGB(255, 230, 120))
local rebirthLabel = makeLabel(topBar, "RebirthLabel", UDim2.fromOffset(410, 0), UDim2.fromOffset(110, 52),
	"Rebirth 0", 20, Color3.fromRGB(200, 150, 255))

-- Tsunami banner under the top bar: calm countdown, then a red warning.
local waveBanner = makeLabel(gui, "WaveBanner", UDim2.new(0.5, -260, 0, 76), UDim2.fromOffset(520, 44),
	"Noodle Tsunami in 100s", 22, Color3.fromRGB(140, 220, 255))
waveBanner.BackgroundTransparency = 0.45

-- Carried indicator: what you are holding and where it needs to go.
local carryLabel = makeLabel(gui, "CarryLabel", UDim2.new(0.5, -200, 1, -120), UDim2.fromOffset(400, 40),
	"", 20, Color3.fromRGB(255, 255, 255))
carryLabel.Visible = false

-- Right-hand action buttons.
local buttonStack = Instance.new("Frame")
buttonStack.Name = "ActionButtons"
buttonStack.AnchorPoint = Vector2.new(1, 0)
buttonStack.Position = UDim2.new(1, -16, 0, 140)
buttonStack.Size = UDim2.fromOffset(190, 260)
buttonStack.BackgroundTransparency = 1
buttonStack.Parent = gui

local slapButton = makeButton(buttonStack, "SlapButton", UDim2.fromOffset(0, 0), UDim2.fromOffset(190, 52),
	"SLAP  [F]", Color3.fromRGB(230, 80, 80))
local lockButton = makeButton(buttonStack, "LockButton", UDim2.fromOffset(0, 62), UDim2.fromOffset(190, 52),
	"LOCK BASE  [L]", Color3.fromRGB(70, 130, 230))
local rebirthButton = makeButton(buttonStack, "RebirthButton", UDim2.fromOffset(0, 124), UDim2.fromOffset(190, 52),
	"REBIRTH", Color3.fromRGB(160, 80, 220))
local shopButton = makeButton(buttonStack, "ShopButton", UDim2.fromOffset(0, 186), UDim2.fromOffset(190, 52),
	"CATALOG + SHOP", Color3.fromRGB(60, 180, 120))

-- Catalog + upgrade shop panel, hidden until opened.
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.Size = UDim2.fromOffset(560, 480)
shopPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopPanel

local shopTitle = makeLabel(shopPanel, "ShopTitle", UDim2.fromOffset(16, 12), UDim2.fromOffset(528, 40),
	"WEIRDO CATALOG — buy them on the conveyor, place them on your base", 18, Color3.fromRGB(255, 255, 255))
shopTitle.BackgroundTransparency = 1

local catalogList = Instance.new("ScrollingFrame")
catalogList.Name = "CatalogList"
catalogList.Position = UDim2.fromOffset(16, 60)
catalogList.Size = UDim2.fromOffset(528, 250)
catalogList.BackgroundTransparency = 1
catalogList.ScrollBarThickness = 6
catalogList.CanvasSize = UDim2.fromOffset(0, #BrainrotCatalog.CHARACTERS * 46)
catalogList.Parent = shopPanel
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = catalogList

for _, entry in ipairs(BrainrotCatalog.CHARACTERS) do
	local rarity = BrainrotCatalog.RARITIES[entry.rarity]
	local row = Instance.new("Frame")
	row.Name = entry.id
	row.Size = UDim2.fromOffset(512, 42)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
	row.BorderSizePixel = 0
	row.Parent = catalogList
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(10, 0)
	nameLabel.Size = UDim2.fromOffset(230, 42)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = rarity.color
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.fromOffset(250, 0)
	rateLabel.Size = UDim2.fromOffset(120, 42)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = BrainrotCatalog.formatMoney(entry.rate) .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	rateLabel.TextSize = 18
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.Parent = row
	local costLabel = Instance.new("TextLabel")
	costLabel.Position = UDim2.fromOffset(380, 0)
	costLabel.Size = UDim2.fromOffset(120, 42)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = BrainrotCatalog.formatMoney(entry.cost)
	costLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	costLabel.TextSize = 18
	costLabel.Font = Enum.Font.SourceSansBold
	costLabel.Parent = row
end

local upgradesTitle = makeLabel(shopPanel, "UpgradesTitle", UDim2.fromOffset(16, 322), UDim2.fromOffset(528, 30),
	"UPGRADES — spend cash, keep them forever", 18, Color3.fromRGB(255, 255, 255))
upgradesTitle.BackgroundTransparency = 1

local upgradeButtons = {}
local upgradeY = 358
for id, upgrade in pairs(GameConfig.UPGRADES) do
	local button = makeButton(shopPanel, "Upgrade_" .. id, UDim2.fromOffset(16, upgradeY), UDim2.fromOffset(528, 34),
		upgrade.name .. " — " .. BrainrotCatalog.formatMoney(upgrade.cost) .. "  •  " .. upgrade.description,
		Color3.fromRGB(70, 120, 200))
	button.TextSize = 16
	button.MouseButton1Click:Connect(function()
		buyUpgradeRemote:FireServer(id)
	end)
	upgradeButtons[id] = button
	upgradeY += 40
end

-- Toasts: server messages slide in at the bottom and fade away.
local toastArea = Instance.new("Frame")
toastArea.Name = "ToastArea"
toastArea.AnchorPoint = Vector2.new(0.5, 1)
toastArea.Position = UDim2.new(0.5, 0, 1, -170)
toastArea.Size = UDim2.fromOffset(560, 120)
toastArea.BackgroundTransparency = 1
toastArea.Parent = gui

local function showToast(text: string)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(560, 34)
	toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toast.BackgroundTransparency = 0.15
	toast.BorderSizePixel = 0
	toast.Text = text
	toast.TextSize = 18
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Font = Enum.Font.SourceSansBold
	toast.Parent = toastArea
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	-- Stack: older toasts rise.
	for _, child in ipairs(toastArea:GetChildren()) do
		if child:IsA("TextLabel") and child ~= toast then
			child.Position = child.Position - UDim2.fromOffset(0, 38)
		end
	end
	task.delay(4, function()
		toast:Destroy()
	end)
end

notifyRemote.OnClientEvent:Connect(showToast)

-- Buttons and keys.
slapButton.MouseButton1Click:Connect(function()
	slapRemote:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	lockBaseRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)
shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		slapRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.L then
		lockBaseRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B then
		shopPanel.Visible = not shopPanel.Visible
	end
end)

-- Live numbers: cash, income and rebirths from leaderstats; wave from GameState.
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash") :: IntValue
local incomeValue = leaderstats:WaitForChild("Income") :: IntValue
local rebirthsValue = leaderstats:WaitForChild("Rebirths") :: IntValue
local waveCountdown = gameState:WaitForChild("WaveCountdown") :: IntValue
local waveState = gameState:WaitForChild("WaveState") :: StringValue

local function refreshMoney()
	cashLabel.Text = BrainrotCatalog.formatMoney(cashValue.Value)
	incomeLabel.Text = "+" .. BrainrotCatalog.formatMoney(incomeValue.Value) .. "/s"
	rebirthLabel.Text = "Rebirth " .. rebirthsValue.Value
	rebirthButton.Text = "REBIRTH — " .. BrainrotCatalog.formatMoney(GameConfig.REBIRTH_BASE_COST * (2 ^ rebirthsValue.Value))
end

local function refreshWave()
	local state = waveState.Value
	if state == "Warning" then
		waveBanner.Text = "NOODLE TSUNAMI IN " .. waveCountdown.Value .. "s — RUN HOME!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		waveBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif state == "Wave" then
		waveBanner.Text = "THE NOODLE TSUNAMI IS HERE — STAY ON YOUR BASE!"
		waveBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		waveBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		waveBanner.Text = "Noodle Tsunami in " .. waveCountdown.Value .. "s"
		waveBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		waveBanner.TextColor3 = Color3.fromRGB(140, 220, 255)
	end
end

local function refreshCarrying()
	local carrying = player:GetAttribute("Carrying")
	if typeof(carrying) == "string" and carrying ~= "" then
		carryLabel.Text = "Carrying: " .. carrying .. " — take it to YOUR base!"
		carryLabel.Visible = true
	else
		carryLabel.Visible = false
	end
end

cashValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
incomeValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
rebirthsValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
waveCountdown:GetPropertyChangedSignal("Value"):Connect(refreshWave)
waveState:GetPropertyChangedSignal("Value"):Connect(refreshWave)
player:GetAttributeChangedSignal("Carrying"):Connect(refreshCarrying)

refreshMoney()
refreshWave()
refreshCarrying()
showToast("Welcome to Brainrot Lagoon! Buy a weirdo on the conveyor!")
