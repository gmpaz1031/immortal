--!strict
-- src/shared/OreConfig.luau
-- Configuration for 5 Mineable Ore Deposits in Immortal Xianxia RPG

export type OreDefinition = {
	Id: string,
	Name: string,
	TierName: string,
	HitsRequired: number,
	RespawnTime: number,
	DropsItem: string,
	DropMinQty: number,
	DropMaxQty: number,
	QiReward: number?,
	Description: string,
	HitSoundId: string,
	BreakSoundId: string,
	ParticleColor: ColorSequence,
	RockColor: Color3,
	MineralColor: Color3,
}

local OreConfig = {}

OreConfig.Ores = {
	["Iron Ore"] = {
		Id = "Iron Ore",
		Name = "Iron Ore",
		TierName = "Common",
		HitsRequired = 3,
		RespawnTime = 4,
		DropsItem = "Iron Ore",
		DropMinQty = 1,
		DropMaxQty = 2,
		QiReward = 0,
		Description = "Rough weathered stone with raw metallic iron veins and oxidized rust patches.",
		HitSoundId = "rbxassetid://9114223171", -- Realistic pickaxe stone strike
		BreakSoundId = "rbxassetid://9114223789", -- Rock fracture shatter
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 110, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 75, 45)),
		}),
		RockColor = Color3.fromRGB(75, 68, 62),
		MineralColor = Color3.fromRGB(180, 115, 65),
	},
	["Steel Ore"] = {
		Id = "Steel Ore",
		Name = "Steel Ore",
		TierName = "Refined Mortal",
		HitsRequired = 5,
		RespawnTime = 5,
		DropsItem = "Steel Ore",
		DropMinQty = 1,
		DropMaxQty = 2,
		QiReward = 5,
		Description = "Dense dark basalt rock with polished bright silver metallic veins and sharp fracture planes.",
		HitSoundId = "rbxassetid://9114223171",
		BreakSoundId = "rbxassetid://9114223789",
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 225, 230)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 125, 135)),
		}),
		RockColor = Color3.fromRGB(48, 52, 56),
		MineralColor = Color3.fromRGB(215, 220, 225),
	},
	["Spirit Stone"] = {
		Id = "Spirit Stone",
		Name = "Spirit Stone",
		TierName = "Spiritual Qi",
		HitsRequired = 6,
		RespawnTime = 6,
		DropsItem = "Spirit Stone",
		DropMinQty = 1,
		DropMaxQty = 2,
		QiReward = 25,
		Description = "Naturally glowing translucent cyan crystals embedded in cavern bedrock, radiating celestial spiritual Qi.",
		HitSoundId = "rbxassetid://9114223171",
		BreakSoundId = "rbxassetid://9114223789",
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 245, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 220)),
		}),
		RockColor = Color3.fromRGB(36, 42, 48),
		MineralColor = Color3.fromRGB(90, 235, 255),
	},
	["Jade Crystal"] = {
		Id = "Jade Crystal",
		Name = "Jade Crystal",
		TierName = "Rare Earth",
		HitsRequired = 7,
		RespawnTime = 7,
		DropsItem = "Jade Crystal",
		DropMinQty = 1,
		DropMaxQty = 1,
		QiReward = 15,
		Description = "Smooth emerald-green crystalline fingers growing from cavern rock, semi-translucent with oily mineral luster.",
		HitSoundId = "rbxassetid://9114223171",
		BreakSoundId = "rbxassetid://9114223789",
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 230, 130)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 150, 75)),
		}),
		RockColor = Color3.fromRGB(45, 48, 44),
		MineralColor = Color3.fromRGB(50, 215, 120),
	},
	["Black Iron"] = {
		Id = "Black Iron",
		Name = "Black Iron",
		TierName = "Deep Abyss",
		HitsRequired = 8,
		RespawnTime = 8,
		DropsItem = "Black Iron",
		DropMinQty = 1,
		DropMaxQty = 1,
		QiReward = 10,
		Description = "Extremely dense, pitch-black volcanic rock with gunmetal-gray reflective metallic seams.",
		HitSoundId = "rbxassetid://9114223171",
		BreakSoundId = "rbxassetid://9114223789",
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 145, 155)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 50)),
		}),
		RockColor = Color3.fromRGB(22, 23, 26),
		MineralColor = Color3.fromRGB(95, 100, 110),
	},
} :: { [string]: OreDefinition }

function OreConfig.GetOre(name: string): OreDefinition?
	return OreConfig.Ores[name]
end

return OreConfig
