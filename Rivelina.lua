--[[
	Rivelina [Riven] By
	   _____             _____          __  .__                               ____    .____    .__.__  .__                       .__  .__        
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____    /  _ \   |    |   |__|  | |  |    ____   _________  |  | |__| ____  
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \   >  _ </\ |    |   |  |  | |  |   / ___\ /  _ \__  \ |  | |  |/ __ \ 
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> ) /  <_\ \/ |    |___|  |  |_|  |__/ /_/  >  <_> ) __ \|  |_|  \  ___/ 
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/  \_____\ \ |_______ \__|____/____/\___  / \____(____  /____/__|\___  >
	        \/                \/                    \/           \/                \/         \/            /_____/            \/             \/ 

]]

--if myHero.charName ~= "Riven" then return end


local version = 0.72
local AUTOUPDATE = false


local SCRIPT_NAME = "Rivelina"
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
	SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/Lillgoalie/Rivelina/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/Lillgoalie/Rivelina/master/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Add("mrLib", "https://raw.githubusercontent.com/gmlyra/BolScripts/master/common/mrLib.lua")

RequireI:Check()

if RequireI.downloadNeeded == true then return end

require 'mrLib'
require 'VPrediction'
require 'SOW'

--decodeScript(tcpParser("https://raw.githubusercontent.com/gmlyra/BolScripts/master/file.lua"))
