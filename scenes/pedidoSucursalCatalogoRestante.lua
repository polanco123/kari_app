-----------------------------------------------------------------------------------------
--
-- pedidoSucursalCatalogoRestante.lua
--
-----------------------------------------------------------------------------------------

-- requires--

local widget = require("widget")
local storyboard = require("storyboard")
local db_sincronizacion = require ("include.db_sincronizacion")
local db_sucursal = require ("include.db_sucursal")
local db_pedido = require ("include.db_pedido")

local scene = storyboard.newScene()
local grupoCatalogoRestante = display.newGroup()
local grupoImagen = display.newGroup()
local bgGrupoImagen
local grupoSegmento = {} --array de grupos de los segmentos (cada 99 articulos es un segmento)
local tableCatalogoRestante

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
local totalProductosCatalogo = 0

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

--tallas del anterior segmento (en caso de que tenia catalogo la sucursal)
local articulosC = {}
local articulosSQLiteC = {}
local numArticulosPedidosAntes = 0
local xsC = {}
local sC = {}
local mC = {}
local lC = {}
local xlC = {}
local xxlC = {}
local xxxlC = {}
local uniC = {}
-- end tallas

local imageRegresarAnterior, imageRegresarSiguiente
local imgGrupoImage

local txtDescripcionGrupoImage
local txtSkuGrupoImage
local txtColorGrupoImage
local txtSublineaGrupoImage


local idsucursaltemporal
--cantidad de articulos por segmento
local limiteSegmento = 200
--contador para los articulos que se han cargado
local contArticulosCargados
local articuloActual = ''
local contItemsCat = 0
local idsucursal
local idsucursal_server
local pedidoCreadoAntes = false
local pedidoActual = 1
-- se ingresaran los articulos del catalogo 
--ejemplo  articulos[1] = {1 (idcatalogo)} , articulos[2] = {3 (idcatalogo)}
local articulos = {}
local articulosSQLite = {}

function verImagen( event )
	if event.target.imgpreview == false then
		native.showAlert( "Sin previsualización", "No se ha podido cargar la imagen.", { "OK" } )
	else
		esconderTextFields()
		local skuImg = event.target.imagen
		print("cargando imagen: " .. skuImg)
		grupoImagen.x = 0
		bgGrupoImagen = display.newRect( 0, top, width_s, height_s - top) --x, y, width, height
	    bgGrupoImagen.anchorX = 0
	    bgGrupoImagen.anchorY = 0
	    bgGrupoImagen:setFillColor( 0 )
	    bgGrupoImagen.alpha = .7

	    grupoImagen:insert(bgGrupoImagen)

	    imgGrupoImage = display.newImage("storage/emulated/0/DCIM/catalogo/".. skuImg, width_s / 3 , height_s / 2)
		imgGrupoImage:scale(1, 1)

		txtSkuGrupoImage  = display.newText( {
			text = event.target.sku,     
			x = (width_s / 4) * 3 , y = imgGrupoImage.y - (imgGrupoImage.height / 2) + 10, width = width_s,
			font = native.BrushScriptStd, fontSize = 24, align = "center"
		})
		txtSkuGrupoImage:setFillColor( 1 )
		grupoImagen:insert(txtSkuGrupoImage)

		txtDescripcionGrupoImage  = display.newText( {
			text = event.target.descripcion,     
			x = (width_s / 4) * 3 , y = txtSkuGrupoImage.y + 40, width = width_s,
			font = native.BrushScriptStd, fontSize = 18, align = "center"
		})
		txtDescripcionGrupoImage:setFillColor( 1 )
		grupoImagen:insert(txtDescripcionGrupoImage)

		txtColorGrupoImage  = display.newText( {
			--text = event.target.color,
			text = "AZUL",     
			x = (width_s / 4) * 3 , y = txtSkuGrupoImage.y + 80, width = width_s,
			font = native.BrushScriptStd, fontSize = 20, align = "center"
		})
		txtColorGrupoImage:setFillColor( 1 )
		grupoImagen:insert(txtColorGrupoImage)

		txtSublineaGrupoImage  = display.newText( {
			--text = event.target.sublinea,     
			text = "BORDADA",
			x = (width_s / 4) * 3 , y = txtSkuGrupoImage.y + 120, width = width_s,
			font = native.BrushScriptStd, fontSize = 20, align = "center"
		})
		txtSublineaGrupoImage:setFillColor( 1 )
		grupoImagen:insert(txtSublineaGrupoImage)		
		

	    bgGrupoImagen:addEventListener( 'tap', closeGrupoImagen )
	end
end

function closeGrupoImagen( event )
	 
    bgGrupoImagen.x = 900
    imgGrupoImage:removeSelf()
    txtSkuGrupoImage:removeSelf()
    txtDescripcionGrupoImage:removeSelf()
    txtColorGrupoImage:removeSelf()
    txtSublineaGrupoImage:removeSelf()
    mostrarTextFields()

    return true

end

function mostrarTextFields( event )
	
	for j = 1, #grupoTextFields, 1 do
		grupoTextFields[j].x = 0
	end

end

function esconderTextFields( event )

	for j = 1, #grupoTextFields, 1 do
		grupoTextFields[j].x = 900
	end
		
end


function llenadoFormularioPedidoCatalogoRestante( items ) --print("cantidad:" .. #items)
	crearFila2(items, contItemsCat)
	totalItemsPedido = totalItemsPedido + 1
end

function crearFila2( items, posc )

	local lineS = {}
	local posc
	--como los registros devueltos pueden repetirse los sku (sku1 - talla1, sku1 - talla2...)
	--cada vez que se cambie de articulo
	if items.sku ~= articuloActual then

		--si todavia se pueden cargar mas articulos en el segmento
		--if contItemsCat <  limiteSegmento then 
			contItemsCat = contItemsCat + 1
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
			
			--img[posc] = display.newImage("storage/emulated/0/DCIM/catalogo/"..items.imagen, 65, posicion_y + 10)
			img[posc] = display.newImage("img/catalogo/"..items.imagen, 65, posicion_y + 10)
			print("sku:" .. items.sku .. "; img: " .. items.imagen)

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
			img[posc]:addEventListener("tap", verImagen)



			grupoSegmento[totalGrupoPedido]:insert(img[posc])
			poscXL = poscXL + tdHeaderWitdh[2]

			--sku
			sku[posc] = display.newText( {
				text = items.sku,
				--text =  items.imagen,        
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

			txtPrecio[posc] = display.newText({
				text = "$0.00", 
				x = width_s - 35, y = posicion_y - 10, width = 55,
				font = native.BrushScriptStd, fontSize = 16, align = "right"
			})
			txtPrecio[posc]:setFillColor( 0 )
			grupoSegmento[totalGrupoPedido]:insert(txtPrecio[posc])

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

		--end

	end

	articuloActual =  items.sku

	totalProductosCatalogo =  contItemsCat



end

--crea los textField
function createNativeTextField2()

	--print(totalItemsPedido)

	


	
	if txtTalla[1] == nil then

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
				txtTalla[tTalla]:addEventListener("userInput", ingresandoOrden2)
				grupoTextFields[totalGrupoPedido]:insert(txtTalla[tTalla])
				poscXL = poscXL + tdHeaderWitdh[i + 2]	

			end

			--posicion_y = posicion_y + row[j].height - 50
		
			posicion_y = posicion_y + 110
			
		end
	
	end
	
end


function ingresandoOrden2( event )

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
		--(4 es la cantidad de articulos que se ven x seccion)
		numFila = ( imageRegresarAnterior.num * 4 ) + numFila

		print("num de flecha: " .. imageRegresarAnterior.num)

		if tallaTextEvent == 1 then
			xs[numFila] = numeroOrden
		elseif tallaTextEvent ==  2 then
			s[numFila] = numeroOrden
		elseif tallaTextEvent ==  3 then
			m[numFila] = numeroOrden
		elseif tallaTextEvent ==  4 then
			l[numFila] = numeroOrden
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
		txtPrecio[numFila].text =  "$" .. tostring(tonumber((costo[numFila]) * xs[numFila]) + tonumber((costo[numFila]) * s[numFila]) + tonumber((costo[numFila]) * m[numFila]) + tonumber((costo[numFila]) * l[numFila]) + tonumber((costo[numFila]) * xl[numFila]) + tonumber((costo[numFila]) * xxl[numFila]) + tonumber((costo[numFila]) * xxxl[numFila]) + tonumber((costo[numFila]) * uni[numFila]) )
    end   
end

function registrarPedido( event )

	if ( event.phase == "ended" or event.phase == "submitted" ) then

		cargarLoading()
		--esconderTextFields()
 --print("articulos cargados: " .. contItemsCat)
		--ejemplos
		
		--[[s[1] = 20
		m[1] = 10
		m[2] = 10
		l[2] = 10
		m[4] = 20
		l[4] = 30
		m[5] = 10
		l[5]= 10]]
		
		--si no se creo el pedido antes, que puede ser:
		--[[
			- la sucursal no tiene catalogo y entro primero a esta escena con todo el catalogo machote
			- no ordeno productos de su catalogo, solo va a aumentar su catalogo
		]]


		if db_sincronizacion.getComprobarConexion() then
			
			--comprobar conexion a internet,
			--si existe conexion registrar el pedido en el servidor
			db_pedido.insertarPedidoServidor(idsucursal_server)

		else
			--si no hay conexion
			print("no hay internet")
			native.showAlert( "Sin cnexion a internet", "Sin internet.", { "OK"} )

			--db_pedido.insertPedidoLocal( idsucursaltemporal, fechaActual)
		end

	end

end

function registrarDetallePedido( folioServ )
	--print("detallepedido CON FOLIO: " .. folioServ)
	local idPedidoSQLite =  db_pedido.insertarPedidoLocal(folioServ, idsucursal, 4000)
	--print("idpedido: " .. idPedidoSQLite)

	local strDetalleOrdenCatalogo = ''


	if pedidoCreadoAntes == true then
		print("no se ha creado pedido")
		-- si ordeno de su catalogo se inserta el detalle del pedido
		
		print("****** Productos de su catalogo ******")

		strDetalleOrdenCatalogo = ""
		local primerDetalleOrden = true

		for i = 1, numArticulosPedidosAntes, 1 do

			print("---------------------")
			print("articulo: " .. articulosC[i]) 
			print("xs["..i.."]="..xsC[i])
			print("s["..i.."]=" ..sC[i])
			print("m["..i.."]=" ..mC[i])
			print("l["..i.."]=" ..lC[i])
			print("xl["..i.."]=" ..xlC[i])
			print("xxl["..i.."]=" ..xxlC[i])
			print("xxxl["..i.."]=" ..xxxlC[i])
			print("uni["..i.."]=" ..uniC[i])

			--PARA CONCATENAR
			local tllXS = ''
			local tllS = ''
			local tllM = ''
			local tllL = ''
			local tllXL = ''
			local tllXXL = ''
			local tllXXXL = ''
			local tllUNI = ''
			local ordenaTalla = false

			--se recorren todos los arrays de las tallas para insertar el pedido
		
			if tonumber(xsC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 1, xsC[i])				
				print("Orden registrada: folio - " .. idPedidoSQLite .. " articulo - " .. articulosSQLiteC[i] .. " talla - xs, orden - " .. xsC[i])

				tllXS = xsC[i]
				ordenaTalla = true
			end
			if tonumber(sC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 2, sC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - s, orden - " .. sC[i])

				tllS = sC[i]
				ordenaTalla = true
			end
			if tonumber(mC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 3, mC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - m, orden - " .. mC[i])

				tllM = mC[i]
				ordenaTalla = true
			end
			if tonumber(lC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 4, lC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - l, orden - " .. lC[i])
				
				tllL = lC[i]
				ordenaTalla = true
			end
			if tonumber(xlC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 5, xlC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - xl, orden - " .. xlC[i])
				
				tllXL = xlC[i]
				ordenaTalla = true
			end
			if tonumber(xxlC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 6, xxlC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - xxl, orden - " .. xxlC[i])
				
				tllXXL = xxlC[i]
				ordenaTalla = true
			end
			if tonumber(xxxlC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 7, xxxlC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - xxxl, orden - " .. xxxlC[i])
				
				tllXXXL = xxxlC[i]
				ordenaTalla = true
			end
			if tonumber(uniC[i]) > 0 then -- si en la talla del articulo hay algo
				--se regitra el pedido en la base de datos local
				db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLiteC[i], 8, uniC[i])				
				print("Orden registrada: articulo - " .. articulosSQLiteC[i] .. " talla - uni, orden - " .. uniC[i])
				
				tllUNI = uniC[i]
				ordenaTalla = true
			end

			if ordenaTalla == true then

				--creando el detallepedido en string para pasarlo todo
				if primerDetalleOrden == false then
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ";"
				end

				strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. articulosC[i]

				local primerTallaDetalleOrden = true

				if tllXS ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end	
					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "1-" .. tllXS
					primerTallaDetalleOrden = false
				
				end

				if tllS ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end	
					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "2-" .. tllS
					primerTallaDetalleOrden = false
				
				end

				if tllM ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end	
					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "3-" .. tllM
					primerTallaDetalleOrden = false

				end

				if tllL ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end

					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "4-" .. tllL
					primerTallaDetalleOrden = false
				
				end

				if tllXL ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end

					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "5-" .. tllXL
					primerTallaDetalleOrden = false
				
				end

				if tllXXL ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end

					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "6-" .. tllXXL
					primerTallaDetalleOrden = false
				
				end

				if tllXXXL ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end

					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "7-" .. tllXXXL
					primerTallaDetalleOrden = false
				
				end

				if tllUNI ~= '' then
					
					if primerTallaDetalleOrden == true then
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "/"
					else
						strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. ","
					end

					
					strDetalleOrdenCatalogo = strDetalleOrdenCatalogo .. "8-" .. tllUNI
					primerTallaDetalleOrden = false
				
				end




				primerDetalleOrden = false

			end

		end

	end -- END IF

	print("pedido de catalogo(parte 1): " .. strDetalleOrdenCatalogo)


	print("****** Productos de catalogo restante (machote) ******")

	local strDetalleOrdenRestante = ""
	local primerDetalleOrden = true


	for i = 1, contItemsCat, 1 do

		print("---------------------")
		print("articulo: " .. articulos[i]) 
		print("xs["..i.."]="..xs[i])
		print("s["..i.."]=" ..s[i])
		print("m["..i.."]=" ..m[i])
		print("l["..i.."]=" ..l[i])
		print("xl["..i.."]=" ..xl[i])
		print("xxl["..i.."]=" ..xxl[i])
		print("xxxl["..i.."]=" ..xxxl[i])
		print("uni["..i.."]=" ..uni[i])

		local ordenaTalla = false

		--PARA CONCATENAR
		local tllXS = ''
		local tllS = ''
		local tllM = ''
		local tllL = ''
		local tllXL = ''
		local tllXXL = ''
		local tllXXXL = ''
		local tllUNI = ''


		--se recorren todos los arrays de las tallas para insertar el pedido

		if tonumber(xs[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 1, xs[i])				
			print("Orden registrada: folio - " .. idPedidoSQLite .. " articulo - " .. articulosSQLite[i] .. " talla - xs, orden - " .. xs[i])

			tllXS = xs[i]
			ordenaTalla = true
		end
		if tonumber(s[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 2, s[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - s, orden - " .. s[i])
			
			tllS = s[i]
			ordenaTalla = true
		end
		if tonumber(m[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 3, m[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - m, orden - " .. m[i])

			tllM = m[i]
			ordenaTalla = true
		end
		if tonumber(l[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 4, l[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - l, orden - " .. l[i])
			
			tllL = l[i]
			ordenaTalla = true			
		end
		if tonumber(xl[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 5, xl[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - xl, orden - " .. xl[i])
			
			tllXL = xl[i]
			ordenaTalla = true	
		end
		if tonumber(xxl[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 6, xxl[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - xxl, orden - " .. xxl[i])
			
			tllXXL = xxl[i]
			ordenaTalla = true
		end
		if tonumber(xxxl[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 7, xxxl[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - xxxl, orden - " .. xxxl[i])
			
			tllXXXL = xxxl[i]
			ordenaTalla = true
		end
		if tonumber(uni[i]) > 0 then -- si en la talla del articulo hay algo
			--se regitra el pedido en la base de datos local
			db_pedido.insertarDetallePedidoLocal(idPedidoSQLite, articulosSQLite[i], 8, uni[i])				
			print("Orden registrada: articulo - " .. articulosSQLite[i] .. " talla - uni, orden - " .. uni[i])
			
			tllUNI = uni[i]
			ordenaTalla = true
		end

		--agregar el producto al catalogo de la sucursal
		if ordenaTalla == true then
			--se agrega al catalogo en local
			db_sucursal.addProductoCatalogoLocal(idsucursal , articulosSQLite[i] )
			print("producto: " .. articulosSQLite[i] .. " agregado al catalogo local de la sucursal: " .. idsucursal)
			
			--se agrega al catalogo en servidor
			db_sucursal.addProductoCatalogoServer(idsucursal_server , articulos[i])
			print("producto: " .. articulos[i] .. " agregado al catalogo server de la sucursal: " .. idsucursal)


			--creando el detallepedido en string para pasarlo todo
			if primerDetalleOrden == false then
				strDetalleOrdenRestante = strDetalleOrdenRestante .. ";"
			end

			strDetalleOrdenRestante = strDetalleOrdenRestante .. articulos[i]

			local primerTallaDetalleOrden = true

			if tllXS ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end	
				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "1-" .. tllXS
				primerTallaDetalleOrden = false
			
			end

			if tllS ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end	
				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "2-" .. tllS
				primerTallaDetalleOrden = false
			
			end

			if tllM ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end	
				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "3-" .. tllM
				primerTallaDetalleOrden = false

			end

			if tllL ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end

				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "4-" .. tllL
				primerTallaDetalleOrden = false
			
			end

			if tllXL ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end

				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "5-" .. tllXL
				primerTallaDetalleOrden = false
			
			end

			if tllXXL ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end

				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "6-" .. tllXXL
				primerTallaDetalleOrden = false
	
			end

			if tllXXXL ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end

				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "7-" .. tllXXXL
				primerTallaDetalleOrden = false
	
			end

			if tllUNI ~= '' then
				
				if primerTallaDetalleOrden == true then
					strDetalleOrdenRestante = strDetalleOrdenRestante .. "/"
				else
					strDetalleOrdenRestante = strDetalleOrdenRestante .. ","
				end

				
				strDetalleOrdenRestante = strDetalleOrdenRestante .. "8-" .. tllUNI
				primerTallaDetalleOrden = false
	
			end


			primerDetalleOrden = false

		end


		timeMarker = timer.performWithDelay( 3000, function ( )
            terminarLoading()

    	end, 1)

	end -- end for

	-- problemas aki
	db_pedido.insertarDetallePedidoServidorConString( folioServ, idsucursal_server, strDetalleOrdenCatalogo, strDetalleOrdenRestante )
	--db_pedido.insertarDetallePedidoServidorConString( folioServ, idsucursal_server, "", strDetalleOrdenRestante )
	--folio, idsucursal, detallepedido de seccion 1(catalogosucursal), detallepedido de seccion 2(machote)		

	timeMarker = timer.performWithDelay( 3000, function ( )
        terminarLoading()
        mostrarTextFields()
        local function onComplete( event )

			storyboard.gotoScene("scenes.home")    

        end
           --if i == contItemsCat then
           native.showAlert( "Pedido registrado", "El registro fue registrado correctamente. Folio: " .. folioServ .. ".", { "OK"}, onComplete )
    	--end
    end, 1)

end

function cambiarSegmentoPedido( event )
	if event.target.tipo == 1 then
		transition.to( grupoSegmento[event.target.num], 	 { x = 0, time = 400, transition = easing.outExpo } )
		transition.to( grupoSegmento[event.target.num - 1 ], { x = -1000, time = 400, transition = easing.outExpo } )
		
		imageRegresarAnterior.alpha = 1

		--totalProductosCatalogo = 200

		if ( imageRegresarSiguiente.num ) * 4 >= totalProductosCatalogo  then
			imageRegresarSiguiente.alpha = 0
		end

		--cambia los valores de las flechas
		imageRegresarSiguiente.num = imageRegresarSiguiente.num + 1
		imageRegresarAnterior.num = imageRegresarAnterior.num + 1

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
		transition.to( grupoSegmento[event.target.num], 	 { x = 0, time = 400, transition = easing.outExpo } )
		transition.to( grupoSegmento[event.target.num + 1 ], { x = 1000, time = 400, transition = easing.outExpo } )

		imageRegresarSiguiente.alpha = 1

		if event.target.num == 1 then
			imageRegresarAnterior.alpha = 0
		end

		--cambia los valores de las flechas
		imageRegresarSiguiente.num = imageRegresarSiguiente.num - 1
		imageRegresarAnterior.num = imageRegresarAnterior.num - 1

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
	grupoCatalogoRestante = display.newGroup()
	vw = self.view

	vw:insert(grupoCatalogoRestante)
	local header = Header:new()
    grupoCatalogoRestante:insert(header)
    --getLoading(grupoCatalogoRestante)

    grupoImagen.x = 900

    grupoImagen:removeSelf()
    grupoImagen = display.newGroup()

    grupoImagen.x = 900

    --si el pedido se creo en la escena anterior se pasa true, sino false
    pedidoCreadoAntes = event.params.pedidoCreado
    idsucursal = event.params.idsucursal
    idsucursal_server = event.params.idsucursal_server

    -- si la sucursal tenia catalogo
    if pedidoCreadoAntes == true then

		articulosC = event.params.arrayProductos
		articulosSQLiteC = event.params.arrayProductosLocal
		print("hello2")
    	print("numarticulos anteriores: " .. event.params.numArticulos)


		numArticulosPedidosAntes = event.params.numArticulos

		

    	--  se pasan las ordenes del paso anterior
    	xsC = event.params.xs
    	sC = event.params.s
    	mC = event.params.m
    	lC = event.params.l
    	xlC = event.params.xl
    	xxlC = event.params.xxl
    	xxxlC = event.params.xxxl
    	uniC = event.params.uni

    	--[[for i = 1, #sC, 1 do
			print("elemento: " .. sC[i])
		end]]


    	--[[print("sC[1] es : " .. articulosSQLiteC[1] .. "-" .. articulosC[1] ..  "-" .. sC[1])
    	print("mC[1] es : " .. articulosSQLiteC[1] .. "-" .. articulosC[1] ..  "-" .. mC[1])
    	print("mC[2] es : " .. articulosSQLiteC[2] .. "-" .. articulosC[2] ..  "-" .. mC[2])]]
    end
   
	local thHeaderS = {}
	local tdTxtHeader = {}
	local poscXH = 1

	-- background
	local background = display.newRect( 0, top, width_s, height_s - top) 
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( 236/255, 240/255, 241/255 )
	grupoCatalogoRestante:insert(background)

	-- rectangulo negro top
	local recAcciones = display.newRect( 0, top, width_s, 45)
	recAcciones.anchorX = 0
	recAcciones.anchorY = 0
	recAcciones:setFillColor( 0 )
	grupoCatalogoRestante:insert(recAcciones)

	imageRegresarAnterior = display.newImage("img/app/arrowBackW.png" , width_s / 2 + 250 , top + 15)
    imageRegresarAnterior.height = 50
   	imageRegresarAnterior.width = 60
   	imageRegresarAnterior.num = 0
   	imageRegresarAnterior.alpha = 0
   	imageRegresarAnterior.tipo = 0
   	imageRegresarAnterior:addEventListener('tap', cambiarSegmentoPedido )
   	grupoCatalogoRestante:insert(imageRegresarAnterior)
   
   	imageRegresarSiguiente = display.newImage("img/app/arrowNextW.png" , width_s / 2 + 320 , top + 15)
   	imageRegresarSiguiente.height = 50
   	imageRegresarSiguiente.width = 60
   	imageRegresarSiguiente.num = 2
   	imageRegresarSiguiente.tipo = 1
   	imageRegresarSiguiente:addEventListener('tap', cambiarSegmentoPedido )
   	grupoCatalogoRestante:insert(imageRegresarSiguiente)

	local btnPedidoRegistrar =  widget.newButton({
    	label = "Registrar",
    	onEvent = registrarPedido,
    	emboss = true,
    	shape = "roundedRect",
    	labelColor = { default = { 1, 1, 1}, over = { 163, 25, 12} },
    	width = 150,
    	height = 32,
    	cornerRadius = 3
    })
    btnPedidoRegistrar.x = width_s / 2
    btnPedidoRegistrar:setFillColor(.05, .36, .30)
    btnPedidoRegistrar.y = top + 20
   	grupoCatalogoRestante:insert(btnPedidoRegistrar)

	--tabla de pedidos del vendedor

	-- header de la tabla de formulario para el pedido (barra gris)
	local thHeader = display.newRoundedRect ( width_s/2, poscTabla - 35, width_s - 6, 50,5) 
	thHeader.anchorY = 0
	thHeader:setFillColor( 189/255, 195/255, 199/255 )
	grupoCatalogoRestante:insert(thHeader)

	local poscXL = 0

	-- impresion de los headers
	for i = 1, 10, 1 do
	
		poscXL = tdHeaderWitdh[i] + poscXL
		
		--separadores
		thHeaderS[i] = display.newRect( poscXL, poscTabla - 35 , 2, 50) --x, y, width, height
		thHeaderS[i].anchorY = 0
		thHeaderS[i]:setFillColor( 1 )
		grupoCatalogoRestante:insert(thHeaderS[i])
		
		tdTxtHeader[i] = display.newText( {
            text = tdHeaderName[i],     
            x = poscXH + tdHeaderWitdh[i]/2, y = poscTabla - 10, width = tdHeaderWitdh[i],
            font = native.BrushScriptStd, fontSize = 22, align = "center"
        })
        tdTxtHeader[i]:setFillColor( 0 )
        grupoCatalogoRestante:insert(tdTxtHeader[i])
	
		poscXH = poscXH + tdHeaderWitdh[i]
	
	end

	--idsucursaltemporal = db_sucursal.getSucursalPedidoTemporal()
	contArticulosCargados = 0
	local sucursalCatalogo = db_sucursal.getCatalogoRestanteSucursal(idsucursal, 0, limiteSegmento) 
	--id de sucursal seleccionada, desde 0 hasta la cantidad de articulos por segmento
   	
	--se crean los textfields
   	createNativeTextField2()

end

function scene:exitScene( event )

	timeMarker = timer.performWithDelay( 250, function ( )

				grupoCatalogoRestante:removeSelf()
			for i = 1, #txtTalla, 1 do
				txtTalla[i]:removeSelf()
				--print(txtTalla[i])
			end
			txtTalla = {}
			storyboard.removeScene('scenes.pedidoSucursalCatalogoRestante')   

        	end, 1)

	
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene",  scene)
scene:addEventListener("exitScene",   scene)

return scene


