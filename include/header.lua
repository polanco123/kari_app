
local Sprites = require('resources.Sprites')
local storyboard = require( "storyboard" )
local Globals = require('include.Globals')

local grpLoading

local btnBackFunction = false

local toolbarMenu


Header = {}

function Header:new()
    -- Variables
	
	local fondoLoading
    local isWifiBle = true
    local self = display.newGroup()

    --obtenemos el grupo de cada escena
	function getScreen()
		local currentScene = storyboard.getCurrentSceneName()
		if currentScene == "src.Home" then
			return getScreenH()
		elseif currentScene == "src.Event" then
			return getScreenE()
		elseif currentScene == "src.Coupon" then
			return getScreenC()
		elseif currentScene == "src.Partner" then
			return getScreenP()
		elseif currentScene == "src.PartnerList" then
			return getScreenPL()
        elseif currentScene == "src.PartnerWelcome" then
			return getScreenWP()
		elseif currentScene == "src.Mapa" then
			return getScreenM()
		elseif currentScene == "src.Message" then
            return getScreenMe()
		elseif currentScene == "src.Notifications" then
			return getScreenN()
		elseif currentScene == "src.Wallet" then
			return getScreenW()
		elseif currentScene == "src.Code" then
			return getScreenRC()
		end
		
	end

	function sinAccion( event )
		return true
	end

	function endLoading()
		if grpLoading then
			grpLoading:removeSelf()
			grpLoading = nil
		end
	end

	function getLoading()
	--function getLoading(obj)
		if not grpLoading then
		
			grpLoading = display.newGroup()
			grpLoading:toFront()
			--obj:insert(grpLoading)

			-- Sprite and text
			local sheet = graphics.newImageSheet(Sprites.loading.source, Sprites.loading.frames)
			--local sheet = graphics.newImageSheet("img/loading.png", options)


			--local frame1 = display.newImage( sheet, 1)
			--local frame1 = display.newImage( sheet, 2)

			
			local loadingBottom = display.newSprite(sheet, Sprites.loading.sequences)
			loadingBottom.x = display.contentWidth / 2
			--loadingBottom.y = obj.height / 3
			loadingBottom.y = display.contentHeight / 2
			grpLoading:insert(loadingBottom)
			loadingBottom:setSequence("play")
			loadingBottom:play()

			local title = display.newText( "Cargando...", 0, 30, native.systemFont, 16)
			title:setFillColor( .3, .3, .3 )
			title.x = display.contentWidth / 2
			title.y = display.contentHeight / 2 + 40
			grpLoading:insert(title)

			fondoLoading = display.newRect( 0, 30, display.contentWidth, display.contentHeight  - 30) --x, y, width, height
		    fondoLoading.anchorX = 0
		    fondoLoading.anchorY = 0
		    fondoLoading:setFillColor( 0 )
		    fondoLoading.alpha = .5
		    fondoLoading:addEventListener( 'tap', sinAccion)
		    fondoLoading:addEventListener( 'tocuh', sinAccion )
		    grpLoading:insert(fondoLoading)


		else
			--obj:insert(grpLoading)
			grpLoading:removeSelf()
			grpLoading = nil
			getLoading()
		end
	end
	
	---regresamos a la scena anterior
	function returnScene( event )
	
        -- Obtenemos escena anterior y eliminamos del arreglo
        if #Globals.scene > 2 then
			
            local previousScene = Globals.scene[#Globals.scene - 1]
			local currentScene = Globals.scene[#Globals.scene]
			
			if previousScene == currentScene then
				while previousScene == currentScene do
					previousScene = Globals.scene[#Globals.scene - 1]
					table.remove(Globals.scene, #Globals.scene)
				end
				
			else
				table.remove(Globals.scene, #Globals.scene)
				table.remove(Globals.scene, #Globals.scene)
			end
			
			storyboard.gotoScene( previousScene, { time = 400, effect = "slideRight" })
			
		else
			Globals.scene = nil
			Globals.scene = {}
			storyboard.gotoScene( "scenes.home", { time = 400, effect = "slideRight" })
			Globals.scene[1] = "scenes.home"
        end
		
    end

	return self
end

-- Return button Android Devices
local function onKeyEventBack( event )
	local phase = event.phase
	local keyName = event.keyName
	local platformName = system.getInfo( "platformName" )
	
	if( "back" == keyName and phase == "up" ) then
		--native.showAlert( "Go Deals", "hola" , { "OK"})
		if ( platformName == "Android" ) then
			--native.showAlert( "Go Deals", Globals.scene[#Globals.scene] , { "OK"})
			--native.showAlert( "Go Deals", modalActive , { "OK"})
			returnScene()
			return true
			
		end
	end
	return false
end

if btnBackFunction == false then
	btnBackFunction = true
	Runtime:addEventListener( "key", onKeyEventBack )
end