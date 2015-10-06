-----------------------------------------------------------------------------------------
--
-- db_pedido.lua
--
-----------------------------------------------------------------------------------------

local db_pedido = {}

local mime   = require("mime")
local json   = require("json")
local crypto = require("crypto")


local conexionServer = require ("include.conexion_server")
local conexionSQLite = require ("include.conexion_sqlite")


db_pedido.getPedido = function ( idPedido )
	--devuelve la fila con los datos del pedido
	local infoPedido = conexionSQLite.getPedido(idPedido)
	return infoPedido
end

db_pedido.getDetallePedido = function ( idPedido )
	--devuelve la fila con los datos del pedido
	conexionSQLite.getDetallePedido(idPedido)
end

db_pedido.getTotalPedido = function ( idPedido )
	--devuelve el total del pedido
	print("idpedido: " .. idPedido)
	local t = conexionSQLite.getTotalPedido(9)
	print("total: " .. t.total)
	return t.total
end

db_pedido.getPedidosVendedor = function ( )
	
	local idVendedor = conexionSQLite.getIdVendedor()
	conexionSQLite.getPedidosVendedor(idVendedor)

end

--function para insertar pedidos en la base de datos del servidor
db_pedido.insertarPedidoServidor = function ( idsucursal )
	
	local idVendedor = conexionSQLite.getIdVendedor()
	local fechaActual = os.date( "%Y" )  .. "-" .. os.date( "%m" )  .. "-" .. os.date( "%d" )

	conexionServer.insertPedido(idVendedor, idsucursal, fechaActual)

	return true

end

--function para insertar pedidos en la base de datos local
db_pedido.insertarPedidoLocal = function ( folio, idsucursal, total )
	
	local fechaActual = os.date( "%Y" )  .. "-" .. os.date( "%m" )  .. "-" .. os.date( "%d" )
	print("fechaActual: " .. fechaActual)
	local idPedido = conexionSQLite.insertPedido( folio, idsucursal, fechaActual, total )

	return idPedido

end

--function para insertar el detalle del pedido(las ordenes) en la base de datos del servidor
db_pedido.insertarDetallePedidoServidorConString = function ( folio, idsucursal, detallePedidoCatalogoSucursal, detallePedidoCatalogoRestante )
	
	
	if(detallePedidoCatalogoSucursal ==  nil) then
		print("No hay detallepedido de la sucursal, solo machote")
	else
		print("Detalle pedido de la sucursal: " .. detallePedidoCatalogoSucursal)
	end
	
	conexionServer.insertarDetallePedidoServidorConString(folio, idsucursal, detallePedidoCatalogoSucursal, detallePedidoCatalogoRestante )
	
	return true

end

--function para insertar el detalle del pedido(las ordenes) en la base de datos del servidor
db_pedido.insertarDetallePedidoServidor = function ( folio, skucatalogo, talla, orden )
	
	conexionServer.insertarDetallePedido(folio, skucatalogo, talla, orden)
	
	return true

end

--function para insertar el detalle del pedido (las ordenes) en sqlite
db_pedido.insertarDetallePedidoLocal = function ( idpedido, idcatalogo, talla, orden )
	print("idcatalogo: " .. idcatalogo)
	conexionSQLite.insertarDetallePedido(idpedido, idcatalogo, talla, orden)
	return true
end



return db_pedido