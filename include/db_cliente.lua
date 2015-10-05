-----------------------------------------------------------------------------------------
--
-- db_cliente.lua
--
-----------------------------------------------------------------------------------------

local db_cliente = {}

local mime   = require("mime")
local json   = require("json")
local crypto = require("crypto")

--local conexionServer = require ("screens.conexion.conexion_server")
local conexionSQLite = require ("include.conexion_sqlite")


db_cliente.getClienteCombo = function ( )
	local clientes = conexionSQLite.getClienteCombo()
	return clientes
end

db_cliente.getNumSucursales = function ( idcliente )
	local numeroSucursales = conexionSQLite.getNumSucursales( idcliente )
	return numeroSucursales
end

return db_cliente