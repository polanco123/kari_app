-----------------------------------------------------------------------------------------
--
-- db_sucursal.lua
--
-----------------------------------------------------------------------------------------

local db_sucursal = {}

local mime   = require("mime")
local json   = require("json")
local crypto = require("crypto")

local conexionServer = require ("include.conexion_server")
local conexionSQLite = require ("include.conexion_sqlite")


db_sucursal.getSucursalCombo = function ( idsucursal  )
	local sucursales = conexionSQLite.getSucursalCombo( idsucursal )
	return sucursales
end

db_sucursal.getNumCatalogoSucursal = function ( idsucursal  )
	local numeroProductos = conexionSQLite.getNumCatalogoSucursal( idsucursal )
	return numeroProductos
end

--obtiene la sucursal temporal
db_sucursal.getSucursalPedidoTemporal = function ( )
	local idsucursal = conexionSQLite.getSucursalPedidoTemporal( )
	return idsucursal
end

db_sucursal.setSucursalPedidoTemporal = function ( idsucursal )
	conexionSQLite.setSucursalPedidoTemporal( idsucursal )
end

db_sucursal.getCatalogoSucursal = function ( idsucursal, productoInicial, cantidad )
    print("datos: " .. idsucursal .. "; " .. productoInicial .. "; " .. cantidad)
	conexionSQLite.getCatalogoSucursal( idsucursal, productoInicial, cantidad )
end

db_sucursal.getCatalogoRestanteSucursal = function ( idsucursal, productoInicial, cantidad )
	local numeroProductos = conexionSQLite.getCatalogoRestanteSucursal( idsucursal, productoInicial, cantidad )
	return numeroProductos
end

db_sucursal.addProductoCatalogoLocal = function ( idsucursal, idcatalogo)
	conexionSQLite.addProductoCatalogo( idsucursal, idcatalogo )
	return true
end

--yaEnCatalogo boolean que detemina si el producto ya esta en el catalogo de la sucursal(true)
--o se necesita agregar al catalogo de la sucursal(false)
db_sucursal.addProductoCatalogoServer = function ( idsucursal, sku)
	conexionServer.addProductoCatalogo( idsucursal, sku )
end

return db_sucursal