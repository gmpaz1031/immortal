--!strict
--[[
    SpecialEnemyConfig.luau
    Phase G — Configuration for special wandering enemies:
      - IronBodyBandit  : Iron transformation at 50% HP
      - ThiefAssassin   : 10,000 Thieves (behind-counter + Omni Slash)
      - WanderingSwordmaster : 3x slash + Cross Slash finisher
]]

export type EnemyStats = {
	MaxHealth: number, WalkSpeed: number, Scale: number, BaseDamage: number,
	AttackRange: number, AttackCooldown: number, ChaseRange: number,
	SpecialCooldowns: { [string]: number }?,
	IsBoss: boolean?, IsStandby: boolean?, Title: string?,
}

local SpecialEnemyConfig = {
	-- Iron Body Bandit — transforms at 50% HP
	IronBodyBandit = {
		MaxHealth = 420, WalkSpeed = 12, Scale = 1.15, BaseDamage = 30,
		AttackRange = 6.0, AttackCooldown = 1.3, ChaseRange = 60,
		SpecialCooldowns = { IronGuard = 6.0, BodySlam = 8.0 },
		IsBoss = false, IsStandby = false, Title = "Iron Body Bandit",
	} :: EnemyStats,

	-- 10,000 Thieves — shadow assassin variant
	ThiefAssassin = {
		MaxHealth = 260, WalkSpeed = 17, Scale = 1.0, BaseDamage = 22,
		AttackRange = 5.5, AttackCooldown = 1.0, ChaseRange = 65,
		SpecialCooldowns = {
			BehindCounter = 3.5,  -- teleport behind then counter
			OmniSlash     = 12.0, -- 5-hit omnidirectional slash
		},
		IsBoss = false, IsStandby = false, Title = "10,000 Thieves · Shadow Blade",
	} :: EnemyStats,

	-- Wandering Swordmaster — elite roaming boss
	WanderingSwordmaster = {
		MaxHealth = 1400, WalkSpeed = 15, Scale = 1.3, BaseDamage = 40,
		AttackRange = 7.0, AttackCooldown = 1.1, ChaseRange = 80,
		SpecialCooldowns = {
			TripleSlash  = 5.0,   -- 3 rapid slashes
			CrossSlash   = 8.0,   -- diagonal cross slash finisher
			SwordPresure = 10.0,  -- sword ki pressure wave
		},
		IsBoss = true, IsStandby = false, Title = "Wandering Swordmaster · Blade of No Return",
	} :: EnemyStats,
}

return SpecialEnemyConfig
