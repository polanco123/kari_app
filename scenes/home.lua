-----------------------------------------------------------------------------------------
--
-- home.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

-- requires--
local widget = require("widget")
local storyboard = require("storyboard")
--local conexionServer = require ("include.conexion_server")
local conexionSQLite = require ("include.conexion_sqlite")
require('include.header')
local db_pedido = require ("include.db_pedido")
local db_sincronizacion = require ("include.db_sincronizacion")
--db
--iniciar base de datos
conexionSQLite.setupSquema()

local scene = storyboard.newScene()

local grupoHome = display.newGroup()
local tableHome

--variables del screen
local top = display.topStatusBarContentHeight
local width_s = display.contentWidth
local height_s = display.contentHeight
local poscTabla = height_s/2 + 25
local posicion_y = 5

--variables de tabla pedidos - home
local tdHeaderName = {'Folio','Sucursal','Cliente','Fecha','Estado',''}
local tdHeaderWitdh = {80,220,220,110,130,75}
local filaPedido = {}
local folio = {}
local sucursal = {}
local cliente = {}
local fecha = {}
local estado = {}
local labelVer = {}

local contPedido = 0

function verCatalogo( event )	
	if ( event.phase == "ended") then
		cargarLoading()
		timeMarker = timer.performWithDelay( 250, function ( )
			storyboard.gotoScene("screens.catalogoHome")
	    end, 1)
    end
end

function verPedido( event )
	if ( event.phase == "ended") then
		print(event.target.idPedido)
		print("llega")
		cargarLoading()
		local options = { params = { idPedido = event.target.idPedido  } }
		timeMarker = timer.performWithDelay( 250, function ( )
			storyboard.gotoScene("scenes.verPedido2", options)
			
	    end, 1)
	    --storyboard.gotoScene("scenes.pedidoVer", options)
    end
end

function verAgregarPedido( event )
	cargarLoading()
		timeMarker = timer.performWithDelay( 250, function ( )
		    storyboard.gotoScene("scenes.pedidoNuevoPre")
		end, 1)
	--if ( event.phase == "ended" or event.phase == "submitted" ) then  
		--print("entra2")	
	--end
end

function verAgregarCliente( event )
	if ( event.phase == "ended") then
		cargarLoading()
		timeMarker = timer.performWithDelay( 250, function ( )
			storyboard.gotoScene("screens.clienteNuevo")
	    end, 1)
	end
end

function verAgregarSucursal( event )
	if ( event.phase == "ended") then
		cargarLoading()
		timeMarker = timer.performWithDelay( 250, function ( )
			storyboard.gotoScene("screens.sucursalNueva")
	    end, 1)
	end
end

function sincronizarDB( event )
	if ( event.phase == "ended") then
		cargarLoading()
		--comprobar si hay internet
		if db_sincronizacion.getComprobarConexion() then
			local seNecesitaSync = db_sincronizacion.getComprobarSincronizacion()
		else
			print("no hay internet")
			endLoading()
		end
	end	
end

function empezarSincronizacion( arraySync )
	local stringSync = ''
	local msj = false
	--checar en todas las tablas
	if arraySync["catalogo"] then
		stringSync = stringSync .. " catalogo "
		msj = true
	end
	if arraySync["pedido"] then
		stringSync = stringSync .. " pedido "
		msj = true
	end
	if arraySync["cliente"] then
		stringSync = stringSync .. " cliente "
		msj = true
	end
	if arraySync["sucursal"] then
		stringSync = stringSync .. " sucursal "
		msj = true
	end

	endLoading()

	local function onComplete( event )
		if event.action == "clicked" then
	        local i = event.index
	        if i == 1 then
	            -- Do nothing; dialog will simply dismiss
	        elseif i == 2 then
	        	--iniciar la sincronizacion
	            print("iniciando sinc")
	            print(arraySync["pedido"])
	            if arraySync["pedido"] then
	            	print("iniciando sinc de pedido")
	            	db_sincronizacion.sincronizarPedidos()
					
				end
			end
	    end
	end

	if msj then
		native.showAlert( "Sincronización requerida.", "Se detectó que se necesita sincronizacion en: " .. stringSync .. ". ¿Sincronizar ahora?", { "No", "Si"}, onComplete )           
	else
		native.showAlert( "No se necesita sincronización.", "No es necesaria la sincronización con el servidor: " .. stringSync, { "OK"})           
	end

end


function llenadoTablaPedidosHome(fila)
	contPedido = contPedido + 1
	crearFilaH(fila, contPedido)
end


function crearFilaH( items, posc )

	print("posicion y: " .. posicion_y)

	local lineS = {}
			
	--fondo gris de la fila
	filaPedido[posc] = display.newRect( width_s/2, posicion_y, width_s - 2, 75)
	filaPedido[posc].anchorY = 0
	filaPedido[posc]:setFillColor( 242/255, 243/255, 244/255 )
	tableHome:insert(filaPedido[posc])

	local poscXL = 0
	
	--lineas que dividen los campos de la fila
	for i = 1, 5, 1 do
	
		poscXL= tdHeaderWitdh[i] + poscXL
		
		lineS[i] = display.newRect( poscXL, posicion_y , 2, 75) --x, y, width, height
		lineS[i].anchorX = 0
		lineS[i].anchorY = 0
		lineS[i]:setFillColor( 1 )
		tableHome:insert(lineS[i])
		
	end

	--llenado de campos de la fila del pedido
	folio[posc] = display.newText( {
		text = items.folio,     
		x = tdHeaderWitdh[1]/2, y = posicion_y + 30, width = tdHeaderWitdh[1],
		font = native.BrushScriptStd, fontSize = 20, align = "center"
	})
	folio[posc]:setFillColor( 0 )
	tableHome:insert(folio[posc])
	folio[posc].y = folio[posc].y + folio[posc].height/2
	poscXL = tdHeaderWitdh[1]

	sucursal[posc] = display.newText( {
		text = items.nombresucursal,     
		x = tdHeaderWitdh[2]/2 + poscXL + 5, y = posicion_y + 10, width = tdHeaderWitdh[2] - 15,
		font = native.BrushScriptStd, fontSize = 14, align = "center"
	})
	sucursal[posc]:setFillColor( 0 )
	tableHome:insert(sucursal[posc])
	sucursal[posc].y = sucursal[posc].y + sucursal[posc].height/2
	poscXL =  poscXL + tdHeaderWitdh[2]

	cliente[posc] = display.newText( {
		text = items.razonsocialcliente,     
		x = tdHeaderWitdh[3]/2 + poscXL + 5, y = posicion_y + 10, width = tdHeaderWitdh[3] - 15,
		font = native.BrushScriptStd, fontSize = 14, align = "center"
	})
	cliente[posc]:setFillColor( 0 )
	tableHome:insert(cliente[posc])
	cliente[posc].y = cliente[posc].y + cliente[posc].height/2
	poscXL =  poscXL + tdHeaderWitdh[3]

	fecha[posc] = display.newText( {
		text = items.fechapedido,     
		x = tdHeaderWitdh[4]/2 + poscXL, y = posicion_y + 30, width = tdHeaderWitdh[4],
		font = native.BrushScriptStd, fontSize = 16, align = "center"
	})
	fecha[posc]:setFillColor( 0 )
	tableHome:insert(fecha[posc])
	fecha[posc].y = fecha[posc].y + fecha[posc].height/2
	poscXL =  poscXL + tdHeaderWitdh[4]

	--cambia el estado dependiendo el tipo
	local typeEstado = "Por entregar"
	
	if items.estado == "2" then
		typeEstado = "Entregado"
	end

	estado[posc] = display.newText( {
		text = typeEstado,     
		x = tdHeaderWitdh[5]/2 + poscXL, y = posicion_y + 30, width = tdHeaderWitdh[5],
		font = native.BrushScriptStd, fontSize = 16, align = "center"
	})
	estado[posc]:setFillColor( 0 )
	tableHome:insert(estado[posc])
	estado[posc].y = estado[posc].y + estado[posc].height/2

	poscXL =  poscXL + tdHeaderWitdh[5] + 10


	labelVer[posc] =  widget.newButton({
    	label = "Ver",
    	onEvent = verPedido,
    	emboss = true,
    	shape = "roundedRect",
    	labelColor = { default = { 1, 1, 1 }, over = { 163, 25, 12} },
    	width = tdHeaderWitdh[6],
    	height = 30,
    	cornerRadius = 3
    })
    labelVer[posc].x = tdHeaderWitdh[6]/2 + poscXL
    labelVer[posc].y = posicion_y + 35
    labelVer[posc].idPedido = items.id
    labelVer[posc]:setFillColor(.05, .36, .30)
    tableHome:insert(labelVer[posc])

   	print("p_y: " .. posicion_y)



	--[[labelVer[posc] = display.newText( {
		text = "Ver",     
		x = tdHeaderWitdh[6]/2 + poscXL, y = posicion_y + 35, width = tdHeaderWitdh[6],
		font = native.BrushScriptStd, fontSize = 20, align = "center"
	})
	labelVer[posc].idPedido = items.id
	labelVer[posc]:addEventListener("tap", verPedido )
	labelVer[posc]:setFillColor( 0 )
	tableHome:insert(labelVer[posc])]]

    posicion_y = posicion_y + filaPedido[posc].height + 5

end

function scene:createScene( event )

end

function scene:enterScene( event )
	vw = self.view

	vw:insert(grupoHome)

	local thHeaderS = {}
	local tdTxtHeader = {}
	local poscXH = 1

	posicion_y = 5


	-- background
	local background = display.newRect( 0, top, width_s, height_s - top) 
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( 236/255, 240/255, 241/255 )
	grupoHome:insert(background)

	-- rectangulo negro top
	local recAcciones = display.newRect( 0, top, width_s, 45)
	recAcciones.anchorX = 0
	recAcciones.anchorY = 0
	recAcciones:setFillColor( 0 )
	grupoHome:insert(recAcciones)

	 local btnSincronizar =  widget.newButton({
    	label = "SINCRONIZAR",
    	onEvent = sincronizarDB,
    	emboss = true,
    	shape = "roundedRect",
    	labelColor = { default = { 0, 0, 0 }, over = { 163, 25, 12} },
    	width = 150,
    	height = 32,
    	cornerRadius = 3
    })
    btnSincronizar.x = width_s - 110
    btnSincronizar.y = top + 20
    grupoHome:insert(btnSincronizar)

    local btnVerCatalogo =  widget.newButton({
    	label = "Ver catálogo",
    	onEvent = verCatalogo,
    	emboss = true,
    	shape = "roundedRect",
    	labelColor = { default = { 0, 0, 0 }, over = { 163, 25, 12} },
    	width = 150,
    	height = 32,
    	cornerRadius = 3
    })
    btnVerCatalogo.x = width_s / 2
    btnVerCatalogo.y = top + 20
   	grupoHome:insert(btnVerCatalogo)

	--principales acciones de home (nuevo pedido, nuevo cliente y nueva sucursal)
	local btnNuevoPedido = display.newRect( width_s /6  , height_s / 4  + top, width_s/ 4, height_s / 4)
	btnNuevoPedido:setFillColor( 1 )
	btnNuevoPedido:addEventListener('tap', verAgregarPedido)
	grupoHome:insert(btnNuevoPedido)

	local btnNuevoCliente = display.newRect( width_s /2  , height_s / 4 + top, width_s/ 4, height_s / 4)
	btnNuevoCliente:setFillColor( 1 )
	btnNuevoCliente:addEventListener('tap', verAgregarCliente) 
	grupoHome:insert(btnNuevoCliente)

	local btnNuevaSucursal = display.newRect( width_s / 1.2 , height_s / 4 + top, width_s/ 4, height_s / 4)
	btnNuevaSucursal:setFillColor( 1 )
	btnNuevaSucursal:addEventListener('tap', verAgregarSucursal)
	grupoHome:insert(btnNuevaSucursal)

	local labelNuevoPedido = display.newText( {
        text = "Nuevo Pedido",     
        x = width_s /6 , y =  height_s / 4 + top + 32, width_s/ 4 - 20,
        font = native.BrushScriptStd, fontSize = 24, align = "center"
    })
    labelNuevoPedido:setFillColor(255/255, 210/255, 79/255 )
    grupoHome:insert(labelNuevoPedido)

    local labelNuevoCliente = display.newText( {
        text = "Nuevo Cliente",     
        x = width_s /2, y =  height_s / 4 + top + 32, width_s/ 4 - 20,
        font = native.BrushScriptStd, fontSize = 24, align = "center"
    })
    labelNuevoCliente:setFillColor(41/255, 128/255, 185/255 )
    grupoHome:insert(labelNuevoCliente)

    local labelNuevaSucursal = display.newText( {
        text = "Nueva Sucursal",     
        x = width_s / 1.2 , y =  height_s / 4 + top + 32, width_s/ 4 - 20,
        font = native.BrushScriptStd, fontSize = 24, align = "center"
    })
    labelNuevaSucursal:setFillColor(192/255, 57/255, 43/255)
    grupoHome:insert(labelNuevaSucursal)

	local imageBtnNuevoPedido = display.newImage("img/app/iconoNuevoPedido.png" , width_s /6  , height_s / 4 + top - 25)
	grupoHome:insert(imageBtnNuevoPedido)

	local imageBtnNuevoCliente = display.newImage("img/app/iconoNuevoCliente.png" , width_s /2   , height_s / 4 + top - 25)
	grupoHome:insert(imageBtnNuevoCliente)

	local imageBtnNuevaSucursal = display.newImage("img/app/iconoNuevaSucursal.png" , width_s / 1.2   , height_s / 4 + top - 25)
	grupoHome:insert(imageBtnNuevaSucursal)

	--tabla de pedidos del vendedor

	-- header de la tabla de pedidos de home (barra gris)
	local thHeader = display.newRoundedRect ( width_s/2, poscTabla - 50, width_s - 6, 50,5) 
	thHeader.anchorY = 0
	thHeader:setFillColor( 189/255, 195/255, 199/255 )
	grupoHome:insert(thHeader)

	local poscXL = 0

	-- impresion de los headers
	for i = 1, 5, 1 do
	
		poscXL = tdHeaderWitdh[i] + poscXL
		
		--separadores
		thHeaderS[i] = display.newRect( poscXL, poscTabla - 50 , 2, 50) --x, y, width, height
		thHeaderS[i].anchorY = 0
		thHeaderS[i]:setFillColor( 1 )
		grupoHome:insert(thHeaderS[i])
		
		tdTxtHeader[i] = display.newText( {
            text = tdHeaderName[i],     
            x = poscXH + tdHeaderWitdh[i]/2, y = poscTabla - 25, width = tdHeaderWitdh[i],
            font = native.BrushScriptStd, fontSize = 22, align = "center"
        })
        tdTxtHeader[i]:setFillColor( 0 )
        grupoHome:insert(tdTxtHeader[i])
	
		poscXH = poscXH + tdHeaderWitdh[i]
	
	end

	tableHome = widget.newScrollView{
		top = height_s / 2 + 25,
		left = 0,
		width = width_s,
		height = height_s / 2 - 30,
		horizontalScrollDisabled = true,
		verticalScrollDisabled = false,
		isBounceEnabled = false,
		backgroundColor = { 1 }
	}
	grupoHome:insert(tableHome)

	--llenado de la tabla de pedidos del vendedor
	db_pedido.getPedidosVendedor()

	print(system.DocumentsDirectory)

end

function scene:exitScene( event )

end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene",  scene)
scene:addEventListener("exitScene",   scene)

return scene


