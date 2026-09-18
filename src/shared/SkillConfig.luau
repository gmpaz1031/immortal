--!strict
--[[
    SkillConfig.luau
    Central configuration for all 6 combat skills.
    Defines cooldowns, base damage, ranges, targeting behaviors, and metadata.
    Keybinds: Z = Slot 1, X = Slot 2, V = Slot 3, F = Slot 4
]]

export type SkillType = "ForwardProjectile" | "AreaAroundCaster" | "TargetAreaAoE" | "SkyStrikeAoE" | "MultiProjectile" | "LockOnHoming"

export type SkillDefinition = {
	Name: string,
	DisplayName: string,
	Description: string,
	SkillType: SkillType,
	BaseDamage: number,
	Cooldown: number,
	Range: number,
	Radius: number?,
	ProjectileSpeed: number?,
	ProjectileCount: number?,
	CastTime: number?,
	WarningDuration: number?,
	Color: Color3,
	SecondaryColor: Color3,
	IconSymbol: string,
}

local SkillConfig: { [string]: SkillDefinition } = {
	["Sword Slash"] = {
		Name = "Sword Slash",
		DisplayName = "Wind Blade Slash",
		Description = "Performs a swift crescent slash, launching a razor-sharp blade of pressurized wind forward 20 studs.",
		SkillType = "ForwardProjectile",
		BaseDamage = 28,
		Cooldown = 3.5,
		Range = 25,
		Radius = 4,
		ProjectileSpeed = 70,
		CastTime = 0.25,
		Color = Color3.fromRGB(120, 235, 210), -- Cyan-Teal wind
		SecondaryColor = Color3.fromRGB(240, 255, 255),
		IconSymbol = "🗡️",
	},

	["Palm Art"] = {
		Name = "Palm Art",
		DisplayName = "Vajra Energy Palm",
		Description = "Focuses inner Qi into the palm, unleashing an immense golden shockwave hand that blasts all nearby enemies.",
		SkillType = "AreaAroundCaster",
		BaseDamage = 38,
		Cooldown = 5.0,
		Range = 14,
		Radius = 14,
		CastTime = 0.4,
		Color = Color3.fromRGB(255, 210, 40), -- Golden
		SecondaryColor = Color3.fromRGB(255, 255, 180),
		IconSymbol = "🖐️",
	},

	["Flame Ball"] = {
		Name = "Flame Ball",
		DisplayName = "Phoenix Fire Orb",
		Description = "Conjures a spiraling orb of compressed phoenix fire that detonates on impact, scorching all enemies in an 8-stud radius.",
		SkillType = "TargetAreaAoE",
		BaseDamage = 45,
		Cooldown = 6.0,
		Range = 40,
		Radius = 8,
		ProjectileSpeed = 55,
		CastTime = 0.5,
		Color = Color3.fromRGB(255, 90, 10), -- Deep Orange-Red
		SecondaryColor = Color3.fromRGB(255, 200, 60),
		IconSymbol = "🔥",
	},

	["Thunder Strike"] = {
		Name = "Thunder Strike",
		DisplayName = "Heaven Smiting Bolt",
		Description = "Calls down a divine bolt of purple lightning from the heavens onto the targeted location with a 1.5s warning ring.",
		SkillType = "SkyStrikeAoE",
		BaseDamage = 55,
		Cooldown = 8.0,
		Range = 50,
		Radius = 7,
		CastTime = 0.3,
		WarningDuration = 1.5,
		Color = Color3.fromRGB(180, 80, 255), -- Purple Lightning
		SecondaryColor = Color3.fromRGB(240, 200, 255),
		IconSymbol = "⚡",
	},

	["Multiple Swords"] = {
		Name = "Multiple Swords",
		DisplayName = "Thousand Blade Storm",
		Description = "Summons a spiraling storm of spectral blue swords that converge on a target area, each dealing individual damage.",
		SkillType = "MultiProjectile",
		BaseDamage = 20,
		Cooldown = 9.0,
		Range = 45,
		Radius = 5,
		ProjectileCount = 7,
		ProjectileSpeed = 65,
		CastTime = 0.6,
		Color = Color3.fromRGB(80, 160, 255), -- Electric Blue
		SecondaryColor = Color3.fromRGB(200, 230, 255),
		IconSymbol = "⚔️",
	},

	["Flame Spear"] = {
		Name = "Flame Spear",
		DisplayName = "Solar Homing Spear",
		Description = "Hurls a blazing spear of solar energy that locks onto the nearest enemy and tracks them relentlessly until impact.",
		SkillType = "LockOnHoming",
		BaseDamage = 62,
		Cooldown = 10.0,
		Range = 70,
		Radius = 5,
		ProjectileSpeed = 80,
		CastTime = 0.55,
		Color = Color3.fromRGB(255, 160, 20), -- Solar Gold-Orange
		SecondaryColor = Color3.fromRGB(255, 240, 120),
		IconSymbol = "🔱",
	},
}

-- Ordered list for Skill Book display
local SkillList: { string } = {
	"Sword Slash",
	"Palm Art",
	"Flame Ball",
	"Thunder Strike",
	"Multiple Swords",
	"Flame Spear",
}

-- Default slot loadout for new players (Z=1, X=2, V=3, F=4)
local DefaultSlots: { string } = {
	"Sword Slash",   -- Slot 1 (Z)
	"Palm Art",      -- Slot 2 (X)
	"Flame Ball",    -- Slot 3 (V)
	"Thunder Strike",-- Slot 4 (F)
}

return {
	Skills = SkillConfig,
	SkillList = SkillList,
	DefaultSlots = DefaultSlots,
}
