-- WorldBuilder: hang the floating signs at runtime, so the project file
-- stays plain parts. Each sign is a BillboardGui on an existing part.

local WorldBuilder = {}

local function hangSign(partName, title, subtitle, width, height, titleColor, lift)
	local part = workspace:FindFirstChild(partName)
	if not part then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.55, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextScaled = true
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.Parent = gui

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Position = UDim2.new(0, 0, 0.55, 0)
	subtitleLabel.Size = UDim2.new(1, 0, 0.45, 0)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = subtitle
	subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subtitleLabel.Font = Enum.Font.SourceSansBold
	subtitleLabel.TextScaled = true
	subtitleLabel.Parent = gui
end

function WorldBuilder.build()
	hangSign("SpawnArchBeam", "BRAINROT LAGOON", "Catch the weirdos  •  Guard your base  •  Outrun the wave", 520, 110, Color3.fromRGB(255, 210, 60), 4)
	hangSign("DockSign", "WEIRDO DOCK", "New brainrots walk in from the sea — buy one!", 420, 90, Color3.fromRGB(120, 220, 255), 4)
	hangSign("MartSign", "WEIRDO MART", "See the full catalog in your HUD", 420, 90, Color3.fromRGB(255, 150, 210), 4)
	hangSign("PortalSign", "REBIRTH PORTAL", "100k cash = +50% income forever", 420, 90, Color3.fromRGB(190, 130, 255), 4)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	for index = 1, 6 do
		local base = GameConfig.BASES[index]
		hangSign("BasePlate" .. index, "BASE " .. index, "Your brainrots earn here", 300, 70, base.color, 3)
	end
end

return WorldBuilder
