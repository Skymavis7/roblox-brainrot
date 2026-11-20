-- WorldBuilder: hangs the signs at runtime, so the project file stays plain
-- parts. Each sign is a two-line BillboardGui on a part.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.GameConfig)

local WorldBuilder = {}

local function hangSign(part, title, subtitle, width, height, titleColor, lift)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = part
	gui.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.55, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = titleColor
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Text = title
	titleLabel.Parent = gui

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Size = UDim2.new(1, 0, 0.45, 0)
	subLabel.Position = UDim2.new(0, 0, 0.55, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.SourceSansBold
	subLabel.TextScaled = true
	subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subLabel.TextStrokeTransparency = 0.2
	subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	subLabel.Text = subtitle
	subLabel.Parent = gui
end

function WorldBuilder.build()
	local function signOn(partName, title, subtitle, width, height, color, lift)
		local part = Workspace:FindFirstChild(partName)
		if part then
			hangSign(part, title, subtitle, width, height, color, lift)
		end
	end

	signOn(
		"SpawnArchBeam",
		"BRAINROT LAGOON",
		"Catch the weirdos  •  Guard your base  •  Outrun the wave",
		520,
		110,
		Color3.fromRGB(255, 210, 60),
		0
	)
	signOn(
		"DockSign",
		"WEIRDO DOCK",
		"New brainrots walk in from the sea — buy one!",
		420,
		90,
		Color3.fromRGB(120, 220, 255),
		0
	)
	signOn(
		"MartSign",
		"WEIRDO MART",
		"See the full catalog in your HUD",
		420,
		90,
		Color3.fromRGB(255, 150, 210),
		0
	)
	signOn(
		"PortalSign",
		"REBIRTH PORTAL",
		"100k cash = +50% income forever",
		420,
		90,
		Color3.fromRGB(190, 130, 255),
		0
	)
	for index, base in ipairs(Config.BASES) do
		signOn(
			"BasePlate" .. index,
			"BASE " .. index,
			"Your brainrots earn here",
			300,
			70,
			base.color,
			3
		)
	end
end

return WorldBuilder
