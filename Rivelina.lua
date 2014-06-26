-- Mr Articuno Rivelina
if myHero.charName ~= "Riven" then return end

local version = "0.47"
local SCRIPT_NAME = "Rivelina"

local AUTOUPDATE = true
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
  SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/gmlyra/BolScripts/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/gmlyra/VersionFiles/master/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Start Vadash Credit
class 'Kalman' -- {
function Kalman:__init()
  self.current_state_estimate = 0
  self.current_prob_estimate = 0
  self.Q = 1
  self.R = 15
end
function Kalman:STEP(control_vector, measurement_vector)
  local predicted_state_estimate = self.current_state_estimate + control_vector
  local predicted_prob_estimate = self.current_prob_estimate + self.Q
  local innovation = measurement_vector - predicted_state_estimate
  local innovation_covariance = predicted_prob_estimate + self.R
  local kalman_gain = predicted_prob_estimate / innovation_covariance
  self.current_state_estimate = predicted_state_estimate + kalman_gain * innovation
  self.current_prob_estimate = (1 - kalman_gain) * predicted_prob_estimate
  return self.current_state_estimate
end

--[[ Velocities ]]
local kalmanFilters = {}
local velocityTimers = {}
local oldPosx = {}
local oldPosz = {}
local oldTick = {}
local velocity = {}
local lastboost = {}
local velocity_TO = 10
local CONVERSATION_FACTOR = 975
local MS_MIN = 500
local MS_MEDIUM = 750

--End Vadash Credit


-- Minhas Variaveis
local comboStarted = 0
local IM
local ultStage = 0
local P_Stack=0
local P_BuffName="rivenpassiveaaboost"
local Q_BuffName="RivenTriCleave"
local R_BuffName='RivenFengShuiEngine'

local AnimationCancel={
  [1]=function() myHero:MoveTo(mousePos.x,mousePos.z) end, --"Move"
  [2]=function() SendChat('/l') end, --"Laugh"
  [3]=function() SendChat('/d') end, --"Dance"
  [4]=function() SendChat('/t') end, --"Taunt"
  [5]=function() SendChat('/j') end, --"joke"
  [6]=function() end,
}

-- List Escape

local list =
  {
    {cast = true , spell = _Q , x = mousePos.x , y = mousePos.y},
    {cast = true , spell = _Q , x = mousePos.x , y = mousePos.y},
    {cast = true , spell = _E , x = mousePos.x , y = mousePos.y},
    {cast = true , spell = _Q , x = mousePos.x , y = mousePos.y}
  }

---Combo lists

-- Constantes

local ranges = { AA = 125, Q = 260, W = 125, E = 325, R = 900 }

--
local initDone, target1 = false, nil
local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local ignite
local lastWindUpTime = 0
local Target
local eneplayeres = {}
local Config
local QReady, WReady, EReady, RReady = false, false, false, false
local informationTable = {}
local spellExpired = true
local ignite, igniteReady = nil, nil

function Init()
  --print('Init called')
  --Start Vadash Credit
  for i = 1, heroManager.iCount do
    local hero = heroManager:GetHero(i)
    if hero.team ~= player.team then
      table.insert(eneplayeres, hero)
      kalmanFilters[hero.networkID] = Kalman()
      velocityTimers[hero.networkID] = 0
      oldPosx[hero.networkID] = 0
      oldPosz[hero.networkID] = 0
      oldTick[hero.networkID] = 0
      velocity[hero.networkID] = 0
      lastboost[hero.networkID] = 0
    end
  end
  --End Vadash Credit
  ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 650, DAMAGE_PHYSICAL)
  ts.name = "Target"
  Config:addTS(ts)
  EnemyMinions = minionManager(MINION_ENEMY, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
  JungleMinions = minionManager(MINION_JUNGLE, 1200, myHero, MINION_SORT_MAXHEALTH_DEC)
  initDone = true
  print('Mr Articuno Rivelina ')
end

function Menu()
  Config = scriptConfig("Rivelina", "MrArticuno")

  Config:addParam("ComboS", "Smart Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
  Config:addParam("ComboE", "Combo Safe", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('V'))
  Config:addParam("ComboA", "All in Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('C'))
  Config:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('A'))
  Config:addParam("Escape", "Flee to Mouse", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('X'))
  --Sub Menu
  Config:addSubMenu("Combo options", "ComboSub")
  Config:addSubMenu("KS", "KS")
  Config:addSubMenu("Draw", "Draw")
  if _G.MMA_Target or _G.AutoCarry then
  else
    print('MMA or SAC not found Loading SOW')
    Config:addSubMenu("SOW", "SOW")
    --SOW
    SOWi:LoadToMenu(Config.SOW)
  end

  Config:addSubMenu("Extras", "Extras")
  --Combo options
  Config.ComboSub:addParam("useR", "Ult in Combo", SCRIPT_PARAM_ONOFF, true)
  Config.ComboSub:addParam("weaving", "Q>AA", SCRIPT_PARAM_ONOFF, false)
  Config.ComboSub:addParam("Orbwalk", "Use OrbWalk (Turn of if MMA,SAC or SOW)", SCRIPT_PARAM_ONOFF, false)
  Config.ComboSub:addParam("moveMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
  --Extras
  Config.Extras:addParam("cancel", "Animation Cancel", SCRIPT_PARAM_LIST, 1, { "Move","Laugh","Dance","Taunt","joke","Nothing" })
  AddProcessSpellCallback(function(unit, spell)
    if not unit.isMe then return end

    if Config.Harass then
      if spell.name == 'RivenTriCleave' then -- _Q
        DelayAction(function() SOWi:resetAA() end, nil)
        AnimationCancel[Config.Extras.cancel]()
      elseif spell.name == 'RivenMartyr' then -- _W
        AnimationCancel[Config.Extras.cancel]()
      end
    end
    if Config.ComboA then
      if spell.name == 'RivenTriCleave' then -- _Q
        DelayAction(function() SOWi:resetAA() end, nil)
        AnimationCancel[Config.Extras.cancel]()
      elseif spell.name == 'RivenMartyr' then -- _W
        AnimationCancel[Config.Extras.cancel]()
      elseif spell.name == 'RivenFeint'  then -- _E
        --OnLy To OnTick Target
        if  RReady then --AUTOMATIC R
          SpellCast(_R)
      end
      if WReady and SpellCast(_W)== SPELLSTATE_TRIGGERED then
        castItens()
      end
      AnimationCancel[Config.Extras.cancel]()
      elseif spell.name == 'RivenFengShuiEngine' then -- _R first cast
        AnimationCancel[Config.Extras.cancel]()
      end
    end
  end)
  Config.Extras:addParam("pCast", "Skill by Packet Faster/VIP Only", SCRIPT_PARAM_ONOFF, false)
  --KS
  Config.KS:addParam("useR", "Ult to KS", SCRIPT_PARAM_ONOFF, true)
  Config.KS:addParam("Ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
  --Draw
  Config.Draw:addSubMenu("Drawings", "Drawings")

  --Permashow
end

--Credit Trees

function GetCustomTarget()
  ts:update()
  if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
  if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
  return ts.target
end

--End Credit Trees

function OnLoad()
  VP = VPrediction()
  SOWi = SOW(VP)
  Menu()
  Init()
end

function OnTick()
  if initDone then
    Checks()
    target = GetCustomTarget()
    KillSteal()
    EnemyMinions:update()
    JungleMinions:update()
    if Config.ComboS or Config.ComboA or Config.ComboE or Config.Harass then
      if target ~= nil and ValidTarget(target) then
        if ValidTarget(target) and target ~= nil then
          if TargetValid(target) == false then
            ts:update()
            target = ts.target
          end
          if Config.ComboS then
            ComboS(target)
          elseif Config.ComboA then
            ComboA(target)
          elseif Config.ComboE then
            ComboE(target)
          elseif target.type == 'obj_AI_Hero' then
            Harass(target)
          end
        end
        if Config.ComboSub.Orbwalk and ValidTarget(target) and target ~= nil then
          OrbWalking(target)
        end
      else
        if Config.ComboSub.moveMouse then myHero:MoveTo(mousePos.x,mousePos.z) end
      end
    end
    if Config.Escape then
      Escape()
    end

  end
end

function chase(Target)
  if GetDistance(Target) > 325 then
    if EReady then SpellCast(_E, mousePos.x,mousePos.z) end
    if QReady then SpellCast(_Q, mousePos.x,mousePos.z) end
    if not QReady and not EReady and Config.ComboSub.moveMouse then myHero:MoveTo(mousePos.x,mousePos.z) end
  end
end

function ComboA(Target)

  if EReady then
    SpellCast(_E, Target.x, Target.z)
  end
  if RReady then
    CastSpell(_R)
  end
  if WReady then
    SpellCast(_W, Target.x, Target.z)
    castItens()
  end
  if QReady then
    SpellCast(_Q, Target.x, Target.z)
  end
  if RReady then
    forceUseUlt(Target)
    SpellCast(_R, Target.x, Target.z)
    SpellCast(_R, Target.x, Target.z)
    SpellCast(_R, Target.x, Target.z)
    SpellCast(_R, Target.x, Target.z)
  end
  if QReady then
    SpellCast(_Q, Target.x, Target.z)
  end

end

function ComboE(Target)

  if Config.ComboSub.useR and GetDistance(Target) <= 200 and RReady and ultStage == 0 then
    finishWithUlt(Target)
  end

  if GetDistance(Target) <= ranges.W and WReady then
    SpellCast(_W)
    castItens()
  end
  if Config.ComboSub.weaving then
    QWeaving(Target)
  elseif QReady and GetDistance(Target) < ranges.Q then
    SpellCast(_Q, Target.x, Target.z)
  end
end

--- Safe Combo
--
--

function ComboS(Target)

  if Config.ComboSub.useR and RReady then
    finishWithUlt(Target)
  end

  if EReady and GetDistance(Target) <= ranges.Q then
    SpellCast(_E, Target.x, Target.z)
  end
  if Config.ComboSub.useR and GetDistance(Target) <= 200 and RReady and ultStage == 0 then
    finishWithUlt(Target)
    SpellCast(_R)
  end
  if WReady and GetDistance(Target) <= ranges.W then
    SpellCast(_W)
  end
  if GetDistance(Target) <= ranges.W then
    castItens()
  end
  if QReady and GetDistance(Target) <= ranges.Q then
    SpellCast(_W)
  end

  if Config.ComboSub.weaving then
    QWeaving(Target)
  elseif QReady and GetDistance(Target) < ranges.Q then
    SpellCast(_Q, Target.x, Target.z)
  end
end

--- Harras
--
--

function Harass(Target)
  if WReady and GetDistance(Target) <= ranges.W then
    SpellCast(_W)
  end
  if Config.ComboSub.weaving then
    QWeaving(Target)
  end

end

function TargetValid(target)
  if target ~= nil and target.dead == false and target.team == TEAM_ENEMY and target.visible == true then
    return true
  else
    return false
  end
end

function QWeaving(Target)

  if GetDistance(Target) <= 325 then
    SOWi:RegisterAfterAttackCallback(function(target,mode)
      if target.type == 'obj_AI_Hero' and Config.Harass then
        if EReady and not QReady then
          SpellCast(_E, target.x, target.z)
        end
        if WReady  and GetDistance(target) <= ranges.W then
          SpellCast(_W)
        end
        if QReady then
          SpellCast(_Q, target.x, target.z)
        end
      end
    end)
    if GetDistance(Target) <= ranges.AA then
      myHero:Attack(Target)
    else
      myHero:MoveTo(mousePos.x, mousePos.z)
    end
  end

end

function finishWithUlt(Target)
  if myHero:GetSpellData(_R).level ~= 0 and myHero:CanUseSpell(_R) == READY then
    for i=1, heroManager.iCount do
      local enemy = heroManager:GetHero(i)
      if enemy.team ~= myHero.team and enemy ~= nil then
        local RDamage = getDmg("R",enemy,myHero)
        if TargetValid(enemy) then
          if RDamage > enemy.health and GetDistance(enemy) < 900 then
            if Config.ComboSub.useR then
              SpellCast(_R, enemy.x, enemy.z)
            else
              SpellCast(_R)
              if not enemy.dead then
                SpellCast(_R, enemy.x, enemy.z)
              end
            end
          end
        end
      end
    end
  end
end

function forceUseUlt(Target)
  if myHero:GetSpellData(_R).level ~= 0 and myHero:CanUseSpell(_R) == READY then
    for i=1, heroManager.iCount do
      local enemy = heroManager:GetHero(i)
      if enemy.team ~= myHero.team and enemy ~= nil then
        if TargetValid(enemy) then
          if Config.ComboSub.useR then
            SpellCast(_R, enemy.x, enemy.z)
          else
            SpellCast(_R)
            if not enemy.dead then
              SpellCast(_R, enemy.x, enemy.z)
            end
          end
        end
      end
    end
  end
end


function spellSequence(list)
  if list ~= nil and #list > 0 then
    for i=1, #list do
      if list[i].item then
        castItens()
      elseif list[i].cast then
        SpellCast(list[i].spell, list[i].x, list[i].y)
      else
        SpellCast(list[i].spell)
      end
    end
  end
end

function Escape()
  myHero:MoveTo(mousePos.x,mousePos.z)
  if QReady and EReady then
    spellSequence(list)
  elseif EReady then
    SpellCast(_E,mousePos.x,mousePos.z)
  elseif QReady then
    SpellCast(_Q,mousePos.x,mousePos.z)
  end
  return

end

if VIP_USER then

  function OnGainBuff(unit,buff)
    if unit.isMe then
      if buff.name==P_BuffName then
        P_Stack=1
      elseif buff.name==Q_BuffName then
        Q_Sequence=1
      elseif buff.name==R_BuffName then
        R_ON_FLAG=false
        R_ON=true
      end
    end
  end

  function OnLoseBuff(unit,buff)
    if unit.isMe then
      if buff.name==P_BuffName then
        P_Stack=0
      elseif buff.name=="RivenTriCleave" then
        Q_Sequence=0
      elseif buff.name==R_BuffName then
        R_ON=false
      end
    end
  end

  function OnUpdateBuff(unit,buff)
    if unit.isMe then
      if buff.name=="RivenTriCleave" then
        Q_Sequence=2
      elseif buff.name==P_BuffName then
        P_Stack=buff.stack
      end
    end
  end
end

function KillSteal()
  if Config.KS.useR then
    finishWithUlt(Target)
  end

  if Config.KS.Ignite then
    IgniteKS()
  end
end

function IgniteKS()
  if igniteReady then
    local Enemies = GetEnemyHeroes()
    for idx,val in ipairs(Enemies) do
      if ValidTarget(val, 600) then
        if getDmg("IGNITE", val, myHero) > val.health and RReady ~= true and GetDistance(val) >= 530 then
          CastSpell(ignite, val)
        end
      end
    end
  end
end

function OnDraw()

end

function Checks()
  QReady = (myHero:CanUseSpell(_Q) == READY)
  WReady = (myHero:CanUseSpell(_W) == READY)
  EReady = (myHero:CanUseSpell(_E) == READY)
  RReady = (myHero:CanUseSpell(_R) == READY)
  if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
    ignite = SUMMONER_1
  elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
    ignite = SUMMONER_2
  end
  igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function OnProcessSpell(unit, spell)

end

--Start Manciuszz orbwalker credit
function OrbWalking(target)
  if TimeToAttack() and GetDistance(target) <= 565 then
    myHero:Attack(target)
  elseif heroCanMove() then
    moveToCursor()
  end
end

function TimeToAttack()
  return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function heroCanMove()
  return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function moveToCursor()
  if GetDistance(mousePos) then
    local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
    myHero:MoveTo(moveToPos.x, moveToPos.z)
  end
end

function OnAnimation(unit,animationName)
  if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end
--End Manciuszz orbwalker credit

--Start Vadash Credit
function HaveLowVelocity(target, time)
  if ValidTarget(target, 1500) then
    return (velocity[target.networkID] < MS_MIN and target.ms < MS_MIN and GetTickCount() - lastboost[target.networkID] > time)
  else
    return nil
  end
end

function HaveMediumVelocity(target, time)
  if ValidTarget(target, 1500) then
    return (velocity[target.networkID] < MS_MEDIUM and target.ms < MS_MEDIUM and GetTickCount() - lastboost[target.networkID] > time)
  else
    return nil
  end
end

function castItens()

  local TIAMATSlot = GetInventorySlotItem(3077)
  local TIAMATREADY = (TIAMATSlot ~= nil and myHero:CanUseSpell(TIAMATSlot) == READY)
  local HYDRASlot = GetInventorySlotItem(3074)
  local HYDRAREADY = (HYDRASlot ~= nil and myHero:CanUseSpell(HYDRASlot) == READY)

  if TIAMATREADY then
    SpellCast(TIAMATSlot)
    return
  end

  if HYDRAREADY then
    SpellCast(HYDRASlot)
    return
  end

end

function _calcHeroVelocity(target, oldPosx, oldPosz, oldTick)
  if oldPosx and oldPosz and target.x and target.z then
    local dis = math.sqrt((oldPosx - target.x) ^ 2 + (oldPosz - target.z) ^ 2)
    velocity[target.networkID] = kalmanFilters[target.networkID]:STEP(0, (dis / (GetTickCount() - oldTick)) * CONVERSATION_FACTOR)
  end
end

function UpdateSpeed()
  local tick = GetTickCount()
  for i=1, #eneplayeres do
    local hero = eneplayeres[i]
    if ValidTarget(hero) then
      if velocityTimers[hero.networkID] <= tick and hero and hero.x and hero.z and (tick - oldTick[hero.networkID]) > (velocity_TO-1) then
        velocityTimers[hero.networkID] = tick + velocity_TO
        _calcHeroVelocity(hero, oldPosx[hero.networkID], oldPosz[hero.networkID], oldTick[hero.networkID])
        oldPosx[hero.networkID] = hero.x
        oldPosz[hero.networkID] = hero.z
        oldTick[hero.networkID] = tick
        if velocity[hero.networkID] > MS_MIN then
          lastboost[hero.networkID] = tick
        end
      end
    end
  end
end
--End Vadash Credit

--Credit Xetrok
function CountEnemyNearPerson(person,vrange)
  count = 0
  for i=1, heroManager.iCount do
    currentEnemy = heroManager:GetHero(i)
    if currentEnemy.team ~= myHero.team then
      if person:GetDistance(currentEnemy) <= vrange and not currentEnemy.dead then count = count + 1 end
    end
  end
  return count
end
--End Credit Xetrok

function SpellCast(spell, posx, posz)
  if Config.Extras.pCast and VIP_USER then
    Packet('S_CAST', { spellId = spell, fromX = posx, fromY = posz}):send()
  else
    if posx == nil or posz == nill then
      CastSpell(spell)
    else
      CastSpell(spell, posx, posz)
      Config.Extras.pCast = false
    end
  end
end