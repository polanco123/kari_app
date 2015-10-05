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

--local totalPedido = 0

function cargarLoading()
    getLoading()
end

function terminarLoading()
	endLoading()
end