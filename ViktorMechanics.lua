--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/


Hot Keys:
	-All In: Space
	-Harass: G

Changelog:

0.1 - 19/7/14
Draw Texts;
E Logic;
R Logic;

]]

if myHero.charName ~= "Viktor" or not VIP_USER then return end


local version = 0.1
local AUTOUPDATE = true


local SCRIPT_NAME = "ViktorMechanics"
local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"
if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
	SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/gmlyra/BolScripts/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/gmlyra/BolScripts/master/VersionFiles/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
if VIP_USER then
	RequireI:Add("Prodiction", "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/ec830facccefb3b52212dba5696c08697c3c2854/Test/Prodiction/Prodiction.lua")	
end
--RequireI:Add("mrLib", "https://raw.githubusercontent.com/gmlyra/BolScripts/master/common/mrLib.lua")

RequireI:Check()

if RequireI.downloadNeeded == true then return end


require 'VPrediction'
require 'SOW'

-- Constants --
local ignite, igniteReady = nil, nil
local ts = nil
local VP = nil
local qMode = false
local qOff, wOff, eOff, rOff = 0,0,0,0
local abilitySequence = {3, 1, 3, 2, 3, 4, 3, 1, 3, 1, 4, 1, 1, 2, 2, 4, 2, 2}
local Ranges = { AA = 525 }
local skills = {
    Q = { ready = false, name = myHero:GetSpellData(_Q).name, range = 650, delay = myHero:GetSpellData(_Q).delayTotalTimePercent, speed = myHero:GetSpellData(_Q).missileSpeed, width = myHero:GetSpellData(_Q).lineWidth },
	W = { ready = false, name = myHero:GetSpellData(_W).name, range = 600, delay = 0.50, speed = 1750, width = 300 },
	E = { ready = false, name = myHero:GetSpellData(_E).name, range = 550, delay = 0.25, speed = 1210, width = 90 },
	R = { ready = false, name = myHero:GetSpellData(_R).name, range = 700, delay = 0.50, speed = 1210, width = 250 },
}

local AnimationCancel =
{
	[1]=function() myHero:MoveTo(mousePos.x,mousePos.z) end, --"Move"
	[2]=function() SendChat('/l') end, --"Laugh"
	[3]=function() SendChat('/d') end, --"Dance"
	[4]=function() SendChat('/t') end, --"Taunt"
	[5]=function() SendChat('/j') end, --"joke"
	[6]=function() end,
}


--[[ Slots Itens ]]--
local tiamatSlot, hydraSlot, youmuuSlot, bilgeSlot, bladeSlot, dfgSlot, divineSlot = nil, nil, nil, nil, nil, nil, nil
local tiamatReady, hydraReady, youmuuReady, bilgeReady, bladeReady, dfgReady, divineReady = nil, nil, nil, nil, nil, nil, nil

--[[Misc]]--
local lastSkin = 0
local isSAC = false
local isMMA = false
local target = nil

-- [[ VIP Variables]] --
local Prodict

--[[ Kill Text ]]--
TextList = {"Harass him", "Q", "E", "ULT HIM !", "Q+E", "Q+E+Item", "Q+E+R", "All In", "Skills Not Ready"}
KillText = {}
colorText = ARGB(229,229,229,0)

--Credit Trees
function GetCustomTarget()
	ts:update()
	if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
	if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
	return ts.target
end

function OnLoad()
	initComponents()
end

function initComponents()
	-- VPrediction Start
	VP = VPrediction()
	-- SOW Declare
	Orbwalker = SOW(VP)
	-- Target Selector
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1075)
	
	Menu = scriptConfig("Viktor Mechanics by Mr Articuno", "ViktorMA")

	if _G.MMA_Target ~= nil then
		PrintChat("<font color = \"#33CCCC\">MMA Status:</font> <font color = \"#fff8e7\"> Loaded</font>")
		isMMA = true
	elseif _G.AutoCarry ~= nil then
		PrintChat("<font color = \"#33CCCC\">SAC Status:</font> <font color = \"#fff8e7\"> Loaded</font>")
		isSAC = true
	else
		PrintChat("<font color = \"#33CCCC\">OrbWalker not found:</font> <font color = \"#fff8e7\"> Loading SOW</font>")
		Menu:addSubMenu("["..myHero.charName.." - Orbwalker]", "SOWorb")
		Orbwalker:LoadToMenu(Menu.SOWorb)
	end
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "ViktorCombo")
	Menu.ViktorCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.ViktorCombo:addSubMenu("Q Settings", "qSet")
	Menu.ViktorCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.ViktorCombo:addSubMenu("W Settings", "wSet")
	Menu.ViktorCombo.wSet:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Menu.ViktorCombo:addSubMenu("E Settings", "eSet")
	Menu.ViktorCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.ViktorCombo:addSubMenu("R Settings", "rSet")
	Menu.ViktorCombo.rSet:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Harass]", "Harass")
	Menu.Harass:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	Menu.Harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useE", "Use E in Harass", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("["..myHero.charName.." - Laneclear]", "Laneclear")
	Menu.Laneclear:addParam("lclr", "Laneclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Laneclear:addParam("useClearQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Laneclear:addParam("useClearW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, false)
	Menu.Laneclear:addParam("useClearE", "Use E in Laneclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Jungleclear]", "Jungleclear")
	Menu.Jungleclear:addParam("jclr", "Jungleclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Jungleclear:addParam("useClearQ", "Use Q in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungleclear:addParam("useClearW", "Use W in Jungleclear", SCRIPT_PARAM_ONOFF, false)
	Menu.Jungleclear:addParam("useClearE", "Use E in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Additionals]", "Ads")
	Menu.Ads:addParam("cancel", "Animation Cancel", SCRIPT_PARAM_LIST, 1, { "Move","Laugh","Dance","Taunt","joke","Nothing" })
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Killsteal", "KS")
	Menu.Ads.KS:addParam("useQ", "Use Q to KS", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("useE", "Use E to KS", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("useR", "Use R to KS", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("igniteRange", "Minimum range to cast Ignite", SCRIPT_PARAM_SLICE, 470, 0, 600, 0)
	Menu.Ads:addSubMenu("VIP", "VIP")
	--Menu.Ads.VIP:addParam("spellCast", "Spell by Packet", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.VIP:addParam("prodiction", "Use Prodiction", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin", "Use custom skin", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin1", "Skin changer", SCRIPT_PARAM_SLICE, 1, 1, 3)
	
	Menu:addSubMenu("["..myHero.charName.." - Target Selector]", "targetSelector")
	Menu.targetSelector:addTS(ts)
	ts.name = "Focus"
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
	Menu.drawings:addParam("text", "Draw Texts", SCRIPT_PARAM_ONOFF, true)
	local DManager = DrawManager()
	DManager:CreateCircle(myHero, Ranges.AA, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"AA range", true, true, true)
	DManager:CreateCircle(myHero, skills.Q.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"Q range", true, true, true)
	DManager:CreateCircle(myHero, skills.W.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"W range", true, true, true)
	DManager:CreateCircle(myHero, skills.E.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"E range", true, true, true)
	
	targetMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)

	if VIP_USER then
		require 'Prodiction'
		require 'Collision'
		Prodict = ProdictManager.GetInstance()
		
	end
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Viktor", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end
	
	PrintChat("<font color = \"#33CCCC\">Viktor Mechanics by</font> <font color = \"#fff8e7\">Mr Articuno</font>")

end

function OnTick()
	target = GetCustomTarget()
	targetMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()

	if Menu.Ads.VIP.skin and VIP_USER and skinChanged() then
		GenModelPacket("Viktor", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end

	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.ViktorCombo.combo then
		Combo()
	end
	
	if Menu.Harass.harass then
		Harass()
	end

	if Menu.Laneclear.lclr then
		LaneClear()
	end
	
	if Menu.Jungleclear.jclr then
		JungleClear()
	end

end

function CDHandler()
	-- Spells
	skills.Q.ready = (myHero:CanUseSpell(_Q) == READY)
	skills.W.ready = (myHero:CanUseSpell(_W) == READY)
	skills.E.ready = (myHero:CanUseSpell(_E) == READY)
	skills.R.ready = (myHero:CanUseSpell(_R) == READY)
	Ranges.AA = myHero.range
	-- Items
	tiamatSlot = GetInventorySlotItem(3077)
	hydraSlot = GetInventorySlotItem(3074)
	youmuuSlot = GetInventorySlotItem(3142) 
	bilgeSlot = GetInventorySlotItem(3144)
	bladeSlot = GetInventorySlotItem(3153)
	dfgSlot = GetInventorySlotItem(3128)
	divineSlot = GetInventorySlotItem(3131)
	
	tiamatReady = (tiamatSlot ~= nil and myHero:CanUseSpell(tiamatSlot) == READY)
	hydraReady = (hydraSlot ~= nil and myHero:CanUseSpell(hydraSlot) == READY)
	youmuuReady = (youmuuSlot ~= nil and myHero:CanUseSpell(youmuuSlot) == READY)
	bilgeReady = (bilgeSlot ~= nil and myHero:CanUseSpell(bilgeSlot) == READY)
	bladeReady = (bladeSlot ~= nil and myHero:CanUseSpell(bladeSlot) == READY)
	dfgReady = (dfgSlot ~= nil and myHero:CanUseSpell(dfgSlot) == READY)
	divineReady = (divineSlot ~= nil and myHero:CanUseSpell(divineSlot) == READY)

	DamageCalculation()

	-- Summoners
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

-- Harass --

function Harass()	
	if target ~= nil and ValidTarget(target) then
		
		if target.type == myHero.type then

			if Menu.Harass.useQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then

				CastSpell(_Q, target)

			end

			if Menu.Harass.useE and ValidTarget(target, skills.E.range) and skills.E.ready then

				pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

				-- Ryuk's E cast Logic --

				nearUnit = nearEnemy(target, skills.E.range)

				if nearUnit then
					pos2 = Prodiction.GetPrediction(nearUnit, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

					if GetDistance((nearUnit or target)) > 540 and pos ~= nil and pos2 ~= nil then
						m = (pos.z - pos2.z)/(pos.x - pos2.x)
						b = pos.z - (m*pos.x)

						x = (- 500 - b)/(m-1)
						z = (m*x) + b

						castE(x,z,pos.x,pos.z)
					else
						if pos and pos2 then
							c = nil
							f = nil
							if GetDistance(nearUnit) > GetDistance(target) then
								c = pos
								f = pos2
							else
								c = pos2
								f = pos
								castE(c.x,c.z,f.x,f.z)
							end
						end
					end
				end

				castE(target.x, target.z, pos.x, pos.z)  
			end

			if Menu.Harass.useE and ValidTarget(target, skills.E.range + 530) and skills.E.ready then

				pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

				castE(target.x, target.z, pos.x, pos.z)  
			end

			if Menu.Harass.useW and ValidTarget(target, skills.W.range) and skills.W.ready then

				pos, info = Prodiction.GetPrediction(target, skills.W.range, skills.W.speed, skills.W.delay, skills.W.width)

				CastSpell(_W, pos.x, pos.z)

			end

		end
		
	end
end

-- End Harass --

-- Combo Selector --

function Combo()
	local typeCombo = 0
	if target ~= nil then
		AllInCombo(target, 0)
	end
	
end

-- Combo Selector --

-- All In Combo -- 

function AllInCombo(target, typeCombo)
	if target ~= nil and typeCombo == 0 then
		ItemUsage(target)

		if Menu.ViktorCombo.qSet.useQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then

			CastSpell(_Q, target)

		end

		if Menu.ViktorCombo.eSet.useE and ValidTarget(target, skills.E.range) and skills.E.ready then

			pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

			-- Ryuk's E cast Logic --

			nearUnit = nearEnemy(target, skills.E.range)

			if nearUnit then
				pos2 = Prodiction.GetPrediction(nearUnit, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

				if GetDistance((nearUnit or target)) > 540 and pos ~= nil and pos2 ~= nil then
						--
						m = (pos.z - pos2.z)/(pos.x - pos2.x)
						b = pos.z - (m*pos.x)

						x = (- 500 - b)/(m-1)
						z = (m*x) + b
						--
						castE(x,z,pos.x,pos.z)
					else
						if pos and pos2 then
							c = nil
							f = nil
							if GetDistance(nearUnit) > GetDistance(target) then
								c = pos
								f = pos2
							else
								c = pos2
								f = pos

								castE(c.x,c.z,f.x,f.z)
							end
						end
					end
				end
				castE(target.x, target.z, pos.x, pos.z) 
			end
		end

		if Menu.ViktorCombo.wSet.useW and ValidTarget(target, skills.W.range) and skills.W.ready then

			pos, info = Prodiction.GetPrediction(target, skills.W.range, skills.W.speed, skills.W.delay, skills.W.width)

			CastSpell(_W, pos.x, pos.z)

		end

		if Menu.ViktorCombo.rSet.useR and ValidTarget(target, skills.R.range) and skills.R.ready then
			rDmg = getDmg("R", target, myHero)
			
			if not target.canMove then
				CastSpell(_R, target.x, target.z)
			else
				if target.health < rDmg then
					CastSpell(_R, target.x, target.z)
				end
			end

		end
end

-- All In Combo --


function LaneClear()
	for i, target in pairs(targetMinions.objects) do
		if target ~= nil then
			
			if Menu.Laneclear.useClearQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then
				CastSpell(_Q, target)
			end

			if Menu.Laneclear.useClearW and ValidTarget(target, skills.W.range) and skills.W.ready then
				CastSpell(_W, target.x, target.z)
			end

			if Menu.Laneclear.useClearE and ValidTarget(target, skills.E.range) and skills.E.ready then
				pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

				-- Ryuk's E cast Logic --

				nearUnit = nearMinion(target, skills.E.range)
				if nearUnit then
					pos2 = Prodiction.GetPrediction(nearUnit, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)
					if GetDistance((nearUnit or target)) > 540 and pos ~= nil and pos2 ~= nil then
							--
							m = (pos.z - pos2.z)/(pos.x - pos2.x)
							b = pos.z - (m*pos.x)

							x = (- 500 - b)/(m-1)
							z = (m*x) + b
							--
							castE(x,z,pos.x,pos.z)
						else
							if pos and pos2 then
								c = nil
								f = nil
								if GetDistance(nearUnit) > GetDistance(target) then
									c = pos
									f = pos2
								else
									c = pos2
									f = pos

									castE(c.x,c.z,f.x,f.z)
								end
							end
						end
					end
				else
					castE(target.x + 100, target.z + 100, pos.x, pos.z) 
				end
			end
		
	end
end

function JungleClear()
	for i, target in pairs(jungleMinions.objects) do
		if target ~= nil then
			if Menu.Jungleclear.useClearQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then
				CastSpell(_Q, target)
			end

			if Menu.Jungleclear.useClearW and ValidTarget(target, skills.W.range) and skills.W.ready then
				CastSpell(_W, target.x, target.z)
			end

			if Menu.Jungleclear.useClearE and ValidTarget(target, skills.E.range) and skills.E.ready then
				pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

				-- Ryuk's E cast Logic --

				nearUnit = nearJungleMinion(target, skills.E.range)
				if nearUnit then
					pos2 = Prodiction.GetPrediction(nearUnit, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)
					if GetDistance((nearUnit or target)) > 540 and pos ~= nil and pos2 ~= nil then
							--
							m = (pos.z - pos2.z)/(pos.x - pos2.x)
							b = pos.z - (m*pos.x)

							x = (- 500 - b)/(m-1)
							z = (m*x) + b
							--
							castE(x,z,pos.x,pos.z)
						else
							if pos and pos2 then
								c = nil
								f = nil
								if GetDistance(nearUnit) > GetDistance(target) then
									c = pos
									f = pos2
								else
									c = pos2
									f = pos

									castE(c.x,c.z,f.x,f.z)
								end
							end
					end
				else
					castE(target.x + 100, target.z + 100, pos.x, pos.z) 
				end
			end
		end
	end
end

function AutoLevel()
	local qL, wL, eL, rL = player:GetSpellData(_Q).level + qOff, player:GetSpellData(_W).level + wOff, player:GetSpellData(_E).level + eOff, player:GetSpellData(_R).level + rOff
	if qL + wL + eL + rL < player.level then
		local spellSlot = { SPELL_1, SPELL_2, SPELL_3, SPELL_4, }
		local level = { 0, 0, 0, 0 }
		for i = 1, player.level, 1 do
			level[abilitySequence[i]] = level[abilitySequence[i]] + 1
		end
		for i, v in ipairs({ qL, wL, eL, rL }) do
			if v < level[i] then LevelSpell(spellSlot[i]) end
		end
	end
end

function KillSteal()
	if Menu.Ads.KS.useQ or Menu.Ads.KS.useE or Menu.Ads.KS.useR  then KSR() end
	if Menu.Ads.KS.ignite then
		IgniteKS()
	end
end


function nearEnemy(unit,range)
	count = nil
	current = nil
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if enemy.charName ~= unit.charName and GetDistance(enemy) < range then
			if count == nil then
				count = enemy.health
				current = enemy
			end
			if count > enemy.health then
				count = enemy.health
				current = enemy
			end
		end
	end
	return current
end

function nearMinion(unit,range)
	count = nil
	current = nil
	for i, target in ipairs(targetMinions.objects) do
		if target.charName ~= unit.charName and GetDistance(target) < range then
			if count == nil then
				count = target.health
				current = target
			end
			if count > target.health then
				count = target.health
				current = target
			end
		end
	end
	return current
end

function nearJungleMinion(unit,range)
	count = nil
	current = nil
	for i, target in ipairs(jungleMinions.objects) do
		if target.charName ~= unit.charName and GetDistance(target) < range then
			if count == nil then
				count = target.health
				current = target
			end
			if count > target.health then
				count = target.health
				current = target
			end
		end
	end
	return current
end

-- Auto Ignite get the maximum range to avoid over kill --

function KSR()
	local Enemies = GetEnemyHeroes()
	for i, target in ipairs(Enemies) do
		if Menu.Ads.KS.useQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then
			Dmg = getDmg("Q", target, myHero)

			if target.health < Dmg then
				CastSpell(_Q, target)
			end
		elseif Menu.Ads.KS.useR and ValidTarget(target, skills.E.range) and skills.E.ready then
			Dmg = getDmg("E", target, myHero)

			if target.health < Dmg then
				pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

				castE(target.x + 100, target.z + 100, pos.x, pos.z)
			end
		elseif Menu.Ads.KS.useR and ValidTarget(target, skills.R.range) and skills.R.ready then
			Dmg = getDmg("R", target, myHero)

			if target.health < Dmg then
				CastSpell(_R, target.x, target.z)
			end
		end
	end
end

function IgniteKS()
	if igniteReady then
		local Enemies = GetEnemyHeroes()
		for i, val in ipairs(Enemies) do
			if ValidTarget(val, 600) then
				if getDmg("IGNITE", val, myHero) > val.health and GetDistance(val) >= Menu.Ads.KS.igniteRange then
					CastSpell(ignite, val)
				end
			end
		end
	end
end

-- Auto Ignite --

function HealthCheck(unit, HealthValue)
	if unit.health > (unit.maxHealth * (HealthValue/100)) then 
		return true
	else
		return false
	end
end

function animationCancel(unit, spell)
	if spell.name == "ViktorDeathRay" or spell.name == "ViktorGravitonField" or spell.name == "ViktorChaosStorm" then
		AnimationCancel[Menu.Ads.cancel]()
	end
end

function ItemUsage(target)

	if dfgReady then CastSpell(dfgSlot, target) end
	if youmuuReady then CastSpell(youmuuSlot, target) end
	if bilgeReady then CastSpell(bilgeSlot, target) end
	if bladeReady then CastSpell(bladeSlot, target) end
	if divineReady then CastSpell(divineSlot, target) end

end

function OnProcessSpell(unit, spell)
	if unit.isMe then
		animationCancel(unit,spell)
	end
end

function castE(sx,sz,dx,dz)
	if skills.E.ready then
		Packet('S_CAST', { spellId = _E, fromX = sx, fromY = sz, toX = dx, toY = dz }):send()
	end
end

-- Change skin function, made by Shalzuth
function GenModelPacket(champ, skinId)
	p = CLoLPacket(0x97)
	p:EncodeF(myHero.networkID)
	p.pos = 1
	t1 = p:Decode1()
	t2 = p:Decode1()
	t3 = p:Decode1()
	t4 = p:Decode1()
	p:Encode1(t1)
	p:Encode1(t2)
	p:Encode1(t3)
	p:Encode1(bit32.band(t4,0xB))
	p:Encode1(1)--hardcode 1 bitfield
	p:Encode4(skinId)
	for i = 1, #champ do
		p:Encode1(string.byte(champ:sub(i,i)))
	end
	for i = #champ + 1, 64 do
		p:Encode1(0)
	end
	p:Hide()
	RecvPacket(p)
end

function skinChanged()
	return Menu.Ads.VIP.skin1 ~= lastSkin
end

function OnDraw()
	if Menu.drawings.text then
		for i = 1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) and enemy ~= nil then
			local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z)) --(Credit to Zikkah)
			local PosX = barPos.x - 35
			local PosY = barPos.y - 10
			if KillText[i] ~= 10 then
				DrawText(TextList[KillText[i]], 16, PosX, PosY, colorText)
			else
				DrawText(TextList[KillText[i]] .. string.format("%4.1f", ((enemy.health - (qDmg + pDmg + eDmg + itemsDmg)) * (1/rDmg)) * 2.5) .. "s = Kill", 16, PosX, PosY, colorText)
			end
		end
	end
	end
end

-- Damage Calculation Thanks Skeem for the base --

function DamageCalculation()

	for i=1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
		if ValidTarget(enemy) and enemy ~= nil then
			
			qDmg = getDmg("Q",enemy,myHero)
			eDmg = getDmg("E",enemy,myHero)
			rDmg = getDmg("R",enemy,myHero)

			if not skills.Q.ready and not skills.E.ready and not skills.R.ready then
				KillText[i] = 9
			elseif enemy.health <= qDmg then
				KillText[i] = 2
			elseif enemy.health <= eDmg then
				KillText[i] = 3
			elseif enemy.health <= rDmg then
				KillText[i] = 4
			elseif enemy.health <= qDmg + eDmg then
				KillText[i] = 5
			elseif enemy.health <= qDmg + eDmg + rDmg then
				KillText[i] = 7
			else
				KillText[i] = 1
			end
		end
	end
end