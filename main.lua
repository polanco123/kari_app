-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local launchArgs = ...

display.setStatusBar( display.DarkStatusBar )

local composer = require("composer")
local storyboard = require("storyboard")
require('include.header')

storyboard.gotoScene("scenes.home")

local grupoLoad
grupoLoad = display.newGroup()

local grupoHeader = display.newGroup()
local header = Header:new()
grupoHeader:insert(header)

local totalPedido = 0

function cargarLoading()
    getLoading()
end

function terminarLoading()
	endLoading()
end

--[[

local function goBack (scene)
	local options = {
		effect = "zoomInOutFade",
        time = 400
        }
	composer.gotoScene( scene , options) 
end

local function onKeyEvent( event )
    local keyName = event.keyName
    local phase = event.phase
 
 	local scene = composer.getSceneName( "current" )
 	local backscene = {
 		--["scripts.menu"] = function () native.requestExit() end,
 		["screens.pedidoNuevoPre"] = function () goBack ("scripts.home") end,
 		["scripts.select"] = function () goBack ("scripts.menu") end,
 		["scripts.puzzle"] = function () goBack ("scripts.select") end,
 		["scripts.language"] = function () goBack ("scripts.menu") end,
 		["scripts.aboutus"] = function () goBack ("scripts.menu") end
 	}

    -- Listening for B as well so can test Android Back with B key
    if ("back" == keyName and phase == "down") or ("b" == keyName and phase == "down" and system.getInfo("environment") == "simulator")  then 
        --print("Back", scene)
 		if (backscene[scene]) then
 			backscene[scene]()
 			return true
 		end
 		
    end

   if event.keyName == 's' and event.phase == 'down' and system.getInfo("environment") == "simulator" then
     local scene = display.captureScreen(false)
     --if scene then
     --   print( "screenshot" )
       display.save(scene, {filename = display.pixelWidth .. 'x' .. display.pixelHeight .. '_' .. math.floor(system.getTimer()) .. '.png', isFullResolution=false})
       scene:removeSelf( )
       return true
     --end
   end

    return false
end
Runtime:addEventListener("key", onKeyEvent)

]]