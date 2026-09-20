--!strict
-- src/shared/CultivationConfig.luau
-- Comprehensive 12-Tier Xianxia Cultivation Realm System & Formulas for Immortal

export type RealmDef = {
	Name: string,
	RankTitle: string,
	MaxLevel: number,
	BaseQiPerSecond: number,
	BaseDamage: number,
	BaseDefense: number,
	BaseHealth: number,
	ReqFormula: (level: number) -> number,
}

local CultivationConfig = {}

CultivationConfig.Realms = {
	["Qi Condensation"] = {
		Name = "Qi Condensation",
		RankTitle = "Mortal Disciple",
		MaxLevel = 10,
		BaseQiPerSecond = 5,
		BaseDamage = 15,
		BaseDefense = 5,
		BaseHealth = 100,
		ReqFormula = function(level: number): number
			return math.floor(100 * (2.5 ^ level) + 0.5)
		end,
	},
	["Foundation Establishment"] = {
		Name = "Foundation Establishment",
		RankTitle = "Outer Sect Adept",
		MaxLevel = 9,
		BaseQiPerSecond = 18,
		BaseDamage = 45,
		BaseDefense = 20,
		BaseHealth = 250,
		ReqFormula = function(level: number): number
			return math.floor(3000 * (1.8 ^ level) + 0.5)
		end,
	},
	["Core Formation"] = {
		Name = "Core Formation",
		RankTitle = "Inner Sect Expert",
		MaxLevel = 9,
		BaseQiPerSecond = 60,
		BaseDamage = 120,
		BaseDefense = 60,
		BaseHealth = 600,
		ReqFormula = function(level: number): number
			return math.floor(50000 * (1.9 ^ level) + 0.5)
		end,
	},
	["Nascent Soul"] = {
		Name = "Nascent Soul",
		RankTitle = "Core Elder",
		MaxLevel = 9,
		BaseQiPerSecond = 200,
		BaseDamage = 350,
		BaseDefense = 180,
		BaseHealth = 1500,
		ReqFormula = function(level: number): number
			return math.floor(500000 * (2.0 ^ level) + 0.5)
		end,
	},
	["Soul Formation"] = {
		Name = "Soul Formation",
		RankTitle = "Grand Elder",
		MaxLevel = 9,
		BaseQiPerSecond = 650,
		BaseDamage = 900,
		BaseDefense = 480,
		BaseHealth = 3800,
		ReqFormula = function(level: number): number
			return math.floor(4000000 * (2.0 ^ level) + 0.5)
		end,
	},
	["Void Refinement"] = {
		Name = "Void Refinement",
		RankTitle = "Sect Patriarch",
		MaxLevel = 9,
		BaseQiPerSecond = 2000,
		BaseDamage = 2400,
		BaseDefense = 1300,
		BaseHealth = 9500,
		ReqFormula = function(level: number): number
			return math.floor(30000000 * (2.0 ^ level) + 0.5)
		end,
	},
	["Body Integration"] = {
		Name = "Body Integration",
		RankTitle = "Earthly Sovereign",
		MaxLevel = 9,
		BaseQiPerSecond = 6000,
		BaseDamage = 6500,
		BaseDefense = 3500,
		BaseHealth = 24000,
		ReqFormula = function(level: number): number
			return math.floor(250000000 * (2.1 ^ level) + 0.5)
		end,
	},
	["Great Mahayana"] = {
		Name = "Great Mahayana",
		RankTitle = "Supreme Ancestor",
		MaxLevel = 9,
		BaseQiPerSecond = 18000,
		BaseDamage = 18000,
		BaseDefense = 9500,
		BaseHealth = 60000,
		ReqFormula = function(level: number): number
			return math.floor(2000000000 * (2.1 ^ level) + 0.5)
		end,
	},
	["Tribulation Transcendence"] = {
		Name = "Tribulation Transcendence",
		RankTitle = "Heavenly Ascendant",
		MaxLevel = 9,
		BaseQiPerSecond = 50000,
		BaseDamage = 50000,
		BaseDefense = 26000,
		BaseHealth = 150000,
		ReqFormula = function(level: number): number
			return math.floor(15000000000 * (2.1 ^ level) + 0.5)
		end,
	},
	["True Immortal"] = {
		Name = "True Immortal",
		RankTitle = "Earthly Immortal",
		MaxLevel = 9,
		BaseQiPerSecond = 150000,
		BaseDamage = 140000,
		BaseDefense = 75000,
		BaseHealth = 400000,
		ReqFormula = function(level: number): number
			return math.floor(120000000000 * (2.2 ^ level) + 0.5)
		end,
	},
	["Golden Immortal"] = {
		Name = "Golden Immortal",
		RankTitle = "Heavenly Golden Immortal",
		MaxLevel = 9,
		BaseQiPerSecond = 450000,
		BaseDamage = 400000,
		BaseDefense = 210000,
		BaseHealth = 1000000,
		ReqFormula = function(level: number): number
			return math.floor(1000000000000 * (2.2 ^ level) + 0.5)
		end,
	},
	["Immortal Sovereign"] = {
		Name = "Immortal Sovereign",
		RankTitle = "Primordial Dao Paragon",
		MaxLevel = 9,
		BaseQiPerSecond = 1350000,
		BaseDamage = 1200000,
		BaseDefense = 600000,
		BaseHealth = 2800000,
		ReqFormula = function(level: number): number
			return math.floor(8000000000000 * (2.2 ^ level) + 0.5)
		end,
	},
} :: { [string]: RealmDef }

CultivationConfig.RealmOrder = {
	"Qi Condensation",
	"Foundation Establishment",
	"Core Formation",
	"Nascent Soul",
	"Soul Formation",
	"Void Refinement",
	"Body Integration",
	"Great Mahayana",
	"Tribulation Transcendence",
	"True Immortal",
	"Golden Immortal",
	"Immortal Sovereign",
}

function CultivationConfig.getRequiredQi(realmName: string, level: number): number
	local def = CultivationConfig.Realms[realmName]
	if not def then return 100 end
	return def.ReqFormula(level)
end

function CultivationConfig.getNextRealm(currentRealm: string): string?
	for i, name in ipairs(CultivationConfig.RealmOrder) do
		if name == currentRealm then
			return CultivationConfig.RealmOrder[i + 1]
		end
	end
	return nil
end

function CultivationConfig.getRealmIndex(realmName: string): number
	for i, name in ipairs(CultivationConfig.RealmOrder) do
		if name == realmName then
			return i
		end
	end
	return 1
end

function CultivationConfig.meetsRequirement(playerRealm: string, requiredRealm: string): boolean
	return CultivationConfig.getRealmIndex(playerRealm) >= CultivationConfig.getRealmIndex(requiredRealm)
end

return CultivationConfig
