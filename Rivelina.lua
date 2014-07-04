local o=.72
local r=false
local e="Rivelina"local l="https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"local i=LIB_PATH.."SourceLib.lua"if FileExist(i)then
require("SourceLib")else
DOWNLOADING_SOURCELIB=true
DownloadFile(l,i,function()print("Required libraries downloaded successfully, please reload")end)end
if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...")return end
if r then
SourceUpdater(e,o,"raw.github.com","/Lillgoalie/Rivelina/master/"..e..".lua",SCRIPT_PATH..GetCurrentEnv().FILE_NAME,"/Lillgoalie/Rivelina/master/"..e..".version"):CheckUpdate()end
local e=Require("SourceLib")e:Add("vPrediction","https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")e:Add("SOW","https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")e:Add("mrLib","https://raw.githubusercontent.com/gmlyra/BolScripts/master/common/mrLib.lua")e:Check()if e.downloadNeeded==true then return end
require'mrLib'require'VPrediction'require'SOW'
