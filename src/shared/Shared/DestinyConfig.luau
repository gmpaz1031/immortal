--!strict
--[[
    DestinyConfig.luau
    Defines all Talents and Spiritual Roots with their multipliers,
    exact percentage chances, tier rankings, and visual themes.
    Strictly English text without unicode emojis.
]]

export type TalentEntry = {
	Id: number,
	Name: string,
	Multiplier: number,
	Chance: number,       -- Percentage e.g. 25.0 for 25%
	Weight: number,       -- Normalized weight
	Color: Color3,
	TierName: string,
	Description: string,
}

export type RootEntry = {
	Id: number,
	Name: string,
	Multiplier: number,
	Chance: number,       -- Percentage e.g. 22.0 for 22%
	Weight: number,
	Color: Color3,
	TierName: string,
	Description: string,
}

local DestinyConfig = {}

DestinyConfig.SPIN_COST = 50 -- Gold per spin after initial free spin

DestinyConfig.TALENTS = {
	{
		Id = 1,
		Name = "Mortal",
		Multiplier = 1.0,
		Chance = 25.00,
		Weight = 2500,
		Color = Color3.fromRGB(165, 172, 185),
		TierName = "Common",
		Description = "An ordinary mortal vessel. Gathers worldly Qi at normal speed.",
	},
	{
		Id = 2,
		Name = "Adept",
		Multiplier = 1.1,
		Chance = 18.00,
		Weight = 1800,
		Color = Color3.fromRGB(120, 200, 130),
		TierName = "Uncommon",
		Description = "Cleansed meridians allow slightly faster spiritual circulation.",
	},
	{
		Id = 3,
		Name = "Gifted",
		Multiplier = 1.25,
		Chance = 13.00,
		Weight = 1300,
		Color = Color3.fromRGB(80, 210, 140),
		TierName = "Superior",
		Description = "Naturally receptive to ambient spiritual qi and dao rhythms.",
	},
	{
		Id = 4,
		Name = "Genius",
		Multiplier = 1.5,
		Chance = 10.00,
		Weight = 1000,
		Color = Color3.fromRGB(70, 170, 255),
		TierName = "Rare",
		Description = "A rare cultivation intellect capable of rapid comprehension.",
	},
	{
		Id = 5,
		Name = "Earthly Genius",
		Multiplier = 1.75,
		Chance = 7.50,
		Weight = 750,
		Color = Color3.fromRGB(50, 130, 240),
		TierName = "Exquisite",
		Description = "Blessed by terrestrial veins with strong spiritual affinity.",
	},
	{
		Id = 6,
		Name = "Heavenly Genius",
		Multiplier = 2.0,
		Chance = 6.00,
		Weight = 600,
		Color = Color3.fromRGB(160, 100, 250),
		TierName = "Grand",
		Description = "Favored by celestial skies. Meridians open wide for heavy Qi absorption.",
	},
	{
		Id = 7,
		Name = "Profound Genius",
		Multiplier = 2.5,
		Chance = 5.00,
		Weight = 500,
		Color = Color3.fromRGB(200, 80, 230),
		TierName = "Mystic",
		Description = "Profound enlightenment flows naturally into inner core cultivation.",
	},
	{
		Id = 8,
		Name = "Peerless Genius",
		Multiplier = 3.0,
		Chance = 4.00,
		Weight = 400,
		Color = Color3.fromRGB(240, 70, 120),
		TierName = "Peerless",
		Description = "Standing uncontested among peers in all martial territories.",
	},
	{
		Id = 9,
		Name = "Saintly Talent",
		Multiplier = 4.0,
		Chance = 3.00,
		Weight = 300,
		Color = Color3.fromRGB(250, 160, 40),
		TierName = "Saint",
		Description = "Radiates holy resonance that purifies and amplifies every breath of Qi.",
	},
	{
		Id = 10,
		Name = "Immortal Talent",
		Multiplier = 5.0,
		Chance = 2.50,
		Weight = 250,
		Color = Color3.fromRGB(255, 215, 50),
		TierName = "Immortal",
		Description = "Immortal heritage awakened. Worldly limits begin to dissolve.",
	},
	{
		Id = 11,
		Name = "Ancient Prodigy",
		Multiplier = 6.5,
		Chance = 1.80,
		Weight = 180,
		Color = Color3.fromRGB(30, 235, 235),
		TierName = "Ancient",
		Description = "Born with primeval vitality remembered from ancient eons.",
	},
	{
		Id = 12,
		Name = "Heaven's Chosen",
		Multiplier = 8.0,
		Chance = 1.20,
		Weight = 120,
		Color = Color3.fromRGB(255, 110, 210),
		TierName = "Celestial",
		Description = "Chosen by celestial destiny; fortune and boundless Qi follow.",
	},
	{
		Id = 13,
		Name = "Dao Prodigy",
		Multiplier = 10.0,
		Chance = 0.80,
		Weight = 80,
		Color = Color3.fromRGB(255, 80, 60),
		TierName = "Dao Paragon",
		Description = "Walks hand-in-hand with cosmic laws, condensing Qi at transcendent speeds.",
	},
	{
		Id = 14,
		Name = "Heavenly Dao Talent",
		Multiplier = 15.0,
		Chance = 0.15,
		Weight = 15,
		Color = Color3.fromRGB(230, 215, 255),
		TierName = "Heavenly Dao",
		Description = "Direct embodiment of the Heavenly Dao. Commands spiritual energy at will.",
	},
	{
		Id = 15,
		Name = "Heaven-Defying Talent",
		Multiplier = 25.0,
		Chance = 0.05,
		Weight = 5,
		Color = Color3.fromRGB(255, 45, 85),
		TierName = "Supreme Chaos",
		Description = "Defies destiny itself. Infinite cultivation potential unmatched in the universe.",
	},
}

DestinyConfig.SPIRITUAL_ROOTS = {
	{
		Id = 1,
		Name = "Metal Root",
		Multiplier = 1.5,
		Chance = 22.00,
		Weight = 2200,
		Color = Color3.fromRGB(220, 225, 235),
		TierName = "Elemental",
		Description = "Unyielding metallic essence that sharpens cultivation and spirit.",
	},
	{
		Id = 2,
		Name = "Wood Root",
		Multiplier = 1.5,
		Chance = 18.00,
		Weight = 1800,
		Color = Color3.fromRGB(65, 215, 95),
		TierName = "Elemental",
		Description = "Verdant life energy providing boundless vitality and continuous recovery.",
	},
	{
		Id = 3,
		Name = "Water Root",
		Multiplier = 1.5,
		Chance = 18.00,
		Weight = 1800,
		Color = Color3.fromRGB(40, 150, 255),
		TierName = "Elemental",
		Description = "Fluid adaptive flow nourishing meridians like deep mountain rivers.",
	},
	{
		Id = 4,
		Name = "Fire Root",
		Multiplier = 1.5,
		Chance = 18.00,
		Weight = 1800,
		Color = Color3.fromRGB(255, 85, 45),
		TierName = "Elemental",
		Description = "Blazing passion that tempers raw Qi into potent spiritual flame.",
	},
	{
		Id = 5,
		Name = "Earth Root",
		Multiplier = 1.5,
		Chance = 15.00,
		Weight = 1500,
		Color = Color3.fromRGB(185, 145, 100),
		TierName = "Elemental",
		Description = "Unyielding mountain foundation granting steadfast grounding and endurance.",
	},
	{
		Id = 6,
		Name = "Lightning Root",
		Multiplier = 2.0,
		Chance = 5.00,
		Weight = 500,
		Color = Color3.fromRGB(190, 95, 255),
		TierName = "Variant",
		Description = "Thunder tribulation essence that empowers explosive bursts of Qi.",
	},
	{
		Id = 7,
		Ice = 7,
		Name = "Ice Root",
		Multiplier = 2.0,
		Chance = 2.50,
		Weight = 250,
		Color = Color3.fromRGB(90, 225, 255),
		TierName = "Variant",
		Description = "Absolute glacial cold that crystalizes spiritual clarity and focus.",
	},
	{
		Id = 8,
		Name = "Space Root",
		Multiplier = 3.0,
		Chance = 1.00,
		Weight = 100,
		Color = Color3.fromRGB(105, 100, 245),
		TierName = "Supreme",
		Description = "Commands dimensional currents, drawing spiritual Qi from across the void.",
	},
	{
		Id = 9,
		Name = "Chaos Root",
		Multiplier = 5.0,
		Chance = 0.50,
		Weight = 50,
		Color = Color3.fromRGB(255, 215, 60),
		TierName = "Primordial",
		Description = "The undivided origin of all elements. Supreme cosmic enlightenment.",
	},
}

-- Fast lookup maps
local talentMap: { [string]: TalentEntry } = {}
for _, item in ipairs(DestinyConfig.TALENTS) do
	talentMap[item.Name] = item
end

local rootMap: { [string]: RootEntry } = {}
for _, item in ipairs(DestinyConfig.SPIRITUAL_ROOTS) do
	rootMap[item.Name] = item
end

function DestinyConfig.GetTalent(name: string?): TalentEntry
	if name and talentMap[name] then
		return talentMap[name]
	end
	return DestinyConfig.TALENTS[1] -- Default Mortal
end

function DestinyConfig.GetSpiritualRoot(name: string?): RootEntry?
	if name and rootMap[name] then
		return rootMap[name]
	end
	return nil
end

function DestinyConfig.GetTalentMultiplier(name: string?): number
	local entry = DestinyConfig.GetTalent(name)
	return entry.Multiplier
end

function DestinyConfig.GetRootMultiplier(name: string?): number
	local entry = DestinyConfig.GetSpiritualRoot(name)
	return entry and entry.Multiplier or 1.0
end

-- Server roll using exact weights
function DestinyConfig.RollTalent(): (TalentEntry, number)
	local totalWeight = 10000 -- 100% * 100
	local roll = math.random(1, totalWeight)
	local running = 0
	for idx, talent in ipairs(DestinyConfig.TALENTS) do
		running = running + talent.Weight
		if roll <= running then
			return talent, idx
		end
	end
	return DestinyConfig.TALENTS[1], 1
end

function DestinyConfig.RollSpiritualRoot(): (RootEntry, number)
	local totalWeight = 10000 -- 100% * 100
	local roll = math.random(1, totalWeight)
	local running = 0
	for idx, root in ipairs(DestinyConfig.SPIRITUAL_ROOTS) do
		running = running + root.Weight
		if roll <= running then
			return root, idx
		end
	end
	return DestinyConfig.SPIRITUAL_ROOTS[1], 1
end

return DestinyConfig
