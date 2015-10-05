-----------------------------------------------------------------------------------------
--
-- db_sincronizacion.lua
--
-----------------------------------------------------------------------------------------

local db_sincronizacion = {}

local mime   = require("mime")
local json   = require("json")
local crypto = require("crypto")

local conexionServer = require ("include.conexion_server")
local conexionSQLite = require ("include.conexion_sqlite")


db_sincronizacion.getComprobarConexion = function ( )
	
	local con =  require('socket').connect('www.karisur.com.mx', 80)
	if con == nil then
		return false
	else
		return true
	end
	con:close()

end

db_sincronizacion.getComprobarSincronizacion = function ( )

	local syncCatalogo, syncPedido, syncCliente, syncSucursal, needSync = false
	local arraySync = {}

	local idVendedor   = conexionSQLite.getIdVendedor()
	syncCatalogo = conexionServer.getComprobarSync(idVendedor, "catalogo")
	syncPedido   = conexionServer.getComprobarSync(idVendedor, "pedido"  )
	syncCliente  = conexionServer.getComprobarSync(idVendedor, "cliente" )
	syncSucursal = conexionServer.getComprobarSync(idVendedor, "sucursal")

end

db_sincronizacion.sincronizarPedidos = function ( )

	--obtener los pedidos locales
	--luego comparar en el servidor con ellos 
	--y devolver solo los que estan en proceso

	local resultPedidos = conexionSQLite.getPedidosVendedorResult()

	for i = 1, #resultPedidos, 1 do
		print(resultPedidos[i]["id"])
	end

	--[[local url = baseURL .. "app/syncPedidos"
	local headers = { }
	headers["Content-Type"] = "application/x-www-form-urlencoded"
	local params = { }
	local body = {}

	params.headers = headers

	local function callback(event)
		
		if(event.isError) then
			--print("error no lo trajo")
		else
			
			local data = json.decode(event.response)
			if data.success == true then
				if #data.catalogoRestante > 0 then
					--si obtuvo bien el catalogo restante
					--dbCatalogo.agregarCatalogoRestante(data.catalogoRestante)
				else 
					print("error, no se obtuvo productos que agregar")
					return false
				end

			else
				print("no regreso la consulta")
			end
		end

	end

	network.request( url , "POST", callback, params )]]
end

return db_sincronizacion