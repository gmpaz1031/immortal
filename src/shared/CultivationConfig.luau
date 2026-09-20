--!strict
-- src/shared/CultivationConfig.luau
-- Comprehensive Cultivation Realm System & Formulas for Immortal

export type RealmDef = {
	Name: string,
	RankTitle: string,
	MaxLevel: number,
	BaseQiPerSecond: number,
	BaseDamage: number,
	BaseDefense: number,
	BaseHealth: number,
	StageCapacities: { [number]: number },
	ReqFormula: (level: number) -> number,
}

local CultivationConfig = {}

CultivationConfig.Realms = {
	["Qi Condensation"] = {
		Name = "Qi Condensation",
		RankTitle = "Mortal Disciple",
		MaxLevel = 9,
		BaseQiPerSecond = 10,
		BaseDamage = 15,
		BaseDefense = 5,
		BaseHealth = 100,
		StageCapacities = {
			[1] = 5000,
			[2] = 7500,
			[3] = 10000,
			[4] = 13000,
			[5] = 16500,
			[6] = 20500,
			[7] = 25000,
			[8] = 30000,
			[9] = 36000,
		},
		ReqFormula = function(level: number): number
			local stage = math.clamp(level <= 0 and 1 or level, 1, 9)
			local caps = CultivationConfig.Realms["Qi Condensation"].StageCapacities
			return caps[stage] or (5000 + (stage - 1) * 2500)
		end,
	},
	["Foundation Establishment"] = {
		Name = "Foundation Establishment",
		RankTitle = "Outer Sect Adept",
		MaxLevel = 9,
		BaseQiPerSecond = 25,
		BaseDamage = 50,
		BaseDefense = 25,
		BaseHealth = 300,
		StageCapacities = {
			[1] = 50000,
			[2] = 70000,
			[3] = 95000,
			[4] = 125000,
			[5] = 160000,
			[6] = 200000,
			[7] = 250000,
			[8] = 310000,
			[9] = 380000,
		},
		ReqFormula = function(level: number): number
			local stage = math.clamp(level <= 0 and 1 or level, 1, 9)
			local caps = CultivationConfig.Realms["Foundation Establishment"].StageCapacities
			return caps[stage] or (50000 + (stage - 1) * 20000)
		end,
	},
	["Core Formation"] = {
		Name = "Core Formation",
		RankTitle = "Inner Sect Expert",
		MaxLevel = 9,
		BaseQiPerSecond = 75,
		BaseDamage = 150,
		BaseDefense = 80,
		BaseHealth = 800,
		StageCapacities = {
			[1] = 500000,
			[2] = 750000,
			[3] = 1050000,
			[4] = 1400000,
			[5] = 1800000,
			[6] = 2250000,
			[7] = 2800000,
			[8] = 3500000,
			[9] = 4300000,
		},
		ReqFormula = function(level: number): number
			local stage = math.clamp(level <= 0 and 1 or level, 1, 9)
			local caps = CultivationConfig.Realms["Core Formation"].StageCapacities
			return caps[stage] or (500000 + (stage - 1) * 250000)
		end,
	},
	["Nascent Soul"] = {
		Name = "Nascent Soul",
		RankTitle = "Grand Elder",
		MaxLevel = 9,
		BaseQiPerSecond = 250,
		BaseDamage = 450,
		BaseDefense = 220,
		BaseHealth = 2000,
		StageCapacities = {
			[1] = 5000000,
			[2] = 7500000,
			[3] = 11000000,
			[4] = 15000000,
			[5] = 20000000,
			[6] = 26000000,
			[7] = 33000000,
			[8] = 42000000,
			[9] = 53000000,
		},
		ReqFormula = function(level: number): number
			local stage = math.clamp(level <= 0 and 1 or level, 1, 9)
			local caps = CultivationConfig.Realms["Nascent Soul"].StageCapacities
			return caps[stage] or (5000000 + (stage - 1) * 2500000)
		end,
	},
} :: { [string]: RealmDef }

CultivationConfig.RealmOrder = {
	"Qi Condensation",
	"Foundation Establishment",
	"Core Formation",
	"Nascent Soul",
}

function CultivationConfig.getRequiredQi(realmName: string, level: number): number
	local def = CultivationConfig.Realms[realmName]
	if not def then return 5000 end
	return def.ReqFormula(level)
end

function CultivationConfig.getBaseQiRate(realmName: string): number
	local def = CultivationConfig.Realms[realmName]
	return def and def.BaseQiPerSecond or 10
end

function CultivationConfig.getNextRealm(currentRealm: string): string?
	for i, name in ipairs(CultivationConfig.RealmOrder) do
		if name == currentRealm then
			return CultivationConfig.RealmOrder[i + 1]
		end
	end
	return nil
end

-- Checks if manual element matches character spiritual root
-- E.g. "Fire Scripture" (Element="Fire") matches "Fire Root"
function CultivationConfig.isManualSynergy(manualElement: string?, rootName: string?): boolean
	if not manualElement or manualElement == "" or not rootName or rootName == "" or rootName == "None" then
		return false
	end
	local rootPrefix = string.match(rootName, "^(%a+)") or rootName
	return string.lower(manualElement) == string.lower(rootPrefix)
end

-- Formula: Final Qi Rate = BaseQi * TalentMultiplier * (hasSynergy and RootBonus or 1.0)
function CultivationConfig.calculateQiRate(baseQi: number, talentMult: number, rootMult: number, hasSynergy: boolean): number
	local effectiveRoot = hasSynergy and rootMult or 1.0
	local total = baseQi * talentMult * effectiveRoot
	return math.floor(total * 10 + 0.5) / 10
end

return CultivationConfig
