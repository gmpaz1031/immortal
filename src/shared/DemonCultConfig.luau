--!strict
--[[
    DemonCultConfig.luau
    Central configuration for all Heavenly Demon Cult enemies.
    Mirrors the pattern of CaveEnemyConfig.luau exactly.
]]

export type EnemyStats = {
	MaxHealth: number,
	WalkSpeed: number,
	Scale: number,
	BaseDamage: number,
	AttackRange: number,
	AttackCooldown: number,
	ChaseRange: number,
	SpecialCooldowns: { [string]: number }?,
	IsBoss: boolean?,
	IsStandby: boolean?,
	Title: string?,
}

local DemonCultConfig = {
	-- 1. Demon Cultist (Normal)
	DemonCultist = {
		MaxHealth = 120,
		WalkSpeed = 14,
		Scale = 1.0,
		BaseDamage = 18,
		AttackRange = 5.5,
		AttackCooldown = 1.2,
		ChaseRange = 55,
		IsBoss = false,
		IsStandby = false,
		Title = "Demon Cultist",
	} :: EnemyStats,

	-- 2. Senior Demon Cultist (Elite)
	SeniorDemonCultist = {
		MaxHealth = 280,
		WalkSpeed = 15,
		Scale = 1.1,
		BaseDamage = 26,
		AttackRange = 6.0,
		AttackCooldown = 1.1,
		ChaseRange = 60,
		IsBoss = false,
		IsStandby = false,
		Title = "Senior Demon Cultist",
	} :: EnemyStats,

	-- 3. Demonic Elder (Mini-Boss)
	DemonicElder = {
		MaxHealth = 750,
		WalkSpeed = 13,
		Scale = 1.2,
		BaseDamage = 30,
		AttackRange = 6.5,
		AttackCooldown = 1.4,
		ChaseRange = 75,
		SpecialCooldowns = {
			NearPull  = 4.0, -- palm pull if player within 10 studs
			FarFlame  = 3.0, -- flame palm projectile if player > 10 studs
		},
		IsBoss = true,
		IsStandby = false,
		Title = "Demonic Elder · Cult Guardian",
	} :: EnemyStats,

	-- 4. Flame Demoness (Demonic Pillar)
	FlameDemoness = {
		MaxHealth = 900,
		WalkSpeed = 14,
		Scale = 1.15,
		BaseDamage = 32,
		AttackRange = 6.0,
		AttackCooldown = 1.3,
		ChaseRange = 80,
		SpecialCooldowns = {
			FlameShockwave = 6.0,
			FlamePull      = 4.0,
		},
		IsBoss = true,
		IsStandby = false,
		Title = "Flame Demoness · Pillar of Fire",
	} :: EnemyStats,

	-- 5. Poison Demoness (Demonic Pillar)
	PoisonDemoness = {
		MaxHealth = 850,
		WalkSpeed = 15,
		Scale = 1.15,
		BaseDamage = 28,
		AttackRange = 6.0,
		AttackCooldown = 1.2,
		ChaseRange = 80,
		SpecialCooldowns = {
			PoisonOrb  = 5.0,
			PoisonPool = 8.0,
		},
		IsBoss = true,
		IsStandby = false,
		Title = "Poison Demoness · Pillar of Venom",
	} :: EnemyStats,

	-- 6. Fist Demon (Demonic Pillar)
	FistDemon = {
		MaxHealth = 1050,
		WalkSpeed = 13,
		Scale = 1.3,
		BaseDamage = 38,
		AttackRange = 7.0,
		AttackCooldown = 1.5,
		ChaseRange = 75,
		SpecialCooldowns = {
			GroundSmash  = 7.0,
			DemonicDash  = 5.0,
		},
		IsBoss = true,
		IsStandby = false,
		Title = "Fist Demon · Pillar of Destruction",
	} :: EnemyStats,

	-- 7. Sword Demon (Demonic Pillar)
	SwordDemon = {
		MaxHealth = 920,
		WalkSpeed = 16,
		Scale = 1.2,
		BaseDamage = 35,
		AttackRange = 6.5,
		AttackCooldown = 1.0,
		ChaseRange = 80,
		SpecialCooldowns = {
			CrossSlash   = 6.0,
			SwordWave    = 4.0,
			ShadowStep   = 5.0,
		},
		IsBoss = true,
		IsStandby = false,
		Title = "Sword Demon · Pillar of Blades",
	} :: EnemyStats,

	-- 8. Supreme Demon (High-Level Boss - Standby skills)
	SupremeDemon = {
		MaxHealth = 2800,
		WalkSpeed = 14,
		Scale = 1.45,
		BaseDamage = 55,
		AttackRange = 8.0,
		AttackCooldown = 1.6,
		ChaseRange = 90,
		SpecialCooldowns = {
			DarkExplosion = 10.0,
			DemonSummon   = 15.0,
			InfernalWave  = 8.0,
		},
		IsBoss = true,
		IsStandby = true,
		Title = "Supreme Demon · Heavenly Demon Sovereign",
	} :: EnemyStats,

	-- 9. Blood Demon (High-Level Boss - Standby skills)
	BloodDemon = {
		MaxHealth = 2400,
		WalkSpeed = 15,
		Scale = 1.35,
		BaseDamage = 48,
		AttackRange = 7.5,
		AttackCooldown = 1.4,
		ChaseRange = 85,
		SpecialCooldowns = {
			BloodSlash  = 5.0,
			BloodPool   = 8.0,
			LifeDrain   = 10.0,
		},
		IsBoss = true,
		IsStandby = true,
		Title = "Blood Demon · Crimson Patriarch",
	} :: EnemyStats,
}

return DemonCultConfig
