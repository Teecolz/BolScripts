--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/

]]

if myHero.charName ~= "Elise" then return end


local version = 0.31
local AUTOUPDATE = true


local SCRIPT_NAME = "EliseMechanics"
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
local abilitySequence = {2, 1, 3, 2, 2, 4, 1, 1, 2, 2, 4, 1, 1, 3, 3, 4, 3, 3}
local Ranges = { AA = 550 }
local skills = {
    Q = { ready = false, name = myHero:GetSpellData(_Q).name, range = 625, delay = myHero:GetSpellData(_Q).delayTotalTimePercent, speed = myHero:GetSpellData(_Q).missileSpeed, width = myHero:GetSpellData(_Q).lineWidth },
	W = { ready = false, name = myHero:GetSpellData(_W).name, range = 950, delay = 0.25, speed = 1000, width = 100 },
	E = { ready = false, name = myHero:GetSpellData(_E).name, range = 1075, delay = 0.25, speed = 1300, width = 90 },
	R = { ready = false, name = myHero:GetSpellData(_R).name, range = 0, delay = myHero:GetSpellData(_R).delayTotalTimePercent, speed = myHero:GetSpellData(_R).missileSpeed, width = myHero:GetSpellData(_R).lineWidth },
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
local spiderForm = false
local focusTarget = nil

-- [[ VIP Variables]] --
local Prodict
local ProdictE, ProdictECol


--Credit Trees
function GetCustomTarget()
	ts:update()
	if focusTarget ~= nil and not focusTarget.dead and Menu.targetSelector.focusPriority then return focusTarget end
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
	
	Menu = scriptConfig("Elise Mechanics by Mr Articuno", "EliseMA")

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
	
	Menu:addSubMenu("["..myHero.charName.." - Combo]", "EliseCombo")
	Menu.EliseCombo:addParam("combo", "Combo mode", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.EliseCombo:addSubMenu("Q Settings", "qSet")
	Menu.EliseCombo.qSet:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.EliseCombo:addSubMenu("W Settings", "wSet")
	Menu.EliseCombo.wSet:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Menu.EliseCombo:addSubMenu("E Settings", "eSet")
	Menu.EliseCombo.eSet:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.EliseCombo:addSubMenu("R Settings", "rSet")
	Menu.EliseCombo.rSet:addParam("useR", "Auto Change Form", SCRIPT_PARAM_ONOFF, true)
	Menu.EliseCombo.rSet:addParam("useRE", "Gap Closer Gank", SCRIPT_PARAM_ONOFF, false)
	
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
	Menu.Ads:addParam("autoLevel", "Auto-Level Spells", SCRIPT_PARAM_ONOFF, false)
	Menu.Ads:addSubMenu("Killsteal", "KS")
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
	Menu.targetSelector:addParam("focusPriority", "Force Combo Selected Target", SCRIPT_PARAM_ONOFF, false)
	
	Menu:addSubMenu("["..myHero.charName.." - Drawings]", "drawings")
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
		ProdictE = Prodict:AddProdictionObject(_E, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)
        ProdictECol = Collision(skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)

	end
	
	if Menu.Ads.VIP.skin and VIP_USER then
		GenModelPacket("Elise", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end
	
	PrintChat("<font color = \"#33CCCC\">Elise Mechanics by</font> <font color = \"#fff8e7\">Mr Articuno</font>")
	PrintChat("<font color = \"#4693e0\">Sponsored by www.RefsPlea.se</font> <font color = \"#d6ebff\"> - A League of Legends Referrals service. Get RP cheaper!</font>")
end

function OnTick()
	target = GetCustomTarget()
	targetMinions:update()
	allyMinions:update()
	jungleMinions:update()
	CDHandler()
	KillSteal()

	 if myHero.dead then
        return
    end
       
    if not myHero.canMove then
        return
    end

     local focus = GetTarget()
        if focus ~= nil then
            if string.find(focus.type, "Hero") and focus.team ~= myHero.team then
                focusTarget = focus
            end
        end

	if Menu.Ads.VIP.skin and VIP_USER and skinChanged() then
		GenModelPacket("Elise", Menu.Ads.VIP.skin1)
		lastSkin = Menu.Ads.VIP.skin1
	end

	if Menu.Ads.autoLevel then
		AutoLevel()
	end
	
	if Menu.EliseCombo.combo then
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

	if myHero.dead then
		spiderForm = false
	end

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
		
		if not spiderForm then
			if skills.E.ready and ValidTarget(target, skills.E.range) and Menu.Harass.useE then
				if VIP_USER and Menu.Ads.VIP.prodiction then
					ProdictE:GetPredictionCallBack(target, CastE)
				else
					local ePosition, eChance = VP:GetLineCastPosition(target, skills.E.delay, skills.E.width, skills.E.range, skills.E.speed, myHero, true)

				    if ePosition ~= nil and GetDistance(ePosition) < skills.E.range and eChance >= 2 then
				      CastSpell(_E, ePosition.x, ePosition.z)
				    end
				end
			end

			if skills.W.ready and ValidTarget(target, skills.W.range) and Menu.Harass.useW then
				if VIP_USER and Menu.Ads.VIP.prodiction then
					local pos, info = Prodiction.GetPrediction(target, skills.W.range, skills.W.speed, skills.W.delay, skills.W.width)
					if pos then 
						CastSpell(_W, pos.x, pos.z)
					end
				else
					local Position, Chance = VP:GetLineCastPosition(target, skills.W.delay, skills.W.width, skills.W.range, skills.W.speed, myHero, false)

				    if Position ~= nil and GetDistance(Position) < skills.W.range and Chance >= 2 then
				      CastSpell(_W, Position.x, Position.z)
				    end
				end
			end

			if skills.Q.ready and ValidTarget(target, skills.Q.range) and Menu.Harass.useQ then
				CastSpell(_Q, target)
			end
		end

		if spiderForm then

			if skills.E.ready and ValidTarget(target, skills.E.range) and Menu.Harass.useE then
				CastSpell(_E, target)
				CastSpell(_E, target.x, target.z)
			end

			if skills.W.ready and ValidTarget(target, Ranges.AA - 425) and Menu.Harass.useW then
				CastSpell(_E)
			end

			if skills.Q.ready and ValidTarget(target, skills.Q.range - 125) and Menu.Harass.useQ then
				CastSpell(_Q, target)
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

		if not spiderForm then
			if skills.E.ready and ValidTarget(target, skills.E.range) and Menu.EliseCombo.eSet.useE then
				if VIP_USER and Menu.Ads.VIP.prodiction then
					local pos, info = Prodiction.GetPrediction(target, skills.E.range, skills.E.speed, skills.E.delay, skills.E.width)
					if info.hitchance > 2 then 
						CastSpell(_E, pos.x, pos.z)
					end
				else
					local ePosition, eChance = VP:GetLineCastPosition(target, skills.E.delay, skills.E.width, skills.E.range, skills.E.speed, myHero, true)

				    if ePosition ~= nil and GetDistance(ePosition) < skills.E.range and eChance >= 2 then
				      CastSpell(_E, ePosition.x, ePosition.z)
				    end
				end
			end

			if skills.W.ready and ValidTarget(target, skills.W.range) and Menu.EliseCombo.wSet.useW then
				if VIP_USER and Menu.Ads.VIP.prodiction then
					local pos, info = Prodiction.GetPrediction(target, skills.W.range, skills.W.speed, skills.W.delay, skills.W.width)
					if info.hitchance >= 2 then 
						CastSpell(_W, pos.x, pos.z)
					end
				else
					local Position, Chance = VP:GetLineCastPosition(target, skills.W.delay, skills.W.width, skills.W.range, skills.W.speed, myHero, false)

				    if Position ~= nil and GetDistance(Position) < skills.W.range and Chance >= 2 then
				      CastSpell(_W, Position.x, Position.z)
				    end
				end
			end

			if skills.Q.ready and ValidTarget(target, skills.Q.range) and Menu.EliseCombo.qSet.useQ then
				CastSpell(_Q, target)
			end

			if skills.R.ready and ValidTarget(target, skills.E.range) and Menu.EliseCombo.rSet.useR then
				CastSpell(_R)
			end
		end

		if spiderForm then

			if Menu.EliseCombo.rSet.useRE and ValidTarget(target, skills.E.range) and skills.R.ready then
				if skills.E.ready then
					CastSpell(_E)
					CastSpell(_E, target)
					CastSpell(_R)
				end
			end

			if skills.E.ready and ValidTarget(target, skills.E.range) and GetDistance(target) >= 425 and Menu.EliseCombo.eSet.useE then
				CastSpell(_E, target)
				CastSpell(_E, target.x, target.z)
			end

			if skills.Q.ready and ValidTarget(target, skills.Q.range - 125) and Menu.EliseCombo.qSet.useQ then
				CastSpell(_Q, target)
			end

			if skills.W.ready and ValidTarget(target, Ranges.AA - 425) and Menu.EliseCombo.wSet.useW then
				CastSpell(_W)
			end

			if not skills.Q.ready and not skills.E.ready and not skills.W.ready and GetDistance(target) >= 325 then
				if skills.R.ready and Menu.EliseCombo.rSet.useR then
					CastSpell(_R)
				end
			end

		end

	end
end

-- All In Combo --


function LaneClear()
	for i, target in pairs(targetMinions.objects) do
		if target ~= nil then
			
			if not spiderForm then
				if skills.W.ready and ValidTarget(target, skills.W.range) and Menu.Laneclear.useClearW then
					if VIP_USER and Menu.Ads.VIP.prodiction then
						local pos, info = Prodiction.GetPrediction(target, skills.W.range, skills.W.speed, skills.W.delay, skills.W.width)
						if pos then 
							CastSpell(_W, pos.x, pos.z)
						end
					else
						local Position, Chance = VP:GetLineCastPosition(target, skills.W.delay, skills.W.width, skills.W.range, skills.W.speed, myHero, false)

					    if Position ~= nil and GetDistance(Position) < skills.W.range and Chance >= 2 then
					      CastSpell(_W, Position.x, Position.z)
					    end
					end
				end

				if skills.Q.ready and ValidTarget(target, skills.Q.range) and Menu.Laneclear.useClearQ then
					CastSpell(_Q, target)
				end

				if skills.R.ready and ValidTarget(target, skills.E.range) then
					CastSpell(_R)
				end
			end

			if spiderForm then

				if skills.W.ready and ValidTarget(target, Ranges.AA - 425) and Menu.Laneclear.useClearW then
					CastSpell(_W)
				end

				if skills.Q.ready and ValidTarget(target, skills.Q.range - 125) and Menu.Laneclear.useClearQ then
					CastSpell(_Q, target)
				end

			end

		end
		
	end
end

function JungleClear()
	for i, target in pairs(jungleMinions.objects) do
		if target ~= nil then
			
			if not spiderForm then
				if skills.W.ready and ValidTarget(target, skills.W.range) and Menu.Jungleclear.useClearW then
					if VIP_USER and Menu.Ads.VIP.prodiction then
						local pos, info = Prodiction.GetPrediction(target, skills.W.range, skills.W.speed, skills.W.delay, skills.W.width)
						if pos then 
							CastSpell(_W, pos.x, pos.z)
						end
					else
						local Position, Chance = VP:GetLineCastPosition(target, skills.W.delay, skills.W.width, skills.W.range, skills.W.speed, myHero, false)

					    if Position ~= nil and GetDistance(Position) < skills.W.range and Chance >= 2 then
					      CastSpell(_W, Position.x, Position.z)
					    end
					end
				end

				if skills.Q.ready and ValidTarget(target, skills.Q.range) and Menu.Jungleclear.useClearQ then
					CastSpell(_Q, target)
				end

				if skills.R.ready and ValidTarget(target, skills.E.range) then
					CastSpell(_R)
				end
			end

			if spiderForm then

				if skills.W.ready and ValidTarget(target, Ranges.AA - 425) and Menu.Jungleclear.useClearW then
					CastSpell(_W)
				end

				if skills.Q.ready and ValidTarget(target, skills.Q.range - 125) and Menu.Jungleclear.useClearQ then
					CastSpell(_Q, target)
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
	if Menu.Ads.KS.ignite then
		IgniteKS()
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

	if dfgReady then CastSpell(dfgSlot, target) end
	if youmuuReady then CastSpell(youmuuSlot, target) end
	if bilgeReady then CastSpell(bilgeSlot, target) end
	if bladeReady then CastSpell(bladeSlot, target) end
	if divineReady then CastSpell(divineSlot, target) end

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


function OnProcessSpell(unit, spell)

	if unit.isMe then
		if spell.name == 'EliseR' then
			spiderForm = true
		elseif spell.name == 'EliseRSpider' then
			spiderForm = false
		end
	end

end

function CastE(unit, pos, spell)
        if GetDistance(pos) - getHitBoxRadius(unit)/2 < skills.E.range then
            local willCollide = ProdictECol:GetMinionCollision(pos, myHero)
            if not willCollide then CastSpell(_E, pos.x, pos.z) end
        end
end

function skinChanged()
	return Menu.Ads.VIP.skin1 ~= lastSkin
end

function OnDraw()
	
end