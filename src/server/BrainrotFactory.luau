-- BrainrotFactory: builds the 3D model of one brainrot character from the catalog.
-- Every brainrot is a little creature of coloured parts with googly eyes, an accessory,
-- and a floating label showing its name, rarity and dollars per second.
-- The model is anchored and moved by the services that own it (conveyor, following, base).

local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local BrainrotFactory = {}

local BODY_SIZES = {
	Box = Vector3.new(3, 3, 3),
	Ball = Vector3.new(3, 3, 3),
	Cylinder = Vector3.new(3, 3, 3),
}

-- One googly eye: a white ball with a black pupil stuck on the front of the body.
local function buildEye(parent: Instance, offset: Vector3): Part
	local eye = Instance.new("Part")
	eye.Name = "Eye"
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(0.7, 0.7, 0.4)
	eye.Color = Color3.fromRGB(255, 255, 255)
	eye.Material = Enum.Material.SmoothPlastic
	eye.Anchored = true
	eye.CanCollide = false
	eye.Position = parent.Position + offset
	eye.Parent = parent.Parent

	local pupil = Instance.new("Part")
	pupil.Name = "Pupil"
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.32, 0.32, 0.2)
	pupil.Color = Color3.fromRGB(20, 20, 20)
	pupil.Material = Enum.Material.SmoothPlastic
	pupil.Anchored = true
	pupil.CanCollide = false
	pupil.Position = parent.Position + offset + Vector3.new(0, 0, -0.25)
	pupil.Parent = parent.Parent
	return eye
end

-- The accessory named in the catalog entry: a hat, crown, antenna or wheels.
local function buildAccessory(model: Model, body: Part, accessory: string, bodyColor: Color3)
	if accessory == "hat" then
		local hat = Instance.new("Part")
		hat.Name = "Hat"
		hat.Size = Vector3.new(3.4, 0.5, 3.4)
		hat.Color = Color3.fromRGB(40, 40, 60)
		hat.Material = Enum.Material.SmoothPlastic
		hat.Anchored = true
		hat.CanCollide = false
		hat.Position = body.Position + Vector3.new(0, 1.7, 0)
		hat.Parent = model
		local top = Instance.new("Part")
		top.Name = "HatTop"
		top.Size = Vector3.new(1.8, 1.2, 1.8)
		top.Color = Color3.fromRGB(40, 40, 60)
		top.Material = Enum.Material.SmoothPlastic
		top.Anchored = true
		top.CanCollide = false
		top.Position = body.Position + Vector3.new(0, 2.4, 0)
		top.Parent = model
	elseif accessory == "crown" then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(2.6, 0.9, 2.6)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Material = Enum.Material.Neon
		crown.Anchored = true
		crown.CanCollide = false
		crown.Position = body.Position + Vector3.new(0, 1.8, 0)
		crown.Parent = model
	elseif accessory == "antenna" then
		local stick = Instance.new("Part")
		stick.Name = "Antenna"
		stick.Size = Vector3.new(0.25, 1.6, 0.25)
		stick.Color = Color3.fromRGB(60, 60, 60)
		stick.Material = Enum.Material.SmoothPlastic
		stick.Anchored = true
		stick.CanCollide = false
		stick.Position = body.Position + Vector3.new(0, 2.2, 0)
		stick.Parent = model
		local ball = Instance.new("Part")
		ball.Name = "AntennaBall"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(0.7, 0.7, 0.7)
		ball.Color = Color3.fromRGB(255, 80, 80)
		ball.Material = Enum.Material.Neon
		ball.Anchored = true
		ball.CanCollide = false
		ball.Position = body.Position + Vector3.new(0, 3.1, 0)
		ball.Parent = model
	elseif accessory == "wheels" then
		for _, side in ipairs({ -1, 1 }) do
			for _, front in ipairs({ -1, 1 }) do
				local wheel = Instance.new("Part")
				wheel.Name = "Wheel"
				wheel.Shape = Enum.PartType.Cylinder
				wheel.Size = Vector3.new(0.5, 1, 1)
				wheel.Color = Color3.fromRGB(30, 30, 30)
				wheel.Material = Enum.Material.SmoothPlastic
				wheel.Anchored = true
				wheel.CanCollide = false
				wheel.CFrame = CFrame.new(body.Position + Vector3.new(side * 1.5, -1.2, front * 1.1))
					* CFrame.Angles(0, 0, math.rad(90))
				wheel.Parent = model
			end
		end
	end
end

-- The floating label above a brainrot: name, rarity and $/s, in the rarity colour.
local function buildLabel(model: Model, body: Part, entry, mutation, rate: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local rarityInfo = BrainrotCatalog.RARITIES[entry.rarity]
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.fromScale(0, 0.4)
	rarityLabel.Size = UDim2.fromScale(1, 0.3)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = entry.rarity .. "  •  " .. mutation.name
	rarityLabel.TextColor3 = rarityInfo.color
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.TextStrokeTransparency = 0.4
	rarityLabel.Parent = gui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.fromScale(0, 0.7)
	rateLabel.Size = UDim2.fromScale(1, 0.3)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = BrainrotCatalog.formatMoney(rate) .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.Parent = gui
end

-- Build the model for one catalog entry with one mutation, standing at `position`.
-- Returns the model; the caller owns where it goes next.
function BrainrotFactory.build(entry, mutation, position: Vector3): Model
	local rate = entry.rate * mutation.multiplier

	local model = Instance.new("Model")
	model.Name = entry.name

	local body = Instance.new("Part")
	body.Name = "Body"
	if entry.shape == "Ball" then
		body.Shape = Enum.PartType.Ball
	elseif entry.shape == "Cylinder" then
		body.Shape = Enum.PartType.Cylinder
	else
		body.Shape = Enum.PartType.Block
	end
	body.Size = BODY_SIZES[entry.shape] or BODY_SIZES.Box
	body.Color = entry.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Position = position + Vector3.new(0, 1.6, 0)
	body.Parent = model
	model.PrimaryPart = body

	-- A mutation tints the body: Golden glows, Frozen turns icy, Rainbow spins hues.
	if mutation.name == "Golden" then
		body.Material = Enum.Material.Neon
		body.Color = Color3.fromRGB(255, 215, 0)
	elseif mutation.name == "Frozen" then
		body.Material = Enum.Material.Glass
		body.Transparency = 0.25
	elseif mutation.name == "Rainbow" then
		body.Material = Enum.Material.Neon
	end

	buildEye(body, Vector3.new(-0.7, 0.4, -1.5))
	buildEye(body, Vector3.new(0.7, 0.4, -1.5))

	-- Little feet so it looks like it walks.
	for _, side in ipairs({ -1, 1 }) do
		local foot = Instance.new("Part")
		foot.Name = "Foot"
		foot.Size = Vector3.new(0.8, 0.5, 1.2)
		foot.Color = Color3.fromRGB(40, 40, 40)
		foot.Material = Enum.Material.SmoothPlastic
		foot.Anchored = true
		foot.CanCollide = false
		foot.Position = body.Position + Vector3.new(side * 0.7, -1.6, 0)
		foot.Parent = model
	end

	buildAccessory(model, body, entry.accessory, entry.color)
	buildLabel(model, body, entry, mutation, rate)

	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Cost", entry.cost)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Rarity", entry.rarity)
	model:SetAttribute("State", "Walking")

	return model
end

return BrainrotFactory
