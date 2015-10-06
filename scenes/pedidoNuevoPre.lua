-----------------------------------------------------------------------------------------
--
-- sucursalNuevo.lua
--
-----------------------------------------------------------------------------------------

-- requires--
require('include.header')
local widget = require("widget")
local storyboard = require("storyboard")
local Globals = require('include.Globals')

local screen = storyboard.newScene()

local grupoPedidoNuevoPre = display.newGroup()

local grupoDroboxOptionCliente = display.newGroup()
local grupoDroboxOptionSucursal = display.newGroup()

local mainActions
local tableHome 

local top = display.topStatusBarContentHeight
local width_s = display.contentWidth
local height_s = display.contentHeight
local poscYCon = height_s/2
local posicion_y = 5
local poscX = 1
local cont = 0

local txtSucursalNumero
local txtSucursalNombre

local idsClientes = {}
local razonesSocialesClientes = {}
local cont = 0

local reinicioSucursal = 0 --para reiniciar el combo de sucursal y aparezcan bien as opcines
local labelOpcionSucursal = {}
local bgOptionSucursal = {}
local opcionesSucursal = {}
local totalSucursales = 0 -- numero de sucursales que tiene el cliente seleccionado
------------------------
--------input-----------
------------------------

local bgRazonCliente
local labelSelectCliente
local srvOptionCliente

local bgDroboxOptionCliente

local opcionesCliente = {}
------------------



local bgNombreSucursal
local labelSelectSucursal
local srvOptionSucursal
local bgDroboxOptionSucursal

local db_sincronizacion = require ("include.db_sincronizacion")
local db_cliente = require ("include.db_cliente")
local db_sucursal = require ("include.db_sucursal")


local poscY = 39

-----------------------------------

local function onKeyEvent( event )
    local keyName = event.keyName
    local phase = event.phase

    if ("back" == keyName and phase == "down") or ("b" == keyName and phase == "down" and system.getInfo("environment") == "simulator")  then 
        storyboard.gotoScene("scenes.home")
    end
end


function verHome( event )
    if ( event.phase == "ended") then
        storyboard.gotoScene("scenes.home")
    end    
end

function formularioPedido( event )

	if event.phase == "ended" then
        if bgNombreSucursal.id > 0 then
            
            --verificar que tenga productos su catalogo, sino mandarlo a pedidosucursalcatalogo
            local numProductos =  db_sucursal.getNumCatalogoSucursal(bgNombreSucursal.id)
            --print("num de productos: " .. numProductos)

            if numProductos > 0 then
                print("preparando formulario....")

                local options = { params = { 
                    pedidoCreado = true,
                    idsucursal_server = bgNombreSucursal.id_server, 
                    idsucursal = bgNombreSucursal.id
                    } 
                }
                timeMarker = timer.performWithDelay( 250, function ( )
					storyboard.removeScene("screens.pedidoNuevo")
                    storyboard.gotoScene("scenes.pedidoNuevo", options)
                end, 1)
            else

                print("preparando formulario....")
                local options = { params = { 
                    pedidoCreado = false, 
                    idsucursal_server = bgNombreSucursal.id_server, 
                    idsucursal = bgNombreSucursal.id
                    } 
                }
                
                timeMarker = timer.performWithDelay( 250, function ( )
					storyboard.removeScene("screens.pedidoSucursalCatalogoRestante")
                    storyboard.gotoScene("scenes.pedidoSucursalCatalogoRestante", options)
                end, 1)
            end

            --bgNombreSucursal.id = 0
            labelSelectSucursal.text = "Selecione un sucursal"

            --[[

            conexionSQLite.setSucursalPedidoTemporal(bgNombreSucursal.id)
    		print("preparando formulario....")
            bgNombreSucursal.id = 0
            labelSelectSucursal.text = "Selecione un sucursal"
            --getLoading(grupoPedidoNuevoPre)
            
            cargarLoading()
            timeMarker = timer.performWithDelay( 250, function ( )
                storyboard.gotoScene("screens.pedidoNuevo")
            end, 1)]]
        else
            native.showAlert( "Elija sucursal", "Seleccione la sucursal.", { "OK"})           
        end
    end

end

--------muestra las opcionesCliente del combobox
function createOptionCliente( event )

    bgDroboxOptionCliente = display.newRect( 0, top, width_s, height_s - top) --x, y, width, height
    bgDroboxOptionCliente.anchorX = 0
    bgDroboxOptionCliente.anchorY = 0
    bgDroboxOptionCliente:setFillColor( 0 )
    bgDroboxOptionCliente.alpha = .5
    grupoDroboxOptionCliente:insert(bgDroboxOptionCliente)
    bgDroboxOptionCliente:addEventListener( 'tap', closeOptionComboCliente )
    srvOptionCliente = widget.newScrollView{
        top = top + height_s/15,
        left = 100,
        width = width_s - 200,
        height = height_s/1.2 - top,
        horizontalScrollDisabled = true,
        verticalScrollDisabled = false,
        isBounceEnabled = false,
        backgroundColor = { 1 }
    }
    grupoDroboxOptionCliente:insert(srvOptionCliente)
    srvOptionCliente:addEventListener( 'tap', sinAccion)

    return true
end

--------mestra las opciones sucursales del combobox
function createOptionSucursal( event )

    bgDroboxOptionSucursal = display.newRect( 0, top, width_s, height_s - top) --x, y, width, height
    bgDroboxOptionSucursal.anchorX = 0
    bgDroboxOptionSucursal.anchorY = 0
    bgDroboxOptionSucursal:setFillColor( 0 )
    bgDroboxOptionSucursal.alpha = .5
    grupoDroboxOptionSucursal:insert(bgDroboxOptionSucursal)
    bgDroboxOptionSucursal:addEventListener( 'tap', closeOptionComboSucursal )
    srvOptionSucursal = widget.newScrollView{
        top = top + height_s/15,
        left = 100,
        width = width_s - 200,
        height = height_s/1.2 - top,
        horizontalScrollDisabled = true,
        verticalScrollDisabled = false,
        isBounceEnabled = false,
        backgroundColor = { 1 }
    }
    grupoDroboxOptionSucursal:insert(srvOptionSucursal)
    srvOptionSucursal:addEventListener( 'tap', sinAccion)

    return true
end

-----cierra las opcionesCliente del drobox
function closeOptionComboCliente( event )

    if event.target.tipo == "opcion" then
        cargarLoading()
        labelSelectCliente.text = event.target.nombre
        bgRazonCliente.id = event.target.id
        --se llena el combo de sucursales
        removerOptionSucursal()
        totalSucursales = 0
        totalSucursales = db_cliente.getNumSucursales(bgRazonCliente.id)
        print("Total sucursales: " .. totalSucursales)
        timeMarker = timer.performWithDelay( 250, function ( )
            db_sucursal.getSucursalCombo(bgRazonCliente.id )
        end, 1)
        
    end
    
    grupoDroboxOptionCliente.x = 900

    return true
end

-----cierra las opciones sucursales del drobox
function closeOptionComboSucursal( event )

    if event.target.tipo == "opcion" then
        labelSelectSucursal.text = event.target.nombre
        bgNombreSucursal.id = event.target.id
        bgNombreSucursal.id_server = event.target.id_server

    end

    grupoDroboxOptionSucursal.x = 900

    return true
end

--quita los efectos del padre en el hijo
function sinAccion( event )
    return true
end

-----creamos las opcionesCliente del combobox
--crea las opcionesCliente del droboz
function nuevaOptionCliente(nombre,id)

    local numOption = 0

    numOption = #opcionesCliente + 1
   
    opcionesCliente[numOption] = display.newRect( 325, poscY, width_s - 200, 80) --x, y, width, height
    opcionesCliente[numOption]:setFillColor( 1 )
    srvOptionCliente:insert(opcionesCliente[numOption])
    opcionesCliente[numOption].id = id
    opcionesCliente[numOption].nombre = nombre
    opcionesCliente[numOption].tipo = "opcion"
    opcionesCliente[numOption]:addEventListener( 'tap', closeOptionComboCliente)
    local labelOpcion = display.newText( {
        text = nombre,     
        x = width_s/2 - 100, y = poscY, width = width_s - 240,
        font = native.systemFont, fontSize = 30, align = "left"
    })
    labelOpcion:setFillColor( 0 )
    srvOptionCliente:insert(labelOpcion)
    
    poscY = poscY + 42
    
    local bgOption = display.newRect( 325, poscY, width_s - 200, 5) --x, y, width, height
    bgOption:setFillColor( 0 )
    srvOptionCliente:insert(bgOption)
    bgOption:toFront()
    
    poscY = poscY + 45
    
    srvOptionCliente:setScrollHeight(poscY - 40)

    timeMarker = timer.performWithDelay( 1000, function ( )
        terminarLoading()
    end, 1)
    
end

-----creamos las opcionesCliente del combobox
--crea las opcionesCliente del droboz
function nuevaOptionSucursal(nombre, id, id_server)

    local numOption = 0

    numOption = #opcionesSucursal + 1

    if reinicioSucursal == 0 then
        reinicioSucursal = 1
        poscY = 41
    end    
    
    opcionesSucursal[numOption] = display.newRect( 325, poscY, width_s - 200, 80) --x, y, width, height
    opcionesSucursal[numOption]:setFillColor( 1 )
    srvOptionSucursal:insert(opcionesSucursal[numOption])
    opcionesSucursal[numOption].id = id
    opcionesSucursal[numOption].id_server = id_server
    opcionesSucursal[numOption].nombre = nombre
    opcionesSucursal[numOption].tipo = "opcion"
    opcionesSucursal[numOption]:addEventListener( 'tap', closeOptionComboSucursal)

    labelOpcionSucursal[numOption] = display.newText( {
        text = nombre,     
        x = width_s/2 - 100, y = poscY, width = width_s - 240,
        font = native.systemFont, fontSize = 30, align = "left"
    })
    labelOpcionSucursal[numOption]:setFillColor( 0 )
    srvOptionSucursal:insert( labelOpcionSucursal[numOption])
    
    poscY = poscY + 42
    
    bgOptionSucursal[numOption]= display.newRect( 325, poscY, width_s - 200, 5) --x, y, width, height
    bgOptionSucursal[numOption]:setFillColor( 0 )
    srvOptionSucursal:insert(bgOptionSucursal[numOption])
    bgOptionSucursal[numOption]:toFront()
    
    poscY = poscY + 45
    
    srvOptionSucursal:setScrollHeight(poscY - 40)

    if numOption >= totalSucursales then 
        timeMarker = timer.performWithDelay( 1000, function ( )
                terminarLoading()
        end, 1)
    end
    
end

function removerOptionSucursal( event )
    --se remueven todos los elementos de las sucursales
    --print("Numero de sucursales: " .. #opcionesSucursal)
	for i = 1, #opcionesSucursal, 1 do
        opcionesSucursal[i]:removeSelf()
        labelOpcionSucursal[i]:removeSelf()
        bgOptionSucursal[i]:removeSelf()
    end

    opcionesSucursal = {}
    bgOptionSucursal = {}
    labelOpcionSucursal = {}
    labelSelectSucursal.text = "Seleccione una sucursal"
    bgNombreSucursal.id = 0
    bgNombreSucursal.id_server = 0
    reinicioSucursal = 0

end

--despliega la lista del drobox
function showOption( event )
    --txtSucursalNumero.x = txtSucursalNumero.x * 3
    --txtSucursalNombre.x = txtSucursalNombre.x * 3
    grupoDroboxOptionCliente.x = 0
    return true

end

--despliega la lista del drobox sucursal
function showOptionSucursal( event )
    --txtSucursalNumero.x = txtSucursalNumero.x * 3
    --txtSucursalNombre.x = txtSucursalNombre.x * 3
    grupoDroboxOptionSucursal.x = 0
    return true

end

function screen:createScene( event )

end

function screen:enterScene( event )

	Globals.scene[#Globals.scene + 1] = storyboard.getCurrentSceneName()

	print('jawdnawjdnakjwndjkawdnkjawdnkjawndkjawdjaw djaw djaw')

	grupoPedidoNuevoPre = display.newGroup()

	vw = self.view

    vw:insert(grupoPedidoNuevoPre)

    local header = Header:new()
    grupoPedidoNuevoPre:insert(header)
    grupoLoad = display.newGroup()
    
    grupoDroboxOptionCliente.x = 900

    opcionesSucursal= {}
    labelOpcionSucursal = {}
    bgOptionSucursal = {}

    local thHeaderS = {}
    local tdTxtHeader = {}
    local poscXH = 1


    -- bg de home
    local background = display.newRect( 0, top, width_s, height_s - top) --x, y, width, height
    background.anchorX = 0
    background.anchorY = 0
    background:setFillColor( 236/255, 240/255, 241/255 )
    grupoPedidoNuevoPre:insert(background)

    local recAcciones = display.newRect( 0, top, width_s, 45) --x, y, width, height
    recAcciones.anchorX = 0
    recAcciones.anchorY = 0
    recAcciones:setFillColor( 0 )
    grupoPedidoNuevoPre:insert(recAcciones)
    
    local poscXL = 0

    local btnVerHome =  widget.newButton({
        label = "Home",
        onEvent = verHome,
        emboss = true,
        shape = "roundedRect",
        labelColor = { default = { 0, 0, 0 }, over = { 163, 25, 12} },
        width = 150,
        height = 32,
        cornerRadius = 3
    })
    btnVerHome.x = width_s / 2
    btnVerHome.y = top + 20
    grupoPedidoNuevoPre:insert(btnVerHome)
    
    -------------------------
    -------drobox cliente-----
    --------------------------
    
    local labelRazonCliente = display.newText( {
        text = "Cliente",     
        x = width_s / 2 - 240, y = top + 150, width = 120,
        font = native.systemFont, fontSize = 16, align = "right"
    })
    labelRazonCliente:setFillColor( 0 )
    grupoPedidoNuevoPre:insert(labelRazonCliente)
    
    --drobox
    bgRazonCliente = display.newRect( width_s / 2 + 25, top + 150, 350, 60 )
    bgRazonCliente:setFillColor( 1 )
    bgRazonCliente.id = 0
    grupoPedidoNuevoPre:insert(bgRazonCliente)
    bgRazonCliente:addEventListener( 'tap', showOption)
    
    --texto dentro del drobox
    labelSelectCliente = display.newText( {
        text = "Seleccione un cliente",     
        x = width_s / 2 + 25, y = top + 150, width = 300,
        font = native.systemFont, fontSize = 18, align = "left"
    })
    labelSelectCliente:setFillColor( 0 )
    grupoPedidoNuevoPre:insert(labelSelectCliente)
    
    --flecha del drobox(decorativo)
    local imgArrowDown= display.newImage("img/app/picker.png" , width_s / 2 + 190, top + 172)
    imgArrowDown.height = 15
    imgArrowDown.width = 15
    grupoPedidoNuevoPre:insert(imgArrowDown)
    
    ---------------------------
     -------------------------
    -------drobox sucursal-----
    --------------------------
   
    local labelNombreSucursal = display.newText( {
        text = "Sucursal",     
        x = width_s / 2 - 240, y = top + 300, width = 120,
        font = native.systemFont, fontSize = 16, align = "right"
    })
    labelNombreSucursal:setFillColor( 0 )
    grupoPedidoNuevoPre:insert(labelNombreSucursal)
    
    --drobox
    bgNombreSucursal = display.newRect( width_s / 2 + 25, top + 300, 350, 60 )
    bgNombreSucursal:setFillColor( 1 )
    bgNombreSucursal.id = 0
    bgNombreSucursal.id_server = 0
    grupoPedidoNuevoPre:insert(bgNombreSucursal)
    bgNombreSucursal:addEventListener( 'tap', showOptionSucursal)
    
    --texto dentro del drobox
    labelSelectSucursal = display.newText( {
        text = "Seleccione un sucursal",     
        x = width_s / 2 + 25, y = top + 300, width = 300,
        font = native.systemFont, fontSize = 18, align = "left"
    })
    labelSelectSucursal:setFillColor( 0 )
    grupoPedidoNuevoPre:insert(labelSelectSucursal)
    
    --flecha del drobox(decorativo)
    local imgArrowDown2= display.newImage("img/app/picker.png" , width_s / 2 + 190, top + 322)
    imgArrowDown2.height = 15
    imgArrowDown2.width = 15
    grupoPedidoNuevoPre:insert(imgArrowDown2)

    local btnSucursalRegistrar =  widget.newButton({
        label = "Ir a formulario de pedido",
        onEvent = formularioPedido,
        emboss = true,
        shape = "roundedRect",
        labelColor = { default = { 1, 1, 1 }, over = { 163, 25, 12} },
        width = 250,
        height = 60,
        cornerRadius = 3
    })
    btnSucursalRegistrar.x = width_s / 2 
    btnSucursalRegistrar:setFillColor(.05, .36, .30)
    btnSucursalRegistrar.y = top + 400

    grupoPedidoNuevoPre:insert(btnSucursalRegistrar)

    grupoDroboxOptionCliente:removeSelf()
    grupoDroboxOptionCliente = display.newGroup()

    grupoDroboxOptionSucursal:removeSelf()
    grupoDroboxOptionSucursal = display.newGroup()
    
    poscY = 41
    
    grupoDroboxOptionCliente.x = 900

    grupoDroboxOptionSucursal.x = 900
    
    createOptionCliente()

    createOptionSucursal()
    
    --local conex = db_sincronizacion.getComprobarConexion()

    db_cliente.getClienteCombo()

end

function screen:exitScene( event )
	print('tioyjrijirtnjirtnjriotnritnritnio')
end

function screen:destroyScene( event )
	print('ofhkomhtykhmftkhmtkmhfktmfkhftm')
end

screen:addEventListener("createScene", screen)
screen:addEventListener("enterScene",  screen)
screen:addEventListener("exitScene",   screen)
screen:addEventListener("destroyScene",   screen)


return screen