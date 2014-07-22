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