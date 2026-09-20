--!strict
--[[
    HeavenAllianceConfig.luau
    Phase E/F — Configuration for all Heavenly Alliance enemies.
    Mirrors CaveEnemyConfig.luau and DemonCultConfig.luau patterns exactly.
]]

export type EnemyStats = {
	MaxHealth: number, WalkSpeed: number, Scale: number, BaseDamage: number,
	AttackRange: number, AttackCooldown: number, ChaseRange: number,
	SpecialCooldowns: { [string]: number }?,
	IsBoss: boolean?, IsStandby: boolean?, Title: string?,
}

local HeavenAllianceConfig = {
	-- 1. Heaven Swordsman (Normal)
	HeavenSwordsman = {
		MaxHealth = 130, WalkSpeed = 14, Scale = 1.0, BaseDamage = 20,
		AttackRange = 5.5, AttackCooldown = 1.1, ChaseRange = 55,
		IsBoss = false, IsStandby = false, Title = "Heaven Swordsman",
	} :: EnemyStats,

	-- 2. Senior Heaven Swordsman (Elite)
	SeniorHeavenSwordsman = {
		MaxHealth = 320, WalkSpeed = 15, Scale = 1.1, BaseDamage = 28,
		AttackRange = 6.0, AttackCooldown = 1.0, ChaseRange = 62,
		SpecialCooldowns = { GoldenSlash = 5.0 },
		IsBoss = false, IsStandby = false, Title = "Senior Heaven Swordsman",
	} :: EnemyStats,

	-- 3. Heavenly Elder (Mini-Boss)
	HeavenlyElder = {
		MaxHealth = 820, WalkSpeed = 13, Scale = 1.2, BaseDamage = 32,
		AttackRange = 6.5, AttackCooldown = 1.3, ChaseRange = 75,
		SpecialCooldowns = { DivinePalm = 5.0, LightBeam = 7.0 },
		IsBoss = true, IsStandby = false, Title = "Heavenly Elder · Alliance Protector",
	} :: EnemyStats,

	-- 4. Heaven Flame Pillar (Tower Pillar)
	HeavenFlamePillar = {
		MaxHealth = 1100, WalkSpeed = 13, Scale = 1.2, BaseDamage = 34,
		AttackRange = 6.5, AttackCooldown = 1.2, ChaseRange = 80,
		SpecialCooldowns = { GoldenFlameBurst = 6.0, SolarPull = 4.0 },
		IsBoss = true, IsStandby = false, Title = "Heaven Flame Pillar · Solar Guardian",
	} :: EnemyStats,

	-- 5. Heaven Thunder Pillar (Tower Pillar)
	HeavenThunderPillar = {
		MaxHealth = 980, WalkSpeed = 15, Scale = 1.2, BaseDamage = 38,
		AttackRange = 7.0, AttackCooldown = 1.1, ChaseRange = 80,
		SpecialCooldowns = { ThunderBolt = 6.0, LightningDash = 4.0 },
		IsBoss = true, IsStandby = false, Title = "Heaven Thunder Pillar · Storm Guardian",
	} :: EnemyStats,

	-- 6. Heaven Palm Pillar (Tower Pillar)
	HeavenPalmPillar = {
		MaxHealth = 1150, WalkSpeed = 13, Scale = 1.3, BaseDamage = 40,
		AttackRange = 7.5, AttackCooldown = 1.4, ChaseRange = 78,
		SpecialCooldowns = { VajraSmash = 7.0, DivineDash = 5.0 },
		IsBoss = true, IsStandby = false, Title = "Heaven Palm Pillar · Iron Guardian",
	} :: EnemyStats,

	-- 7. Heaven Sword Pillar (Tower Pillar)
	HeavenSwordPillar = {
		MaxHealth = 1020, WalkSpeed = 16, Scale = 1.2, BaseDamage = 36,
		AttackRange = 7.0, AttackCooldown = 1.0, ChaseRange = 82,
		SpecialCooldowns = { ThousandBlades = 7.0, SwordAura = 4.0, BladeTeleport = 5.0 },
		IsBoss = true, IsStandby = false, Title = "Heaven Sword Pillar · Blade Guardian",
	} :: EnemyStats,

	-- 8. Supreme Heaven (Apex Boss — Standby)
	SupremeHeaven = {
		MaxHealth = 3500, WalkSpeed = 14, Scale = 1.5, BaseDamage = 60,
		AttackRange = 9.0, AttackCooldown = 1.5, ChaseRange = 95,
		IsBoss = true, IsStandby = true, Title = "Supreme Heaven · Celestial Patriarch",
	} :: EnemyStats,
}

return HeavenAllianceConfig
