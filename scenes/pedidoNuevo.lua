-----------------------------------------------------------------------------------------
--
-- pedidoNuevo.lua
--
-----------------------------------------------------------------------------------------

-- requires--
require('include.header')
local widget = require("widget")
local storyboard = require("storyboard")
local Globals = require('include.Globals')

local db_sucursal = require ("include.db_sucursal")

local scene = storyboard.newScene()
local grupoPedidoNuevo = display.newGroup()
local grupoSegmento = {} --array de grupos de los segmentos (cada 99 articulos es un segmento)
local tableCatalogoSucursal

--variables del screen
local top = display.topStatusBarContentHeight + 15
local width_s = display.contentWidth
local height_s = display.contentHeight
local poscTabla = 120
local posicion_y = 5

--variables de tabla pedido
local tdHeaderName = {'Imagen','SKU','XS','S','M','L','XL','XXL','XXXL','UNI',  }
local tdHeaderWitdh = {130,100,70,70,70,70,70,70,70,70, 20}
local fila = {}
local sku = {}
local img = {}
local precio = {} --subtotal de lo calculado (ordenes * costo)
local txtPrecio = {}
local color = {}
local costo = {} --precio unitario
local sublinea = {}
local txtTalla = {} -- array para los textbox de las ordenes
local grupoTextFields = {}
local totalItemsPedido = 0
local totalInteraciones = 0

--tallas
local xs = {}
local s = {}
local m = {}
local l = {}
local xl = {}
local xxl = {}
local xxxl = {}
local uni = {}
-- end tallas

local limiteSegmento = 100
--contador para los articulos que se han cargado
local contArticulosCargados
local articuloActual = ''
local contItemsCat = 0
local idsucursal
local idsucursal_server
local pedidoActual = 1
-- se ingresaran los articulos del catalogo 
--ejemplo  articulos[1] = {1 (idcatalogo)} , articulos[2] = {3 (idcatalogo)}
local articulos = {}
local articulosSQLite = {}
local totalProductosCatalogo = 0


local imageAnterior, imageSiguiente

function verHome( event )
    if ( event.phase == "ended") then
        storyboard.gotoScene("scenes.home")
    end    
end

function verCatalogoRestante( event )

    if ( event.phase == "ended" or event.phase == "submitted" ) then        

        --ejemplos


        --[[
        articulos[1] = "4810101009"
        articulosSQLite[1] = 1
        articulos[2] = "4810101073"
        articulosSQLite[2] = 2

        s[1] = 30
        m[1] = 10
        m[2] = 10]]

        print("Contador de articulos: " .. contItemsCat)

        local options = { params = {
            pedidoCreado = true, --cambiar a paso por primer paso (catalogo sucursal)
            idsucursal_server = idsucursal_server, 
            idsucursal = idsucursal,
            numArticulos = contItemsCat,
            arrayProductos = articulos,
            arrayProductosLocal = articulosSQLite,
            xs = xs,
            s = s,
            m = m,
            l = l,
            xl = xl,
            xxl = xxl,
            xxxl = xxxl,
            uni = uni
            } 
        }

        

        timeMarker = timer.performWithDelay( 250, function ( )

            storyboard.gotoScene("scenes.pedidoSucursalCatalogoRestante", options)
            
        end, 1)

        
    
    end
    
end

function llenadoFormularioPedido( items )

    crearFila(items, contItemsCat)

end

function crearFila( items, posc )

    print("id!!!!: " .. items.id)

    local lineS = {}
    local posc
    --como los registros devueltos pueden repetirse los sku (sku1 - talla1, sku1 - talla2...)
    --cada vez que se cambie de articulo
    if items.sku ~= articuloActual then

        --si todavia se pueden cargar mas articulos en el segmento
        if contItemsCat < contArticulosCargados + limiteSegmento then 
            contItemsCat = contItemsCat + 1
            totalItemsPedido = totalItemsPedido + 1

            posc = contItemsCat 
            articulos[posc] = items.sku
            articulosSQLite[posc] = items.id

            local totalGrupoPedido = #grupoSegmento + 1

            if contItemsCat%4 == 1 then
                grupoSegmento[totalGrupoPedido] = display.newGroup()
                vw:insert(grupoSegmento[totalGrupoPedido])
                grupoSegmento[totalGrupoPedido].y = 150
                posicion_y = -15
                if totalGrupoPedido == 1 then
                    grupoSegmento[totalGrupoPedido].x = 0
                else
                    grupoSegmento[totalGrupoPedido].x = 1000
                end
            end

            totalGrupoPedido = #grupoSegmento

            --impresion del articulo
            fila[posc] = display.newRect( width_s/2, posicion_y - 10, width_s - 2, 120) --x, y, width, height
            fila[posc].anchorY = 0
            fila[posc]:setFillColor( 242/255, 243/255, 244/255 )
            grupoSegmento[totalGrupoPedido]:insert(fila[posc])
            
            local poscXL = 0
            
            for i = 1, 10, 1 do
            
                poscXL= tdHeaderWitdh[i] + poscXL
                
                lineS[i] = display.newRect( poscXL, posicion_y , 2, 100) --x, y, width, height
                lineS[i].anchorX = 0
                lineS[i].anchorY = 0
                lineS[i]:setFillColor( 1 )
                grupoSegmento[totalGrupoPedido]:insert(lineS[i])
                
            end
            
            posicion_y = posicion_y + 40


            -- datos del articulo

            --imagen del producto
            
            img[posc] = display.newImage("img/catalogo/"..items.imagen, 65, posicion_y + 10)
            
            
            if img[posc] == nil then
                img[posc] = display.newImage("img/app/noimage.jpg", 65, posicion_y + 10)
                img[posc]:scale(.5, .5)
                img[posc].imgpreview = false

            else
                img[posc]:scale(.3, .3)
                img[posc].imgpreview = true

            end

            img[posc].sku = items.sku
            img[posc].imagen = items.imagen
            img[posc].descripcion = items.descripcion
            --img[posc]:addEventListener("tap", verImagen)



            --img[posc].imagen = 


            grupoSegmento[totalGrupoPedido]:insert(img[posc])
            poscXL = poscXL + tdHeaderWitdh[2]

            --sku
            sku[posc] = display.newText( {
                text = items.sku,     
                x = 180, y = posicion_y - 30, width = tdHeaderWitdh[2],
                font = native.BrushScriptStd, fontSize = 14, align = "center"
            })
            sku[posc]:setFillColor( 0 )
            grupoSegmento[totalGrupoPedido]:insert(sku[posc])
            sku[posc].y = sku[posc].y + sku[posc].height/2

            --precio unitario
            precio[posc] = display.newText({
                text = "$" .. items.costo, 
                x = 180, y = posicion_y - 10, width = tdHeaderWitdh[2],
                font = native.BrushScriptStd, fontSize = 14, align = "center"
            })
            precio[posc]:setFillColor( 0 )
            grupoSegmento[totalGrupoPedido]:insert(precio[posc])
            precio[posc].y = precio[posc].y + precio[posc].height/2
            costo[posc] = items.costo

            poscXL = tdHeaderWitdh[3] + 187

            for i = 1, 8, 1 do

                poscXL = poscXL + tdHeaderWitdh[i + 2]

            end

            --precioPedido[posc]:setFillColor( 0 )
            --groupoNuevoPedido[totalGrupoPedido]:insert(precioPedido[posc])
            

            posicion_y = posicion_y + fila[posc].height - 50

            xs[posc] = 0
            s[posc] = 0
            m[posc] = 0
            l[posc] = 0
            xl[posc] = 0
            xxl[posc] = 0
            xxxl[posc] = 0
            uni[posc] = 0

        end

    end

    articuloActual =  items.sku 

    totalProductosCatalogo =  contItemsCat


end

function createNativeTextField()

    --print(totalItemsPedido)
    
    if txtTalla[1] == nil then

        print("totalitemspedido: " .. totalItemsPedido)
        if totalItemsPedido > 3 then
            totalInteraciones = 4
        else
            totalInteraciones = totalItemsPedido
        end
        
        posicion_y = 180
    
        for j = 1, totalInteraciones, 1 do
        
            local totalGrupoPedido = #grupoTextFields + 1
        
            grupoTextFields[totalGrupoPedido] = display.newGroup()
        
            poscXL = tdHeaderWitdh[3] + 187
    
            for i = 1, 8, 1 do

                local tTalla = #txtTalla + 1
                
                txtTalla[tTalla] = native.newTextField(poscXL + 9, posicion_y , tdHeaderWitdh[i + 2] - 10, 60)
                txtTalla[tTalla].align = "left"
                txtTalla[tTalla]:setTextColor(0)
                txtTalla[tTalla].inputType = "number"
                txtTalla[tTalla].txtIdTalla = i
                txtTalla[tTalla].txtNumFila = j
                txtTalla[tTalla].text = 0
                --txtTalla.txtIdCatalogo = items.idcatalogo
                txtTalla[tTalla]:addEventListener("userInput", ingresandoOrden)
                grupoTextFields[totalGrupoPedido]:insert(txtTalla[tTalla])
                poscXL = poscXL + tdHeaderWitdh[i + 2]  

            end
            
            txtPrecio[j] = display.newText( {
                text = '$0',    
                x = 600, y = posicion_y + 5, width = tdHeaderWitdh[9],
                font = "Lato-Regular", fontSize = 26, align = "center"
            })
            txtPrecio[j]:setFillColor( 0 )
            grupoPedidoNuevo:insert(txtPrecio[j])
            --posicion_y = posicion_y + row[j].height - 50
        
            posicion_y = posicion_y + 120
            
        end
    
    end
    
end

function ingresandoOrden( event )

    if ( event.phase == "began" ) then
        if event.target.text == "0" then
            event.target.text = ""
        end
    end

    if ( event.phase == "editing" ) then
        --poner el puntero hasta la derecha y quitar el 0 cuando 
        --se edita 2 veces el mismo textbox
        --ejemplo editas un numero, luego el mismo le pones vacio y te lo pone 0
        --y editar el mismo y poner 6, t pondra 60

    end

    if ( event.phase == "ended" or event.phase == "submitted" ) then
        local numeroOrden

        if event.target.text == "" then
            event.target.text = "0"
            numeroOrden = 0
        else
            numeroOrden = event.target.text
        end

        local tallaTextEvent = event.target.txtIdTalla
        local numFila = event.target.txtNumFila

        --print(numFila)

        numFila = ( imageAnterior.num * 4 ) + numFila
        --cambiado
        
        if tallaTextEvent == 1 then
            xs[numFila] = numeroOrden
        elseif tallaTextEvent ==  2 then
            s[numFila] = numeroOrden
            print(s[numFila])
        elseif tallaTextEvent ==  3 then
            m[numFila] = numeroOrden
            print(m[numFila])
        elseif tallaTextEvent ==  4 then
            l[numFila] = numeroOrden
             print(l[numFila])
        elseif tallaTextEvent ==  5 then
            --native.showAlert( "Ingresando talla", "Talla: xl; numfila: " .. numFila .. "; numeroOrden: " .. numeroOrden, { "OK"} )
            xl[numFila] = numeroOrden
        elseif tallaTextEvent ==  6 then
            xxl[numFila] = numeroOrden
        elseif tallaTextEvent ==  7 then
            xxxl[numFila] = numeroOrden
        elseif tallaTextEvent ==  8 then
            uni[numFila] = numeroOrden
        end

        --editar el precio a mostrar
        --precioPedido[numFila].text =  "$" .. tostring(tonumber((costo[numFila]) * xs[numFila]) + tonumber((costo[numFila]) * s[numFila]) + tonumber((costo[numFila]) * m[numFila]) + tonumber((costo[numFila]) * l[numFila]) + tonumber((costo[numFila]) * xl[numFila]) + tonumber((costo[numFila]) * xxl[numFila]) + tonumber((costo[numFila]) * xxxl[numFila]) + tonumber((costo[numFila]) * uni[numFila]) )
    end   
end


function cambiarSegmentoPedido( event )
    if event.target.tipo == 1 then
        transition.to( grupoSegmento[event.target.num],      { x = 0, time = 400, transition = easing.outExpo } )
        transition.to( grupoSegmento[event.target.num - 1 ], { x = -1000, time = 400, transition = easing.outExpo } )
        
        imageAnterior.alpha = 1

        --totalProductosCatalogo = 15

        if ( imageSiguiente.num ) * 4 >= totalProductosCatalogo  then
            imageSiguiente.alpha = 0
        end

        --cambia los valores de las flechas
        imageSiguiente.num =  imageSiguiente.num + 1
        imageAnterior.num = imageAnterior.num + 1

        local contTalla = 1
        
        for j = pedidoActual, pedidoActual + 3, 1 do --cambiar a 4!
        
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
            
        end

        pedidoActual = pedidoActual + 4
        
        if txtTalla[pedidoActual] ~= nill then
        
            local contTalla = 1
        
            for j = pedidoActual, pedidoActual + 3, 1 do
            
                txtTalla[contTalla].text = xs[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = s[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = m[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = l[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = xl[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = xxl[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = xxxl[j]
                    contTalla = contTalla + 1
                txtTalla[contTalla].text = uni[j]
                    contTalla = contTalla + 1
                    
                if txtTalla[contTalla] == nil then
                    break
                end
                
            end

        end 

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
        
        for j = pedidoActual, pedidoActual + 3, 1 do
        
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
            
        end
        
        pedidoActual = pedidoActual - 4
        
        local contTalla = 1
        
        for j = pedidoActual, pedidoActual + 3, 1 do
        
        
            txtTalla[contTalla].text = xs[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = s[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = m[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = l[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = xl[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = xxl[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = xxxl[j]
                contTalla = contTalla + 1
            txtTalla[contTalla].text = uni[j]
                contTalla = contTalla + 1
                
            if txtTalla[contTalla] == nil then
                break
            end
            
        end

    end
end

function scene:createScene( event )
end

function scene:enterScene( event )

	Globals.scene[#Globals.scene + 1] = storyboard.getCurrentSceneName()

	grupoPedidoNuevo = display.newGroup()

	vw = self.view

    vw:insert(grupoPedidoNuevo)

    local header = Header:new()
    grupoPedidoNuevo:insert(header)


    idsucursal = event.params.idsucursal
    print("idsucursal" .. idsucursal)
    idsucursal_server = event.params.idsucursal_server
    
    local thHeaderS = {}
    local tdTxtHeader = {}
    local poscXH = 1

    -- bg de home
    local background = display.newRect( 0, top, width_s, height_s - top) --x, y, width, height
    background.anchorX = 0
    background.anchorY = 0
    background:setFillColor( 236/255, 240/255, 241/255 )
    grupoPedidoNuevo:insert(background)

    local recAcciones = display.newRect( 0, top, width_s, 45) --x, y, width, height
    recAcciones.anchorX = 0
    recAcciones.anchorY = 0
    recAcciones:setFillColor( 0 )
    grupoPedidoNuevo:insert(recAcciones)

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
    btnVerHome.x = width_s / 5
    btnVerHome.y = top + 20
    grupoPedidoNuevo:insert(btnVerHome)

    --boton para pasar a la siguiente erapa, 
    --el catalogo restante de la sucursal para aumentar su catalogo
    local btnMasProductos =  widget.newButton({
        label = "Siguiente",
        onEvent = verCatalogoRestante,
        emboss = true,
        shape = "roundedRect",
        labelColor = { default = { 0, 0, 0 }, over = { 163, 25, 12} },
        width = 150,
        height = 32,
        cornerRadius = 3
    })
    btnMasProductos.x = width_s / 2
    btnMasProductos.y = top + 20
    grupoPedidoNuevo:insert(btnMasProductos)

    imageAnterior = display.newImage("img/app/arrowBackW.png" , width_s / 2 + 250 , top + 15)
    imageAnterior.height = 50
    imageAnterior.width = 60
    imageAnterior.num = 0
    imageAnterior.alpha = 0
    imageAnterior.tipo = 0
    imageAnterior:addEventListener('tap', cambiarSegmentoPedido )
    grupoPedidoNuevo:insert(imageAnterior)
   
    imageSiguiente = display.newImage("img/app/arrowNextW.png" , width_s / 2 + 320 , top + 15)
    imageSiguiente.height = 50
    imageSiguiente.width = 60
    imageSiguiente.num = 2
    imageSiguiente.tipo = 1
    imageSiguiente:addEventListener('tap', cambiarSegmentoPedido )
    grupoPedidoNuevo:insert(imageSiguiente)

    -- header de la tabla de formulario para el pedido (barra gris)
    local thHeader = display.newRoundedRect ( width_s/2, poscTabla - 50, width_s - 6, 50,5) 
    thHeader.anchorY = 0
    thHeader:setFillColor( 189/255, 195/255, 199/255 )
    grupoPedidoNuevo:insert(thHeader)

    local poscXL = 0

    -- impresion de los headers
    for i = 1, 10, 1 do
    
        poscXL = tdHeaderWitdh[i] + poscXL
        
        --separadores
        thHeaderS[i] = display.newRect( poscXL, poscTabla - 50 , 2, 50) --x, y, width, height
        thHeaderS[i].anchorY = 0
        thHeaderS[i]:setFillColor( 1 )
        grupoPedidoNuevo:insert(thHeaderS[i])
        
        tdTxtHeader[i] = display.newText( {
            text = tdHeaderName[i],     
            x = poscXH + tdHeaderWitdh[i]/2, y = poscTabla - 25, width = tdHeaderWitdh[i],
            font = native.BrushScriptStd, fontSize = 22, align = "center"
        })
        tdTxtHeader[i]:setFillColor( 0 )
        grupoPedidoNuevo:insert(tdTxtHeader[i])
    
        poscXH = poscXH + tdHeaderWitdh[i]
    
    end

    --idsucursaltemporal = db_sucursal.getSucursalPedidoTemporal()
    contArticulosCargados = 0
    print(idsucursal)
    local sucursalCatalogo = db_sucursal.getCatalogoSucursal(idsucursal, 0, limiteSegmento) 
    --id de sucursal seleccionada, desde 0 hasta la cantidad de articulos por segmento
    
    --se crean los textfields
    if contItemsCat <= 4 then
        imageSiguiente.alpha = 0
    end

    createNativeTextField()

end

function scene:exitScene( event )

    grupoPedidoNuevo:removeSelf()
    for i = 1, #txtTalla, 1 do
        txtTalla[i]:removeSelf()
         --print(txtTalla[i])
    end
    txtTalla = {}

    timeMarker = timer.performWithDelay( 500, function ( )
        storyboard.removeScene('scenes.pedidoNuevo')
    end, 1)


end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene",  scene)
scene:addEventListener("exitScene",   scene)

return scene