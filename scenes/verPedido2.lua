-----------------------------------------------------------------------------------------
--
-- pedidoNuevo.lua
--
-----------------------------------------------------------------------------------------

-- requires--
require('include.header')
local widget = require("widget")
local storyboard = require("storyboard")
local db_pedido = require ("include.db_pedido")
local Globals = require('include.Globals')

local scene = storyboard.newScene()
local grupoPedido = display.newGroup()
local grupoSegmento
--array de grupos de los segmentos (cada 99 articulos es un segmento)


--variables del screen
local top = display.topStatusBarContentHeight
local width_s = display.contentWidth
local height_s = display.contentHeight
local poscTabla = 180
local posicion_y_vp = 5

--variables de tabla pedido
local tdHeaderName = {'Imagen','SKU','XS','S','M','L','XL','XXL','XXXL','UNI',  }
local tdHeaderWitdh = {130,100,60,60,60,60,60,60,60,60,100}
local fila = {}
local sku = {}
local precio = {}
local img = {}
local orden = {}
local precio = {}
local subtotalProductoDecimal = {}
local subtotalProducto = {}
local subtotalSegmento = {}
local imageRegresarAnterior, imageRegresarSiguiente
--tallas
local xs = {}
local s = {}
local m = {}
local l = {}
local xl = {}
local xxl = {}
local xxxl = {}
local uni = {}

local limiteSegmento = 99
--contador para los articulos que se han cargado
local contArticulosCargados
local pedidoActual = 1
local totalProductosPedido = 0
local articuloActual = ''
local totalGrupoPedido = 0
local contItem = 0
local ultimaTalla = 0
local posc = 0


--para saber que talla fue la anterior orden y con ello rellenar con 0

function verHome( event )
    if ( event.phase == "ended") then
        storyboard.gotoScene("scenes.home")
    end    
end


function crearFilaDetallePedido( item )
    local lineS = {}

    if item.sku ~= articuloActual then
        print(item.sku)
        
        --si todavia se pueden cargar mas articulos en el segmento
        if contItem < contArticulosCargados + limiteSegmento then
            
            contItem = contItem + 1
            posc = contItem

            totalGrupoPedido = #grupoSegmento + 1

            if contItem%4 == 1 then

                grupoSegmento[totalGrupoPedido] = display.newGroup()
                vw:insert(grupoSegmento[totalGrupoPedido])
                grupoSegmento[totalGrupoPedido].y = 150
                posicion_y_vp = 50
                if totalGrupoPedido == 1 then
                    grupoSegmento[totalGrupoPedido].x = 0
                else
                    grupoSegmento[totalGrupoPedido].x = 1000
                end
            end

            totalGrupoPedido = #grupoSegmento

            print("datos")
            print(totalGrupoPedido)
            print("" .. #grupoSegmento)
            print(posicion_y_vp)

            fila[posc] = display.newRect( width_s/2, posicion_y_vp, width_s - 2, 100) --x, y, width, height
            fila[posc].anchorY = 0
            fila[posc]:setFillColor( 242/255, 243/255, 244/255 )

            grupoSegmento[totalGrupoPedido]:insert(fila[posc])

            local poscXL = 0
            
            for i = 1, 10, 1 do
            
                poscXL= tdHeaderWitdh[i] + poscXL
                
                lineS[i] = display.newRect( poscXL, posicion_y_vp , 2, 100) --x, y, width, height
                lineS[i].anchorX = 0
                lineS[i].anchorY = 0
                lineS[i]:setFillColor( 1 )
                grupoSegmento[totalGrupoPedido]:insert(lineS[i])
                
            end
            
            posicion_y_vp = posicion_y_vp + 40

            --impresion del detalle del pedido

            for t = 1, 8, 1 do
                
                orden[t] = display.newText( {
                    text = "0",     
                    x =  193 + (60 * t), y = posicion_y_vp, width = 70,
                    font = native.BrushScriptStd, fontSize = 18, align = "center", 
                })
                orden[t]:setFillColor(0)
                grupoSegmento[totalGrupoPedido]:insert(orden[t])

            end

            xs[contItem] = 0
            s[contItem] = 0
            m[contItem] = 0
            l[contItem] = 0
            xl[contItem] = 0
            xxl[contItem] = 0
            xxxl[contItem] = 0
            uni[contItem] = 0

            --img[posc] = display.newImage("/storage/emulated/0/DCIM/catalogo/"..item.imagen, 65, posicion_y_vp + 10)
            img[posc] = display.newImage("img/catalogo/"..item.imagen, 65, posicion_y_vp + 20)

            
            if img[posc] == nil then
                img[posc] = display.newImage("img/app/noimage.jpg", 65, posicion_y_vp + 20)
                img[posc]:scale(.5, .5)
            else
                img[posc]:scale(.3, .3)
            end


            grupoSegmento[totalGrupoPedido]:insert(img[posc])
            poscXL = poscXL + tdHeaderWitdh[2]

            --sku
            sku[posc] = display.newText( {
                text = item.sku,
                x = 180, y = posicion_y_vp - 30, width = tdHeaderWitdh[2],
                font = native.BrushScriptStd, fontSize = 14, align = "center"
            })
            sku[posc]:setFillColor( 0 )
            grupoSegmento[totalGrupoPedido]:insert(sku[posc])
            sku[posc].y = sku[posc].y + sku[posc].height/2

            --precio unitario
            precio[posc] = display.newText({
                text = "$" .. item.costo, 
                x = 180, y = posicion_y_vp - 10, width = tdHeaderWitdh[2],
                font = native.BrushScriptStd, fontSize = 14, align = "center"
            })
            precio[posc]:setFillColor( 0 )
            grupoSegmento[totalGrupoPedido]:insert(precio[posc])
            precio[posc].y = precio[posc].y + precio[posc].height/2

            subtotalProductoDecimal[posc] = 0

            subtotalProducto[posc] = display.newText({
                text = "$0.00", 
                x = width_s - tdHeaderWitdh[11] + 22, y = posicion_y_vp, width = tdHeaderWitdh[11],
                font = native.BrushScriptStd, fontSize = 16, align = "right"
            })
            subtotalProducto[posc]:setFillColor( 0 )
            grupoSegmento[totalGrupoPedido]:insert(subtotalProducto[posc])

            

            posicion_y_vp = posicion_y_vp + fila[posc].height - 50

        end

    end

    subtotalProductoDecimal[posc] = subtotalProductoDecimal[posc] + (item.costo * item.orden)
    subtotalProducto[posc].text = "$" .. subtotalProductoDecimal[posc]


    --se reemplaza el 0 por la orden
    orden[item.talla].text = item.orden

    if item.talla == 1 then
        xs[contItem] = item.orden
    end
    if item.talla == 2 then
        s[contItem] = item.orden
    end
    if item.talla == 3 then
        m[contItem] = item.orden
    end
    if item.talla == 4 then
        l[contItem] = item.orden
    end
    if item.talla == 5 then
        xl[contItem] = item.orden
    end
    if item.talla == 6 then
        xxl[contItem] = item.orden
    end
    if item.talla == 7 then
        xxxl[contItem] = item.orden
    end
    if item.talla == 8 then
        uni[contItem] = item.orden
    end
    --totalOrden[posc] = totalOrden[posc] + 

    articuloActual = item.sku
    totalProductosPedido =  contItem


    timeMarker = timer.performWithDelay( 2000, function ( )
        terminarLoading()
    end, 1)

end

function cambiarSegmentoPedido( event )
    if event.target.tipo == 1 then
        transition.to( grupoSegmento[event.target.num],      { x = 0, time = 400, transition = easing.outExpo } )
        transition.to( grupoSegmento[event.target.num - 1 ], { x = -1000, time = 400, transition = easing.outExpo } )
        
        imageAnterior.alpha = 1

        --totalProductosCatalogo = 15

        if ( imageSiguiente.num ) * 4 >= totalProductosPedido  then
            imageSiguiente.alpha = 0
        end

        --cambia los valores de las flechas
        imageSiguiente.num =  imageSiguiente.num + 1
        imageAnterior.num = imageAnterior.num + 1

        local contTalla = 1
        
        --[[for j = pedidoActual, pedidoActual + 3, 1 do 
        
            xs[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            s[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            m[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            l[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            xl[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            xxl[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            xxxl[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            uni[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            
             if orden[contTalla] == nil then
                    break
            end
            
        end]]

        pedidoActual = pedidoActual + 4
        
        --if txtTalla[pedidoActual] ~= nill then
        
            local contTalla = 1
        
            for j = pedidoActual, pedidoActual + 3, 1 do
            
                orden[contTalla].text = xs[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = s[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = m[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = l[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = xl[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = xxl[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = xxxl[j]
                    contTalla = contTalla + 1
                orden[contTalla].text = uni[j]
                    contTalla = contTalla + 1   
                    
                if orden[contTalla] == nil then
                    break
                end
                
            end

        --end 

    else
        transition.to( grupoSegmento[event.target.num],      { x = 0, time = 400, transition = easing.outExpo } )
        transition.to( grupoSegmento[event.target.num + 1 ], { x = 1000, time = 400, transition = easing.outExpo } )

        imageSiguiente.alpha = 1

        if event.target.num == 1 then
            imageAnterior.alpha = 0
        end

        --cambia los valores de las flechas
        imageSiguiente.num = imageSiguiente.num - 1
        imageAnterior.num = imageAnterior.num - 1

        local contTalla = 1
        
        --[[for j = pedidoActual, pedidoActual + 3, 1 do
        
            xs[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            s[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            m[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            l[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            xl[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            xxl[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            xxxl[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            uni[j] = txtTalla[contTalla].text
                txtTalla[contTalla].text = 0
                contTalla = contTalla + 1
            
            if txtTalla[contTalla] == nil then
                break
            end
            
        end]]
        
        pedidoActual = pedidoActual - 4
        
        local contTalla = 1
        
        for j = pedidoActual, pedidoActual + 3, 1 do
        
                orden[1].text = xs[j]
                print("xsj: " .. xs[j])
                    contTalla = contTalla + 1
                print("conttalla: " .. contTalla)
                orden[2].text = s[j]
                    contTalla = contTalla + 1
                orden[3].text = m[j]
                print("mj: " .. m[j])
                    contTalla = contTalla + 1
                orden[4].text = l[j]
                    contTalla = contTalla + 1
                orden[5].text = xl[j]
                    contTalla = contTalla + 1
                orden[6].text = xxl[j]
                    contTalla = contTalla + 1
                orden[7].text = xxxl[j]
                    contTalla = contTalla + 1
                orden[8].text = uni[j]
                
            if orden[contTalla] == nil then
                break
            end
            
        end

    end
end


function scene:createScene( event )

end

function scene:enterScene( event )

	Globals.scene[#Globals.scene + 1] = storyboard.getCurrentSceneName()

    vw = self.view

    vw:insert(grupoPedido)

    local thHeaderS = {}
    local tdTxtHeader = {}
    local poscXH = 1
    posicion_y_vp  = 0
    contItem = 0
    ultimaTalla = 0
    posc = 0
    grupoSegmento = {}
    fila = {}
    sku = {}
    precio = {}
    img = {}
    orden = {}
    precio = {}
    subtotalProductoDecimal = {}
    subtotalProducto = {}
    subtotalSegmento = {}


    -- bacckground
    local background = display.newRect( 0, top, width_s, height_s - top) --x, y, width, height
    background.anchorX = 0
    background.anchorY = 0
    background:setFillColor( 236/255, 240/255, 241/255 )
    grupoPedido:insert(background)

    local recAcciones = display.newRect( 0, top, width_s, 45) --x, y, width, height
    recAcciones.anchorX = 0
    recAcciones.anchorY = 0
    recAcciones:setFillColor( 0 )
    grupoPedido:insert(recAcciones)

    --datos del pedido
    
    local folioPedido = display.newText( {
        text = "Folio: ",     
        x = 125, y = 100, width = 200,
        font = native.BrushScriptStd, fontSize = 16, align = "left"
    })
    folioPedido:setFillColor( 0 )
    grupoPedido:insert(folioPedido)

    local fechaPedido = display.newText( {
        text = "Fecha: ",     
        x = 125, y = 130, width = 200,
        font = native.BrushScriptStd, fontSize = 16, align = "left"
    })
    fechaPedido:setFillColor( 0 )
    grupoPedido:insert(fechaPedido)

    local clientePedido = display.newText( {
        text = "Cliente: ",     
        x = 400, y = 100, width = 850,
        font = native.BrushScriptStd, fontSize = 16, align = "right"
    })
    clientePedido:setFillColor( 0 )
    grupoPedido:insert(clientePedido)

    local sucursalPedido = display.newText( {
        text = "Sucursal: ",     
        x = 400, y = 130, width = 850,
        font = native.BrushScriptStd, fontSize = 16, align = "right"
    })
    sucursalPedido:setFillColor( 0 )
    grupoPedido:insert(sucursalPedido)

    local thHeader = display.newRoundedRect ( width_s/2, poscTabla - 35, width_s - 6, 50,5) 
    thHeader.anchorY = 0
    thHeader:setFillColor( 189/255, 195/255, 199/255 )
    grupoPedido:insert(thHeader)

    local poscXL = 0

    -- impresion de los headers
    for i = 1, 10, 1 do
    
        poscXL = tdHeaderWitdh[i] + poscXL
        
        --separadores
        thHeaderS[i] = display.newRect( poscXL, poscTabla - 35 , 2, 50) --x, y, width, height
        thHeaderS[i].anchorY = 0
        thHeaderS[i]:setFillColor( 1 )
        grupoPedido:insert(thHeaderS[i])
        
        tdTxtHeader[i] = display.newText( {
            text = tdHeaderName[i],     
            x = poscXH + tdHeaderWitdh[i]/2, y = poscTabla - 10, width = tdHeaderWitdh[i],
            font = native.BrushScriptStd, fontSize = 22, align = "center"
        })
        tdTxtHeader[i]:setFillColor( 0 )
        grupoPedido:insert(tdTxtHeader[i])
    
        poscXH = poscXH + tdHeaderWitdh[i]
    
    end

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
    grupoPedido:insert(btnVerHome)


    imageAnterior = display.newImage("img/app/arrowBackW.png" , width_s / 2 + 250 , top + 15)
    imageAnterior.height = 50
    imageAnterior.width = 60
    imageAnterior.num = 0
    imageAnterior.alpha = 0
    imageAnterior.tipo = 0
    imageAnterior:addEventListener('tap', cambiarSegmentoPedido )
    grupoPedido:insert(imageAnterior)
   
    imageSiguiente = display.newImage("img/app/arrowNextW.png" , width_s / 2 + 320 , top + 15)
    imageSiguiente.height = 50
    imageSiguiente.width = 60
    imageSiguiente.num = 2
    imageSiguiente.tipo = 1
    imageSiguiente:addEventListener('tap', cambiarSegmentoPedido )
    grupoPedido:insert(imageSiguiente)

    local idpedido = event.params.idPedido
    print("idpedido: " .. idpedido)
    --local idpedido = 1

    --consultar los datos del pedido con la id del pedido

    local info_pedido = db_pedido.getPedido(idpedido)

    folioPedido.text   = folioPedido.text     .. info_pedido.folio
    fechaPedido.text   = fechaPedido.text     .. info_pedido.fecha
    clientePedido.text = clientePedido.text   .. info_pedido.razonsocial
    sucursalPedido.text = sucursalPedido.text .. info_pedido.nombresucursal

    contArticulosCargados = 0
    --obtiene el detalle del pedido y crea las filas en la funcion crearFilaDetallePedido
    db_pedido.getDetallePedido(idpedido)

    if contItem <= 4 then
        imageSiguiente.alpha = 0
    end

    local totalPedido = 0

    tdTxtHeader[11] = display.newText( {
        --text = "$" .. db_pedido.getTotalPedido(idpedido),  
        text = "$" .. "102,200",   
        x = poscXH + tdHeaderWitdh[11]/2, y = poscTabla - 10, width = tdHeaderWitdh[11],
        font = native.BrushScriptStd, fontSize = 20, align = "right"
    })
    tdTxtHeader[11]:setFillColor( 0 )
    grupoPedido:insert(tdTxtHeader[11])

    print("---------------------")

    --[[timeMarker = timer.performWithDelay( 2000, function ( )
        terminarLoading()
    end, 1)]]

end

function scene:exitScene( event )

end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene",  scene)
scene:addEventListener("exitScene",   scene)

return scene