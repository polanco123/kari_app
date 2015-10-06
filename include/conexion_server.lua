-----------------------------------------------------------------------------------------
--
-- conexion_server.lua
--
-----------------------------------------------------------------------------------------

local conexion_server = {}

local mime   = require("mime")
local json   = require("json")
local crypto = require("crypto")
local conexionSQLite = require ("include.conexion_sqlite")
local dbCatalogo = require ("include.db_catalogo")

local arraySync = {}

local baseURL = "http://karisur.com.mx/"

local contTablasSync = 0

--numero de las tablas que se verifican si se sincronizan
local numTablasSync = 4


----------------- PEDIDOS -------------------

conexion_server.getPedidosVendedor = function ( idVendedor)
	
	local url = baseURL .. "app/getPedidos"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "idVendedor=" .. idVendedor
	params.body = strEnviar


	local function callback(event)
		
		if(event.isError) then
			--print("error no lo trajo")
		else
			
			local data = json.decode(event.response)
			if data.success == true then
				
				if #data.pedidos > 0 then
					llenadoTablaPedidosHome(data.pedidos)
				else 
					print("el vendedor no tiene pedidos")
				end

			else
				print("no regreso la consulta")
			end
		end

	end

	network.request( url , "POST", callback, params )	
end


conexion_server.insertPedido = function ( idVendedor, idsucursal, fecha )
	
	--obtener los datos de la tabla pedido temporal
	--local datosPedidoTemporal = conexionSQLite.getPedidoTemporal()

	local url = baseURL .. "app/insertarPedido"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}
	params.headers = headers
	local strEnviar = "idVendedor=" .. idVendedor .. "&idSucursal=" .. idsucursal .. "&fecha=" .. fecha
	params.body = strEnviar
	local function callback(event)
		
		if(event.isError) then
			--print("error no lo trajo")
		else
			
			local data = json.decode(event.response)
			if data.success == true then
				
				if data.folio > 0 then
					registrarDetallePedido(data.folio)
				else
					print("error al devolver el folio")
				end

			else
				print("error al insertar el pedido")
			end
		end

	end

	network.request( url , "POST", callback, params )	
end

conexion_server.insertarDetallePedido  = function ( folio, skucatalogo, idtalla, orden )

	local url = baseURL .. "app/insertarDetallePedido"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "folio=" .. folio .. "&skucatalogo=" .. skucatalogo .. "&idtalla=" .. idtalla .. "&orden=" .. orden
	params.body = strEnviar

	local function callback(event)
		
		if(event.isError) then
			print("error no lo trajo: error: " .. event.errorMessage)
			
		else
			
			local data = json.decode(event.response)
			if data.success == true then
				
				if data.idcatalogo == "" then
					print("error al devolver el folio")
					
				else 
					print("insertado articulo: " .. data.idcatalogo)
				end

			else
				print("error al insertar el pedido")
			end
		end

	end

	network.request( url , "POST", callback, params )	
end

conexion_server.insertarDetallePedidoServidorConString = function ( folio, idsucursal, detallePedido1, detallePedido2  )

	print(detallePedido2)

	--obtener los datos de la tabla pedido temporal
	--local datosPedidoTemporal = conexionSQLite.getPedidoTemporal()

	local url = baseURL .. "app/insertarDetallePedidoServidorConString"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}
	params.headers = headers
	local strEnviar = "folio=" .. folio .. "&idSucursal=" .. idsucursal .. "&detallePedidoCatalogoS=" .. detallePedido1 .. "&detallePedidoCatalogoR=" .. detallePedido2
	params.body = strEnviar
	local function callback(event)
		
		if(event.isError) then
			--print("error no lo trajo")
		else
			
			--[[local data = json.decode(event.response)
			if data.success == true then
				
				print("BIEN")
				print(data.folio)
			

			else
				print("error al insertar el pedido")
			end

			]]
		end

	end

	network.request( url , "POST", callback, params )

end

conexion_server.addProductoCatalogo  = function ( idsucursal, sku )
	
	print("idSucursal serv: " .. idsucursal)
	print("sku serv: " .. sku)

	local url = baseURL .. "app/agregarRefSucursalCatalogo"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "idSucursal=" .. idsucursal .. "&skuCatalogo=" .. sku
	params.body = strEnviar

	local function callback(event)
		
		if(event.isError) then
			print("error no lo trajo: error: " .. event.errorMessage)
			
		else
			
			local data = json.decode(event.response)
			
			if data.success == true then
				print("AGREGADO PRODUCTO A CATALOGO EN SERVIDOR")
				--[[if data.idcatalogo == "" then
					print("error al devolver el folio")
					
				else 
					print("insertado articulo: " .. data.idcatalogo)
				end]]

			else
				print("error al insertar el pedido")
			end
		end

	end

	network.request( url , "POST", callback, params )
end



----------------- SYNC -------------------

conexion_server.getComprobarSync = function ( idVendedor, nombreTabla )

	local url = baseURL .. "app/getNeedSync"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "idVendedor=" .. idVendedor .. "&nombreTabla=" .. nombreTabla
	params.body = strEnviar

	local function callback(event)
		
		if(event.isError) then
			print("error no lo trajo")
			return false
		else
			local data = json.decode(event.response)
			local needSync = false

			--si regreso bien la consulta
			if data.success == true then
				--1 si se necesita sincronizar con esa tabla
				if data.needSync == "1" then
					--se pone que la tabla necesita sincronizarse
					print("si necesita sync: " .. nombreTabla )
					arraySync[nombreTabla] = true
					needSync = true
				else
					print("no necesita sync: " .. nombreTabla )
					arraySync[nombreTabla] = false
				end
				--cada vez que regresa la peticion, aumentar en contador para saber
				--si ya se busco si se necesita sincronizacion de todas las tablas
				contTablasSync = contTablasSync + 1;

				if contTablasSync == numTablasSync then
					empezarSincronizacion(arraySync)
					--resetear valores
					arraySync = {}
					contTablasSync = 0
				end	
			else
				print("no regreso la consulta")
				return false
			end
		end
	end
	network.request( url , "POST", callback, params )	
end

conexion_server.setCompleteSync = function ( idVendedor, nombreTabla )
	
	local url = baseURL .. "app/setCompleteSync"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "idVendedor=" .. idVendedor .. "&nombreTabla=" .. nombreTabla
	params.body = strEnviar

	local function callback(event)
		
		if(event.isError) then
			print(event)
		else
			
			local data2 = json.decode(event.response)
			if data2.success == true then
				if data2.affectedRows > 0 then

					print("Se completó satisfactoriamente la sincronización.")
					
					return true
				else 
					native.showAlert("Error al sincronizar.",
						"Ocurrió un error al sincronizar la base de datos. Intentarlo más tarde.", 
						{ OK }
					)
					print("Error al sincronizar.")	
					return false
				end

			else
				native.showAlert("Error al sincronizar.",
					"Ocurrió un error al sincronizar la base de datos. Intentarlo más tarde.", 
					{ OK }
				)
				print("No se obtuvo feed-back")
			end
		end

	end

	network.request( url , "POST", callback, params )	
end

--------------- CATALOGO -----------------

conexion_server.getCatalogoRestante = function (lastIdCatalogoInterno )

	local url = baseURL .. "app/getCatalogoRestante"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "apartirDeId=" .. lastIdCatalogoInterno
	params.body = strEnviar

	local function callback(event)
		
		if(event.isError) then
			--print("error no lo trajo")
		else
			
			local data = json.decode(event.response)
			if data.success == true then
				if #data.catalogoRestante > 0 then
					--si obtuvo bien el catalogo restante
					dbCatalogo.agregarCatalogoRestante(data.catalogoRestante)
				else 
					print("error, no se obtuvo productos que agregar")
					return false
				end

			else
				print("no regreso la consulta")
			end
		end

	end

	network.request( url , "POST", callback, params )
end

conexion_server.sincronizarPedidos = function ( idVendedor )
	--se eliminan los pedidos donde coincidan en folio traidos del servidor
	--que ya esten ene stado 2 (entregados)
	
	--[[for i = 1, #arrayFoliosLocales, 1 do
		print("folio local: " .. arrayFoliosLocales[i])
	end]]
	print("idvendedor: " .. idVendedor)

	local url = baseURL .. "app/getFoliosPedidosEntregados"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	local strEnviar = "idVendedor=" .. idVendedor
	params.body = strEnviar

	local function callback(event)
		
		if(event.isError) then
			print("error no lo trajo")
			return false
		else
			local data = json.decode(event.response)

			--si regreso bien la consulta
			if data.success == true then

				--recorrer los folios entregados
				for i = 1, #data.foliosPedidosEntregados, 1 do
					print("folio server: " .. data.foliosPedidosEntregados[i])

					--eliminar los pedidos y detalles de pedidos locales
					print("eliminando folio: " .. data.foliosPedidosEntregados[i])
					conexionSQLite.eliminarPedido(data.foliosPedidosEntregados[i])
				end

				
			else
				print("no regreso la consulta correctamente")
				return false
			end
		end
	end
	network.request( url , "POST", callback, params )

end


--[[conexion_server.getPedidosVendedor = function ( idVendedor)
	
	local url = baseURL .. "app/getCatalogo"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers
	--local strEnviar = "idVendedor=" .. idVendedor
	--params.body = strEnviar


	local function callback(event)
		
		if(event.isError) then
			--print("error no lo trajo")
		else
			
			local data = json.decode(event.response)
			if data.success == true then
				
				if #data.pedidos > 0 then
					llenadoTabla(data.pedidos)
				else 
					print("el vendedor no tiene pedidos")
				end

			else
				print("no regreso la consulta")
			end
		end

	end

	network.request( url , "POST", callback, params )	
end]]


return conexion_server


