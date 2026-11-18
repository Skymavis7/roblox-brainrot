-- WorldBuilder: the signs and labels that hang over the 3D world.
-- Built at runtime (so the project file stays plain parts): a big title sign over the
-- spawn arch, the dock sign, the shop sign, the rebirth portal sign, and one coloured
-- number plate over each base. BillboardGuis always face the camera.

local Workspace = game:GetService("Workspace")

local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))

local WorldBuilder = {}

local function makeSign(parent: Instance, text: string, subtext: string, size: Vector3, color: Color3, offsetY: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "WorldSign"
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent

	local title = Instance.new("TextLabel")
	title.Name = "SignTitle"
	title.Size = UDim2.fromScale(1, 0.6)
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextColor3 = color
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextStrokeTransparency = 0.2
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "SignSub"
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Size = UDim2.fromScale(1, 0.4)
	sub.BackgroundTransparency = 1
	sub.Text = subtext
	sub.TextColor3 = Color3.fromRGB(255, 255, 255)
	sub.TextScaled = true
	sub.Font = Enum.Font.SourceSansBold
	sub.TextStrokeTransparency = 0.2
	sub.Parent = gui
	return gui
end

-- Hang every sign once the world exists.
function WorldBuilder.build()
	local arch = Workspace:FindFirstChild("SpawnArchBeam")
	if arch ~= nil then
		makeSign(arch, "BRAINROT LAGOON", "Catch the weirdos  •  Guard your base  •  Outrun the wave",
			Vector3.new(520, 110, 0), Color3.fromRGB(255, 210, 60), 0)
	end
	local dock = Workspace:FindFirstChild("DockSign")
	if dock ~= nil then
		makeSign(dock, "WEIRDO DOCK", "New brainrots walk in from the sea — buy one!",
			Vector3.new(420, 90, 0), Color3.fromRGB(120, 220, 255), 0)
	end
	local mart = Workspace:FindFirstChild("MartSign")
	if mart ~= nil then
		makeSign(mart, "WEIRDO MART", "See the full catalog in your HUD",
			Vector3.new(420, 90, 0), Color3.fromRGB(255, 150, 210), 0)
	end
	local portal = Workspace:FindFirstChild("PortalSign")
	if portal ~= nil then
		makeSign(portal, "REBIRTH PORTAL", "100k cash = +50% income forever",
			Vector3.new(420, 90, 0), Color3.fromRGB(190, 130, 255), 0)
	end
	-- One number plate per base, in that base's colour.
	for index, base in ipairs(GameConfig.BASES) do
		local plate = Workspace:FindFirstChild("BasePlate" .. index)
		if plate ~= nil then
			makeSign(plate, "BASE " .. index, "Your brainrots earn here",
				Vector3.new(300, 70, 0), base.color, 3)
		end
	end
end

return WorldBuilder
