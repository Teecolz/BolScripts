--[[
	   _____             _____          __  .__                              
	  /     \_______    /  _  \________/  |_|__| ____  __ __  ____   ____ 
	 /  \ /  \_  __ \  /  /_\  \_  __ \   __\  |/ ___\|  |  \/    \ /  _ \
	/    Y    \  | \/ /    |    \  | \/|  | |  \  \___|  |  /   |  (  <_> )
	\____|__  /__|    \____|__  /__|   |__| |__|\___  >____/|___|  /\____/
	        \/                \/                    \/           \/

	Mechanics Series Laucher

]]


require 'mrLib'

_G.ScriptLoaded = false
_G.LibsChecked = false


local ScriptLink = {
	SOW = { filename = "SOW.lua", host = "raw.github.com" , versionLink = "/Hellsing/BoL/master/common/SOW.lua" , isLib = true , forceUpdate = false },
	VPrediction = { filename = "VPrediction.lua", host = "raw.github.com" , versionLink = "/Hellsing/BoL/master/common/VPrediction.lua" , isLib = true , forceUpdate = false },
	Prodiction = { filename = "Prodiction.lua", host = "bitbucket.org" , versionLink = "/Klokje/public-klokjes-bol-scripts/raw/ec830facccefb3b52212dba5696c08697c3c2854/Test/Prodiction/Prodiction.lua" , isLib = true , forceUpdate = false },
	Tristana = { filename = "TristanaMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/TristanaMechanics.lua" , isLib = false , forceUpdate = true },
	Elise = { filename = "EliseMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/EliseMechanics.lua" , isLib = false , forceUpdate = true },
	Lucian = { filename = "LucianMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/LucianMechanics.lua" , isLib = false , forceUpdate = true },
	Jinx = { filename = "JinxMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/JinxMechanics.lua" , isLib = false , forceUpdate = true },
	Gragas = { filename = "GragasMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/GragasMechanics.lua" , isLib = false , forceUpdate = true },
	Viktor = { filename = "ViktorMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/ViktorMechanics.lua" , isLib = false , forceUpdate = true },
	Chogath = { filename = "ChogathMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/ChogathMechanics.lua" , isLib = false , forceUpdate = true },
	Kayle = { filename = "KayleMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/KayleMechanics.lua" , isLib = false , forceUpdate = true },
	Karthus = { filename = "KarthusMechanics.lua", host = "raw.github.com" , versionLink = "/gmlyra/BolScripts/master/KarthusMechanics.lua" , isLib = false , forceUpdate = true },
}

function OnLoad()
	if file_exists(LIB_PATH.."mrLib.lua") then
		require 'mrLib'
	else
		print('You must have mrLib.lua to use this laucher')
		return
	end

	checkLibs()

	if not _G.ScriptLoaded then
		if not ScriptLink[myHero.charName].forceUpdate then
			if not file_exists(SCRIPT_PATH..ScriptLink[myHero.charName].filename) then
				loadFromWeb(SCRIPT_PATH..ScriptLink[myHero.charName].filename, ScriptLink[myHero.charName].host, ScriptLink[myHero.charName].versionLink, true)
			else
				loadfile(SCRIPT_PATH..ScriptLink[myHero.charName].filename)()
			end
		else
			loadFromWeb(SCRIPT_PATH..ScriptLink[myHero.charName].filename, ScriptLink[myHero.charName].host, ScriptLink[myHero.charName].versionLink, false)
		end
	end
end

function checkLibs()
	for i,v in ipairs(ScriptLink) do
		if ScriptLink[v].isLib then
			if not file_exists(LIB_PATH..ScriptLink[v].filename) or ScriptLink[v].forceUpdate then
				downloadLib(ScriptLink[v].filename, ScriptLink[v].host, ScriptLink[v].versionLink)
			end
		end
	end
end

local io = require "io"

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- End of Laucher --