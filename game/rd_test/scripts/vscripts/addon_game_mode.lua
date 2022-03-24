require('override/CDOTA_BaseNPC')

XP_PER_LEVEL_TABLE = {}
XP_PER_LEVEL_TABLE[0] = 0
XP_PER_LEVEL_TABLE[1] = 150

for i = 2, 25 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 250
end

for i = 26, 50 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 350
end

for i = 51, 74 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 500
end

for i = 75, 99 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 1000
end

function Precache( context )
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_magnataur.vsndevts", context )
end

function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end

function GameMode:InitGameMode()
	GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
	GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
end