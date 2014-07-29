--[[
		           __    _ _      _____        _____        _____     _   _                 
		 _____ ___|  |  |_| |_   | __  |_ _   |     |___   |  _  |___| |_|_|___ _ _ ___ ___ 
		|     |  _|  |__| | . |  | __ -| | |  | | | |  _|  |     |  _|  _| |  _| | |   | . |
		|_|_|_|_| |_____|_|___|  |_____|_  |  |_|_|_|_|    |__|__|_| |_| |_|___|___|_|_|___|
		                               |___|                                                

]]

--[[

		_________                        __    _________ .__                        
		\_   ___ \_______ ___.__._______/  |_  \_   ___ \|  | _____    ______ ______
		/    \  \/\_  __ <   |  |\____ \   __\ /    \  \/|  | \__  \  /  ___//  ___/
		\     \____|  | \/\___  ||  |_> >  |   \     \___|  |__/ __ \_\___ \ \___ \ 
		 \______  /|__|   / ____||   __/|__|    \______  /____(____  /____  >____  >
		        \/        \/     |__|                  \/          \/     \/     \/ 

]]

local hashKey = {1,2,3,4,0} -- You can use your own Hash key

local function convert(chars,dist,inv)
  local charInt = string.byte(chars);
  for i=1,dist do
    if(inv)then charInt = charInt - 1; else charInt = charInt + 1; end
    if(charInt<32)then
      if(inv)then charInt = 126; else charInt = 126; end
    elseif(charInt>126)then
      if(inv)then charInt = 32; else charInt = 32; end
    end
  end
  return string.char(charInt);
end

local function crypt(str,k,inv)
  local enc= "";
  for i=1,#str do
    if(#str-k[5] >= i or not inv)then
      for inc=0,3 do
        if(i%4 == inc)then
          enc = enc .. convert(string.sub(str,i,i),k[inc+1],inv);
          break;
        end
      end
    end
  end
  if(not inv)then
    for i=1,k[5] do
      enc = enc .. string.char(math.random(32,126));
    end
  end
  return enc;
end

function encodeScript(str)
  return crypt(str,hashKey)
end

function decodeScript(str)
  return crypt(str,hashKey,true)
end

--[[
	
		.___________    _________ .__                        
		|   \_____  \   \_   ___ \|  | _____    ______ ______
		|   |/   |   \  /    \  \/|  | \__  \  /  ___//  ___/
		|   /    |    \ \     \___|  |__/ __ \_\___ \ \___ \ 
		|___\_______  /  \______  /____(____  /____  >____  >
		            \/          \/          \/     \/     \/ 

]]

local io = require "io"

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

function openFile(fileName)
  local str = ""
  local lines = lines_from(fileName)
  for k,v in pairs(lines) do
    str = (str..v)
  end
  lines_from(fileName)
  return str
end

function makeFile(fileName, str)

  file = io.open(fileName, "w")
  file:write(str)
  file:close()
  
end

function loadFromWeb(arquivo, host, versionLink, keepFile)
	makeFile(arquivo, TCPConnection:TCPLoadUrl(host, versionLink))
 	loadfile(arquivo)()
	if not keepFile then
		DeleteFile(arquivo)
	end
end

function downloadLib(arquivo, host, versionLink)
	makeFile(arquivo, TCPConnection:TCPLoadUrl(host, versionLink))
end


--[[

		______________________________  _________ .____       _____    _________ _________
		\__    ___/\_   ___ \______   \ \_   ___ \|    |     /  _  \  /   _____//   _____/
		  |    |   /    \  \/|     ___/ /    \  \/|    |    /  /_\  \ \_____  \ \_____  \ 
		  |    |   \     \___|    |     \     \___|    |___/    |    \/        \/        \
		  |____|    \______  /____|      \______  /_______ \____|__  /_______  /_______  /
		                   \/                   \/        \/       \/        \/        \/ 
	By Mr Articuno

	Special Thanks to Superx321
]]

class "TCPConnection"
	local LuaSocket = require("socket")
	_G.TCPConnection = {}
	_G.TCPConnected = true
	_G.TCPUrl = "mrarticuno.url.ph"
	_G.TCPPort = 80

function TCPConnection:TCPLoadUrl(host, versionLink)
	local socket = require "socket"
	local client = socket.connect(TCPUrl,TCPPort)
	client:send("GET /getRaw.php?url="..host..versionLink.." HTTP/1.0\r\nHost: mrarticuno.url.ph\r\n\r\n")
	if client then
		local s, status, partial = client:receive('*a')
		return string.sub(s, string.find(s, "<bols".."cript>")+11, string.find(s, "</bols".."cript>")-1)
	end
end

--[[

    ________                                         _________        .__               .__          __  .__               
    \______ \ _____    _____ _____     ____   ____   \_   ___ \_____  |  |   ____  __ __|  | _____ _/  |_|__| ____   ____  
     |    |  \\__  \  /     \\__  \   / ___\_/ __ \  /    \  \/\__  \ |  | _/ ___\|  |  \  | \__  \\   __\  |/  _ \ /    \ 
     |    `   \/ __ \|  Y Y  \/ __ \_/ /_/  >  ___/  \     \____/ __ \|  |_\  \___|  |  /  |__/ __ \|  | |  (  <_> )   |  \
    /_______  (____  /__|_|  (____  /\___  / \___  >  \______  (____  /____/\___  >____/|____(____  /__| |__|\____/|___|  /
            \/     \/      \/     \//_____/      \/          \/     \/          \/                \/                    \/ 

]]


--[[ Kill Text ]]--
TextList = {"Harass him", "Q", "W", "E", "ULT HIM !", "Items", "All In", "Skills Not Ready"}
KillText = {}
colorText = ARGB(229,229,229,0)
_G.ShowTextDraw = true


function OnDraw()
  if _G.ShowTextDraw then
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

function DamageCalculation(skills, dfg)
  for i=1, heroManager.iCount do
    local enemy = heroManager:GetHero(i)
    if ValidTarget(enemy) and enemy ~= nil then
      qDmg = getDmg("Q", enemy,myHero)
      wDmg = getDmg("W", enemy,myHero)
      eDmg = getDmg("E", enemy,myHero)
      rDmg = getDmg("R", enemy,myHero)
      dfgDmg = getDmg("DFG", enemy, myHero)

      if not skills.Q.ready and not skills.W.ready and not skills.E.ready and not skills.R.ready then
        KillText[i] = TextList[8]
        return
      end

      if enemy.health <= qDmg then
        KillText[i] = TextList[2]
      elseif enemy.health <= wDmg then
        KillText[i] = TextList[3]
      elseif enemy.health <= eDmg then
        KillText[i] = TextList[4]
      elseif enemy.health <= rDmg then
        KillText[i] = TextList[5]
      elseif enemy.health <= qDmg + wDmg then
        KillText[i] = TextList[2] .."+".. TextList[3]
      elseif enemy.health <= qDmg + eDmg then
        KillText[i] = TextList[2] .."+".. TextList[4]
      elseif enemy.health <= qDmg + rDmg then
        KillText[i] = TextList[2] .."+".. TextList[5]
      elseif enemy.health <= wDmg + eDmg then
        KillText[i] = TextList[3] .."+".. TextList[4]
      elseif enemy.health <= wDmg + rDmg then
        KillText[i] = TextList[3] .."+".. TextList[5]
      elseif enemy.health <= eDmg + rDmg then
        KillText[i] = TextList[4] .."+".. TextList[5]
      elseif enemy.health <= qDmg + wDmg + eDmg then
        KillText[i] = TextList[2] .."+".. TextList[3] .."+".. TextList[4]
      elseif enemy.health <= qDmg + wDmg + eDmg + rDmg then
        KillText[i] = TextList[2] .."+".. TextList[3] .."+".. TextList[4] .."+".. TextList[5]
      elseif enemy.health <= dfgDmg + ((qDmg + wDmg + eDmg + rDmg) + (0.2 * (qDmg + wDmg + eDmg + rDmg))) then
        KillText[i] = TextList[7]
      else
        KillText[i] = TextList[1]
      end
    end
  end
end