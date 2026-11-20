-- BrainrotFactory: builds the 3D model of one brainrot from a catalog entry
-- and a mutation, standing at a position.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)

local BrainrotFactory = {}

local function makePart(name, size, color, position, shape, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Position = position
	part.Shape = shape or Enum.PartType.Block
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	return part
end

local function rarityColor(rarityName)
	for _, rarity in ipairs(Catalog.RARITIES) do
		if rarity.name == rarityName then
			return rarity.color
		end
	end
	return Color3.fromRGB(255, 255, 255)
end

-- entry: a catalog character; mutation: a mutation row; at: ground position.
function BrainrotFactory.build(entry, mutation, at)
	local rate = entry.rate * mutation.multiplier
	local model = Instance.new("Model")
	model.Name = entry.name

	local bodyPos = at + Vector3.new(0, 1.6, 0)
	local bodyShape = Enum.PartType.Block
	if entry.shape == "Ball" then
		bodyShape = Enum.PartType.Ball
	elseif entry.shape == "Cylinder" then
		bodyShape = Enum.PartType.Cylinder
	end
	local body = makePart("Body", Vector3.new(3, 3, 3), entry.color, bodyPos, bodyShape)
	model.PrimaryPart = body
	body.Parent = model

	-- Mutation re-skins the body.
	if mutation.name == "Golden" then
		body.Material = Enum.Material.Neon
		body.Color = Color3.fromRGB(255, 215, 0)
	elseif mutation.name == "Frozen" then
		body.Material = Enum.Material.Glass
		body.Transparency = 0.25
	elseif mutation.name == "Rainbow" then
		body.Material = Enum.Material.Neon
	end

	-- Googly eyes on the front (-Z) face.
	for _, side in ipairs({ -0.7, 0.7 }) do
		local white = makePart(
			"EyeWhite",
			Vector3.new(0.7, 0.7, 0.4),
			Color3.fromRGB(255, 255, 255),
			bodyPos + Vector3.new(side, 0.4, -1.5),
			Enum.PartType.Ball
		)
		white.Parent = model
		local pupil = makePart(
			"Pupil",
			Vector3.new(0.32, 0.32, 0.2),
			Color3.fromRGB(20, 20, 25),
			bodyPos + Vector3.new(side, 0.4, -1.75),
			Enum.PartType.Ball
		)
		pupil.Parent = model
	end

	-- Little dark feet.
	for _, side in ipairs({ -0.7, 0.7 }) do
		local foot = makePart(
			"Foot",
			Vector3.new(0.8, 0.5, 1.2),
			Color3.fromRGB(40, 40, 45),
			bodyPos + Vector3.new(side, -1.6, 0)
		)
		foot.Parent = model
	end

	-- Accessory. "top" here is the body centre; offsets stack above the head.
	local top = bodyPos
	if entry.accessory == "hat" then
		local brim = makePart("HatBrim", Vector3.new(3.4, 0.5, 3.4), Color3.fromRGB(40, 40, 45), top + Vector3.new(0, 1.7, 0))
		brim.Parent = model
		local crown = makePart("HatTop", Vector3.new(1.8, 1.2, 1.8), Color3.fromRGB(40, 40, 45), top + Vector3.new(0, 2.4, 0))
		crown.Parent = model
	elseif entry.accessory == "crown" then
		local band = makePart(
			"Crown",
			Vector3.new(2.6, 0.9, 2.6),
			Color3.fromRGB(255, 215, 0),
			top + Vector3.new(0, 1.8, 0),
			Enum.PartType.Block,
			Enum.Material.Neon
		)
		band.Parent = model
	elseif entry.accessory == "antenna" then
		local stick = makePart("Antenna", Vector3.new(0.25, 1.6, 0.25), Color3.fromRGB(40, 40, 45), top + Vector3.new(0, 2.2, 0))
		stick.Parent = model
		local bulb = makePart(
			"AntennaBulb",
			Vector3.new(0.7, 0.7, 0.7),
			Color3.fromRGB(255, 60, 60),
			top + Vector3.new(0, 3.1, 0),
			Enum.PartType.Ball,
			Enum.Material.Neon
		)
		bulb.Parent = model
	elseif entry.accessory == "wheels" then
		for _, sx in ipairs({ -1.5, 1.5 }) do
			for _, sz in ipairs({ -1.1, 1.1 }) do
				local wheel = makePart(
					"Wheel",
					Vector3.new(0.5, 1, 1),
					Color3.fromRGB(40, 40, 45),
					top + Vector3.new(sx, -1.2, sz),
					Enum.PartType.Cylinder
				)
				wheel.Orientation = Vector3.new(0, 0, 90)
				wheel.Parent = model
			end
		end
	end

	-- Name plate floating above the head.
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	gui.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = entry.name
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.TextScaled = true
	rarityLabel.TextColor3 = rarityColor(entry.rarity)
	rarityLabel.Text = entry.rarity .. "  •  " .. mutation.name
	rarityLabel.Parent = gui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.7, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextScaled = true
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 130)
	rateLabel.Text = Catalog.formatMoney(rate) .. "/s"
	rateLabel.Parent = gui

	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Cost", entry.cost)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Rarity", entry.rarity)
	model:SetAttribute("State", "Walking")

	return model
end

return BrainrotFactory
