--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/

]]

if myHero.charName ~= "Nami" then return end


local version = 0.2
local AUTOUPDATE = true


local SCRIPT_NAME = "NamiMechanics"
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
local abilitySequence = {2, 1, 3, 2, 2, 4, 2, 1, 2, 1, 4, 1, 1, 3, 3, 4, 3, 3}
local Ranges = { AA = 550 }
local skills = {
    Q = { ready = false, name = myHero:GetSpellData(_Q).name, range = 875, delay = 0.5, speed = 1750, width = 200 },
	W = { ready = false, name = myHero:GetSpellData(_W).name, range = 725, delay = 0.5, speed = 1100, width = 0 },
	E = { ready = false, name = myHero:GetSpellData(_E).name, range = 800, delay = 0.5, speed = math.huge, width = 0 },
	R = { ready = false, name = myHero:GetSpellData(_R).name, range = 2550, delay = 0.5, speed = 1200, width = 550 },
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
local focusTarget = nil

-- [[ VIP Variables]] --
local Prodict


--Credit Trees
function GetCustomTarget()
	ts:update()
	if focusTarget ~= nil and not focusTarget.dead and Menu.targetSelector.focusPriority then return focusTarget end
	if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
	if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
	return ts.target
end

function OnLoad()
	if _G.ScriptLoaded then	return end
	_G.ScriptLoaded = true
	initComponents()
	analytics()
end

function initComponents()
	-- VPrediction Start
	VP = VPrediction()
	-- SOW Declare
	Orbwalker = SOW(VP)
	-- Target Selector
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 2550)
	
	Menu = scriptConfig("Nami Mechanics by Mr Articuno", "NamiMA")

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

	if VIP_USER then
		require 'Prodiction'
		require 'Collision'
		Prodict = ProdictManager.GetInstance()
	end
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "NamiCombo")
	Menu.NamiCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.NamiCombo:addSubMenu("Q Settings", "qSet")
	Menu.NamiCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.NamiCombo:addSubMenu("W Settings", "wSet")
	Menu.NamiCombo.wSet:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Menu.NamiCombo:addSubMenu("E Settings", "eSet")
	Menu.NamiCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.NamiCombo:addSubMenu("R Settings", "rSet")
	Menu.NamiCombo.rSet:addParam("useR", "Use Smart Ultimate", SCRIPT_PARAM_ONOFF, true)
	Menu.NamiCombo.rSet:addParam("minimumEnemies", "Minimum Targets to Ult", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	
	Menu:addSubMenu("["..myHero.charName.." - Harass]", "Harass")
	Menu.Harass:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	Menu.Harass:addParam("harassToggle", "Harass", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("K"))
	Menu.Harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
	Menu.Harass:addParam("useE", "Use E in Harass", SCRIPT_PARAM_ONOFF, false)
	
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
	AddProcessSpellCallback(function(unit, spell)
		animationCancel(unit,spell)
	end)
	Menu.Ads:addParam("antiGapCloser", "Anti Gap Closer", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addParam("autoSnare", "Auto Q if Target Cannot Move", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Killsteal", "KS")
	Menu.Ads.KS:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.KS:addParam("igniteRange", "Minimum range to cast Ignite", SCRIPT_PARAM_SLICE, 470, 0, 600, 0)
	Menu.Ads:addSubMenu("VIP", "VIP")
	Menu.Ads.VIP:addParam("prodiction", "Use prodiction", SCRIPT_PARAM_ONOFF, true)
	Menu.Ads.VIP:addParam("skin", "Use custom skin", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads.VIP:addParam("skin1", "Skin changer", SCRIPT_PARAM_SLICE, 1, 1, 3)
	
	Menu:addSubMenu("["..myHero.charName.." - Target Selector]", "targetSelector")
	Menu.targetSelector:addTS(ts)
	ts.name = "Focus"
	Menu.targetSelector:addParam("focusPriority", "Force Combo Selected Target", SCRIPT_PARAM_ONOFF, false)
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
	local DManager = DrawManager()
	DManager:CreateCircle(myHero, Ranges.AA + (myHero.level * 8.5), 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"AA range", true, true, true)
	DManager:CreateCircle(myHero, skills.Q.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"Q range", true, true, true)
	DManager:CreateCircle(myHero, skills.W.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"W range", true, true, true)
	DManager:CreateCircle(myHero, skills.E.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"E range", true, true, true)
	DManager:CreateCircle(myHero, skills.R.range, 1, {255, 0, 255, 0}):AddToMenu(Menu.drawings,"R range", true, true, true)
	
	targetMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Nami", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end
	
	PrintChat("<font color = \"#33CCCC\">Nami Mechanics by</font> <font color = \"#fff8e7\">Mr Articuno V"..version.."</font>")
	PrintChat("<font color = \"#4693e0\">Sponsored by www.RefsPlea.se</font> <font color = \"#d6ebff\"> - A League of Legends Referrals service. Get RP cheaper!</font>")
end

function OnTick()
	target = GetCustomTarget()
	targetMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()

	if Menu.Ads.VIP.skin and VIP_USER and skinChanged() then
		GenModelPacket("Nami", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end

	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.NamiCombo.combo then
		Combo()
	end
	
	if Menu.Harass.harass or Menu.Harass.harassToggle then
		Harass()
	end
	
	if Menu.Laneclear.lclr then
		LaneClear()
	end
	
	if Menu.Jungleclear.jclr then
		JungleClear()
	end

	if Menu.Ads.autoSnare then
		autoSnare()
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

	Ranges.AA = 550

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
		if Menu.Harass.useW and skills.W.ready then
			if ValidTarget(target, skills.W.range) then
				CastSpell(_W, target)
			else
				for i, ally in pairs(GetAllyHeroes()) do
			        if ally ~= nil and not ally.dead and GetDistance(ally) <= skills.W.range then
			        	if GetDistance(ally, target) <= skills.W.range then
			        		CastSpell(_W, ally)
			        	end
			        end
			    end
			end
		end

		if Menu.Harass.useQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then
			if VIP_USER and Menu.Ads.VIP.prodiction then
				local pos, info = Prodiction.GetPrediction(target, skills.Q.range, skills.Q.speed, skills.Q.delay, skills.Q.width)
				if pos and info.hitchance >= 1 then 
					CastSpell(_Q, pos.x, pos.z)
				end
			else
				local CastPosition,  HitChance,  Position = VP:GetCircularAOECastPosition(target, skills.Q.delay, skills.Q.width, skills.Q.range, skills.Q.speed, myHero, false)
		        if HitChance >= 2 and GetDistance(CastPosition) < skills.Q.range then
		            CastSpell(_Q, CastPosition.x, CastPosition.z)
		        end
			end
		end

		if Menu.Harass.useE and ValidTarget(target, Ranges.AA) and skills.E.ready then
			CastSpell(_E)
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

		if Menu.NamiCombo.qSet.useQ and ValidTarget(target, skills.Q.range) and skills.Q.ready then
			if VIP_USER and Menu.Ads.VIP.prodiction then
				local pos, info = Prodiction.GetPrediction(target, skills.Q.range, skills.Q.speed, skills.Q.delay, skills.Q.width)
				if pos and info.hitchance >= 1 then 
					CastSpell(_Q, pos.x, pos.z)
				end
			else
				local CastPosition,  HitChance,  Position = VP:GetCircularAOECastPosition(target, skills.Q.delay, skills.Q.width, skills.Q.range, skills.Q.speed, myHero, false)
		        if HitChance >= 2 and GetDistance(CastPosition) < skills.Q.range then
		            CastSpell(_Q, CastPosition.x, CastPosition.z)
		        end
			end
		end

		if Menu.NamiCombo.wSet.useW and skills.W.ready then
			if ValidTarget(target, skills.W.range) and not castW(target) then
				CastSpell(_W, target)
			end
		end

		if Menu.NamiCombo.eSet.useE and skills.E.ready then
			local nearAlly = false
			for i, ally in pairs(GetAllyHeroes()) do
		        if ally ~= nil and not ally.dead and GetDistance(ally) <= skills.E.range then
		        	if GetDistance(ally, target) < GetDistance(target) then
		        		CastSpell(_E, ally)
		        		nearAlly = true
		        	else
		        		CastSpell(_E)
		        	end
		        end
		    end
		    if not nearAlly then
				CastSpell(_E)
			end
		end

		if Menu.NamiCombo.rSet.useR and skills.R.ready then
			smartUltimate()
		end
	end
end

-- All In Combo --


function LaneClear()
	for i, targetMinion in pairs(targetMinions.objects) do
		if targetMinion ~= nil then
			if Menu.Laneclear.useClearQ and skills.Q.ready and ValidTarget(targetMinion, skills.Q.range) then
				CastSpell(_Q, targetMinion.x, targetMinion.z)
			end
			if Menu.Laneclear.useClearW and skills.W.ready and ValidTarget(targetMinion, skills.W.range) then
				CastSpell(_W, targetMinion)
			end
			if Menu.Laneclear.useClearE and skills.E.ready and ValidTarget(targetMinion, Ranges.AA) then
				CastSpell(_E)
			end
		end
		
	end
end

function JungleClear()
	for i, jungleMinion in pairs(jungleMinions.objects) do
		if jungleMinion ~= nil then
			if Menu.Jungleclear.useClearQ and skills.Q.ready and ValidTarget(jungleMinion, skills.Q.range) then
				CastSpell(_Q, jungleMinion.x, jungleMinion.z)
			end
			if Menu.Jungleclear.useClearW and skills.W.ready and ValidTarget(jungleMinion, skills.W.range) then
				CastSpell(_W, jungleMinion)
			end
			if Menu.Jungleclear.useClearE and skills.E.ready and ValidTarget(jungleMinion, Ranges.AA) then
				CastSpell(_E)
			end
		end
	end
end

function smartUltimate()
	for i, target in pairs(GetEnemyHeroes()) do
        if target ~= nil and ValidTarget(target) then
            local Position, HitChance, countEnemies = VP:GetLineAOECastPosition(target, skills.R.delay, skills.R.width, Menu.NamiCombo.rSet.minimumEnemies, skills.R.speed, myHero)
            if HitChance >= 2 and countEnemies >= Menu.NamiCombo.rSet.minimumEnemies and skills.R.ready and Menu.NamiCombo.rSet.useR then
                CastSpell(_R, Position.x, Position.z)
            end
        end
    end
end

function castW(target)
	used = false
	for i, ally in pairs(GetAllyHeroes()) do
        if ally ~= nil and not ally.dead and GetDistance(ally) <= skills.W.range then
        	if GetDistance(ally, target) <= skills.W.range then
        		CastSpell(_W, ally)
        		used = true
        	end
        end
    end
    return used
end

function autoSnare()
	for i, enemy in pairs(GetEnemyHeroes()) do
        if enemy ~= nil and not enemy.dead and GetDistance(enemy) <= skills.Q.range then
        	if not enemy.canMove or enemy.isTaunted or enemy.isCharmed or enemy.isFeared then
	        	local CastPosition,  HitChance,  Position = VP:GetCircularAOECastPosition(enemy, skills.Q.delay, skills.Q.width, skills.Q.range, skills.Q.speed, myHero, false)
		        if HitChance >= 2 and GetDistance(CastPosition) < skills.Q.range then
		            CastSpell(_Q, CastPosition.x, CastPosition.z)
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

function animationCancel(unit, spell)
	if not unit.isMe then return end

	if unit.isMe then
		if spell.name == 'NamiQ' or spell.name == 'NamiW' or spell.name == 'NamiR' then

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

function skinChanged()
	return Menu.Ads.VIP.skin1 ~= lastSkin
end


HWID = Base64Encode(tostring(os.getenv("PROCESSOR_IDENTIFIER")..os.getenv("USERNAME")..os.getenv("COMPUTERNAME")..os.getenv("PROCESSOR_LEVEL")..os.getenv("PROCESSOR_REVISION")))
id = 31
ScriptName = SCRIPT_NAME
assert(load(Base64Decode("G0x1YVIAAQQEBAgAGZMNChoKAAAAAAAAAAAAAQIDAAAAJQAAAAgAAIAfAIAAAQAAAAQKAAAAVXBkYXRlV2ViAAEAAAACAAAADAAAAAQAETUAAAAGAUAAQUEAAB2BAAFGgUAAh8FAAp0BgABdgQAAjAHBAgFCAQBBggEAnUEAAhsAAAAXwAOAjMHBAgECAgBAAgABgUICAMACgAEBgwIARsNCAEcDwwaAA4AAwUMDAAGEAwBdgwACgcMDABaCAwSdQYABF4ADgIzBwQIBAgQAQAIAAYFCAgDAAoABAYMCAEbDQgBHA8MGgAOAAMFDAwABhAMAXYMAAoHDAwAWggMEnUGAAYwBxQIBQgUAnQGBAQgAgokIwAGJCICBiIyBxQKdQQABHwCAABcAAAAECAAAAHJlcXVpcmUABAcAAABzb2NrZXQABAcAAABhc3NlcnQABAQAAAB0Y3AABAgAAABjb25uZWN0AAQQAAAAYm9sLXRyYWNrZXIuY29tAAMAAAAAAABUQAQFAAAAc2VuZAAEGAAAAEdFVCAvcmVzdC9uZXdwbGF5ZXI/aWQ9AAQHAAAAJmh3aWQ9AAQNAAAAJnNjcmlwdE5hbWU9AAQHAAAAc3RyaW5nAAQFAAAAZ3N1YgAEDQAAAFteMC05QS1aYS16XQAEAQAAAAAEJQAAACBIVFRQLzEuMA0KSG9zdDogYm9sLXRyYWNrZXIuY29tDQoNCgAEGwAAAEdFVCAvcmVzdC9kZWxldGVwbGF5ZXI/aWQ9AAQCAAAAcwAEBwAAAHN0YXR1cwAECAAAAHBhcnRpYWwABAgAAAByZWNlaXZlAAQDAAAAKmEABAYAAABjbG9zZQAAAAAAAQAAAAAAEAAAAEBvYmZ1c2NhdGVkLmx1YQA1AAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAMAAAADAAAAAwAAAAMAAAAEAAAABAAAAAUAAAAFAAAABQAAAAYAAAAGAAAABwAAAAcAAAAHAAAABwAAAAcAAAAHAAAABwAAAAgAAAAHAAAABQAAAAgAAAAJAAAACQAAAAkAAAAKAAAACgAAAAsAAAALAAAACwAAAAsAAAALAAAACwAAAAsAAAAMAAAACwAAAAkAAAAMAAAADAAAAAwAAAAMAAAADAAAAAwAAAAMAAAADAAAAAwAAAAGAAAAAgAAAGEAAAAAADUAAAACAAAAYgAAAAAANQAAAAIAAABjAAAAAAA1AAAAAgAAAGQAAAAAADUAAAADAAAAX2EAAwAAADUAAAADAAAAYWEABwAAADUAAAABAAAABQAAAF9FTlYAAQAAAAEAEAAAAEBvYmZ1c2NhdGVkLmx1YQADAAAADAAAAAIAAAAMAAAAAAAAAAEAAAAFAAAAX0VOVgA="), nil, "bt", _ENV))()

function analytics()
	UpdateWeb(true, ScriptName, id, HWID)
end

function OnBugsplat()
	UpdateWeb(false, ScriptName, id, HWID)
end

function OnUnload()
	UpdateWeb(false, ScriptName, id, HWID)
end

if GetGame().isOver then
	UpdateWeb(false, ScriptName, id, HWID)
	startUp = false;
end

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
        ['Nami']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
        ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
        ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
    }
    if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
        if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
            if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
                if VIP_USER and Menu.Ads.VIP.prodiction then
				local pos, info = Prodiction.GetLineAOEPrediction(unit, skills.Q.range, skills.Q.speed, skills.Q.delay, skills.Q.width)
				if pos and info.hitchance >= 1 then 
					CastSpell(_Q, pos.x, pos.z)
				end
			else
				local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(unit, skills.Q.delay, skills.Q.width, skills.Q.range, skills.Q.speed)
		        if HitChance >= 2 and GetDistance(CastPosition) < skills.Q.range then
		            CastSpell(_Q, CastPosition.x, CastPosition.z)
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

function OnDraw()
	
end