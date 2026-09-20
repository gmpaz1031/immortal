--!strict
--[[
    CaveEnemyConfig.luau
    Central configuration and balance tuning for Cave Enemies and Destroyed Village combatants.
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

local CaveEnemyConfig = {
	-- 1. Cave Spider (Normal)
	CaveSpider = {
		MaxHealth = 85,
		WalkSpeed = 15,
		Scale = 1.0,
		BaseDamage = 14,
		AttackRange = 5.5,
		AttackCooldown = 1.2,
		ChaseRange = 50,
		IsBoss = false,
		IsStandby = false,
		Title = "Cave Spider",
	} :: EnemyStats,

	-- 2. Cave Spider Mother (Boss)
	SpiderMother = {
		MaxHealth = 650,
		WalkSpeed = 13,
		Scale = 2.2,
		BaseDamage = 28,
		AttackRange = 8.5,
		AttackCooldown = 1.4,
		ChaseRange = 85,
		SpecialCooldowns = {
			PoisonSpit = 5.0, -- Every 5 seconds
		},
		IsBoss = true,
		IsStandby = false,
		Title = "Cave Spider Mother · Brood Queen",
	} :: EnemyStats,

	-- 3. Assassin (Normal)
	Assassin = {
		MaxHealth = 100,
		WalkSpeed = 16,
		Scale = 1.0,
		BaseDamage = 16,
		AttackRange = 5.0,
		AttackCooldown = 1.1,
		ChaseRange = 60,
		SpecialCooldowns = {
			BehindAttack = 3.5, -- Every 3.5 seconds
		},
		IsBoss = false,
		IsStandby = false,
		Title = "Shadow Assassin",
	} :: EnemyStats,

	-- 4. Senior Assassin (Elite)
	SeniorAssassin = {
		MaxHealth = 220,
		WalkSpeed = 17,
		Scale = 1.15,
		BaseDamage = 20,
		AttackRange = 5.5,
		AttackCooldown = 1.0,
		ChaseRange = 70,
		SpecialCooldowns = {
			BehindAttack = 3.5,  -- Every 3.5 seconds
			MultipleSlash = 10.0, -- Every 10 seconds
		},
		IsBoss = false,
		IsStandby = false,
		Title = "Senior Assassin · Elite",
	} :: EnemyStats,

	-- 5. Four Pillar Assassin (Semi-Boss - STANDBY)
	FourPillarAssassin = {
		MaxHealth = 480,
		WalkSpeed = 14,
		Scale = 1.25,
		BaseDamage = 25,
		AttackRange = 6.0,
		AttackCooldown = 1.5,
		ChaseRange = 75,
		IsBoss = true,
		IsStandby = true,
		Title = "Four Pillar Assassin",
	} :: EnemyStats,

	-- 6. Supreme Assassin (Boss - STANDBY)
	SupremeAssassin = {
		MaxHealth = 1100,
		WalkSpeed = 14,
		Scale = 1.4,
		BaseDamage = 35,
		AttackRange = 7.0,
		AttackCooldown = 1.5,
		ChaseRange = 90,
		IsBoss = true,
		IsStandby = true,
		Title = "Supreme Assassin · Shadow Patriarch",
	} :: EnemyStats,

	-- 7. Swordsman (Destroyed Village Normal)
	Swordsman = {
		MaxHealth = 95,
		WalkSpeed = 13,
		Scale = 1.0,
		BaseDamage = 15,
		AttackRange = 5.5,
		AttackCooldown = 1.2,
		ChaseRange = 55,
		IsBoss = false,
		IsStandby = false,
		Title = "Fallen Swordsman",
	} :: EnemyStats,

	-- 8. Swordmaster (Village Boss - STANDBY)
	Swordmaster = {
		MaxHealth = 880,
		WalkSpeed = 14,
		Scale = 1.35,
		BaseDamage = 32,
		AttackRange = 7.5,
		AttackCooldown = 1.5,
		ChaseRange = 85,
		IsBoss = true,
		IsStandby = true,
		Title = "Swordmaster · Grandmaster of the Fallen Shrine",
	} :: EnemyStats,
}

return CaveEnemyConfig
