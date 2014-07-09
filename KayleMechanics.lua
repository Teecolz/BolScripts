--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/

]]

if myHero.charName ~= "Kayle" then return end


local version = 0.2
local AUTOUPDATE = true


local SCRIPT_NAME = "KayleMechanics"
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
	SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/gmlyra/BolScripts/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/gmlyra/BolScripts/VersionFiles/master/"..SCRIPT_NAME..".version"):CheckUpdate()
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
local QREADY, WREADY, EREADY, RREADY = false, false, false, false
local ignite, igniteReady = nil, nil
local ts = nil
local VP = nil
local qOff, wOff, eOff, rOff = 0,0,0,0
local abilitySequence = {3, 1, 1, 2, 1, 4, 1, 3, 1, 3, 4, 3, 3, 2, 2, 4, 2, 2}
local Ranges = { Q = 650, W = 900, E = 400, R = 900 , AA = 125}
local AnimationCancel =
{
	[1]=function() myHero:MoveTo(mousePos.x,mousePos.z) end, --"Move"
	[2]=function() SendChat('/l') end, --"Laugh"
	[3]=function() SendChat('/d') end, --"Dance"
	[4]=function() SendChat('/t') end, --"Taunt"
	[5]=function() SendChat('/j') end, --"joke"
	[6]=function() end,
}

local QREADY, WREADY, EREADY, RREADY= false, false, false, false
local BRKSlot, DFGSlot, HXGSlot, BWCSlot, TMTSlot, RAHSlot, RNDSlot, YGBSlot = nil, nil, nil, nil, nil, nil, nil, nil
local BRKREADY, DFGREADY, HXGREADY, BWCREADY, TMTREADY, RAHREADY, RNDREADY, YGBREADY = false, false, false, false, false, false, false, false

--[[Auto Attacks]]--
local lastBasicAttack = 0
local swingDelay = 0.25
local swing = false

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
	
	Menu = scriptConfig("Kayle Mechanics by Mr Articuno", "KayleMA")
	
	Menu:addSubMenu("["..myHero.charName.." - Orbwalker]", "SOWorb")
	Orbwalker:LoadToMenu(Menu.SOWorb)
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "KayleCombo")
	Menu.KayleCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	-- Menu.KayleCombo:addParam("useF", "Use Flash in Combo ", SCRIPT_PARAM_ONOFF, false)
	Menu.KayleCombo:addSubMenu("Q Settings", "qSet")
	Menu.KayleCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.KayleCombo:addSubMenu("E Settings", "eSet")
	Menu.KayleCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	
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
	Menu.Ads:addSubMenu("Ultimate Settings", "rSet")
	Menu.Ads.rSet:addParam("useR", "Auto Use Ultimate", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.rSet:addParam("rPer", "% of Life to Use R", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)
	Menu.Ads:addSubMenu("Heal Settings", "wSet")
	Menu.Ads.wSet:addParam("useW", "Auto Use Heal", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.wSet:addParam("wPer", "% of Life to Use W", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)
	Menu.Ads:addParam("cancel", "Animation Cancel", SCRIPT_PARAM_LIST, 1, { "Move","Laugh","Dance","Taunt","joke","Nothing" })
	AddProcessSpellCallback(function(unit, spell)
		if unit.isMe and (spell.name:find("Attack") ~= nil) then
            --swing = true
            lastBasicAttack = os.clock()
        end
		animationCancel(unit, spell)
	end)
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Killsteal", "KS")
	Menu.Ads.KS:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.KS:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("igniteRange", "Minimum range to cast Ignite", SCRIPT_PARAM_SLICE, 470, 0, 600, 0)
	Menu.Ads:addSubMenu("VIP", "VIP")
	Menu.Ads.VIP:addParam("spellCast", "Spell by Packet", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.VIP:addParam("skin", "Use custom skin (Requires Reload)", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin1", "Skin changer", SCRIPT_PARAM_SLICE, 1, 1, 7)
	
	Menu:addSubMenu("["..myHero.charName.." - Target Selector]", "targetSelector")
	Menu.targetSelector:addTS(ts)
	ts.name = "Focus"
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
	local DManager = DrawManager()
	DManager:CreateCircle(myHero, Ranges.AA, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"AA range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.Q, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"Q range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.W, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"W range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.E, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"E range", true, true, true)
	DManager:CreateCircle(myHero, Ranges.R, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"R range", true, true, true)
	
	enemyMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Kayle", Menu.Ads.VIP.skin1)
	end
	
	PrintChat("<font color = \"#33CCCC\">Kayle Mechanics by</font> <font color = \"#fff8e7\">Mr Articuno</font>")
end

function OnTick()
	ts:update()
	enemyMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()
	useHeal()
	useUltimate()

	DFGSlot, HXGSlot, BWCSlot, SheenSlot, TrinitySlot, LichBaneSlot, BRKSlot, TMTSlot, RAHSlot, RNDSlot, STDSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3057), GetInventorySlotItem(3078), GetInventorySlotItem(3100), GetInventorySlotItem(3153), GetInventorySlotItem(3077), GetInventorySlotItem(3074), GetInventorySlotItem(3143), GetInventorySlotItem(3131)
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	DFGREADY = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	HXGREADY = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
	BWCREADY = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
	BRKREADY = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
	TMTREADY = (TMTSlot ~= nil and myHero:CanUseSpell(TMTSlot) == READY)
	RAHREADY = (RAHSlot ~= nil and myHero:CanUseSpell(RAHSlot) == READY)
	RNDREADY = (RNDSlot ~= nil and myHero:CanUseSpell(RNDSlot) == READY)
	STDREADY = (STDSlot ~= nil and myHero:CanUseSpell(STDSlot) == READY)
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)

	if swing and os.clock() > lastBasicAttack + 0.625 then
		--swing = false
	end
		
	
	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.KayleCombo.combo then
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
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	-- Items
	tiamatSlot = GetInventorySlotItem(3077)
	hydraSlot = GetInventorySlotItem(3074)
	youmuuSlot = GetInventorySlotItem(3142) 
	bilgeSlot = GetInventorySlotItem(3144)
	bladeSlot = GetInventorySlotItem(3153)
	
	tiamatReady = (tiamatSlot ~= nil and myHero:CanUseSpell(tiamatSlot) == READY)
	hydraReady = (hydraSlot ~= nil and myHero:CanUseSpell(hydraSlot) == READY)
	youmuuReady = (youmuuSlot ~= nil and myHero:CanUseSpell(youmuuSlot) == READY)
	bilgeReady = (bilgeSlot ~= nil and myHero:CanUseSpell(bilgeSlot) == READY)
	bladeReady = (bladeSlot ~= nil and myHero:CanUseSpell(bladeSlot) == READY)
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
	local enemy = ts.target
	
	if enemy ~= nil and ValidTarget(enemy) then
		if Menu.Harass.useE and ValidTarget(target, Ranges.E + Ranges.AA) and EREADY then
			CastSpell(_E)
		end
		if QREADY and Menu.Harass.useQ and ValidTarget(target, Ranges.Q) then
			CastSpell(_Q, target)
		end
	end
	
end

-- End Harass --


-- Combo Selector --

function Combo()
	local typeCombo = 0
	if ts.target ~= nil then
		AllInCombo(ts.target, 0)
	end
	
end

-- Combo Selector --

-- All In Combo -- 

function AllInCombo(target, typeCombo)
	if target ~= nil and typeCombo == 0 then
		useUltimate()
		useHeal()

		if QREADY and Menu.KayleCombo.qSet.useQ and ValidTarget(target, Ranges.Q) then
			CastSpell(_Q, target)
		end
		if Menu.KayleCombo.eSet.useE and ValidTarget(target, Ranges.E + Ranges.AA) and EREADY then
			CastSpell(_E)
		end
	end
end

-- All In Combo --


function LaneClear()
	for i, enemyMinion in pairs(enemyMinions.objects) do
		if enemyMinion ~= nil and ValidTarget(enemyMinion) and Menu.Laneclear.useClearQ and QREADY then
			CastSpell(_Q, enemyMinion)
		end
		if Menu.Laneclear.useClearE and EREADY then
			CastSpell(_E)
		end
		if Menu.Laneclear.useClearW and WREADY then
			CastSpell(_W, myHero)
		end
	end
end

function JungleClear()
	for i, jungleMinion in pairs(jungleMinions.objects) do
		if jungleMinion ~= nil then
			if Menu.Jungleclear.useClearE and EREADY then
				CastSpell(_E)
			end
			if Menu.Jungleclear.useClearQ and QREADY then
				CastSpell(_Q, jungleMinion)
			end
			if Menu.Jungleclear.useClearW and WREADY then
				CastSpell(_W, myHero)
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
	if Menu.Ads.KS.ignite then
		IgniteKS()
	end
end

-- Use Ultimate --

function useUltimate()
	if Menu.Ads.rSet.useR and myHero.health <= myHero.maxHealth * (Menu.Ads.rSet.rPer / 100) then
		local Enemies = GetEnemyHeroes()
		for i, val in ipairs(Enemies) do
			if ValidTarget(val, 900) then
				CastSpell(_R, myHero)
			end
		end
		
	end
end

function useHeal()
	if Menu.Ads.wSet.useW and myHero.health <= myHero.maxHealth * (Menu.Ads.wSet.wPer / 100) then
		CastSpell(_W, myHero)
	end
end

-- Use Ultimate --

-- Auto Ignite get the maximum range to avoid over kill --

function IgniteKS()
	if igniteReady then
		local Enemies = GetEnemyHeroes()
		for i, val in ipairs(Enemies) do
			if ValidTarget(val, 600) then
				if getDmg("IGNITE", val, myHero) > val.health and RReady ~= true and GetDistance(val) >= Menu.Ads.KS.igniteRange then
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


function spellByPacket(spell, target)
	if not VIP_USER then return end

	local offset = spell.windUpTime - GetLatency / 2000

	DelayAction(function()
		Packet('S_CAST', {spellId = spell, targetNetworkId = target.networkID, fromX = target.x, toX = target.x, fromY = target.z, toY = target.z})
	end, offset)
	
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

function OnDraw()
	
end