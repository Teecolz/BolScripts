--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/

]]

if myHero.charName ~= "Tristana" then return end


local version = 0.45
local AUTOUPDATE = true


local SCRIPT_NAME = "TristanaMechanics"
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
local abilitySequence = {3, 2, 3, 1, 3, 4, 1, 1, 1, 1, 4, 2, 2, 2, 2, 4, 3, 3}
local Ranges = { AA = 550 }
local skills = {
    SkillQ = { ready = false, name = myHero:GetSpellData(_Q).name, range = Ranges.AA, delay = myHero:GetSpellData(_Q).delayTotalTimePercent, speed = myHero:GetSpellData(_Q).missileSpeed, width = myHero:GetSpellData(_Q).lineWidth },
	SkillW = { ready = false, name = myHero:GetSpellData(_W).name, range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delayTotalTimePercent, speed = myHero:GetSpellData(_W).missileSpeed, width = myHero:GetSpellData(_W).lineWidth },
	SkillE = { ready = false, name = myHero:GetSpellData(_E).name, range = Ranges.AA, delay = myHero:GetSpellData(_E).delayTotalTimePercent, speed = myHero:GetSpellData(_E).missileSpeed, width = myHero:GetSpellData(_E).lineWidth },
	SkillR = { ready = false, name = myHero:GetSpellData(_R).name, range = Ranges.AA, delay = myHero:GetSpellData(_R).delayTotalTimePercent, speed = myHero:GetSpellData(_R).missileSpeed, width = myHero:GetSpellData(_R).lineWidth },
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

--[[Auto Attacks]]--
local lastBasicAttack = 0
local swingDelay = 0.25
local swing = false

--[[Misc]]--
local lastSkin = 0
local isSAC = false
local isMMA = false
local target = nil

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
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 900)
	
	Menu = scriptConfig("Tristana Mechanics by Mr Articuno", "TristanaMA")

	if _G.MMA_Loaded ~= nil then
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
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "TristanaCombo")
	Menu.TristanaCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.TristanaCombo:addSubMenu("Q Settings", "qSet")
	Menu.TristanaCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.TristanaCombo:addSubMenu("W Settings", "wSet")
	Menu.TristanaCombo.wSet:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Menu.TristanaCombo.wSet:addParam("wAp", "AP Tristana", SCRIPT_PARAM_ONOFF, false)
	Menu.TristanaCombo:addSubMenu("E Settings", "eSet")
	Menu.TristanaCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.TristanaCombo:addSubMenu("R Settings", "rSet")
	Menu.TristanaCombo.rSet:addParam("useR", "Use Smart Ultimate", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Harass]", "Harass")
	Menu.Harass:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	Menu.Harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useE", "Use E in Harass", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Laneclear]", "Laneclear")
	Menu.Laneclear:addParam("lclr", "Laneclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Laneclear:addParam("useClearQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Laneclear:addParam("useClearW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Laneclear:addParam("useClearE", "Use E in Laneclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Jungleclear]", "Jungleclear")
	Menu.Jungleclear:addParam("jclr", "Jungleclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Jungleclear:addParam("useClearQ", "Use Q in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungleclear:addParam("useClearW", "Use W in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungleclear:addParam("useClearE", "Use E in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Additionals]", "Ads")
	Menu.Ads:addParam("cancel", "Animation Cancel", SCRIPT_PARAM_LIST, 1, { "Move","Laugh","Dance","Taunt","joke","Nothing" })
	AddProcessSpellCallback(function(unit, spell)
		animationCancel(unit,spell)
	end)
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Killsteal", "KS")
	Menu.Ads.KS:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("igniteRange", "Minimum range to cast Ignite", SCRIPT_PARAM_SLICE, 470, 0, 600, 0)
	Menu.Ads:addSubMenu("VIP", "VIP")
	--Menu.Ads.VIP:addParam("spellCast", "Spell by Packet", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.VIP:addParam("skin", "Use custom skin", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin1", "Skin changer", SCRIPT_PARAM_SLICE, 1, 1, 7)
	
	Menu:addSubMenu("["..myHero.charName.." - Target Selector]", "targetSelector")
	Menu.targetSelector:addTS(ts)
	ts.name = "Focus"
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
	local DManager = DrawManager()
	DManager:CreateCircle(myHero, Ranges.AA, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"AA range", true, true, true)
	DManager:CreateCircle(myHero, skills.SkillQ.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"Q range", true, true, true)
	DManager:CreateCircle(myHero, skills.SkillW.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"W range", true, true, true)
	DManager:CreateCircle(myHero, skills.SkillE.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"E range", true, true, true)
	
	targetMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Tristana", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end
	
	PrintChat("<font color = \"#33CCCC\">Tristana Mechanics by</font> <font color = \"#fff8e7\">Mr Articuno</font>")
end

function OnTick()
	target = GetCustomTarget()
	targetMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()

	if Menu.Ads.VIP.skin and VIP_USER and skinChanged() then
		GenModelPacket("Tristana", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end

	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.TristanaCombo.combo then
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
	skills.SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	skills.SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	skills.SkillE.ready = (myHero:CanUseSpell(_E) == READY)
	skills.SkillR.ready = (myHero:CanUseSpell(_R) == READY)
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

	Ranges.AA = 550 + (myHero.level * 8.5)

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
		if Menu.Harass.useE and ValidTarget(target, skills.SkillE.range) and skills.SkillE.ready then
			CastSpell(_E, target)
		end

		if Menu.Harass.useQ and ValidTarget(target, Ranges.AA) and skills.SkillQ.ready then
			CastSpell(_Q)
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
		if skills.SkillR.ready and Menu.TristanaCombo.rSet.useR and ValidTarget(target, skills.SkillR.range) then
			rDmg = getDmg("R", target, myHero)

			if skills.SkillR.ready and target ~= nil and ValidTarget(target, 645) and target.health < rDmg then
				CastSpell(_R, target)
			end
		end
		if Menu.TristanaCombo.eSet.useE and ValidTarget(target, Ranges.AA) and skills.SkillE.ready then
			CastSpell(_E, target)
		end

		if Menu.TristanaCombo.qSet.useQ and ValidTarget(target, Ranges.AA) and skills.SkillQ.ready then
			CastSpell(_Q)
		end

		if Menu.TristanaCombo.wSet.useW and ValidTarget(target, skills.SkillW.range) and skills.SkillW.ready then
			if Menu.TristanaCombo.wSet.wAp then
				local wPosition, wChance = VP:GetCircularCastPosition(target, skills.SkillW.delay, skills.SkillW.width, skills.SkillW.range, skills.SkillW.speed, myHero, true)

			    if wPosition ~= nil and GetDistance(wPosition) < skills.SkillW.range and wChance >= 2 then
			      CastSpell(_W, wPosition.x, wPosition.z)
			    end
			else
				wDmg = getDmg("W", target, myHero)
				if skills.SkillW.ready and target ~= nil and ValidTarget(target, skills.SkillW.range) and target.health < wDmg then
					local wPosition, wChance = VP:GetCircularCastPosition(target, skills.SkillW.delay, skills.SkillW.width, skills.SkillW.range, skills.SkillW.speed, myHero, true)

				    if wPosition ~= nil and GetDistance(wPosition) < skills.SkillW.range and wChance >= 2 then
				      CastSpell(_W, wPosition.x, wPosition.z)
				    end
				end
			end
		end
	end
end

-- All In Combo --


function LaneClear()
	for i, targetMinion in pairs(targetMinions.objects) do
		if targetMinion ~= nil then
			if Menu.Laneclear.useClearQ and skills.SkillQ.ready and ValidTarget(targetMinion, Ranges.AA) then
				CastSpell(_Q)
			end
			if Menu.Laneclear.useClearW and skills.SkillW.ready and ValidTarget(targetMinion, skills.SkillW.range) then
				CastSpell(_W, targetMinion)
			end
			if Menu.Laneclear.useClearE and skills.SkillE.ready and ValidTarget(targetMinion, Ranges.AA) then
				CastSpell(_E, targetMinion)
			end
		end
		
	end
end

function JungleClear()
	for i, jungleMinion in pairs(jungleMinions.objects) do
		if jungleMinion ~= nil then
			if Menu.Jungleclear.useClearQ and skills.SkillQ.ready and ValidTarget(jungleMinion, Ranges.AA) then
				CastSpell(_Q)
			end
			if Menu.Jungleclear.useClearW and skills.SkillW.ready and ValidTarget(jungleMinion, skills.SkillW.range) then
				CastSpell(_W, jungleMinion)
			end
			if Menu.Jungleclear.useClearE and skills.SkillE.ready and ValidTarget(jungleMinion, Ranges.AA) then
				CastSpell(_E, jungleMinion)
			end

			if jungleMinion.name == "Dragon6.1.1" or jungleMinion.name == "Worm12.1.1" then
				rDmg = getDmg("R", jungleMinion, myHero)

				if skills.SkillR.ready and jungleMinion ~= nil and ValidTarget(jungleMinion, skills.SkillR.range) and jungleMinion.health < rDmg then
					CastSpell(_R, jungleMinion)
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
	if Menu.Ads.KS.useR then
		KSR()
	end
	if Menu.Ads.KS.ignite then
		IgniteKS()
	end
end

-- Use Ultimate --

function KSR()
	for i, target in ipairs(GetEnemyHeroes()) do
		rDmg = getDmg("R", target, myHero)

		if skills.SkillR.ready and target ~= nil and ValidTarget(target, 645) and target.health < rDmg then
			CastSpell(_R, target)
		elseif skills.SkillR.ready and skills.SkillW.ready and target ~= nil and ValidTarget(target, 645 + skills.SkillW.range) and target.health < rDmg and Menu.Ads.KS.useW then
			CastSpell(_W, target.x, target.z)
			CastSpell(_R, target)
		end
	end
end

-- Use Ultimate --

-- Auto Ignite get the maximum range to avoid over kill --

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
	if not unit.isMe then return end

end

function ItemUsage(target)

	if dfgReady then CastSpell(dfgSlot, target) end
	if youmuuReady then CastSpell(youmuuSlot, target) end
	if bilgeReady then CastSpell(bilgeSlot, target) end
	if bladeReady then CastSpell(bladeSlot, target) end
	if divineReady then CastSpell(divineSlot, target) end

end

function animationCancel(unit, spell)
	if not unit.isMe then return end

	if spell.name == 'BusterShot' then -- _R
		AnimationCancel[Menu.Ads.cancel]()
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
	
end