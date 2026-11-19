-- BrainrotFactory — builds the 3D model of one brainrot from the catalog.
-- Each one is a little creature of coloured parts: a body with googly eyes and
-- little feet, the accessory its entry names, and a floating label showing its
-- name, rarity and dollars per second. The model is anchored; the services
-- that own it (conveyor, following, base) move it around.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local BrainrotFactory = {}

-- Every body shape is a 3-stud cube, ball or cylinder.
local BODY_SIZE = {
	Box = Vector3.new(3, 3, 3),
	Ball = Vector3.new(3, 3, 3),
	Cylinder = Vector3.new(3, 3, 3),
}

local function newPart(name: string, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- One googly eye: a white ball with a black pupil, stuck on the body's front.
local function addEye(model: Model, body: Part, offset: Vector3)
	local eye = newPart("Eye", model)
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(0.7, 0.7, 0.4)
	eye.Color = Color3.fromRGB(255, 255, 255)
	eye.Position = body.Position + offset

	local pupil = newPart("Pupil", model)
	pupil.Shape = Enum.PartType.Ball
	pupil.Size = Vector3.new(0.32, 0.32, 0.2)
	pupil.Color = Color3.fromRGB(20, 20, 20)
	pupil.Position = body.Position + offset + Vector3.new(0, 0, -0.25)
end

-- The accessory named in the catalog entry: hat, crown, antenna or wheels.
local function addAccessory(model: Model, body: Part, kind: string)
	local top = body.Position
	if kind == "hat" then
		local brim = newPart("Hat", model)
		brim.Size = Vector3.new(3.4, 0.5, 3.4)
		brim.Color = Color3.fromRGB(40, 40, 60)
		brim.Position = top + Vector3.new(0, 1.7, 0)
		local crown = newPart("HatTop", model)
		crown.Size = Vector3.new(1.8, 1.2, 1.8)
		crown.Color = Color3.fromRGB(40, 40, 60)
		crown.Position = top + Vector3.new(0, 2.4, 0)
	elseif kind == "crown" then
		local band = newPart("Crown", model)
		band.Size = Vector3.new(2.6, 0.9, 2.6)
		band.Color = Color3.fromRGB(255, 215, 0)
		band.Material = Enum.Material.Neon
		band.Position = top + Vector3.new(0, 1.8, 0)
	elseif kind == "antenna" then
		local stick = newPart("Antenna", model)
		stick.Size = Vector3.new(0.25, 1.6, 0.25)
		stick.Color = Color3.fromRGB(60, 60, 60)
		stick.Position = top + Vector3.new(0, 2.2, 0)
		local tip = newPart("AntennaBall", model)
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(0.7, 0.7, 0.7)
		tip.Color = Color3.fromRGB(255, 80, 80)
		tip.Material = Enum.Material.Neon
		tip.Position = top + Vector3.new(0, 3.1, 0)
	elseif kind == "wheels" then
		for _, side in ipairs({ -1, 1 }) do
			for _, front in ipairs({ -1, 1 }) do
				local wheel = newPart("Wheel", model)
				wheel.Shape = Enum.PartType.Cylinder
				wheel.Size = Vector3.new(0.5, 1, 1)
				wheel.Color = Color3.fromRGB(30, 30, 30)
				wheel.CFrame = CFrame.new(top + Vector3.new(side * 1.5, -1.2, front * 1.1))
					* CFrame.Angles(0, 0, math.rad(90))
			end
		end
	end
end

-- The floating label above a brainrot: name, rarity with mutation, and $/s,
-- the rarity line in the rarity's colour.
local function addLabel(model: Model, body: Part, entry, mutation, rate: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(140, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body

	local function line(name: string, y: number, height: number, text: string, color: Color3, font: Enum.Font)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Position = UDim2.fromScale(0, y)
		label.Size = UDim2.fromScale(1, height)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		label.TextScaled = true
		label.Font = font
		label.TextStrokeTransparency = 0.4
		label.Parent = gui
	end

	local rarityInfo = BrainrotCatalog.RARITIES[entry.rarity]
	line("NameLabel", 0, 0.4, entry.name, Color3.fromRGB(255, 255, 255), Enum.Font.FredokaOne)
	line("RarityLabel", 0.4, 0.3, entry.rarity .. "  •  " .. mutation.name, rarityInfo.color, Enum.Font.SourceSansBold)
	line("RateLabel", 0.7, 0.3, BrainrotCatalog.formatMoney(rate) .. "/s", Color3.fromRGB(120, 255, 130), Enum.Font.SourceSansBold)
end

-- Build the model for one catalog entry with one mutation, standing at `at`.
-- The caller owns where it goes next.
function BrainrotFactory.build(entry, mutation, at: Vector3): Model
	local rate = entry.rate * mutation.multiplier

	local model = Instance.new("Model")
	model.Name = entry.name

	local body = newPart("Body", model)
	if entry.shape == "Ball" then
		body.Shape = Enum.PartType.Ball
	elseif entry.shape == "Cylinder" then
		body.Shape = Enum.PartType.Cylinder
	else
		body.Shape = Enum.PartType.Block
	end
	body.Size = BODY_SIZE[entry.shape] or BODY_SIZE.Box
	body.Color = entry.color
	body.Position = at + Vector3.new(0, 1.6, 0)
	model.PrimaryPart = body

	-- A mutation re-skins the body: Golden glows, Frozen turns to glass,
	-- Rainbow glows too (its colour comes from the label).
	if mutation.name == "Golden" then
		body.Material = Enum.Material.Neon
		body.Color = Color3.fromRGB(255, 215, 0)
	elseif mutation.name == "Frozen" then
		body.Material = Enum.Material.Glass
		body.Transparency = 0.25
	elseif mutation.name == "Rainbow" then
		body.Material = Enum.Material.Neon
	end

	addEye(model, body, Vector3.new(-0.7, 0.4, -1.5))
	addEye(model, body, Vector3.new(0.7, 0.4, -1.5))

	-- Little feet so it looks like it walks.
	for _, side in ipairs({ -1, 1 }) do
		local foot = newPart("Foot", model)
		foot.Size = Vector3.new(0.8, 0.5, 1.2)
		foot.Color = Color3.fromRGB(40, 40, 40)
		foot.Position = body.Position + Vector3.new(side * 0.7, -1.6, 0)
	end

	addAccessory(model, body, entry.accessory)
	addLabel(model, body, entry, mutation, rate)

	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Cost", entry.cost)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Rarity", entry.rarity)
	model:SetAttribute("State", "Walking")

	return model
end

return BrainrotFactory
