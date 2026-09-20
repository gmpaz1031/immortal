--!strict
-- src/shared/PlantConfig.luau
-- Centralized Modular Configuration for Harvestable Plants in Immortal RPG

export type PlantDef = {
	Id: string,
	Name: string,
	InventoryItem: string,
	InventoryCategory: string,
	RespawnTime: number, -- Default 3 seconds
	RespawnRadius: number, -- Default 9 studs
	Rarity: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary",
	Description: string,
	SellValue: number,
	PromptHoldDuration: number,
	PrimaryColor: Color3,
	SecondaryColor: Color3?,
	IsWaterPlant: boolean?,
}

local PlantConfig = {}

PlantConfig.DEFAULT_RESPAWN_TIME = 3
PlantConfig.DEFAULT_RESPAWN_RADIUS = 9
PlantConfig.DEFAULT_INVENTORY_CATEGORY = "Miscs"

PlantConfig.Plants = {
	["Spirit Grass"] = {
		Id = "Spirit Grass",
		Name = "Spirit Grass",
		InventoryItem = "Spirit Grass",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Common",
		Description = "Wild spiritual grass with slender emerald blades that absorb the ambient Qi of heaven and earth.",
		SellValue = 5,
		PromptHoldDuration = 0.4,
		PrimaryColor = Color3.fromRGB(80, 200, 110),
		SecondaryColor = Color3.fromRGB(160, 255, 180),
	},
	["Ginseng Herb"] = {
		Id = "Ginseng Herb",
		Name = "Ginseng Herb",
		InventoryItem = "Ginseng Herb",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Common",
		Description = "A potent nourishing mountain root with serrated leaves and a cluster of scarlet berries.",
		SellValue = 8,
		PromptHoldDuration = 0.4,
		PrimaryColor = Color3.fromRGB(210, 175, 120),
		SecondaryColor = Color3.fromRGB(215, 45, 45),
	},
	["Ironleaf Herb"] = {
		Id = "Ironleaf Herb",
		Name = "Ironleaf Herb",
		InventoryItem = "Ironleaf Herb",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Uncommon",
		Description = "Sturdy, metallic-sheen lanceolate leaves with tempered edges, prized for strengthening physical meridians.",
		SellValue = 12,
		PromptHoldDuration = 0.4,
		PrimaryColor = Color3.fromRGB(115, 130, 145),
		SecondaryColor = Color3.fromRGB(60, 75, 90),
	},
	["Moonlight Grass"] = {
		Id = "Moonlight Grass",
		Name = "Moonlight Grass",
		InventoryItem = "Moonlight Grass",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Uncommon",
		Description = "Pale silver curved blades that absorb lunar essence, emitting a cool and tranquil twilight radiance.",
		SellValue = 15,
		PromptHoldDuration = 0.4,
		PrimaryColor = Color3.fromRGB(195, 220, 245),
		SecondaryColor = Color3.fromRGB(140, 180, 235),
	},
	["Clearheart Flower"] = {
		Id = "Clearheart Flower",
		Name = "Clearheart Flower",
		InventoryItem = "Clearheart Flower",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Uncommon",
		Description = "A pristine ivory blossom with a warm golden core that cleanses mental demons and calms turbulent Qi.",
		SellValue = 16,
		PromptHoldDuration = 0.4,
		PrimaryColor = Color3.fromRGB(245, 245, 240),
		SecondaryColor = Color3.fromRGB(255, 205, 70),
	},
	["Bloodroot"] = {
		Id = "Bloodroot",
		Name = "Bloodroot",
		InventoryItem = "Bloodroot",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Rare",
		Description = "Deep crimson root nodule rich with vital blood essence, flanked by rich wine-red spade foliage.",
		SellValue = 22,
		PromptHoldDuration = 0.5,
		PrimaryColor = Color3.fromRGB(175, 30, 40),
		SecondaryColor = Color3.fromRGB(105, 15, 25),
	},
	["Jade Lotus"] = {
		Id = "Jade Lotus",
		Name = "Jade Lotus",
		InventoryItem = "Jade Lotus",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Rare",
		Description = "Translucent jade petals unfurling in quiet mountain springs, distilling pure watery spirit essence.",
		SellValue = 25,
		PromptHoldDuration = 0.5,
		PrimaryColor = Color3.fromRGB(90, 215, 160),
		SecondaryColor = Color3.fromRGB(240, 220, 130),
		IsWaterPlant = true,
	},
	["Hundred-Year Ginseng"] = {
		Id = "Hundred-Year Ginseng",
		Name = "Hundred-Year Ginseng",
		InventoryItem = "Hundred-Year Ginseng",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Epic",
		Description = "An ancient, thick humanoid ginseng root that has absorbed mountain essence for over a century.",
		SellValue = 38,
		PromptHoldDuration = 0.5,
		PrimaryColor = Color3.fromRGB(230, 185, 105),
		SecondaryColor = Color3.fromRGB(235, 60, 50),
	},
	["Dragon Vein Grass"] = {
		Id = "Dragon Vein Grass",
		Name = "Dragon Vein Grass",
		InventoryItem = "Dragon Vein Grass",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Epic",
		Description = "Spiritual grass growing along subterranean dragon pulses, etched with vibrant golden meridian patterns.",
		SellValue = 42,
		PromptHoldDuration = 0.5,
		PrimaryColor = Color3.fromRGB(65, 165, 95),
		SecondaryColor = Color3.fromRGB(255, 195, 45),
	},
	["Ghost Orchid"] = {
		Id = "Ghost Orchid",
		Name = "Ghost Orchid",
		InventoryItem = "Ghost Orchid",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Epic",
		Description = "An ethereal pale orchid with serpentine drooping petals that flutters like a wandering spiritual phantom.",
		SellValue = 48,
		PromptHoldDuration = 0.5,
		PrimaryColor = Color3.fromRGB(230, 225, 255),
		SecondaryColor = Color3.fromRGB(165, 135, 220),
	},
	["Spirit Bamboo"] = {
		Id = "Spirit Bamboo",
		Name = "Spirit Bamboo",
		InventoryItem = "Spirit Bamboo",
		InventoryCategory = "Miscs",
		RespawnTime = 3,
		RespawnRadius = 9,
		Rarity = "Legendary",
		Description = "A sacred segmented bamboo shoot humming with concentrated spiritual resonance and celestial poise.",
		SellValue = 60,
		PromptHoldDuration = 0.6,
		PrimaryColor = Color3.fromRGB(75, 195, 110),
		SecondaryColor = Color3.fromRGB(215, 245, 175),
	},
} :: { [string]: PlantDef }

function PlantConfig.GetPlant(name: string?): PlantDef?
	if not name then return nil end
	return PlantConfig.Plants[name]
end

function PlantConfig.IsPlant(name: string?): boolean
	if not name then return false end
	return PlantConfig.Plants[name] ~= nil
end

return PlantConfig
