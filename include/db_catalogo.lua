-----------------------------------------------------------------------------------------
--
-- db_catalogo.lua
--
-----------------------------------------------------------------------------------------

local db_catalogo = {}

local mime   = require("mime")
local json   = require("json")
local crypto = require("crypto")

--local conexionServer = require ("screens.conexion.conexion_server")
local conexionSQLite = require ("include.conexion_sqlite")


--function para insertar el catalogo restante (recibido del servidor) a la base de datos local
db_catalogo.agregarCatalogoRestante = function ( catalogoRestante )

	if conexionSQLite.insertarCatalogo(catalogoRestante) then
		bajarImagenCatalogo(catalogoRestante,1)
		return true
	end

end

function bajarImagenCatalogo(datosProducto,poscY)

	if poscY <= #datosProducto then

		local function loadImageListener( event )
			if event.target then
				event.target:removeSelf()
				poscY = poscY + 1
				bajarImagenCatalogo(datosProducto,poscY)
				
			end
		end
	
		display.loadRemoteImage( "http://www.karisur.com.mx/assets/img/data/catalogo/"..datosProducto[poscY].imagen, 
		"GET", loadImageListener, datosProducto[poscY].imagen, system.TemporaryDirectory )
	end
	
end

return db_catalogo