--!strict
-- src/shared/ItemConfig.luau
-- Comprehensive Item & Equipment Catalog for Immortal

export type ItemType = "Pill" | "Weapon" | "Armor" | "Plant" | "Ore"
export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

export type ItemDef = {
	Id: string,
	Name: string,
	Type: ItemType,
	Rarity: ItemRarity,
	Icon: string,
	Price: number, -- Buy price in Gold
	SellValue: number,
	Description: string,
	
	-- Combat & Stat Modifiers
	DamageBonus: number?,
	DefenseBonus: number?,
	MaxHealthBonus: number?,
	QiGatherMultiplier: number?,
	InstantQi: number?,
	BuffDurationSeconds: number?,
}

local ItemConfig = {}

ItemConfig.Catalog = {
	-- ------------------------------------------------------------------------
	-- SPIRITUAL PILLS
	-- ------------------------------------------------------------------------
	["Qi Condensation Pill"] = {
		Id = "Qi Condensation Pill",
		Name = "Qi Condensation Pill",
		Type = "Pill",
		Rarity = "Rare",
		Icon = "QC",
		Price = 30,
		SellValue = 15,
		Description = "Amplifies Qi gathering speed by 2x for 5 minutes.",
		QiGatherMultiplier = 2.0,
		BuffDurationSeconds = 300,
	},
	["Lesser Qi Pill"] = {
		Id = "Lesser Qi Pill",
		Name = "Lesser Qi Pill",
		Type = "Pill",
		Rarity = "Common",
		Icon = "QP",
		Price = 15,
		SellValue = 7,
		Description = "Instant spiritual surge. Restores +50 Qi immediately.",
		InstantQi = 50,
	},
	["Spirit Spring Elixir"] = {
		Id = "Spirit Spring Elixir",
		Name = "Spirit Spring Elixir",
		Type = "Pill",
		Rarity = "Uncommon",
		Icon = "EL",
		Price = 20,
		SellValue = 10,
		Description = "Sacred mountain dew. Fully restores 100% of your Total Health.",
	},

	-- ------------------------------------------------------------------------
	-- WEAPONS (Bandit & Boss Drops)
	-- ------------------------------------------------------------------------
	["Iron Sword"] = {
		Id = "Iron Sword",
		Name = "Iron Sword",
		Type = "Weapon",
		Rarity = "Common",
		Icon = "IS",
		Price = 60,
		SellValue = 25,
		Description = "A sturdy forged iron blade carried by mountain wanderers.",
		DamageBonus = 15,
	},
	["Dragon Spear"] = {
		Id = "Dragon Spear",
		Name = "Dragon Spear",
		Type = "Weapon",
		Rarity = "Rare",
		Icon = "DS",
		Price = 150,
		SellValue = 65,
		Description = "Forged with dragon-scale bronze. Strikes with immense reach and piercing power.",
		DamageBonus = 25,
	},
	["Mountain Axe"] = {
		Id = "Mountain Axe",
		Name = "Mountain Axe",
		Type = "Weapon",
		Rarity = "Uncommon",
		Icon = "MA",
		Price = 90,
		SellValue = 40,
		Description = "A heavy brutal axe capable of cleaving armor and bones.",
		DamageBonus = 20,
	},

	-- ------------------------------------------------------------------------
	-- BODY ARMOR (Bandit & Boss Drops)
	-- ------------------------------------------------------------------------
	["Cloud Silk Robe"] = {
		Id = "Cloud Silk Robe",
		Name = "Cloud Silk Robe",
		Type = "Armor",
		Rarity = "Uncommon",
		Icon = "CR",
		Price = 80,
		SellValue = 35,
		Description = "Woven from spiritual silkworm threads. Deflects spiritual cuts.",
		DefenseBonus = 10,
		MaxHealthBonus = 50,
	},
	["Iron Scale Armor"] = {
		Id = "Iron Scale Armor",
		Name = "Iron Scale Armor",
		Type = "Armor",
		Rarity = "Rare",
		Icon = "IA",
		Price = 160,
		SellValue = 70,
		Description = "Interlocking scales of tempered iron, heavy but granting high resilience.",
		DefenseBonus = 20,
		MaxHealthBonus = 120,
	},

	-- ------------------------------------------------------------------------
	-- HARVESTABLE SPIRITUAL PLANTS
	-- ------------------------------------------------------------------------
	["Spirit Grass"] = {
		Id = "Spirit Grass",
		Name = "Spirit Grass",
		Type = "Plant",
		Rarity = "Common",
		Icon = "SG",
		Price = 10,
		SellValue = 5,
		Description = "Wild spiritual grass with slender emerald blades that absorb the ambient Qi of heaven and earth.",
	},
	["Ginseng Herb"] = {
		Id = "Ginseng Herb",
		Name = "Ginseng Herb",
		Type = "Plant",
		Rarity = "Common",
		Icon = "GH",
		Price = 16,
		SellValue = 8,
		Description = "A potent nourishing mountain root with serrated leaves and a cluster of scarlet berries.",
	},
	["Ironleaf Herb"] = {
		Id = "Ironleaf Herb",
		Name = "Ironleaf Herb",
		Type = "Plant",
		Rarity = "Uncommon",
		Icon = "IH",
		Price = 24,
		SellValue = 12,
		Description = "Sturdy, metallic-sheen lanceolate leaves with tempered edges, prized for strengthening physical meridians.",
	},
	["Moonlight Grass"] = {
		Id = "Moonlight Grass",
		Name = "Moonlight Grass",
		Type = "Plant",
		Rarity = "Uncommon",
		Icon = "MG",
		Price = 30,
		SellValue = 15,
		Description = "Pale silver curved blades that absorb lunar essence, emitting a cool and tranquil twilight radiance.",
	},
	["Clearheart Flower"] = {
		Id = "Clearheart Flower",
		Name = "Clearheart Flower",
		Type = "Plant",
		Rarity = "Uncommon",
		Icon = "CF",
		Price = 32,
		SellValue = 16,
		Description = "A pristine ivory blossom with a warm golden core that cleanses mental demons and calms turbulent Qi.",
	},
	["Bloodroot"] = {
		Id = "Bloodroot",
		Name = "Bloodroot",
		Type = "Plant",
		Rarity = "Rare",
		Icon = "BR",
		Price = 45,
		SellValue = 22,
		Description = "Deep crimson root nodule rich with vital blood essence, flanked by rich wine-red spade foliage.",
	},
	["Jade Lotus"] = {
		Id = "Jade Lotus",
		Name = "Jade Lotus",
		Type = "Plant",
		Rarity = "Rare",
		Icon = "JL",
		Price = 50,
		SellValue = 25,
		Description = "Translucent jade petals unfurling in quiet mountain springs, distilling pure watery spirit essence.",
	},
	["Hundred-Year Ginseng"] = {
		Id = "Hundred-Year Ginseng",
		Name = "Hundred-Year Ginseng",
		Type = "Plant",
		Rarity = "Epic",
		Icon = "HY",
		Price = 80,
		SellValue = 38,
		Description = "An ancient, thick humanoid ginseng root that has absorbed mountain essence for over a century.",
	},
	["Dragon Vein Grass"] = {
		Id = "Dragon Vein Grass",
		Name = "Dragon Vein Grass",
		Type = "Plant",
		Rarity = "Epic",
		Icon = "DG",
		Price = 90,
		SellValue = 42,
		Description = "Spiritual grass growing along subterranean dragon pulses, etched with vibrant golden meridian patterns.",
	},
	["Ghost Orchid"] = {
		Id = "Ghost Orchid",
		Name = "Ghost Orchid",
		Type = "Plant",
		Rarity = "Epic",
		Icon = "GO",
		Price = 100,
		SellValue = 48,
		Description = "An ethereal pale orchid with serpentine drooping petals that flutters like a wandering spiritual phantom.",
	},
	["Spirit Bamboo"] = {
		Id = "Spirit Bamboo",
		Name = "Spirit Bamboo",
		Type = "Plant",
		Rarity = "Legendary",
		Icon = "SB",
		Price = 130,
		SellValue = 60,
		Description = "A sacred segmented bamboo shoot humming with concentrated spiritual resonance and celestial poise.",
	},

	-- ------------------------------------------------------------------------
	-- MINEABLE ORES & MINERALS
	-- ------------------------------------------------------------------------
	["Iron Ore"] = {
		Id = "Iron Ore",
		Name = "Iron Ore",
		Type = "Ore",
		Rarity = "Common",
		Icon = "IO",
		Price = 12,
		SellValue = 6,
		Description = "Rough weathered stone with raw metallic iron veins and oxidized rust patches.",
	},
	["Steel Ore"] = {
		Id = "Steel Ore",
		Name = "Steel Ore",
		Type = "Ore",
		Rarity = "Uncommon",
		Icon = "SO",
		Price = 25,
		SellValue = 12,
		Description = "Dense dark basalt rock with polished bright silver metallic veins and sharp fracture planes.",
	},
	["Spirit Stone"] = {
		Id = "Spirit Stone",
		Name = "Spirit Stone",
		Type = "Ore",
		Rarity = "Rare",
		Icon = "SS",
		Price = 50,
		SellValue = 25,
		Description = "Naturally glowing translucent cyan crystals embedded in cavern bedrock, radiating celestial spiritual Qi.",
	},
	["Jade Crystal"] = {
		Id = "Jade Crystal",
		Name = "Jade Crystal",
		Type = "Ore",
		Rarity = "Rare",
		Icon = "JC",
		Price = 60,
		SellValue = 30,
		Description = "Smooth emerald-green crystalline fingers growing from cavern rock, semi-translucent with oily mineral luster.",
	},
	["Black Iron"] = {
		Id = "Black Iron",
		Name = "Black Iron",
		Type = "Ore",
		Rarity = "Epic",
		Icon = "BI",
		Price = 85,
		SellValue = 40,
		Description = "Extremely dense, pitch-black volcanic rock with gunmetal-gray reflective metallic seams.",
	},
} :: { [string]: ItemDef }

ItemConfig.Items = ItemConfig.Catalog

ItemConfig.ShopInventory = {
	"Qi Condensation Pill",
	"Lesser Qi Pill",
	"Spirit Spring Elixir",
	"Iron Sword",
	"Cloud Silk Robe",
}

ItemConfig.EquipmentDrops = {
	"Iron Sword",
	"Dragon Spear",
	"Mountain Axe",
	"Iron Scale Armor",
	"Cloud Silk Robe",
}

function ItemConfig.getItem(itemId: string): ItemDef?
	return ItemConfig.Catalog[itemId]
end

return ItemConfig
