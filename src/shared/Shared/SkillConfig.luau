--!strict
-- src/shared/SkillConfig.luau
-- Martial Arts & Spiritual Skills Catalog for Immortal

export type TargetType = "Directional" | "AOE" | "Targeted"

export type SkillDef = {
	Name: string,
	DisplayName: string,
	Description: string,
	Icon: string,
	Cooldown: number,
	QiCost: number,
	Damage: number,
	Range: number,
	Radius: number?,
	Speed: number?,
	Count: number?,
	TargetType: TargetType,
}

local SkillConfig = {}

SkillConfig.SkillList = {
	"Sword Slash",
	"Flame Ball",
	"Palm Art",
	"Thunder Strike",
	"Multiple Swords",
	"Flame Spear",
}

SkillConfig.DefaultSlots = {
	[1] = "Sword Slash",
	[2] = "Flame Ball",
	[3] = "Palm Art",
	[4] = "Thunder Strike",
}

SkillConfig.Skills = {
	["Sword Slash"] = {
		Name = "Sword Slash",
		DisplayName = "Sword Slash",
		Description = "Fires a sharp crescent wave of spiritual sword energy forward, cutting through enemies.",
		Icon = "SS",
		Cooldown = 2.0,
		QiCost = 0, -- Free basic martial strike
		Damage = 35,
		Range = 45,
		Speed = 75,
		TargetType = "Directional",
	},
	["Flame Ball"] = {
		Name = "Flame Ball",
		DisplayName = "Flame Ball",
		Description = "Hurls a condensed fireball of True Samadhi Fire that detonates on impact.",
		Icon = "FB",
		Cooldown = 4.0,
		QiCost = 15,
		Damage = 55,
		Range = 60,
		Radius = 12,
		Speed = 65,
		TargetType = "Directional",
	},
	["Palm Art"] = {
		Name = "Palm Art",
		DisplayName = "Palm Art",
		Description = "Clones PalmArtHand, firing it forward toward your aim. Explodes on contact with foes or ground, fading after 4 seconds.",
		Icon = "PA",
		Cooldown = 3.5,
		QiCost = 10,
		Damage = 50,
		Range = 120,
		Radius = 14,
		Speed = 55,
		TargetType = "Directional",
	},
	["Thunder Strike"] = {
		Name = "Thunder Strike",
		DisplayName = "Thunder Strike",
		Description = "Summons heavenly lightning to strike the targeted area after a brief warning.",
		Icon = "TS",
		Cooldown = 6.5,
		QiCost = 25,
		Damage = 90,
		Range = 65,
		Radius = 16,
		TargetType = "AOE",
	},
	["Multiple Swords"] = {
		Name = "Multiple Swords",
		DisplayName = "Multiple Swords",
		Description = "Forms 5 spirit flying swords in a halo that pierce sequentially towards the target.",
		Icon = "MS",
		Cooldown = 10.0,
		QiCost = 60,
		Damage = 110,
		Range = 70,
		Count = 5,
		TargetType = "Directional",
	},
	["Flame Spear"] = {
		Name = "Flame Spear",
		DisplayName = "Flame Spear",
		Description = "Channels intense spiritual flames into a piercing lance that strikes directly at a target.",
		Icon = "FS",
		Cooldown = 6.5,
		QiCost = 35,
		Damage = 70,
		Range = 55,
		TargetType = "Targeted",
	},
} :: { [string]: SkillDef }

function SkillConfig.getSkill(skillName: string): SkillDef?
	return SkillConfig.Skills[skillName]
end

return SkillConfig
