--[[

   _____             _____          __  .__                            
  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____  
 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \ 
/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/ 
        \/                \/                    \/           \/        

]]

local function convert( chars, dist, inv )
  return string.char( ( string.byte( chars ) - 32 + ( inv and -dist or dist ) ) % 95 + 32 )
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

function decodeScript(str,key)
  return crypt(str,key,true)
end

------------------------
------ TCPUpdater ------
------------------------
class "TCPUpdater"
function TCPUpdater:__init()
  _G.TCPUpdates = {}
  _G.TCPUpdaterLoaded = true
  self.AutoUpdates = {}
  self.LuaSocket = require("socket")
  AddTickCallback(function() self:GetOnlineVersion() end)
  AddTickCallback(function() self:GetScriptPath() end)
  AddTickCallback(function() self:GetLocalVersion() end)
  AddTickCallback(function() self:DownloadUpdate() end)
end

function TCPUpdater:GetScriptPath()
  for i=1,#self.AutoUpdates do
    if not self.AutoUpdates[i]["ScriptPath"] then
      if self.AutoUpdates[i]["Type"] == "Lib" then
        self.AutoUpdates[i]["ScriptPath"] = LIB_PATH..self.AutoUpdates[i]["Name"]..".lua"
      else
        self.AutoUpdates[i]["ScriptPath"] = SCRIPT_PATH..self.AutoUpdates[i]["Name"]..".lua"
      end
    end
  end
end

function TCPUpdater:GetOnlineVersion()
  for i=1,#self.AutoUpdates do
    if not self.AutoUpdates[i]["ServerVersion"] and not self.AutoUpdates[i]["VersionSocket"] then
      self.AutoUpdates[i]["VersionSocket"] = self.LuaSocket.connect("sx-bol.eu", 80)
      self.AutoUpdates[i]["VersionSocket"]:send("GET /BoL/TCPUpdater/GetScript.php?script="..self.AutoUpdates[i]["Host"]..self.AutoUpdates[i]["VersionLink"].."&rand="..tostring(math.random(1000)).." HTTP/1.0\r\n\r\n")
    end

    if not self.AutoUpdates[i]["ServerVersion"] and self.AutoUpdates[i]["VersionSocket"] then
      self.AutoUpdates[i]["VersionSocket"]:settimeout(0)
      self.AutoUpdates[i]["VersionReceive"], self.AutoUpdates[i]["VersionStatus"] = self.AutoUpdates[i]["VersionSocket"]:receive('*a')
    end

    if self.AutoUpdates[i]["VersionStatus"] ~= 'timeout' and self.AutoUpdates[i]["VersionReceive"] == nil then
      self.AutoUpdates[i]["VersionSocket"] = nil
    end

    if not self.AutoUpdates[i]["ServerVersion"] and self.AutoUpdates[i]["VersionSocket"] and self.AutoUpdates[i]["VersionStatus"] ~= 'timeout' and self.AutoUpdates[i]["VersionReceive"] ~= nil then
      self.AutoUpdates[i]["ServerVersion"] = tonumber(string.sub(self.AutoUpdates[i]["VersionReceive"], string.find(self.AutoUpdates[i]["VersionReceive"], "<bols".."cript>")+11, string.find(self.AutoUpdates[i]["VersionReceive"], "</bols".."cript>")-1))
    end
  end
end

function TCPUpdater:GetLocalVersion()
  for i=1,#self.AutoUpdates do
    if not self.AutoUpdates[i]["LocalVersion"] and self.AutoUpdates[i]["ScriptPath"] then
      if FileExist(self.AutoUpdates[i]["ScriptPath"]) then
        self.FileOpen = io.open(self.AutoUpdates[i]["ScriptPath"], "r")
        self.FileString = self.FileOpen:read("*a")
        self.FileOpen:close()
        VersionPos = self.FileString:find(self.AutoUpdates[i]["VersionSearchString"])
        if VersionPos ~= nil then
          self.VersionString = string.sub(self.FileString, VersionPos + string.len(self.AutoUpdates[i]["VersionSearchString"]) + 1, VersionPos + string.len(self.AutoUpdates[i]["VersionSearchString"]) + 11)
          self.AutoUpdates[i]["LocalVersion"] = tonumber(string.match(self.VersionString, "%d *.*%d"))
        end
        if self.AutoUpdates[i]["LocalVersion"] == 2.431 then self.AutoUpdates[i]["LocalVersion"] = 99 end -- VPred 2.431
        if self.AutoUpdates[i]["LocalVersion"] == nil then self.AutoUpdates[i]["LocalVersion"] = 0 end
      else
        self.AutoUpdates[i]["LocalVersion"] = 0
      end
    end
  end
end

function TCPUpdater:DownloadUpdate()
  for i=1,#self.AutoUpdates do
    if self.AutoUpdates[i]["LocalVersion"] and self.AutoUpdates[i]["ServerVersion"] and self.AutoUpdates[i]["ServerVersion"] > self.AutoUpdates[i]["LocalVersion"] and not self.AutoUpdates[i]["Updated"] then
      if not self.AutoUpdates[i]["ScriptSocket"] then
        self.AutoUpdates[i]["ScriptSocket"] = self.LuaSocket.connect("sx-bol.eu", 80)
        self.AutoUpdates[i]["ScriptSocket"]:send("GET /BoL/TCPUpdater/GetScript.php?script="..self.AutoUpdates[i]["Host"]..self.AutoUpdates[i]["ScriptLink"].."&rand="..tostring(math.random(1000)).." HTTP/1.0\r\n\r\n")
      end

      if self.AutoUpdates[i]["ScriptSocket"] then
        self.AutoUpdates[i]["ScriptReceive"] = self.AutoUpdates[i]["ScriptSocket"]:receive('*a')
      end

      if self.AutoUpdates[i]["ScriptSocket"] and self.AutoUpdates[i]["ScriptReceive"] ~= nil and not self.AutoUpdates[i]["Updated"] then
        self.FileOpen = io.open(self.AutoUpdates[i]["ScriptPath"], "w+")
        self.FileOpen:write(string.sub(self.AutoUpdates[i]["ScriptReceive"], string.find(self.AutoUpdates[i]["ScriptReceive"], "<bols".."cript>")+11, string.find(self.AutoUpdates[i]["ScriptReceive"], "</bols".."cript>")-1))
        self.FileOpen:close()
        if self.AutoUpdates[i]["ScriptRequire"] ~= nil and self.AutoUpdates[i]["Type"] == "Lib" then
          if self.AutoUpdates[i]["ScriptRequire"] == "VIP" then
            if VIP_USER then
              loadfile(LIB_PATH ..self.AutoUpdates[i]["Name"]..".lua")()
            end
          else
            loadfile(LIB_PATH ..self.AutoUpdates[i]["Name"]..".lua")()
          end
        end
        self.AutoUpdates[i]["Updated"] = true
        _G.TCPUpdates[self.AutoUpdates[i]["Name"]] = true
      end
    end

    if self.AutoUpdates[i]["LocalVersion"] and self.AutoUpdates[i]["ServerVersion"] and self.AutoUpdates[i]["ServerVersion"] <= self.AutoUpdates[i]["LocalVersion"] and not self.AutoUpdates[i]["Updated"] then
      if self.AutoUpdates[i]["ScriptRequire"] ~= nil and self.AutoUpdates[i]["Type"] == "Lib" then
        if self.AutoUpdates[i]["ScriptRequire"] == "VIP" then
          if VIP_USER then
            loadfile(LIB_PATH..self.AutoUpdates[i]["Name"]..".lua")()
          end
        else
          loadfile(LIB_PATH..self.AutoUpdates[i]["Name"]..".lua")()
        end
      end
      self.AutoUpdates[i]["Updated"] = true
      _G.TCPUpdates[self.AutoUpdates[i]["Name"]] = true
    end
  end
end

function TCPUpdater:AddScript(Name, Type, Host, ScriptLink, VersionLink, VersionSearchString, ScriptRequire, ServerVersion)
  table.insert(self.AutoUpdates, {["Name"] = Name, ["Type"] = Type, ["Host"] = Host, ["ScriptLink"] = ScriptLink, ["VersionLink"] = VersionLink, ["VersionSearchString"] = VersionSearchString, ["ScriptRequire"] = ScriptRequire, ["ServerVersion"] = ServerVersion})
  _G.TCPUpdates[Name] = false
end