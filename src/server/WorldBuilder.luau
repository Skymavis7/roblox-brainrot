-- WorldBuilder — the signs and labels that hang over the 3D world.
-- Built at runtime (so the project file stays plain parts): a big title sign
-- over the spawn arch, the dock sign, the shop sign, the rebirth portal sign,
-- and one coloured number plate over each base. BillboardGuis always face the
-- camera, so every sign reads from anywhere on the island.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WorldBuilder = {}

-- One two-line sign pinned to a part: a big coloured title over a white subtitle.
local function hangSign(anchor: Instance, title: string, subtitle: string, width: number, height: number, titleColor: Color3, lift: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "WorldSign"
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	gui.AlwaysOnTop = false
	gui.Parent = anchor

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "SignTitle"
	titleLabel.Size = UDim2.fromScale(1, 0.6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.Parent = gui

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SignSub"
	subLabel.Position = UDim2.fromScale(0, 0.6)
	subLabel.Size = UDim2.fromScale(1, 0.4)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = subtitle
	subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.SourceSansBold
	subLabel.TextStrokeTransparency = 0.2
	subLabel.Parent = gui
	return gui
end

-- Hang every sign once the world exists. A missing anchor is skipped, never an error.
function WorldBuilder.build()
	local arch = Workspace:FindFirstChild("SpawnArchBeam")
	if arch ~= nil then
		hangSign(arch, "BRAINROT LAGOON", "Catch the weirdos  •  Guard your base  •  Outrun the wave",
			520, 110, Color3.fromRGB(255, 210, 60), 0)
	end
	local dock = Workspace:FindFirstChild("DockSign")
	if dock ~= nil then
		hangSign(dock, "WEIRDO DOCK", "New brainrots walk in from the sea — buy one!",
			420, 90, Color3.fromRGB(120, 220, 255), 0)
	end
	local mart = Workspace:FindFirstChild("MartSign")
	if mart ~= nil then
		hangSign(mart, "WEIRDO MART", "See the full catalog in your HUD",
			420, 90, Color3.fromRGB(255, 150, 210), 0)
	end
	local portal = Workspace:FindFirstChild("PortalSign")
	if portal ~= nil then
		hangSign(portal, "REBIRTH PORTAL", "100k cash = +50% income forever",
			420, 90, Color3.fromRGB(190, 130, 255), 0)
	end
	-- One number plate per base, in that base's colour, floating above it.
	for index, plot in ipairs(GameConfig.BASES) do
		local plate = Workspace:FindFirstChild("BasePlate" .. index)
		if plate ~= nil then
			hangSign(plate, "BASE " .. index, "Your brainrots earn here",
				300, 70, plot.color, 3)
		end
	end
end

return WorldBuilder
