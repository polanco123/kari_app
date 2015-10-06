
local Sprites = require('resources.Sprites')
local storyboard = require( "storyboard" )


local txtCiudad = {}
local textoCiudad = ""
local menuScreenLeft = nil
local menuScreenRight = nil
local groupSearchTool = display.newGroup()
local grpLoading

Header = {}

function Header:new()
    -- Variables
	
	local fondoLoading
    local isWifiBle = true
    local self = display.newGroup()


	function getNoContent(obj, txtData)
		if not grpLoading then
			grpLoading = display.newGroup()
			obj:insert(grpLoading)
			
			local noData = display.newImage( "img/btn/noData.png" )
			noData.x = display.contentWidth / 2
			noData.y = (obj.height / 3) - 35
			grpLoading:insert(noData) 
			
			local title = display.newText( txtData, 0, 30, native.systemFont, 16)
			title:setFillColor( .3, .3, .3 )
			title.x = display.contentWidth / 2
			title.y = (obj.height / 3) + 80
			grpLoading:insert(title) 
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
	
	-- regresamos a la escena de home
	function returnHome()
		Globals.scene = nil
		Globals.scene = {}
		storyboard.gotoScene( "src.Home", { time = 400, effect = "slideRight" })
	end

	local function onKeyEvent( event )

	   local phase = event.phase
	   local keyName = event.keyName
	   print( event.phase, event.keyName )

	   if ( "back" == keyName and phase == "up" ) then
	      if ( storyboard.currentScene == "splash" ) then
	         native.requestExit()
	      else
	         if ( storyboard.isOverlay ) then
	            storyboard.hideOverlay()
	         else
	            local lastScene = storyboard.returnTo
	            print( "previous scene", lastScene )
	            if ( lastScene ) then
	               storyboard.gotoScene( lastScene, { effect="crossFade", time=500 } )
	            else
	               native.requestExit()
	            end
	         end
	      end
	   end

	   if ( keyName == "volumeUp" and phase == "down" ) then
	      local masterVolume = audio.getVolume()
	      print( "volume:", masterVolume )
	      if ( masterVolume < 1.0 ) then
	         masterVolume = masterVolume + 0.1
	         audio.setVolume( masterVolume )
	      end
	      return true
	   elseif ( keyName == "volumeDown" and phase == "down" ) then
	      local masterVolume = audio.getVolume()
	      print( "volume:", masterVolume )
	      if ( masterVolume > 0.0 ) then
	         masterVolume = masterVolume - 0.1
	         audio.setVolume( masterVolume )
	      end
	      return true
	   end
	   return false  --SEE NOTE BELOW
	end

	--add the key callback
	Runtime:addEventListener( "key", onKeyEvent )

	return self
end