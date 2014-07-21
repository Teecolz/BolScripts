--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/

]]

if myHero.charName ~= "Jinx" then return end


local version = 0.42
local AUTOUPDATE = true


local SCRIPT_NAME = "JinxMechanics"
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
local abilitySequence = {1, 2, 1, 3, 1, 4, 1, 2, 1, 2, 4, 2, 2, 3, 3, 4, 3, 3}
local Ranges = { AA = 525 }
local skills = {
  Q = {ready = false, spellName = "Switcheroo", range = Ranges.AA + 25, speed = 2000, delay = .25, width = 160},
  W = {ready = false, spellName = "Zap", range = 1500, speed = 1600, delay = .25, width = 80},
  E = {ready = false, spellName = "Flame Chompers", range = 900, speed = 1600, delay = .25, width = 80},
  R = {ready = false, spellName = "Super Mega Death Rocket", range = math.huge, speed = 2000, delay = .50, width = 400},
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

local BRKSlot, DFGSlot, HXGSlot, BWCSlot, TMTSlot, RAHSlot, RNDSlot, YGBSlot = nil, nil, nil, nil, nil, nil, nil, nil
local BRKREADY, DFGREADY, HXGREADY, BWCREADY, TMTREADY, RAHREADY, RNDREADY, YGBREADY = false, false, false, false, false, false, false, false

--[[Auto Attacks]]--
local lastBasicAttack = 0
local swingDelay = 0.25
local swing = false
local miniGun = true

--[[Misc]]--
local lastSkin = 0
local isSAC = false
local isMMA = false
local target = nil

--[[ Kill Text ]]--
TextList = {"Harass him", "W", "ULT HIM !", "W+R", "Skills Not Ready"}
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
	ts = TargetSelector(TARGET_NEAR_MOUSE, 900)
	
	Menu = scriptConfig("Jinx Mechanics by Mr Articuno", "JinxMA")
	
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
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "JinxCombo")
	Menu.JinxCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.JinxCombo:addSubMenu("Q Settings", "qSet")
	Menu.JinxCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.JinxCombo:addSubMenu("W Settings", "wSet")
	Menu.JinxCombo.wSet:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.JinxCombo:addSubMenu("E Settings", "eSet")
	Menu.JinxCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.JinxCombo:addSubMenu("R Settings", "rSet")
	Menu.JinxCombo.rSet:addParam("useR", "Use Smart Ultimate", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Harass]", "Harass")
	Menu.Harass:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	Menu.Harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useE", "Use E in Harass", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Laneclear]", "Laneclear")
	Menu.Laneclear:addParam("lclr", "Laneclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Laneclear:addParam("useClearQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Laneclear:addParam("useClearW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Jungleclear]", "Jungleclear")
	Menu.Jungleclear:addParam("jclr", "Jungleclear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	Menu.Jungleclear:addParam("useClearQ", "Use Q in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	Menu.Jungleclear:addParam("useClearW", "Use W in Jungleclear", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("["..myHero.charName.." - Additionals]", "Ads")
	Menu.Ads:addParam("cancel", "Animation Cancel", SCRIPT_PARAM_LIST, 1, { "Move","Laugh","Dance","Taunt","joke","Nothing" })
	AddProcessSpellCallback(function(unit, spell)
	end)
	Menu.Ads:addParam("antiGapCloser", "Anti Gap Closer", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addParam("autoSnare", "Auto-Snare if enemy cannot move", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Killsteal", "KS")
	Menu.Ads.KS:addParam("useR", "Recall Ultimate", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("igniteRange", "Minimum range to cast Ignite", SCRIPT_PARAM_SLICE, 470, 0, 600, 0)
	Menu.Ads:addSubMenu("VIP", "VIP")
	Menu.Ads.VIP:addParam("spellCast", "Spell by Packet", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.VIP:addParam("skin", "Use custom skin (Requires Reload)", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin1", "Skin changer", SCRIPT_PARAM_SLICE, 1, 1, 2)
	
	Menu:addSubMenu("["..myHero.charName.." - Target Selector]", "targetSelector")
	Menu.targetSelector:addTS(ts)
	ts.name = "Focus"
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
	local DManager = DrawManager()
	Menu.drawings:addParam("text", "Draw Texts", SCRIPT_PARAM_ONOFF, true)
	DManager:CreateCircle(myHero, Ranges.AA, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"AA range", true, true, true)
	DManager:CreateCircle(myHero, skills.Q.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"Q range", true, true, true)
	DManager:CreateCircle(myHero, skills.W.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"W range", true, true, true)
	DManager:CreateCircle(myHero, skills.E.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"E range", true, true, true)
	
	targetMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Jinx", Menu.Ads.VIP.skin1)
	end
	
	PrintChat("<font color = \"#33CCCC\">Jinx Mechanics by</font> <font color = \"#fff8e7\">Mr Articuno V"..version.."</font>")
	PrintChat("<font color = \"#4693e0\">Sponsored by www.RefsPlea.se</font> <font color = \"#d6ebff\"> - A League of Legends Referrals service. Get RP cheaper!</font>")
end

function OnTick()
	target = GetCustomTarget()
	targetMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()

	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot, BRKSlot, TMTSlot, RAHSlot, RNDSlot, STDSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3057), GetInventorySlotItem(3078), GetInventorySlotItem(3100), GetInventorySlotItem(3153), GetInventorySlotItem(3077), GetInventorySlotItem(3074), GetInventorySlotItem(3143), GetInventorySlotItem(3131)
	DFGREADY = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	HXGREADY = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
	BWCREADY = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
	BRKREADY = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
	TMTREADY = (TMTSlot ~= nil and myHero:CanUseSpell(TMTSlot) == READY)
	RAHREADY = (RAHSlot ~= nil and myHero:CanUseSpell(RAHSlot) == READY)
	RNDREADY = (RNDSlot ~= nil and myHero:CanUseSpell(RNDSlot) == READY)
	STDREADY = (STDSlot ~= nil and myHero:CanUseSpell(STDSlot) == READY)
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)

	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.JinxCombo.combo then
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
	-- Items
	tiamatSlot = GetInventorySlotItem(3077)
	hydraSlot = GetInventorySlotItem(3074)
	youmuuSlot = GetInventorySlotItem(3142) 
	bilgeSlot = GetInventorySlotItem(3144)
	bladeSlot = GetInventorySlotItem(3153)
	DamageCalculation()

	tiamatReady = (tiamatSlot ~= nil and myHero:CanUseSpell(tiamatSlot) == READY)
	hydraReady = (hydraSlot ~= nil and myHero:CanUseSpell(hydraSlot) == READY)
	youmuuReady = (youmuuSlot ~= nil and myHero:CanUseSpell(youmuuSlot) == READY)
	bilgeReady = (bilgeSlot ~= nil and myHero:CanUseSpell(bilgeSlot) == READY)
	bladeReady = (bladeSlot ~= nil and myHero:CanUseSpell(bladeSlot) == READY)

	skills.Q.range = Ranges.AA + (myHero:GetSpellData(_Q).level * 25)

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
		if Menu.Harass.useE and ValidTarget(target, skills.E.range) and skills.E.ready then
			local ePosition, eChance = VP:GetCircularCastPosition(target, skills.E.delay, skills.E.width, skills.E.range, skills.E.speed, myHero, false)

		    if ePosition ~= nil and GetDistance(ePosition) < skills.E.range and eChance >= 2 then
		      CastSpell(_E, ePosition.x, ePosition.z)
		    end
		end
		if skills.W.ready and Menu.Harass.useW and ValidTarget(target, skills.W.range) then
			local wPosition, wChance = VP:GetLineCastPosition(target, skills.W.delay, skills.W.width, skills.W.range, skills.W.speed, myHero, true)

		    if wPosition ~= nil and GetDistance(wPosition) < skills.W.range and wChance >= 2 then
		      CastSpell(_W, wPosition.x, wPosition.z)
		    end
		end
		if skills.Q.ready and Menu.Harass.useQ and ValidTarget(target, skills.Q.range) and not ValidTarget(target, Ranges.AA) and miniGun then
			CastSpell(_Q)
		end
		if skills.Q.ready and Menu.Harass.useQ and ValidTarget(target, Ranges.AA) and not miniGun then
			CastSpell(_Q)
		end
	end
	
end

-- End Harass --


-- Combo Selector --

function Combo()
	local typeCombo = 0
	if target ~= nil then
		AllInCombo(0)
	end
	
end

-- Combo Selector --

-- All In Combo -- 

function AllInCombo(typeCombo)
	if target ~= nil and typeCombo == 0 then
		if skills.R.ready and Menu.JinxCombo.rSet.useR and ValidTarget(target, 3500) then
			rDmg = getDmg("R", target, myHero)

			if skills.R.ready and target ~= nil and ValidTarget(target, Ranges.R) and target.health < rDmg then
				local rPosition, rChance = VP:GetLineCastPosition(target, skills.R.delay, skills.R.width, skills.R.range, skills.R.speed, myHero, false)

			    if rPosition ~= nil and rChance >= 2 then
			      CastSpell(_R, rPosition.x, rPosition.z)
			    end
			end
		end
		if Menu.JinxCombo.eSet.useE and ValidTarget(target, skills.E.range) and skills.E.ready then
			local ePosition, eChance = VP:GetCircularCastPosition(target, skills.E.delay, skills.E.width, skills.E.range, skills.E.speed, myHero, false)

		    if ePosition ~= nil and GetDistance(ePosition) < skills.E.range and eChance >= 2 then
		      CastSpell(_E, ePosition.x, ePosition.z)
		    end
		end
		if skills.W.ready and Menu.JinxCombo.wSet.useW and ValidTarget(target, skills.W.range) then
			local wPosition, wChance = VP:GetLineCastPosition(target, skills.W.delay, skills.W.width, skills.W.range, skills.W.speed, myHero, true)

		    if wPosition ~= nil and GetDistance(wPosition) < skills.W.range and wChance >= 2 then
		      CastSpell(_W, wPosition.x, wPosition.z)
		    end
		end
		if skills.Q.ready and Menu.JinxCombo.qSet.useQ and ValidTarget(target, skills.Q.range) and not ValidTarget(target, Ranges.AA) and miniGun then
			CastSpell(_Q)
		end
		if skills.Q.ready and Menu.JinxCombo.qSet.useQ and ValidTarget(target, Ranges.AA) and not miniGun then
			CastSpell(_Q)
		end
	end
end

-- All In Combo --


function LaneClear()
	for i, targetMinion in pairs(targetMinions.objects) do
		if targetMinion ~= nil then
			if skills.Q.ready and Menu.Laneclear.useClearQ and ValidTarget(jungleMinion, skills.Q.range) and not ValidTarget(jungleMinion, Ranges.AA) and miniGun then
				CastSpell(_Q)
			end
			if skills.Q.ready and Menu.Laneclear.useClearQ and ValidTarget(jungleMinion, Ranges.AA) and not miniGun then
				CastSpell(_Q)
			end
			if skills.W.ready and Menu.Laneclear.useClearW and ValidTarget(jungleMinion, Ranges.W) then
				CastSpell(_W, targetMinion.x, targetMinion.z)
			end
		end
	end
end

function JungleClear()
	for i, jungleMinion in pairs(jungleMinions.objects) do
		if jungleMinion ~= nil then
			if skills.Q.ready and Menu.Jungleclear.useClearQ and ValidTarget(jungleMinion, skills.Q.range) and not ValidTarget(jungleMinion, Ranges.AA) and miniGun then
				CastSpell(_Q)
			end
			if skills.Q.ready and Menu.Jungleclear.useClearQ and ValidTarget(jungleMinion, Ranges.AA) and not miniGun then
				CastSpell(_Q)
			end
			if skills.W.ready and Menu.Jungleclear.useClearW and ValidTarget(jungleMinion, skills.W.range) then
				CastSpell(_W, targetMinion.x, targetMinion.z)
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
	if Menu.Ads.autoSnare then
		Snare()
	end
	if Menu.Ads.KS.ignite then
		IgniteKS()
	end
end

function Snare()
	for i, target in ipairs(GetEnemyHeroes()) do
		if not target.canMove or target.isTaunted or target.isCharmed or target.isFeared then
			local ePosition, eChance = VP:GetCircularCastPosition(target, skills.E.delay, skills.E.width, skills.E.range, skills.E.speed, myHero, false)

		    if ePosition ~= nil and GetDistance(ePosition) < skills.E.range and eChance >= 2 then
		      CastSpell(_E, ePosition.x, ePosition.z)
		    end
		end
	end
end

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

	if DFGREADY then CastSpell(DFGSlot, target) end
	if HXGREADY then CastSpell(HXGSlot, target) end
	if BWCREADY then CastSpell(BWCSlot, target) end
	if BRKREADY then CastSpell(BRKSlot, target) end
	if TMTREADY and GetDistance(target) < 275 then CastSpell(TMTSlot) end
	if RAHREADY and GetDistance(target) < 275 then CastSpell(RAHSlot) end
	if RNDREADY and GetDistance(target) < 275 then CastSpell(RNDSlot) end

end

function OnProcessSpell( unit, spell )
	if unit.isMe then
		if spell.name == 'JinxQ' then
			miniGun = (not miniGun)
		end
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

-- Credit Manciuszz
function OnProcessSpell(unit, spell)
    if not Menu.Ads.antiGapCloser then return end

    local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q 
    local isAGapcloserUnit = {
        ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
        ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
        ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
        ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
        ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
        ['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
        ['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
        ['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
        ['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
        ['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
        ['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
        ['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
        ['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
        ['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
        ['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
        ['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
        ['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
        ['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
        ['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
        ['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
        ['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
        ['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
        ['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
        ['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
        ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
        ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
    }
    if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
        if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
            if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
                if ValidTarget(spell.target, skills.E.range) and skills.E.ready then
					local ePosition, eChance = VP:GetCircularCastPosition(spell.target, skills.E.delay, skills.E.width, skills.E.range, skills.E.speed, myHero, false)

				    if ePosition ~= nil and GetDistance(ePosition) < skills.E.range and eChance >= 2 then
				      CastSpell(_E, ePosition.x, ePosition.z)
				    end
				end
            else
                spellExpired = false
                informationTable = {
                    spellSource = unit,
                    spellCastedTick = GetTickCount(),
                    spellStartPos = Point(spell.startPos.x, spell.startPos.z),
                    spellEndPos = Point(spell.endPos.x, spell.endPos.z),
                    spellRange = isAGapcloserUnit[unit.charName].range,
                    spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
                    spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
                }
            end
        end
    end

end

function OnRecvPacket(p)
	if Menu.KS.useR then
		if p.header = 0xD8 then
			p.pos = 5
			local idUnit = p.DecodeF(p)
			local unit = objManager:GetObjectByNetworkId(idUnit)

			rDmg = getDmg("R", unit, myHero)

			if skills.R.ready and unit ~= nil and ValidTarget(unit, Ranges.R) and unit.health < rDmg then
			    CastSpell(_R, unit.x, unit.z)
			end
		end
	end
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
			
			wDmg = getDmg("E",enemy,myHero)
			rDmg = getDmg("R",enemy,myHero)

			if not skills.W.ready and not skills.R.ready then
				KillText[i] = 9
			elseif enemy.health <= wDmg then
				KillText[i] = 2
			elseif enemy.health <= rDmg then
				KillText[i] = 3
			elseif enemy.health <= wDmg + rDmg then
				KillText[i] = 4
			else
				KillText[i] = 1
			end
		end
	end
end