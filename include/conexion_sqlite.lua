--Include sqlite
local dbManager = {}

	require "sqlite3"
	local path, db
    local lfs = require "lfs"

	--Open rackem.db.  If the file doesn't exist it will be created
	local function openConnection( )
        local pathBase = system.pathForFile(nil, system.DocumentsDirectory)
        print("Pathbase: " .. pathBase)
        if findLast(pathBase, "/data/data") > -1 then
            local newFile = pathBase:gsub("/app_data", "") .. "/databases/karisur.db"
            local fhd = io.open( newFile )
            if fhd then
                fhd:close()
            else
                local success = lfs.chdir(  pathBase:gsub("/app_data", "") )
                if success then
                    lfs.mkdir( "databases" )
                end
            end
            db = sqlite3.open( newFile )
        else
            db = sqlite3.open( system.pathForFile("karisur_movil.db", system.DocumentsDirectory) )
        end
	end

	local function closeConnection( )
		if db and db:isopen() then
			db:close()
		end     
	end
	 
	--Handle the applicationExit event to close the db
	local function onSystemEvent( event )
	    if( event.type == "applicationExit" ) then              
	        closeConnection()
	    end
	end

    -- Find substring
    function findLast(haystack, needle)
        local i=haystack:match(".*"..needle.."()")
        if i==nil then return -1 else return i-1 end
    end

	dbManager.getSettings = function()
		local result = {}
		openConnection( )
		for row in db:nrows("SELECT * FROM config;") do
			closeConnection( )
			return  row
		end
		closeConnection( )
		return 1
	end
	--catalogo -- 
	dbManager.getCatalogo = function ( inicial  )
		openConnection( )
		local row    --de 10 en 10 articulos
		for row in db:nrows("SELECT * FROM catalogo order by id limit " .. inicial .. ", 10;") do
			print(row.sku)
			llenadoTablaCatalogo(row)
		end
		closeConnection( )
	end

	dbManager.getCatalogoSucursal = function ( idsucursal, inicial, limiteSegmento )
		openConnection( )
		local row
		-- catalogo cat1 
		--for row in db:nrows("SELECT rsc.idcatalogo, cat.sku, cat.imagen, cat.costo, clr.nombre as nombrecolor FROM  refsucursalcatalogo rsc left join catalogo cat on rsc.idcatalogo = cat.id left join refcatalogocolor rcc on rsc.idcatalogo = rcc.idcatalogo left join color clr on rcc.idcolor = clr.id  where idsucursal = " .. idsucursal .. " limit " .. inicial ..  ", " .. limite ..";") do
		--for row in db:nrows("select cat.id, cat.sku, cat.imagen, cat.descripcion, cat.costo, clr.nombre as nombrecolor, rct.idtalla FROM ( select * from catalogo limit " ..  inicial .. ", " .. limite .. ") AS cat left join refcatalogotalla rct on cat.id = rct.idcatalogo left join refcatalogocolor rcc on rsc.idcatalogo = rcc.idcatalogo left join color clr on rcc.idcolor = clr.id  where idsucursal = " .. idsucursal .. ";") do
		-- ( select * from catalogo limit " ..  inicial .. ", " .. limite .. ") AS cat
		--for row in db:nrows("select cat.id, cat.sku, cat.imagen, cat.descripcion, cat.costo FROM catalogo;") do

		for row in db:nrows("select cat.id, cat.sku, cat.imagen, cat.descripcion, cat.costo, clr.nombre as nombrecolor, rct.idtalla"  .. 
		--" FROM ( select * from catalogo" ..
		--	" left join refsucursalcatalogo rsc on cat.id = rsc.idcatalogo " ..
		--	" where idsucursal = " .. idsucursal .. 
		--	" limit " ..  inicial .. ", " .. limiteSegmento .. ") AS cat" ..
		" FROM (select * from catalogo" ..
			" left join refsucursalcatalogo rsc on catalogo.id = rsc.idcatalogo " ..
			" where idsucursal = " .. idsucursal ..
			" limit " ..  inicial .. ", " .. limiteSegmento .. ") AS cat" ..
		" left join refcatalogotalla rct on cat.id = rct.idcatalogo" ..
		" left join refcatalogocolor rcc on cat.id = rcc.idcatalogo" .. 
		" left join color clr on rcc.idcolor = clr.id") do

			llenadoFormularioPedido(row)
		end
		--createNativeTextField()
		closeConnection( )
	end

	dbManager.getNumCatalogoSucursal = function ( idsucursal )
		
		openConnection( )
		local row
		for row in db:nrows("SELECT count(*) as totalcatalogo FROM refsucursalcatalogo rsc left join catalogo cat on rsc.idcatalogo = cat.id left join refcatalogocolor rcc on rsc.idcatalogo = rcc.idcatalogo left join color clr on rcc.idcolor = clr.id  where idsucursal = " .. idsucursal .. ";") do
			closeConnection( )
			return row.totalcatalogo
		end
		
	end
	

	dbManager.getCatalogoRestanteSucursal = function ( idsucursal, inicial, limiteSegmento)
		openConnection( )
		local row
		
		for row in db:nrows("select cat1.id, cat1.sku, cat1.imagen, cat1.descripcion, cat1.costo, cat1.tipo, rct.idtalla from catalogo cat1 join refcatalogotalla rct on cat1.id = rct.idcatalogo where cat1.id not in (select distinct cat2.id from catalogo cat2 join refsucursalcatalogo rsc on cat2.id = rsc.idcatalogo join sucursal suc on rsc.idsucursal = suc.id where suc.id = " .. idsucursal .. " and cat2.id = cat1.id) limit " .. inicial ..  ", " .. limiteSegmento .. ";") do  
		--for row in db:nrows("select cat1.id, cat1.sku, cat1.imagen, cat1.descripcion, cat1.costo, cat1.tipo from catalogo cat1 where cat1.id not in (select distinct cat2.id from catalogo cat2 join refsucursalcatalogo rsc on cat2.id = rsc.idcatalogo join sucursal suc on rsc.idsucursal = suc.id where suc.id = 1 and cat2.id = cat1.id);") do 	
			llenadoFormularioPedidoCatalogoRestante(row)
		end
		--createNativeTextField()
		closeConnection( )
	end

	dbManager.getNumRowsCatalogo = function ( )
		openConnection( )
		
		for row in db:nrows("SELECT count(*) as cantidadArticulos FROM catalogo;") do
            closeConnection( )
            
            print("Cantidad de articulo en base de datos local: " .. row.cantidadArticulos)
            return row.cantidadArticulos
		end

	end

	dbManager.getLastIdCatalogo = function (  )
		openConnection( )
		
		for row in db:nrows("SELECT id as lastId FROM catalogo order by id DESC LIMIT 0, 1 ;") do
            closeConnection( )

            print("Ultima id registrada: " .. row.lastId)
            return row.lastId
		end
	end

	dbManager.insertarCatalogo = function ( datosProducto )
		openConnection( )

		for z = 1, #datosProducto, 1 do
			--local tablefill = [[INSERT INTO catalogo VALUES (]]..datosProducto[z].id..[[,']]..datosProducto[z].sku..[[,']]..datosProducto[z].descripcion..[[',']]..datosProducto[z].imagen..[[',]]..datosProducto[z].costo..[[,']]..datosProducto[z].tipo..[[', 1); ]]

			--[[queryA = "INSERT INTO catalogo VALUES " ..
	           "("  .. datosProducto[z].id     .. ", " ..
	            "'" .. datosProducto[z].sku    .. "'" .. ", " ..
	            "'" .. datosProducto[z].imagen .. "'" .. ", " ..
	            	   datosProducto[z].costo  .. ", " ..
	            "'" .. datosProducto[z].tipo   .. "'" .. ", " ..
	            "1);"]]

			print ("insertando el articulo: " .. datosProducto[z].id )

			local tablefill = "insert into catalogo values (" .. datosProducto[z].id ..",'".. datosProducto[z].sku .."','".. datosProducto[z].descripcion .."','" .. datosProducto[z].imagen .."'," .. datosProducto[z].costo ..",'".. datosProducto[z].tipo .."',1)"

			db:exec( tablefill )

			--print (tablefill)
			
		end

		closeConnection( )
		print ("catalogo restante insertado")
		return true
	end

	--end catalogo --
	-- clientes--
	dbManager.getClientes = function (  )
		
		openConnection( )
		local row
		for row in db:nrows("SELECT * FROM cliente;") do
			llenadoTablaCliente(row)
		end
		closeConnection( )
	end

	dbManager.getClienteCombo = function ( )
		openConnection( )
		local row
		local clientes 
		for row in db:nrows("SELECT id_server as id, razonsocial FROM cliente order by razonsocial;") do
			nuevaOptionCliente(row.razonsocial, row.id)
			--[[clientes[#clientes+1] = 
			{
				id = row.id,
				razonsocial = row.razonsocial
			}]]
		end
		closeConnection( )
		return clientes
	end


	dbManager.insertarCliente = function ( numero, razonsocial, correo, telefono )
		openConnection()
		local queryInsert = "INSERT INTO cliente (id, numero, razonsocial, correo, telefono, activo) VALUES " .. 
        "( ( select id from cliente ORDER BY id desc limit 1  ) + 1, " .. numero .. ",'" .. razonsocial .. "','" .. correo .. "','" .. telefono .. "', 1 ); "
		print(queryInsert)
		db:exec( queryInsert )
		closeConnection( )
	end

	-- end clientes -- 

	-- sucursales--
	
	dbManager.getSucursales = function (  )
		
		openConnection( )
		local row
		for row in db:nrows("SELECT suc.id, suc.numero, suc.nombre, suc.activo, cli.id, cli.razonsocial FROM sucursal suc join cliente cli on suc.idcliente = cli.id;") do
			print(row.sku)
			llenadoTablaSucursales(row)
		end
		closeConnection( )
	end
	
	dbManager.getSucursalPedidoTemporal = function ( )
		openConnection()
		for row in db:nrows("SELECT idsucursal from sucursalpedidotemporal order by id desc limit 1;") do
			closeConnection( )
			return row.idsucursal
		end
	end

	dbManager.setSucursalPedidoTemporal = function ( idsucursal )
		openConnection()
		local queryInsert = "INSERT INTO sucursalpedidotemporal (idsucursal) VALUES " .. 
        "(" .. idsucursal .. "); "
		db:exec( queryInsert )
		closeConnection()
	end

	dbManager.getNumSucursales = function ( idcliente )
		openConnection( )
		local row
		for row in db:nrows("SELECT count(*) as totalsucursales FROM sucursal where idcliente = " .. idcliente .. ";") do
			closeConnection( )
			return row.totalsucursales
		end
	end

	dbManager.getSucursalCombo = function ( idcliente )
		openConnection( )
		local row
		for row in db:nrows("SELECT id, id_server, nombre FROM sucursal where idcliente = " .. idcliente .. " order by nombre;") do
			nuevaOptionSucursal(row.nombre, row.id, row.id_server)
		end
		closeConnection( )
	end

	dbManager.insertarSucursal = function ( numero, nombre, idcliente )
		openConnection()
		local queryInsert = "INSERT INTO sucursal (id, numero, nombre, idcliente, activo) VALUES " .. 
        "( ( select id from sucursal ORDER BY id desc limit 1  ) + 1, " .. numero .. ",'" .. nombre .. "'," .. idcliente .. ", 1 ); "
		print(queryInsert)
		db:exec( queryInsert )
		closeConnection()
	end

	dbManager.addProductoCatalogo = function ( idsucursal, idcatalogo )
		openConnection()
		local queryInsert = "INSERT INTO refsucursalcatalogo (idsucursal, idcatalogo) VALUES " .. 
        "( " .. idsucursal .. "," .. idcatalogo .. " ); "
		db:exec( queryInsert )
		closeConnection()
	end

	-- end sucursales -- 

	-- pedidos --

	dbManager.getPedidosVendedor = function ( idVendedor )
		openConnection( )
		local row
		for row in db:nrows("SELECT ped.id, ped.folio, strftime('%d-%m-%Y', ped.fecha) as fechapedido, ped.estado, suc.nombre as nombresucursal, cli.razonsocial as razonsocialcliente FROM pedido ped join sucursal suc on ped.idsucursal = suc.id join cliente cli on suc.idcliente = cli.id  ORDER BY ped.folio desc;") do
			print("Vista del folio: " .. row.folio)
			llenadoTablaPedidosHome(row)
		end
		closeConnection( )
	end

	dbManager.getPedidosVendedorResult = function ( idVendedor )
		openConnection( )
		local row
		local pedidos
		for row in db:nrows("SELECT ped.id, ped.folio, strftime('%d-%m-%Y', ped.fecha) as fechapedido, ped.estado, suc.nombre as nombresucursal, cli.razonsocial as razonsocialcliente FROM pedido ped join sucursal suc on ped.idsucursal = suc.id join cliente cli on suc.idcliente = cli.id  ORDER BY ped.folio desc;") do
			pedidos[#pedidos+1] = 
			{
				id = row.id,
				folio = row.folio,
				fecha = row.fechapedido,
				estado = row.estado,
				nombresucursal = row.nombresucursal,
				razonsocialcliente = row.razonsocialcliente 
			}
		end
		closeConnection( )
		return pedidos
	end

	dbManager.getPedido = function ( idPedido )
		openConnection( )
		local fila
		for row in db:nrows("SELECT ped.folio, ped.fecha, ped.total, ped.estado, suc.id as idsucursal, suc.nombre as nombresucursal, cli.id as idcliente, cli.razonsocial, cat.id as idcatalogo, cat.sku, cat.descripcion, cat.imagen, cat.costo, dp.talla, dp.orden FROM detallepedido dp join pedido ped on dp.idpedido = ped.id join catalogo cat on dp.idcatalogo =  cat.id join sucursal suc on ped.idsucursal = suc.id join cliente cli on suc.idcliente = cli.id where idpedido = " .. idPedido .. ";") do
			fila =  row
			closeConnection( )
			return fila
		end
	end

	dbManager.getDetallePedido = function ( idPedido )
		openConnection( )
		local fila
		for row in db:nrows("SELECT cat.id as idcatalogo, cat.sku, cat.descripcion, cat.imagen, cat.costo, dp.talla, dp.orden FROM detallepedido dp join catalogo cat on dp.idcatalogo =  cat.id where idpedido = " .. idPedido .. ";") do
			fila =  row
			crearFilaDetallePedido(fila)
		end
		closeConnection( )
	end

	dbManager.getTotalPedido = function ( idPedido )
		openConnection( )
		local total
		for row in db:nrows("SELECT total FROM pedido WHERE id =" .. idPedido .. ";") do
			total =  row
			closeConnection( )
			return total
		end
	end




	--funcion para insertar un pedido y ya se tiene el folio (se inserto previamente en el servidor)
	dbManager.insertPedido =  function ( folio, idsucursal, fecha, total )
		openConnection( )
		local queryInsert = "INSERT INTO pedido (id, folio, idsucursal, fecha, total, estado) VALUES " .. 
        "( ( select id from pedido ORDER BY id desc limit 1  ) + 1, " .. tonumber(folio) ..  ", " .. idsucursal .. ",'" .. fecha .. "'," .. total .. ", 1 ); "
		print(queryInsert)
		db:exec( queryInsert )
		local idpedido
		for row in db:nrows("SELECT id from pedido order by id desc limit 1;") do
			print(queryInsert)
			idpedido = row.id
		end
		closeConnection()
		return idpedido
	end
	--cuando no se encuentra conectado a internet
	dbManager.insertPedidoNoFolio =  function ( idsucursal, fecha )
		openConnection( )
		local queryInsert = "INSERT INTO pedido (id, idsucursal, fecha, estado) VALUES " .. 
        "( ( select id from pedido ORDER BY id desc limit 1  ) + 1, " .. idsucursal .. ",'" .. fecha .. "', 1 ); "
		print(queryInsert)
		db:exec( queryInsert )
		local idpedido
		for row in db:nrows("SELECT id from pedido order by id desc limit 1;") do
			local idpedido = row.id
		end
		closeConnection()
		return idpedido
	end

	dbManager.insertarDetallePedido =  function ( idpedido, idcatalogo, talla, orden  )
		openConnection( )
		local queryInsert = "INSERT INTO detallepedido ( idpedido, idcatalogo, talla, orden) VALUES " .. 
        "( " .. idpedido .. ", " .. idcatalogo .. ", " .. talla .. ", " .. orden .. "); "
		db:exec( queryInsert )
		closeConnection()
	end

	--Pedido temporal--

	dbManager.getPedidoTemporal =  function ( )
		openConnection( )
		local row_res

		for row in db:nrows("SELECT id, folio, idsucursal, fecha, estado FROM pedidotemporal pedtemp order by id limit 1;") do
			print("entra 2")
			print(row.idsucursal)
			row_res = row
			
			print("select idsucursal")
			print(row_res.idsucursal)
			
		end
		closeConnection( )
		return row_res

	end

	dbManager.getDetallePedidoTemporal =  function ( idpedidotemporal )
		openConnection( )
		local row_res

		for row in db:nrows("SELECT id, idcatalogo, talla, orden, estaencatalogo FROM detallepedidotemporal dtp where dtp.idpedidotemporal = ( select pt.id from pedidotemporal pt order by id desc limit 1 ) order by estaencatalogo desc;") do
			print("si entra aki!!!")
			row_res = row
			insertarDetallePedidoServer_SQLite(row_res)	
		end
		closeConnection( )
		return row_res

	end

	dbManager.insertarEnPedidoTemporal = function ( idsucursal, fecha )
		openConnection( )
		local idpedidotemporal
		local queryInsert = "INSERT INTO pedidotemporal (idsucursal, fecha, estado) VALUES " .. 
        "(" .. idsucursal .. ",'" .. fecha .. "', 1 ); "
		--print(queryInsert)
		db:exec( queryInsert )
		for row in db:nrows("SELECT id from pedidotemporal order by id desc limit 1;") do
			idpedidotemporal = row.id
		end
		closeConnection()
	end

	dbManager.insertarEnDetallePedidoTemporal =  function ( idcatalogo, talla, orden, estaencatalogo  ) -- estaencatalogo (0 - no, 1 - si)
		openConnection( )
		local queryInsert = "INSERT INTO detallepedidotemporal (idpedidotemporal, idcatalogo, talla, orden, estaencatalogo) VALUES " .. 
        "((SELECT id FROM pedidotemporal order by id desc limit 1)," .. idcatalogo .. ", " .. talla .. ",'" .. orden .. "','" .. estaencatalogo .. "');"
		print(queryInsert)
		db:exec( queryInsert )
		closeConnection()
	end

	dbManager.editarEnDetallePedidoTemporal = function ( idcatalogo, talla, orden,  estaencatalogo )
		openConnection( )
		local queryInsert = "update detallepedidotemporal set orden = " .. orden .. " where idcatalogo = " .. idcatalogo .. " and talla = " .. talla .. " and estaencatalogo = " .. estaencatalogo .. ";"
		db:exec( queryInsert )
		closeConnection()
	end


	dbManager.comprobarNoInsertadoDetallePedidoTemporal =  function ( idcatalogo, talla, estaencatalogo )
		openConnection( )
		local rowProducto = 0;
		--print("select id, orden from detallepedidotemporal dpt where dpt.idcatalogo = " .. idcatalogo .. " and dpt.talla = " .. talla .. " and estaencatalogo = " .. estaencatalogo .. ";")
		for row in db:nrows("select id, orden from detallepedidotemporal dpt where dpt.idcatalogo = " .. idcatalogo .. " and dpt.talla = " .. talla .. " and estaencatalogo = " .. estaencatalogo .. ";") do
			rowProducto = row 
		end
		closeConnection()
		if rowProducto == 0 then
			print("0")
			return 0
		else
			return rowProducto;
		end
	end

	dbManager.eliminarTemporales = function (  )
		openConnection( )
		local queryInsert = "delete from detallepedidotemporal where id >=1;"
		print("eliminando temporales")
		db:exec( queryInsert )
		queryInsert = "delete from pedidotemporal where id >=1;"
		db:exec( queryInsert )
		closeConnection()
	end

	-- end pedidos --


	dbManager.getIdVendedor = function ( )
		local result = {}
		openConnection( )

		for row in db:nrows("SELECT idVendedor FROM config;") do
            closeConnection( )
            return row.idVendedor
		end

	end

	
	--Setup squema if it doesn't exist
	dbManager.setupSquema = function()
		openConnection( )
		
		local query = "CREATE TABLE IF NOT EXISTS config (id INTEGER PRIMARY KEY, idVendedor INTEGER, nombre TEXT, activo INTEGER);"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS catalogo (id INTEGER PRIMARY KEY, sku TEXT, descripcion TEXT, imagen TEXT, costo REAL, tipo TEXT DEFAULT 'pt', activo INTEGER DEFAULT 1);"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS talla (id INTEGER PRIMARY KEY, nombre TEXT);"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS linea (id INTEGER PRIMARY KEY, nombre TEXT, clave TEXT)"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS sublinea(id INTEGER PRIMARY KEY, nombre TEXT, idlinea INTEGER, clave TEXT, FOREIGN KEY(idlinea) REFERENCES linea(id))"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS color (id INTEGER PRIMARY KEY, nombre TEXT);"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS refcatalogotalla (id INTEGER PRIMARY KEY, idcatalogo INTEGER, idtalla INTEGER, FOREIGN KEY(idtalla) REFERENCES talla(id), FOREIGN KEY(idcatalogo) REFERENCES catalogo(id));"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS refcatalogocolor (id INTEGER PRIMARY KEY, idcatalogo INTEGER, idcolor INTEGER, FOREIGN KEY(idcolor) REFERENCES color(id), FOREIGN KEY(idcatalogo) REFERENCES catalogo(id));"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS cliente (id INTEGER PRIMARY KEY, id_server INTEGER, numero INTEGER, razonsocial TEXT, correo TEXT, telefono TEXT, activo INTEGER);"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS sucursal (id INTEGER PRIMARY KEY, id_server INTEGER, numero INTEGER, nombre TEXT, idcliente INTEGER, activo INTEGER, FOREIGN KEY(idcliente) REFERENCES cliente(id) );"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS refsucursalcatalogo (id INTEGER PRIMARY KEY, idsucursal INTEGER, idcatalogo INTEGER, FOREIGN KEY(idsucursal) REFERENCES sucursal(id), FOREIGN KEY(idcatalogo) REFERENCES catalogo(id));"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS pedido (id INTEGER PRIMARY KEY, folio INTEGER, idsucursal INTEGER, fecha TEXT, total REAL, estado INTEGER, FOREIGN KEY(idsucursal) REFERENCES sucursal(id) );"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS detallepedido (id INTEGER PRIMARY KEY, idpedido INTEGER, idcatalogo INTEGER, talla INTEGER , orden INTEGER, FOREIGN KEY(idpedido) REFERENCES pedido(id), FOREIGN KEY(idcatalogo) REFERENCES catalogo(id), FOREIGN KEY(talla) REFERENCES talla(id) );"
		db:exec( query )

		--[[query = "CREATE TABLE IF NOT EXISTS sucursalpedidotemporal (id INTEGER PRIMARY KEY, idsucursal INTEGER );"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS pedidotemporal (id INTEGER PRIMARY KEY AUTOINCREMENT, folio INTEGER, idsucursal INTEGER, fecha TEXT , estado INTEGER, FOREIGN KEY(idsucursal) REFERENCES sucursal(id) );"
		db:exec( query )

		query = "CREATE TABLE IF NOT EXISTS detallepedidotemporal (id INTEGER PRIMARY KEY AUTOINCREMENT, idpedidotemporal INTEGER, idcatalogo INTEGER, talla INTEGER , orden INTEGER, estaencatalogo INTEGER, FOREIGN KEY(idpedidotemporal) REFERENCES pedidotemporal(id), FOREIGN KEY(idcatalogo) REFERENCES catalogo(id), FOREIGN KEY(talla) REFERENCES talla(id) );"
		db:exec( query )]]

		query = "CREATE TABLE IF NOT EXISTS async_vend (id INTEGER PRIMARY KEY, idvendedor INTEGER, sync INTEGER, nombretabla TEXT);"
		db:exec( query )

        -- Populate tables

        --populate async_vend
        query2 = "INSERT INTO async_vend (id, idvendedor, sync, nombretabla) VALUES " .. 
    	"(1,2,0,'catalogo'),"..
    	"(2,2,0,'cliente'),"..
    	"(3,2,0,'sucursal'),"..
    	"(4,2,0,'pedido');"
    	db:exec( query2 )

        --datos catalogo

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1,'4810101009','PL AD SOL PANAMA BLANCO','CUNPAO02011.jpg','70', '1'),"..
		"(2,'4810101073','PL AD 3 DELFINES BRINCANDO MARINO','9041.jpg','70', '1'),"..
		"(3,'4810101105','PL AD MARGARITAS BLANCO','CUNPAO02011.jpg','70', '1'),"..
		"(4,'4810101382','PL AD PEZ VELA MARINO','4810101382.jpg','70', '1'),"..
		"(5,'4810101459','PL AD GEKO RECTANGULO OLIVO','4810101459.jpg','70', '1'),"..
		"(6,'4810101470','PL AD CHANCLITAS ROSA','4810101470.jpg','70', '1'),"..
		"(7,'4810101485','PL AD 4 IGUANAS PALMERA CHOCOLATE','4810101485.jpg','70', '1'),"..
		"(8,'4810101486','PL AD IGUANA PAISAJE DELFIN','4810101486.jpg','70', '1'),"..
		"(9,'4810101487','PL AD 4 DELFINES BAILANDO OCRE','4810101487.jpg','70', '1'),"..
		"(10,'4810101490','PL AD PALMERA MEXICO PETROLEO','4810101490.jpg','70', '1'),"..
		"(11,'4810101491','PL AD TORTUGA NADANDO BEIGE','4810101491.jpg','70', '1'),"..
		"(12,'4810101492','PL AD 3 GEKOS NEGRO','4810101492.jpg','70', '1'),"..
		"(13,'4810101493','PL AD LETRAS FLORES ROSA','4810101493.jpg','70', '1'),"..
		"(14,'4810101494','PL AD 2 PALMERAS MX MARINO','4810101494.jpg','70', '1'),"..
		"(15,'4810101495','PL AD GEKO HUELLAS LADRILLO','4810101495.jpg','70', '1'),"..
		"(16,'4810102001','PL AD PEZ ESPADA 1967 BLANCO','4810102001.jpg','38', '1'),"..
		"(17,'4810102002','PL AD AUTHENTIC BEACH BLANCO','4810102002.jpg','38', '1'),"..
		"(18,'4810102003','PL AD ORIGINAL APPAREL GOODS BLANCO','4810102003.jpg','38', '1'),"..
		"(19,'4810102004','PL AD DELFIN CUADRO BLANCO','4810102004.jpg','38', '1'),"..
		"(20,'4810102005','PL AD BEACH APPAREL BLANCO','4810102005.jpg','38', '1'),"..
		"(21,'4810102006','PL AD PALMERA TROPICAL BLANCO','4810102006.jpg','38', '1'),"..
		"(22,'4810103001','PL AD SAIL AWAY AZUL CLARO','4810103001.jpg','62', '1'),"..
		"(23,'48101030019','PL AD SAIL AWAY AZUL CLARO','48101030019.jpg','73', '1'),"..
		"(24,'4810103002','PL AD 2 PALMERAS PRIDE NEGRO','4810103002.jpg','62', '1'),"..
		"(25,'48101030029','PL AD 2 PALMERAS PRIDE NEGRO','48101030029.jpg','73', '1'),"..
		"(26,'4810103003','PL AD LIMITED EDITION LADRILLO','4810103003.jpg','62', '1'),"..
		"(27,'48101030039','PL AD LIMITED EDITION LADRILLO','48101030039.jpg','73', '1'),"..
		"(28,'4810103004','PL AD ORIGINAL GECKO NEGRO','4810103004.jpg','62', '1'),"..
		"(29,'48101030049','PL AD ORIGINAL GECKO NEGRO','48101030049.jpg','73', '1'),"..
		"(30,'4810103005','PL AD DESTINO MX OLIVO','4810103005.jpg','62', '1'),"..
		"(31,'48101030059','PL AD DESTINO MX OLIVO','48101030059.jpg','73', '1'),"..
		"(32,'4810103006','PL AD DESTINO LETRAS NEGRO','4810103006.jpg','62', '1'),"..
		"(33,'48101030069','PL AD DESTINO LETRAS NEGRO','48101030069.jpg','73', '1'),"..
		"(34,'4810103007','PL AD GEKOS ESCALANDO NARANJA','4810103007.jpg','62', '1'),"..
		"(35,'48101030079','PL AD GEKOS ESCALANDO NARANJA','48101030079.jpg','73', '1'),"..
		"(36,'4810103008','PL AD GEKOS RECTANGULO LADRILLO','4810103008.jpg','62', '1'),"..
		"(37,'48101030089','PL AD GEKOS RECTANGULO LADRILLO','48101030089.jpg','73', '1'),"..
		"(38,'4810103009','PL AD TORTUGA VERTICAL DELFIN','4810103009.jpg','62', '1'),"..
		"(39,'48101030099','PL AD TORTUGA VERTICAL DELFIN','48101030099.jpg','73', '1'),"..
		"(40,'4810103010','PL AD VELERO OFFSHORE MANGO','4810103010.jpg','62', '1'),"..
		"(41,'48101030109','PL AD VELERO OFFSHORE MANGO','48101030109.jpg','73', '1'),"..
		"(42,'4810103011','PL AD VELERO OFFSHORE GRIS','4810103011.jpg','62', '1'),"..
		"(43,'48101030119','PL AD VELERO OFFSHORE GRIS','48101030119.jpg','73', '1'),"..
		"(44,'4810103012','PL AD COMPAGNIE GENERAL MARINO','4810103012.jpg','62', '1'),"..
		"(45,'48101030129','PL AD COMPAGNIE GENERAL MARINO','48101030129.jpg','73', '1'),"..
		"(46,'4810103013','PL AD PALMERAS PRIDE NARANJA','4810103013.jpg','62', '1'),"..
		"(47,'48101030139','PL AD PALMERAS PRIDE NARANJA','48101030139.jpg','73', '1'),"..
		"(48,'4810103014','PL AD 3 DELFINES CORAL DELFIN','4810103014.jpg','62', '1'),"..
		"(49,'48101030149','PL AD 3 DELFINES CORAL DELFIN','48101030149.jpg','73', '1'),"..
		"(50,'4810103015','PL AD PROPERTI MX OLIVO','4810103015.jpg','62', '1'),"..
		"(51,'48101030159','PL AD PROPERTI MX OLIVO','48101030159.jpg','73', '1'),"..
		"(52,'4810103016','PL AD A¥O CUADRITOS LADRILLO','4810103016.jpg','62', '1'),"..
		"(53,'48101030169','PL AD A¥O CUADRITOS LADRILLO','48101030169.jpg','73', '1'),"..
		"(54,'4810103017','PL AD GEKO SOMBRAS GRIS','4810103017.jpg','62', '1'),"..
		"(55,'48101030179','PL AD GEKO SOMBRAS GRIS','48101030179.jpg','73', '1'),"..
		"(56,'4810103018','PL AD LIMITED EDITION CHOCOLATE','4810103018.jpg','62', '1'),"..
		"(57,'48101030189','PL AD LIMITED EDITION CHOCOLATE','48101030189.jpg','73', '1'),"..
		"(58,'4810103019','PL AD EXPLORE PARADISE MANGO','4810103019.jpg','62', '1'),"..
		"(59,'48101030199','PL AD EXPLORE PARADISE MANGO','48101030199.jpg','73', '1'),"..
		"(60,'4810103020','PL AD ORIGINAL GECKO NEGRO','4810103020.jpg','62', '1'),"..
		"(61,'48101030209','PL AD ORIGINAL GECKO NEGRO','48101030209.jpg','73', '1'),"..
		"(62,'4810103021','PL AD TRADENT MARCK ROSA','4810103021.jpg','62', '1'),"..
		"(63,'48101030219','PL AD TRADENT MARCK ROSA','48101030219.jpg','73', '1'),"..
		"(64,'4810103022','PL AD GAVIOTA 70 OCRE','4810103022.jpg','62', '1'),"..
		"(65,'48101030229','PL AD GAVIOTA 70 OCRE','48101030229.jpg','73', '1'),"..
		"(66,'4810103023','PL AD SELLO FOIL PLATA NEGRO','4810103023.jpg','62', '1'),"..
		"(67,'48101030239','PL AD SELLO FOIL PLATA NEGRO','48101030239.jpg','73', '1'),"..
		"(68,'4810103024','PL AD DESTINO PUNTOS ROJO','4810103024.jpg','62', '1'),"..
		"(69,'48101030249','PL AD DESTINO PUNTOS ROJO','48101030249.jpg','73', '1'),"..
		"(70,'4810103025','PL AD PALMERA PRIDE NEGRO','4810103025.jpg','62', '1'),"..
		"(71,'48101030259','PL AD PALMERA PRIDE NEGRO','48101030259.jpg','73', '1'),"..
		"(72,'4810103026','PL AD IGUANA TRPPICAL LADRILLO','4810103026.jpg','62', '1'),"..
		"(73,'48101030269','PL AD IGUANA TRPPICAL LADRILLO','48101030269.jpg','73', '1'),"..
		"(74,'4810103027','PL AD PALMERA VERTICAL MARINO','4810103027.jpg','62', '1'),"..
		"(75,'48101030279','PL AD PALMERA VERTICAL MARINO','48101030279.jpg','73', '1'),"..
		"(76,'4810103028','PL AD GEKOS ESCALANDO BLANCO','4810103028.jpg','38', '1'),"..
		"(77,'48101030289','PL AD GEKOS ESCALANDO BLANCO','48101030289.jpg','48', '1'),"..
		"(78,'4810103029','PL AD GEKO VERTICAL BLANCO','4810103029.jpg','38', '1'),"..
		"(79,'48101030299','PL AD GEKO VERTICAL BLANCO','48101030299.jpg','48', '1'),"..
		"(80,'4810103030','PL AD DESTINO PESPUNTE BLANCO','4810103030.jpg','38', '1'),"..
		"(81,'48101030309','PL AD DESTINO PESPUNTE BLANCO','48101030309.jpg','48', '1'),"..
		"(82,'4810103031','PL AD DESTINO PUNTOS BLANCO','4810103031.jpg','38', '1'),"..
		"(83,'48101030319','PL AD DESTINO PUNTOS BLANCO','48101030319.jpg','48', '1'),"..
		"(84,'4810103032','PL AD AÑO CUADRITOS BLANCO','4810103032.jpg','38', '1'),"..
		"(85,'48101030329','PL AD AÑO CUADRITOS BLANCO','48101030329.jpg','48', '1'),"..
		"(86,'4810103033','PL AD ESPIRAL BLANCO','4810103033.jpg','38', '1'),"..
		"(87,'48101030339','PL AD ESPIRAL BLANCO','48101030339.jpg','48', '1'),"..
		"(88,'4810103034','PL AD PALMERA RED BLANCO','4810103034.jpg','38', '1'),"..
		"(89,'48101030349','PL AD PALMERA RED BLANCO','48101030349.jpg','48', '1'),"..
		"(90,'4810103035','PL AD IBISCUS EST GRIS','4810103035.jpg','62', '1'),"..
		"(91,'48101030359','PL AD IBISCUS EST GRIS','48101030359.jpg','73', '1'),"..
		"(92,'4810103036','PL AD GAVIOTA MX BLANCO','4810103036.jpg','38', '1'),"..
		"(93,'48101030369','PL AD GAVIOTA MX BLANCO','48101030369.jpg','48', '1'),"..
		"(94,'4810103037','PL AD CHANCLITAS BLANCO','4810103037.jpg','38', '1'),"..
		"(95,'48101030379','PL AD CHANCLITAS BLANCO','48101030379.jpg','48', '1'),"..
		"(96,'4810103038','PL AD GAVIOTA 70 BLANCO','4810103038.jpg','38', '1'),"..
		"(97,'48101030389','PL AD GAVIOTA 70 BLANCO','48101030389.jpg','48', '1'),"..
		"(98,'4810103039','PL AD TRADICIONAL GRIS','4810103039.jpg','62', '1'),"..
		"(99,'48101030399','PL AD TRADICIONAL GRIS','48101030399.jpg','73', '1'),"..
		"(100,'4810103040','PL AD MARLIN CORAL DELFIN','4810103040.jpg','62', '1'),"..
		"(101,'48101030409','PL AD MARLIN CORAL DELFIN','48101030409.jpg','73', '1'),"..
		"(102,'4810103041','PL AD MX NARANJA','4810103041.jpg','62', '1'),"..
		"(103,'48101030419','PL AD MX NARANJA','48101030419.jpg','73', '1'),"..
		"(104,'4810103042','PL AD BEACH APPAREL LADRILLO','4810103042.jpg','62', '1'),"..
		"(105,'48101030429','PL AD BEACH APPAREL LADRILLO','48101030429.jpg','73', '1'),"..
		"(106,'4810103043','PL AD OFF SHORE GRIS','4810103043.jpg','62', '1'),"..
		"(107,'48101030439','PL AD OFF SHORE GRIS','48101030439.jpg','73', '1'),"..
		"(108,'4810103044','PL AD IGUANA SOMBRA OLIVO','4810103044.jpg','62', '1'),"..
		"(109,'4810103045','PL AD DELFIN CUADRO DELFIN','4810103045.jpg','62', '1'),"..
		"(110,'48101030459','PL AD DELFIN CUADRO DELFIN','48101030459.jpg','73', '1'),"..
		"(111,'4810103046','PL AD TROPIACAL RELAX NEGRO','4810103046.jpg','62', '1'),"..
		"(112,'48101030469','PL AD TROPIACAL RELAX NEGRO','48101030469.jpg','73', '1'),"..
		"(113,'4810103047','PL AD PEZ VELA NEGRO','4810103047.jpg','62', '1'),"..
		"(114,'48101030479','PL AD PEZ VELA NEGRO','48101030479.jpg','73', '1'),"..
		"(115,'4810103048','PL AD ORIGINAL APPAREL NEGRO','4810103048.jpg','62', '1'),"..
		"(116,'48101030489','PL AD ORIGINAL APPAREL NEGRO','48101030489.jpg','73', '1'),"..
		"(117,'4810103049','PL AD LETRAS VERTICAL GRIS','4810103049.jpg','62', '1'),"..
		"(118,'48101030499','PL AD LETRAS VERTICAL GRIS','48101030499.jpg','73', '1'),"..
		"(119,'4810103050','PL AD EXPLORE PARADISE MANGO','4810103050.jpg','62', '1'),"..
		"(120,'48101030509','PL AD EXPLORE PARADISE MANGO','48101030509.jpg','73', '1'),"..
		"(121,'4810103051','PL AD SELLO NARANJA','4810103051.jpg','62', '1'),"..
		"(122,'48101030519','PL AD SELLO NARANJA','48101030519.jpg','73', '1'),"..
		"(123,'4810103065','PL AD DESTINO PESPUNTE NEGRO','4810103065.jpg','62', '1'),"..
		"(124,'48101030659','PL AD DESTINO PESPUNTE NEGRO XXL','48101030659.jpg','73', '1'),"..
		"(125,'4810103066','PL AD FIRMA MX GRIS','4810103066.jpg','62', '1'),"..
		"(126,'48101030669','PL AD FIRMA MX XXL GRIS','48101030669.jpg','73', '1'),"..
		"(127,'4810103067','PL AD DESTINO CURVO DELFIN','4810103067.jpg','62', '1'),"..
		"(128,'48101030679','PL AD DESTINO CURVO DELFIN','48101030679.jpg','73', '1'),"..
		"(129,'4810103074','PL AD TORTUGAS BEBES MARINO','4810103074.jpg','62', '1'),"..
		"(130,'48101030749','PL AD TORTUGAS BEBES MARINO','48101030749.jpg','73', '1'),"..
		"(131,'4810103075','PL AD 3 GEKOS SOL OCRE','4810103075.jpg','62', '1'),"..
		"(132,'48101030759','PL AD 3 GEKOS SOL OCRE','48101030759.jpg','73', '1'),"..
		"(133,'4810103076','PL AD GEKO FIGURAS PERTOLEO','4810103076.jpg','62', '1'),"..
		"(134,'48101030769','PL AD GEKO FIGURAS PETROLEO','48101030769.jpg','73', '1'),"..
		"(135,'4810103077','PL AD 3 TORTUGAS NADANDO CHOCOLATE','4810103077.jpg','62', '1'),"..
		"(136,'48101030779','PL AD 3 TORTUGAS NADANDO CHOCOLATE','48101030779.jpg','73', '1'),"..
		"(137,'4810103078','PL AD 2 TORTUGAS PAISAJE CHOCOLATE','4810103078.jpg','62', '1'),"..
		"(138,'48101030789','PL AD 2 TORTUGAS PAISAJE CHOCOLATE','48101030789.jpg','73', '1'),"..
		"(139,'4810103079','PL AD PALMERAS PAISAJE DELFIN','4810103079.jpg','62', '1'),"..
		"(140,'48101030799','PL AD PALMERAS PAISAJE DELFIN','48101030799.jpg','73', '1'),"..
		"(141,'4810103080','PL AD 3 PALMERAS TRIANGULOS OLIVO','4810103080.jpg','62', '1'),"..
		"(142,'48101030809','PL AD 3 PALMERAS TRIANGULOS OLIVO','48101030809.jpg','73', '1'),"..
		"(143,'4810103081','PL AD DELFIN MARCO ROJO','4810103081.jpg','62', '1'),"..
		"(144,'48101030819','PL AD DELFIN MARCO ROJO','48101030819.jpg','73', '1'),"..
		"(145,'4810103082','PL AD 3 GEKOS SOMBRAS NARANJA','4810103082.jpg','62', '1'),"..
		"(146,'48101030829','PL AD 3 GEKOS SOMBRAS NARANJA','48101030829.jpg','73', '1'),"..
		"(147,'4810103083','PL AD 3 GEKOS SOL OLIVO','4810103083.jpg','62', '1'),"..
		"(148,'48101030839','PL AD 3 GEKOS SOL OLIVO','48101030839.jpg','73', '1'),"..
		"(149,'4810103084','PL AD PALMERAS FRANJA ARENA','4810103084.jpg','62', '1'),"..
		"(150,'48101030849','PL AD PALMERAS FRANJA ARENA','48101030849.jpg','73', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(151,'4810103101','PL AD TRANS TORTUGA OLAS MANGO','4810103101.jpg','62', '1'),"..
		"(152,'4810103101E','PL AD TRANS TORTUGA OLAS MANGO','4810103101E.jpg','73', '1'),"..
		"(153,'4810103102','PL AD TRANS 3 GEKOS REALZADO NARANJA','4810103102.jpg','62', '1'),"..
		"(154,'4810103102E','PL AD TRANS 3 GEKOS REALZADO NARANJA','4810103102E.jpg','73', '1'),"..
		"(155,'4810103104','PL AD TRANS 3 PALMERAS NEON NEGRO','4810103104.jpg','62', '1'),"..
		"(156,'4810103104E','PL AD TRANS 3 PALMERAS NEON NEGRO','4810103104E.jpg','73', '1'),"..
		"(157,'4810103106','PL AD TRANS COLEGIAL VERTICAL MARINO','4810103106.jpg','62', '1'),"..
		"(158,'4810103106E','PL AD TRANS COLEGIAL VERTICAL MARINO','4810103106E.jpg','73', '1'),"..
		"(159,'4810103108','PL AD TRANS SELLO TIBURON DELFIN','4810103108.jpg','62', '1'),"..
		"(160,'4810103108E','PL AD TRANS SELLO TIBURON DELFIN','4810103108E.jpg','73', '1'),"..
		"(161,'4810103109','PL AD TRANS MX ATHLETICS LADRILLO','4810103109.jpg','62', '1'),"..
		"(162,'4810103109E','PL AD TRANS MX ATHLETICS LADRILLO','4810103109E.jpg','73', '1'),"..
		"(163,'4810103494','PL AD PALMERAS SELLO MARINO','4810103494.jpg','62', '1'),"..
		"(164,'48101034949','PL AD PALMERAS SELLO MARINO','48101034949.jpg','73', '1'),"..
		"(165,'4810104040','PL AD IGUANA FLOCK MARINO`','4810104040.jpg','65', '1'),"..
		"(166,'4810104041','PL AD GECKO OJON NEGRO','4810104041.jpg','65', '1'),"..
		"(167,'4810104042','PL AD IGUANA GRECAS LADRILLO','4810104042.jpg','65', '1'),"..
		"(168,'4810104043','PL AD IGUANA FOIL BEIGE','4810104043.jpg','65', '1'),"..
		"(169,'4810104044','PL AD TORTUGAS CIRCULO OLIVO','4810104044.jpg','65', '1'),"..
		"(170,'4810104045','PL AD 2 GEKOS FOIL CHOCOLATE','4810104045.jpg','65', '1'),"..
		"(171,'481015102011','PL AD OIL V ESCUDO GUIRNALDAS MARINO','481015102011.jpg','85', '1'),"..
		"(172,'481015102116','PL AD OIL V MX SOMBRAS ROJO','481015102116.jpg','85', '1'),"..
		"(173,'481015102213','PL AD OIL V SELLO VERTICAL NEGRO','481015102213.jpg','85', '1'),"..
		"(174,'4810201073','PL NÑ 3 DELFINES BRINCANDO','4810201073.jpg','61', '1'),"..
		"(175,'4810201411','PL NIÑA MARIPOSAS LIMON','4810201411.jpg','61', '1'),"..
		"(176,'4810201465','PL NIÑA 5 FLORES SMILE ROSA','4810201465.jpg','61', '1'),"..
		"(177,'4810201467','PL NIÑO 2 GEKOS CIRCULO ROJO','4810201467.jpg','61', '1'),"..
		"(178,'4810201470','PL NIÑA CHANCLAS ROSA','4810201470.jpg','61', '1'),"..
		"(179,'4810201480','PL NIÑO IGUANA SURF GRIS','4810201480.jpg','61', '1'),"..
		"(180,'4810201481','PL NIÑO 2 GEKOS OJONES MANGO','4810201481.jpg','61', '1'),"..
		"(181,'4810201482','PL NIÑA TOTORTUGA FLORES AMARILLO','4810201482.jpg','61', '1'),"..
		"(182,'4810203011','PL NIÑO COMPAGINE GENERALE MARINO','4810203011.jpg','55', '1'),"..
		"(183,'4810203012','PL NIÑO DESTINO MX CARBON','4810203012.jpg','55', '1'),"..
		"(184,'4810203014','PL NIÑO 2 PALMERAS PRIDE NARANJA','4810203014.jpg','55', '1'),"..
		"(185,'4810203016','PL NIÑO GEKO SOMBRA GRIS','4810203016.jpg','55', '1'),"..
		"(186,'4810203039','PL NIÑO DESTINO PUNTOS ROJO','4810203039.jpg','55', '1'),"..
		"(187,'4810203041','PL NIÑO AUTENTIC WEAR LIMON','4810203041.jpg','55', '1'),"..
		"(188,'4810203042','PL NIÑO MX NARANJA','4810203042.jpg','55', '1'),"..
		"(189,'4810203043','PL NIÑO WIND SURFISTA LADRILLO','4810203043.jpg','55', '1'),"..
		"(190,'4810203044','PL NIÑ0 LOVE PESPUNTE ROSA','4810203044.jpg','55', '1'),"..
		"(191,'4810203046','PL NIÑO DESTINO MORADO','4810203046.jpg','55', '1'),"..
		"(192,'4810203047','PL NIÑO DESTINO NEGRO','4810203047.jpg','55', '1'),"..
		"(193,'4810203048','PL NIÑO IBISCUS EST ROSA','4810203048.jpg','55', '1'),"..
		"(194,'4810203049','PL NIÑO CHANCLITAS BLANCO','4810203049.jpg','55', '1'),"..
		"(195,'4810203050','PL NIÑO IBISCUS FOIL MORADO','4810203050.jpg','55', '1'),"..
		"(196,'4810203051','PL NIÑO IBISCUS FOIL NEGRO','4810203051.jpg','55', '1'),"..
		"(197,'4810203052','PL NIÑO LOVE PESPUNTE AMARILLO','4810203052.jpg','55', '1'),"..
		"(198,'4810203088','PL NIÑO 2 TORTUGAS PAISAJE LIMON','4810203088.jpg','55', '1'),"..
		"(199,'4810203089','PL NIÑO PALMERAS PAISAJE CHOCOLATE','4810203089.jpg','55', '1'),"..
		"(200,'4810203090','PL NIÑO DELFIN MARCO CARBON','4810203090.jpg','55', '1'),"..
		"(201,'4810203091','PL NIÑO 3 GEKOS SOMBRAS LIMON','4810203091.jpg','55', '1'),"..
		"(202,'4810203092','PL NIÑO 3 PALMERAS TRIANGULOS CARBON','4810203092.jpg','55', '1'),"..
		"(203,'4810203093','PL NIÑO 2 TORTUGAS PAISAJE DELFIN','4810203093.jpg','55', '1'),"..
		"(204,'4810203094','PL NIÑO GEKO RETRO CARBON','4810203094.jpg','55', '1'),"..
		"(205,'4810203095','PL NIÑO 3 TORTUGAS NADANDO MARINO','4810203095.jpg','55', '1'),"..
		"(206,'4810203096','PL NIÑO TORTUGAS BEBES MANGO','4810203096.jpg','55', '1'),"..
		"(207,'4810203097','PL NIÑO PALMERAS FRANJA NARANJA','4810203097.jpg','55', '1'),"..
		"(208,'4810204051','PL NIÑO 4 TORTUGAS MANGO','4810204051.jpg','59', '1'),"..
		"(209,'4810204052','PL NIÑO TIBURON SOMBRAS ROJO','4810204052.jpg','59', '1'),"..
		"(210,'4810204053','PL NINO 3 TORTUGAS NADANDO LIMON','4810204053.jpg','59', '1'),"..
		"(211,'4810204054','PL NIÑO GEKO PATON GRIS','4810204054.jpg','59', '1'),"..
		"(212,'4810204055','PL NIÑO GEKO DOBLE CIRCULO NARANJA','4810204055.jpg','59', '1'),"..
		"(213,'4810204056','PL NIÑO PLAY HOOKY ROYAL','4810204056.jpg','59', '1'),"..
		"(214,'4810206001','PL NIÑO PRINCESS ROSA','4810206001.jpg','55', '1'),"..
		"(215,'4810206002','PL NIÑO DELFIN MARINO','4810206002.jpg','55', '1'),"..
		"(216,'4810206003','PL NIÑO MARIPOSA ROSA','4810206003.jpg','55', '1'),"..
		"(217,'4810303019','PL DAM PALMERAS ROSA','4810303019.jpg','62', '1'),"..
		"(218,'4810303020','PL DAM PEACE & LOVE FIUSHA','4810303020.jpg','62', '1'),"..
		"(219,'4810303021','PL DAM CORAZON PEACE & LOVE MARINO','4810303021.jpg','62', '1'),"..
		"(220,'4810303054','PL DAM PLAMERAS EST CHOCOLATE','4810303054.jpg','62', '1'),"..
		"(221,'4810303055','PL DAM IBISCUS EST MARINO','4810303055.jpg','62', '1'),"..
		"(222,'4810303056','PL DAM PARADISE MX ROSA','4810303056.jpg','62', '1'),"..
		"(223,'4810303057','PL DAM TORTUGA FLORES CHOCOLATE','4810303057.jpg','62', '1'),"..
		"(224,'4810303058','PL DAM LOVE PESPUNTE FIUSHA','4810303058.jpg','62', '1'),"..
		"(225,'4810303060','PL DAM PARADISE MX MARINO','4810303060.jpg','62', '1'),"..
		"(226,'4810303061','PL DAM IBISCUS FIOL ROSA','4810303061.jpg','62', '1'),"..
		"(227,'4810303062','PL DAM A 3 PALMERAS TRADEN MARK AMARILLO','4810303062.jpg','62', '1'),"..
		"(228,'4810303063','PL DAM PALMERA LUNA NEGRO','4810303063.jpg','62', '1'),"..
		"(229,'4810303064','PL DAM PALMERA SOL NEGRO','4810303064.jpg','62', '1'),"..
		"(230,'4810303068','PL DAM CORAZON MARGARITAS NEGRO','4810303068.jpg','62', '1'),"..
		"(231,'4810303069','PL DAM PICE & LOVE COLORES BLANCO','4810303069.jpg','62', '1'),"..
		"(232,'4810303085','PL DAM COOL RULE ROSA','4810303085.jpg','62', '1'),"..
		"(233,'4810303086','PL DAM ADICTED LOVE AMARILLO','4810303086.jpg','62', '1'),"..
		"(234,'4810303098','PL DAM LOVE ROSA','4810303098.jpg','62', '1'),"..
		"(235,'4810303101','PL DA TRANS CORAZON MOSAICO BLANCO','4810303101.jpg','62', '1'),"..
		"(236,'4810303102','PL DA TRANS CORAZON MOSAICO FIUSHA','4810303102.jpg','62', '1'),"..
		"(237,'4810303106','PL DA TRANS 3 PALMERAS VERTICAL LIMA','4810303106.jpg','62', '1'),"..
		"(238,'4810303107','PL DA TRANS IBISCUS VERTICAL MARINO','4810303107.jpg','62', '1'),"..
		"(239,'481030330003','PLAYERA SIN MANGA FIRMA ATHLETIC','481030330003.jpg','38', '1'),"..
		"(240,'4810303300XXL03','PLAYERA SIN MANGA FIRMA ATHLETIC','4810303300XXL03.jpg','48', '1'),"..
		"(241,'481030330109','PLAYERA SIN MANGA AUTHENTIC BRAND','481030330109.jpg','62', '1'),"..
		"(242,'4810303301XXL09','PLAYERA SIN MANGA AUTHENTIC BRAND','4810303301XXL09.jpg','73', '1'),"..
		"(243,'481030330211','PLAYERA SIN MANGA TORTUGAS RECTANGULO','481030330211.jpg','62', '1'),"..
		"(244,'4810303302XXL11','PLAYERA SIN MANGA TORTUGAS RECTANGULO','4810303302XXL11.jpg','73', '1'),"..
		"(245,'481030330316','PLAYERA SIN MANGA CIRCULO MEX','481030330316.jpg','62', '1'),"..
		"(246,'4810303303XXL16','PLAYERA SIN MANGA CIRCULO MEX','4810303303XXL16.jpg','73', '1'),"..
		"(247,'481030330413','PLAYERA SIN MANGA IGUANA NEON','481030330413.jpg','62', '1'),"..
		"(248,'4810303304XXL13','PLAYERA SIN MANGA IGUANA NEON','4810303304XXL13.jpg','73', '1'),"..
		"(249,'4810307022','PL DAM PIEDRITAS NEGRO','4810307022.jpg','62', '1'),"..
		"(250,'4810307023','PL DAM PIEDRITAS BLANCO','4810307023.jpg','62', '1'),"..
		"(251,'4810307024','PL DAM PIEDRITAS FIUSHA','4810307024.jpg','62', '1'),"..
		"(252,'4810307025','PL DAM PIEDRITAS MORADO','4810307025.jpg','62', '1'),"..
		"(253,'481035102378','PL DA OIL V 3 CORAZONES SINCE AQUA','481035102378.jpg','85', '1'),"..
		"(254,'481035102429','PL DA OIL V FLORES 70 ROSA','481035102429.jpg','85', '1'),"..
		"(255,'481035102504','PL DA OIL V LOVE PARCHE CELESTE','481035102504.jpg','85', '1'),"..
		"(256,'4810601001','SUDADERA ADULTO CAPUCHA GRIS','4810601001.jpg','170', '1'),"..
		"(257,'4810601002','SUDADERA ADULTO CAPUCHA MARINO','4810601002.jpg','170', '1'),"..
		"(258,'4810601003','SUDADERA ADULTO CAPUCHA FIUSHA','4810601003.jpg','170', '1'),"..
		"(259,'4810601004','SUDADERA ADULTO CAPUCHA TURQUESA','4810601004.jpg','170', '1'),"..
		"(260,'4810601005','SUDADERA ADULTO CAPUCHA LILA','4810601005.jpg','170', '1'),"..
		"(261,'4810601006','SUDADERA ADULTO CAPUCHA NEGRO','4810601006.jpg','170', '1'),"..
		"(262,'4810601007','SUDADERA ADULTO CAPUCHA LIMON','4810601007.jpg','170', '1'),"..
		"(263,'4810703001','PL AD SM BEACH APPAREL GRIS','4810703001.jpg','62', '1'),"..
		"(264,'48107030019','PL AD SM BEACH APPAREL','48107030019.jpg','73', '1'),"..
		"(265,'4810703002','PL AD SM DELFIN CUADRO MARINO','4810703002.jpg','62', '1'),"..
		"(266,'48107030029','PL AD SM DELFIN CUADRO MARINO','48107030029.jpg','73', '1'),"..
		"(267,'4810703003','PL AD SM GAVIOTA SINCE BLANCO','4810703003.jpg','38', '1'),"..
		"(268,'48107030039','PL AD SM GAVIOTA SINCE BLANCO','48107030039.jpg','48', '1'),"..
		"(269,'4810703004','PL AD SM AUTHENTIC BRAND 74 ROJO','4810703004.jpg','62', '1'),"..
		"(270,'48107030049','PL AD SM AUTHENTIC BRAND 74 ROJO','48107030049.jpg','73', '1'),"..
		"(271,'4810907022','PL DAM TANK PIEDRITAS BLANCO','4810907022.jpg','75', '1'),"..
		"(272,'4810907023','PL DAM TANK PIEDRA NEGRO','4810907023.jpg','75', '1'),"..
		"(273,'4810907024','PL DAM TANK PIEDRA FIUSHA','4810907024.jpg','62', '1'),"..
		"(274,'4810907025','PL DAM TANK PIEDRA TURQUESA','4810907025.jpg','62', '1'),"..
		"(275,'4811003053','PL BB TORTUGA AMARILLO','4811003053.jpg','50', '1'),"..
		"(276,'48110060170','PL BB TORTUGAS ROSA','48110060170.jpg','50', '1'),"..
		"(277,'4811006018','PL BB PECES CELESTE','4811006018.jpg','50', '1'),"..
		"(278,'4811006054','PL BB DELFIN CELESTE','4811006054.jpg','50', '1'),"..
		"(279,'4811006055','PL BB PEZ ROSA','4811006055.jpg','50', '1'),"..
		"(280,'481116500111','GORRA RAUL','481116500111.jpg','76', '1'),"..
		"(281,'481116500113','GORRA RAUL','481116500113.jpg','76', '1'),"..
		"(282,'481116500128','GORRA RAUL','481116500128.jpg','76', '1'),"..
		"(283,'481116500130','GORRA RAUL','481116500130.jpg','76', '1'),"..
		"(284,'481116500166','GORRA RAUL','481116500166.jpg','76', '1'),"..
		"(285,'481116600102','GORRA OXFORD','481116600102.jpg','68', '1'),"..
		"(286,'481116600111','GORRA OXFORD','481116600111.jpg','68', '1'),"..
		"(287,'481116600113','GORRA OXFORD','481116600113.jpg','68', '1'),"..
		"(288,'481116600128','GORRA OXFORD','481116600128.jpg','68', '1'),"..
		"(289,'481116600130','GORRA OXFORD','481116600130.jpg','68', '1'),"..
		"(290,'481116600131','GORRA OXFORD','481116600131.jpg','68', '1'),"..
		"(291,'481116600137','GORRA OXFORD','481116600137.jpg','68', '1'),"..
		"(292,'481116700102','GORRA PESPUNTE','481116700102.jpg','68', '1'),"..
		"(293,'481116700111','GORRA PESPUNTE','481116700111.jpg','68', '1'),"..
		"(294,'481116700113','GORRA PESPUNTE','481116700113.jpg','68', '1'),"..
		"(295,'481116700128','GORRA PESPUNTE','481116700128.jpg','68', '1'),"..
		"(296,'481116700131','GORRA PESPUNTE','481116700131.jpg','68', '1'),"..
		"(297,'481116900503','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900503.jpg','73', '1'),"..
		"(298,'481116900510','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900510.jpg','73', '1'),"..
		"(299,'481116900511','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900511.jpg','73', '1'),"..
		"(300,'481116900512','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900512.jpg','73', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(301,'481116900513','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900513.jpg','73', '1'),"..
		"(302,'481116900526','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900526.jpg','73', '1'),"..
		"(303,'481116900528','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900528.jpg','73', '1'),"..
		"(304,'481116900530','SOMBRERO GUILLIGAN LOGO SECRETS CAPRI','481116900530.jpg','73', '1'),"..
		"(305,'481117800117','GORRA FIDEL','481117800117.jpg','76', '1'),"..
		"(306,'481117800129','GORRA FIDEL','481117800129.jpg','76', '1'),"..
		"(307,'481117800130','GORRA FIDEL','481117800130.jpg','76', '1'),"..
		"(308,'481117800137','GORRA FIDEL','481117800137.jpg','76', '1'),"..
		"(309,'481117800140','GORRA FIDEL','481117800140.jpg','76', '1'),"..
		"(310,'481117800166','GORRA FIDEL','481117800166.jpg','76', '1'),"..
		"(311,'481117900104','GORRA ARCOIRIS','481117900104.jpg','68', '1'),"..
		"(312,'481117900118','GORRA ARCOIRIS','481117900118.jpg','68', '1'),"..
		"(313,'481117900129','GORRA ARCOIRIS','481117900129.jpg','68', '1'),"..
		"(314,'481117900138','GORRA ARCOIRIS','481117900138.jpg','68', '1'),"..
		"(315,'481118000113','GORRA CAMBAS','481118000113.jpg','68', '1'),"..
		"(316,'481118000126','GORRA CAMBAS','481118000126.jpg','68', '1'),"..
		"(317,'481118000132','GORRA CAMBAS','481118000132.jpg','68', '1'),"..
		"(318,'481118100102','GORRA DESLAVADA NI¥O','481118100102.jpg','63', '1'),"..
		"(319,'481118100110','GORRA DESLAVADA NI¥O','481118100110.jpg','63', '1'),"..
		"(320,'481118100111','GORRA DESLAVADA NI¥O','481118100111.jpg','63', '1'),"..
		"(321,'481118100112','GORRA DESLAVADA NI¥O','481118100112.jpg','63', '1'),"..
		"(322,'481118100115','GORRA DESLAVADA NI¥O','481118100115.jpg','63', '1'),"..
		"(323,'481118100126','GORRA DESLAVADA NI¥O','481118100126.jpg','63', '1'),"..
		"(324,'481118200104','GORRA DAMA','481118200104.jpg','63', '1'),"..
		"(325,'481118200112','GORRA DAMA','481118200112.jpg','63', '1'),"..
		"(326,'481118200118','GORRA DAMA','481118200118.jpg','63', '1'),"..
		"(327,'481118200119','GORRA DAMA','481118200119.jpg','63', '1'),"..
		"(328,'481118200123','GORRA DAMA','481118200123.jpg','63', '1'),"..
		"(329,'481118200129','GORRA DAMA','481118200129.jpg','63', '1'),"..
		"(330,'481118200140','GORRA DAMA','481118200140.jpg','63', '1'),"..
		"(331,'481118200141','GORRA DAMA','481118200141.jpg','63', '1'),"..
		"(332,'481118200142','GORRA DAMA','481118200142.jpg','63', '1'),"..
		"(333,'481118300105','GORRA SANDWICH','481118300105.jpg','68', '1'),"..
		"(334,'481118300111','GORRA SANDWICH','481118300111.jpg','68', '1'),"..
		"(335,'481118300113','GORRA SANDWICH','481118300113.jpg','68', '1'),"..
		"(336,'481118300120','GORRA SANDWICH','481118300120.jpg','68', '1'),"..
		"(337,'481118300122','GORRA SANDWICH','481118300122.jpg','68', '1'),"..
		"(338,'481118300133','GORRA SANDWICH','481118300133.jpg','68', '1'),"..
		"(339,'481118300136','GORRA SANDWICH','481118300136.jpg','68', '1'),"..
		"(340,'481118300139','GORRA SANDWICH','481118300139.jpg','68', '1'),"..
		"(341,'481118300143','GORRA SANDWICH','481118300143.jpg','68', '1'),"..
		"(342,'481118300145','GORRA SANDWICH','481118300145.jpg','68', '1'),"..
		"(343,'481118300147','GORRA SANDWICH','481118300147.jpg','68', '1'),"..
		"(344,'481118300149','GORRA SANDWICH','481118300149.jpg','68', '1'),"..
		"(345,'481118300205','GORRA SANDWICH RIU CUN','481118300205.jpg','68', '1'),"..
		"(346,'481118300211','GORRA SANDWICH RIU CUN','481118300211.jpg','68', '1'),"..
		"(347,'481118300213','GORRA SANDWICH RIU CUN','481118300213.jpg','68', '1'),"..
		"(348,'481118300220','GORRA SANDWICH RIU CUN','481118300220.jpg','68', '1'),"..
		"(349,'481118300222','GORRA SANDWICH RIU CUN','481118300222.jpg','68', '1'),"..
		"(350,'481118300233','GORRA SANDWICH RIU CUN','481118300233.jpg','68', '1'),"..
		"(351,'481118300236','GORRA SANDWICH RIU CUN','481118300236.jpg','68', '1'),"..
		"(352,'481118300239','GORRA SANDWICH RIU CUN','481118300239.jpg','68', '1'),"..
		"(353,'481118300243','GORRA SANDWICH RIU CUN','481118300243.jpg','68', '1'),"..
		"(354,'481118300245','GORRA SANDWICH RIU CUN','481118300245.jpg','68', '1'),"..
		"(355,'481118300247','GORRA SANDWICH RIU CUN','481118300247.jpg','68', '1'),"..
		"(356,'481118300249','GORRA SANDWICH RIU CUN','481118300249.jpg','68', '1'),"..
		"(357,'481118500102','GORRA DESLAVADA','481118500102.jpg','63', '1'),"..
		"(358,'481118500103','GORRA DESLAVADA','481118500103.jpg','63', '1'),"..
		"(359,'481118500105','GORRA DESLAVADA','481118500105.jpg','63', '1'),"..
		"(360,'481118500106','GORRA DESLAVADA','481118500106.jpg','63', '1'),"..
		"(361,'481118500109','GORRA DESLAVADA','481118500109.jpg','63', '1'),"..
		"(362,'481118500110','GORRA DESLAVADA','481118500110.jpg','63', '1'),"..
		"(363,'481118500111','GORRA DESLAVADA','481118500111.jpg','63', '1'),"..
		"(364,'481118500112','GORRA DESLAVADA','481118500112.jpg','63', '1'),"..
		"(365,'481118500113','GORRA DESLAVADA','481118500113.jpg','63', '1'),"..
		"(366,'481118500114','GORRA DESLAVADA','481118500114.jpg','63', '1'),"..
		"(367,'481118500115','GORRA DESLAVADA','481118500115.jpg','63', '1'),"..
		"(368,'481118500116','GORRA DESLAVADA','481118500116.jpg','63', '1'),"..
		"(369,'481118500121','GORRA DESLAVADA','481118500121.jpg','63', '1'),"..
		"(370,'481118500125','GORRA DESLAVADA','481118500125.jpg','63', '1'),"..
		"(371,'481118500126','GORRA DESLAVADA','481118500126.jpg','63', '1'),"..
		"(372,'481118500128','GORRA DESLAVADA','481118500128.jpg','63', '1'),"..
		"(373,'481118500129','GORRA DESLAVADA','481118500129.jpg','63', '1'),"..
		"(374,'481118500130','GORRA DESLAVADA','481118500130.jpg','63', '1'),"..
		"(375,'481118500131','GORRA DESLAVADA','481118500131.jpg','63', '1'),"..
		"(376,'481118500132','GORRA DESLAVADA','481118500132.jpg','63', '1'),"..
		"(377,'481118500134','GORRA DESLAVADA','481118500134.jpg','63', '1'),"..
		"(378,'481118500135','GORRA DESLAVADA','481118500135.jpg','63', '1'),"..
		"(379,'481118500137','GORRA DESLAVADA','481118500137.jpg','63', '1'),"..
		"(380,'481118500138','GORRA DESLAVADA','481118500138.jpg','63', '1'),"..
		"(381,'481118500202','GORRA DESLAVADA RIU CUN','481118500202.jpg','63', '1'),"..
		"(382,'481118500203','GORRA DESLAVADA RIU CUN','481118500203.jpg','63', '1'),"..
		"(383,'481118500205','GORRA DESLAVADA RIU CUN','481118500205.jpg','63', '1'),"..
		"(384,'481118500206','GORRA DESLAVADA RIU CUN','481118500206.jpg','63', '1'),"..
		"(385,'481118500209','GORRA DESLAVADA RIU CUN','481118500209.jpg','63', '1'),"..
		"(386,'481118500210','GORRA DESLAVADA RIU CUN','481118500210.jpg','63', '1'),"..
		"(387,'481118500211','GORRA DESLAVADA RIU CUN','481118500211.jpg','63', '1'),"..
		"(388,'481118500212','GORRA DESLAVADA RIU CUN','481118500212.jpg','63', '1'),"..
		"(389,'481118500213','GORRA DESLAVADA RIU CUN','481118500213.jpg','63', '1'),"..
		"(390,'481118500214','GORRA DESLAVADA RIU CUN','481118500214.jpg','63', '1'),"..
		"(391,'481118500215','GORRA DESLAVADA RIU CUN','481118500215.jpg','63', '1'),"..
		"(392,'481118500216','GORRA DESLAVADA RIU CUN','481118500216.jpg','63', '1'),"..
		"(393,'481118500221','GORRA DESLAVADA RIU CUN','481118500221.jpg','63', '1'),"..
		"(394,'481118500225','GORRA DESLAVADA RIU CUN','481118500225.jpg','63', '1'),"..
		"(395,'481118500226','GORRA DESLAVADA RIU CUN','481118500226.jpg','63', '1'),"..
		"(396,'481118500228','GORRA DESLAVADA RIU CUN','481118500228.jpg','63', '1'),"..
		"(397,'481118500229','GORRA DESLAVADA RIU CUN','481118500229.jpg','63', '1'),"..
		"(398,'481118500230','GORRA DESLAVADA RIU CUN','481118500230.jpg','63', '1'),"..
		"(399,'481118500231','GORRA DESLAVADA RIU CUN','481118500231.jpg','63', '1'),"..
		"(400,'481118500232','GORRA DESLAVADA RIU CUN','481118500232.jpg','63', '1'),"..
		"(401,'481118500234','GORRA DESLAVADA RIU CUN','481118500234.jpg','63', '1'),"..
		"(402,'481118500235','GORRA DESLAVADA RIU CUN','481118500235.jpg','63', '1'),"..
		"(403,'481118500237','GORRA DESLAVADA RIU CUN','481118500237.jpg','63', '1'),"..
		"(404,'481118500238','GORRA DESLAVADA RIU CUN','481118500238.jpg','63', '1'),"..
		"(405,'481118500302','GORRA DESLAVADA LOGO DREAMS','481118500302.jpg','63', '1'),"..
		"(406,'481118500303','GORRA DESLAVADA LOGO DREAMS','481118500303.jpg','63', '1'),"..
		"(407,'481118500305','GORRA DESLAVADA LOGO DREAMS','481118500305.jpg','63', '1'),"..
		"(408,'481118500306','GORRA DESLAVADA LOGO DREAMS','481118500306.jpg','63', '1'),"..
		"(409,'481118500309','GORRA DESLAVADA LOGO DREAMS','481118500309.jpg','63', '1'),"..
		"(410,'481118500310','GORRA DESLAVADA LOGO DREAMS','481118500310.jpg','63', '1'),"..
		"(411,'481118500311','GORRA DESLAVADA LOGO DREAMS','481118500311.jpg','63', '1'),"..
		"(412,'481118500312','GORRA DESLAVADA LOGO DREAMS','481118500312.jpg','63', '1'),"..
		"(413,'481118500313','GORRA DESLAVADA LOGO DREAMS','481118500313.jpg','63', '1'),"..
		"(414,'481118500314','GORRA DESLAVADA LOGO DREAMS','481118500314.jpg','63', '1'),"..
		"(415,'481118500315','GORRA DESLAVADA LOGO DREAMS','481118500315.jpg','63', '1'),"..
		"(416,'481118500316','GORRA DESLAVADA LOGO DREAMS','481118500316.jpg','63', '1'),"..
		"(417,'481118500321','GORRA DESLAVADA LOGO DREAMS','481118500321.jpg','63', '1'),"..
		"(418,'481118500325','GORRA DESLAVADA LOGO DREAMS','481118500325.jpg','63', '1'),"..
		"(419,'481118500326','GORRA DESLAVADA LOGO DREAMS','481118500326.jpg','63', '1'),"..
		"(420,'481118500328','GORRA DESLAVADA LOGO DREAMS','481118500328.jpg','63', '1'),"..
		"(421,'481118500329','GORRA DESLAVADA LOGO DREAMS','481118500329.jpg','63', '1'),"..
		"(422,'481118500330','GORRA DESLAVADA LOGO DREAMS','481118500330.jpg','63', '1'),"..
		"(423,'481118500331','GORRA DESLAVADA LOGO DREAMS','481118500331.jpg','63', '1'),"..
		"(424,'481118500332','GORRA DESLAVADA LOGO DREAMS','481118500332.jpg','63', '1'),"..
		"(425,'481118500334','GORRA DESLAVADA LOGO DREAMS','481118500334.jpg','63', '1'),"..
		"(426,'481118500335','GORRA DESLAVADA LOGO DREAMS','481118500335.jpg','63', '1'),"..
		"(427,'481118500337','GORRA DESLAVADA LOGO DREAMS','481118500337.jpg','63', '1'),"..
		"(428,'481118500338','GORRA DESLAVADA LOGO DREAMS','481118500338.jpg','63', '1'),"..
		"(429,'481118500402','GORRA DESLAVADA LOGO DREAMS TULUM','481118500402.jpg','63', '1'),"..
		"(430,'481118500403','GORRA DESLAVADA LOGO DREAMS TULUM','481118500403.jpg','63', '1'),"..
		"(431,'481118500405','GORRA DESLAVADA LOGO DREAMS TULUM','481118500405.jpg','63', '1'),"..
		"(432,'481118500406','GORRA DESLAVADA LOGO DREAMS TULUM','481118500406.jpg','63', '1'),"..
		"(433,'481118500409','GORRA DESLAVADA LOGO DREAMS TULUM','481118500409.jpg','63', '1'),"..
		"(434,'481118500410','GORRA DESLAVADA LOGO DREAMS TULUM','481118500410.jpg','63', '1'),"..
		"(435,'481118500411','GORRA DESLAVADA LOGO DREAMS TULUM','481118500411.jpg','63', '1'),"..
		"(436,'481118500412','GORRA DESLAVADA LOGO DREAMS TULUM','481118500412.jpg','63', '1'),"..
		"(437,'481118500413','GORRA DESLAVADA LOGO DREAMS TULUM','481118500413.jpg','63', '1'),"..
		"(438,'481118500414','GORRA DESLAVADA LOGO DREAMS TULUM','481118500414.jpg','63', '1'),"..
		"(439,'481118500415','GORRA DESLAVADA LOGO DREAMS TULUM','481118500415.jpg','63', '1'),"..
		"(440,'481118500416','GORRA DESLAVADA LOGO DREAMS TULUM','481118500416.jpg','63', '1'),"..
		"(441,'481118500421','GORRA DESLAVADA LOGO DREAMS TULUM','481118500421.jpg','63', '1'),"..
		"(442,'481118500425','GORRA DESLAVADA LOGO DREAMS TULUM','481118500425.jpg','63', '1'),"..
		"(443,'481118500426','GORRA DESLAVADA LOGO DREAMS TULUM','481118500426.jpg','63', '1'),"..
		"(444,'481118500428','GORRA DESLAVADA LOGO DREAMS TULUM','481118500428.jpg','63', '1'),"..
		"(445,'481118500429','GORRA DESLAVADA LOGO DREAMS TULUM','481118500429.jpg','63', '1'),"..
		"(446,'481118500430','GORRA DESLAVADA LOGO DREAMS TULUM','481118500430.jpg','63', '1'),"..
		"(447,'481118500431','GORRA DESLAVADA LOGO DREAMS TULUM','481118500431.jpg','63', '1'),"..
		"(448,'481118500432','GORRA DESLAVADA LOGO DREAMS TULUM','481118500432.jpg','63', '1'),"..
		"(449,'481118500434','GORRA DESLAVADA LOGO DREAMS TULUM','481118500434.jpg','63', '1'),"..
		"(450,'481118500435','GORRA DESLAVADA LOGO DREAMS TULUM','481118500435.jpg','63', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(451,'481118500437','GORRA DESLAVADA LOGO DREAMS TULUM','481118500437.jpg','63', '1'),"..
		"(452,'481118500438','GORRA DESLAVADA LOGO DREAMS TULUM','481118500438.jpg','63', '1'),"..
		"(453,'481118500502','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500502.jpg','63', '1'),"..
		"(454,'481118500503','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500503.jpg','63', '1'),"..
		"(455,'481118500505','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500505.jpg','63', '1'),"..
		"(456,'481118500506','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500506.jpg','63', '1'),"..
		"(457,'481118500509','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500509.jpg','63', '1'),"..
		"(458,'481118500510','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500510.jpg','63', '1'),"..
		"(459,'481118500511','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500511.jpg','63', '1'),"..
		"(460,'481118500512','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500512.jpg','63', '1'),"..
		"(461,'481118500513','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500513.jpg','63', '1'),"..
		"(462,'481118500514','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500514.jpg','63', '1'),"..
		"(463,'481118500515','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500515.jpg','63', '1'),"..
		"(464,'481118500516','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500516.jpg','63', '1'),"..
		"(465,'481118500521','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500521.jpg','63', '1'),"..
		"(466,'481118500525','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500525.jpg','63', '1'),"..
		"(467,'481118500526','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500526.jpg','63', '1'),"..
		"(468,'481118500528','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500528.jpg','63', '1'),"..
		"(469,'481118500529','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500529.jpg','63', '1'),"..
		"(470,'481118500530','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500530.jpg','63', '1'),"..
		"(471,'481118500531','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500531.jpg','63', '1'),"..
		"(472,'481118500532','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500532.jpg','63', '1'),"..
		"(473,'481118500534','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500534.jpg','63', '1'),"..
		"(474,'481118500535','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500535.jpg','63', '1'),"..
		"(475,'481118500537','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500537.jpg','63', '1'),"..
		"(476,'481118500538','GORRA DESLAVADA LOGO SECRETS CAPRI','481118500538.jpg','63', '1'),"..
		"(477,'481118500602','GORRA DESLAVADA LOGO HYATT','481118500602.jpg','63', '1'),"..
		"(478,'481118500603','GORRA DESLAVADA LOGO HYATT','481118500603.jpg','63', '1'),"..
		"(479,'481118500605','GORRA DESLAVADA LOGO HYATT','481118500605.jpg','63', '1'),"..
		"(480,'481118500606','GORRA DESLAVADA LOGO HYATT','481118500606.jpg','63', '1'),"..
		"(481,'481118500609','GORRA DESLAVADA LOGO HYATT','481118500609.jpg','63', '1'),"..
		"(482,'481118500610','GORRA DESLAVADA LOGO HYATT','481118500610.jpg','63', '1'),"..
		"(483,'481118500611','GORRA DESLAVADA LOGO HYATT','481118500611.jpg','63', '1'),"..
		"(484,'481118500612','GORRA DESLAVADA LOGO HYATT','481118500612.jpg','63', '1'),"..
		"(485,'481118500613','GORRA DESLAVADA LOGO HYATT','481118500613.jpg','63', '1'),"..
		"(486,'481118500614','GORRA DESLAVADA LOGO HYATT','481118500614.jpg','63', '1'),"..
		"(487,'481118500615','GORRA DESLAVADA LOGO HYATT','481118500615.jpg','63', '1'),"..
		"(488,'481118500616','GORRA DESLAVADA LOGO HYATT','481118500616.jpg','63', '1'),"..
		"(489,'481118500621','GORRA DESLAVADA LOGO HYATT','481118500621.jpg','63', '1'),"..
		"(490,'481118500625','GORRA DESLAVADA LOGO HYATT','481118500625.jpg','63', '1'),"..
		"(491,'481118500626','GORRA DESLAVADA LOGO HYATT','481118500626.jpg','63', '1'),"..
		"(492,'481118500628','GORRA DESLAVADA LOGO HYATT','481118500628.jpg','63', '1'),"..
		"(493,'481118500629','GORRA DESLAVADA LOGO HYATT','481118500629.jpg','63', '1'),"..
		"(494,'481118500630','GORRA DESLAVADA LOGO HYATT','481118500630.jpg','63', '1'),"..
		"(495,'481118500631','GORRA DESLAVADA LOGO HYATT','481118500631.jpg','63', '1'),"..
		"(496,'481118500632','GORRA DESLAVADA LOGO HYATT','481118500632.jpg','63', '1'),"..
		"(497,'481118500634','GORRA DESLAVADA LOGO HYATT','481118500634.jpg','63', '1'),"..
		"(498,'481118500635','GORRA DESLAVADA LOGO HYATT','481118500635.jpg','63', '1'),"..
		"(499,'481118500637','GORRA DESLAVADA LOGO HYATT','481118500637.jpg','63', '1'),"..
		"(500,'481118500638','GORRA DESLAVADA LOGO HYATT','481118500638.jpg','63', '1'),"..
		"(501,'481118500702','GORRA DESLAVADA LOGO NOW JADE','481118500702.jpg','63', '1'),"..
		"(502,'481118500703','GORRA DESLAVADA LOGO NOW JADE','481118500703.jpg','63', '1'),"..
		"(503,'481118500705','GORRA DESLAVADA LOGO NOW JADE','481118500705.jpg','63', '1'),"..
		"(504,'481118500706','GORRA DESLAVADA LOGO NOW JADE','481118500706.jpg','63', '1'),"..
		"(505,'481118500709','GORRA DESLAVADA LOGO NOW JADE','481118500709.jpg','63', '1'),"..
		"(506,'481118500710','GORRA DESLAVADA LOGO NOW JADE','481118500710.jpg','63', '1'),"..
		"(507,'481118500711','GORRA DESLAVADA LOGO NOW JADE','481118500711.jpg','63', '1'),"..
		"(508,'481118500712','GORRA DESLAVADA LOGO NOW JADE','481118500712.jpg','63', '1'),"..
		"(509,'481118500713','GORRA DESLAVADA LOGO NOW JADE','481118500713.jpg','63', '1'),"..
		"(510,'481118500714','GORRA DESLAVADA LOGO NOW JADE','481118500714.jpg','63', '1'),"..
		"(511,'481118500715','GORRA DESLAVADA LOGO NOW JADE','481118500715.jpg','63', '1'),"..
		"(512,'481118500716','GORRA DESLAVADA LOGO NOW JADE','481118500716.jpg','63', '1'),"..
		"(513,'481118500721','GORRA DESLAVADA LOGO NOW JADE','481118500721.jpg','63', '1'),"..
		"(514,'481118500725','GORRA DESLAVADA LOGO NOW JADE','481118500725.jpg','63', '1'),"..
		"(515,'481118500726','GORRA DESLAVADA LOGO NOW JADE','481118500726.jpg','63', '1'),"..
		"(516,'481118500728','GORRA DESLAVADA LOGO NOW JADE','481118500728.jpg','63', '1'),"..
		"(517,'481118500729','GORRA DESLAVADA LOGO NOW JADE','481118500729.jpg','63', '1'),"..
		"(518,'481118500730','GORRA DESLAVADA LOGO NOW JADE','481118500730.jpg','63', '1'),"..
		"(519,'481118500731','GORRA DESLAVADA LOGO NOW JADE','481118500731.jpg','63', '1'),"..
		"(520,'481118500732','GORRA DESLAVADA LOGO NOW JADE','481118500732.jpg','63', '1'),"..
		"(521,'481118500734','GORRA DESLAVADA LOGO NOW JADE','481118500734.jpg','63', '1'),"..
		"(522,'481118500735','GORRA DESLAVADA LOGO NOW JADE','481118500735.jpg','63', '1'),"..
		"(523,'481118500737','GORRA DESLAVADA LOGO NOW JADE','481118500737.jpg','63', '1'),"..
		"(524,'481118500738','GORRA DESLAVADA LOGO NOW JADE','481118500738.jpg','63', '1'),"..
		"(525,'481118600102','GORRA VINTAGE','481118600102.jpg','68', '1'),"..
		"(526,'481118600103','GORRA VINTAGE','481118600103.jpg','68', '1'),"..
		"(527,'481118600108','GORRA VINTAGE','481118600108.jpg','68', '1'),"..
		"(528,'481118600109','GORRA VINTAGE','481118600109.jpg','68', '1'),"..
		"(529,'481118600111','GORRA VINTAGE','481118600111.jpg','68', '1'),"..
		"(530,'481118600112','GORRA VINTAGE','481118600112.jpg','68', '1'),"..
		"(531,'481118600113','GORRA VINTAGE','481118600113.jpg','68', '1'),"..
		"(532,'481118600115','GORRA VINTAGE','481118600115.jpg','68', '1'),"..
		"(533,'481118600116','GORRA VINTAGE','481118600116.jpg','68', '1'),"..
		"(534,'481118600117','GORRA VINTAGE','481118600117.jpg','68', '1'),"..
		"(535,'481118600118','GORRA VINTAGE','481118600118.jpg','68', '1'),"..
		"(536,'481118600128','GORRA VINTAGE','481118600128.jpg','68', '1'),"..
		"(537,'481118600129','GORRA VINTAGE','481118600129.jpg','68', '1'),"..
		"(538,'481118600130','GORRA VINTAGE','481118600130.jpg','68', '1'),"..
		"(539,'481118600131','GORRA VINTAGE','481118600131.jpg','68', '1'),"..
		"(540,'481118600132','GORRA VINTAGE','481118600132.jpg','68', '1'),"..
		"(541,'481118600137','GORRA VINTAGE','481118600137.jpg','68', '1'),"..
		"(542,'481118600140','GORRA VINTAGE','481118600140.jpg','68', '1'),"..
		"(543,'481118600169','GORRA VINTAGE','481118600169.jpg','68', '1'),"..
		"(544,'481118600170','GORRA VINTAGE','481118600170.jpg','68', '1'),"..
		"(545,'481118600171','GORRA VINTAGE','481118600171.jpg','68', '1'),"..
		"(546,'481118600172','GORRA VINTAGE','481118600172.jpg','68', '1'),"..
		"(547,'481118600173','GORRA VINTAGE','481118600173.jpg','68', '1'),"..
		"(548,'481118600186','GORRA VINTAGE','481118600186.jpg','68', '1'),"..
		"(549,'481118600187','GORRA VINTAGE','481118600187.jpg','68', '1'),"..
		"(550,'481118700103','GORRA BEBE','481118700103.jpg','47', '1'),"..
		"(551,'481118700104','GORRA BEBE','481118700104.jpg','47', '1'),"..
		"(552,'481118700110','GORRA BEBE','481118700110.jpg','47', '1'),"..
		"(553,'481118700112','GORRA BEBE','481118700112.jpg','47', '1'),"..
		"(554,'481118700129','GORRA BEBE','481118700129.jpg','47', '1'),"..
		"(555,'481118800103','GORRA GENERICA','481118800103.jpg','68', '1'),"..
		"(556,'481118800104','GORRA GENERICA','481118800104.jpg','68', '1'),"..
		"(557,'481118800108','GORRA GENERICA','481118800108.jpg','68', '1'),"..
		"(558,'481118800110','GORRA GENERICA','481118800110.jpg','68', '1'),"..
		"(559,'481118800111','GORRA GENERICA','481118800111.jpg','68', '1'),"..
		"(560,'481118800112','GORRA GENERICA','481118800112.jpg','68', '1'),"..
		"(561,'481118800113','GORRA GENERICA','481118800113.jpg','68', '1'),"..
		"(562,'481118800116','GORRA GENERICA','481118800116.jpg','68', '1'),"..
		"(563,'481118800171','GORRA GENERICA','481118800171.jpg','68', '1'),"..
		"(564,'481118800173','GORRA GENERICA','481118800173.jpg','68', '1'),"..
		"(565,'4811406050','PL TANK TOP NIÑA MARIPOSAS FIUSHA','4811406050.jpg','66', '1'),"..
		"(566,'4811406051','PL TANK TOP NIÑA PRINCESS TURQUESA','4811406051.jpg','66', '1'),"..
		"(567,'4811564001','COMBO DAMA CHANCLITAS ROSA','4811564001.jpg','99', '1'),"..
		"(568,'4811564002','COMBO DAMA PIEDRITAS CELESTE','4811564002.jpg','99', '1'),"..
		"(569,'4811564003','COMBO DAMA PIEDRITAS ROSA','4811564003.jpg','99', '1'),"..
		"(570,'4811564004','COMBO DAMA PIEDRITAS MUSGO','4811564004.jpg','99', '1'),"..
		"(571,'4811564005','COMBO DAMA PIEDRITAS DURAZNO','4811564005.jpg','99', '1'),"..
		"(572,'4811564006','COMBO VICERA BLANCO','4811564006.jpg','99', '1'),"..
		"(573,'4811564007','COMBO VICERA CELESTE','4811564007.jpg','99', '1'),"..
		"(574,'4811564008','COMBO VICERA MARINO','4811564008.jpg','99', '1'),"..
		"(575,'4811564009','COMBO VICERA NEGRO','4811564009.jpg','99', '1'),"..
		"(576,'4811564010','COMBO VICERA ROJO','4811564010.jpg','99', '1'),"..
		"(577,'4811564011','COMBO VICERA ROSA','4811564011.jpg','99', '1'),"..
		"(578,'4811564012','COMBO VICERA KAKY','4811564012.jpg','99', '1'),"..
		"(579,'4811564013','COMBO VICERA CHOCOLATE','4811564013.jpg','99', '1'),"..
		"(580,'4811584001','COMBO NIÑO MARINO','4811584001.jpg','94', '1'),"..
		"(581,'4811584002','COMBO NIÑO NARANJA','4811584002.jpg','94', '1'),"..
		"(582,'4811586001','COMBO ADULTO INSTITUCIONAL MARINO','4811586001.jpg','99', '1'),"..
		"(583,'4811586001E','COMBO ADULTO INSTITUCIONAL MARINO XXL','4811586001E.jpg','110', '1'),"..
		"(584,'4811586002','COMBO ADULTO INSTITUCIONAL OLIVO','4811586002.jpg','99', '1'),"..
		"(585,'4811586002E','COMBO ADULTO INSTITUCIONAL OLIVO XXL','4811586002E.jpg','110', '1'),"..
		"(586,'4811586003','COMBO ADULTO INSTITUCIONAL VINO','4811586003.jpg','99', '1'),"..
		"(587,'4811586003E','COMBO ADULTO INSTITUCIONAL VINO XXL','4811586003E.jpg','110', '1'),"..
		"(588,'4811586004','COMBO ADULTO INSTITUCIONAL KAKY','4811586004.jpg','99', '1'),"..
		"(589,'4811586004E','COMBO ADULTO INSTITUCIONAL KAKY XXL','4811586004E.jpg','110', '1'),"..
		"(590,'4811586005','COMBO ADULTO INSTITUCIONAL ROYAL','4811586005.jpg','99', '1'),"..
		"(591,'4811586005E','COMBO ADULTO INSTITUCIONAL ROYAL XXL','4811586005E.jpg','110', '1'),"..
		"(592,'4811586006','COMBO ADULTO BICOLOR MOSTAZA','4811586006.jpg','99', '1'),"..
		"(593,'4811586007','COMBO ADULTO COLEGIAL NARAJA','4811586007.jpg','99', '1'),"..
		"(594,'4811586008','COMBO TEAM OLIVO','4811586008.jpg','99', '1'),"..
		"(595,'4811586009','COMBO PROPERTY KAKY','4811586009.jpg','99', '1'),"..
		"(596,'4811586010','COMBO CITY MARINO','4811586010.jpg','99', '1'),"..
		"(597,'4811586011','COMBO SINCE NARANJA','4811586011.jpg','99', '1'),"..
		"(598,'481176900103','SOMBRERO GUILLIGAN','481176900103.jpg','73', '1'),"..
		"(599,'481176900110','SOMBRERO GUILLIGAN','481176900110.jpg','73', '1'),"..
		"(600,'481176900111','SOMBRERO GUILLIGAN','481176900111.jpg','73', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(601,'481176900112','SOMBRERO GUILLIGAN','481176900112.jpg','73', '1'),"..
		"(602,'481176900113','SOMBRERO GUILLIGAN','481176900113.jpg','73', '1'),"..
		"(603,'481176900128','SOMBRERO GUILLIGAN','481176900128.jpg','73', '1'),"..
		"(604,'481176900130','SOMBRERO GUILLIGAN','481176900130.jpg','73', '1'),"..
		"(605,'481176900403','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900403.jpg','73', '1'),"..
		"(606,'481176900410','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900410.jpg','73', '1'),"..
		"(607,'481176900411','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900411.jpg','73', '1'),"..
		"(608,'481176900412','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900412.jpg','73', '1'),"..
		"(609,'481176900413','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900413.jpg','73', '1'),"..
		"(610,'481176900426','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900426.jpg','73', '1'),"..
		"(611,'481176900428','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900428.jpg','73', '1'),"..
		"(612,'481176900430','SOMBRERO GUILLIGAN LOGO DREAMS TULUM','481176900430.jpg','73', '1'),"..
		"(613,'481186800102','VICERA SANDWICH','481186800102.jpg','62', '1'),"..
		"(614,'481186800103','VICERA SANDWICH','481186800103.jpg','62', '1'),"..
		"(615,'481186800104','VICERA SANDWICH','481186800104.jpg','62', '1'),"..
		"(616,'481186800111','VICERA SANDWICH','481186800111.jpg','62', '1'),"..
		"(617,'481186800113','VICERA SANDWICH','481186800113.jpg','62', '1'),"..
		"(618,'481186800116','VICERA SANDWICH','481186800116.jpg','62', '1'),"..
		"(619,'481186800129','VICERA SANDWICH','481186800129.jpg','62', '1'),"..
		"(620,'481186800137','VICERA SANDWICH','481186800137.jpg','62', '1'),"..
		"(621,'4814006001','MAMELUCO SM PEZ MALETA AMARILLO','4814006001.jpg','50', '1'),"..
		"(622,'4814006002','MAMELUCO SM MARGARITA ROSA','4814006002.jpg','50', '1'),"..
		"(623,'4814008009','MEN`S SWIMWEAR SHORTS MN 009 MARINO','4814008009.jpg','135', '1'),"..
		"(624,'4814008015','MEN`S SWIMWEAR SHORTS MN 015 BLANCO','4814008015.jpg','135', '1'),"..
		"(625,'4814008026','MEN`S SWIMWEAR SHORTS MN 026 ROYAL','4814008026.jpg','135', '1'),"..
		"(626,'4814008027','MEN`S SWIMWEAR SHORTS MN 027 NEGRO','4814008027.jpg','135', '1'),"..
		"(627,'4814008033','MEN`S SWIMWEAR SHORTS MN 033 MARINO','4814008033.jpg','135', '1'),"..
		"(628,'4814008036','MEN`S SWIMWEAR SHORTS MN 036 NEGRO','4814008036.jpg','135', '1'),"..
		"(629,'4814008038','MEN`S SWIMWEAR SHORTS MBD 038 CHARCOAL','4814008038.jpg','135', '1'),"..
		"(630,'4814008039','MEN`S SWIMWEAR MN 039 NEGRO','4814008039.jpg','135', '1'),"..
		"(631,'4814008041','MEN`S SWIMWEAR SHORTS MN 041 MARINO','4814008041.jpg','135', '1'),"..
		"(632,'4814008044','MEN`S SWIMWEAR SHORTS MN 044 ROYAL','4814008044.jpg','135', '1'),"..
		"(633,'4814008045','MEN`S SWIMWEAR SHORTS MN 045 NARANJA','4814008045.jpg','135', '1'),"..
		"(634,'4814008047','MEN`S SWIMWEAR SHORTS MN 047 VERDE','4814008047.jpg','135', '1'),"..
		"(635,'4814008049','MEN`S SWIMWEAR SHORTS MN 049 NEGRO','4814008049.jpg','135', '1'),"..
		"(636,'4814008050','MEN`S SWIMWEAR SHORTS MN 050 CHARCOAL','4814008050.jpg','135', '1'),"..
		"(637,'4814008051','MEN`S SWIMWEAR SHORTS MN 051 INDIGO','4814008051.jpg','135', '1'),"..
		"(638,'4814008059','MEN`S SWIMWEAR SHORTS MN 059 BLUE','4814008059.jpg','135', '1'),"..
		"(639,'4814008060','MEN`S SWIMWEAR SHORTS MN 060 NARANJA','4814008060.jpg','135', '1'),"..
		"(640,'4814008063','MEN`S SWIMWEAR SHORTS MN 063 DERMIN','4814008063.jpg','135', '1'),"..
		"(641,'4814008065','MEN`S SWIMWEAR SHORTS MN 065 MARINO','4814008065.jpg','135', '1'),"..
		"(642,'4814008067','MEN`S SWIMWEAR SHORTS MN 067 NEGRO','4814008067.jpg','135', '1'),"..
		"(643,'4814008068','MEN`S SWIMWEAR SHORTS MN 068 ROYAL','4814008068.jpg','135', '1'),"..
		"(644,'4814008109','MEN`S SWIMWEAR SHORTS MN 009 NEGRO','4814008109.jpg','135', '1'),"..
		"(645,'4814008126','MEN`S SWIMWEAR SHORTS MN 026 NEGRO','4814008126.jpg','135', '1'),"..
		"(646,'4814008127','MEN`S SWIMWEAR SHORTS MN 027 ROYAL','4814008127.jpg','135', '1'),"..
		"(647,'4814008133','MEN`S SWIMWEAR SHORTS MN 033 ROYAL','4814008133.jpg','135', '1'),"..
		"(648,'4814008136','MEN`S SWIMWEAR SHORTS MN 036 BLANCO','4814008136.jpg','135', '1'),"..
		"(649,'4814008138','MEN`S SWIMWEAR SHORTS MBD 038 TAN','4814008138.jpg','135', '1'),"..
		"(650,'4814008149','MEN`S SWIMWEAR SHORTS MN 049 ROYAL','4814008149.jpg','135', '1'),"..
		"(651,'4814008150','MEN`S SWIMWEAR SHORTS MN 050 NARANJA','4814008150.jpg','135', '1'),"..
		"(652,'4814008160','MEN`S SWIMWEAR SHORTS MN 060 LIMON','4814008160.jpg','135', '1'),"..
		"(653,'4814008163','MEN`S SWIMWEAR SHORTS MN 063 NEGRO','4814008163.jpg','135', '1'),"..
		"(654,'4814008165','MEN`S SWIMWEAR SHORTS MN 065 NEGRO','4814008165.jpg','135', '1'),"..
		"(655,'4814008167','MEN`S SWIMWEAR SHORTS MN 067 BLUE','4814008167.jpg','135', '1'),"..
		"(656,'4814008168','MEN`S SWIMWEAR SHORTS MN 068 PURPLE','4814008168.jpg','135', '1'),"..
		"(657,'4814008209','MEN`S SWIMWEAR SHORTS MN 009 BEIGE','4814008209.jpg','135', '1'),"..
		"(658,'4814008226','MEN`S SWIMWEAR SHORTS MN 026 VERDE','4814008226.jpg','135', '1'),"..
		"(659,'4814008233','MEN`S SWIMWEAR SHORTS MN 033 CHARCOAL','4814008233.jpg','135', '1'),"..
		"(660,'4814008236','MEN`S SWIMWEAR SHORTS MN 036 CHARCOAL','4814008236.jpg','135', '1'),"..
		"(661,'4814008267','MEN`S SWIMWEAR SHORTS MN 067 ROJO','4814008267.jpg','135', '1'),"..
		"(662,'4814008309','MEN`S SWIMWEAR SHORTS MN 009 OLIVO','4814008309.jpg','135', '1'),"..
		"(663,'4814008326','MEN`S SWIMWEAR SHORTS MN 026 MULTI','4814008326.jpg','135', '1'),"..
		"(664,'4814008333','MEN`S SWIMWEAR SHORTS MN 033 NEGRO','4814008333.jpg','135', '1'),"..
		"(665,'4814008336','MEN`S SWIMWEAR SHORTS MN 036 TAN','4814008336.jpg','135', '1'),"..
		"(666,'4814008367','MEN`S SWIMWEAR SHORTS MN 067 NARANJA','4814008367.jpg','135', '1'),"..
		"(667,'4814203070','PL NIÑA CORAZON MARGARITAS MORADO','4814203070.jpg','55', '1'),"..
		"(668,'4814203071','PL NIÑA LOVE ROSA','4814203071.jpg','55', '1'),"..
		"(669,'4814203072','PL NIÑA ADICTED LOVE','4814203072.jpg','55', '1'),"..
		"(670,'48142030730','PL NIÑA PICE & LOVE COLORES','48142030730.jpg','55', '1'),"..
		"(671,'4814203101','PL NÑA TRANS CORAZON MOSAICO FIUSHA','4814203101.jpg','55', '1'),"..
		"(672,'4814203102','PL NÑA TRANS CORAZON IBISCUS MARINO','4814203102.jpg','55', '1'),"..
		"(673,'4814203103','PL NÑA TRANS PALMERAS CORAZON FIUSHA','4814203103.jpg','55', '1'),"..
		"(674,'4814203105','PL NÑA TRANS 2 TENIS COLORES LIMA','4814203105.jpg','55', '1'),"..
		"(675,'9038','PLAYERA DE NADAR RASH AD TRES TORTUGAS M/L','9038.jpg','129', '1'),"..
		"(676,'9039','PLAYERA DE NADAR RASH AD IGUANA RETRO M/C','9039.jpg','125', '1'),"..
		"(677,'9040','PLAYERA DE NADAR RASH DA FLORES LINEALES M/L','9040.jpg','129', '1'),"..
		"(678,'9041','PLAYERA DE NADAR RASH DA FLORES TURQUEAS M/C','9041.jpg','125', '1'),"..
		"(679,'9042','PLAYERA DE NADAR RASH NIÑA PAISAJE M/C','9042.jpg','115', '1'),"..
		"(680,'9043','PLAYERA DE NADAR RASH NIÑA 4 FIGURAS M/L','9043.jpg','119', '1'),"..
		"(681,'9044','PLAYERA DE NADAR RASH NIÑO OPEN WATER M/L','9044.jpg','119', '1'),"..
		"(682,'9045','PLAYERA DE NADAR RASH NIÑO DELFIN LINEAS M/C','9045.jpg','115', '1'),"..
		"(683,'9463','TRAJE DE BAÑO DAMA','9463.jpg','230', '1'),"..
		"(684,'9464','TRAJE DE BAÑO DAMA','9464.jpg','230', '1'),"..
		"(685,'9465','TRAJE DE BAÑO DAMA','9465.jpg','230', '1'),"..
		"(686,'9465','TRAJE DE BAÑO DAMA','9465.jpg','230', '1'),"..
		"(687,'9466','TRAJE DE BAÑO DAMA','9466.jpg','230', '1'),"..
		"(688,'9467','TRAJE DE BAÑO DAMA','9467.jpg','230', '1'),"..
		"(689,'AZUCOA00102','COMBO ADULTO INSTITUCIONAL','AZUCOA00102.jpg','99', '1'),"..
		"(690,'AZUCOA00105','COMBO ADULTO INSTITUCIONAL','AZUCOA00105.jpg','99', '1'),"..
		"(691,'AZUCOA00110','COMBO ADULTO INSTITUCIONAL','AZUCOA00110.jpg','99', '1'),"..
		"(692,'AZUCOA00111','COMBO ADULTO INSTITUCIONAL','AZUCOA00111.jpg','99', '1'),"..
		"(693,'AZUCOA00112','COMBO ADULTO INSTITUCIONAL','AZUCOA00112.jpg','99', '1'),"..
		"(694,'AZUCOA001XXL02','COMBO ADULTO INSTITUCIONAL','AZUCOA001XXL02.jpg','110', '1'),"..
		"(695,'AZUCOA001XXL05','COMBO ADULTO INSTITUCIONAL','AZUCOA001XXL05.jpg','110', '1'),"..
		"(696,'AZUCOA001XXL10','COMBO ADULTO INSTITUCIONAL','AZUCOA001XXL10.jpg','110', '1'),"..
		"(697,'AZUCOA001XXL11','COMBO ADULTO INSTITUCIONAL','AZUCOA001XXL11.jpg','110', '1'),"..
		"(698,'AZUCOA001XXL12','COMBO ADULTO INSTITUCIONAL','AZUCOA001XXL12.jpg','110', '1'),"..
		"(699,'AZUGDKMFI03','GORRA MICRO FIBRA AZUL','AZUGDKMFI03.jpg','76', '1'),"..
		"(700,'AZUGDKMFI11','GORRA MICRO FIBRA AZUL','AZUGDKMFI11.jpg','76', '1'),"..
		"(701,'AZUGDKMFI13','GORRA MICRO FIBRA AZUL','AZUGDKMFI13.jpg','76', '1'),"..
		"(702,'AZUGDKMFI16','GORRA MICRO FIBRA AZUL','AZUGDKMFI16.jpg','76', '1'),"..
		"(703,'AZUGDKNBA03','GORRA NIÑO BASICA AZUL','AZUGDKNBA03.jpg','63', '1'),"..
		"(704,'AZUGMBCAM13','GORRA CAMBAS AZUL','AZUGMBCAM13.jpg','68', '1'),"..
		"(705,'AZUGMBCAM26','GORRA CAMBAS AZUL','AZUGMBCAM26.jpg','68', '1'),"..
		"(706,'AZUGMBCAM32','GORRA CAMBAS AZUL','AZUGMBCAM32.jpg','68', '1'),"..
		"(707,'AZUGMBDAM04','GORRA DAMA AZUL','AZUGMBDAM04.jpg','63', '1'),"..
		"(708,'AZUGMBDAM12','GORRA DAMA AZUL','AZUGMBDAM12.jpg','63', '1'),"..
		"(709,'AZUGMBDAM17','GORRA DAMA AZUL','AZUGMBDAM17.jpg','63', '1'),"..
		"(710,'AZUGMBDAM18','GORRA DAMA AZUL','AZUGMBDAM18.jpg','63', '1'),"..
		"(711,'AZUGMBDAM19','GORRA DAMA AZUL','AZUGMBDAM19.jpg','63', '1'),"..
		"(712,'AZUGMBDAM29','GORRA DAMA AZUL','AZUGMBDAM29.jpg','63', '1'),"..
		"(713,'AZUGMBDAM40','GORRA DAMA AZUL','AZUGMBDAM40.jpg','63', '1'),"..
		"(714,'AZUGMBDAM41','GORRA DAMA AZUL','AZUGMBDAM41.jpg','63', '1'),"..
		"(715,'AZUGMBDES02','GORRA DESLAVADA AZUL','AZUGMBDES02.jpg','63', '1'),"..
		"(716,'AZUGMBDES05','GORRA DESLAVADA AZUL','AZUGMBDES05.jpg','63', '1'),"..
		"(717,'AZUGMBDES06','GORRA DESLAVADA AZUL','AZUGMBDES06.jpg','63', '1'),"..
		"(718,'AZUGMBDES10','GORRA DESLAVADA AZUL','AZUGMBDES10.jpg','63', '1'),"..
		"(719,'AZUGMBDES11','GORRA DESLAVADA AZUL','AZUGMBDES11.jpg','63', '1'),"..
		"(720,'AZUGMBDES12','GORRA DESLAVADA AZUL','AZUGMBDES12.jpg','63', '1'),"..
		"(721,'AZUGMBDES13','GORRA DESLAVADA AZUL','AZUGMBDES13.jpg','63', '1'),"..
		"(722,'AZUGMBDES15','GORRA DESLAVADA AZUL','AZUGMBDES15.jpg','63', '1'),"..
		"(723,'AZUGMBDES21','GORRA DESLAVADA AZUL','AZUGMBDES21.jpg','63', '1'),"..
		"(724,'AZUGMBDES25','GORRA DESLAVADA AZUL','AZUGMBDES25.jpg','63', '1'),"..
		"(725,'AZUGMBDES26','GORRA DESLAVADA AZUL','AZUGMBDES26.jpg','63', '1'),"..
		"(726,'AZUGMBDES28','GORRA DESLAVADA AZUL','AZUGMBDES28.jpg','63', '1'),"..
		"(727,'AZUGMBDES30','GORRA DESLAVADA AZUL','AZUGMBDES30.jpg','63', '1'),"..
		"(728,'AZUGMBDES32','GORRA DESLAVADA AZUL','AZUGMBDES32.jpg','63', '1'),"..
		"(729,'AZUGMBDES34','GORRA DESLAVADA AZUL','AZUGMBDES34.jpg','63', '1'),"..
		"(730,'AZUGMBDES35','GORRA DESLAVADA AZUL','AZUGMBDES35.jpg','63', '1'),"..
		"(731,'AZUGMBNIÑ02','GORRA NIÑO DESLAVADA AZUL','AZUGMBNIÑ02.jpg','63', '1'),"..
		"(732,'AZUGMBNIÑ10','GORRA NIÑO DESLAVADA AZUL','AZUGMBNIÑ10.jpg','63', '1'),"..
		"(733,'AZUGMBNIÑ11','GORRA NIÑO DESLAVADA AZUL','AZUGMBNIÑ11.jpg','63', '1'),"..
		"(734,'AZUGMBNIÑ12','GORRA NIÑO DESLAVADA AZUL','AZUGMBNIÑ12.jpg','63', '1'),"..
		"(735,'AZUGMBNIÑ15','GORRA NIÑO DESLAVADA AZUL','AZUGMBNIÑ15.jpg','63', '1'),"..
		"(736,'AZUGMBNMA62','GORRA NIÑA AZUL','AZUGMBNMA62.jpg','68', '1'),"..
		"(737,'AZUGMBNMA63','GORRA NIÑA AZUL','AZUGMBNMA63.jpg','68', '1'),"..
		"(738,'AZUGMBNMA64','GORRA NIÑA AZUL','AZUGMBNMA64.jpg','68', '1'),"..
		"(739,'AZUGMBNMA65','GORRA NIÑA AZUL','AZUGMBNMA65.jpg','68', '1'),"..
		"(740,'AZUGMBOXF11','GORRA OXFORD AZUL','AZUGMBOXF11.jpg','68', '1'),"..
		"(741,'AZUGMBOXF28','GORRA OXFORD AZUL','AZUGMBOXF28.jpg','68', '1'),"..
		"(742,'AZUGMBOXF37','GORRA OXFORD AZUL','AZUGMBOXF37.jpg','68', '1'),"..
		"(743,'AZUGMBSAN02','GORRA SANDWICH AZUL','AZUGMBSAN02.jpg','68', '1'),"..
		"(744,'AZUGMBSAN03','GORRA SANDWICH AZUL','AZUGMBSAN03.jpg','68', '1'),"..
		"(745,'AZUGMBSAN05','GORRA SANDWICH AZUL','AZUGMBSAN05.jpg','68', '1'),"..
		"(746,'AZUGMBSAN06','GORRA SANDWICH AZUL','AZUGMBSAN06.jpg','68', '1'),"..
		"(747,'AZUGMBSAN07','GORRA SANDWICH AZUL','AZUGMBSAN07.jpg','68', '1'),"..
		"(748,'AZUGMBSAN11','GORRA SANDWICH AZUL','AZUGMBSAN11.jpg','68', '1'),"..
		"(749,'AZUGMBSAN13','GORRA SANDWICH AZUL','AZUGMBSAN13.jpg','68', '1'),"..
		"(750,'AZUGMBSAN20','GORRA SANDWICH AZUL','AZUGMBSAN20.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(751,'AZUGMBSAN22','GORRA SANDWICH AZUL','AZUGMBSAN22.jpg','68', '1'),"..
		"(752,'AZUGMBSAN30','GORRA SANDWICH AZUL','AZUGMBSAN30.jpg','68', '1'),"..
		"(753,'AZUGMBSAN32','GORRA SANDWICH AZUL','AZUGMBSAN32.jpg','68', '1'),"..
		"(754,'AZUGMBSAN33','GORRA SANDWICH AZUL','AZUGMBSAN33.jpg','68', '1'),"..
		"(755,'AZUGMBSAN36','GORRA SANDWICH AZUL','AZUGMBSAN36.jpg','68', '1'),"..
		"(756,'AZUGMBSAN39','GORRA SANDWICH AZUL','AZUGMBSAN39.jpg','68', '1'),"..
		"(757,'AZUGMBSAN43','GORRA SANDWICH AZUL','AZUGMBSAN43.jpg','68', '1'),"..
		"(758,'AZUGMBSAN45','GORRA SANDWICH AZUL','AZUGMBSAN45.jpg','68', '1'),"..
		"(759,'AZUGMBSAN49','GORRA SANDWICH AZUL','AZUGMBSAN49.jpg','68', '1'),"..
		"(760,'BAPGDKBAS40','GORRA BASICA BAHIA','BAPGDKBAS40.jpg','43', '1'),"..
		"(761,'BAPGMBDES04','GORRA DESLAVADA','BAPGMBDES04.jpg','63', '1'),"..
		"(762,'BAPGMBDES05','GORRA DESLAVADA','BAPGMBDES05.jpg','63', '1'),"..
		"(763,'BAPGMBDES06','GORRA DESLAVADA','BAPGMBDES06.jpg','63', '1'),"..
		"(764,'BAPGMBDES10','GORRA DESLAVADA','BAPGMBDES10.jpg','63', '1'),"..
		"(765,'BAPGMBDES11','GORRA DESLAVADA','BAPGMBDES11.jpg','63', '1'),"..
		"(766,'BAPGMBDES12','GORRA DESLAVADA','BAPGMBDES12.jpg','63', '1'),"..
		"(767,'BAPGMBDES13','GORRA DESLAVADA','BAPGMBDES13.jpg','63', '1'),"..
		"(768,'BAPGMBDES15','GORRA DESLAVADA','BAPGMBDES15.jpg','63', '1'),"..
		"(769,'BAPGMBDES16','GORRA DESLAVADA','BAPGMBDES16.jpg','63', '1'),"..
		"(770,'BAPGMBDES21','GORRA DESLAVADA','BAPGMBDES21.jpg','63', '1'),"..
		"(771,'BAPGMBDES25','GORRA DESLAVADA','BAPGMBDES25.jpg','63', '1'),"..
		"(772,'BAPGMBDES26','GORRA DESLAVADA','BAPGMBDES26.jpg','63', '1'),"..
		"(773,'BAPGMBDES28','GORRA DESLAVADA','BAPGMBDES28.jpg','63', '1'),"..
		"(774,'BAPGMBDES30','GORRA DESLAVADA','BAPGMBDES30.jpg','63', '1'),"..
		"(775,'BAPGMBDES32','GORRA DESLAVADA','BAPGMBDES32.jpg','63', '1'),"..
		"(776,'BAPGMBDES34','GORRA DESLAVADA','BAPGMBDES34.jpg','63', '1'),"..
		"(777,'BAPGMBDES35','GORRA DESLAVADA','BAPGMBDES35.jpg','63', '1'),"..
		"(778,'BAPGMBDES37','GORRA DESLAVADA','BAPGMBDES37.jpg','63', '1'),"..
		"(779,'BAPGMBSAN02','GORRA SANDWICH','BAPGMBSAN02.jpg','68', '1'),"..
		"(780,'BAPGMBSAN03','GORRA SANDWICH','BAPGMBSAN03.jpg','68', '1'),"..
		"(781,'BAPGMBSAN05','GORRA SANDWICH','BAPGMBSAN05.jpg','68', '1'),"..
		"(782,'BAPGMBSAN06','GORRA SANDWICH','BAPGMBSAN06.jpg','68', '1'),"..
		"(783,'BAPGMBSAN07','GORRA SANDWICH','BAPGMBSAN07.jpg','68', '1'),"..
		"(784,'BAPGMBSAN11','GORRA SANDWICH','BAPGMBSAN11.jpg','68', '1'),"..
		"(785,'BAPGMBSAN13','GORRA SANDWICH','BAPGMBSAN13.jpg','68', '1'),"..
		"(786,'BAPGMBSAN20','GORRA SANDWICH','BAPGMBSAN20.jpg','68', '1'),"..
		"(787,'BAPGMBSAN22','GORRA SANDWICH','BAPGMBSAN22.jpg','68', '1'),"..
		"(788,'BAPGMBSAN30','GORRA SANDWICH','BAPGMBSAN30.jpg','68', '1'),"..
		"(789,'BAPGMBSAN32','GORRA SANDWICH','BAPGMBSAN32.jpg','68', '1'),"..
		"(790,'BAPGMBSAN33','GORRA SANDWICH','BAPGMBSAN33.jpg','68', '1'),"..
		"(791,'BAPGMBSAN36','GORRA SANDWICH','BAPGMBSAN36.jpg','68', '1'),"..
		"(792,'BAPGMBSAN39','GORRA SANDWICH','BAPGMBSAN39.jpg','68', '1'),"..
		"(793,'BAPGMBSAN43','GORRA SANDWICH','BAPGMBSAN43.jpg','68', '1'),"..
		"(794,'BAPGMBSAN45','GORRA SANDWICH','BAPGMBSAN45.jpg','68', '1'),"..
		"(795,'BAPGMBSAN49','GORRA SANDWICH','BAPGMBSAN49.jpg','68', '1'),"..
		"(796,'BAPGMBSAN51','GORRA SANDWICH','BAPGMBSAN51.jpg','68', '1'),"..
		"(797,'BRYGMBNIÑ02','GORRA NIÑO LOGO BARCY','BRYGMBNIÑ02.jpg','63', '1'),"..
		"(798,'BRYGMBNIÑ10','GORRA NIÑO LOGO BARCY','BRYGMBNIÑ10.jpg','63', '1'),"..
		"(799,'BRYGMBNIÑ11','GORRA NIÑO LOGO BARCY','BRYGMBNIÑ11.jpg','63', '1'),"..
		"(800,'BRYGMBNIÑ12','GORRA NIÑO LOGO BARCY','BRYGMBNIÑ12.jpg','63', '1'),"..
		"(801,'BRYGMBNIÑ15','GORRA NIÑO LOGO BARCY','BRYGMBNIÑ15.jpg','63', '1'),"..
		"(802,'CATCOA00510','COMBO ADULTO INSTITUCIONAL','CATCOA00510.jpg','99', '1'),"..
		"(803,'CATCOA00511','COMBO ADULTO INSTITUCIONAL','CATCOA00511.jpg','99', '1'),"..
		"(804,'CATCOA00512','COMBO ADULTO INSTITUCIONAL','CATCOA00512.jpg','99', '1'),"..
		"(805,'CATCOA00515','COMBO ADULTO INSTITUCIONAL','CATCOA00515.jpg','99', '1'),"..
		"(806,'CATCOA00526','COMBO ADULTO INSTITUCIONAL','CATCOA00526.jpg','99', '1'),"..
		"(807,'CATCOA00528','COMBO ADULTO INSTITUCIONAL','CATCOA00528.jpg','99', '1'),"..
		"(808,'CATCOA00530','COMBO ADULTO INSTITUCIONAL','CATCOA00530.jpg','99', '1'),"..
		"(809,'CATCOA00532','COMBO ADULTO INSTITUCIONAL','CATCOA00532.jpg','99', '1'),"..
		"(810,'CATCOA005XXL10','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL10.jpg','110', '1'),"..
		"(811,'CATCOA005XXL11','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL11.jpg','110', '1'),"..
		"(812,'CATCOA005XXL12','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL12.jpg','110', '1'),"..
		"(813,'CATCOA005XXL15','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL15.jpg','110', '1'),"..
		"(814,'CATCOA005XXL26','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL26.jpg','110', '1'),"..
		"(815,'CATCOA005XXL28','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL28.jpg','110', '1'),"..
		"(816,'CATCOA005XXL30','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL30.jpg','110', '1'),"..
		"(817,'CATCOA005XXL32','COMBO ADULTO INSTITUCIONAL','CATCOA005XXL32.jpg','110', '1'),"..
		"(818,'CATGMBDAM04','GORRA DAMA CATALONIA','CATGMBDAM04.jpg','63', '1'),"..
		"(819,'CATGMBDAM12','GORRA DAMA CATALONIA','CATGMBDAM12.jpg','63', '1'),"..
		"(820,'CATGMBDAM17','GORRA DAMA CATALONIA','CATGMBDAM17.jpg','63', '1'),"..
		"(821,'CATGMBDAM18','GORRA DAMA CATALONIA','CATGMBDAM18.jpg','63', '1'),"..
		"(822,'CATGMBDAM19','GORRA DAMA CATALONIA','CATGMBDAM19.jpg','63', '1'),"..
		"(823,'CATGMBDAM29','GORRA DAMA CATALONIA','CATGMBDAM29.jpg','63', '1'),"..
		"(824,'CATGMBDAM40','GORRA DAMA CATALONIA','CATGMBDAM40.jpg','63', '1'),"..
		"(825,'CATGMBDAM41','GORRA DAMA CATALONIA','CATGMBDAM41.jpg','63', '1'),"..
		"(826,'CATGMBDES04','GORRA DESLAVADA CATALONIA','CATGMBDES04.jpg','63', '1'),"..
		"(827,'CATGMBDES05','GORRA DESLAVADA CATALONIA','CATGMBDES05.jpg','63', '1'),"..
		"(828,'CATGMBDES06','GORRA DESLAVADA CATALONIA','CATGMBDES06.jpg','63', '1'),"..
		"(829,'CATGMBDES10','GORRA DESLAVADA CATALONIA','CATGMBDES10.jpg','63', '1'),"..
		"(830,'CATGMBDES11','GORRA DESLAVADA CATALONIA','CATGMBDES11.jpg','63', '1'),"..
		"(831,'CATGMBDES12','GORRA DESLAVADA CATALONIA','CATGMBDES12.jpg','63', '1'),"..
		"(832,'CATGMBDES13','GORRA DESLAVADA CATALONIA','CATGMBDES13.jpg','63', '1'),"..
		"(833,'CATGMBDES15','GORRA DESLAVADA CATALONIA','CATGMBDES15.jpg','63', '1'),"..
		"(834,'CATGMBDES16','GORRA DESLAVADA CATALONIA','CATGMBDES16.jpg','63', '1'),"..
		"(835,'CATGMBDES21','GORRA DESLAVADA CATALONIA','CATGMBDES21.jpg','63', '1'),"..
		"(836,'CATGMBDES25','GORRA DESLAVADA CATALONIA','CATGMBDES25.jpg','63', '1'),"..
		"(837,'CATGMBDES26','GORRA DESLAVADA CATALONIA','CATGMBDES26.jpg','63', '1'),"..
		"(838,'CATGMBDES28','GORRA DESLAVADA CATALONIA','CATGMBDES28.jpg','63', '1'),"..
		"(839,'CATGMBDES30','GORRA DESLAVADA CATALONIA','CATGMBDES30.jpg','63', '1'),"..
		"(840,'CATGMBDES32','GORRA DESLAVADA CATALONIA','CATGMBDES32.jpg','63', '1'),"..
		"(841,'CATGMBDES34','GORRA DESLAVADA CATALONIA','CATGMBDES34.jpg','63', '1'),"..
		"(842,'CATGMBDES35','GORRA DESLAVADA CATALONIA','CATGMBDES35.jpg','63', '1'),"..
		"(843,'CATGMBDES37','GORRA DESLAVADA CATALONIA','CATGMBDES37.jpg','63', '1'),"..
		"(844,'CATGMBSAN02','GORRA SANDWICH CATALONIA','CATGMBSAN02.jpg','68', '1'),"..
		"(845,'CATGMBSAN03','GORRA SANDWICH CATALONIA','CATGMBSAN03.jpg','68', '1'),"..
		"(846,'CATGMBSAN05','GORRA SANDWICH CATALONIA','CATGMBSAN05.jpg','68', '1'),"..
		"(847,'CATGMBSAN06','GORRA SANDWICH CATALONIA','CATGMBSAN06.jpg','68', '1'),"..
		"(848,'CATGMBSAN07','GORRA SANDWICH CATALONIA','CATGMBSAN07.jpg','68', '1'),"..
		"(849,'CATGMBSAN11','GORRA SANDWICH CATALONIA','CATGMBSAN11.jpg','68', '1'),"..
		"(850,'CATGMBSAN13','GORRA SANDWICH CATALONIA','CATGMBSAN13.jpg','68', '1'),"..
		"(851,'CATGMBSAN20','GORRA SANDWICH CATALONIA','CATGMBSAN20.jpg','68', '1'),"..
		"(852,'CATGMBSAN22','GORRA SANDWICH CATALONIA','CATGMBSAN22.jpg','68', '1'),"..
		"(853,'CATGMBSAN30','GORRA SANDWICH CATALONIA','CATGMBSAN30.jpg','68', '1'),"..
		"(854,'CATGMBSAN32','GORRA SANDWICH CATALONIA','CATGMBSAN32.jpg','68', '1'),"..
		"(855,'CATGMBSAN33','GORRA SANDWICH CATALONIA','CATGMBSAN33.jpg','68', '1'),"..
		"(856,'CATGMBSAN36','GORRA SANDWICH CATALONIA','CATGMBSAN36.jpg','68', '1'),"..
		"(857,'CATGMBSAN39','GORRA SANDWICH CATALONIA','CATGMBSAN39.jpg','68', '1'),"..
		"(858,'CATGMBSAN43','GORRA SANDWICH CATALONIA','CATGMBSAN43.jpg','68', '1'),"..
		"(859,'CATGMBSAN45','GORRA SANDWICH CATALONIA','CATGMBSAN45.jpg','68', '1'),"..
		"(860,'CATGMBSAN49','GORRA SANDWICH CATALONIA','CATGMBSAN49.jpg','68', '1'),"..
		"(861,'CATGMBSAN51','GORRA SANDWICH CATALONIA','CATGMBSAN51.jpg','68', '1'),"..
		"(862,'CFS-100078','SHORTS DAMA','CFS-100078.jpg','135', '1'),"..
		"(863,'CFS-1000Q','SHORTS DAMA','CFS-1000Q.jpg','135', '1'),"..
		"(864,'CFS-710017','SHORTS DAMA','CFS-710017.jpg','85', '1'),"..
		"(865,'CFS-710018','SHORTS DAMA','CFS-710018.jpg','85', '1'),"..
		"(866,'CFS-710071','SHORTS DAMA','CFS-710071.jpg','85', '1'),"..
		"(867,'CIDGMBDES04','GORRA DESLAVADA','CIDGMBDES04.jpg','63', '1'),"..
		"(868,'CIDGMBDES05','GORRA DESLAVADA','CIDGMBDES05.jpg','63', '1'),"..
		"(869,'CIDGMBDES06','GORRA DESLAVADA','CIDGMBDES06.jpg','63', '1'),"..
		"(870,'CIDGMBDES10','GORRA DESLAVADA','CIDGMBDES10.jpg','63', '1'),"..
		"(871,'CIDGMBDES11','GORRA DESLAVADA','CIDGMBDES11.jpg','63', '1'),"..
		"(872,'CIDGMBDES12','GORRA DESLAVADA','CIDGMBDES12.jpg','63', '1'),"..
		"(873,'CIDGMBDES13','GORRA DESLAVADA','CIDGMBDES13.jpg','63', '1'),"..
		"(874,'CIDGMBDES15','GORRA DESLAVADA','CIDGMBDES15.jpg','63', '1'),"..
		"(875,'CIDGMBDES16','GORRA DESLAVADA','CIDGMBDES16.jpg','63', '1'),"..
		"(876,'CIDGMBDES21','GORRA DESLAVADA','CIDGMBDES21.jpg','63', '1'),"..
		"(877,'CIDGMBDES25','GORRA DESLAVADA','CIDGMBDES25.jpg','63', '1'),"..
		"(878,'CIDGMBDES26','GORRA DESLAVADA','CIDGMBDES26.jpg','63', '1'),"..
		"(879,'CIDGMBDES28','GORRA DESLAVADA','CIDGMBDES28.jpg','63', '1'),"..
		"(880,'CIDGMBDES30','GORRA DESLAVADA','CIDGMBDES30.jpg','63', '1'),"..
		"(881,'CIDGMBDES32','GORRA DESLAVADA','CIDGMBDES32.jpg','63', '1'),"..
		"(882,'CIDGMBDES34','GORRA DESLAVADA','CIDGMBDES34.jpg','63', '1'),"..
		"(883,'CIDGMBDES35','GORRA DESLAVADA','CIDGMBDES35.jpg','63', '1'),"..
		"(884,'CIDGMBDES37','GORRA DESLAVADA','CIDGMBDES37.jpg','63', '1'),"..
		"(885,'CIDGMBSAN02','GORRA SANDWICH','CIDGMBSAN02.jpg','68', '1'),"..
		"(886,'CIDGMBSAN03','GORRA SANDWICH','CIDGMBSAN03.jpg','68', '1'),"..
		"(887,'CIDGMBSAN05','GORRA SANDWICH','CIDGMBSAN05.jpg','68', '1'),"..
		"(888,'CIDGMBSAN06','GORRA SANDWICH','CIDGMBSAN06.jpg','68', '1'),"..
		"(889,'CIDGMBSAN07','GORRA SANDWICH','CIDGMBSAN07.jpg','68', '1'),"..
		"(890,'CIDGMBSAN11','GORRA SANDWICH','CIDGMBSAN11.jpg','68', '1'),"..
		"(891,'CIDGMBSAN13','GORRA SANDWICH','CIDGMBSAN13.jpg','68', '1'),"..
		"(892,'CIDGMBSAN20','GORRA SANDWICH','CIDGMBSAN20.jpg','68', '1'),"..
		"(893,'CIDGMBSAN22','GORRA SANDWICH','CIDGMBSAN22.jpg','68', '1'),"..
		"(894,'CIDGMBSAN30','GORRA SANDWICH','CIDGMBSAN30.jpg','68', '1'),"..
		"(895,'CIDGMBSAN32','GORRA SANDWICH','CIDGMBSAN32.jpg','68', '1'),"..
		"(896,'CIDGMBSAN33','GORRA SANDWICH','CIDGMBSAN33.jpg','68', '1'),"..
		"(897,'CIDGMBSAN36','GORRA SANDWICH','CIDGMBSAN36.jpg','68', '1'),"..
		"(898,'CIDGMBSAN39','GORRA SANDWICH','CIDGMBSAN39.jpg','68', '1'),"..
		"(899,'CIDGMBSAN43','GORRA SANDWICH','CIDGMBSAN43.jpg','68', '1'),"..
		"(900,'CIDGMBSAN45','GORRA SANDWICH','CIDGMBSAN45.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(901,'CIDGMBSAN49','GORRA SANDWICH','CIDGMBSAN49.jpg','68', '1'),"..
		"(902,'CIDGMBSAN51','GORRA SANDWICH','CIDGMBSAN51.jpg','68', '1'),"..
		"(903,'COZCOA01502','COMBO BASICO ADULTO','COZCOA01502.jpg','85', '1'),"..
		"(904,'COZCOA01511','COMBO BASICO ADULTO','COZCOA01511.jpg','85', '1'),"..
		"(905,'COZCOA015XXL02','COMBO BASICO ADULTO','COZCOA015XXL02.jpg','85', '1'),"..
		"(906,'COZCOA015XXL11','COMBO BASICO ADULTO','COZCOA015XXL11.jpg','85', '1'),"..
		"(907,'COZCOD01540','COMBO BASICO DAMA','COZCOD01540.jpg','85', '1'),"..
		"(908,'COZCOD01571','COMBO BASICO DAMA','COZCOD01571.jpg','85', '1'),"..
		"(909,'COZCOV00303','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00303.jpg','99', '1'),"..
		"(910,'COZCOV00304','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00304.jpg','99', '1'),"..
		"(911,'COZCOV00311','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00311.jpg','99', '1'),"..
		"(912,'COZCOV00313','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00313.jpg','99', '1'),"..
		"(913,'COZCOV00316','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00316.jpg','99', '1'),"..
		"(914,'COZCOV00329','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00329.jpg','99', '1'),"..
		"(915,'COZCOV00330','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00330.jpg','99', '1'),"..
		"(916,'COZCOV00337','COMBO VICERA PIEDRITAS COZUMEL','COZCOV00337.jpg','99', '1'),"..
		"(917,'COZGDKBBE03','GORRA BEBE','COZGDKBBE03.jpg','49', '1'),"..
		"(918,'COZGDKBBE04','GORRA BEBE','COZGDKBBE04.jpg','47', '1'),"..
		"(919,'COZGDKBBE10','GORRA BEBE','COZGDKBBE10.jpg','47', '1'),"..
		"(920,'COZGDKBBE12','GORRA BEBE','COZGDKBBE12.jpg','47', '1'),"..
		"(921,'COZGDKBBE29','GORRA BEBE','COZGDKBBE29.jpg','47', '1'),"..
		"(922,'COZGDKPLU12','GORRA PLUS COZUMEL','COZGDKPLU12.jpg','68', '1'),"..
		"(923,'COZGDKPLU17','GORRA PLUS COZUMEL','COZGDKPLU17.jpg','68', '1'),"..
		"(924,'COZGDKPLU18','GORRA PLUS COZUMEL','COZGDKPLU18.jpg','68', '1'),"..
		"(925,'COZGDKPLU40','GORRA PLUS COZUMEL','COZGDKPLU40.jpg','68', '1'),"..
		"(926,'COZGDKPLU71','GORRA PLUS COZUMEL','COZGDKPLU71.jpg','68', '1'),"..
		"(927,'COZGGE00111','GORRA GENERICA 2 TORTUGAS NADANDO','COZGGE00111.jpg','68', '1'),"..
		"(928,'COZGGE00216','GORRA GENERICA PARCHE KAKY','COZGGE00216.jpg','68', '1'),"..
		"(929,'COZGGE00373','GORRA GENERICA PIRATAS','COZGGE00373.jpg','68', '1'),"..
		"(930,'COZGGE00508','GORRA GENERICA PESPUNTE RAYADA','COZGGE00508.jpg','68', '1'),"..
		"(931,'COZGGE00713','GORRA GENERICA PARCHE MILITAR','COZGGE00713.jpg','68', '1'),"..
		"(932,'COZGGE00803','GORRA GENERICA APLICACION AGUILA','COZGGE00803.jpg','68', '1'),"..
		"(933,'COZGGE00971','GORRA GENERICA BORDADO METALICO','COZGGE00971.jpg','68', '1'),"..
		"(934,'COZGGE02513','GORRA GENERICA TIBURON BUCEO','COZGGE02513.jpg','68', '1'),"..
		"(935,'COZGGE02611','GORRA GENERICA TIBURON BUCEO','COZGGE02611.jpg','68', '1'),"..
		"(936,'COZGMBARC04','GORRA ARCOIRIS','COZGMBARC04.jpg','68', '1'),"..
		"(937,'COZGMBARC18','GORRA ARCOIRIS','COZGMBARC18.jpg','68', '1'),"..
		"(938,'COZGMBARC29','GORRA ARCOIRIS','COZGMBARC29.jpg','68', '1'),"..
		"(939,'COZGMBARC38','GORRA ARCOIRIS','COZGMBARC38.jpg','68', '1'),"..
		"(940,'COZGMBCAZ09','GORRA CAZADOR 7667 COZUMEL','COZGMBCAZ09.jpg','76', '1'),"..
		"(941,'COZGMBCAZ30','GORRA CAZADOR 7667 COZUMEL','COZGMBCAZ30.jpg','76', '1'),"..
		"(942,'COZGMBDAM04','GORRA DAMA','COZGMBDAM04.jpg','63', '1'),"..
		"(943,'COZGMBDAM12','GORRA DAMA','COZGMBDAM12.jpg','63', '1'),"..
		"(944,'COZGMBDAM17','GORRA DAMA','COZGMBDAM17.jpg','63', '1'),"..
		"(945,'COZGMBDAM18','GORRA DAMA','COZGMBDAM18.jpg','63', '1'),"..
		"(946,'COZGMBDAM19','GORRA DAMA','COZGMBDAM19.jpg','63', '1'),"..
		"(947,'COZGMBDAM29','GORRA DAMA','COZGMBDAM29.jpg','63', '1'),"..
		"(948,'COZGMBDAM40','GORRA DAMA','COZGMBDAM40.jpg','63', '1'),"..
		"(949,'COZGMBDAM41','GORRA DAMA','COZGMBDAM41.jpg','63', '1'),"..
		"(950,'COZGMBDES04','GORRA DESLAVADA','COZGMBDES04.jpg','63', '1'),"..
		"(951,'COZGMBDES05','GORRA DESLAVADA','COZGMBDES05.jpg','63', '1'),"..
		"(952,'COZGMBDES06','GORRA DESLAVADA','COZGMBDES06.jpg','63', '1'),"..
		"(953,'COZGMBDES10','GORRA DESLAVADA','COZGMBDES10.jpg','63', '1'),"..
		"(954,'COZGMBDES11','GORRA DESLAVADA','COZGMBDES11.jpg','63', '1'),"..
		"(955,'COZGMBDES12','GORRA DESLAVADA','COZGMBDES12.jpg','63', '1'),"..
		"(956,'COZGMBDES13','GORRA DESLAVADA','COZGMBDES13.jpg','63', '1'),"..
		"(957,'COZGMBDES15','GORRA DESLAVADA','COZGMBDES15.jpg','63', '1'),"..
		"(958,'COZGMBDES16','GORRA DESLAVADA','COZGMBDES16.jpg','63', '1'),"..
		"(959,'COZGMBDES21','GORRA DESLAVADA','COZGMBDES21.jpg','63', '1'),"..
		"(960,'COZGMBDES25','GORRA DESLAVADA','COZGMBDES25.jpg','63', '1'),"..
		"(961,'COZGMBDES26','GORRA DESLAVADA','COZGMBDES26.jpg','63', '1'),"..
		"(962,'COZGMBDES28','GORRA DESLAVADA','COZGMBDES28.jpg','63', '1'),"..
		"(963,'COZGMBDES30','GORRA DESLAVADA','COZGMBDES30.jpg','63', '1'),"..
		"(964,'COZGMBDES32','GORRA DESLAVADA','COZGMBDES32.jpg','63', '1'),"..
		"(965,'COZGMBDES34','GORRA DESLAVADA','COZGMBDES34.jpg','63', '1'),"..
		"(966,'COZGMBDES35','GORRA DESLAVADA','COZGMBDES35.jpg','63', '1'),"..
		"(967,'COZGMBDES37','GORRA DESLAVADA','COZGMBDES37.jpg','63', '1'),"..
		"(968,'COZGMBFCU17','GORRA FIDEL CUADRO','COZGMBFCU17.jpg','76', '1'),"..
		"(969,'COZGMBFCU40','GORRA FIDEL CUADRO','COZGMBFCU40.jpg','76', '1'),"..
		"(970,'COZGMBFID29','GORRA FIDEL MILITAR','COZGMBFID29.jpg','76', '1'),"..
		"(971,'COZGMBFID30','GORRA FIDEL MILITAR','COZGMBFID30.jpg','76', '1'),"..
		"(972,'COZGMBFID37','GORRA FIDEL MILITAR','COZGMBFID37.jpg','76', '1'),"..
		"(973,'COZGMBFID66','GORRA FIDEL MILITAR','COZGMBFID66.jpg','76', '1'),"..
		"(974,'COZGMBNIÑ02','GORRA DESLAVADA NIÑO','COZGMBNIÑ02.jpg','63', '1'),"..
		"(975,'COZGMBNIÑ10','GORRA DESLAVADA NIÑO','COZGMBNIÑ10.jpg','63', '1'),"..
		"(976,'COZGMBNIÑ11','GORRA DESLAVADA NIÑO','COZGMBNIÑ11.jpg','63', '1'),"..
		"(977,'COZGMBNIÑ12','GORRA DESLAVADA NIÑO','COZGMBNIÑ12.jpg','63', '1'),"..
		"(978,'COZGMBNIÑ15','GORRA DESLAVADA NIÑO','COZGMBNIÑ15.jpg','63', '1'),"..
		"(979,'COZGMBOXF11','GORRA OXFORD','COZGMBOXF11.jpg','68', '1'),"..
		"(980,'COZGMBOXF13','GORRA OXFORD','COZGMBOXF13.jpg','68', '1'),"..
		"(981,'COZGMBOXF28','GORRA OXFORD','COZGMBOXF28.jpg','68', '1'),"..
		"(982,'COZGMBOXF30','GORRA OXFORD','COZGMBOXF30.jpg','68', '1'),"..
		"(983,'COZGMBOXF31','GORRA OXFORD','COZGMBOXF31.jpg','68', '1'),"..
		"(984,'COZGMBPES02','GORRA PESPUNTE','COZGMBPES02.jpg','68', '1'),"..
		"(985,'COZGMBPES11','GORRA PESPUNTE','COZGMBPES11.jpg','68', '1'),"..
		"(986,'COZGMBPES13','GORRA PESPUNTE','COZGMBPES13.jpg','68', '1'),"..
		"(987,'COZGMBPES28','GORRA PESPUNTE','COZGMBPES28.jpg','68', '1'),"..
		"(988,'COZGMBRAU11','GORRA RAUL','COZGMBRAU11.jpg','76', '1'),"..
		"(989,'COZGMBRAU13','GORRA RAUL','COZGMBRAU13.jpg','76', '1'),"..
		"(990,'COZGMBRAU28','GORRA RAUL','COZGMBRAU28.jpg','76', '1'),"..
		"(991,'COZGMBRAU30','GORRA RAUL','COZGMBRAU30.jpg','76', '1'),"..
		"(992,'COZGMBRAU31','GORRA RAUL','COZGMBRAU31.jpg','76', '1'),"..
		"(993,'COZGMBSAF03','GORRA SAFARI 7692 COZUMEL','COZGMBSAF03.jpg','76', '1'),"..
		"(994,'COZGMBSAF28','GORRA SAFARI 7692 COZUMEL','COZGMBSAF28.jpg','76', '1'),"..
		"(995,'COZGMBSAF30','GORRA SAFARI 7692 COZUMEL','COZGMBSAF30.jpg','76', '1'),"..
		"(996,'COZGMBSAN02','GORRA SANDWICH','COZGMBSAN02.jpg','68', '1'),"..
		"(997,'COZGMBSAN03','GORRA SANDWICH','COZGMBSAN03.jpg','68', '1'),"..
		"(998,'COZGMBSAN05','GORRA SANDWICH','COZGMBSAN05.jpg','68', '1'),"..
		"(999,'COZGMBSAN06','GORRA SANDWICH','COZGMBSAN06.jpg','68', '1'),"..
		"(1000,'COZGMBSAN07','GORRA SANDWICH','COZGMBSAN07.jpg','68', '1'),"..
		"(1001,'COZGMBSAN11','GORRA SANDWICH','COZGMBSAN11.jpg','68', '1'),"..
		"(1002,'COZGMBSAN13','GORRA SANDWICH','COZGMBSAN13.jpg','68', '1'),"..
		"(1003,'COZGMBSAN20','GORRA SANDWICH','COZGMBSAN20.jpg','68', '1'),"..
		"(1004,'COZGMBSAN22','GORRA SANDWICH','COZGMBSAN22.jpg','68', '1'),"..
		"(1005,'COZGMBSAN30','GORRA SANDWICH','COZGMBSAN30.jpg','68', '1'),"..
		"(1006,'COZGMBSAN32','GORRA SANDWICH','COZGMBSAN32.jpg','68', '1'),"..
		"(1007,'COZGMBSAN33','GORRA SANDWICH','COZGMBSAN33.jpg','68', '1'),"..
		"(1008,'COZGMBSAN36','GORRA SANDWICH','COZGMBSAN36.jpg','68', '1'),"..
		"(1009,'COZGMBSAN39','GORRA SANDWICH','COZGMBSAN39.jpg','68', '1'),"..
		"(1010,'COZGMBSAN43','GORRA SANDWICH','COZGMBSAN43.jpg','68', '1'),"..
		"(1011,'COZGMBSAN45','GORRA SANDWICH','COZGMBSAN45.jpg','68', '1'),"..
		"(1012,'COZGMBSAN49','GORRA SANDWICH','COZGMBSAN49.jpg','68', '1'),"..
		"(1013,'COZGMBSAN51','GORRA SANDWICH','COZGMBSAN51.jpg','68', '1'),"..
		"(1014,'COZGMBVIN202','GORRA VINTAGE','COZGMBVIN202.jpg','68', '1'),"..
		"(1015,'COZGMBVIN203','GORRA VINTAGE','COZGMBVIN203.jpg','68', '1'),"..
		"(1016,'COZGMBVIN208','GORRA VINTAGE','COZGMBVIN208.jpg','68', '1'),"..
		"(1017,'COZGMBVIN209','GORRA VINTAGE','COZGMBVIN209.jpg','68', '1'),"..
		"(1018,'COZGMBVIN211','GORRA VINTAGE','COZGMBVIN211.jpg','68', '1'),"..
		"(1019,'COZGMBVIN212','GORRA VINTAGE','COZGMBVIN212.jpg','68', '1'),"..
		"(1020,'COZGMBVIN213','GORRA VINTAGE','COZGMBVIN213.jpg','68', '1'),"..
		"(1021,'COZGMBVIN215','GORRA VINTAGE','COZGMBVIN215.jpg','68', '1'),"..
		"(1022,'COZGMBVIN216','GORRA VINTAGE','COZGMBVIN216.jpg','68', '1'),"..
		"(1023,'COZGMBVIN226','GORRA VINTAGE','COZGMBVIN226.jpg','68', '1'),"..
		"(1024,'COZGMBVIN228','GORRA VINTAGE','COZGMBVIN228.jpg','68', '1'),"..
		"(1025,'COZGMBVIN229','GORRA VINTAGE','COZGMBVIN229.jpg','68', '1'),"..
		"(1026,'COZGMBVIN230','GORRA VINTAGE','COZGMBVIN230.jpg','68', '1'),"..
		"(1027,'COZGMBVIN231','GORRA VINTAGE','COZGMBVIN231.jpg','68', '1'),"..
		"(1028,'COZGMBVIN237','GORRA VINTAGE','COZGMBVIN237.jpg','68', '1'),"..
		"(1029,'COZGMBVIN269','GORRA VINTAGE','COZGMBVIN269.jpg','68', '1'),"..
		"(1030,'COZGMBVIN270','GORRA VINTAGE','COZGMBVIN270.jpg','68', '1'),"..
		"(1031,'COZGMBVIN272','GORRA VINTAGE','COZGMBVIN272.jpg','68', '1'),"..
		"(1032,'COZGMBVIN302','GORRA DESLAVADA','COZGMBVIN302.jpg','63', '1'),"..
		"(1033,'COZGMBVIN303','GORRA DESLAVADA','COZGMBVIN303.jpg','63', '1'),"..
		"(1034,'COZGMBVIN305','GORRA DESLAVADA','COZGMBVIN305.jpg','63', '1'),"..
		"(1035,'COZGMBVIN306','GORRA DESLAVADA','COZGMBVIN306.jpg','63', '1'),"..
		"(1036,'COZGMBVIN309','GORRA DESLAVADA','COZGMBVIN309.jpg','63', '1'),"..
		"(1037,'COZGMBVIN310','GORRA DESLAVADA','COZGMBVIN310.jpg','63', '1'),"..
		"(1038,'COZGMBVIN311','GORRA DESLAVADA','COZGMBVIN311.jpg','63', '1'),"..
		"(1039,'COZGMBVIN312','GORRA DESLAVADA','COZGMBVIN312.jpg','63', '1'),"..
		"(1040,'COZGMBVIN313','GORRA DESLAVADA','COZGMBVIN313.jpg','63', '1'),"..
		"(1041,'COZGMBVIN314','GORRA DESLAVADA','COZGMBVIN314.jpg','63', '1'),"..
		"(1042,'COZGMBVIN315','GORRA DESLAVADA','COZGMBVIN315.jpg','63', '1'),"..
		"(1043,'COZGMBVIN316','GORRA DESLAVADA','COZGMBVIN316.jpg','63', '1'),"..
		"(1044,'COZGMBVIN321','GORRA DESLAVADA','COZGMBVIN321.jpg','63', '1'),"..
		"(1045,'COZGMBVIN325','GORRA DESLAVADA','COZGMBVIN325.jpg','63', '1'),"..
		"(1046,'COZGMBVIN326','GORRA DESLAVADA','COZGMBVIN326.jpg','63', '1'),"..
		"(1047,'COZGMBVIN328','GORRA DESLAVADA','COZGMBVIN328.jpg','63', '1'),"..
		"(1048,'COZGMBVIN329','GORRA DESLAVADA','COZGMBVIN329.jpg','63', '1'),"..
		"(1049,'COZGMBVIN330','GORRA DESLAVADA','COZGMBVIN330.jpg','63', '1'),"..
		"(1050,'COZGMBVIN331','GORRA DESLAVADA','COZGMBVIN331.jpg','63', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1051,'COZGMBVIN332','GORRA DESLAVADA','COZGMBVIN332.jpg','63', '1'),"..
		"(1052,'COZGMBVIN334','GORRA DESLAVADA','COZGMBVIN334.jpg','63', '1'),"..
		"(1053,'COZGMBVIN335','GORRA DESLAVADA','COZGMBVIN335.jpg','63', '1'),"..
		"(1054,'COZGMBVIN337','GORRA DESLAVADA','COZGMBVIN337.jpg','63', '1'),"..
		"(1055,'COZGMBVIN368','GORRA DESLAVADA','COZGMBVIN368.jpg','63', '1'),"..
		"(1056,'COZGMBVIT02','GORRA VINTAGE','COZGMBVIT02.jpg','68', '1'),"..
		"(1057,'COZGMBVIT03','GORRA VINTAGE','COZGMBVIT03.jpg','68', '1'),"..
		"(1058,'COZGMBVIT08','GORRA VINTAGE','COZGMBVIT08.jpg','68', '1'),"..
		"(1059,'COZGMBVIT09','GORRA VINTAGE','COZGMBVIT09.jpg','68', '1'),"..
		"(1060,'COZGMBVIT11','GORRA VINTAGE','COZGMBVIT11.jpg','68', '1'),"..
		"(1061,'COZGMBVIT12','GORRA VINTAGE','COZGMBVIT12.jpg','68', '1'),"..
		"(1062,'COZGMBVIT13','GORRA VINTAGE','COZGMBVIT13.jpg','68', '1'),"..
		"(1063,'COZGMBVIT15','GORRA VINTAGE','COZGMBVIT15.jpg','68', '1'),"..
		"(1064,'COZGMBVIT16','GORRA VINTAGE','COZGMBVIT16.jpg','68', '1'),"..
		"(1065,'COZGMBVIT17','GORRA VINTAGE','COZGMBVIT17.jpg','68', '1'),"..
		"(1066,'COZGMBVIT18','GORRA VINTAGE','COZGMBVIT18.jpg','68', '1'),"..
		"(1067,'COZGMBVIT26','GORRA VINTAGE','COZGMBVIT26.jpg','68', '1'),"..
		"(1068,'COZGMBVIT28','GORRA VINTAGE','COZGMBVIT28.jpg','68', '1'),"..
		"(1069,'COZGMBVIT29','GORRA VINTAGE','COZGMBVIT29.jpg','68', '1'),"..
		"(1070,'COZGMBVIT30','GORRA VINTAGE','COZGMBVIT30.jpg','68', '1'),"..
		"(1071,'COZGMBVIT31','GORRA VINTAGE','COZGMBVIT31.jpg','68', '1'),"..
		"(1072,'COZGMBVIT32','GORRA VINTAGE','COZGMBVIT32.jpg','68', '1'),"..
		"(1073,'COZGMBVIT37','GORRA VINTAGE','COZGMBVIT37.jpg','68', '1'),"..
		"(1074,'COZGMBVIT40','GORRA VINTAGE','COZGMBVIT40.jpg','68', '1'),"..
		"(1075,'COZGMBVIT69','GORRA VINTAGE','COZGMBVIT69.jpg','68', '1'),"..
		"(1076,'COZGMBVIT70','GORRA VINTAGE','COZGMBVIT70.jpg','68', '1'),"..
		"(1077,'COZGMBVIT71','GORRA VINTAGE','COZGMBVIT71.jpg','68', '1'),"..
		"(1078,'COZGMBVIT72','GORRA VINTAGE','COZGMBVIT72.jpg','68', '1'),"..
		"(1079,'COZGMBVIT73','GORRA VINTAGE','COZGMBVIT73.jpg','68', '1'),"..
		"(1080,'COZGMBVIT86','GORRA VINTAGE','COZGMBVIT86.jpg','68', '1'),"..
		"(1081,'COZGMBVIT87','GORRA VINTAGE','COZGMBVIT87.jpg','68', '1'),"..
		"(1082,'COZGMBVITQ','GORRA VINTAGE','COZGMBVITQ.jpg','68', '1'),"..
		"(1083,'CSLSMBGUI03','SOMBRERO GUILLIGAN','CSLSMBGUI03.jpg','73', '1'),"..
		"(1084,'CSLSMBGUI10','SOMBRERO GUILLIGAN','CSLSMBGUI10.jpg','73', '1'),"..
		"(1085,'CSLSMBGUI11','SOMBRERO GUILLIGAN','CSLSMBGUI11.jpg','73', '1'),"..
		"(1086,'CSLSMBGUI12','SOMBRERO GUILLIGAN','CSLSMBGUI12.jpg','73', '1'),"..
		"(1087,'CSLSMBGUI13','SOMBRERO GUILLIGAN','CSLSMBGUI13.jpg','73', '1'),"..
		"(1088,'CSLSMBGUI28','SOMBRERO GUILLIGAN','CSLSMBGUI28.jpg','73', '1'),"..
		"(1089,'CSLSMBGUI30','SOMBRERO GUILLIGAN','CSLSMBGUI30.jpg','73', '1'),"..
		"(1090,'CUNCCMCV04','COMANDO CON MANGA CAVIAR','CUNCCMCV04.jpg','50', '1'),"..
		"(1091,'CUNCCMCV18','COMANDO CON MANGA CAVIAR','CUNCCMCV18.jpg','50', '1'),"..
		"(1092,'CUNCCMCV29','COMANDO CON MANGA CAVIAR','CUNCCMCV29.jpg','50', '1'),"..
		"(1093,'CUNCOA001','COMBO ADULTO ESTRELLAS CANCUN','CUNCOA001.jpg','110', '1'),"..
		"(1094,'CUNCOA001XXL','COMBO ADULTO ESTRELLAS CANCUN','CUNCOA001XXL.jpg','110', '1'),"..
		"(1095,'CUNCOA002','COMBO ADULTO FIRMA CANCUN','CUNCOA002.jpg','99', '1'),"..
		"(1096,'CUNCOA002XXL','COMBO ADULTO FIRMA CANCUN','CUNCOA002XXL.jpg','110', '1'),"..
		"(1097,'CUNCOA00311','COMBO ADULTO FIRMA PREMIER','CUNCOA00311.jpg','99', '1'),"..
		"(1098,'CUNCOA00328','COMBO ADULTO FIRMA PREMIER','CUNCOA00328.jpg','99', '1'),"..
		"(1099,'CUNCOA00330','COMBO ADULTO FIRMA PREMIER','CUNCOA00330.jpg','99', '1'),"..
		"(1100,'CUNCOA003XXL11','COMBO ADULTO FIRMA PREMIER','CUNCOA003XXL11.jpg','110', '1'),"..
		"(1101,'CUNCOA003XXL28','COMBO ADULTO FIRMA PREMIER','CUNCOA003XXL28.jpg','110', '1'),"..
		"(1102,'CUNCOA003XXL30','COMBO ADULTO FIRMA PREMIER','CUNCOA003XXL30.jpg','110', '1'),"..
		"(1103,'CUNCOA00402','COMBO ADULTO ESCUDO CANCUN','CUNCOA00402.jpg','99', '1'),"..
		"(1104,'CUNCOA00411','COMBO ADULTO ESCUDO CANCUN','CUNCOA00411.jpg','99', '1'),"..
		"(1105,'CUNCOA00413','COMBO ADULTO ESCUDO CANCUN','CUNCOA00413.jpg','99', '1'),"..
		"(1106,'CUNCOA004XXL02','COMBO ADULTO ESCUDO CANCUN','CUNCOA004XXL02.jpg','110', '1'),"..
		"(1107,'CUNCOA004XXL11','COMBO ADULTO ESCUDO CANCUN','CUNCOA004XXL11.jpg','110', '1'),"..
		"(1108,'CUNCOA004XXL13','COMBO ADULTO ESCUDO CANCUN','CUNCOA004XXL13.jpg','110', '1'),"..
		"(1109,'CUNCOA00502','COMBO ADULTO INSTITUCIONAL','CUNCOA00502.jpg','99', '1'),"..
		"(1110,'CUNCOA00510','COMBO ADULTO INSTITUCIONAL','CUNCOA00510.jpg','99', '1'),"..
		"(1111,'CUNCOA00511','COMBO ADULTO INSTITUCIONAL','CUNCOA00511.jpg','99', '1'),"..
		"(1112,'CUNCOA00512','COMBO ADULTO INSTITUCIONAL','CUNCOA00512.jpg','99', '1'),"..
		"(1113,'CUNCOA00515','COMBO ADULTO INSTITUCIONAL','CUNCOA00515.jpg','99', '1'),"..
		"(1114,'CUNCOA00521','COMBO ADULTO INSTITUCIONAL','CUNCOA00521.jpg','99', '1'),"..
		"(1115,'CUNCOA00526','COMBO ADULTO INSTITUCIONAL','CUNCOA00526.jpg','99', '1'),"..
		"(1116,'CUNCOA00528','COMBO ADULTO INSTITUCIONAL','CUNCOA00528.jpg','99', '1'),"..
		"(1117,'CUNCOA00530','COMBO ADULTO INSTITUCIONAL','CUNCOA00530.jpg','99', '1'),"..
		"(1118,'CUNCOA00532','COMBO ADULTO INSTITUCIONAL','CUNCOA00532.jpg','99', '1'),"..
		"(1119,'CUNCOA005XXL02','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL02.jpg','110', '1'),"..
		"(1120,'CUNCOA005XXL10','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL10.jpg','110', '1'),"..
		"(1121,'CUNCOA005XXL11','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL11.jpg','110', '1'),"..
		"(1122,'CUNCOA005XXL12','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL12.jpg','110', '1'),"..
		"(1123,'CUNCOA005XXL15','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL15.jpg','110', '1'),"..
		"(1124,'CUNCOA005XXL21','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL21.jpg','110', '1'),"..
		"(1125,'CUNCOA005XXL26','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL26.jpg','110', '1'),"..
		"(1126,'CUNCOA005XXL28','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL28.jpg','110', '1'),"..
		"(1127,'CUNCOA005XXL30','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL30.jpg','110', '1'),"..
		"(1128,'CUNCOA005XXL32','COMBO ADULTO INSTITUCIONAL','CUNCOA005XXL32.jpg','110', '1'),"..
		"(1129,'CUNCOA01502','COMBO BASICO ADULTO','CUNCOA01502.jpg','85', '1'),"..
		"(1130,'CUNCOA01511','COMBO BASICO ADULTO','CUNCOA01511.jpg','85', '1'),"..
		"(1131,'CUNCOA015XXL02','COMBO BASICO ADULTO','CUNCOA015XXL02.jpg','85', '1'),"..
		"(1132,'CUNCOA015XXL11','COMBO BASICO ADULTO','CUNCOA015XXL11.jpg','85', '1'),"..
		"(1133,'CUNCOA02012','COMBO ADULTO NEON','CUNCOA02012.jpg','99', '1'),"..
		"(1134,'CUNCOA02017','COMBO ADULTO NEON','CUNCOA02017.jpg','99', '1'),"..
		"(1135,'CUNCOA02018','COMBO ADULTO NEON','CUNCOA02018.jpg','99', '1'),"..
		"(1136,'CUNCOA02071','COMBO ADULTO NEON','CUNCOA02071.jpg','99', '1'),"..
		"(1137,'CUNCOA13','COMBO ADULTO FIRMA KAKY','CUNCOA13.jpg','99', '1'),"..
		"(1138,'CUNCOA13XXL','COMBO ADULTO FIRMA KAKY','CUNCOA13XXL.jpg','110', '1'),"..
		"(1139,'CUNCOD00129','COMBO DAMA CHANCLITAS','CUNCOD00129.jpg','99', '1'),"..
		"(1140,'CUNCOD00204','COMBO DAMA PIEDRITAS','CUNCOD00204.jpg','99', '1'),"..
		"(1141,'CUNCOD00212','COMBO DAMA PIEDRITAS','CUNCOD00212.jpg','99', '1'),"..
		"(1142,'CUNCOD00217','COMBO DAMA PIEDRITAS','CUNCOD00217.jpg','99', '1'),"..
		"(1143,'CUNCOD00218','COMBO DAMA PIEDRITAS','CUNCOD00218.jpg','99', '1'),"..
		"(1144,'CUNCOD00219','COMBO DAMA PIEDRITAS','CUNCOD00219.jpg','99', '1'),"..
		"(1145,'CUNCOD00223','COMBO DAMA PIEDRITAS','CUNCOD00223.jpg','99', '1'),"..
		"(1146,'CUNCOD00240','COMBO DAMA PIEDRITAS','CUNCOD00240.jpg','99', '1'),"..
		"(1147,'CUNCOD00242','COMBO DAMA PIEDRITAS','CUNCOD00242.jpg','99', '1'),"..
		"(1148,'CUNCOD01540','COMBO BASICO DAMA','CUNCOD01540.jpg','85', '1'),"..
		"(1149,'CUNCOD01571','COMBO BASICO DAMA','CUNCOD01571.jpg','85', '1'),"..
		"(1150,'CUNCON001','COMBO NIÑO GEKO MOSCO','CUNCON001.jpg','94', '1'),"..
		"(1151,'CUNCON002','COMBO NIÑO IGUANA TABLA','CUNCON002.jpg','94', '1'),"..
		"(1152,'CUNCSMCV04','COMANDOSIN MANGA CAVIAR','CUNCSMCV04.jpg','50', '1'),"..
		"(1153,'CUNCSMCV18','COMANDOSIN MANGA CAVIAR','CUNCSMCV18.jpg','50', '1'),"..
		"(1154,'CUNCSMCV29','COMANDOSIN MANGA CAVIAR','CUNCSMCV29.jpg','50', '1'),"..
		"(1155,'CUNGDKBBE03','GORRA BEBE','CUNGDKBBE03.jpg','47', '1'),"..
		"(1156,'CUNGDKBBE04','GORRA BEBE','CUNGDKBBE04.jpg','47', '1'),"..
		"(1157,'CUNGDKBBE10','GORRA BEBE','CUNGDKBBE10.jpg','47', '1'),"..
		"(1158,'CUNGDKBBE12','GORRA BEBE','CUNGDKBBE12.jpg','47', '1'),"..
		"(1159,'CUNGDKBBE29','GORRA BEBE','CUNGDKBBE29.jpg','47', '1'),"..
		"(1160,'CUNGDKDES11','GORRA DESTAPADOR','CUNGDKDES11.jpg','63', '1'),"..
		"(1161,'CUNGDKDES13','GORRA DESTAPADOR','CUNGDKDES13.jpg','63', '1'),"..
		"(1162,'CUNGDKPLU12','GORRA PLUS CANCUN','CUNGDKPLU12.jpg','68', '1'),"..
		"(1163,'CUNGDKPLU17','GORRA PLUS CANCUN','CUNGDKPLU17.jpg','68', '1'),"..
		"(1164,'CUNGDKPLU18','GORRA PLUS CANCUN','CUNGDKPLU18.jpg','68', '1'),"..
		"(1165,'CUNGDKPLU40','GORRA PLUS CANCUN','CUNGDKPLU40.jpg','68', '1'),"..
		"(1166,'CUNGDKPLU71','GORRA PLUS CANCUN','CUNGDKPLU71.jpg','68', '1'),"..
		"(1167,'CUNGGE001','GORRA GENERICA 2 TORTUGAS NADANDO','CUNGGE001.jpg','68', '1'),"..
		"(1168,'CUNGGE002','GORRA GENERICA PARCHE KAKY','CUNGGE002.jpg','68', '1'),"..
		"(1169,'CUNGGE003','GORRA GENERICA PIRATAS','CUNGGE003.jpg','68', '1'),"..
		"(1170,'CUNGGE004','GORRA GENERICA TRES PALMERAS','CUNGGE004.jpg','68', '1'),"..
		"(1171,'CUNGGE005','GORRA GENERICA PESPUNTE RAYADA','CUNGGE005.jpg','68', '1'),"..
		"(1172,'CUNGGE006','GORRA GENERICA PALMERAS COMBI','CUNGGE006.jpg','68', '1'),"..
		"(1173,'CUNGGE007','GORRA GENERICA PARCHE MILITAR','CUNGGE007.jpg','68', '1'),"..
		"(1174,'CUNGGE008','GORRA GENERICA APLICACION AGUILA.','CUNGGE008.jpg','68', '1'),"..
		"(1175,'CUNGGE009','GORRA GENERICA BORDADO METALICO','CUNGGE009.jpg','68', '1'),"..
		"(1176,'CUNGGE010','GORRA GENERICA 3 GEKOS OVALO','CUNGGE010.jpg','68', '1'),"..
		"(1177,'CUNGGE013','GORRA GENERICA DRAGON CHINO','CUNGGE013.jpg','68', '1'),"..
		"(1178,'CUNGGE019','GORRA GENERICA FLOR CON ZIG-ZAG','CUNGGE019.jpg','68', '1'),"..
		"(1179,'CUNGGE020','GORRA GENERICA 3 ESTRELLAS','CUNGGE020.jpg','68', '1'),"..
		"(1180,'CUNGGE021','GORRA GENERICA 3 ESTRELLAS','CUNGGE021.jpg','68', '1'),"..
		"(1181,'CUNGGE022','GORRA GENERICA COMBINACION','CUNGGE022.jpg','68', '1'),"..
		"(1182,'CUNGGE023','GORRA GENERICA COMBINACION','CUNGGE023.jpg','68', '1'),"..
		"(1183,'CUNGGE025','GORRA GENERICA TIBURON BUCEO','CUNGGE025.jpg','68', '1'),"..
		"(1184,'CUNGGE026','GORRA GENERICA TIBURON BUCEO','CUNGGE026.jpg','68', '1'),"..
		"(1185,'CUNGMBARC04','GORRA ARCOIRIS','CUNGMBARC04.jpg','68', '1'),"..
		"(1186,'CUNGMBARC18','GORRA ARCOIRIS','CUNGMBARC18.jpg','68', '1'),"..
		"(1187,'CUNGMBARC29','GORRA ARCOIRIS','CUNGMBARC29.jpg','68', '1'),"..
		"(1188,'CUNGMBBAS04','GORRA BASICA CANCUN','CUNGMBBAS04.jpg','43', '1'),"..
		"(1189,'CUNGMBBAS05','GORRA BASICA CANCUN','CUNGMBBAS05.jpg','43', '1'),"..
		"(1190,'CUNGMBBAS11','GORRA BASICA CANCUN','CUNGMBBAS11.jpg','43', '1'),"..
		"(1191,'CUNGMBBAS12','GORRA BASICA CANCUN','CUNGMBBAS12.jpg','43', '1'),"..
		"(1192,'CUNGMBBAS28','GORRA BASICA CANCUN','CUNGMBBAS28.jpg','43', '1'),"..
		"(1193,'CUNGMBBAS30','GORRA BASICA CANCUN','CUNGMBBAS30.jpg','43', '1'),"..
		"(1194,'CUNGMBBAS03','GORRA BASICA CANCUN','CUNGMBBAS03.jpg','43', '1'),"..
		"(1195,'CUNGMBBAS71','GORRA BASICA CANCUN','CUNGMBBAS71.jpg','43', '1'),"..
		"(1196,'CUNGMBBAS17','GORRA BASICA CANCUN','CUNGMBBAS17.jpg','43', '1'),"..
		"(1197,'CUNGMBBAS13','GORRA BASICA CANCUN','CUNGMBBAS13.jpg','43', '1'),"..
		"(1198,'CUNGMBBAS16','GORRA BASICA CANCUN','CUNGMBBAS16.jpg','43', '1'),"..
		"(1199,'CUNGMBBAS74','GORRA BASICA CANCUN','CUNGMBBAS74.jpg','43', '1'),"..
		"(1200,'CUNGMBBAS02','GORRA BASICA CANCUN','CUNGMBBAS02.jpg','43', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1201,'CUNGMBBCA10','GORRA BASICA CAMBAS CANCUN','CUNGMBBCA10.jpg','68', '1'),"..
		"(1202,'CUNGMBBCA12','GORRA BASICA CAMBAS CANCUN','CUNGMBBCA12.jpg','68', '1'),"..
		"(1203,'CUNGMBCAM13','GORRA CAMBAS','CUNGMBCAM13.jpg','68', '1'),"..
		"(1204,'CUNGMBCAM26','GORRA CAMBAS','CUNGMBCAM26.jpg','68', '1'),"..
		"(1205,'CUNGMBCAM32','GORRA CAMBAS','CUNGMBCAM32.jpg','68', '1'),"..
		"(1206,'CUNGMBCAZ09','GORRA CAZADOR','CUNGMBCAZ09.jpg','76', '1'),"..
		"(1207,'CUNGMBCAZ11','GORRA CAZADOR','CUNGMBCAZ11.jpg','76', '1'),"..
		"(1208,'CUNGMBCAZ30','GORRA CAZADOR','CUNGMBCAZ30.jpg','76', '1'),"..
		"(1209,'CUNGMBDAM04','GORRA DAMA','CUNGMBDAM04.jpg','63', '1'),"..
		"(1210,'CUNGMBDAM12','GORRA DAMA','CUNGMBDAM12.jpg','63', '1'),"..
		"(1211,'CUNGMBDAM17','GORRA DAMA','CUNGMBDAM17.jpg','63', '1'),"..
		"(1212,'CUNGMBDAM18','GORRA DAMA','CUNGMBDAM18.jpg','63', '1'),"..
		"(1213,'CUNGMBDAM19','GORRA DAMA','CUNGMBDAM19.jpg','63', '1'),"..
		"(1214,'CUNGMBDAM23','GORRA DAMA','CUNGMBDAM23.jpg','63', '1'),"..
		"(1215,'CUNGMBDAM29','GORRA DAMA','CUNGMBDAM29.jpg','63', '1'),"..
		"(1216,'CUNGMBDAM40','GORRA DAMA','CUNGMBDAM40.jpg','63', '1'),"..
		"(1217,'CUNGMBDAM41','GORRA DAMA','CUNGMBDAM41.jpg','63', '1'),"..
		"(1218,'CUNGMBDAM42','GORRA DAMA','CUNGMBDAM42.jpg','63', '1'),"..
		"(1219,'CUNGMBDES02','GORRA DESLAVADA','CUNGMBDES02.jpg','63', '1'),"..
		"(1220,'CUNGMBDES04','GORRA DESLAVADA','CUNGMBDES04.jpg','63', '1'),"..
		"(1221,'CUNGMBDES05','GORRA DESLAVADA','CUNGMBDES05.jpg','63', '1'),"..
		"(1222,'CUNGMBDES06','GORRA DESLAVADA','CUNGMBDES06.jpg','63', '1'),"..
		"(1223,'CUNGMBDES09','GORRA DESLAVADA','CUNGMBDES09.jpg','63', '1'),"..
		"(1224,'CUNGMBDES10','GORRA DESLAVADA','CUNGMBDES10.jpg','63', '1'),"..
		"(1225,'CUNGMBDES11','GORRA DESLAVADA','CUNGMBDES11.jpg','63', '1'),"..
		"(1226,'CUNGMBDES12','GORRA DESLAVADA','CUNGMBDES12.jpg','63', '1'),"..
		"(1227,'CUNGMBDES13','GORRA DESLAVADA','CUNGMBDES13.jpg','63', '1'),"..
		"(1228,'CUNGMBDES15','GORRA DESLAVADA','CUNGMBDES15.jpg','63', '1'),"..
		"(1229,'CUNGMBDES16','GORRA DESLAVADA','CUNGMBDES16.jpg','63', '1'),"..
		"(1230,'CUNGMBDES17','GORRA DESLAVADA','CUNGMBDES17.jpg','63', '1'),"..
		"(1231,'CUNGMBDES21','GORRA DESLAVADA','CUNGMBDES21.jpg','63', '1'),"..
		"(1232,'CUNGMBDES25','GORRA DESLAVADA','CUNGMBDES25.jpg','63', '1'),"..
		"(1233,'CUNGMBDES26','GORRA DESLAVADA','CUNGMBDES26.jpg','63', '1'),"..
		"(1234,'CUNGMBDES28','GORRA DESLAVADA','CUNGMBDES28.jpg','63', '1'),"..
		"(1235,'CUNGMBDES29','GORRA DESLAVADA','CUNGMBDES29.jpg','63', '1'),"..
		"(1236,'CUNGMBDES30','GORRA DESLAVADA','CUNGMBDES30.jpg','63', '1'),"..
		"(1237,'CUNGMBDES31','GORRA DESLAVADA','CUNGMBDES31.jpg','63', '1'),"..
		"(1238,'CUNGMBDES32','GORRA DESLAVADA','CUNGMBDES32.jpg','63', '1'),"..
		"(1239,'CUNGMBDES34','GORRA DESLAVADA','CUNGMBDES34.jpg','63', '1'),"..
		"(1240,'CUNGMBDES35','GORRA DESLAVADA','CUNGMBDES35.jpg','63', '1'),"..
		"(1241,'CUNGMBDES37','GORRA DESLAVADA','CUNGMBDES37.jpg','63', '1'),"..
		"(1242,'CUNGMBDES68','GORRA DESLAVADA','CUNGMBDES68.jpg','63', '1'),"..
		"(1243,'CUNGMBDES74','GORRA DESLAVADA','CUNGMBDES74.jpg','63', '1'),"..
		"(1244,'CUNGMBFCU17','GORRA FIDEL CUADRO','CUNGMBFCU17.jpg','76', '1'),"..
		"(1245,'CUNGMBFCU40','GORRA FIDEL CUADRO','CUNGMBFCU40.jpg','76', '1'),"..
		"(1246,'CUNGMBFID11','GORRA FIDEL MILITAR','CUNGMBFID11.jpg','76', '1'),"..
		"(1247,'CUNGMBFID13','GORRA FIDEL MILITAR','CUNGMBFID13.jpg','76', '1'),"..
		"(1248,'CUNGMBFID17','GORRA FIDEL MILITAR','CUNGMBFID17.jpg','76', '1'),"..
		"(1249,'CUNGMBFID28','GORRA FIDEL MILITAR','CUNGMBFID28.jpg','76', '1'),"..
		"(1250,'CUNGMBFID29','GORRA FIDEL MILITAR','CUNGMBFID29.jpg','76', '1'),"..
		"(1251,'CUNGMBFID30','GORRA FIDEL MILITAR','CUNGMBFID30.jpg','76', '1'),"..
		"(1252,'CUNGMBFID37','GORRA FIDEL MILITAR','CUNGMBFID37.jpg','76', '1'),"..
		"(1253,'CUNGMBFID40','GORRA FIDEL MILITAR','CUNGMBFID40.jpg','76', '1'),"..
		"(1254,'CUNGMBFID66','GORRA FIDEL MILITAR','CUNGMBFID66.jpg','76', '1'),"..
		"(1255,'CUNGMBFID71','GORRA FIDEL MILITAR','CUNGMBFID71.jpg','76', '1'),"..
		"(1256,'CUNGMBNIÑ02','GORRA DESLAVADA NIÑO','CUNGMBNIÑ02.jpg','63', '1'),"..
		"(1257,'CUNGMBNIÑ10','GORRA DESLAVADA NIÑO','CUNGMBNIÑ10.jpg','59', '1'),"..
		"(1258,'CUNGMBNIÑ11','GORRA DESLAVADA NIÑO','CUNGMBNIÑ11.jpg','59', '1'),"..
		"(1259,'CUNGMBNIÑ12','GORRA DESLAVADA NIÑO','CUNGMBNIÑ12.jpg','59', '1'),"..
		"(1260,'CUNGMBNIÑ15','GORRA DESLAVADA NIÑO','CUNGMBNIÑ15.jpg','59', '1'),"..
		"(1261,'CUNGMBNIÑ26','GORRA DESLAVADA NIÑO','CUNGMBNIÑ26.jpg','59', '1'),"..
		"(1262,'CUNGMBNMA62','GORRA NIÑA MARIPOSA','CUNGMBNMA62.jpg','68', '1'),"..
		"(1263,'CUNGMBNMA63','GORRA NIÑA MARIPOSA','CUNGMBNMA63.jpg','68', '1'),"..
		"(1264,'CUNGMBNMA64','GORRA NIÑA MARIPOSA','CUNGMBNMA64.jpg','68', '1'),"..
		"(1265,'CUNGMBNMA65','GORRA NIÑA MARIPOSA','CUNGMBNMA65.jpg','68', '1'),"..
		"(1266,'CUNGMBOXF02','GORRA OXFORD','CUNGMBOXF02.jpg','68', '1'),"..
		"(1267,'CUNGMBOXF11','GORRA OXFORD','CUNGMBOXF11.jpg','68', '1'),"..
		"(1268,'CUNGMBOXF13','GORRA OXFORD','CUNGMBOXF13.jpg','68', '1'),"..
		"(1269,'CUNGMBOXF28','GORRA OXFORD','CUNGMBOXF28.jpg','68', '1'),"..
		"(1270,'CUNGMBOXF30','GORRA OXFORD','CUNGMBOXF30.jpg','68', '1'),"..
		"(1271,'CUNGMBOXF31','GORRA OXFORD','CUNGMBOXF31.jpg','68', '1'),"..
		"(1272,'CUNGMBOXF37','GORRA OXFORD','CUNGMBOXF37.jpg','68', '1'),"..
		"(1273,'CUNGMBPES02','GORRA PESPUNTE','CUNGMBPES02.jpg','68', '1'),"..
		"(1274,'CUNGMBPES11','GORRA PESPUNTE','CUNGMBPES11.jpg','68', '1'),"..
		"(1275,'CUNGMBPES13','GORRA PESPUNTE','CUNGMBPES13.jpg','68', '1'),"..
		"(1276,'CUNGMBPES28','GORRA PESPUNTE','CUNGMBPES28.jpg','68', '1'),"..
		"(1277,'CUNGMBPES31','GORRA PESPUNTE','CUNGMBPES31.jpg','68', '1'),"..
		"(1278,'CUNGMBRAU11','GORRA RAUL','CUNGMBRAU11.jpg','76', '1'),"..
		"(1279,'CUNGMBRAU13','GORRA RAUL','CUNGMBRAU13.jpg','76', '1'),"..
		"(1280,'CUNGMBRAU28','GORRA RAUL','CUNGMBRAU28.jpg','76', '1'),"..
		"(1281,'CUNGMBRAU29','GORRA RAUL','CUNGMBRAU29.jpg','76', '1'),"..
		"(1282,'CUNGMBRAU30','GORRA RAUL','CUNGMBRAU30.jpg','76', '1'),"..
		"(1283,'CUNGMBRAU31','GORRA RAUL','CUNGMBRAU31.jpg','76', '1'),"..
		"(1284,'CUNGMBRAU66','GORRA RAUL','CUNGMBRAU66.jpg','76', '1'),"..
		"(1285,'CUNGMBSAF03','GORRA SAFARI','CUNGMBSAF03.jpg','76', '1'),"..
		"(1286,'CUNGMBSAF28','GORRA SAFARI','CUNGMBSAF28.jpg','76', '1'),"..
		"(1287,'CUNGMBSAF30','GORRA SAFARI','CUNGMBSAF30.jpg','76', '1'),"..
		"(1288,'CUNGMBSAN02','GORRA SANDWICH','CUNGMBSAN02.jpg','68', '1'),"..
		"(1289,'CUNGMBSAN03','GORRA SANDWICH','CUNGMBSAN03.jpg','68', '1'),"..
		"(1290,'CUNGMBSAN04','GORRA SANDWICH','CUNGMBSAN04.jpg','68', '1'),"..
		"(1291,'CUNGMBSAN05','GORRA SANDWICH','CUNGMBSAN05.jpg','68', '1'),"..
		"(1292,'CUNGMBSAN07','GORRA SANDWICH','CUNGMBSAN07.jpg','68', '1'),"..
		"(1293,'CUNGMBSAN11','GORRA SANDWICH','CUNGMBSAN11.jpg','68', '1'),"..
		"(1294,'CUNGMBSAN13','GORRA SANDWICH','CUNGMBSAN13.jpg','68', '1'),"..
		"(1295,'CUNGMBSAN20','GORRA SANDWICH','CUNGMBSAN20.jpg','68', '1'),"..
		"(1296,'CUNGMBSAN22','GORRA SANDWICH','CUNGMBSAN22.jpg','68', '1'),"..
		"(1297,'CUNGMBSAN30','GORRA SANDWICH','CUNGMBSAN30.jpg','68', '1'),"..
		"(1298,'CUNGMBSAN32','GORRA SANDWICH','CUNGMBSAN32.jpg','68', '1'),"..
		"(1299,'CUNGMBSAN33','GORRA SANDWICH','CUNGMBSAN33.jpg','68', '1'),"..
		"(1300,'CUNGMBSAN36','GORRA SANDWICH','CUNGMBSAN36.jpg','68', '1'),"..
		"(1301,'CUNGMBSAN39','GORRA SANDWICH','CUNGMBSAN39.jpg','68', '1'),"..
		"(1302,'CUNGMBSAN43','GORRA SANDWICH','CUNGMBSAN43.jpg','68', '1'),"..
		"(1303,'CUNGMBSAN45','GORRA SANDWICH','CUNGMBSAN45.jpg','68', '1'),"..
		"(1304,'CUNGMBSAN47','GORRA SANDWICH','CUNGMBSAN47.jpg','68', '1'),"..
		"(1305,'CUNGMBSAN49','GORRA SANDWICH','CUNGMBSAN49.jpg','68', '1'),"..
		"(1306,'CUNGMBSAN51','GORRA SANDWICH','CUNGMBSAN51.jpg','68', '1'),"..
		"(1307,'CUNGMBSAN83','GORRA SANDWICH','CUNGMBSAN83.jpg','68', '1'),"..
		"(1308,'CUNGMBVIN202','GORRA VINTAGE','CUNGMBVIN202.jpg','68', '1'),"..
		"(1309,'CUNGMBVIN203','GORRA VINTAGE','CUNGMBVIN203.jpg','68', '1'),"..
		"(1310,'CUNGMBVIN208','GORRA VINTAGE','CUNGMBVIN208.jpg','68', '1'),"..
		"(1311,'CUNGMBVIN209','GORRA VINTAGE','CUNGMBVIN209.jpg','68', '1'),"..
		"(1312,'CUNGMBVIN211','GORRA VINTAGE','CUNGMBVIN211.jpg','68', '1'),"..
		"(1313,'CUNGMBVIN212','GORRA VINTAGE','CUNGMBVIN212.jpg','68', '1'),"..
		"(1314,'CUNGMBVIN213','GORRA VINTAGE','CUNGMBVIN213.jpg','68', '1'),"..
		"(1315,'CUNGMBVIN215','GORRA VINTAGE','CUNGMBVIN215.jpg','68', '1'),"..
		"(1316,'CUNGMBVIN216','GORRA VINTAGE','CUNGMBVIN216.jpg','68', '1'),"..
		"(1317,'CUNGMBVIN226','GORRA VINTAGE','CUNGMBVIN226.jpg','68', '1'),"..
		"(1318,'CUNGMBVIN228','GORRA VINTAGE','CUNGMBVIN228.jpg','68', '1'),"..
		"(1319,'CUNGMBVIN229','GORRA VINTAGE','CUNGMBVIN229.jpg','68', '1'),"..
		"(1320,'CUNGMBVIN230','GORRA VINTAGE','CUNGMBVIN230.jpg','68', '1'),"..
		"(1321,'CUNGMBVIN231','GORRA VINTAGE','CUNGMBVIN231.jpg','68', '1'),"..
		"(1322,'CUNGMBVIN237','GORRA VINTAGE','CUNGMBVIN237.jpg','68', '1'),"..
		"(1323,'CUNGMBVIN269','GORRA VINTAGE','CUNGMBVIN269.jpg','68', '1'),"..
		"(1324,'CUNGMBVIN270','GORRA VINTAGE','CUNGMBVIN270.jpg','68', '1'),"..
		"(1325,'CUNGMBVIN272','GORRA VINTAGE','CUNGMBVIN272.jpg','68', '1'),"..
		"(1326,'CUNGMBVIN302','GORRA DESLAVADA','CUNGMBVIN302.jpg','63', '1'),"..
		"(1327,'CUNGMBVIN303','GORRA DESLAVADA','CUNGMBVIN303.jpg','63', '1'),"..
		"(1328,'CUNGMBVIN305','GORRA DESLAVADA','CUNGMBVIN305.jpg','63', '1'),"..
		"(1329,'CUNGMBVIN306','GORRA DESLAVADA','CUNGMBVIN306.jpg','63', '1'),"..
		"(1330,'CUNGMBVIN309','GORRA DESLAVADA','CUNGMBVIN309.jpg','63', '1'),"..
		"(1331,'CUNGMBVIN310','GORRA DESLAVADA','CUNGMBVIN310.jpg','63', '1'),"..
		"(1332,'CUNGMBVIN311','GORRA DESLAVADA','CUNGMBVIN311.jpg','63', '1'),"..
		"(1333,'CUNGMBVIN312','GORRA DESLAVADA','CUNGMBVIN312.jpg','63', '1'),"..
		"(1334,'CUNGMBVIN313','GORRA DESLAVADA','CUNGMBVIN313.jpg','63', '1'),"..
		"(1335,'CUNGMBVIN314','GORRA DESLAVADA','CUNGMBVIN314.jpg','63', '1'),"..
		"(1336,'CUNGMBVIN315','GORRA DESLAVADA','CUNGMBVIN315.jpg','63', '1'),"..
		"(1337,'CUNGMBVIN316','GORRA DESLAVADA','CUNGMBVIN316.jpg','63', '1'),"..
		"(1338,'CUNGMBVIN321','GORRA DESLAVADA','CUNGMBVIN321.jpg','63', '1'),"..
		"(1339,'CUNGMBVIN325','GORRA DESLAVADA','CUNGMBVIN325.jpg','63', '1'),"..
		"(1340,'CUNGMBVIN326','GORRA DESLAVADA','CUNGMBVIN326.jpg','63', '1'),"..
		"(1341,'CUNGMBVIN328','GORRA DESLAVADA','CUNGMBVIN328.jpg','63', '1'),"..
		"(1342,'CUNGMBVIN329','GORRA DESLAVADA','CUNGMBVIN329.jpg','63', '1'),"..
		"(1343,'CUNGMBVIN330','GORRA DESLAVADA','CUNGMBVIN330.jpg','63', '1'),"..
		"(1344,'CUNGMBVIN331','GORRA DESLAVADA','CUNGMBVIN331.jpg','63', '1'),"..
		"(1345,'CUNGMBVIN332','GORRA DESLAVADA','CUNGMBVIN332.jpg','63', '1'),"..
		"(1346,'CUNGMBVIN334','GORRA DESLAVADA','CUNGMBVIN334.jpg','63', '1'),"..
		"(1347,'CUNGMBVIN335','GORRA DESLAVADA','CUNGMBVIN335.jpg','63', '1'),"..
		"(1348,'CUNGMBVIN337','GORRA DESLAVADA','CUNGMBVIN337.jpg','63', '1'),"..
		"(1349,'CUNGMBVIN368','GORRA DESLAVADA','CUNGMBVIN368.jpg','63', '1'),"..
		"(1350,'CUNGMBVIN403','GORRA VINTAGE','CUNGMBVIN403.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1351,'CUNGMBVIN452','GORRA VINTAGE','CUNGMBVIN452.jpg','68', '1'),"..
		"(1352,'CUNGMBVIN457','GORRA VINTAGE','CUNGMBVIN457.jpg','68', '1'),"..
		"(1353,'CUNGMBVIT02','GORRA VINTAGE','CUNGMBVIT02.jpg','68', '1'),"..
		"(1354,'CUNGMBVIT03','GORRA VINTAGE','CUNGMBVIT03.jpg','68', '1'),"..
		"(1355,'CUNGMBVIT08','GORRA VINTAGE','CUNGMBVIT08.jpg','68', '1'),"..
		"(1356,'CUNGMBVIT09','GORRA VINTAGE','CUNGMBVIT09.jpg','68', '1'),"..
		"(1357,'CUNGMBVIT11','GORRA VINTAGE','CUNGMBVIT11.jpg','68', '1'),"..
		"(1358,'CUNGMBVIT12','GORRA VINTAGE','CUNGMBVIT12.jpg','68', '1'),"..
		"(1359,'CUNGMBVIT13','GORRA VINTAGE','CUNGMBVIT13.jpg','68', '1'),"..
		"(1360,'CUNGMBVIT15','GORRA VINTAGE','CUNGMBVIT15.jpg','68', '1'),"..
		"(1361,'CUNGMBVIT16','GORRA VINTAGE','CUNGMBVIT16.jpg','68', '1'),"..
		"(1362,'CUNGMBVIT17','GORRA VINTAGE','CUNGMBVIT17.jpg','68', '1'),"..
		"(1363,'CUNGMBVIT18','GORRA VINTAGE','CUNGMBVIT18.jpg','68', '1'),"..
		"(1364,'CUNGMBVIT26','GORRA VINTAGE','CUNGMBVIT26.jpg','68', '1'),"..
		"(1365,'CUNGMBVIT28','GORRA VINTAGE','CUNGMBVIT28.jpg','68', '1'),"..
		"(1366,'CUNGMBVIT29','GORRA VINTAGE','CUNGMBVIT29.jpg','68', '1'),"..
		"(1367,'CUNGMBVIT30','GORRA VINTAGE','CUNGMBVIT30.jpg','68', '1'),"..
		"(1368,'CUNGMBVIT31','GORRA VINTAGE','CUNGMBVIT31.jpg','68', '1'),"..
		"(1369,'CUNGMBVIT32','GORRA VINTAGE','CUNGMBVIT32.jpg','68', '1'),"..
		"(1370,'CUNGMBVIT37','GORRA VINTAGE','CUNGMBVIT37.jpg','68', '1'),"..
		"(1371,'CUNGMBVIT40','GORRA VINTAGE','CUNGMBVIT40.jpg','68', '1'),"..
		"(1372,'CUNGMBVIT69','GORRA VINTAGE','CUNGMBVIT69.jpg','68', '1'),"..
		"(1373,'CUNGMBVIT70','GORRA VINTAGE','CUNGMBVIT70.jpg','68', '1'),"..
		"(1374,'CUNGMBVIT71','GORRA VINTAGE','CUNGMBVIT71.jpg','68', '1'),"..
		"(1375,'CUNGMBVIT72','GORRA VINTAGE','CUNGMBVIT72.jpg','68', '1'),"..
		"(1376,'CUNGMBVIT73','GORRA VINTAGE','CUNGMBVIT73.jpg','68', '1'),"..
		"(1377,'CUNGMBVIT86','GORRA VINTAGE','CUNGMBVIT86.jpg','68', '1'),"..
		"(1378,'CUNGMBVIT87','GORRA VINTAGE','CUNGMBVIT87.jpg','68', '1'),"..
		"(1379,'CUNPAB0009','PLAYERA ADULTO SOL PANAMA','CUNPAB0009.jpg','70', '1'),"..
		"(1380,'CUNPAB001','PLAYERA ADULTO BORDADA SURF','CUNPAB001.jpg','70', '1'),"..
		"(1381,'CUNPAB002','PLAYERA ADULTO BORDADA PALMERAS 70','CUNPAB002.jpg','70', '1'),"..
		"(1382,'CUNPAB003','PLAYERA ADULTO BORDADA DIVE DEEP','CUNPAB003.jpg','70', '1'),"..
		"(1383,'CUNPAB073','PLAYERA ADULTO 3 DELFINES BRINCANDO','CUNPAB073.jpg','70', '1'),"..
		"(1384,'CUNPAB105','PLAYERA ADULTO MARGARITAS','CUNPAB105.jpg','70', '1'),"..
		"(1385,'CUNPAB379','PLAYERA ADULTO DELFIN RECTANGULO 2','CUNPAB379.jpg','70', '1'),"..
		"(1386,'CUNPAB490','PLAYERA ADULTO PALMERA MEXICO','CUNPAB490.jpg','70', '1'),"..
		"(1387,'CUNPAB491','PLAYERA ADULTO TORTUGA NADANDO','CUNPAB491.jpg','70', '1'),"..
		"(1388,'CUNPAB492','PLAYERA ADULTO 2 GEKOS','CUNPAB492.jpg','70', '1'),"..
		"(1389,'CUNPAB493','PLAYERA ADULTO LETRAS FLORES','CUNPAB493.jpg','70', '1'),"..
		"(1390,'CUNPAB494','PLAYERA ADULTO 2 PALMERAS MX','CUNPAB494.jpg','70', '1'),"..
		"(1391,'CUNPAB495','PLAYERA ADULTO GEKO HUELLAS','CUNPAB495.jpg','70', '1'),"..
		"(1392,'CUNPAI040','PLAYERA ADULTO IGUANA FLOC','CUNPAI040.jpg','65', '1'),"..
		"(1393,'CUNPAI041','PLAYERA ADULTO GEKO OJON','CUNPAI041.jpg','65', '1'),"..
		"(1394,'CUNPAI042','PLAYERA ADULTO IGUANA GRECAS','CUNPAI042.jpg','65', '1'),"..
		"(1395,'CUNPAI043','PLAYERA ADULTO IGUANA FOIL','CUNPAI043.jpg','65', '1'),"..
		"(1396,'CUNPAI044','PLAYERA ADULTO 2 TORTUGAS CIRCULO','CUNPAI044.jpg','65', '1'),"..
		"(1397,'CUNPAI045','PLAYERA ADULTO 2 GECOS CIRCULO FOIL','CUNPAI045.jpg','65', '1'),"..
		"(1398,'CUNPAJ001','PLAYERA ADULTO PREMIER TORTUGA CASCADA NEGRO','CUNPAJ001.jpg','65', '1'),"..
		"(1399,'CUNPAJ002','PLAYERA ADULTO PREMIER TIBURON DIVE','CUNPAJ002.jpg','65', '1'),"..
		"(1400,'CUNPAJ003','PLAYERA ADULTO PREMIER 7 TIBURONES','CUNPAJ003.jpg','65', '1'),"..
		"(1401,'CUNPAJ004','PLAYERA ADULTO PREMIER GEKO CASCADA','CUNPAJ004.jpg','65', '1'),"..
		"(1402,'CUNPAJ011','PLAYERA AD PREMIER 2 GEKOS FLOK','CUNPAJ011.jpg','68', '1'),"..
		"(1403,'CUNPAJ011XXL','PLAYERA AD PREMIER 2 GEKOS FLOK','CUNPAJ011XXL.jpg','68', '1'),"..
		"(1404,'CUNPAJ012','PLAYERA AD PREMIER DELFIN FLORES','CUNPAJ012.jpg','68', '1'),"..
		"(1405,'CUNPAJ012XXL','PLAYERA AD PREMIER DELFIN FLORES','CUNPAJ012XXL.jpg','68', '1'),"..
		"(1406,'CUNPAJ013','PLAYERA AD PREMIER TIBURON RETRO','CUNPAJ013.jpg','68', '1'),"..
		"(1407,'CUNPAJ013XXL','PLAYERA AD PREMIER TIBURON RETRO','CUNPAJ013XXL.jpg','68', '1'),"..
		"(1408,'CUNPAJ014','PLAYERA AD PREMIER TORTUGA DIVE','CUNPAJ014.jpg','68', '1'),"..
		"(1409,'CUNPAJ014XXL','PLAYERA AD PREMIER TORTUGA DIVE','CUNPAJ014XXL.jpg','68', '1'),"..
		"(1410,'CUNPAJ015','PLAYERA AD PREMIER TORTUGA GREKAS','CUNPAJ015.jpg','68', '1'),"..
		"(1411,'CUNPAJ015XXL','PLAYERA AD PREMIER TORTUGA GREKAS','CUNPAJ015XXL.jpg','68', '1'),"..
		"(1412,'CUNPAO02011','PL AD OIL V ESCUDO GUIRNALDAS MARINO','CUNPAO02011.jpg','85', '1'),"..
		"(1413,'CUNPAO02116','PL AD OIL V MX SOMBRAS ROJO','CUNPAO02116.jpg','85', '1'),"..
		"(1414,'CUNPAO02213','PL AD OIL V SELLO VERTICAL NEGRO','CUNPAO02213.jpg','85', '1'),"..
		"(1415,'CUNPAU00113','PLAYERA ADULTO ULTRA C COLEGIAL NEGRO','CUNPAU00113.jpg','72', '1'),"..
		"(1416,'CUNPAU00211','PLAYERA ADULTO ULTRA V TIBURON CUADRO MARINO','CUNPAU00211.jpg','72', '1'),"..
		"(1417,'CUNPAU00309','PLAYERA ADULTO ULTRA V TIBURON ROMBO GRIS','CUNPAU00309.jpg','72', '1'),"..
		"(1418,'CUNPAU00416','PLAYERA ADULTO ULTRA V 3 PALMERAS ROJO','CUNPAU00416.jpg','72', '1'),"..
		"(1419,'CUNPAU00503','PLAYERA ADULTO ULTRA V ATHLETIC BLANCO','CUNPAU00503.jpg','72', '1'),"..
		"(1420,'CUNPDO02378','PL DA OIL V 3 CORAZONES SINCE AQUA','CUNPDO02378.jpg','85', '1'),"..
		"(1421,'CUNPDO02429','PL DA OIL V FLORES 70 ROSA','CUNPDO02429.jpg','85', '1'),"..
		"(1422,'CUNPDO02504','PL DA OIL V LOVE PARCHE CELESTE','CUNPDO02504.jpg','85', '1'),"..
		"(1423,'CUNPDU00171','PLAYERA DAMA ULTRA V PALMERAS FIUSHA','CUNPDU00171.jpg','72', '1'),"..
		"(1424,'CUNPDU00217','PLAYERA DAMA ULTRA V ERY DAY LIMON','CUNPDU00217.jpg','72', '1'),"..
		"(1425,'CUNPDU00378','PLAYERA DAMA ULTRA V LOVE CORAZON AQUA','CUNPDU00378.jpg','72', '1'),"..
		"(1426,'CUNPDU00413','PLAYERA DAMA ULTRA V RELAX NEGRO','CUNPDU00413.jpg','72', '1'),"..
		"(1427,'CUNPDU00503','PLAYERA DAMA ULTRA V DESTINO PINCEL BLANCO','CUNPDU00503.jpg','72', '1'),"..
		"(1428,'CUNPNB073','PLAYERA NIÑO BORDADA 3 DELFINES BRINCANDO','CUNPNB073.jpg','61', '1'),"..
		"(1429,'CUNPNB411','PLAYERA NIÑO BORDADA MARIPOSAS','CUNPNB411.jpg','61', '1'),"..
		"(1430,'CUNPNB465','PLAYERA NIÑO BORDADA 5 FLORES SMILE','CUNPNB465.jpg','61', '1'),"..
		"(1431,'CUNPNB470','PLAYERA NIÑO BORDADA CHANCLAS','CUNPNB470.jpg','61', '1'),"..
		"(1432,'CUNPNB480','PLAYERA NIÑO IGUANA SURF','CUNPNB480.jpg','61', '1'),"..
		"(1433,'CUNPNB481','PLAYERA NIÑO 2 GEKOS OJONES','CUNPNB481.jpg','61', '1'),"..
		"(1434,'CUNPNB482','PLAYERA NIÑO TORTUGA FLORES','CUNPNB482.jpg','61', '1'),"..
		"(1435,'CUNPNB483','PLAYERA NIÑO 3 DELFINES FLORES','CUNPNB483.jpg','61', '1'),"..
		"(1436,'CUNPNI050','PLAYERA NIÑO 2 GECOS RECTANGULO','CUNPNI050.jpg','59', '1'),"..
		"(1437,'CUNPNI051','PLAYERA NIÑO 4 TORTUGAS','CUNPNI051.jpg','59', '1'),"..
		"(1438,'CUNPNI052','PLAYERA NIÑO 3 TIBURONES SOMBRAS','CUNPNI052.jpg','59', '1'),"..
		"(1439,'CUNPNI053','PLAYERA NIÑO 3 TORTUGAS NADANDO','CUNPNI053.jpg','59', '1'),"..
		"(1440,'CUNPNI054','PLAYERA NIÑO GEKO PATON','CUNPNI054.jpg','59', '1'),"..
		"(1441,'CUNPNI055','PLAYERA NIÑO GEKO DOBLE CIRCULO','CUNPNI055.jpg','59', '1'),"..
		"(1442,'CUNPNI056','PLAYERA NIÑO PLAY HOOKY','CUNPNI056.jpg','59', '1'),"..
		"(1443,'CUNPNJ005','PLAYERA NIÑO PREMIER TORTUGA SELLO','CUNPNJ005.jpg','59', '1'),"..
		"(1444,'CUNPNJ006','PLAYERA NIÑO PREMIER TENIS GLITER ROSA','CUNPNJ006.jpg','59', '1'),"..
		"(1445,'CUNPNJ007','PLAYERA NIÑO PREMIER BANDERA PIRATA ROYAL','CUNPNJ007.jpg','59', '1'),"..
		"(1446,'CUNPNJ008','PLAYERA NIÑO PREMIER 2 DLFINES PALMERAS','CUNPNJ008.jpg','59', '1'),"..
		"(1447,'CUNPNJ009','PLAYERA NIÑO PREMIER GEKO MAYA','CUNPNJ009.jpg','59', '1'),"..
		"(1448,'CUNPNJ010','PLAYERA NIÑO PREMIER CALACA SURF','CUNPNJ010.jpg','59', '1'),"..
		"(1449,'CUNSAB00109','SUDADERA ADULTO CAPUCHA','CUNSAB00109.jpg','170', '1'),"..
		"(1450,'CUNSAB00111','SUDADERA ADULTO CAPUCHA','CUNSAB00111.jpg','170', '1'),"..
		"(1451,'CUNSAB00113','SUDADERA ADULTO CAPUCHA','CUNSAB00113.jpg','170', '1'),"..
		"(1452,'CUNSAB00117','SUDADERA ADULTO CAPUCHA','CUNSAB00117.jpg','170', '1'),"..
		"(1453,'CUNSAB00138','SUDADERA ADULTO CAPUCHA','CUNSAB00138.jpg','170', '1'),"..
		"(1454,'CUNSAB00140','SUDADERA ADULTO CAPUCHA','CUNSAB00140.jpg','170', '1'),"..
		"(1455,'CUNSAB00171','SUDADERA ADULTO CAPUCHA','CUNSAB00171.jpg','170', '1'),"..
		"(1456,'CUNSAB001XXL09','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL09.jpg','170', '1'),"..
		"(1457,'CUNSAB001XXL11','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL11.jpg','170', '1'),"..
		"(1458,'CUNSAB001XXL13','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL13.jpg','170', '1'),"..
		"(1459,'CUNSAB001XXL17','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL17.jpg','170', '1'),"..
		"(1460,'CUNSAB001XXL29','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL29.jpg','170', '1'),"..
		"(1461,'CUNSAB001XXL38','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL38.jpg','170', '1'),"..
		"(1462,'CUNSAB001XXL40','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL40.jpg','170', '1'),"..
		"(1463,'CUNSAB001XXL71','SUDADERA ADULTO CAPUCHA','CUNSAB001XXL71.jpg','170', '1'),"..
		"(1464,'CUNSMBGUI03','SOMBRERO GUILLIGAN','CUNSMBGUI03.jpg','73', '1'),"..
		"(1465,'CUNSMBGUI10','SOMBRERO GUILLIGAN','CUNSMBGUI10.jpg','73', '1'),"..
		"(1466,'CUNSMBGUI11','SOMBRERO GUILLIGAN','CUNSMBGUI11.jpg','73', '1'),"..
		"(1467,'CUNSMBGUI12','SOMBRERO GUILLIGAN','CUNSMBGUI12.jpg','73', '1'),"..
		"(1468,'CUNSMBGUI13','SOMBRERO GUILLIGAN','CUNSMBGUI13.jpg','73', '1'),"..
		"(1469,'CUNSMBGUI28','SOMBRERO GUILLIGAN','CUNSMBGUI28.jpg','73', '1'),"..
		"(1470,'CUNSMBGUI30','SOMBRERO GUILLIGAN','CUNSMBGUI30.jpg','73', '1'),"..
		"(1471,'CUNSNB00109','SUDADERA IMPORTACION NIÑO','CUNSNB00109.jpg','170', '1'),"..
		"(1472,'CUNSNB00111','SUDADERA IMPORTACION NIÑO','CUNSNB00111.jpg','170', '1'),"..
		"(1473,'CUNSNB00113','SUDADERA IMPORTACION NIÑO','CUNSNB00113.jpg','170', '1'),"..
		"(1474,'CUNVCOV0303','VICERA PIEDRITAS CANCUN','CUNVCOV0303.jpg','62', '1'),"..
		"(1475,'CUNVCOV0304','VICERA PIEDRITAS CANCUN','CUNVCOV0304.jpg','62', '1'),"..
		"(1476,'CUNVCOV0311','VICERA PIEDRITAS CANCUN','CUNVCOV0311.jpg','62', '1'),"..
		"(1477,'CUNVCOV0313','VICERA PIEDRITAS CANCUN','CUNVCOV0313.jpg','62', '1'),"..
		"(1478,'CUNVCOV0316','VICERA PIEDRITAS CANCUN','CUNVCOV0316.jpg','62', '1'),"..
		"(1479,'CUNVCOV0329','VICERA PIEDRITAS CANCUN','CUNVCOV0329.jpg','62', '1'),"..
		"(1480,'CUNVCOV0330','VICERA PIEDRITAS CANCUN','CUNVCOV0330.jpg','62', '1'),"..
		"(1481,'CUNVCOV0337','VICERA PIEDRITAS CANCUN','CUNVCOV0337.jpg','62', '1'),"..
		"(1482,'CUNVIBSAN03','VICERA SANDWICH','CUNVIBSAN03.jpg','62', '1'),"..
		"(1483,'CUNVIBSAN04','VICERA SANDWICH','CUNVIBSAN04.jpg','62', '1'),"..
		"(1484,'CUNVIBSAN11','VICERA SANDWICH','CUNVIBSAN11.jpg','62', '1'),"..
		"(1485,'CUNVIBSAN13','VICERA SANDWICH','CUNVIBSAN13.jpg','62', '1'),"..
		"(1486,'CUNVIBSAN16','VICERA SANDWICH','CUNVIBSAN16.jpg','62', '1'),"..
		"(1487,'CUNVIBSAN29','VICERA SANDWICH','CUNVIBSAN29.jpg','62', '1'),"..
		"(1488,'CUNVIBSAN30','VICERA SANDWICH','CUNVIBSAN30.jpg','62', '1'),"..
		"(1489,'CUNVIBSAN37','VICERA SANDWICH','CUNVIBSAN37.jpg','62', '1'),"..
		"(1490,'DELCOA00111','COMBO PESPUNTE DELPHINUS','DELCOA00111.jpg','99', '1'),"..
		"(1491,'DELCOA00112','COMBO ADULO DELPHINUS','DELCOA00112.jpg','99', '1'),"..
		"(1492,'DELCOA00128','COMBO ADULO DELPHINUS','DELCOA00128.jpg','99', '1'),"..
		"(1493,'DELCOA00129','COMBO DAMA DELPHINUS','DELCOA00129.jpg','99', '1'),"..
		"(1494,'DELCOA00130','COMBO ADULO DELPHINUS','DELCOA00130.jpg','110', '1'),"..
		"(1495,'DELCOA00140','COMBO PLUS DELPHINUS','DELCOA00140.jpg','99', '1'),"..
		"(1496,'DELGDKPLU12','GORRA PLUS DELPHINUS','DELGDKPLU12.jpg','68', '1'),"..
		"(1497,'DELGDKPLU17','GORRA PLUS DELPHINUS','DELGDKPLU17.jpg','68', '1'),"..
		"(1498,'DELGDKPLU18','GORRA PLUS DELPHINUS','DELGDKPLU18.jpg','68', '1'),"..
		"(1499,'DELGDKPLU40','GORRA PLUS DELPHINUS','DELGDKPLU40.jpg','68', '1'),"..
		"(1500,'DELGDKPLU71','GORRA PLUS DELPHINUS','DELGDKPLU71.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1501,'DELGMBDAM04','GORRA DAMA DELPHINUS','DELGMBDAM04.jpg','63', '1'),"..
		"(1502,'DELGMBDAM12','GORRA DAMA DELPHINUS','DELGMBDAM12.jpg','63', '1'),"..
		"(1503,'DELGMBDAM17','GORRA DAMA DELPHINUS','DELGMBDAM17.jpg','63', '1'),"..
		"(1504,'DELGMBDAM18','GORRA DAMA DELPHINUS','DELGMBDAM18.jpg','63', '1'),"..
		"(1505,'DELGMBDAM19','GORRA DAMA DELPHINUS','DELGMBDAM19.jpg','63', '1'),"..
		"(1506,'DELGMBDAM29','GORRA DAMA DELPHINUS','DELGMBDAM29.jpg','63', '1'),"..
		"(1507,'DELGMBDAM40','GORRA DAMA DELPHINUS','DELGMBDAM40.jpg','63', '1'),"..
		"(1508,'DELGMBDAM41','GORRA DAMA DELPHINUS','DELGMBDAM41.jpg','63', '1'),"..
		"(1509,'DELGMBDES04','GORRA DESLAVADA DELPHINUS','DELGMBDES04.jpg','63', '1'),"..
		"(1510,'DELGMBDES05','GORRA DESLAVADA DELPHINUS','DELGMBDES05.jpg','63', '1'),"..
		"(1511,'DELGMBDES06','GORRA DESLAVADA DELPHINUS','DELGMBDES06.jpg','63', '1'),"..
		"(1512,'DELGMBDES10','GORRA DESLAVADA DELPHINUS','DELGMBDES10.jpg','63', '1'),"..
		"(1513,'DELGMBDES11','GORRA DESLAVADA DELPHINUS','DELGMBDES11.jpg','63', '1'),"..
		"(1514,'DELGMBDES12','GORRA DESLAVADA DELPHINUS','DELGMBDES12.jpg','63', '1'),"..
		"(1515,'DELGMBDES13','GORRA DESLAVADA DELPHINUS','DELGMBDES13.jpg','63', '1'),"..
		"(1516,'DELGMBDES15','GORRA DESLAVADA DELPHINUS','DELGMBDES15.jpg','63', '1'),"..
		"(1517,'DELGMBDES16','GORRA DESLAVADA DELPHINUS','DELGMBDES16.jpg','63', '1'),"..
		"(1518,'DELGMBDES21','GORRA DESLAVADA DELPHINUS','DELGMBDES21.jpg','63', '1'),"..
		"(1519,'DELGMBDES25','GORRA DESLAVADA DELPHINUS','DELGMBDES25.jpg','63', '1'),"..
		"(1520,'DELGMBDES26','GORRA DESLAVADA DELPHINUS','DELGMBDES26.jpg','63', '1'),"..
		"(1521,'DELGMBDES28','GORRA DESLAVADA DELPHINUS','DELGMBDES28.jpg','63', '1'),"..
		"(1522,'DELGMBDES30','GORRA DESLAVADA DELPHINUS','DELGMBDES30.jpg','63', '1'),"..
		"(1523,'DELGMBDES32','GORRA DESLAVADA DELPHINUS','DELGMBDES32.jpg','63', '1'),"..
		"(1524,'DELGMBDES34','GORRA DESLAVADA DELPHINUS','DELGMBDES34.jpg','63', '1'),"..
		"(1525,'DELGMBDES35','GORRA DESLAVADA DELPHINUS','DELGMBDES35.jpg','63', '1'),"..
		"(1526,'DELGMBDES37','GORRA DESLAVADA DELPHINUS','DELGMBDES37.jpg','63', '1'),"..
		"(1527,'DELGMBPES11','GORRA PESPUNTE DELPHINUS','DELGMBPES11.jpg','68', '1'),"..
		"(1528,'DRPCOA00105','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA00105.jpg','99', '1'),"..
		"(1529,'DRPCOA00105','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA00105.jpg','99', '1'),"..
		"(1530,'DRPCOA00111','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA00111.jpg','99', '1'),"..
		"(1531,'DRPCOA00115','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA00115.jpg','99', '1'),"..
		"(1532,'DRPCOA00128','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA00128.jpg','99', '1'),"..
		"(1533,'DRPCOA00130','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA00130.jpg','99', '1'),"..
		"(1534,'DRPCOA001XXL05','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA001XXL05.jpg','110', '1'),"..
		"(1535,'DRPCOA001XXL11','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA001XXL11.jpg','110', '1'),"..
		"(1536,'DRPCOA001XXL15','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA001XXL15.jpg','110', '1'),"..
		"(1537,'DRPCOA001XXL28','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA001XXL28.jpg','110', '1'),"..
		"(1538,'DRPCOA001XXL30','COMBO ADULTO DREAMS PTO AVENTURAS','DRPCOA001XXL30.jpg','110', '1'),"..
		"(1539,'DRPGMBDES04','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES04.jpg','63', '1'),"..
		"(1540,'DRPGMBDES05','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES05.jpg','63', '1'),"..
		"(1541,'DRPGMBDES06','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES06.jpg','63', '1'),"..
		"(1542,'DRPGMBDES10','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES10.jpg','63', '1'),"..
		"(1543,'DRPGMBDES11','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES11.jpg','63', '1'),"..
		"(1544,'DRPGMBDES12','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES12.jpg','63', '1'),"..
		"(1545,'DRPGMBDES13','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES13.jpg','63', '1'),"..
		"(1546,'DRPGMBDES15','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES15.jpg','63', '1'),"..
		"(1547,'DRPGMBDES16','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES16.jpg','63', '1'),"..
		"(1548,'DRPGMBDES21','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES21.jpg','63', '1'),"..
		"(1549,'DRPGMBDES25','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES25.jpg','63', '1'),"..
		"(1550,'DRPGMBDES26','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES26.jpg','63', '1'),"..
		"(1551,'DRPGMBDES28','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES28.jpg','63', '1'),"..
		"(1552,'DRPGMBDES30','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES30.jpg','63', '1'),"..
		"(1553,'DRPGMBDES32','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES32.jpg','63', '1'),"..
		"(1554,'DRPGMBDES34','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES34.jpg','63', '1'),"..
		"(1555,'DRPGMBDES35','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES35.jpg','63', '1'),"..
		"(1556,'DRPGMBDES37','GORRA DESLAVADA DREAMS PTO AVENTURA','DRPGMBDES37.jpg','63', '1'),"..
		"(1557,'DRPGMBNIÑ02','GORRA NIÑO DREAMS PTO AVENTURAS','DRPGMBNIÑ02.jpg','63', '1'),"..
		"(1558,'DRPGMBNIÑ10','GORRA NIÑO DREAMS PTO AVENTURAS','DRPGMBNIÑ10.jpg','63', '1'),"..
		"(1559,'DRPGMBNIÑ11','GORRA NIÑO DREAMS PTO AVENTURAS','DRPGMBNIÑ11.jpg','63', '1'),"..
		"(1560,'DRPGMBNIÑ12','GORRA NIÑO DREAMS PTO AVENTURAS','DRPGMBNIÑ12.jpg','63', '1'),"..
		"(1561,'DRPGMBNIÑ15','GORRA NIÑO DREAMS PTO AVENTURAS','DRPGMBNIÑ15.jpg','63', '1'),"..
		"(1562,'DRTGMBDES04','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES04.jpg','63', '1'),"..
		"(1563,'DRTGMBDES05','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES05.jpg','63', '1'),"..
		"(1564,'DRTGMBDES06','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES06.jpg','63', '1'),"..
		"(1565,'DRTGMBDES10','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES10.jpg','63', '1'),"..
		"(1566,'DRTGMBDES11','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES11.jpg','63', '1'),"..
		"(1567,'DRTGMBDES12','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES12.jpg','63', '1'),"..
		"(1568,'DRTGMBDES13','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES13.jpg','63', '1'),"..
		"(1569,'DRTGMBDES15','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES15.jpg','63', '1'),"..
		"(1570,'DRTGMBDES16','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES16.jpg','63', '1'),"..
		"(1571,'DRTGMBDES21','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES21.jpg','63', '1'),"..
		"(1572,'DRTGMBDES25','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES25.jpg','63', '1'),"..
		"(1573,'DRTGMBDES26','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES26.jpg','63', '1'),"..
		"(1574,'DRTGMBDES28','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES28.jpg','63', '1'),"..
		"(1575,'DRTGMBDES30','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES30.jpg','63', '1'),"..
		"(1576,'DRTGMBDES32','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES32.jpg','63', '1'),"..
		"(1577,'DRTGMBDES34','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES34.jpg','63', '1'),"..
		"(1578,'DRTGMBDES35','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES35.jpg','63', '1'),"..
		"(1579,'DRTGMBDES37','GORRA DESLAVADA DREAMS TULUM','DRTGMBDES37.jpg','63', '1'),"..
		"(1580,'DRTGMBSAN02','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN02.jpg','68', '1'),"..
		"(1581,'DRTGMBSAN03','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN03.jpg','68', '1'),"..
		"(1582,'DRTGMBSAN05','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN05.jpg','68', '1'),"..
		"(1583,'DRTGMBSAN06','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN06.jpg','68', '1'),"..
		"(1584,'DRTGMBSAN07','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN07.jpg','68', '1'),"..
		"(1585,'DRTGMBSAN11','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN11.jpg','68', '1'),"..
		"(1586,'DRTGMBSAN13','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN13.jpg','68', '1'),"..
		"(1587,'DRTGMBSAN20','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN20.jpg','68', '1'),"..
		"(1588,'DRTGMBSAN22','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN22.jpg','68', '1'),"..
		"(1589,'DRTGMBSAN30','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN30.jpg','68', '1'),"..
		"(1590,'DRTGMBSAN32','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN32.jpg','68', '1'),"..
		"(1591,'DRTGMBSAN33','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN33.jpg','68', '1'),"..
		"(1592,'DRTGMBSAN36','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN36.jpg','68', '1'),"..
		"(1593,'DRTGMBSAN39','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN39.jpg','68', '1'),"..
		"(1594,'DRTGMBSAN43','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN43.jpg','68', '1'),"..
		"(1595,'DRTGMBSAN45','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN45.jpg','68', '1'),"..
		"(1596,'DRTGMBSAN49','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN49.jpg','68', '1'),"..
		"(1597,'DRTGMBSAN51','GORRA SANDWICH DREAMS TULUM','DRTGMBSAN51.jpg','68', '1'),"..
		"(1598,'EDMCOA00102','COMBO ADULTO EL DORADO MAROMA','EDMCOA00102.jpg','99', '1'),"..
		"(1599,'EDMCOA00106','COMBO ADULTO EL DORADO MAROMA','EDMCOA00106.jpg','99', '1'),"..
		"(1600,'EDMCOA00111','COMBO ADULTO EL DORADO MAROMA','EDMCOA00111.jpg','99', '1'),"..
		"(1601,'EDMCOA00112','COMBO ADULTO EL DORADO MAROMA','EDMCOA00112.jpg','99', '1'),"..
		"(1602,'EDMCOA00113','COMBO ADULTO EL DORADO MAROMA','EDMCOA00113.jpg','99', '1'),"..
		"(1603,'EDMCOA00115','COMBO ADULTO EL DORADO MAROMA','EDMCOA00115.jpg','99', '1'),"..
		"(1604,'EDMCOA00126','COMBO ADULTO EL DORADO MAROMA','EDMCOA00126.jpg','99', '1'),"..
		"(1605,'EDMCOA00128','COMBO ADULTO EL DORADO MAROMA','EDMCOA00128.jpg','99', '1'),"..
		"(1606,'EDMCOA00130','COMBO ADULTO EL DORADO MAROMA','EDMCOA00130.jpg','99', '1'),"..
		"(1607,'EDMCOA00132','COMBO ADULTO EL DORADO MAROMA','EDMCOA00132.jpg','99', '1'),"..
		"(1608,'EDMCOA00135','COMBO ADULTO EL DORADO MAROMA','EDMCOA00135.jpg','99', '1'),"..
		"(1609,'EDMCOA001XXL02','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL02.jpg','110', '1'),"..
		"(1610,'EDMCOA001XXL06','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL06.jpg','110', '1'),"..
		"(1611,'EDMCOA001XXL11','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL11.jpg','110', '1'),"..
		"(1612,'EDMCOA001XXL12','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL12.jpg','110', '1'),"..
		"(1613,'EDMCOA001XXL13','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL13.jpg','110', '1'),"..
		"(1614,'EDMCOA001XXL15','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL15.jpg','110', '1'),"..
		"(1615,'EDMCOA001XXL26','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL26.jpg','110', '1'),"..
		"(1616,'EDMCOA001XXL28','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL28.jpg','110', '1'),"..
		"(1617,'EDMCOA001XXL30','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL30.jpg','110', '1'),"..
		"(1618,'EDMCOA001XXL32','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL32.jpg','110', '1'),"..
		"(1619,'EDMCOA001XXL35','COMBO ADULTO EL DORADO MAROMA','EDMCOA001XXL35.jpg','110', '1'),"..
		"(1620,'EDMGDKMFI03','GORRA MICRO FIBRA EL DORADO MAROMA','EDMGDKMFI03.jpg','76', '1'),"..
		"(1621,'EDMGDKMFI11','GORRA MICRO FIBRA EL DORADO MAROMA','EDMGDKMFI11.jpg','76', '1'),"..
		"(1622,'EDMGDKMFI13','GORRA MICRO FIBRA EL DORADO MAROMA','EDMGDKMFI13.jpg','76', '1'),"..
		"(1623,'EDMGDKMFI16','GORRA MICRO FIBRA EL DORADO MAROMA','EDMGDKMFI16.jpg','76', '1'),"..
		"(1624,'EDMGMBDAM04','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM04.jpg','63', '1'),"..
		"(1625,'EDMGMBDAM12','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM12.jpg','63', '1'),"..
		"(1626,'EDMGMBDAM17','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM17.jpg','63', '1'),"..
		"(1627,'EDMGMBDAM18','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM18.jpg','63', '1'),"..
		"(1628,'EDMGMBDAM19','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM19.jpg','63', '1'),"..
		"(1629,'EDMGMBDAM29','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM29.jpg','63', '1'),"..
		"(1630,'EDMGMBDAM40','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM40.jpg','63', '1'),"..
		"(1631,'EDMGMBDAM41','GORRA DAMA EL DORADO MAROMA','EDMGMBDAM41.jpg','63', '1'),"..
		"(1632,'EDMGMBDES04','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES04.jpg','63', '1'),"..
		"(1633,'EDMGMBDES05','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES05.jpg','63', '1'),"..
		"(1634,'EDMGMBDES06','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES06.jpg','63', '1'),"..
		"(1635,'EDMGMBDES10','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES10.jpg','63', '1'),"..
		"(1636,'EDMGMBDES11','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES11.jpg','63', '1'),"..
		"(1637,'EDMGMBDES12','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES12.jpg','63', '1'),"..
		"(1638,'EDMGMBDES13','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES13.jpg','63', '1'),"..
		"(1639,'EDMGMBDES15','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES15.jpg','63', '1'),"..
		"(1640,'EDMGMBDES16','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES16.jpg','63', '1'),"..
		"(1641,'EDMGMBDES21','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES21.jpg','63', '1'),"..
		"(1642,'EDMGMBDES25','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES25.jpg','63', '1'),"..
		"(1643,'EDMGMBDES26','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES26.jpg','63', '1'),"..
		"(1644,'EDMGMBDES28','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES28.jpg','63', '1'),"..
		"(1645,'EDMGMBDES30','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES30.jpg','63', '1'),"..
		"(1646,'EDMGMBDES32','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES32.jpg','63', '1'),"..
		"(1647,'EDMGMBDES34','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES34.jpg','63', '1'),"..
		"(1648,'EDMGMBDES35','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES35.jpg','63', '1'),"..
		"(1649,'EDMGMBDES37','GORRA DESLAVADA EL DORADO MAROMA','EDMGMBDES37.jpg','63', '1'),"..
		"(1650,'EDMGMBSAN02','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN02.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1651,'EDMGMBSAN03','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN03.jpg','68', '1'),"..
		"(1652,'EDMGMBSAN05','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN05.jpg','68', '1'),"..
		"(1653,'EDMGMBSAN06','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN06.jpg','68', '1'),"..
		"(1654,'EDMGMBSAN07','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN07.jpg','68', '1'),"..
		"(1655,'EDMGMBSAN11','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN11.jpg','68', '1'),"..
		"(1656,'EDMGMBSAN13','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN13.jpg','68', '1'),"..
		"(1657,'EDMGMBSAN20','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN20.jpg','68', '1'),"..
		"(1658,'EDMGMBSAN22','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN22.jpg','68', '1'),"..
		"(1659,'EDMGMBSAN30','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN30.jpg','68', '1'),"..
		"(1660,'EDMGMBSAN32','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN32.jpg','68', '1'),"..
		"(1661,'EDMGMBSAN33','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN33.jpg','68', '1'),"..
		"(1662,'EDMGMBSAN36','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN36.jpg','68', '1'),"..
		"(1663,'EDMGMBSAN39','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN39.jpg','68', '1'),"..
		"(1664,'EDMGMBSAN43','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN43.jpg','68', '1'),"..
		"(1665,'EDMGMBSAN45','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN45.jpg','68', '1'),"..
		"(1666,'EDMGMBSAN49','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN49.jpg','68', '1'),"..
		"(1667,'EDMGMBSAN51','GORRA SANDWICH DORADO MAROMA','EDMGMBSAN51.jpg','68', '1'),"..
		"(1668,'EDOCOA0102','COMBO ADULTO EL DORADO','EDOCOA0102.jpg','99', '1'),"..
		"(1669,'EDOCOA0105','COMBO ADULTO EL DORADO','EDOCOA0105.jpg','99', '1'),"..
		"(1670,'EDOCOA0106','COMBO ADULTO EL DORADO','EDOCOA0106.jpg','99', '1'),"..
		"(1671,'EDOCOA0110','COMBO ADULTO EL DORADO','EDOCOA0110.jpg','99', '1'),"..
		"(1672,'EDOCOA0111','COMBO ADULTO EL DORADO','EDOCOA0111.jpg','99', '1'),"..
		"(1673,'EDOCOA0112','COMBO ADULTO EL DORADO','EDOCOA0112.jpg','99', '1'),"..
		"(1674,'EDOCOA0113','COMBO ADULTO EL DORADO','EDOCOA0113.jpg','99', '1'),"..
		"(1675,'EDOCOA0115','COMBO ADULTO EL DORADO','EDOCOA0115.jpg','99', '1'),"..
		"(1676,'EDOCOA0121','COMBO ADULTO EL DORADO','EDOCOA0121.jpg','99', '1'),"..
		"(1677,'EDOCOA0125','COMBO ADULTO EL DORADO','EDOCOA0125.jpg','99', '1'),"..
		"(1678,'EDOCOA0126','COMBO ADULTO EL DORADO','EDOCOA0126.jpg','99', '1'),"..
		"(1679,'EDOCOA0128','COMBO ADULTO EL DORADO','EDOCOA0128.jpg','99', '1'),"..
		"(1680,'EDOCOA0130','COMBO ADULTO EL DORADO','EDOCOA0130.jpg','99', '1'),"..
		"(1681,'EDOCOA0132','COMBO ADULTO EL DORADO','EDOCOA0132.jpg','99', '1'),"..
		"(1682,'EDOCOA0134','COMBO ADULTO EL DORADO','EDOCOA0134.jpg','99', '1'),"..
		"(1683,'EDOCOA0135','COMBO ADULTO EL DORADO','EDOCOA0135.jpg','99', '1'),"..
		"(1684,'EDOCOA01XXL02','COMBO ADULTO EL DORADO','EDOCOA01XXL02.jpg','110', '1'),"..
		"(1685,'EDOCOA01XXL05','COMBO ADULTO EL DORADO','EDOCOA01XXL05.jpg','110', '1'),"..
		"(1686,'EDOCOA01XXL06','COMBO ADULTO EL DORADO','EDOCOA01XXL06.jpg','110', '1'),"..
		"(1687,'EDOCOA01XXL10','COMBO ADULTO EL DORADO','EDOCOA01XXL10.jpg','110', '1'),"..
		"(1688,'EDOCOA01XXL11','COMBO ADULTO EL DORADO','EDOCOA01XXL11.jpg','110', '1'),"..
		"(1689,'EDOCOA01XXL12','COMBO ADULTO EL DORADO','EDOCOA01XXL12.jpg','110', '1'),"..
		"(1690,'EDOCOA01XXL13','COMBO ADULTO EL DORADO','EDOCOA01XXL13.jpg','110', '1'),"..
		"(1691,'EDOCOA01XXL15','COMBO ADULTO EL DORADO','EDOCOA01XXL15.jpg','110', '1'),"..
		"(1692,'EDOCOA01XXL21','COMBO ADULTO EL DORADO','EDOCOA01XXL21.jpg','110', '1'),"..
		"(1693,'EDOCOA01XXL25','COMBO ADULTO EL DORADO','EDOCOA01XXL25.jpg','110', '1'),"..
		"(1694,'EDOCOA01XXL26','COMBO ADULTO EL DORADO','EDOCOA01XXL26.jpg','110', '1'),"..
		"(1695,'EDOCOA01XXL28','COMBO ADULTO EL DORADO','EDOCOA01XXL28.jpg','110', '1'),"..
		"(1696,'EDOCOA01XXL30','COMBO ADULTO EL DORADO','EDOCOA01XXL30.jpg','110', '1'),"..
		"(1697,'EDOCOA01XXL32','COMBO ADULTO EL DORADO','EDOCOA01XXL32.jpg','110', '1'),"..
		"(1698,'EDOCOA01XXL34','COMBO ADULTO EL DORADO','EDOCOA01XXL34.jpg','110', '1'),"..
		"(1699,'EDOCOA01XXL35','COMBO ADULTO EL DORADO','EDOCOA01XXL35.jpg','110', '1'),"..
		"(1700,'EDOGDKMFI03','GORRA MICRO FIBRA EL DORADO','EDOGDKMFI03.jpg','76', '1'),"..
		"(1701,'EDOGDKMFI11','GORRA MICRO FIBRA EL DORADO','EDOGDKMFI11.jpg','76', '1'),"..
		"(1702,'EDOGDKMFI13','GORRA MICRO FIBRA EL DORADO','EDOGDKMFI13.jpg','76', '1'),"..
		"(1703,'EDOGDKMFI16','GORRA MICRO FIBRA EL DORADO','EDOGDKMFI16.jpg','76', '1'),"..
		"(1704,'EDOGDKNBA03','GORRA NIÑO BASICA EL DORADO','EDOGDKNBA03.jpg','63', '1'),"..
		"(1705,'EDOGMBARC04','GORRA ARCOIRIS EL DORADO','EDOGMBARC04.jpg','68', '1'),"..
		"(1706,'EDOGMBARC18','GORRA ARCOIRIS EL DORADO','EDOGMBARC18.jpg','68', '1'),"..
		"(1707,'EDOGMBARC29','GORRA ARCOIRIS EL DORADO','EDOGMBARC29.jpg','68', '1'),"..
		"(1708,'EDOGMBARC38','GORRA ARCOIRIS EL DORADO','EDOGMBARC38.jpg','68', '1'),"..
		"(1709,'EDOGMBDAM04','GORRA DAMA EL DORADO','EDOGMBDAM04.jpg','63', '1'),"..
		"(1710,'EDOGMBDAM12','GORRA DAMA EL DORADO','EDOGMBDAM12.jpg','63', '1'),"..
		"(1711,'EDOGMBDAM17','GORRA DAMA EL DORADO','EDOGMBDAM17.jpg','63', '1'),"..
		"(1712,'EDOGMBDAM18','GORRA DAMA EL DORADO','EDOGMBDAM18.jpg','63', '1'),"..
		"(1713,'EDOGMBDAM19','GORRA DAMA EL DORADO','EDOGMBDAM19.jpg','63', '1'),"..
		"(1714,'EDOGMBDAM29','GORRA DAMA EL DORADO','EDOGMBDAM29.jpg','63', '1'),"..
		"(1715,'EDOGMBDAM40','GORRA DAMA EL DORADO','EDOGMBDAM40.jpg','63', '1'),"..
		"(1716,'EDOGMBDAM41','GORRA DAMA EL DORADO','EDOGMBDAM41.jpg','63', '1'),"..
		"(1717,'EDOGMBDES04','GORRA DESLAVADA EL DORADO','EDOGMBDES04.jpg','63', '1'),"..
		"(1718,'EDOGMBDES05','GORRA DESLAVADA EL DORADO','EDOGMBDES05.jpg','63', '1'),"..
		"(1719,'EDOGMBDES06','GORRA DESLAVADA EL DORADO','EDOGMBDES06.jpg','63', '1'),"..
		"(1720,'EDOGMBDES10','GORRA DESLAVADA EL DORADO','EDOGMBDES10.jpg','63', '1'),"..
		"(1721,'EDOGMBDES11','GORRA DESLAVADA EL DORADO','EDOGMBDES11.jpg','63', '1'),"..
		"(1722,'EDOGMBDES12','GORRA DESLAVADA EL DORADO','EDOGMBDES12.jpg','63', '1'),"..
		"(1723,'EDOGMBDES13','GORRA DESLAVADA EL DORADO','EDOGMBDES13.jpg','63', '1'),"..
		"(1724,'EDOGMBDES15','GORRA DESLAVADA EL DORADO','EDOGMBDES15.jpg','63', '1'),"..
		"(1725,'EDOGMBDES16','GORRA DESLAVADA EL DORADO','EDOGMBDES16.jpg','63', '1'),"..
		"(1726,'EDOGMBDES21','GORRA DESLAVADA EL DORADO','EDOGMBDES21.jpg','63', '1'),"..
		"(1727,'EDOGMBDES25','GORRA DESLAVADA EL DORADO','EDOGMBDES25.jpg','63', '1'),"..
		"(1728,'EDOGMBDES26','GORRA DESLAVADA EL DORADO','EDOGMBDES26.jpg','63', '1'),"..
		"(1729,'EDOGMBDES28','GORRA DESLAVADA EL DORADO','EDOGMBDES28.jpg','63', '1'),"..
		"(1730,'EDOGMBDES30','GORRA DESLAVADA EL DORADO','EDOGMBDES30.jpg','63', '1'),"..
		"(1731,'EDOGMBDES32','GORRA DESLAVADA EL DORADO','EDOGMBDES32.jpg','63', '1'),"..
		"(1732,'EDOGMBDES34','GORRA DESLAVADA EL DORADO','EDOGMBDES34.jpg','63', '1'),"..
		"(1733,'EDOGMBDES35','GORRA DESLAVADA EL DORADO','EDOGMBDES35.jpg','63', '1'),"..
		"(1734,'EDOGMBDES37','GORRA DESLAVADA EL DORADO','EDOGMBDES37.jpg','63', '1'),"..
		"(1735,'EDOGMBNIÑ02','GORRA NIÑO EL DORADO','EDOGMBNIÑ02.jpg','63', '1'),"..
		"(1736,'EDOGMBNIÑ10','GORRA NIÑO EL DORADO','EDOGMBNIÑ10.jpg','63', '1'),"..
		"(1737,'EDOGMBNIÑ11','GORRA NIÑO EL DORADO','EDOGMBNIÑ11.jpg','63', '1'),"..
		"(1738,'EDOGMBNIÑ12','GORRA NIÑO EL DORADO','EDOGMBNIÑ12.jpg','63', '1'),"..
		"(1739,'EDOGMBNIÑ15','GORRA NIÑO EL DORADO','EDOGMBNIÑ15.jpg','63', '1'),"..
		"(1740,'EDOGMBNMA62','GORRA NIÑA EL DORADO','EDOGMBNMA62.jpg','68', '1'),"..
		"(1741,'EDOGMBNMA63','GORRA NIÑA EL DORADO','EDOGMBNMA63.jpg','68', '1'),"..
		"(1742,'EDOGMBNMA64','GORRA NIÑA EL DORADO','EDOGMBNMA64.jpg','68', '1'),"..
		"(1743,'EDOGMBNMA65','GORRA NIÑA EL DORADO','EDOGMBNMA65.jpg','68', '1'),"..
		"(1744,'EDOGMBSAN02','GORRA SANDWICH EL DORADO','EDOGMBSAN02.jpg','68', '1'),"..
		"(1745,'EDOGMBSAN03','GORRA SANDWICH EL DORADO','EDOGMBSAN03.jpg','68', '1'),"..
		"(1746,'EDOGMBSAN05','GORRA SANDWICH EL DORADO','EDOGMBSAN05.jpg','68', '1'),"..
		"(1747,'EDOGMBSAN06','GORRA SANDWICH EL DORADO','EDOGMBSAN06.jpg','68', '1'),"..
		"(1748,'EDOGMBSAN07','GORRA SANDWICH EL DORADO','EDOGMBSAN07.jpg','68', '1'),"..
		"(1749,'EDOGMBSAN11','GORRA SANDWICH EL DORADO','EDOGMBSAN11.jpg','68', '1'),"..
		"(1750,'EDOGMBSAN13','GORRA SANDWICH EL DORADO','EDOGMBSAN13.jpg','68', '1'),"..
		"(1751,'EDOGMBSAN20','GORRA SANDWICH EL DORADO','EDOGMBSAN20.jpg','68', '1'),"..
		"(1752,'EDOGMBSAN22','GORRA SANDWICH EL DORADO','EDOGMBSAN22.jpg','68', '1'),"..
		"(1753,'EDOGMBSAN30','GORRA SANDWICH EL DORADO','EDOGMBSAN30.jpg','68', '1'),"..
		"(1754,'EDOGMBSAN32','GORRA SANDWICH EL DORADO','EDOGMBSAN32.jpg','68', '1'),"..
		"(1755,'EDOGMBSAN33','GORRA SANDWICH EL DORADO','EDOGMBSAN33.jpg','68', '1'),"..
		"(1756,'EDOGMBSAN36','GORRA SANDWICH EL DORADO','EDOGMBSAN36.jpg','68', '1'),"..
		"(1757,'EDOGMBSAN39','GORRA SANDWICH EL DORADO','EDOGMBSAN39.jpg','68', '1'),"..
		"(1758,'EDOGMBSAN43','GORRA SANDWICH EL DORADO','EDOGMBSAN43.jpg','68', '1'),"..
		"(1759,'EDOGMBSAN45','GORRA SANDWICH EL DORADO','EDOGMBSAN45.jpg','68', '1'),"..
		"(1760,'EDOGMBSAN49','GORRA SANDWICH EL DORADO','EDOGMBSAN49.jpg','68', '1'),"..
		"(1761,'EDOGMBSAN51','GORRA SANDWICH EL DORADO','EDOGMBSAN51.jpg','68', '1'),"..
		"(1762,'EDOSMBGUI03','SOMBRERO GUILLIGAN','EDOSMBGUI03.jpg','73', '1'),"..
		"(1763,'EDOSMBGUI10','SOMBRERO GUILLIGAN','EDOSMBGUI10.jpg','73', '1'),"..
		"(1764,'EDOSMBGUI11','SOMBRERO GUILLIGAN','EDOSMBGUI11.jpg','73', '1'),"..
		"(1765,'EDOSMBGUI12','SOMBRERO GUILLIGAN','EDOSMBGUI12.jpg','73', '1'),"..
		"(1766,'EDOSMBGUI13','SOMBRERO GUILLIGAN','EDOSMBGUI13.jpg','73', '1'),"..
		"(1767,'EDOSMBGUI28','SOMBRERO GUILLIGAN','EDOSMBGUI28.jpg','73', '1'),"..
		"(1768,'EDOSMBGUI30','SOMBRERO GUILLIGAN','EDOSMBGUI30.jpg','73', '1'),"..
		"(1769,'EDRGDKMFI03','GORRA MICRO FIBRA EL DORADO ROYAL','EDRGDKMFI03.jpg','76', '1'),"..
		"(1770,'EDRGDKMFI11','GORRA MICRO FIBRA EL DORADO ROYAL','EDRGDKMFI11.jpg','76', '1'),"..
		"(1771,'EDRGDKMFI13','GORRA MICRO FIBRA EL DORADO ROYAL','EDRGDKMFI13.jpg','76', '1'),"..
		"(1772,'EDRGDKMFI16','GORRA MICRO FIBRA EL DORADO ROYAL','EDRGDKMFI16.jpg','76', '1'),"..
		"(1773,'EDRGGE00111','GORRA GENERICA 2 TORTUGAS NADANDO','EDRGGE00111.jpg','68', '1'),"..
		"(1774,'EDRGGE00216','GORRA GENERICA PARCHE KAKI','EDRGGE00216.jpg','68', '1'),"..
		"(1775,'EDRGGE00373','GORRA GENERICA PIRATAS','EDRGGE00373.jpg','68', '1'),"..
		"(1776,'EDRGGE00713','GORRA GENERICA PARCHE MILITAR','EDRGGE00713.jpg','68', '1'),"..
		"(1777,'EDRGGE00803','GORRA GENERICA APLICACION AGUILA','EDRGGE00803.jpg','68', '1'),"..
		"(1778,'EDRGMBARC04','GORRA ARCOIRIS EL DORADO ROYAL','EDRGMBARC04.jpg','68', '1'),"..
		"(1779,'EDRGMBARC18','GORRA ARCOIRIS EL DORADO ROYAL','EDRGMBARC18.jpg','68', '1'),"..
		"(1780,'EDRGMBARC29','GORRA ARCOIRIS EL DORADO ROYAL','EDRGMBARC29.jpg','68', '1'),"..
		"(1781,'EDRGMBARC38','GORRA ARCOIRIS EL DORADO ROYAL','EDRGMBARC38.jpg','68', '1'),"..
		"(1782,'EDRGMBDAM04','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM04.jpg','63', '1'),"..
		"(1783,'EDRGMBDAM12','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM12.jpg','63', '1'),"..
		"(1784,'EDRGMBDAM17','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM17.jpg','63', '1'),"..
		"(1785,'EDRGMBDAM18','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM18.jpg','63', '1'),"..
		"(1786,'EDRGMBDAM19','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM19.jpg','63', '1'),"..
		"(1787,'EDRGMBDAM29','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM29.jpg','63', '1'),"..
		"(1788,'EDRGMBDAM40','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM40.jpg','63', '1'),"..
		"(1789,'EDRGMBDAM41','GORRA DAMA EL DORADO ROYAL','EDRGMBDAM41.jpg','63', '1'),"..
		"(1790,'EDRGMBDES04','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES04.jpg','63', '1'),"..
		"(1791,'EDRGMBDES05','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES05.jpg','63', '1'),"..
		"(1792,'EDRGMBDES06','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES06.jpg','63', '1'),"..
		"(1793,'EDRGMBDES10','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES10.jpg','63', '1'),"..
		"(1794,'EDRGMBDES11','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES11.jpg','63', '1'),"..
		"(1795,'EDRGMBDES12','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES12.jpg','63', '1'),"..
		"(1796,'EDRGMBDES13','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES13.jpg','63', '1'),"..
		"(1797,'EDRGMBDES15','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES15.jpg','63', '1'),"..
		"(1798,'EDRGMBDES16','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES16.jpg','63', '1'),"..
		"(1799,'EDRGMBDES21','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES21.jpg','63', '1'),"..
		"(1800,'EDRGMBDES25','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES25.jpg','63', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1801,'EDRGMBDES26','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES26.jpg','63', '1'),"..
		"(1802,'EDRGMBDES28','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES28.jpg','63', '1'),"..
		"(1803,'EDRGMBDES30','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES30.jpg','63', '1'),"..
		"(1804,'EDRGMBDES32','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES32.jpg','63', '1'),"..
		"(1805,'EDRGMBDES34','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES34.jpg','63', '1'),"..
		"(1806,'EDRGMBDES35','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES35.jpg','63', '1'),"..
		"(1807,'EDRGMBDES37','GORRA DESLAVADA EL DORADO ROYAL','EDRGMBDES37.jpg','63', '1'),"..
		"(1808,'EDRGMBNIÑ02','GORRA NIÑO EL DORADO ROYAL','EDRGMBNIÑ02.jpg','63', '1'),"..
		"(1809,'EDRGMBNIÑ10','GORRA NIÑO EL DORADO ROYAL','EDRGMBNIÑ10.jpg','63', '1'),"..
		"(1810,'EDRGMBNIÑ11','GORRA NIÑO EL DORADO ROYAL','EDRGMBNIÑ11.jpg','63', '1'),"..
		"(1811,'EDRGMBNIÑ12','GORRA NIÑO EL DORADO ROYAL','EDRGMBNIÑ12.jpg','63', '1'),"..
		"(1812,'EDRGMBNIÑ15','GORRA NIÑO EL DORADO ROYAL','EDRGMBNIÑ15.jpg','63', '1'),"..
		"(1813,'EDRGMBSAN02','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN02.jpg','68', '1'),"..
		"(1814,'EDRGMBSAN03','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN03.jpg','68', '1'),"..
		"(1815,'EDRGMBSAN05','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN05.jpg','68', '1'),"..
		"(1816,'EDRGMBSAN06','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN06.jpg','68', '1'),"..
		"(1817,'EDRGMBSAN07','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN07.jpg','68', '1'),"..
		"(1818,'EDRGMBSAN11','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN11.jpg','68', '1'),"..
		"(1819,'EDRGMBSAN13','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN13.jpg','68', '1'),"..
		"(1820,'EDRGMBSAN20','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN20.jpg','68', '1'),"..
		"(1821,'EDRGMBSAN22','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN22.jpg','68', '1'),"..
		"(1822,'EDRGMBSAN30','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN30.jpg','68', '1'),"..
		"(1823,'EDRGMBSAN32','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN32.jpg','68', '1'),"..
		"(1824,'EDRGMBSAN33','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN33.jpg','68', '1'),"..
		"(1825,'EDRGMBSAN36','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN36.jpg','68', '1'),"..
		"(1826,'EDRGMBSAN39','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN39.jpg','68', '1'),"..
		"(1827,'EDRGMBSAN43','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN43.jpg','68', '1'),"..
		"(1828,'EDRGMBSAN45','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN45.jpg','68', '1'),"..
		"(1829,'EDRGMBSAN49','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN49.jpg','68', '1'),"..
		"(1830,'EDRGMBSAN51','GORRA SANDWICH EL DORADO ROYAL','EDRGMBSAN51.jpg','68', '1'),"..
		"(1831,'EDRSMBGUI03','SOMBRERO GUILLIGAN','EDRSMBGUI03.jpg','73', '1'),"..
		"(1832,'EDRSMBGUI10','SOMBRERO GUILLIGAN','EDRSMBGUI10.jpg','73', '1'),"..
		"(1833,'EDRSMBGUI11','SOMBRERO GUILLIGAN','EDRSMBGUI11.jpg','73', '1'),"..
		"(1834,'EDRSMBGUI12','SOMBRERO GUILLIGAN','EDRSMBGUI12.jpg','73', '1'),"..
		"(1835,'EDRSMBGUI13','SOMBRERO GUILLIGAN','EDRSMBGUI13.jpg','73', '1'),"..
		"(1836,'EDRSMBGUI28','SOMBRERO GUILLIGAN','EDRSMBGUI28.jpg','73', '1'),"..
		"(1837,'EDRSMBGUI30','SOMBRERO GUILLIGAN','EDRSMBGUI30.jpg','73', '1'),"..
		"(1838,'EDSSGDKMFI03','GORRA MICRO FIBRA EL DORADO ROYAL SEA SIDE','EDSSGDKMFI03.jpg','76', '1'),"..
		"(1839,'EDSSGDKMFI11','GORRA MICRO FIBRA EL DORADO ROYAL SEA SIDE','EDSSGDKMFI11.jpg','76', '1'),"..
		"(1840,'EDSSGDKMFI13','GORRA MICRO FIBRA EL DORADO ROYAL SEA SIDE','EDSSGDKMFI13.jpg','76', '1'),"..
		"(1841,'EDSSGDKMFI16','GORRA MICRO FIBRA EL DORADO ROYAL SEA SIDE','EDSSGDKMFI16.jpg','76', '1'),"..
		"(1842,'EDSSGMBDAM04','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM04.jpg','63', '1'),"..
		"(1843,'EDSSGMBDAM12','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM12.jpg','63', '1'),"..
		"(1844,'EDSSGMBDAM17','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM17.jpg','63', '1'),"..
		"(1845,'EDSSGMBDAM18','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM18.jpg','63', '1'),"..
		"(1846,'EDSSGMBDAM19','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM19.jpg','63', '1'),"..
		"(1847,'EDSSGMBDAM29','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM29.jpg','63', '1'),"..
		"(1848,'EDSSGMBDAM40','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM40.jpg','63', '1'),"..
		"(1849,'EDSSGMBDAM41','GORRA DAMA EL DORADO ROYAL SEA SIDE','EDSSGMBDAM41.jpg','63', '1'),"..
		"(1850,'EDSSGMBNIÑ02','GORRA NIÑO EL DORADO SEA SIDE','EDSSGMBNIÑ02.jpg','63', '1'),"..
		"(1851,'EDSSGMBNIÑ10','GORRA NIÑO EL DORADO SEA SIDE','EDSSGMBNIÑ10.jpg','63', '1'),"..
		"(1852,'EDSSGMBNIÑ11','GORRA NIÑO EL DORADO SEA SIDE','EDSSGMBNIÑ11.jpg','63', '1'),"..
		"(1853,'EDSSGMBNIÑ12','GORRA NIÑO EL DORADO SEA SIDE','EDSSGMBNIÑ12.jpg','63', '1'),"..
		"(1854,'EDSSGMBNIÑ15','GORRA NIÑO EL DORADO SEA SIDE','EDSSGMBNIÑ15.jpg','63', '1'),"..
		"(1855,'EDSSGMBSAN02','GORRA SANDWICH SEA SIDE','EDSSGMBSAN02.jpg','68', '1'),"..
		"(1856,'EDSSGMBSAN03','GORRA SANDWICH SEA SIDE','EDSSGMBSAN03.jpg','68', '1'),"..
		"(1857,'EDSSGMBSAN05','GORRA SANDWICH SEA SIDE','EDSSGMBSAN05.jpg','68', '1'),"..
		"(1858,'EDSSGMBSAN06','GORRA SANDWICH SEA SIDE','EDSSGMBSAN06.jpg','68', '1'),"..
		"(1859,'EDSSGMBSAN07','GORRA SANDWICH SEA SIDE','EDSSGMBSAN07.jpg','68', '1'),"..
		"(1860,'EDSSGMBSAN11','GORRA SANDWICH SEA SIDE','EDSSGMBSAN11.jpg','68', '1'),"..
		"(1861,'EDSSGMBSAN13','GORRA SANDWICH SEA SIDE','EDSSGMBSAN13.jpg','68', '1'),"..
		"(1862,'EDSSGMBSAN20','GORRA SANDWICH SEA SIDE','EDSSGMBSAN20.jpg','68', '1'),"..
		"(1863,'EDSSGMBSAN22','GORRA SANDWICH SEA SIDE','EDSSGMBSAN22.jpg','68', '1'),"..
		"(1864,'EDSSGMBSAN30','GORRA SANDWICH SEA SIDE','EDSSGMBSAN30.jpg','68', '1'),"..
		"(1865,'EDSSGMBSAN32','GORRA SANDWICH SEA SIDE','EDSSGMBSAN32.jpg','68', '1'),"..
		"(1866,'EDSSGMBSAN33','GORRA SANDWICH SEA SIDE','EDSSGMBSAN33.jpg','68', '1'),"..
		"(1867,'EDSSGMBSAN36','GORRA SANDWICH SEA SIDE','EDSSGMBSAN36.jpg','68', '1'),"..
		"(1868,'EDSSGMBSAN39','GORRA SANDWICH SEA SIDE','EDSSGMBSAN39.jpg','68', '1'),"..
		"(1869,'EDSSGMBSAN43','GORRA SANDWICH SEA SIDE','EDSSGMBSAN43.jpg','68', '1'),"..
		"(1870,'EDSSGMBSAN45','GORRA SANDWICH SEA SIDE','EDSSGMBSAN45.jpg','68', '1'),"..
		"(1871,'EDSSGMBSAN49','GORRA SANDWICH SEA SIDE','EDSSGMBSAN49.jpg','68', '1'),"..
		"(1872,'EDSSGMBSAN51','GORRA SANDWICH SEA SIDE','EDSSGMBSAN51.jpg','68', '1'),"..
		"(1873,'EMPCOA00102','COMBO ADULTO EMPORIO','EMPCOA00102.jpg','99', '1'),"..
		"(1874,'EMPCOA00105','COMBO ADULTO EMPORIO','EMPCOA00105.jpg','99', '1'),"..
		"(1875,'EMPCOA00106','COMBO ADULTO EMPORIO','EMPCOA00106.jpg','99', '1'),"..
		"(1876,'EMPCOA00110','COMBO ADULTO EMPORIO','EMPCOA00110.jpg','99', '1'),"..
		"(1877,'EMPCOA00111','COMBO ADULTO EMPORIO','EMPCOA00111.jpg','99', '1'),"..
		"(1878,'EMPCOA00112','COMBO ADULTO EMPORIO','EMPCOA00112.jpg','99', '1'),"..
		"(1879,'EMPCOA00113','COMBO ADULTO EMPORIO','EMPCOA00113.jpg','99', '1'),"..
		"(1880,'EMPCOA00115','COMBO ADULTO EMPORIO','EMPCOA00115.jpg','99', '1'),"..
		"(1881,'EMPCOA00121','COMBO ADULTO EMPORIO','EMPCOA00121.jpg','99', '1'),"..
		"(1882,'EMPCOA00125','COMBO ADULTO EMPORIO','EMPCOA00125.jpg','99', '1'),"..
		"(1883,'EMPCOA00126','COMBO ADULTO EMPORIO','EMPCOA00126.jpg','99', '1'),"..
		"(1884,'EMPCOA00128','COMBO ADULTO EMPORIO','EMPCOA00128.jpg','99', '1'),"..
		"(1885,'EMPCOA00130','COMBO ADULTO EMPORIO','EMPCOA00130.jpg','99', '1'),"..
		"(1886,'EMPCOA00132','COMBO ADULTO EMPORIO','EMPCOA00132.jpg','99', '1'),"..
		"(1887,'EMPCOA00134','COMBO ADULTO EMPORIO','EMPCOA00134.jpg','99', '1'),"..
		"(1888,'EMPCOA00135','COMBO ADULTO EMPORIO','EMPCOA00135.jpg','99', '1'),"..
		"(1889,'EMPCOA001XXL02','COMBO ADULTO EMPORIO','EMPCOA001XXL02.jpg','110', '1'),"..
		"(1890,'EMPCOA001XXL05','COMBO ADULTO EMPORIO','EMPCOA001XXL05.jpg','110', '1'),"..
		"(1891,'EMPCOA001XXL06','COMBO ADULTO EMPORIO','EMPCOA001XXL06.jpg','110', '1'),"..
		"(1892,'EMPCOA001XXL10','COMBO ADULTO EMPORIO','EMPCOA001XXL10.jpg','110', '1'),"..
		"(1893,'EMPCOA001XXL11','COMBO ADULTO EMPORIO','EMPCOA001XXL11.jpg','110', '1'),"..
		"(1894,'EMPCOA001XXL12','COMBO ADULTO EMPORIO','EMPCOA001XXL12.jpg','110', '1'),"..
		"(1895,'EMPCOA001XXL13','COMBO ADULTO EMPORIO','EMPCOA001XXL13.jpg','110', '1'),"..
		"(1896,'EMPCOA001XXL15','COMBO ADULTO EMPORIO','EMPCOA001XXL15.jpg','110', '1'),"..
		"(1897,'EMPCOA001XXL21','COMBO ADULTO EMPORIO','EMPCOA001XXL21.jpg','110', '1'),"..
		"(1898,'EMPCOA001XXL25','COMBO ADULTO EMPORIO','EMPCOA001XXL25.jpg','110', '1'),"..
		"(1899,'EMPCOA001XXL26','COMBO ADULTO EMPORIO','EMPCOA001XXL26.jpg','110', '1'),"..
		"(1900,'EMPCOA001XXL28','COMBO ADULTO EMPORIO','EMPCOA001XXL28.jpg','110', '1'),"..
		"(1901,'EMPCOA001XXL30','COMBO ADULTO EMPORIO','EMPCOA001XXL30.jpg','110', '1'),"..
		"(1902,'EMPCOA001XXL32','COMBO ADULTO EMPORIO','EMPCOA001XXL32.jpg','110', '1'),"..
		"(1903,'EMPCOA001XXL34','COMBO ADULTO EMPORIO','EMPCOA001XXL34.jpg','110', '1'),"..
		"(1904,'EMPCOA001XXL35','COMBO ADULTO EMPORIO','EMPCOA001XXL35.jpg','110', '1'),"..
		"(1905,'FTS-100009','SHORTS DAMA','FTS-100009.jpg','135', '1'),"..
		"(1906,'FTS-100011','SHORTS DAMA','FTS-100011.jpg','135', '1'),"..
		"(1907,'FTS-100013','SHORTS DAMA','FTS-100013.jpg','135', '1'),"..
		"(1908,'GRSCOA00102','COMBO ADULTO GRAN SIRENIS','GRSCOA00102.jpg','99', '1'),"..
		"(1909,'GRSCOA00105','COMBO ADULTO GRAN SIRENIS','GRSCOA00105.jpg','99', '1'),"..
		"(1910,'GRSCOA00106','COMBO ADULTO GRAN SIRENIS','GRSCOA00106.jpg','99', '1'),"..
		"(1911,'GRSCOA00110','COMBO ADULTO GRAN SIRENIS','GRSCOA00110.jpg','99', '1'),"..
		"(1912,'GRSCOA00111','COMBO ADULTO GRAN SIRENIS','GRSCOA00111.jpg','99', '1'),"..
		"(1913,'GRSCOA00112','COMBO ADULTO GRAN SIRENIS','GRSCOA00112.jpg','99', '1'),"..
		"(1914,'GRSCOA00113','COMBO ADULTO GRAN SIRENIS','GRSCOA00113.jpg','99', '1'),"..
		"(1915,'GRSCOA00115','COMBO ADULTO GRAN SIRENIS','GRSCOA00115.jpg','99', '1'),"..
		"(1916,'GRSCOA00121','COMBO ADULTO GRAN SIRENIS','GRSCOA00121.jpg','99', '1'),"..
		"(1917,'GRSCOA00125','COMBO ADULTO GRAN SIRENIS','GRSCOA00125.jpg','99', '1'),"..
		"(1918,'GRSCOA00126','COMBO ADULTO GRAN SIRENIS','GRSCOA00126.jpg','99', '1'),"..
		"(1919,'GRSCOA00128','COMBO ADULTO GRAN SIRENIS','GRSCOA00128.jpg','99', '1'),"..
		"(1920,'GRSCOA00130','COMBO ADULTO GRAN SIRENIS','GRSCOA00130.jpg','99', '1'),"..
		"(1921,'GRSCOA00132','COMBO ADULTO GRAN SIRENIS','GRSCOA00132.jpg','99', '1'),"..
		"(1922,'GRSCOA00134','COMBO ADULTO GRAN SIRENIS','GRSCOA00134.jpg','99', '1'),"..
		"(1923,'GRSCOA00135','COMBO ADULTO GRAN SIRENIS','GRSCOA00135.jpg','99', '1'),"..
		"(1924,'GRSCOA001XXL02','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL02.jpg','110', '1'),"..
		"(1925,'GRSCOA001XXL05','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL05.jpg','110', '1'),"..
		"(1926,'GRSCOA001XXL06','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL06.jpg','110', '1'),"..
		"(1927,'GRSCOA001XXL10','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL10.jpg','110', '1'),"..
		"(1928,'GRSCOA001XXL11','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL11.jpg','110', '1'),"..
		"(1929,'GRSCOA001XXL12','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL12.jpg','110', '1'),"..
		"(1930,'GRSCOA001XXL13','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL13.jpg','110', '1'),"..
		"(1931,'GRSCOA001XXL15','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL15.jpg','110', '1'),"..
		"(1932,'GRSCOA001XXL21','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL21.jpg','110', '1'),"..
		"(1933,'GRSCOA001XXL25','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL25.jpg','110', '1'),"..
		"(1934,'GRSCOA001XXL26','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL26.jpg','110', '1'),"..
		"(1935,'GRSCOA001XXL28','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL28.jpg','110', '1'),"..
		"(1936,'GRSCOA001XXL30','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL30.jpg','110', '1'),"..
		"(1937,'GRSCOA001XXL32','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL32.jpg','110', '1'),"..
		"(1938,'GRSCOA001XXL34','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL34.jpg','110', '1'),"..
		"(1939,'GRSCOA001XXL35','COMBO ADULTO GRAN SIRENIS','GRSCOA001XXL35.jpg','110', '1'),"..
		"(1940,'GRSGMBDES04','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES04.jpg','63', '1'),"..
		"(1941,'GRSGMBDES05','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES05.jpg','63', '1'),"..
		"(1942,'GRSGMBDES06','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES06.jpg','63', '1'),"..
		"(1943,'GRSGMBDES10','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES10.jpg','63', '1'),"..
		"(1944,'GRSGMBDES11','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES11.jpg','63', '1'),"..
		"(1945,'GRSGMBDES12','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES12.jpg','63', '1'),"..
		"(1946,'GRSGMBDES13','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES13.jpg','63', '1'),"..
		"(1947,'GRSGMBDES15','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES15.jpg','63', '1'),"..
		"(1948,'GRSGMBDES16','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES16.jpg','63', '1'),"..
		"(1949,'GRSGMBDES21','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES21.jpg','63', '1'),"..
		"(1950,'GRSGMBDES25','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES25.jpg','63', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(1951,'GRSGMBDES26','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES26.jpg','63', '1'),"..
		"(1952,'GRSGMBDES28','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES28.jpg','63', '1'),"..
		"(1953,'GRSGMBDES30','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES30.jpg','63', '1'),"..
		"(1954,'GRSGMBDES32','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES32.jpg','63', '1'),"..
		"(1955,'GRSGMBDES34','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES34.jpg','63', '1'),"..
		"(1956,'GRSGMBDES35','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES35.jpg','63', '1'),"..
		"(1957,'GRSGMBDES37','GORRA DESLAVADA GRAN SIRENIS','GRSGMBDES37.jpg','63', '1'),"..
		"(1958,'GRSGMBSAN02','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN02.jpg','68', '1'),"..
		"(1959,'GRSGMBSAN03','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN03.jpg','68', '1'),"..
		"(1960,'GRSGMBSAN05','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN05.jpg','68', '1'),"..
		"(1961,'GRSGMBSAN06','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN06.jpg','68', '1'),"..
		"(1962,'GRSGMBSAN07','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN07.jpg','68', '1'),"..
		"(1963,'GRSGMBSAN11','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN11.jpg','68', '1'),"..
		"(1964,'GRSGMBSAN13','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN13.jpg','68', '1'),"..
		"(1965,'GRSGMBSAN20','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN20.jpg','68', '1'),"..
		"(1966,'GRSGMBSAN22','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN22.jpg','68', '1'),"..
		"(1967,'GRSGMBSAN30','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN30.jpg','68', '1'),"..
		"(1968,'GRSGMBSAN32','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN32.jpg','68', '1'),"..
		"(1969,'GRSGMBSAN33','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN33.jpg','68', '1'),"..
		"(1970,'GRSGMBSAN36','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN36.jpg','68', '1'),"..
		"(1971,'GRSGMBSAN39','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN39.jpg','68', '1'),"..
		"(1972,'GRSGMBSAN43','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN43.jpg','68', '1'),"..
		"(1973,'GRSGMBSAN45','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN45.jpg','68', '1'),"..
		"(1974,'GRSGMBSAN49','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN49.jpg','68', '1'),"..
		"(1975,'GRSGMBSAN51','GORRA SANDWICH GRAN SIRENIS','GRSGMBSAN51.jpg','68', '1'),"..
		"(1976,'HIDCOA00102','COMBO ADULTO HIDDEN','HIDCOA00102.jpg','99', '1'),"..
		"(1977,'HIDCOA00105','COMBO ADULTO HIDDEN','HIDCOA00105.jpg','99', '1'),"..
		"(1978,'HIDCOA00106','COMBO ADULTO HIDDEN','HIDCOA00106.jpg','99', '1'),"..
		"(1979,'HIDCOA00110','COMBO ADULTO HIDDEN','HIDCOA00110.jpg','99', '1'),"..
		"(1980,'HIDCOA00111','COMBO ADULTO HIDDEN','HIDCOA00111.jpg','99', '1'),"..
		"(1981,'HIDCOA00112','COMBO ADULTO HIDDEN','HIDCOA00112.jpg','99', '1'),"..
		"(1982,'HIDCOA00113','COMBO ADULTO HIDDEN','HIDCOA00113.jpg','99', '1'),"..
		"(1983,'HIDCOA00115','COMBO ADULTO HIDDEN','HIDCOA00115.jpg','99', '1'),"..
		"(1984,'HIDCOA00121','COMBO ADULTO HIDDEN','HIDCOA00121.jpg','99', '1'),"..
		"(1985,'HIDCOA00125','COMBO ADULTO HIDDEN','HIDCOA00125.jpg','99', '1'),"..
		"(1986,'HIDCOA00126','COMBO ADULTO HIDDEN','HIDCOA00126.jpg','99', '1'),"..
		"(1987,'HIDCOA00128','COMBO ADULTO HIDDEN','HIDCOA00128.jpg','99', '1'),"..
		"(1988,'HIDCOA00130','COMBO ADULTO HIDDEN','HIDCOA00130.jpg','99', '1'),"..
		"(1989,'HIDCOA00132','COMBO ADULTO HIDDEN','HIDCOA00132.jpg','99', '1'),"..
		"(1990,'HIDCOA00134','COMBO ADULTO HIDDEN','HIDCOA00134.jpg','99', '1'),"..
		"(1991,'HIDCOA00135','COMBO ADULTO HIDDEN','HIDCOA00135.jpg','99', '1'),"..
		"(1992,'HIDCOA001XXL02','COMBO ADULTO HIDDEN','HIDCOA001XXL02.jpg','110', '1'),"..
		"(1993,'HIDCOA001XXL05','COMBO ADULTO HIDDEN','HIDCOA001XXL05.jpg','110', '1'),"..
		"(1994,'HIDCOA001XXL06','COMBO ADULTO HIDDEN','HIDCOA001XXL06.jpg','110', '1'),"..
		"(1995,'HIDCOA001XXL10','COMBO ADULTO HIDDEN','HIDCOA001XXL10.jpg','110', '1'),"..
		"(1996,'HIDCOA001XXL11','COMBO ADULTO HIDDEN','HIDCOA001XXL11.jpg','110', '1'),"..
		"(1997,'HIDCOA001XXL12','COMBO ADULTO HIDDEN','HIDCOA001XXL12.jpg','110', '1'),"..
		"(1998,'HIDCOA001XXL13','COMBO ADULTO HIDDEN','HIDCOA001XXL13.jpg','110', '1'),"..
		"(1999,'HIDCOA001XXL15','COMBO ADULTO HIDDEN','HIDCOA001XXL15.jpg','110', '1'),"..
		"(2000,'HIDCOA001XXL21','COMBO ADULTO HIDDEN','HIDCOA001XXL21.jpg','110', '1'),"..
		"(2001,'HIDCOA001XXL25','COMBO ADULTO HIDDEN','HIDCOA001XXL25.jpg','110', '1'),"..
		"(2002,'HIDCOA001XXL26','COMBO ADULTO HIDDEN','HIDCOA001XXL26.jpg','110', '1'),"..
		"(2003,'HIDCOA001XXL28','COMBO ADULTO HIDDEN','HIDCOA001XXL28.jpg','110', '1'),"..
		"(2004,'HIDCOA001XXL30','COMBO ADULTO HIDDEN','HIDCOA001XXL30.jpg','110', '1'),"..
		"(2005,'HIDCOA001XXL32','COMBO ADULTO HIDDEN','HIDCOA001XXL32.jpg','110', '1'),"..
		"(2006,'HIDCOA001XXL34','COMBO ADULTO HIDDEN','HIDCOA001XXL34.jpg','110', '1'),"..
		"(2007,'HIDCOA001XXL35','COMBO ADULTO HIDDEN','HIDCOA001XXL35.jpg','110', '1'),"..
		"(2008,'HIDGDKMFI03','GORRA MICRO FIBRA HIDDEN','HIDGDKMFI03.jpg','76', '1'),"..
		"(2009,'HIDGDKMFI11','GORRA MICRO FIBRA HIDDEN','HIDGDKMFI11.jpg','76', '1'),"..
		"(2010,'HIDGDKMFI13','GORRA MICRO FIBRA HIDDEN','HIDGDKMFI13.jpg','76', '1'),"..
		"(2011,'HIDGDKMFI16','GORRA MICRO FIBRA HIDDEN','HIDGDKMFI16.jpg','76', '1'),"..
		"(2012,'HIDGMBDAM04','GORRA DAMA HIDDEN','HIDGMBDAM04.jpg','63', '1'),"..
		"(2013,'HIDGMBDAM12','GORRA DAMA HIDDEN','HIDGMBDAM12.jpg','63', '1'),"..
		"(2014,'HIDGMBDAM17','GORRA DAMA HIDDEN','HIDGMBDAM17.jpg','63', '1'),"..
		"(2015,'HIDGMBDAM18','GORRA DAMA HIDDEN','HIDGMBDAM18.jpg','63', '1'),"..
		"(2016,'HIDGMBDAM19','GORRA DAMA HIDDEN','HIDGMBDAM19.jpg','63', '1'),"..
		"(2017,'HIDGMBDAM29','GORRA DAMA HIDDEN','HIDGMBDAM29.jpg','63', '1'),"..
		"(2018,'HIDGMBDAM40','GORRA DAMA HIDDEN','HIDGMBDAM40.jpg','63', '1'),"..
		"(2019,'HIDGMBDAM41','GORRA DAMA HIDDEN','HIDGMBDAM41.jpg','63', '1'),"..
		"(2020,'HIDGMBDES04','GORRA DESLAVADA HIDDEN','HIDGMBDES04.jpg','63', '1'),"..
		"(2021,'HIDGMBDES05','GORRA DESLAVADA HIDDEN','HIDGMBDES05.jpg','63', '1'),"..
		"(2022,'HIDGMBDES06','GORRA DESLAVADA HIDDEN','HIDGMBDES06.jpg','63', '1'),"..
		"(2023,'HIDGMBDES10','GORRA DESLAVADA HIDDEN','HIDGMBDES10.jpg','63', '1'),"..
		"(2024,'HIDGMBDES11','GORRA DESLAVADA HIDDEN','HIDGMBDES11.jpg','63', '1'),"..
		"(2025,'HIDGMBDES12','GORRA DESLAVADA HIDDEN','HIDGMBDES12.jpg','63', '1'),"..
		"(2026,'HIDGMBDES13','GORRA DESLAVADA HIDDEN','HIDGMBDES13.jpg','63', '1'),"..
		"(2027,'HIDGMBDES15','GORRA DESLAVADA HIDDEN','HIDGMBDES15.jpg','63', '1'),"..
		"(2028,'HIDGMBDES16','GORRA DESLAVADA HIDDEN','HIDGMBDES16.jpg','63', '1'),"..
		"(2029,'HIDGMBDES21','GORRA DESLAVADA HIDDEN','HIDGMBDES21.jpg','63', '1'),"..
		"(2030,'HIDGMBDES25','GORRA DESLAVADA HIDDEN','HIDGMBDES25.jpg','63', '1'),"..
		"(2031,'HIDGMBDES26','GORRA DESLAVADA HIDDEN','HIDGMBDES26.jpg','63', '1'),"..
		"(2032,'HIDGMBDES28','GORRA DESLAVADA HIDDEN','HIDGMBDES28.jpg','63', '1'),"..
		"(2033,'HIDGMBDES30','GORRA DESLAVADA HIDDEN','HIDGMBDES30.jpg','63', '1'),"..
		"(2034,'HIDGMBDES32','GORRA DESLAVADA HIDDEN','HIDGMBDES32.jpg','63', '1'),"..
		"(2035,'HIDGMBDES34','GORRA DESLAVADA HIDDEN','HIDGMBDES34.jpg','63', '1'),"..
		"(2036,'HIDGMBDES35','GORRA DESLAVADA HIDDEN','HIDGMBDES35.jpg','63', '1'),"..
		"(2037,'HIDGMBDES37','GORRA DESLAVADA HIDDEN','HIDGMBDES37.jpg','63', '1'),"..
		"(2038,'HIDGMBSAN02','GORRA SANDWICH HIDDEN','HIDGMBSAN02.jpg','68', '1'),"..
		"(2039,'HIDGMBSAN03','GORRA SANDWICH HIDDEN','HIDGMBSAN03.jpg','68', '1'),"..
		"(2040,'HIDGMBSAN05','GORRA SANDWICH HIDDEN','HIDGMBSAN05.jpg','68', '1'),"..
		"(2041,'HIDGMBSAN06','GORRA SANDWICH HIDDEN','HIDGMBSAN06.jpg','68', '1'),"..
		"(2042,'HIDGMBSAN07','GORRA SANDWICH HIDDEN','HIDGMBSAN07.jpg','68', '1'),"..
		"(2043,'HIDGMBSAN11','GORRA SANDWICH HIDDEN','HIDGMBSAN11.jpg','68', '1'),"..
		"(2044,'HIDGMBSAN13','GORRA SANDWICH HIDDEN','HIDGMBSAN13.jpg','68', '1'),"..
		"(2045,'HIDGMBSAN20','GORRA SANDWICH HIDDEN','HIDGMBSAN20.jpg','68', '1'),"..
		"(2046,'HIDGMBSAN22','GORRA SANDWICH HIDDEN','HIDGMBSAN22.jpg','68', '1'),"..
		"(2047,'HIDGMBSAN30','GORRA SANDWICH HIDDEN','HIDGMBSAN30.jpg','68', '1'),"..
		"(2048,'HIDGMBSAN32','GORRA SANDWICH HIDDEN','HIDGMBSAN32.jpg','68', '1'),"..
		"(2049,'HIDGMBSAN33','GORRA SANDWICH HIDDEN','HIDGMBSAN33.jpg','68', '1'),"..
		"(2050,'HIDGMBSAN36','GORRA SANDWICH HIDDEN','HIDGMBSAN36.jpg','68', '1'),"..
		"(2051,'HIDGMBSAN39','GORRA SANDWICH HIDDEN','HIDGMBSAN39.jpg','68', '1'),"..
		"(2052,'HIDGMBSAN43','GORRA SANDWICH HIDDEN','HIDGMBSAN43.jpg','68', '1'),"..
		"(2053,'HIDGMBSAN45','GORRA SANDWICH HIDDEN','HIDGMBSAN45.jpg','68', '1'),"..
		"(2054,'HIDGMBSAN49','GORRA SANDWICH HIDDEN','HIDGMBSAN49.jpg','68', '1'),"..
		"(2055,'HIDGMBSAN51','GORRA SANDWICH HIDDEN','HIDGMBSAN51.jpg','68', '1'),"..
		"(2056,'LBS-03513','SHORTS DAMA','LBS-03513.jpg','135', '1'),"..
		"(2057,'LBS-03529','SHORTS DAMA','LBS-03529.jpg','135', '1'),"..
		"(2058,'LBS-03578','SHORTS DAMA','LBS-03578.jpg','135', '1'),"..
		"(2059,'LBS-100212','SHORTS DAMA','LBS-100212.jpg','135', '1'),"..
		"(2060,'LBS-100213','SHORTS DAMA','LBS-100213.jpg','135', '1'),"..
		"(2061,'LBS-100217','SHORTS DAMA','LBS-100217.jpg','135', '1'),"..
		"(2062,'LBS-100271','SHORTS DAMA','LBS-100271.jpg','135', '1'),"..
		"(2063,'LBS-10312','SHORTS DAMA','LBS-10312.jpg','135', '1'),"..
		"(2064,'LBS-10317','SHORTS DAMA','LBS-10317.jpg','135', '1'),"..
		"(2065,'LBS-10318','SHORTS DAMA','LBS-10318.jpg','135', '1'),"..
		"(2066,'LBS-10371','SHORTS DAMA','LBS-10371.jpg','135', '1'),"..
		"(2067,'LFT-30013','TANK TOP DAMA','LFT-30013.jpg','75', '1'),"..
		"(2068,'LFT-30029','TANK TOP DAMA','LFT-30029.jpg','75', '1'),"..
		"(2069,'LJT-10217','TANK TOP DAMA','LJT-10217.jpg','85', '1'),"..
		"(2070,'LJT-10229','TANK TOP DAMA','LJT-10229.jpg','85', '1'),"..
		"(2071,'LJT-10278','TANK TOP DAMA','LJT-10278.jpg','85', '1'),"..
		"(2072,'LJT-20029','BLUSA DAMA MODA','LJT-20029.jpg','85', '1'),"..
		"(2073,'LMT-10012','TANK TOP RED DAMA','LMT-10012.jpg','75', '1'),"..
		"(2074,'LMT-10013','TANK TOP RED DAMA','LMT-10013.jpg','75', '1'),"..
		"(2075,'LMT-10017','TANK TOP RED DAMA','LMT-10017.jpg','75', '1'),"..
		"(2076,'LMT-10018','TANK TOP RED DAMA','LMT-10018.jpg','75', '1'),"..
		"(2077,'LMT-10071','TANK TOP RED DAMA','LMT-10071.jpg','75', '1'),"..
		"(2078,'LSV-10012','BLUSA DAMA CUELLO V','LSV-10012.jpg','85', '1'),"..
		"(2079,'LSV-10017','BLUSA DAMA CUELLO V','LSV-10017.jpg','85', '1'),"..
		"(2080,'LSV-10071','BLUSA DAMA CUELLO V','LSV-10071.jpg','85', '1'),"..
		"(2081,'MARGDKMFI03','GORRA MICRO FIBRA MAROMA','MARGDKMFI03.jpg','76', '1'),"..
		"(2082,'MARGDKMFI11','GORRA MICRO FIBRA MAROMA','MARGDKMFI11.jpg','76', '1'),"..
		"(2083,'MARGDKMFI13','GORRA MICRO FIBRA MAROMA','MARGDKMFI13.jpg','76', '1'),"..
		"(2084,'MARGDKMFI16','GORRA MICRO FIBRA MAROMA','MARGDKMFI16.jpg','76', '1'),"..
		"(2085,'MARGMBDAM04','GORRA DAMA MAROMA','MARGMBDAM04.jpg','63', '1'),"..
		"(2086,'MARGMBDAM12','GORRA DAMA MAROMA','MARGMBDAM12.jpg','63', '1'),"..
		"(2087,'MARGMBDAM17','GORRA DAMA MAROMA','MARGMBDAM17.jpg','63', '1'),"..
		"(2088,'MARGMBDAM18','GORRA DAMA MAROMA','MARGMBDAM18.jpg','63', '1'),"..
		"(2089,'MARGMBDAM19','GORRA DAMA MAROMA','MARGMBDAM19.jpg','63', '1'),"..
		"(2090,'MARGMBDAM29','GORRA DAMA MAROMA','MARGMBDAM29.jpg','63', '1'),"..
		"(2091,'MARGMBDAM40','GORRA DAMA MAROMA','MARGMBDAM40.jpg','63', '1'),"..
		"(2092,'MARGMBDAM41','GORRA DAMA MAROMA','MARGMBDAM41.jpg','63', '1'),"..
		"(2093,'MARGMBDES04','GORRA DESLAVADA MAROMA','MARGMBDES04.jpg','63', '1'),"..
		"(2094,'MARGMBDES05','GORRA DESLAVADA MAROMA','MARGMBDES05.jpg','63', '1'),"..
		"(2095,'MARGMBDES06','GORRA DESLAVADA MAROMA','MARGMBDES06.jpg','63', '1'),"..
		"(2096,'MARGMBDES10','GORRA DESLAVADA MAROMA','MARGMBDES10.jpg','63', '1'),"..
		"(2097,'MARGMBDES11','GORRA DESLAVADA MAROMA','MARGMBDES11.jpg','63', '1'),"..
		"(2098,'MARGMBDES12','GORRA DESLAVADA MAROMA','MARGMBDES12.jpg','63', '1'),"..
		"(2099,'MARGMBDES13','GORRA DESLAVADA MAROMA','MARGMBDES13.jpg','63', '1'),"..
		"(2100,'MARGMBDES15','GORRA DESLAVADA MAROMA','MARGMBDES15.jpg','63', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(2101,'MARGMBDES16','GORRA DESLAVADA MAROMA','MARGMBDES16.jpg','63', '1'),"..
		"(2102,'MARGMBDES21','GORRA DESLAVADA MAROMA','MARGMBDES21.jpg','63', '1'),"..
		"(2103,'MARGMBDES25','GORRA DESLAVADA MAROMA','MARGMBDES25.jpg','63', '1'),"..
		"(2104,'MARGMBDES26','GORRA DESLAVADA MAROMA','MARGMBDES26.jpg','63', '1'),"..
		"(2105,'MARGMBDES28','GORRA DESLAVADA MAROMA','MARGMBDES28.jpg','63', '1'),"..
		"(2106,'MARGMBDES30','GORRA DESLAVADA MAROMA','MARGMBDES30.jpg','63', '1'),"..
		"(2107,'MARGMBDES32','GORRA DESLAVADA MAROMA','MARGMBDES32.jpg','63', '1'),"..
		"(2108,'MARGMBDES34','GORRA DESLAVADA MAROMA','MARGMBDES34.jpg','63', '1'),"..
		"(2109,'MARGMBDES35','GORRA DESLAVADA MAROMA','MARGMBDES35.jpg','63', '1'),"..
		"(2110,'MARGMBDES37','GORRA DESLAVADA MAROMA','MARGMBDES37.jpg','63', '1'),"..
		"(2111,'MARGMBSAN02','GORRA SANDWICH MAROMA','MARGMBSAN02.jpg','68', '1'),"..
		"(2112,'MARGMBSAN03','GORRA SANDWICH MAROMA','MARGMBSAN03.jpg','68', '1'),"..
		"(2113,'MARGMBSAN05','GORRA SANDWICH MAROMA','MARGMBSAN05.jpg','68', '1'),"..
		"(2114,'MARGMBSAN06','GORRA SANDWICH MAROMA','MARGMBSAN06.jpg','68', '1'),"..
		"(2115,'MARGMBSAN07','GORRA SANDWICH MAROMA','MARGMBSAN07.jpg','68', '1'),"..
		"(2116,'MARGMBSAN11','GORRA SANDWICH MAROMA','MARGMBSAN11.jpg','68', '1'),"..
		"(2117,'MARGMBSAN13','GORRA SANDWICH MAROMA','MARGMBSAN13.jpg','68', '1'),"..
		"(2118,'MARGMBSAN20','GORRA SANDWICH MAROMA','MARGMBSAN20.jpg','68', '1'),"..
		"(2119,'MARGMBSAN22','GORRA SANDWICH MAROMA','MARGMBSAN22.jpg','68', '1'),"..
		"(2120,'MARGMBSAN30','GORRA SANDWICH MAROMA','MARGMBSAN30.jpg','68', '1'),"..
		"(2121,'MARGMBSAN32','GORRA SANDWICH MAROMA','MARGMBSAN32.jpg','68', '1'),"..
		"(2122,'MARGMBSAN33','GORRA SANDWICH MAROMA','MARGMBSAN33.jpg','68', '1'),"..
		"(2123,'MARGMBSAN36','GORRA SANDWICH MAROMA','MARGMBSAN36.jpg','68', '1'),"..
		"(2124,'MARGMBSAN39','GORRA SANDWICH MAROMA','MARGMBSAN39.jpg','68', '1'),"..
		"(2125,'MARGMBSAN43','GORRA SANDWICH MAROMA','MARGMBSAN43.jpg','68', '1'),"..
		"(2126,'MARGMBSAN45','GORRA SANDWICH MAROMA','MARGMBSAN45.jpg','68', '1'),"..
		"(2127,'MARGMBSAN49','GORRA SANDWICH MAROMA','MARGMBSAN49.jpg','68', '1'),"..
		"(2128,'MARGMBSAN51','GORRA SANDWICH MAROMA','MARGMBSAN51.jpg','68', '1'),"..
		"(2129,'MERCOA01502','COMBO BASICO ADULTO','MERCOA01502.jpg','85', '1'),"..
		"(2130,'MERCOA01511','COMBO BASICO ADULTO','MERCOA01511.jpg','85', '1'),"..
		"(2131,'MERCOA015XXL02','COMBO BASICO ADULTO','MERCOA015XXL02.jpg','85', '1'),"..
		"(2132,'MERCOA015XXL11','COMBO BASICO ADULTO','MERCOA015XXL11.jpg','85', '1'),"..
		"(2133,'MERCOD01540','COMBO BASICO DAMA','MERCOD01540.jpg','85', '1'),"..
		"(2134,'MERCOD01571','COMBO BASICO DAMA','MERCOD01571.jpg','85', '1'),"..
		"(2135,'MERGMBDAM04','GORRA DAMA MERIDA','MERGMBDAM04.jpg','63', '1'),"..
		"(2136,'MERGMBDAM12','GORRA DAMA MERIDA','MERGMBDAM12.jpg','63', '1'),"..
		"(2137,'MERGMBDAM17','GORRA DAMA MERIDA','MERGMBDAM17.jpg','63', '1'),"..
		"(2138,'MERGMBDAM18','GORRA DAMA MERIDA','MERGMBDAM18.jpg','63', '1'),"..
		"(2139,'MERGMBDAM19','GORRA DAMA MERIDA','MERGMBDAM19.jpg','63', '1'),"..
		"(2140,'MERGMBDAM29','GORRA DAMA MERIDA','MERGMBDAM29.jpg','63', '1'),"..
		"(2141,'MERGMBDAM40','GORRA DAMA MERIDA','MERGMBDAM40.jpg','63', '1'),"..
		"(2142,'MERGMBDAM41','GORRA DAMA MERIDA','MERGMBDAM41.jpg','63', '1'),"..
		"(2143,'MERGMBDES04','GORRA DESLAVADA MERIDA','MERGMBDES04.jpg','63', '1'),"..
		"(2144,'MERGMBDES05','GORRA DESLAVADA MERIDA','MERGMBDES05.jpg','63', '1'),"..
		"(2145,'MERGMBDES06','GORRA DESLAVADA MERIDA','MERGMBDES06.jpg','63', '1'),"..
		"(2146,'MERGMBDES10','GORRA DESLAVADA MERIDA','MERGMBDES10.jpg','63', '1'),"..
		"(2147,'MERGMBDES11','GORRA DESLAVADA MERIDA','MERGMBDES11.jpg','63', '1'),"..
		"(2148,'MERGMBDES12','GORRA DESLAVADA MERIDA','MERGMBDES12.jpg','63', '1'),"..
		"(2149,'MERGMBDES13','GORRA DESLAVADA MERIDA','MERGMBDES13.jpg','63', '1'),"..
		"(2150,'MERGMBDES15','GORRA DESLAVADA MERIDA','MERGMBDES15.jpg','63', '1'),"..
		"(2151,'MERGMBDES16','GORRA DESLAVADA MERIDA','MERGMBDES16.jpg','63', '1'),"..
		"(2152,'MERGMBDES21','GORRA DESLAVADA MERIDA','MERGMBDES21.jpg','63', '1'),"..
		"(2153,'MERGMBDES25','GORRA DESLAVADA MERIDA','MERGMBDES25.jpg','63', '1'),"..
		"(2154,'MERGMBDES26','GORRA DESLAVADA MERIDA','MERGMBDES26.jpg','63', '1'),"..
		"(2155,'MERGMBDES28','GORRA DESLAVADA MERIDA','MERGMBDES28.jpg','63', '1'),"..
		"(2156,'MERGMBDES30','GORRA DESLAVADA MERIDA','MERGMBDES30.jpg','63', '1'),"..
		"(2157,'MERGMBDES32','GORRA DESLAVADA MERIDA','MERGMBDES32.jpg','63', '1'),"..
		"(2158,'MERGMBDES34','GORRA DESLAVADA MERIDA','MERGMBDES34.jpg','63', '1'),"..
		"(2159,'MERGMBDES35','GORRA DESLAVADA MERIDA','MERGMBDES35.jpg','63', '1'),"..
		"(2160,'MERGMBDES37','GORRA DESLAVADA MERIDA','MERGMBDES37.jpg','63', '1'),"..
		"(2161,'MN-00902','MEN'S SWIMWEAR SHORTS','MN-00902.jpg','135', '1'),"..
		"(2162,'MN-00911','MEN'S SWIMWEAR SHORTS','MN-00911.jpg','135', '1'),"..
		"(2163,'MN-00913','MEN'S SWIMWEAR SHORTS','MN-00913.jpg','135', '1'),"..
		"(2164,'MN-009D','MEN'S SWIMWEAR SHORTS','MN-009D.jpg','135', '1'),"..
		"(2165,'MN-02612','MEN'S SWIMWEAR SHORTS','MN-02612.jpg','135', '1'),"..
		"(2166,'MN-02613','MEN'S SWIMWEAR SHORTS','MN-02613.jpg','135', '1'),"..
		"(2167,'MN-02617','MEN'S SWIMWEAR SHORTS','MN-02617.jpg','135', '1'),"..
		"(2168,'MN-026G','MEN'S SWIMWEAR SHORTS','MN-026G.jpg','135', '1'),"..
		"(2169,'MN-026H','MEN'S SWIMWEAR SHORTS','MN-026H.jpg','135', '1'),"..
		"(2170,'MN-026M','MEN'S SWIMWEAR SHORTS','MN-026M.jpg','135', '1'),"..
		"(2171,'MN-05103','MEN'S SWIMWEAR SHORTS','MN-05103.jpg','135', '1'),"..
		"(2172,'MN-05189','MEN'S SWIMWEAR SHORTS','MN-05189.jpg','135', '1'),"..
		"(2173,'MN-05913','MEN'S SWIMWEAR SHORTS','MN-05913.jpg','135', '1'),"..
		"(2174,'MN-059G','MEN'S SWIMWEAR SHORTS','MN-059G.jpg','135', '1'),"..
		"(2175,'MN-06511','MEN'S SWIMWEAR SHORTS','MN-06511.jpg','135', '1'),"..
		"(2176,'MN-06513','MEN'S SWIMWEAR SHORTS','MN-06513.jpg','135', '1'),"..
		"(2177,'MN-077B','MEN'S SWIMWEAR SHORTS','MN-077B.jpg','135', '1'),"..
		"(2178,'MN-077H','MEN'S SWIMWEAR SHORTS','MN-077H.jpg','135', '1'),"..
		"(2179,'MN-07811','MEN'S SWIMWEAR SHORTS','MN-07811.jpg','135', '1'),"..
		"(2180,'MN-07878','MEN'S SWIMWEAR SHORTS','MN-07878.jpg','135', '1'),"..
		"(2181,'MN-078R','MEN'S SWIMWEAR SHORTS','MN-078R.jpg','135', '1'),"..
		"(2182,'MN-08878','MEN'S SWIMWEAR SHORTS','MN-08878.jpg','135', '1'),"..
		"(2183,'MN-088B','MEN'S SWIMWEAR SHORTS','MN-088B.jpg','135', '1'),"..
		"(2184,'MN-088K','MEN'S SWIMWEAR SHORTS','MN-088K.jpg','135', '1'),"..
		"(2185,'MN-088R','MEN'S SWIMWEAR SHORTS','MN-088R.jpg','135', '1'),"..
		"(2186,'MN-08990','MEN'S SWIMWEAR SHORTS','MN-08990.jpg','135', '1'),"..
		"(2187,'MN-089K','MEN'S SWIMWEAR SHORTS','MN-089K.jpg','135', '1'),"..
		"(2188,'MN-090B','MEN'S SWIMWEAR SHORTS','MN-090B.jpg','135', '1'),"..
		"(2189,'MN-090G','MEN'S SWIMWEAR SHORTS','MN-090G.jpg','135', '1'),"..
		"(2190,'MN-090R','MEN'S SWIMWEAR SHORTS','MN-090R.jpg','135', '1'),"..
		"(2191,'MN-09103','MEN'S SWIMWEAR SHORTS','MN-09103.jpg','135', '1'),"..
		"(2192,'MN-09113','MEN'S SWIMWEAR SHORTS','MN-09113.jpg','135', '1'),"..
		"(2193,'MN-091G','MEN'S SWIMWEAR SHORTS','MN-091G.jpg','135', '1'),"..
		"(2194,'MN-09403','MEN'S SWIMWEAR SHORTS','MN-09403.jpg','135', '1'),"..
		"(2195,'MN-09415','MEN'S SWIMWEAR SHORTS','MN-09415.jpg','135', '1'),"..
		"(2196,'MN-09429','MEN'S SWIMWEAR SHORTS','MN-09429.jpg','135', '1'),"..
		"(2197,'MN-094B','MEN'S SWIMWEAR SHORTS','MN-094B.jpg','135', '1'),"..
		"(2198,'MN-094K','MEN'S SWIMWEAR SHORTS','MN-094K.jpg','135', '1'),"..
		"(2199,'MN-094R','MEN'S SWIMWEAR SHORTS','MN-094R.jpg','135', '1'),"..
		"(2200,'MN-09709','MEN'S SWIMWEAR SHORTS','MN-09709.jpg','135', '1'),"..
		"(2201,'MN-09713','MEN'S SWIMWEAR SHORTS','MN-09713.jpg','135', '1'),"..
		"(2202,'MN-09916','MEN'S SWIMWEAR SHORTS','MN-09916.jpg','135', '1'),"..
		"(2203,'MN-099H','MEN'S SWIMWEAR SHORTS','MN-099H.jpg','135', '1'),"..
		"(2204,'MN-10012','MEN'S SWIMWEAR SHORTS','MN-10012.jpg','135', '1'),"..
		"(2205,'MN-10078','MEN'S SWIMWEAR SHORTS','MN-10078.jpg','135', '1'),"..
		"(2206,'MN-100Q','MEN'S SWIMWEAR SHORTS','MN-100Q.jpg','135', '1'),"..
		"(2207,'MN-10209','MEN'S SWIMWEAR SHORTS','MN-10209.jpg','135', '1'),"..
		"(2208,'MN-102B','MEN'S SWIMWEAR SHORTS','MN-102B.jpg','135', '1'),"..
		"(2209,'MN-102R','MEN'S SWIMWEAR SHORTS','MN-102R.jpg','135', '1'),"..
		"(2210,'MN-107I','MEN'S SWIMWEAR SHORTS','MN-107I.jpg','135', '1'),"..
		"(2211,'MN-10978','MEN'S SWIMWEAR SHORTS','MN-10978.jpg','135', '1'),"..
		"(2212,'MN-109Q','MEN'S SWIMWEAR SHORTS','MN-109Q.jpg','135', '1'),"..
		"(2213,'MN-11278','MEN'S SWIMWEAR SHORTS','MN-11278.jpg','135', '1'),"..
		"(2214,'MN-11288','MEN'S SWIMWEAR SHORTS','MN-11288.jpg','135', '1'),"..
		"(2215,'MN-112G','MEN'S SWIMWEAR SHORTS','MN-112G.jpg','135', '1'),"..
		"(2216,'MN-200015','MEN'S SWIMWEAR SHORTS','MN-200015.jpg','135', '1'),"..
		"(2217,'MN-200073','MEN'S SWIMWEAR SHORTS','MN-200073.jpg','135', '1'),"..
		"(2218,'MNP-09916','MEN'S SWIMWEAR SHORTS','MNP-09916.jpg','135', '1'),"..
		"(2219,'MNP-099H','MEN'S SWIMWEAR SHORTS','MNP-099H.jpg','135', '1'),"..
		"(2220,'OMNGMBDES04','GORRA DESLAVADA OMNI','OMNGMBDES04.jpg','63', '1'),"..
		"(2221,'OMNGMBDES05','GORRA DESLAVADA OMNI','OMNGMBDES05.jpg','63', '1'),"..
		"(2222,'OMNGMBDES06','GORRA DESLAVADA OMNI','OMNGMBDES06.jpg','63', '1'),"..
		"(2223,'OMNGMBDES10','GORRA DESLAVADA OMNI','OMNGMBDES10.jpg','63', '1'),"..
		"(2224,'OMNGMBDES11','GORRA DESLAVADA OMNI','OMNGMBDES11.jpg','63', '1'),"..
		"(2225,'OMNGMBDES12','GORRA DESLAVADA OMNI','OMNGMBDES12.jpg','63', '1'),"..
		"(2226,'OMNGMBDES13','GORRA DESLAVADA OMNI','OMNGMBDES13.jpg','63', '1'),"..
		"(2227,'OMNGMBDES15','GORRA DESLAVADA OMNI','OMNGMBDES15.jpg','63', '1'),"..
		"(2228,'OMNGMBDES16','GORRA DESLAVADA OMNI','OMNGMBDES16.jpg','63', '1'),"..
		"(2229,'OMNGMBDES21','GORRA DESLAVADA OMNI','OMNGMBDES21.jpg','63', '1'),"..
		"(2230,'OMNGMBDES25','GORRA DESLAVADA OMNI','OMNGMBDES25.jpg','63', '1'),"..
		"(2231,'OMNGMBDES26','GORRA DESLAVADA OMNI','OMNGMBDES26.jpg','63', '1'),"..
		"(2232,'OMNGMBDES28','GORRA DESLAVADA OMNI','OMNGMBDES28.jpg','63', '1'),"..
		"(2233,'OMNGMBDES30','GORRA DESLAVADA OMNI','OMNGMBDES30.jpg','63', '1'),"..
		"(2234,'OMNGMBDES32','GORRA DESLAVADA OMNI','OMNGMBDES32.jpg','63', '1'),"..
		"(2235,'OMNGMBDES34','GORRA DESLAVADA OMNI','OMNGMBDES34.jpg','63', '1'),"..
		"(2236,'OMNGMBDES35','GORRA DESLAVADA OMNI','OMNGMBDES35.jpg','63', '1'),"..
		"(2237,'OMNGMBDES37','GORRA DESLAVADA OMNI','OMNGMBDES37.jpg','63', '1'),"..
		"(2238,'PA250TCN00112','PLAYERA ADULTO JASPEADA IGUANA STICH','PA250TCN00112.jpg','62', '1'),"..
		"(2239,'PA250TCN00213','PLAYERA ADULTO JASPEADA SELLO VERTICAL','PA250TCN00213.jpg','62', '1'),"..
		"(2240,'PA250TCN00315','PLAYERA ADULTO JASPEADA IGUANA OLEO','PA250TCN00315.jpg','62', '1'),"..
		"(2241,'PA250TCN004U','PLAYERA ADULTO JASPEADA MX ATHLETICS','PA250TCN004U.jpg','62', '1'),"..
		"(2242,'PA250TCNXXL00112','PLAYERA ADULTO JASPEADA IGUANA STICH','PA250TCNXXL00112.jpg','73', '1'),"..
		"(2243,'PA250TCNXXL00213','PLAYERA ADULTO JASPEADA SELLO VERTICAL','PA250TCNXXL00213.jpg','73', '1'),"..
		"(2244,'PA250TCNXXL00315','PLAYERA ADULTO JASPEADA IGUANA OLEO','PA250TCNXXL00315.jpg','73', '1'),"..
		"(2245,'PA250TCNXXL004U','PLAYERA ADULTO JASPEADA MX ATHLETICS','PA250TCNXXL004U.jpg','73', '1'),"..
		"(2246,'PA250TRM00112','PLAYERA ADULTO JASPEADA IGUANA STICH','PA250TRM00112.jpg','62', '1'),"..
		"(2247,'PA250TRM00213','PLAYERA ADULTO JASPEADA SELLO VERTICAL','PA250TRM00213.jpg','62', '1'),"..
		"(2248,'PA250TRM00315','PLAYERA ADULTO JASPEADA IGUANA OLEO','PA250TRM00315.jpg','62', '1'),"..
		"(2249,'PA250TRM004U','PLAYERA ADULTO JASPEADA MX ATHLETICS','PA250TRM004U.jpg','62', '1'),"..
		"(2250,'PA250TRMXX004LU','PLAYERA ADULTO JASPEADA MX ATHLETICS','PA250TRMXX004LU.jpg','73', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(2251,'PA250TRMXXL00112','PLAYERA ADULTO JASPEADA IGUANA STICH','PA250TRMXXL00112.jpg','73', '1'),"..
		"(2252,'PA250TRMXXL00213','PLAYERA ADULTO JASPEADA SELLO VERTICAL','PA250TRMXXL00213.jpg','73', '1'),"..
		"(2253,'PA250TRMXXL00315','PLAYERA ADULTO JASPEADA IGUANA OLEO','PA250TRMXXL00315.jpg','73', '1'),"..
		"(2254,'PA300TCN00173','PLAYERA ADULTO IGUANA FRANJA','PA300TCN00173.jpg','62', '1'),"..
		"(2255,'PA300TCN00212','PLAYERA ADULTO IGUANA STICH','PA300TCN00212.jpg','62', '1'),"..
		"(2256,'PA300TCN00324','PLAYERA ADULTO TORTUGA OLA','PA300TCN00324.jpg','62', '1'),"..
		"(2257,'PA300TCN00417','PLAYERA ADULTO 6 FIGURAS','PA300TCN00417.jpg','62', '1'),"..
		"(2258,'PA300TCN00513','PLAYERA ADULTO PALMERAS COOL','PA300TCN00513.jpg','62', '1'),"..
		"(2259,'PA300TCN00624','PLAYERA ADULTO MX ATHLETICS','PA300TCN00624.jpg','62', '1'),"..
		"(2260,'PA300TCN00711','PLAYERA ADULTO SELLO VERTICAL','PA300TCN00711.jpg','62', '1'),"..
		"(2261,'PA300TCN00810','PLAYERA ADULTO PALMERA COLEGIAL','PA300TCN00810.jpg','62', '1'),"..
		"(2262,'PA300TCN00912','PLAYERA ADULTO COLEGIAL MILITAR','PA300TCN00912.jpg','62', '1'),"..
		"(2263,'PA300TCN01009','PLAYERA ADULTO VELERO FIRMA','PA300TCN01009.jpg','62', '1'),"..
		"(2264,'PA300TCN01108','PLAYERA ADULTO DESTINO RECUADRO','PA300TCN01108.jpg','62', '1'),"..
		"(2265,'PA300TCN01213','PLAYERA ADULTO IGUANA OLEO','PA300TCN01213.jpg','62', '1'),"..
		"(2266,'PA300TCN01308','PLAYERA ADULTO SELLO TIBURON','PA300TCN01308.jpg','62', '1'),"..
		"(2267,'PA300TCN01413','PLAYERA ADULTO GEKO RETRO','PA300TCN01413.jpg','62', '1'),"..
		"(2268,'PA300TCN01528','PLAYERA ADULTO 3 GEKOS SOL','PA300TCN01528.jpg','62', '1'),"..
		"(2269,'PA300TCN01613','PLAYERA ADULTO FIRMA MX','PA300TCN01613.jpg','62', '1'),"..
		"(2270,'PA300TCN01711','PLAYERA ADULTO TORTUGAS BEBÉ','PA300TCN01711.jpg','62', '1'),"..
		"(2271,'PA300TCN01812','PLAYERA ADULTO GEKO ESCALANDO','PA300TCN01812.jpg','62', '1'),"..
		"(2272,'PA300TCN01911','PLAYERA ADULTO I LOVE','PA300TCN01911.jpg','62', '1'),"..
		"(2273,'PA300TCN02013','PLAYERA ADULTO TENIS','PA300TCN02013.jpg','62', '1'),"..
		"(2274,'PA300TCN02111','PLAYERA ADULTO PARADISE MX AZUL','PA300TCN02111.jpg','62', '1'),"..
		"(2275,'PA300TCN02224','PLAYERA ADULTO IGUANA TROPICAL','PA300TCN02224.jpg','62', '1'),"..
		"(2276,'PA300TCN02309','PLAYERA ADULTO SUR TRUK','PA300TCN02309.jpg','62', '1'),"..
		"(2277,'PA300TCN02310','PLAYERA ADULTO SUR TRUK','PA300TCN02310.jpg','62', '1'),"..
		"(2278,'PA300TCN02413','PLAYERA ADULTO DESTINO PESPUNTE','PA300TCN02413.jpg','62', '1'),"..
		"(2279,'PA300TCN02509','PLAYERA ADULTO VELERO OFF SHORE','PA300TCN02509.jpg','62', '1'),"..
		"(2280,'PA300TCN02510','PLAYERA ADULTO VELERO OFF SHORE','PA300TCN02510.jpg','62', '1'),"..
		"(2281,'PA300TCN02613','PLAYERA ADULTO SELLO FOIL PLATA','PA300TCN02613.jpg','62', '1'),"..
		"(2282,'PA300TCN02712','PLAYERA ADULTO GEKO ESCALANDO','PA300TCN02712.jpg','62', '1'),"..
		"(2283,'PA300TCN02828','PLAYERA ADULTO PROPERTY','PA300TCN02828.jpg','62', '1'),"..
		"(2284,'PA300TCN02913','PLAYERA ADULTO ORIGINAL GEKO','PA300TCN02913.jpg','62', '1'),"..
		"(2285,'PA300TCN03037','PLAYERA ADULTO 2 TORTUGAS FLORES','PA300TCN03037.jpg','62', '1'),"..
		"(2286,'PA300TCN03211','PLAYERA ADULTO VELERO NAUTICAL','PA300TCN03211.jpg','62', '1'),"..
		"(2287,'PA300TCN03213','PLAYERA ADULTO LETRAS DESTINO','PA300TCN03213.jpg','62', '1'),"..
		"(2288,'PA300TCN03309','PLAYERA ADULTO 2 GEKOS MX','PA300TCN03309.jpg','62', '1'),"..
		"(2289,'PA300TCN03328','PLAYERA ADULTO 2 GEKOS MX','PA300TCN03328.jpg','62', '1'),"..
		"(2290,'PA300TCN03403','PLAYERA ADULTO LETRAS DESTINO','PA300TCN03403.jpg','38', '1'),"..
		"(2291,'PA300TCN03503','PLAYERA ADULTO VELERO NAUTICAL','PA300TCN03503.jpg','38', '1'),"..
		"(2292,'PA300TCN03603','PLAYERA ADULTO LETRAS QUEMADAS ORO','PA300TCN03603.jpg','38', '1'),"..
		"(2293,'PA300TCN03703','PLAYERA ADULTO DESTINO MX','PA300TCN03703.jpg','38', '1'),"..
		"(2294,'PA300TCN03803','PLAYERA ADULTO CHANCLITAS','PA300TCN03803.jpg','38', '1'),"..
		"(2295,'PA300TCN03903','PLAYERA ADULTO PARADISE MX AZUL','PA300TCN03903.jpg','38', '1'),"..
		"(2296,'PA300TCN04003','PLAYERA ADULTO IBISCUS FOIL','PA300TCN04003.jpg','38', '1'),"..
		"(2297,'PA300TCN04103','PLAYERA ADULTO SUR TRUK','PA300TCN04103.jpg','38', '1'),"..
		"(2298,'PA300TCN04203','PLAYERA ADULTO SELLO FOIL PLATA','PA300TCN04203.jpg','38', '1'),"..
		"(2299,'PA300TCN04303','PLAYERA ADULTO GEKO ESCALANDO','PA300TCN04303.jpg','38', '1'),"..
		"(2300,'PA300TCN04403','PLAYERA ADULTO PROPERTY','PA300TCN04403.jpg','38', '1'),"..
		"(2301,'PA300TCN04503','PLAYERA ADULTO ORIGINAL GEKO','PA300TCN04503.jpg','38', '1'),"..
		"(2302,'PA300TCN04610','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TCN04610.jpg','62', '1'),"..
		"(2303,'PA300TCN04713','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TCN04713.jpg','62', '1'),"..
		"(2304,'PA300TCN04811','PLAYERA ADULTO AUTHENTIC BRAND','PA300TCN04811.jpg','62', '1'),"..
		"(2305,'PA300TCN04916','PLAYERA ADULTO AUTHENTIC BRAND','PA300TCN04916.jpg','62', '1'),"..
		"(2306,'PA300TCN05024','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TCN05024.jpg','62', '1'),"..
		"(2307,'PA300TCN05194','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TCN05194.jpg','62', '1'),"..
		"(2308,'PA300TCN05212','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TCN05212.jpg','62', '1'),"..
		"(2309,'PA300TCN053Q','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TCN053Q.jpg','62', '1'),"..
		"(2310,'PA300TCN05413','PLAYERA ADULTO 3 ESTRELLAS','PA300TCN05413.jpg','62', '1'),"..
		"(2311,'PA300TCN05508','PLAYERA ADULTO VARSITY PARDISE','PA300TCN05508.jpg','62', '1'),"..
		"(2312,'PA300TCN05612','PLAYERA ADULTO VARSITY PARDISE','PA300TCN05612.jpg','62', '1'),"..
		"(2313,'PA300TCN05704','PLAYERA ADULTO FIRMA ATHLETIC','PA300TCN05704.jpg','62', '1'),"..
		"(2314,'PA300TCN05894','PLAYERA ADULTO FIRMA ATHLETIC','PA300TCN05894.jpg','62', '1'),"..
		"(2315,'PA300TCN05909','PLAYERA ADULTO FIRMA ATHLETIC','PA300TCN05909.jpg','62', '1'),"..
		"(2316,'PA300TCN06009','PLAYERA ADULTO PALMERA ORIGINAL','PA300TCN06009.jpg','62', '1'),"..
		"(2317,'PA300TCN06194','PLAYERA ADULTO PALMERA ORIGINAL','PA300TCN06194.jpg','62', '1'),"..
		"(2318,'PA300TCN062Q','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TCN062Q.jpg','62', '1'),"..
		"(2319,'PA300TCN06310','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TCN06310.jpg','62', '1'),"..
		"(2320,'PA300TCN06424','PLAYERA ADULTO CIRCULO MEX','PA300TCN06424.jpg','62', '1'),"..
		"(2321,'PA300TCN06508','PLAYERA ADULTO CIRCULO MEX','PA300TCN06508.jpg','62', '1'),"..
		"(2322,'PA300TCN06671','PLAYERA ADUTLO 6 PALMERAS RECTANGULOS','PA300TCN06671.jpg','62', '1'),"..
		"(2323,'PA300TCN06727','PLAYERA ADULTO 6 PALMERAS RECTANGULOS','PA300TCN06727.jpg','62', '1'),"..
		"(2324,'PA300TCN06813','PLAYERA ADULTO IGUANA NEON','PA300TCN06813.jpg','62', '1'),"..
		"(2325,'PA300TCN06910','PLAYERA ADULTO MX SOMBRAS','PA300TCN06910.jpg','62', '1'),"..
		"(2326,'PA300TCN07009','PLAYERA ADULTO MX SOMBRAS','PA300TCN07009.jpg','62', '1'),"..
		"(2327,'PA300TCNXXL00173','PLAYERA ADULTO IGUANA FRANJA','PA300TCNXXL00173.jpg','73', '1'),"..
		"(2328,'PA300TCNXXL00212','PLAYERA ADULTO IGUANA STICH','PA300TCNXXL00212.jpg','73', '1'),"..
		"(2329,'PA300TCNXXL00324','PLAYERA ADULTO TORTUGA OLA','PA300TCNXXL00324.jpg','73', '1'),"..
		"(2330,'PA300TCNXXL00417','PLAYERA ADULTO 6 FIGURAS','PA300TCNXXL00417.jpg','73', '1'),"..
		"(2331,'PA300TCNXXL00513','PLAYERA ADULTO PALMERAS COOL','PA300TCNXXL00513.jpg','73', '1'),"..
		"(2332,'PA300TCNXXL00624','PLAYERA ADULTO MX ATHLETICS','PA300TCNXXL00624.jpg','73', '1'),"..
		"(2333,'PA300TCNXXL00711','PLAYERA ADULTO SELLO VERTICAL','PA300TCNXXL00711.jpg','73', '1'),"..
		"(2334,'PA300TCNXXL00810','PLAYERA ADULTO PALMERA COLEGIAL','PA300TCNXXL00810.jpg','73', '1'),"..
		"(2335,'PA300TCNXXL00912','PLAYERA ADULTO COLEGIAL MILITAR','PA300TCNXXL00912.jpg','73', '1'),"..
		"(2336,'PA300TCNXXL01009','PLAYERA ADULTO VELERO FIRMA','PA300TCNXXL01009.jpg','73', '1'),"..
		"(2337,'PA300TCNXXL01108','PLAYERA ADULTO DESTINO RECUADRO','PA300TCNXXL01108.jpg','73', '1'),"..
		"(2338,'PA300TCNXXL01213','PLAYERA ADULTO IGUANA OLEO','PA300TCNXXL01213.jpg','73', '1'),"..
		"(2339,'PA300TCNXXL01308','PLAYERA ADULTO SELLO TIBURON','PA300TCNXXL01308.jpg','73', '1'),"..
		"(2340,'PA300TCNXXL01413','PLAYERA ADULTO GEKO RETRO','PA300TCNXXL01413.jpg','73', '1'),"..
		"(2341,'PA300TCNXXL01528','PLAYERA ADULTO 3 GEKOS SOL','PA300TCNXXL01528.jpg','73', '1'),"..
		"(2342,'PA300TCNXXL01613','PLAYERA ADULTO FIRMA MX','PA300TCNXXL01613.jpg','73', '1'),"..
		"(2343,'PA300TCNXXL01711','PLAYERA ADULTO TORTUGAS BEBÉ','PA300TCNXXL01711.jpg','73', '1'),"..
		"(2344,'PA300TCNXXL01812','PLAYERA ADULTO GEKO ESCALANDO','PA300TCNXXL01812.jpg','73', '1'),"..
		"(2345,'PA300TCNXXL01911','PLAYERA ADULTO I LOVE','PA300TCNXXL01911.jpg','73', '1'),"..
		"(2346,'PA300TCNXXL02013','PLAYERA ADULTO TENIS','PA300TCNXXL02013.jpg','73', '1'),"..
		"(2347,'PA300TCNXXL02111','PLAYERA ADULTO PARADISE MX AZUL','PA300TCNXXL02111.jpg','73', '1'),"..
		"(2348,'PA300TCNXXL02224','PLAYERA ADULTO IGUANA TROPICAL','PA300TCNXXL02224.jpg','73', '1'),"..
		"(2349,'PA300TCNXXL02309','PLAYERA ADULTO SUR TRUK','PA300TCNXXL02309.jpg','73', '1'),"..
		"(2350,'PA300TCNXXL02310','PLAYERA ADULTO SUR TRUK','PA300TCNXXL02310.jpg','73', '1'),"..
		"(2351,'PA300TCNXXL02413','PLAYERA ADULTO DESTINO PESPUNTE','PA300TCNXXL02413.jpg','73', '1'),"..
		"(2352,'PA300TCNXXL02509','PLAYERA ADULTO VELERO OFF SHORE','PA300TCNXXL02509.jpg','73', '1'),"..
		"(2353,'PA300TCNXXL02510','PLAYERA ADULTO VELERO OFF SHORE','PA300TCNXXL02510.jpg','73', '1'),"..
		"(2354,'PA300TCNXXL02613','PLAYERA ADULTO SELLO FOIL PLATA','PA300TCNXXL02613.jpg','73', '1'),"..
		"(2355,'PA300TCNXXL02712','PLAYERA ADULTO GEKO ESCALANDO','PA300TCNXXL02712.jpg','73', '1'),"..
		"(2356,'PA300TCNXXL02828','PLAYERA ADULTO PROPERTY','PA300TCNXXL02828.jpg','73', '1'),"..
		"(2357,'PA300TCNXXL02913','PLAYERA ADULTO ORIGINAL GEKO','PA300TCNXXL02913.jpg','73', '1'),"..
		"(2358,'PA300TCNXXL03037','PLAYERA ADULTO 2 TORTUGAS FLORES','PA300TCNXXL03037.jpg','73', '1'),"..
		"(2359,'PA300TCNXXL03211','PLAYERA ADULTO VELERO NAUTICAL','PA300TCNXXL03211.jpg','73', '1'),"..
		"(2360,'PA300TCNXXL03213','PLAYERA ADULTO LETRAS DESTINO','PA300TCNXXL03213.jpg','73', '1'),"..
		"(2361,'PA300TCNXXL03309','PLAYERA ADULTO 2 GEKOS MX','PA300TCNXXL03309.jpg','73', '1'),"..
		"(2362,'PA300TCNXXL03328','PLAYERA ADULTO 2 GEKOS MX','PA300TCNXXL03328.jpg','73', '1'),"..
		"(2363,'PA300TCNXXL03403','PLAYERA ADULTO LETRAS DESTINO','PA300TCNXXL03403.jpg','48', '1'),"..
		"(2364,'PA300TCNXXL03503','PLAYERA ADULTO VELERO NAUTICAL','PA300TCNXXL03503.jpg','48', '1'),"..
		"(2365,'PA300TCNXXL03603','PLAYERA ADULTO LETRAS QUEMADAS ORO','PA300TCNXXL03603.jpg','48', '1'),"..
		"(2366,'PA300TCNXXL03703','PLAYERA ADULTO DESTINO MX','PA300TCNXXL03703.jpg','48', '1'),"..
		"(2367,'PA300TCNXXL03803','PLAYERA ADULTO CHANCLITAS','PA300TCNXXL03803.jpg','48', '1'),"..
		"(2368,'PA300TCNXXL03903','PLAYERA ADULTO PARADISE MX AZUL','PA300TCNXXL03903.jpg','48', '1'),"..
		"(2369,'PA300TCNXXL04003','PLAYERA ADULTO IBISCUS FOIL','PA300TCNXXL04003.jpg','48', '1'),"..
		"(2370,'PA300TCNXXL04103','PLAYERA ADULTO SUR TRUK','PA300TCNXXL04103.jpg','48', '1'),"..
		"(2371,'PA300TCNXXL04203','PLAYERA ADULTO SELLO FOIL PLATA','PA300TCNXXL04203.jpg','48', '1'),"..
		"(2372,'PA300TCNXXL04303','PLAYERA ADULTO GEKO ESCALANDO','PA300TCNXXL04303.jpg','48', '1'),"..
		"(2373,'PA300TCNXXL04403','PLAYERA ADULTO PROPERTY','PA300TCNXXL04403.jpg','48', '1'),"..
		"(2374,'PA300TCNXXL04503','PLAYERA ADULTO ORIGINAL GEKO','PA300TCNXXL04503.jpg','48', '1'),"..
		"(2375,'PA300TCNXXL04610','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TCNXXL04610.jpg','73', '1'),"..
		"(2376,'PA300TCNXXL04713','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TCNXXL04713.jpg','73', '1'),"..
		"(2377,'PA300TCNXXL04811','PLAYERA ADULTO AUTHENTIC BRAND','PA300TCNXXL04811.jpg','73', '1'),"..
		"(2378,'PA300TCNXXL04916','PLAYERA ADULTO AUTHENTIC BRAND','PA300TCNXXL04916.jpg','73', '1'),"..
		"(2379,'PA300TCNXXL05024','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TCNXXL05024.jpg','73', '1'),"..
		"(2380,'PA300TCNXXL05194','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TCNXXL05194.jpg','73', '1'),"..
		"(2381,'PA300TCNXXL05212','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TCNXXL05212.jpg','73', '1'),"..
		"(2382,'PA300TCNXXL053Q','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TCNXXL053Q.jpg','73', '1'),"..
		"(2383,'PA300TCNXXL05413','PLAYERA ADULTO 3 ESTRELLAS','PA300TCNXXL05413.jpg','73', '1'),"..
		"(2384,'PA300TCNXXL05508','PLAYERA ADULTO VARSITY PARDISE','PA300TCNXXL05508.jpg','73', '1'),"..
		"(2385,'PA300TCNXXL05612','PLAYERA ADULTO VARSITY PARDISE','PA300TCNXXL05612.jpg','73', '1'),"..
		"(2386,'PA300TCNXXL05704','PLAYERA ADULTO FIRMA ATHLETIC','PA300TCNXXL05704.jpg','73', '1'),"..
		"(2387,'PA300TCNXXL05894','PLAYERA ADULTO FIRMA ATHLETIC','PA300TCNXXL05894.jpg','73', '1'),"..
		"(2388,'PA300TCNXXL05909','PLAYERA ADULTO FIRMA ATHLETIC','PA300TCNXXL05909.jpg','73', '1'),"..
		"(2389,'PA300TCNXXL06009','PLAYERA ADULTO PALMERA ORIGINAL','PA300TCNXXL06009.jpg','73', '1'),"..
		"(2390,'PA300TCNXXL06194','PLAYERA ADULTO PALMERA ORIGINAL','PA300TCNXXL06194.jpg','73', '1'),"..
		"(2391,'PA300TCNXXL062Q','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TCNXXL062Q.jpg','73', '1'),"..
		"(2392,'PA300TCNXXL06310','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TCNXXL06310.jpg','73', '1'),"..
		"(2393,'PA300TCNXXL06424','PLAYERA ADULTO CIRCULO MEX','PA300TCNXXL06424.jpg','73', '1'),"..
		"(2394,'PA300TCNXXL06508','PLAYERA ADULTO CIRCULO MEX','PA300TCNXXL06508.jpg','73', '1'),"..
		"(2395,'PA300TCNXXL06671','PLAYERA ADUTLO 6 PALMERAS RECTANGULOS','PA300TCNXXL06671.jpg','73', '1'),"..
		"(2396,'PA300TCNXXL06727','PLAYERA ADULTO 6 PALMERAS RECTANGULOS','PA300TCNXXL06727.jpg','73', '1'),"..
		"(2397,'PA300TCNXXL06813','PLAYERA ADULTO IGUANA NEON','PA300TCNXXL06813.jpg','73', '1'),"..
		"(2398,'PA300TCNXXL06910','PLAYERA ADULTO MX SOMBRAS','PA300TCNXXL06910.jpg','73', '1'),"..
		"(2399,'PA300TCNXXL07009','PLAYERA ADULTO MX SOMBRAS','PA300TCNXXL07009.jpg','73', '1'),"..
		"(2400,'PA300TRM00173','PLAYERA ADULTO IGUANA FRANJA','PA300TRM00173.jpg','62', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(2401,'PA300TRM00212','PLAYERA ADULTO IGUANA STICH','PA300TRM00212.jpg','62', '1'),"..
		"(2402,'PA300TRM00324','PLAYERA ADULTO TORTUGA OLA','PA300TRM00324.jpg','62', '1'),"..
		"(2403,'PA300TRM00417','PLAYERA ADULTO 6 FIGURAS','PA300TRM00417.jpg','62', '1'),"..
		"(2404,'PA300TRM00513','PLAYERA ADULTO PALMERAS COOL','PA300TRM00513.jpg','62', '1'),"..
		"(2405,'PA300TRM00624','PLAYERA ADULTO MX ATHLETICS','PA300TRM00624.jpg','62', '1'),"..
		"(2406,'PA300TRM00711','PLAYERA ADULTO SELLO VERTICAL','PA300TRM00711.jpg','62', '1'),"..
		"(2407,'PA300TRM00810','PLAYERA ADULTO PALMERA COLEGIAL','PA300TRM00810.jpg','62', '1'),"..
		"(2408,'PA300TRM00912','PLAYERA ADULTO COLEGIAL MILITAR','PA300TRM00912.jpg','62', '1'),"..
		"(2409,'PA300TRM01009','PLAYERA ADULTO VELERO FIRMA','PA300TRM01009.jpg','62', '1'),"..
		"(2410,'PA300TRM01108','PLAYERA ADULTO DESTINO RECUADRO','PA300TRM01108.jpg','62', '1'),"..
		"(2411,'PA300TRM01213','PLAYERA ADULTO IGUANA OLEO','PA300TRM01213.jpg','62', '1'),"..
		"(2412,'PA300TRM01308','PLAYERA ADULTO SELLO TIBURON','PA300TRM01308.jpg','62', '1'),"..
		"(2413,'PA300TRM01413','PLAYERA ADULTO GEKO RETRO','PA300TRM01413.jpg','62', '1'),"..
		"(2414,'PA300TRM01528','PLAYERA ADULTO 3 GEKOS SOL','PA300TRM01528.jpg','62', '1'),"..
		"(2415,'PA300TRM01613','PLAYERA ADULTO FIRMA MX','PA300TRM01613.jpg','62', '1'),"..
		"(2416,'PA300TRM01711','PLAYERA ADULTO TORTUGAS BEBÉ','PA300TRM01711.jpg','62', '1'),"..
		"(2417,'PA300TRM01812','PLAYERA ADULTO GEKO ESCALANDO','PA300TRM01812.jpg','62', '1'),"..
		"(2418,'PA300TRM01911','PLAYERA ADULTO I LOVE','PA300TRM01911.jpg','62', '1'),"..
		"(2419,'PA300TRM02013','PLAYERA ADULTO TENIS','PA300TRM02013.jpg','62', '1'),"..
		"(2420,'PA300TRM02103','PLAYERA ADULTO LETRAS DESTINO','PA300TRM02103.jpg','38', '1'),"..
		"(2421,'PA300TRM02111','PLAYERA ADULTO PARADISE MX AZUL','PA300TRM02111.jpg','62', '1'),"..
		"(2422,'PA300TRM02224','PLAYERA ADULTO IGUANA TROPICAL','PA300TRM02224.jpg','62', '1'),"..
		"(2423,'PA300TRM02309','PLAYERA ADULTO SUR TRUK','PA300TRM02309.jpg','62', '1'),"..
		"(2424,'PA300TRM02310','PLAYERA ADULTO SUR TRUK','PA300TRM02310.jpg','62', '1'),"..
		"(2425,'PA300TRM02413','PLAYERA ADULTO DESTINO PESPUNTE','PA300TRM02413.jpg','62', '1'),"..
		"(2426,'PA300TRM02509','PLAYERA ADULTO VELERO OFF SHORE','PA300TRM02509.jpg','62', '1'),"..
		"(2427,'PA300TRM02510','PLAYERA ADULTO VELERO OFF SHORE','PA300TRM02510.jpg','62', '1'),"..
		"(2428,'PA300TRM02613','PLAYERA ADULTO SELLO FOIL PLATA','PA300TRM02613.jpg','62', '1'),"..
		"(2429,'PA300TRM02712','PLAYERA ADULTO GEKO ESCALANDO','PA300TRM02712.jpg','62', '1'),"..
		"(2430,'PA300TRM02828','PLAYERA ADULTO PROPERTY','PA300TRM02828.jpg','62', '1'),"..
		"(2431,'PA300TRM02913','PLAYERA ADULTO ORIGINAL GEKO','PA300TRM02913.jpg','62', '1'),"..
		"(2432,'PA300TRM03037','PLAYERA ADULTO 2 TORTUGAS FLORES','PA300TRM03037.jpg','62', '1'),"..
		"(2433,'PA300TRM03211','PLAYERA ADULTO VELERO NAUTICAL','PA300TRM03211.jpg','62', '1'),"..
		"(2434,'PA300TRM03213','PLAYERA ADULTO LETRAS DESTINO','PA300TRM03213.jpg','62', '1'),"..
		"(2435,'PA300TRM03309','PLAYERA ADULTO 2 GEKOS MX','PA300TRM03309.jpg','62', '1'),"..
		"(2436,'PA300TRM03328','PLAYERA ADULTO 2 GEKOS MX','PA300TRM03328.jpg','62', '1'),"..
		"(2437,'PA300TRM03403','PLAYERA ADULTO LETRAS DESTINO','PA300TRM03403.jpg','38', '1'),"..
		"(2438,'PA300TRM03503','PLAYERA ADULTO VELERO NAUTICAL','PA300TRM03503.jpg','38', '1'),"..
		"(2439,'PA300TRM03603','PLAYERA ADULTO LETRAS QUEMADAS ORO','PA300TRM03603.jpg','38', '1'),"..
		"(2440,'PA300TRM03703','PLAYERA ADULTO DESTINO MX','PA300TRM03703.jpg','38', '1'),"..
		"(2441,'PA300TRM03803','PLAYERA ADULTO CHANCLITAS','PA300TRM03803.jpg','38', '1'),"..
		"(2442,'PA300TRM03903','PLAYERA ADULTO PARADISE MX AZUL','PA300TRM03903.jpg','38', '1'),"..
		"(2443,'PA300TRM04003','PLAYERA ADULTO IBISCUS FOIL','PA300TRM04003.jpg','38', '1'),"..
		"(2444,'PA300TRM04103','PLAYERA ADULTO SUR TRUK','PA300TRM04103.jpg','38', '1'),"..
		"(2445,'PA300TRM04203','PLAYERA ADULTO SELLO FOIL PLATA','PA300TRM04203.jpg','38', '1'),"..
		"(2446,'PA300TRM04303','PLAYERA ADULTO GEKO ESCALANDO','PA300TRM04303.jpg','38', '1'),"..
		"(2447,'PA300TRM04403','PLAYERA ADULTO PROPERTY','PA300TRM04403.jpg','38', '1'),"..
		"(2448,'PA300TRM04503','PLAYERA ADULTO ORIGINAL GEKO','PA300TRM04503.jpg','38', '1'),"..
		"(2449,'PA300TRM04610','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TRM04610.jpg','62', '1'),"..
		"(2450,'PA300TRM04713','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TRM04713.jpg','62', '1'),"..
		"(2451,'PA300TRM04811','PLAYERA ADULTO AUTHENTIC BRAND','PA300TRM04811.jpg','62', '1'),"..
		"(2452,'PA300TRM04916','PLAYERA ADULTO AUTHENTIC BRAND','PA300TRM04916.jpg','62', '1'),"..
		"(2453,'PA300TRM05024','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TRM05024.jpg','62', '1'),"..
		"(2454,'PA300TRM05194','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TRM05194.jpg','62', '1'),"..
		"(2455,'PA300TRM05212','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TRM05212.jpg','62', '1'),"..
		"(2456,'PA300TRM053Q','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TRM053Q.jpg','62', '1'),"..
		"(2457,'PA300TRM05413','PLAYERA ADULTO 3 ESTRELLAS','PA300TRM05413.jpg','62', '1'),"..
		"(2458,'PA300TRM05508','PLAYERA ADULTO VARSITY PARDISE','PA300TRM05508.jpg','62', '1'),"..
		"(2459,'PA300TRM05612','PLAYERA ADULTO VARSITY PARDISE','PA300TRM05612.jpg','62', '1'),"..
		"(2460,'PA300TRM05704','PLAYERA ADULTO FIRMA ATHLETIC','PA300TRM05704.jpg','62', '1'),"..
		"(2461,'PA300TRM05894','PLAYERA ADULTO FIRMA ATHLETIC','PA300TRM05894.jpg','62', '1'),"..
		"(2462,'PA300TRM05909','PLAYERA ADULTO FIRMA ATHLETIC','PA300TRM05909.jpg','62', '1'),"..
		"(2463,'PA300TRM06009','PLAYERA ADULTO PALMERA ORIGINAL','PA300TRM06009.jpg','62', '1'),"..
		"(2464,'PA300TRM06194','PLAYERA ADULTO PALMERA ORIGINAL','PA300TRM06194.jpg','62', '1'),"..
		"(2465,'PA300TRM062Q','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TRM062Q.jpg','62', '1'),"..
		"(2466,'PA300TRM06310','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TRM06310.jpg','62', '1'),"..
		"(2467,'PA300TRM06424','PLAYERA ADULTO CIRCULO MEX','PA300TRM06424.jpg','62', '1'),"..
		"(2468,'PA300TRM06508','PLAYERA ADULTO CIRCULO MEX','PA300TRM06508.jpg','62', '1'),"..
		"(2469,'PA300TRM06671','PLAYERA ADUTLO 6 PALMERAS RECTANGULOS','PA300TRM06671.jpg','62', '1'),"..
		"(2470,'PA300TRM06727','PLAYERA ADULTO 6 PALMERAS RECTANGULOS','PA300TRM06727.jpg','62', '1'),"..
		"(2471,'PA300TRM06813','PLAYERA ADULTO IGUANA NEON','PA300TRM06813.jpg','62', '1'),"..
		"(2472,'PA300TRM06910','PLAYERA ADULTO MX SOMBRAS','PA300TRM06910.jpg','62', '1'),"..
		"(2473,'PA300TRM07009','PLAYERA ADULTO MX SOMBRAS','PA300TRM07009.jpg','62', '1'),"..
		"(2474,'PA300TRMXXL00173','PLAYERA ADULTO IGUANA FRANJA','PA300TRMXXL00173.jpg','73', '1'),"..
		"(2475,'PA300TRMXXL00212','PLAYERA ADULTO IGUANA STICH','PA300TRMXXL00212.jpg','73', '1'),"..
		"(2476,'PA300TRMXXL00324','PLAYERA ADULTO TORTUGA OLA','PA300TRMXXL00324.jpg','73', '1'),"..
		"(2477,'PA300TRMXXL00417','PLAYERA ADULTO 6 FIGURAS','PA300TRMXXL00417.jpg','73', '1'),"..
		"(2478,'PA300TRMXXL00513','PLAYERA ADULTO PALMERAS COOL','PA300TRMXXL00513.jpg','73', '1'),"..
		"(2479,'PA300TRMXXL00624','PLAYERA ADULTO MX ATHLETICS','PA300TRMXXL00624.jpg','73', '1'),"..
		"(2480,'PA300TRMXXL00711','PLAYERA ADULTO SELLO VERTICAL','PA300TRMXXL00711.jpg','73', '1'),"..
		"(2481,'PA300TRMXXL00810','PLAYERA ADULTO PALMERA COLEGIAL','PA300TRMXXL00810.jpg','73', '1'),"..
		"(2482,'PA300TRMXXL00912','PLAYERA ADULTO COLEGIAL MILITAR','PA300TRMXXL00912.jpg','73', '1'),"..
		"(2483,'PA300TRMXXL01009','PLAYERA ADULTO VELERO FIRMA','PA300TRMXXL01009.jpg','73', '1'),"..
		"(2484,'PA300TRMXXL01108','PLAYERA ADULTO DESTINO RECUADRO','PA300TRMXXL01108.jpg','73', '1'),"..
		"(2485,'PA300TRMXXL01213','PLAYERA ADULTO IGUANA OLEO','PA300TRMXXL01213.jpg','73', '1'),"..
		"(2486,'PA300TRMXXL01308','PLAYERA ADULTO SELLO TIBURON','PA300TRMXXL01308.jpg','73', '1'),"..
		"(2487,'PA300TRMXXL01413','PLAYERA ADULTO GEKO RETRO','PA300TRMXXL01413.jpg','73', '1'),"..
		"(2488,'PA300TRMXXL01528','PLAYERA ADULTO 3 GEKOS SOL','PA300TRMXXL01528.jpg','73', '1'),"..
		"(2489,'PA300TRMXXL01613','PLAYERA ADULTO FIRMA MX','PA300TRMXXL01613.jpg','73', '1'),"..
		"(2490,'PA300TRMXXL01711','PLAYERA ADULTO TORTUGAS BEBÉ','PA300TRMXXL01711.jpg','73', '1'),"..
		"(2491,'PA300TRMXXL01812','PLAYERA ADULTO GEKO ESCALANDO','PA300TRMXXL01812.jpg','73', '1'),"..
		"(2492,'PA300TRMXXL01911','PLAYERA ADULTO I LOVE','PA300TRMXXL01911.jpg','73', '1'),"..
		"(2493,'PA300TRMXXL02013','PLAYERA ADULTO TENIS','PA300TRMXXL02013.jpg','73', '1'),"..
		"(2494,'PA300TRMXXL02111','PLAYERA ADULTO PARADISE MX AZUL','PA300TRMXXL02111.jpg','73', '1'),"..
		"(2495,'PA300TRMXXL02224','PLAYERA ADULTO IGUANA TROPICAL','PA300TRMXXL02224.jpg','73', '1'),"..
		"(2496,'PA300TRMXXL02309','PLAYERA ADULTO SUR TRUK','PA300TRMXXL02309.jpg','73', '1'),"..
		"(2497,'PA300TRMXXL02310','PLAYERA ADULTO SUR TRUK','PA300TRMXXL02310.jpg','73', '1'),"..
		"(2498,'PA300TRMXXL02413','PLAYERA ADULTO DESTINO PESPUNTE','PA300TRMXXL02413.jpg','73', '1'),"..
		"(2499,'PA300TRMXXL02509','PLAYERA ADULTO VELERO OFF SHORE','PA300TRMXXL02509.jpg','73', '1'),"..
		"(2500,'PA300TRMXXL02510','PLAYERA ADULTO VELERO OFF SHORE','PA300TRMXXL02510.jpg','73', '1'),"..
		"(2501,'PA300TRMXXL02613','PLAYERA ADULTO SELLO FOIL PLATA','PA300TRMXXL02613.jpg','73', '1'),"..
		"(2502,'PA300TRMXXL02712','PLAYERA ADULTO GEKO ESCALANDO','PA300TRMXXL02712.jpg','73', '1'),"..
		"(2503,'PA300TRMXXL02828','PLAYERA ADULTO PROPERTY','PA300TRMXXL02828.jpg','73', '1'),"..
		"(2504,'PA300TRMXXL02913','PLAYERA ADULTO ORIGINAL GEKO','PA300TRMXXL02913.jpg','73', '1'),"..
		"(2505,'PA300TRMXXL03037','PLAYERA ADULTO 2 TORTUGAS FLORES','PA300TRMXXL03037.jpg','73', '1'),"..
		"(2506,'PA300TRMXXL03211','PLAYERA ADULTO VELERO NAUTICAL','PA300TRMXXL03211.jpg','73', '1'),"..
		"(2507,'PA300TRMXXL03213','PLAYERA ADULTO LETRAS DESTINO','PA300TRMXXL03213.jpg','73', '1'),"..
		"(2508,'PA300TRMXXL03309','PLAYERA ADULTO 2 GEKOS MX','PA300TRMXXL03309.jpg','73', '1'),"..
		"(2509,'PA300TRMXXL03328','PLAYERA ADULTO 2 GEKOS MX','PA300TRMXXL03328.jpg','73', '1'),"..
		"(2510,'PA300TRMXXL03403','PLAYERA ADULTO LETRAS DESTINO','PA300TRMXXL03403.jpg','48', '1'),"..
		"(2511,'PA300TRMXXL03503','PLAYERA ADULTO VELERO NAUTICAL','PA300TRMXXL03503.jpg','48', '1'),"..
		"(2512,'PA300TRMXXL03603','PLAYERA ADULTO LETRAS QUEMADAS ORO','PA300TRMXXL03603.jpg','48', '1'),"..
		"(2513,'PA300TRMXXL03703','PLAYERA ADULTO DESTINO MX','PA300TRMXXL03703.jpg','48', '1'),"..
		"(2514,'PA300TRMXXL03803','PLAYERA ADULTO CHANCLITAS','PA300TRMXXL03803.jpg','48', '1'),"..
		"(2515,'PA300TRMXXL03903','PLAYERA ADULTO PARADISE MX AZUL','PA300TRMXXL03903.jpg','48', '1'),"..
		"(2516,'PA300TRMXXL04003','PLAYERA ADULTO IBISCUS FOIL','PA300TRMXXL04003.jpg','48', '1'),"..
		"(2517,'PA300TRMXXL04103','PLAYERA ADULTO SUR TRUK','PA300TRMXXL04103.jpg','48', '1'),"..
		"(2518,'PA300TRMXXL04203','PLAYERA ADULTO SELLO FOIL PLATA','PA300TRMXXL04203.jpg','48', '1'),"..
		"(2519,'PA300TRMXXL04303','PLAYERA ADULTO GEKO ESCALANDO','PA300TRMXXL04303.jpg','48', '1'),"..
		"(2520,'PA300TRMXXL04403','PLAYERA ADULTO PROPERTY','PA300TRMXXL04403.jpg','48', '1'),"..
		"(2521,'PA300TRMXXL04503','PLAYERA ADULTO ORIGINAL GEKO','PA300TRMXXL04503.jpg','48', '1'),"..
		"(2522,'PA300TRMXXL04610','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TRMXXL04610.jpg','73', '1'),"..
		"(2523,'PA300TRMXXL04713','PLAYERA ADULTO TORTUGAS RECTANGULO','PA300TRMXXL04713.jpg','73', '1'),"..
		"(2524,'PA300TRMXXL04811','PLAYERA ADULTO AUTHENTIC BRAND','PA300TRMXXL04811.jpg','73', '1'),"..
		"(2525,'PA300TRMXXL04916','PLAYERA ADULTO AUTHENTIC BRAND','PA300TRMXXL04916.jpg','73', '1'),"..
		"(2526,'PA300TRMXXL05024','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TRMXXL05024.jpg','73', '1'),"..
		"(2527,'PA300TRMXXL05194','PLAYERA ADULTO DESTINO 2 CIRCULOS','PA300TRMXXL05194.jpg','73', '1'),"..
		"(2528,'PA300TRMXXL05212','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TRMXXL05212.jpg','73', '1'),"..
		"(2529,'PA300TRMXXL053Q','PLAYERA ADULTO ESCUDO GUIRNALDA','PA300TRMXXL053Q.jpg','73', '1'),"..
		"(2530,'PA300TRMXXL05413','PLAYERA ADULTO 3 ESTRELLAS','PA300TRMXXL05413.jpg','73', '1'),"..
		"(2531,'PA300TRMXXL05508','PLAYERA ADULTO VARSITY PARDISE','PA300TRMXXL05508.jpg','73', '1'),"..
		"(2532,'PA300TRMXXL05612','PLAYERA ADULTO VARSITY PARDISE','PA300TRMXXL05612.jpg','73', '1'),"..
		"(2533,'PA300TRMXXL05704','PLAYERA ADULTO FIRMA ATHLETIC','PA300TRMXXL05704.jpg','73', '1'),"..
		"(2534,'PA300TRMXXL05894','PLAYERA ADULTO FIRMA ATHLETIC','PA300TRMXXL05894.jpg','73', '1'),"..
		"(2535,'PA300TRMXXL05909','PLAYERA ADULTO FIRMA ATHLETIC','PA300TRMXXL05909.jpg','73', '1'),"..
		"(2536,'PA300TRMXXL06009','PLAYERA ADULTO PALMERA ORIGINAL','PA300TRMXXL06009.jpg','73', '1'),"..
		"(2537,'PA300TRMXXL06194','PLAYERA ADULTO PALMERA ORIGINAL','PA300TRMXXL06194.jpg','73', '1'),"..
		"(2538,'PA300TRMXXL062Q','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TRMXXL062Q.jpg','73', '1'),"..
		"(2539,'PA300TRMXXL06310','PLAYERA ADULTO RECTANGULO PAISAJE','PA300TRMXXL06310.jpg','73', '1'),"..
		"(2540,'PA300TRMXXL06424','PLAYERA ADULTO CIRCULO MEX','PA300TRMXXL06424.jpg','73', '1'),"..
		"(2541,'PA300TRMXXL06508','PLAYERA ADULTO CIRCULO MEX','PA300TRMXXL06508.jpg','73', '1'),"..
		"(2542,'PA300TRMXXL06671','PLAYERA ADUTLO 6 PALMERAS RECTANGULOS','PA300TRMXXL06671.jpg','73', '1'),"..
		"(2543,'PA300TRMXXL06727','PLAYERA ADULTO 6 PALMERAS RECTANGULOS','PA300TRMXXL06727.jpg','73', '1'),"..
		"(2544,'PA300TRMXXL06813','PLAYERA ADULTO IGUANA NEON','PA300TRMXXL06813.jpg','73', '1'),"..
		"(2545,'PA300TRMXXL06910','PLAYERA ADULTO MX SOMBRAS','PA300TRMXXL06910.jpg','73', '1'),"..
		"(2546,'PA300TRMXXL07009','PLAYERA ADULTO MX SOMBRAS','PA300TRMXXL07009.jpg','73', '1'),"..
		"(2547,'PA310TCN00109','PLAYERA SIN MAGA 2 GEKOS MX','PA310TCN00109.jpg','62', '1'),"..
		"(2548,'PA310TCN00216','PLAYERA SIN MAGA DELFIN CUADRO','PA310TCN00216.jpg','62', '1'),"..
		"(2549,'PA310TCN00311','PLAYERA SIN MAGA VELERO NAUTICAL','PA310TCN00311.jpg','62', '1'),"..
		"(2550,'PA310TCN00413','PLAYERA SIN MAGA EST 70','PA310TCN00413.jpg','62', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(2551,'PA310TCN00503','PLAYERA SIN MAGA PROPERTY','PA310TCN00503.jpg','38', '1'),"..
		"(2552,'PA310TCN07103','PLAYERA SIN MANGA FIRMA ATHLETIC','PA310TCN07103.jpg','38', '1'),"..
		"(2553,'PA310TCN07209','PLAYERA SIN MANGA AUTHENTIC BRAND','PA310TCN07209.jpg','62', '1'),"..
		"(2554,'PA310TCN07311','PLAYERA SIN MANGA TORTUGAS RECTANGULO','PA310TCN07311.jpg','62', '1'),"..
		"(2555,'PA310TCN07416','PLAYERA SIN MANGA CIRCULO MEX','PA310TCN07416.jpg','62', '1'),"..
		"(2556,'PA310TCN07513','PLAYERA SIN MANGA IGUANA NEON','PA310TCN07513.jpg','62', '1'),"..
		"(2557,'PA310TCNXXL00109','PLAYERA SIN MAGA 2 GEKOS MX','PA310TCNXXL00109.jpg','73', '1'),"..
		"(2558,'PA310TCNXXL00216','PLAYERA SIN MAGA DELFIN CUADRO','PA310TCNXXL00216.jpg','73', '1'),"..
		"(2559,'PA310TCNXXL00311','PLAYERA SIN MAGA VELERO NAUTICAL','PA310TCNXXL00311.jpg','73', '1'),"..
		"(2560,'PA310TCNXXL00413','PLAYERA SIN MAGA EST 70','PA310TCNXXL00413.jpg','73', '1'),"..
		"(2561,'PA310TCNXXL00503','PLAYERA SIN MAGA PROPERTY','PA310TCNXXL00503.jpg','48', '1'),"..
		"(2562,'PA310TCNXXL07103','PLAYERA SIN MANGA FIRMA ATHLETIC','PA310TCNXXL07103.jpg','48', '1'),"..
		"(2563,'PA310TCNXXL07209','PLAYERA SIN MANGA AUTHENTIC BRAND','PA310TCNXXL07209.jpg','73', '1'),"..
		"(2564,'PA310TCNXXL07311','PLAYERA SIN MANGA TORTUGAS RECTANGULO','PA310TCNXXL07311.jpg','73', '1'),"..
		"(2565,'PA310TCNXXL07416','PLAYERA SIN MANGA CIRCULO MEX','PA310TCNXXL07416.jpg','73', '1'),"..
		"(2566,'PA310TCNXXL07513','PLAYERA SIN MANGA IGUANA NEON','PA310TCNXXL07513.jpg','73', '1'),"..
		"(2567,'PA310TRM00109','PLAYERA SIN MAGA 2 GEKOS MX','PA310TRM00109.jpg','62', '1'),"..
		"(2568,'PA310TRM00216','PLAYERA SIN MAGA DELFIN CUADRO','PA310TRM00216.jpg','62', '1'),"..
		"(2569,'PA310TRM00311','PLAYERA SIN MAGA VELERO NAUTICAL','PA310TRM00311.jpg','62', '1'),"..
		"(2570,'PA310TRM00413','PLAYERA SIN MAGA EST 70','PA310TRM00413.jpg','62', '1'),"..
		"(2571,'PA310TRM00503','PLAYERA SIN MAGA PROPERTY','PA310TRM00503.jpg','38', '1'),"..
		"(2572,'PA310TRM07103','PLAYERA SIN MANGA FIRMA ATHLETIC','PA310TRM07103.jpg','38', '1'),"..
		"(2573,'PA310TRM07209','PLAYERA SIN MANGA AUTHENTIC BRAND','PA310TRM07209.jpg','62', '1'),"..
		"(2574,'PA310TRM07311','PLAYERA SIN MANGA TORTUGAS RECTANGULO','PA310TRM07311.jpg','62', '1'),"..
		"(2575,'PA310TRM07416','PLAYERA SIN MANGA CIRCULO MEX','PA310TRM07416.jpg','62', '1'),"..
		"(2576,'PA310TRM07513','PLAYERA SIN MANGA IGUANA NEON','PA310TRM07513.jpg','62', '1'),"..
		"(2577,'PA310TRMXXL00109','PLAYERA SIN MAGA 2 GEKOS MX','PA310TRMXXL00109.jpg','73', '1'),"..
		"(2578,'PA310TRMXXL00216','PLAYERA SIN MAGA DELFIN CUADRO','PA310TRMXXL00216.jpg','73', '1'),"..
		"(2579,'PA310TRMXXL00311','PLAYERA SIN MAGA VELERO NAUTICAL','PA310TRMXXL00311.jpg','73', '1'),"..
		"(2580,'PA310TRMXXL00413','PLAYERA SIN MAGA EST 70','PA310TRMXXL00413.jpg','73', '1'),"..
		"(2581,'PA310TRMXXL00503','PLAYERA SIN MAGA PROPERTY','PA310TRMXXL00503.jpg','48', '1'),"..
		"(2582,'PA310TRMXXL07103','PLAYERA SIN MANGA FIRMA ATHLETIC','PA310TRMXXL07103.jpg','48', '1'),"..
		"(2583,'PA310TRMXXL07209','PLAYERA SIN MANGA AUTHENTIC BRAND','PA310TRMXXL07209.jpg','73', '1'),"..
		"(2584,'PA310TRMXXL07311','PLAYERA SIN MANGA TORTUGAS RECTANGULO','PA310TRMXXL07311.jpg','73', '1'),"..
		"(2585,'PA310TRMXXL07416','PLAYERA SIN MANGA CIRCULO MEX','PA310TRMXXL07416.jpg','73', '1'),"..
		"(2586,'PA310TRMXXL07513','PLAYERA SIN MANGA IGUANA NEON','PA310TRMXXL07513.jpg','73', '1'),"..
		"(2587,'PB165TRM0104','PLAYERA BEBE TRANSFER COLOR','PB165TRM0104.jpg','50', '1'),"..
		"(2588,'PB165TRM0118','PLAYERA BEBE TRANSFER COLOR','PB165TRM0118.jpg','50', '1'),"..
		"(2589,'PB165TRM0129','PLAYERA BEBE TRANSFER COLOR','PB165TRM0129.jpg','50', '1'),"..
		"(2590,'PD250TCN001U','PLAYERA DAMA JASPEADA TENIS','PD250TCN001U.jpg','62', '1'),"..
		"(2591,'PD250TCN00212','PLAYERA DAMA JASPEADA LOVE MOSAICO','PD250TCN00212.jpg','62', '1'),"..
		"(2592,'PD250TCN00374','PLAYERA DAMA JASPEADA PALMERAS COOL','PD250TCN00374.jpg','62', '1'),"..
		"(2593,'PD250TCN00415','PLAYERA DAMA JASPEADA CORAZON LOVE','PD250TCN00415.jpg','62', '1'),"..
		"(2594,'PD250TCN00513','PLAYERA DAMA JASPEADA CORAZON MASAICO','PD250TCN00513.jpg','62', '1'),"..
		"(2595,'PD250TRM001U','PLAYERA DAMA JASPEADA TENIS','PD250TRM001U.jpg','62', '1'),"..
		"(2596,'PD250TRM00212','PLAYERA DAMA JASPEADA LOVE MOSAICO','PD250TRM00212.jpg','62', '1'),"..
		"(2597,'PD250TRM00374','PLAYERA DAMA JASPEADA PALMERAS COOL','PD250TRM00374.jpg','62', '1'),"..
		"(2598,'PD250TRM00415','PLAYERA DAMA JASPEADA CORAZON LOVE','PD250TRM00415.jpg','62', '1'),"..
		"(2599,'PD250TRM00513','PLAYERA DAMA JASPEADA CORAZON MASAICO','PD250TRM00513.jpg','62', '1'),"..
		"(2600,'PD300TCN00111','PLAYERA DAMA 3 PALMERAS NEON','PD300TCN00111.jpg','62', '1'),"..
		"(2601,'PD300TCN00117','PLAYERA DAMA 3 PALMERAS NEON','PD300TCN00117.jpg','62', '1'),"..
		"(2602,'PD300TCN00171','PLAYERA DAMA 3 PALMERAS NEON','PD300TCN00171.jpg','62', '1'),"..
		"(2603,'PD300TCN00211','PLAYERA DAMA IBISCUS NEON','PD300TCN00211.jpg','62', '1'),"..
		"(2604,'PD300TCN00311','PLAYERA DAMA CORAZON IBISCUS','PD300TCN00311.jpg','62', '1'),"..
		"(2605,'PD300TCN00403','PLAYERA DAMA CORAZON MOSAICO','PD300TCN00403.jpg','62', '1'),"..
		"(2606,'PD300TCN00471','PLAYERA DAMA CORAZON MOSAICO','PD300TCN00471.jpg','62', '1'),"..
		"(2607,'PD300TCN00513','PLAYERA DAMA LOVE MOSAICO','PD300TCN00513.jpg','62', '1'),"..
		"(2608,'PD300TCN00613','PLAYERA DAMA AHUTRNTIC TENIS','PD300TCN00613.jpg','62', '1'),"..
		"(2609,'PD300TCN00617','PLAYERA DAMA AHUTRNTIC TENIS','PD300TCN00617.jpg','62', '1'),"..
		"(2610,'PD300TCN00771','PLAYERA DAMA LETRAS ZEBRA','PD300TCN00771.jpg','62', '1'),"..
		"(2611,'PD300TCN00875','PLAYERA DAMA SOL OLAS','PD300TCN00875.jpg','62', '1'),"..
		"(2612,'PD300TCN00903','PLAYERA DAMA CORAZON I LOVE','PD300TCN00903.jpg','62', '1'),"..
		"(2613,'PD300TCN00911','PLAYERA DAMA CORAZON I LOVE','PD300TCN00911.jpg','62', '1'),"..
		"(2614,'PD300TCN01013','PLAYERA DAMA CORAZON 3 FLORES','PD300TCN01013.jpg','62', '1'),"..
		"(2615,'PD300TCN01018','PLAYERA DAMA CORAZON 3 FLORES','PD300TCN01018.jpg','62', '1'),"..
		"(2616,'PD300TCN01071','PLAYERA DAMA CORAZON 3 FLORES','PD300TCN01071.jpg','62', '1'),"..
		"(2617,'PD300TCN01111','PLAYERA DAMA 2 PALMERAS NEON','PD300TCN01111.jpg','62', '1'),"..
		"(2618,'PD300TCN01113','PLAYERA DAMA 2 PALMERAS NEON','PD300TCN01113.jpg','62', '1'),"..
		"(2619,'PD300TCN01171','PLAYERA DAMA 2 PALMERAS NEON','PD300TCN01171.jpg','62', '1'),"..
		"(2620,'PD300TCN01229','PLAYERA DAMA MX CORAZON','PD300TCN01229.jpg','62', '1'),"..
		"(2621,'PD300TCN01318','PLAYERA DAMA IBISCUS LOVE','PD300TCN01318.jpg','62', '1'),"..
		"(2622,'PD300TCN01329','PLAYERA DAMA IBISCUS LOVE','PD300TCN01329.jpg','62', '1'),"..
		"(2623,'PD300TCN01413','PLAYERA DAMA CORAZON PALMERAS','PD300TCN01413.jpg','62', '1'),"..
		"(2624,'PD300TCN01471','PLAYERA DAMA CORAZON PALMERAS','PD300TCN01471.jpg','62', '1'),"..
		"(2625,'PD300TCN01513','PLAYERA DAMA ONE LOVE','PD300TCN01513.jpg','62', '1'),"..
		"(2626,'PD300TCN01540','PLAYERA DAMA ONE LOVE','PD300TCN01540.jpg','62', '1'),"..
		"(2627,'PD300TCN01603','PLAYERA DAMA PARADISE MX AZUL','PD300TCN01603.jpg','62', '1'),"..
		"(2628,'PD300TCN01611','PLAYERA DAMA PARADISE MX AZUL','PD300TCN01611.jpg','62', '1'),"..
		"(2629,'PD300TCN01703','PLAYERA DAMA CHANCLITAS','PD300TCN01703.jpg','62', '1'),"..
		"(2630,'PD300TCN01875','PLAYERA DAMA IBISCUS GAVIOTA','PD300TCN01875.jpg','62', '1'),"..
		"(2631,'PD300TCN01913','PLAYERA DAMA DESTINO PES PUNTE','PD300TCN01913.jpg','62', '1'),"..
		"(2632,'PD300TCN02003','PLAYERA DAMA IBISCUS PAISAJE','PD300TCN02003.jpg','62', '1'),"..
		"(2633,'PD300TCN02071','PLAYERA DAMA IBISCUS PAISAJE','PD300TCN02071.jpg','62', '1'),"..
		"(2634,'PD300TCN02137','PLAYERA DAMA 2 TORTUGAS FLORES','PD300TCN02137.jpg','62', '1'),"..
		"(2635,'PD300TCN02218','PLAYERA DAMA LOVE','PD300TCN02218.jpg','62', '1'),"..
		"(2636,'PD300TCN02229','PLAYERA DAMA LOVE','PD300TCN02229.jpg','62', '1'),"..
		"(2637,'PD300TCN02313','PLAYERA DAMA MARGARITAS FLORES','PD300TCN02313.jpg','62', '1'),"..
		"(2638,'PD300TCN02374','PLAYERA DAMA MARGARITAS FLORES','PD300TCN02374.jpg','62', '1'),"..
		"(2639,'PD300TCN02418','PLAYERA DAMA ADDICTED TO LOVE','PD300TCN02418.jpg','62', '1'),"..
		"(2640,'PD300TCN02474','PLAYERA DAMA ADDICTED TO LOVE','PD300TCN02474.jpg','62', '1'),"..
		"(2641,'PD300TCN02529','PLAYERA DAMA COOL ROLE','PD300TCN02529.jpg','62', '1'),"..
		"(2642,'PD300TCN07640','PLAYERA DAMA LOVE PAISAJE','PD300TCN07640.jpg','62', '1'),"..
		"(2643,'PD300TCN07771','PLAYERA DAMA LOVE GIRASOL','PD300TCN07771.jpg','62', '1'),"..
		"(2644,'PD300TCN07888','PLAYERA DAMA MX CORAZON','PD300TCN07888.jpg','62', '1'),"..
		"(2645,'PD300TCN07978','PLAYERA DAMA TORTUGA PALMERAS','PD300TCN07978.jpg','62', '1'),"..
		"(2646,'PD300TCN08018','PLAYERA DAMA FLORES 70','PD300TCN08018.jpg','62', '1'),"..
		"(2647,'PD300TCN08174','PLAYERA DAMA BEACH PARADISE','PD300TCN08174.jpg','62', '1'),"..
		"(2648,'PD300TCN08211','PLAYERA DAMA FIRMA ESCUDO PALMERA','PD300TCN08211.jpg','62', '1'),"..
		"(2649,'PD300TCN083Q','PLAYERA DAMA 3 CORAZONES SINCE','PD300TCN083Q.jpg','62', '1'),"..
		"(2650,'PD300TCN08471','PLAYERA DAMA 3 PALMERAS ROCK','PD300TCN08471.jpg','62', '1'),"..
		"(2651,'PD300TCN08529','PLAYERA DAMA DESTINO ROMBO','PD300TCN08529.jpg','62', '1'),"..
		"(2652,'PD300TCN08675','PLAYERA DAMA ENJOY LIFE','PD300TCN08675.jpg','62', '1'),"..
		"(2653,'PD300TCN08713','PLAYERA DAMA LOVE PARCHE','PD300TCN08713.jpg','62', '1'),"..
		"(2654,'PD300TRM00171','PLAYERA DAMA 3 PALMERAS NEON','PD300TRM00171.jpg','62', '1'),"..
		"(2655,'PD300TRM00211','PLAYERA DAMA IBISCUS NEON','PD300TRM00211.jpg','62', '1'),"..
		"(2656,'PD300TRM00311','PLAYERA DAMA CORAZON IBISCUS','PD300TRM00311.jpg','62', '1'),"..
		"(2657,'PD300TRM00403','PLAYERA DAMA CORAZON MOSAICO','PD300TRM00403.jpg','62', '1'),"..
		"(2658,'PD300TRM00513','PLAYERA DAMA LOVE MOSAICO','PD300TRM00513.jpg','62', '1'),"..
		"(2659,'PD300TRM00613','PLAYERA DAMA AHUTRNTIC TENIS','PD300TRM00613.jpg','62', '1'),"..
		"(2660,'PD300TRM00771','PLAYERA DAMA LETRAS ZEBRA','PD300TRM00771.jpg','62', '1'),"..
		"(2661,'PD300TRM00875','PLAYERA DAMA SOL OLAS','PD300TRM00875.jpg','62', '1'),"..
		"(2662,'PD300TRM00911','PLAYERA DAMA CORAZON I LOVE','PD300TRM00911.jpg','62', '1'),"..
		"(2663,'PD300TRM01071','PLAYERA DAMA CORAZON 3 FLORES','PD300TRM01071.jpg','62', '1'),"..
		"(2664,'PD300TRM01111','PLAYERA DAMA 2 PALMERAS NEON','PD300TRM01111.jpg','62', '1'),"..
		"(2665,'PD300TRM01229','PLAYERA DAMA MX CORAZON','PD300TRM01229.jpg','62', '1'),"..
		"(2666,'PD300TRM01318','PLAYERA DAMA IBISCUS LOVE','PD300TRM01318.jpg','62', '1'),"..
		"(2667,'PD300TRM01413','PLAYERA DAMA CORAZON PALMERAS','PD300TRM01413.jpg','62', '1'),"..
		"(2668,'PD300TRM01471','PLAYERA DAMA CORAZON PALMERAS','PD300TRM01471.jpg','62', '1'),"..
		"(2669,'PD300TRM01513','PLAYERA DAMA ONE LOVE','PD300TRM01513.jpg','62', '1'),"..
		"(2670,'PD300TRM01540','PLAYERA DAMA ONE LOVE','PD300TRM01540.jpg','62', '1'),"..
		"(2671,'PD300TRM01603','PLAYERA DAMA PARADISE MX AZUL','PD300TRM01603.jpg','62', '1'),"..
		"(2672,'PD300TRM01611','PLAYERA DAMA PARADISE MX AZUL','PD300TRM01611.jpg','62', '1'),"..
		"(2673,'PD300TRM01703','PLAYERA DAMA CHANCLITAS','PD300TRM01703.jpg','62', '1'),"..
		"(2674,'PD300TRM01875','PLAYERA DAMA IBISCUS GAVIOTA','PD300TRM01875.jpg','62', '1'),"..
		"(2675,'PD300TRM01913','PLAYERA DAMA DESTINO PES PUNTE','PD300TRM01913.jpg','62', '1'),"..
		"(2676,'PD300TRM02003','PLAYERA DAMA IBISCUS PAISAJE','PD300TRM02003.jpg','62', '1'),"..
		"(2677,'PD300TRM02071','PLAYERA DAMA IBISCUS PAISAJE','PD300TRM02071.jpg','62', '1'),"..
		"(2678,'PD300TRM02137','PLAYERA DAMA 2 TORTUGAS FLORES','PD300TRM02137.jpg','62', '1'),"..
		"(2679,'PD300TRM02218','PLAYERA DAMA LOVE','PD300TRM02218.jpg','62', '1'),"..
		"(2680,'PD300TRM02229','PLAYERA DAMA LOVE','PD300TRM02229.jpg','62', '1'),"..
		"(2681,'PD300TRM02313','PLAYERA DAMA MARGARITAS FLORES','PD300TRM02313.jpg','62', '1'),"..
		"(2682,'PD300TRM02374','PLAYERA DAMA MARGARITAS FLORES','PD300TRM02374.jpg','62', '1'),"..
		"(2683,'PD300TRM02418','PLAYERA DAMA ADDICTED TO LOVE','PD300TRM02418.jpg','62', '1'),"..
		"(2684,'PD300TRM02474','PLAYERA DAMA ADDICTED TO LOVE','PD300TRM02474.jpg','62', '1'),"..
		"(2685,'PD300TRM02529','PLAYERA DAMA COOL ROLE','PD300TRM02529.jpg','62', '1'),"..
		"(2686,'PD300TRM07640','PLAYERA DAMA LOVE PAISAJE','PD300TRM07640.jpg','62', '1'),"..
		"(2687,'PD300TRM07771','PLAYERA DAMA LOVE GIRASOL','PD300TRM07771.jpg','62', '1'),"..
		"(2688,'PD300TRM07888','PLAYERA DAMA MX CORAZON','PD300TRM07888.jpg','62', '1'),"..
		"(2689,'PD300TRM07978','PLAYERA DAMA TORTUGA PALMERAS','PD300TRM07978.jpg','62', '1'),"..
		"(2690,'PD300TRM08018','PLAYERA DAMA FLORES 70','PD300TRM08018.jpg','62', '1'),"..
		"(2691,'PD300TRM08174','PLAYERA DAMA BEACH PARADISE','PD300TRM08174.jpg','62', '1'),"..
		"(2692,'PD300TRM08211','PLAYERA DAMA FIRMA ESCUDO PALMERA','PD300TRM08211.jpg','62', '1'),"..
		"(2693,'PD300TRM083Q','PLAYERA DAMA 3 CORAZONES SINCE','PD300TRM083Q.jpg','62', '1'),"..
		"(2694,'PD300TRM08471','PLAYERA DAMA 3 PALMERAS ROCK','PD300TRM08471.jpg','62', '1'),"..
		"(2695,'PD300TRM08529','PLAYERA DAMA DESTINO ROMBO','PD300TRM08529.jpg','62', '1'),"..
		"(2696,'PD300TRM08675','PLAYERA DAMA ENJOY LIFE','PD300TRM08675.jpg','62', '1'),"..
		"(2697,'PD300TRM08713','PLAYERA DAMA LOVE PARCHE','PD300TRM08713.jpg','62', '1'),"..
		"(2698,'PDJ300TCN00111','PLAYERA NIÑA 3 PALMERAS NEON','PDJ300TCN00111.jpg','55', '1'),"..
		"(2699,'PDJ300TCN00117','PLAYERA NIÑA 3 PALMERAS NEON','PDJ300TCN00117.jpg','55', '1'),"..
		"(2700,'PDJ300TCN00171','PLAYERA NIÑA 3 PALMERAS NEON','PDJ300TCN00171.jpg','55', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(2701,'PDJ300TCN00211','PLAYERA NIÑA IBISCUS NEON','PDJ300TCN00211.jpg','55', '1'),"..
		"(2702,'PDJ300TCN00311','PLAYERA NIÑA CORAZON IBISCUS','PDJ300TCN00311.jpg','55', '1'),"..
		"(2703,'PDJ300TCN00374','PLAYERA NIÑA CORAZON IBISCUS','PDJ300TCN00374.jpg','55', '1'),"..
		"(2704,'PDJ300TCN00403','PLAYERA NIÑA CORAZON MOSAICO','PDJ300TCN00403.jpg','55', '1'),"..
		"(2705,'PDJ300TCN00471','PLAYERA NIÑA CORAZON MOSAICO','PDJ300TCN00471.jpg','55', '1'),"..
		"(2706,'PDJ300TCN00513','PLAYERA NIÑA LOVE MOSAICO','PDJ300TCN00513.jpg','55', '1'),"..
		"(2707,'PDJ300TCN00613','PLAYERA NIÑA AHUTRNTIC TENIS','PDJ300TCN00613.jpg','55', '1'),"..
		"(2708,'PDJ300TCN00617','PLAYERA NIÑA AHUTRNTIC TENIS','PDJ300TCN00617.jpg','55', '1'),"..
		"(2709,'PDJ300TCN00771','PLAYERA NIÑA LETRAS ZEBRA','PDJ300TCN00771.jpg','55', '1'),"..
		"(2710,'PDJ300TCN00874','PLAYERA NIÑA SOL OLAS','PDJ300TCN00874.jpg','55', '1'),"..
		"(2711,'PDJ300TCN00903','PLAYERA NIÑA CORAZON I LOVE','PDJ300TCN00903.jpg','55', '1'),"..
		"(2712,'PDJ300TCN00911','PLAYERA NIÑA CORAZON I LOVE','PDJ300TCN00911.jpg','55', '1'),"..
		"(2713,'PDJ300TCN01013','PLAYERA NIÑA CORAZON 3 FLORES','PDJ300TCN01013.jpg','55', '1'),"..
		"(2714,'PDJ300TCN01018','PLAYERA NIÑA CORAZON 3 FLORES','PDJ300TCN01018.jpg','55', '1'),"..
		"(2715,'PDJ300TCN01071','PLAYERA NIÑA CORAZON 3 FLORES','PDJ300TCN01071.jpg','55', '1'),"..
		"(2716,'PDJ300TCN01111','PLAYERA NIÑA 2 PALMERAS NEON','PDJ300TCN01111.jpg','55', '1'),"..
		"(2717,'PDJ300TCN01113','PLAYERA NIÑA 2 PALMERAS NEON','PDJ300TCN01113.jpg','55', '1'),"..
		"(2718,'PDJ300TCN01171','PLAYERA NIÑA 2 PALMERAS NEON','PDJ300TCN01171.jpg','55', '1'),"..
		"(2719,'PDJ300TCN01229','PLAYERA NIÑA MX CORAZON','PDJ300TCN01229.jpg','55', '1'),"..
		"(2720,'PDJ300TCN01318','PLAYERA NIÑA IBISCUS LOVE','PDJ300TCN01318.jpg','55', '1'),"..
		"(2721,'PDJ300TCN01329','PLAYERA NIÑA IBISCUS LOVE','PDJ300TCN01329.jpg','55', '1'),"..
		"(2722,'PDJ300TCN01413','PLAYERA NIÑA CORAZON PALMERAS','PDJ300TCN01413.jpg','55', '1'),"..
		"(2723,'PDJ300TCN01471','PLAYERA NIÑA CORAZON PALMERAS','PDJ300TCN01471.jpg','55', '1'),"..
		"(2724,'PDJ300TCN01513','PLAYERA NIÑA ONE LOVE','PDJ300TCN01513.jpg','55', '1'),"..
		"(2725,'PDJ300TCN01540','PLAYERA NIÑA ONE LOVE','PDJ300TCN01540.jpg','55', '1'),"..
		"(2726,'PDJ300TCN01603','PLAYERA NIÑA PARADISE MX AZUL','PDJ300TCN01603.jpg','55', '1'),"..
		"(2727,'PDJ300TCN01611','PLAYERA NIÑA PARADISE MX AZUL','PDJ300TCN01611.jpg','55', '1'),"..
		"(2728,'PDJ300TCN01703','PLAYERA NIÑA CHANCLITAS','PDJ300TCN01703.jpg','55', '1'),"..
		"(2729,'PDJ300TCN01875','PLAYERA NIÑA IBISCUS GAVIOTA','PDJ300TCN01875.jpg','55', '1'),"..
		"(2730,'PDJ300TCN01913','PLAYERA NIÑA DESTINO PES PUNTE','PDJ300TCN01913.jpg','55', '1'),"..
		"(2731,'PDJ300TCN02003','PLAYERA NIÑA IBISCUS PAISAJE','PDJ300TCN02003.jpg','55', '1'),"..
		"(2732,'PDJ300TCN02071','PLAYERA NIÑA IBISCUS PAISAJE','PDJ300TCN02071.jpg','55', '1'),"..
		"(2733,'PDJ300TCN02137','PLAYERA NIÑA 2 TORTUGAS FLORES','PDJ300TCN02137.jpg','55', '1'),"..
		"(2734,'PDJ300TCN02218','PLAYERA NIÑA LOVE','PDJ300TCN02218.jpg','55', '1'),"..
		"(2735,'PDJ300TCN02229','PLAYERA NIÑA LOVE','PDJ300TCN02229.jpg','55', '1'),"..
		"(2736,'PDJ300TCN02313','PLAYERA NIÑA MARGARITAS FLORES','PDJ300TCN02313.jpg','55', '1'),"..
		"(2737,'PDJ300TCN02374','PLAYERA NIÑA MARGARITAS FLORES','PDJ300TCN02374.jpg','55', '1'),"..
		"(2738,'PDJ300TCN02418','PLAYERA NIÑA ADDICTED TO LOVE','PDJ300TCN02418.jpg','55', '1'),"..
		"(2739,'PDJ300TCN02474','PLAYERA NIÑA ADDICTED TO LOVE','PDJ300TCN02474.jpg','55', '1'),"..
		"(2740,'PDJ300TCN02529','PLAYERA NIÑA COOL ROLE','PDJ300TCN02529.jpg','55', '1'),"..
		"(2741,'PDJ300TCN09771','PLAYERA NIÑA COOL ROLE','PDJ300TCN09771.jpg','55', '1'),"..
		"(2742,'PDJ300TCN098Q','PLAYERA NIÑA CORAZONES LOVE','PDJ300TCN098Q.jpg','55', '1'),"..
		"(2743,'PDJ300TCN09929','PLAYERA NIÑA TENIS CIRCULO','PDJ300TCN09929.jpg','55', '1'),"..
		"(2744,'PDJ300TCN10013','PLAYERA NIÑA 8 CORAZONES','PDJ300TCN10013.jpg','55', '1'),"..
		"(2745,'PDJ300TCN10118','PLAYERA NIÑA SURF COMBI','PDJ300TCN10118.jpg','55', '1'),"..
		"(2746,'PDJ300TCN10271','PLAYERA NIÑA FIRMA RETRO','PDJ300TCN10271.jpg','55', '1'),"..
		"(2747,'PDJ300TCN10311','PLAYERA NIÑA DESTINO CORAZON NEON','PDJ300TCN10311.jpg','55', '1'),"..
		"(2748,'PDJ300TCN10474','PLAYERA NIÑA CORAZON PALMERAS','PDJ300TCN10474.jpg','55', '1'),"..
		"(2749,'PDJ300TRM00171','PLAYERA NIÑA 3 PALMERAS NEON','PDJ300TRM00171.jpg','55', '1'),"..
		"(2750,'PDJ300TRM00211','PLAYERA NIÑA IBISCUS NEON','PDJ300TRM00211.jpg','55', '1'),"..
		"(2751,'PDJ300TRM00311','PLAYERA NIÑA CORAZON IBISCUS','PDJ300TRM00311.jpg','55', '1'),"..
		"(2752,'PDJ300TRM00403','PLAYERA NIÑA CORAZON MOSAICO','PDJ300TRM00403.jpg','55', '1'),"..
		"(2753,'PDJ300TRM00513','PLAYERA NIÑA LOVE MOSAICO','PDJ300TRM00513.jpg','55', '1'),"..
		"(2754,'PDJ300TRM00613','PLAYERA NIÑA AHUTRNTIC TENIS','PDJ300TRM00613.jpg','55', '1'),"..
		"(2755,'PDJ300TRM00771','PLAYERA NIÑA LETRAS ZEBRA','PDJ300TRM00771.jpg','55', '1'),"..
		"(2756,'PDJ300TRM00875','PLAYERA NIÑA SOL OLAS','PDJ300TRM00875.jpg','55', '1'),"..
		"(2757,'PDJ300TRM00911','PLAYERA NIÑA CORAZON I LOVE','PDJ300TRM00911.jpg','55', '1'),"..
		"(2758,'PDJ300TRM01071','PLAYERA NIÑA CORAZON 3 FLORES','PDJ300TRM01071.jpg','55', '1'),"..
		"(2759,'PDJ300TRM01111','PLAYERA NIÑA 2 PALMERAS NEON','PDJ300TRM01111.jpg','55', '1'),"..
		"(2760,'PDJ300TRM01229','PLAYERA NIÑA MX CORAZON','PDJ300TRM01229.jpg','55', '1'),"..
		"(2761,'PDJ300TRM01318','PLAYERA NIÑA IBISCUS LOVE','PDJ300TRM01318.jpg','55', '1'),"..
		"(2762,'PDJ300TRM01413','PLAYERA NIÑA CORAZON PALMERAS','PDJ300TRM01413.jpg','55', '1'),"..
		"(2763,'PDJ300TRM01471','PLAYERA NIÑA CORAZON PALMERAS','PDJ300TRM01471.jpg','55', '1'),"..
		"(2764,'PDJ300TRM01513','PLAYERA NIÑA ONE LOVE','PDJ300TRM01513.jpg','55', '1'),"..
		"(2765,'PDJ300TRM01540','PLAYERA NIÑA ONE LOVE','PDJ300TRM01540.jpg','55', '1'),"..
		"(2766,'PDJ300TRM01603','PLAYERA NIÑA PARADISE MX AZUL','PDJ300TRM01603.jpg','55', '1'),"..
		"(2767,'PDJ300TRM01611','PLAYERA NIÑA PARADISE MX AZUL','PDJ300TRM01611.jpg','55', '1'),"..
		"(2768,'PDJ300TRM01703','PLAYERA NIÑA CHANCLITAS','PDJ300TRM01703.jpg','55', '1'),"..
		"(2769,'PDJ300TRM01875','PLAYERA NIÑA IBISCUS GAVIOTA','PDJ300TRM01875.jpg','55', '1'),"..
		"(2770,'PDJ300TRM01913','PLAYERA NIÑA DESTINO PES PUNTE','PDJ300TRM01913.jpg','55', '1'),"..
		"(2771,'PDJ300TRM02003','PLAYERA NIÑA IBISCUS PAISAJE','PDJ300TRM02003.jpg','55', '1'),"..
		"(2772,'PDJ300TRM02071','PLAYERA NIÑA IBISCUS PAISAJE','PDJ300TRM02071.jpg','55', '1'),"..
		"(2773,'PDJ300TRM02137','PLAYERA NIÑA 2 TORTUGAS FLORES','PDJ300TRM02137.jpg','55', '1'),"..
		"(2774,'PDJ300TRM02218','PLAYERA NIÑA LOVE','PDJ300TRM02218.jpg','55', '1'),"..
		"(2775,'PDJ300TRM02229','PLAYERA NIÑA LOVE','PDJ300TRM02229.jpg','55', '1'),"..
		"(2776,'PDJ300TRM02313','PLAYERA NIÑA MARGARITAS FLORES','PDJ300TRM02313.jpg','55', '1'),"..
		"(2777,'PDJ300TRM02374','PLAYERA NIÑA MARGARITAS FLORES','PDJ300TRM02374.jpg','55', '1'),"..
		"(2778,'PDJ300TRM02418','PLAYERA NIÑA ADDICTED TO LOVE','PDJ300TRM02418.jpg','55', '1'),"..
		"(2779,'PDJ300TRM02474','PLAYERA NIÑA ADDICTED TO LOVE','PDJ300TRM02474.jpg','55', '1'),"..
		"(2780,'PDJ300TRM02529','PLAYERA NIÑA COOL ROLE','PDJ300TRM02529.jpg','55', '1'),"..
		"(2781,'PDJ300TRM09771','PLAYERA NIÑA COOL ROLE','PDJ300TRM09771.jpg','55', '1'),"..
		"(2782,'PDJ300TRM098Q','PLAYERA NIÑA CORAZONES LOVE','PDJ300TRM098Q.jpg','55', '1'),"..
		"(2783,'PDJ300TRM09929','PLAYERA NIÑA TENIS CIRCULO','PDJ300TRM09929.jpg','55', '1'),"..
		"(2784,'PDJ300TRM10013','PLAYERA NIÑA 8 CORAZONES','PDJ300TRM10013.jpg','55', '1'),"..
		"(2785,'PDJ300TRM10118','PLAYERA NIÑA SURF COMBI','PDJ300TRM10118.jpg','55', '1'),"..
		"(2786,'PDJ300TRM10271','PLAYERA NIÑA FIRMA RETRO','PDJ300TRM10271.jpg','55', '1'),"..
		"(2787,'PDJ300TRM10311','PLAYERA NIÑA DESTINO CORAZON NEON','PDJ300TRM10311.jpg','55', '1'),"..
		"(2788,'PDJ300TRM10474','PLAYERA NIÑA CORAZON PALMERAS','PDJ300TRM10474.jpg','55', '1'),"..
		"(2789,'PDTTTCN00103','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTCN00103.jpg','75', '1'),"..
		"(2790,'PDTTTCN00113','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTCN00113.jpg','75', '1'),"..
		"(2791,'PDTTTCN00117','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTCN00117.jpg','75', '1'),"..
		"(2792,'PDTTTCN00118','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTCN00118.jpg','75', '1'),"..
		"(2793,'PDTTTCN00140','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTCN00140.jpg','75', '1'),"..
		"(2794,'PDTTTCN00171','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTCN00171.jpg','75', '1'),"..
		"(2795,'PDTTTRM00103','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTRM00103.jpg','75', '1'),"..
		"(2796,'PDTTTRM00113','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTRM00113.jpg','75', '1'),"..
		"(2797,'PDTTTRM00117','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTRM00117.jpg','75', '1'),"..
		"(2798,'PDTTTRM00118','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTRM00118.jpg','75', '1'),"..
		"(2799,'PDTTTRM00140','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTRM00140.jpg','75', '1'),"..
		"(2800,'PDTTTRM00171','PLAYERA DAMA TANK TOP PIEDRITAS','PDTTTRM00171.jpg','75', '1'),"..
		"(2801,'PN300TCN00173','PLAYERA NIÑO IGUANA FRANJA','PN300TCN00173.jpg','55', '1'),"..
		"(2802,'PN300TCN00212','PLAYERA NIÑO IGUANA STICH','PN300TCN00212.jpg','55', '1'),"..
		"(2803,'PN300TCN00310','PLAYERA NIÑO TORTUGA OLA','PN300TCN00310.jpg','55', '1'),"..
		"(2804,'PN300TCN00417','PLAYERA NIÑO 6 FIGURAS','PN300TCN00417.jpg','55', '1'),"..
		"(2805,'PN300TCN00511','PLAYERA NIÑO PALMERAS COOL','PN300TCN00511.jpg','55', '1'),"..
		"(2806,'PN300TCN00616','PLAYERA NIÑO MX ATHLETICS','PN300TCN00616.jpg','55', '1'),"..
		"(2807,'PN300TCN00711','PLAYERA NIÑO SELLO VERTICAL','PN300TCN00711.jpg','55', '1'),"..
		"(2808,'PN300TCN00810','PLAYERA NIÑO PALMERA COLEGIAL','PN300TCN00810.jpg','55', '1'),"..
		"(2809,'PN300TCN00912','PLAYERA NIÑO COLEGIAL MILITAR','PN300TCN00912.jpg','55', '1'),"..
		"(2810,'PN300TCN01011','PLAYERA NIÑO SELLO TIBURON','PN300TCN01011.jpg','55', '1'),"..
		"(2811,'PN300TCN01113','PLAYERA NIÑO IGUANA OLEO','PN300TCN01113.jpg','55', '1'),"..
		"(2812,'PN300TCN01216','PLAYERA NIÑO DELFIN CUADRO','PN300TCN01216.jpg','55', '1'),"..
		"(2813,'PN300TCN01303','PLAYERA NIÑO SUR TRUK','PN300TCN01303.jpg','55', '1'),"..
		"(2814,'PN300TCN01309','PLAYERA NIÑO SUR TRUK','PN300TCN01309.jpg','55', '1'),"..
		"(2815,'PN300TCN01310','PLAYERA NIÑO SUR TRUK','PN300TCN01310.jpg','55', '1'),"..
		"(2816,'PN300TCN01411','PLAYERA NIÑO 3 TORTUGAS NADANDO','PN300TCN01411.jpg','55', '1'),"..
		"(2817,'PN300TCN01473','PLAYERA NIÑO 3 TORTUGAS NADANDO','PN300TCN01473.jpg','55', '1'),"..
		"(2818,'PN300TCN08815','PLAYERA NIÑO TIBURON BRAND','PN300TCN08815.jpg','55', '1'),"..
		"(2819,'PN300TCN08973','PLAYERA NIÑO TIBURON CLASIC DIVISION','PN300TCN08973.jpg','55', '1'),"..
		"(2820,'PN300TCN09009','PLAYERA NIÑO IGUANA ATH','PN300TCN09009.jpg','55', '1'),"..
		"(2821,'PN300TCN09109','PLAYERA NIÑO MX TIBURON','PN300TCN09109.jpg','55', '1'),"..
		"(2822,'PN300TCN09213','PLAYERA NIÑO VARSITY SQUAD','PN300TCN09213.jpg','55', '1'),"..
		"(2823,'PN300TCN09311','PLAYERA NIÑO PALMERA 6 LINEAS','PN300TCN09311.jpg','55', '1'),"..
		"(2824,'PN300TCN09416','PLAYERA NIÑO 2 TENIS','PN300TCN09416.jpg','55', '1'),"..
		"(2825,'PN300TCN09512','PLAYERA NIÑO MEX TRADEMARK','PN300TCN09512.jpg','55', '1'),"..
		"(2826,'PN300TCN09610','PLAYERA NIÑO IGUANA MAYA','PN300TCN09610.jpg','55', '1'),"..
		"(2827,'PN300TRM00173','PLAYERA NIÑO IGUANA FRANJA','PN300TRM00173.jpg','55', '1'),"..
		"(2828,'PN300TRM00212','PLAYERA NIÑO IGUANA STICH','PN300TRM00212.jpg','55', '1'),"..
		"(2829,'PN300TRM00310','PLAYERA NIÑO TORTUGA OLA','PN300TRM00310.jpg','55', '1'),"..
		"(2830,'PN300TRM00417','PLAYERA NIÑO 6 FIGURAS','PN300TRM00417.jpg','55', '1'),"..
		"(2831,'PN300TRM00511','PLAYERA NIÑO PALMERAS COOL','PN300TRM00511.jpg','55', '1'),"..
		"(2832,'PN300TRM00616','PLAYERA NIÑO MX ATHLETICS','PN300TRM00616.jpg','55', '1'),"..
		"(2833,'PN300TRM00711','PLAYERA NIÑO SELLO VERTICAL','PN300TRM00711.jpg','55', '1'),"..
		"(2834,'PN300TRM00810','PLAYERA NIÑO PALMERA COLEGIAL','PN300TRM00810.jpg','55', '1'),"..
		"(2835,'PN300TRM00912','PLAYERA NIÑO COLEGIAL MILITAR','PN300TRM00912.jpg','55', '1'),"..
		"(2836,'PN300TRM01011','PLAYERA NIÑO SELLO TIBURON','PN300TRM01011.jpg','55', '1'),"..
		"(2837,'PN300TRM01113','PLAYERA NIÑO IGUANA OLEO','PN300TRM01113.jpg','55', '1'),"..
		"(2838,'PN300TRM01216','PLAYERA NIÑO DELFIN CUADRO','PN300TRM01216.jpg','55', '1'),"..
		"(2839,'PN300TRM01303','PLAYERA NIÑO SUR TRUK','PN300TRM01303.jpg','55', '1'),"..
		"(2840,'PN300TRM01309','PLAYERA NIÑO SUR TRUK','PN300TRM01309.jpg','55', '1'),"..
		"(2841,'PN300TRM01310','PLAYERA NIÑO SUR TRUK','PN300TRM01310.jpg','55', '1'),"..
		"(2842,'PN300TRM01411','PLAYERA NIÑO 3 TORTUGAS NADANDO','PN300TRM01411.jpg','55', '1'),"..
		"(2843,'PN300TRM01473','PLAYERA NIÑO 3 TORTUGAS NADANDO','PN300TRM01473.jpg','55', '1'),"..
		"(2844,'PN300TRM08815','PLAYERA NIÑO TIBURON BRAND','PN300TRM08815.jpg','55', '1'),"..
		"(2845,'PN300TRM08973','PLAYERA NIÑO TIBURON CLASIC DIVISION','PN300TRM08973.jpg','55', '1'),"..
		"(2846,'PN300TRM09009','PLAYERA NIÑO IGUANA ATH','PN300TRM09009.jpg','55', '1'),"..
		"(2847,'PN300TRM09109','PLAYERA NIÑO MX TIBURON','PN300TRM09109.jpg','55', '1'),"..
		"(2848,'PN300TRM09213','PLAYERA NIÑO VARSITY SQUAD','PN300TRM09213.jpg','55', '1'),"..
		"(2849,'PN300TRM09311','PLAYERA NIÑO PALMERA 6 LINEAS','PN300TRM09311.jpg','55', '1'),"..
		"(2850,'PN300TRM09416','PLAYERA NIÑO 2 TENIS','PN300TRM09416.jpg','55', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(2851,'PN300TRM09512','PLAYERA NIÑO MEX TRADEMARK','PN300TRM09512.jpg','55', '1'),"..
		"(2852,'PN300TRM09610','PLAYERA NIÑO IGUANA MAYA','PN300TRM09610.jpg','55', '1'),"..
		"(2853,'PNTTTCN00103','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTCN00103.jpg','66', '1'),"..
		"(2854,'PNTTTCN00117','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTCN00117.jpg','66', '1'),"..
		"(2855,'PNTTTCN00118','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTCN00118.jpg','66', '1'),"..
		"(2856,'PNTTTCN00140','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTCN00140.jpg','66', '1'),"..
		"(2857,'PNTTTCN00171','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTCN00171.jpg','66', '1'),"..
		"(2858,'PNTTTRM00103','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTRM00103.jpg','66', '1'),"..
		"(2859,'PNTTTRM00117','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTRM00117.jpg','66', '1'),"..
		"(2860,'PNTTTRM00118','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTRM00118.jpg','66', '1'),"..
		"(2861,'PNTTTRM00140','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTRM00140.jpg','66', '1'),"..
		"(2862,'PNTTTRM00171','PLAYERA NIÑA TANK TOP PIEDRITAS','PNTTTRM00171.jpg','66', '1'),"..
		"(2863,'PROCOA01502','COMBO BASICO ADULTO','PROCOA01502.jpg','85', '1'),"..
		"(2864,'PROCOA01511','COMBO BASICO ADULTO','PROCOA01511.jpg','85', '1'),"..
		"(2865,'PROCOA015XXL02','COMBO BASICO ADULTO','PROCOA015XXL02.jpg','85', '1'),"..
		"(2866,'PROCOA015XXL11','COMBO BASICO ADULTO','PROCOA015XXL11.jpg','85', '1'),"..
		"(2867,'PROCOD01540','COMBO BASICO DAMA','PROCOD01540.jpg','85', '1'),"..
		"(2868,'PROCOD01571','COMBO BASICO DAMA','PROCOD01571.jpg','85', '1'),"..
		"(2869,'PROGMBDES04','GORRA DESLAVADA PROGRESO','PROGMBDES04.jpg','63', '1'),"..
		"(2870,'PROGMBDES05','GORRA DESLAVADA PROGRESO','PROGMBDES05.jpg','63', '1'),"..
		"(2871,'PROGMBDES06','GORRA DESLAVADA PROGRESO','PROGMBDES06.jpg','63', '1'),"..
		"(2872,'PROGMBDES10','GORRA DESLAVADA PROGRESO','PROGMBDES10.jpg','63', '1'),"..
		"(2873,'PROGMBDES11','GORRA DESLAVADA PROGRESO','PROGMBDES11.jpg','63', '1'),"..
		"(2874,'PROGMBDES12','GORRA DESLAVADA PROGRESO','PROGMBDES12.jpg','63', '1'),"..
		"(2875,'PROGMBDES13','GORRA DESLAVADA PROGRESO','PROGMBDES13.jpg','63', '1'),"..
		"(2876,'PROGMBDES15','GORRA DESLAVADA PROGRESO','PROGMBDES15.jpg','63', '1'),"..
		"(2877,'PROGMBDES16','GORRA DESLAVADA PROGRESO','PROGMBDES16.jpg','63', '1'),"..
		"(2878,'PROGMBDES21','GORRA DESLAVADA PROGRESO','PROGMBDES21.jpg','63', '1'),"..
		"(2879,'PROGMBDES25','GORRA DESLAVADA PROGRESO','PROGMBDES25.jpg','63', '1'),"..
		"(2880,'PROGMBDES26','GORRA DESLAVADA PROGRESO','PROGMBDES26.jpg','63', '1'),"..
		"(2881,'PROGMBDES28','GORRA DESLAVADA PROGRESO','PROGMBDES28.jpg','63', '1'),"..
		"(2882,'PROGMBDES30','GORRA DESLAVADA PROGRESO','PROGMBDES30.jpg','63', '1'),"..
		"(2883,'PROGMBDES32','GORRA DESLAVADA PROGRESO','PROGMBDES32.jpg','63', '1'),"..
		"(2884,'PROGMBDES34','GORRA DESLAVADA PROGRESO','PROGMBDES34.jpg','63', '1'),"..
		"(2885,'PROGMBDES35','GORRA DESLAVADA PROGRESO','PROGMBDES35.jpg','63', '1'),"..
		"(2886,'PROGMBDES37','GORRA DESLAVADA PROGRESO','PROGMBDES37.jpg','63', '1'),"..
		"(2887,'PROGMBNIÑ02','GORRA NIÑO PROGRESO','PROGMBNIÑ02.jpg','63', '1'),"..
		"(2888,'PROGMBNIÑ10','GORRA NIÑO PROGRESO','PROGMBNIÑ10.jpg','63', '1'),"..
		"(2889,'PROGMBNIÑ11','GORRA NIÑO PROGRESO','PROGMBNIÑ11.jpg','63', '1'),"..
		"(2890,'PROGMBNIÑ12','GORRA NIÑO PROGRESO','PROGMBNIÑ12.jpg','63', '1'),"..
		"(2891,'PROGMBNIÑ15','GORRA NIÑO PROGRESO','PROGMBNIÑ15.jpg','63', '1'),"..
		"(2892,'RIMCON001','COMBO NIÑO GEKO MOSCO','RIMCON001.jpg','94', '1'),"..
		"(2893,'RIMCON002','COMBO NIÑO IGUANA TABLA','RIMCON002.jpg','94', '1'),"..
		"(2894,'RIMGDKBBE03','GORRA BEBE','RIMGDKBBE03.jpg','47', '1'),"..
		"(2895,'RIMGDKBBE04','GORRA BEBE','RIMGDKBBE04.jpg','47', '1'),"..
		"(2896,'RIMGDKBBE10','GORRA BEBE','RIMGDKBBE10.jpg','47', '1'),"..
		"(2897,'RIMGDKBBE12','GORRA BEBE','RIMGDKBBE12.jpg','47', '1'),"..
		"(2898,'RIMGDKBBE29','GORRA BEBE','RIMGDKBBE29.jpg','47', '1'),"..
		"(2899,'RIMGDKDES11','GORRA DESTAPADOR','RIMGDKDES11.jpg','63', '1'),"..
		"(2900,'RIMGDKDES13','GORRA DESTAPADOR','RIMGDKDES13.jpg','63', '1'),"..
		"(2901,'RIMGDKPLU12','GORRA PLUS','RIMGDKPLU12.jpg','68', '1'),"..
		"(2902,'RIMGDKPLU17','GORRA PLUS','RIMGDKPLU17.jpg','68', '1'),"..
		"(2903,'RIMGDKPLU18','GORRA PLUS','RIMGDKPLU18.jpg','68', '1'),"..
		"(2904,'RIMGDKPLU40','GORRA PLUS','RIMGDKPLU40.jpg','68', '1'),"..
		"(2905,'RIMGDKPLU71','GORRA PLUS','RIMGDKPLU71.jpg','68', '1'),"..
		"(2906,'RIMGGE00111','GORRA GENERICA 2 TORTUGAS NADANDO','RIMGGE00111.jpg','68', '1'),"..
		"(2907,'RIMGGE00216','GORRA GENERICA PARCHE KAKY','RIMGGE00216.jpg','68', '1'),"..
		"(2908,'RIMGGE00373','GORRA GENERICA PIRATAS','RIMGGE00373.jpg','68', '1'),"..
		"(2909,'RIMGGE00412','GORRA GENERICA TRES PALMERAS','RIMGGE00412.jpg','68', '1'),"..
		"(2910,'RIMGGE00508','GORRA GENERICA PESPUNTE RAYADA','RIMGGE00508.jpg','68', '1'),"..
		"(2911,'RIMGGE00604','GORRA GENERICA PALMERAS COMBI','RIMGGE00604.jpg','68', '1'),"..
		"(2912,'RIMGGE00713','GORRA GENERICA PARCHE MILITAR','RIMGGE00713.jpg','68', '1'),"..
		"(2913,'RIMGGE00803','GORRA GENERICA APLICACION AGUILA.','RIMGGE00803.jpg','68', '1'),"..
		"(2914,'RIMGGE00971','GORRA GENERICA BORDADO METALICO','RIMGGE00971.jpg','68', '1'),"..
		"(2915,'RIMGGE01003','GORRA GENERICA 3 GEKOS OVALO','RIMGGE01003.jpg','68', '1'),"..
		"(2916,'RIMGGE01304','GORRA GENERICA DRAGON CHINO','RIMGGE01304.jpg','68', '1'),"..
		"(2917,'RIMGGE01917','GORRA GENERICA FLOR CON ZIG-ZAG','RIMGGE01917.jpg','68', '1'),"..
		"(2918,'RIMGGE02009','GORRA GENERICA 3 ESTRELLAS','RIMGGE02009.jpg','68', '1'),"..
		"(2919,'RIMGGE02118','GORRA GENERICA 3 ESTRELLAS','RIMGGE02118.jpg','68', '1'),"..
		"(2920,'RIMGGE02229','GORRA GENERICA COMBINACION','RIMGGE02229.jpg','68', '1'),"..
		"(2921,'RIMGGE02311','GORRA GENERICA COMBINACION','RIMGGE02311.jpg','68', '1'),"..
		"(2922,'RIMGGE02513','GORRA GENERICA TIBURON BUCEO','RIMGGE02513.jpg','68', '1'),"..
		"(2923,'RIMGGE02611','GORRA GENERICA TIBURON BUCEO','RIMGGE02611.jpg','68', '1'),"..
		"(2924,'RIMGMBARC04','GORRA ARCOIRIS','RIMGMBARC04.jpg','68', '1'),"..
		"(2925,'RIMGMBARC18','GORRA ARCOIRIS','RIMGMBARC18.jpg','68', '1'),"..
		"(2926,'RIMGMBARC29','GORRA ARCOIRIS','RIMGMBARC29.jpg','68', '1'),"..
		"(2927,'RIMGMBARC37','GORRA ARCOIRIS','RIMGMBARC37.jpg','68', '1'),"..
		"(2928,'RIMGMBBAS04','GORRA BASICA','RIMGMBBAS04.jpg','43', '1'),"..
		"(2929,'RIMGMBBAS05','GORRA BASICA','RIMGMBBAS05.jpg','43', '1'),"..
		"(2930,'RIMGMBBAS11','GORRA BASICA','RIMGMBBAS11.jpg','43', '1'),"..
		"(2931,'RIMGMBBAS12','GORRA BASICA','RIMGMBBAS12.jpg','43', '1'),"..
		"(2932,'RIMGMBBAS28','GORRA BASICA','RIMGMBBAS28.jpg','43', '1'),"..
		"(2933,'RIMGMBBAS30','GORRA BASICA RIVIERA','RIMGMBBAS30.jpg','43', '1'),"..
		"(2934,'RIMGMBBAS03','GORRA BASICA RIVIERA','RIMGMBBAS03.jpg','43', '1'),"..
		"(2935,'RIMGMBBAS71','GORRA BASICA RIVIERA','RIMGMBBAS71.jpg','43', '1'),"..
		"(2936,'RIMGMBBAS17','GORRA BASICA RIVIERA','RIMGMBBAS17.jpg','43', '1'),"..
		"(2937,'RIMGMBBAS13','GORRA BASICA RIVIERA','RIMGMBBAS13.jpg','43', '1'),"..
		"(2938,'RIMGMBBAS16','GORRA BASICA RIVIERA','RIMGMBBAS16.jpg','43', '1'),"..
		"(2939,'RIMGMBBAS74','GORRA BASICA RIVIERA','RIMGMBBAS74.jpg','43', '1'),"..
		"(2940,'RIMGMBBAS02','GORRA BASICA RIVIERA','RIMGMBBAS02.jpg','43', '1'),"..
		"(2941,'RIMGMBBCA10','GORRA BASICA CAMBAS','RIMGMBBCA10.jpg','68', '1'),"..
		"(2942,'RIMGMBBCA12','GORRA BASICA CAMBAS','RIMGMBBCA12.jpg','68', '1'),"..
		"(2943,'RIMGMBCAM13','GORRA CAMBAS','RIMGMBCAM13.jpg','68', '1'),"..
		"(2944,'RIMGMBCAM26','GORRA CAMBAS','RIMGMBCAM26.jpg','68', '1'),"..
		"(2945,'RIMGMBCAM32','GORRA CAMBAS','RIMGMBCAM32.jpg','68', '1'),"..
		"(2946,'RIMGMBCAZ09','GORRA CAZADOR','RIMGMBCAZ09.jpg','76', '1'),"..
		"(2947,'RIMGMBCAZ11','GORRA CAZADOR','RIMGMBCAZ11.jpg','76', '1'),"..
		"(2948,'RIMGMBCAZ30','GORRA CAZADOR','RIMGMBCAZ30.jpg','76', '1'),"..
		"(2949,'RIMGMBDAM04','GORRA DAMA','RIMGMBDAM04.jpg','63', '1'),"..
		"(2950,'RIMGMBDAM12','GORRA DAMA','RIMGMBDAM12.jpg','63', '1'),"..
		"(2951,'RIMGMBDAM17','GORRA DAMA','RIMGMBDAM17.jpg','63', '1'),"..
		"(2952,'RIMGMBDAM18','GORRA DAMA','RIMGMBDAM18.jpg','63', '1'),"..
		"(2953,'RIMGMBDAM19','GORRA DAMA','RIMGMBDAM19.jpg','63', '1'),"..
		"(2954,'RIMGMBDAM23','GORRA DAMA','RIMGMBDAM23.jpg','63', '1'),"..
		"(2955,'RIMGMBDAM29','GORRA DAMA','RIMGMBDAM29.jpg','63', '1'),"..
		"(2956,'RIMGMBDAM40','GORRA DAMA','RIMGMBDAM40.jpg','63', '1'),"..
		"(2957,'RIMGMBDAM41','GORRA DAMA','RIMGMBDAM41.jpg','63', '1'),"..
		"(2958,'RIMGMBDAM42','GORRA DAMA','RIMGMBDAM42.jpg','63', '1'),"..
		"(2959,'RIMGMBDES02','GORRA DESLAVADA','RIMGMBDES02.jpg','63', '1'),"..
		"(2960,'RIMGMBDES04','GORRA DESLAVADA','RIMGMBDES04.jpg','63', '1'),"..
		"(2961,'RIMGMBDES05','GORRA DESLAVADA','RIMGMBDES05.jpg','63', '1'),"..
		"(2962,'RIMGMBDES06','GORRA DESLAVADA','RIMGMBDES06.jpg','63', '1'),"..
		"(2963,'RIMGMBDES09','GORRA DESLAVADA','RIMGMBDES09.jpg','63', '1'),"..
		"(2964,'RIMGMBDES10','GORRA DESLAVADA','RIMGMBDES10.jpg','63', '1'),"..
		"(2965,'RIMGMBDES11','GORRA DESLAVADA','RIMGMBDES11.jpg','63', '1'),"..
		"(2966,'RIMGMBDES12','GORRA DESLAVADA','RIMGMBDES12.jpg','63', '1'),"..
		"(2967,'RIMGMBDES13','GORRA DESLAVADA','RIMGMBDES13.jpg','63', '1'),"..
		"(2968,'RIMGMBDES15','GORRA DESLAVADA','RIMGMBDES15.jpg','63', '1'),"..
		"(2969,'RIMGMBDES16','GORRA DESLAVADA','RIMGMBDES16.jpg','63', '1'),"..
		"(2970,'RIMGMBDES17','GORRA DESLAVADA','RIMGMBDES17.jpg','63', '1'),"..
		"(2971,'RIMGMBDES21','GORRA DESLAVADA','RIMGMBDES21.jpg','63', '1'),"..
		"(2972,'RIMGMBDES25','GORRA DESLAVADA','RIMGMBDES25.jpg','63', '1'),"..
		"(2973,'RIMGMBDES26','GORRA DESLAVADA','RIMGMBDES26.jpg','63', '1'),"..
		"(2974,'RIMGMBDES28','GORRA DESLAVADA','RIMGMBDES28.jpg','63', '1'),"..
		"(2975,'RIMGMBDES29','GORRA DESLAVADA','RIMGMBDES29.jpg','63', '1'),"..
		"(2976,'RIMGMBDES30','GORRA DESLAVADA','RIMGMBDES30.jpg','63', '1'),"..
		"(2977,'RIMGMBDES31','GORRA DESLAVADA','RIMGMBDES31.jpg','63', '1'),"..
		"(2978,'RIMGMBDES32','GORRA DESLAVADA','RIMGMBDES32.jpg','63', '1'),"..
		"(2979,'RIMGMBDES34','GORRA DESLAVADA','RIMGMBDES34.jpg','63', '1'),"..
		"(2980,'RIMGMBDES35','GORRA DESLAVADA','RIMGMBDES35.jpg','63', '1'),"..
		"(2981,'RIMGMBDES37','GORRA DESLAVADA','RIMGMBDES37.jpg','63', '1'),"..
		"(2982,'RIMGMBDES68','GORRA DESLAVADA','RIMGMBDES68.jpg','63', '1'),"..
		"(2983,'RIMGMBDES74','GORRA DESLAVADA','RIMGMBDES74.jpg','63', '1'),"..
		"(2984,'RIMGMBFCU17','GORRA FIDEL CUADRO','RIMGMBFCU17.jpg','76', '1'),"..
		"(2985,'RIMGMBFCU40','GORRA FIDEL CUADRO','RIMGMBFCU40.jpg','76', '1'),"..
		"(2986,'RIMGMBFID11','GORRA FIDEL MILITAR','RIMGMBFID11.jpg','76', '1'),"..
		"(2987,'RIMGMBFID13','GORRA FIDEL MILITAR','RIMGMBFID13.jpg','76', '1'),"..
		"(2988,'RIMGMBFID17','GORRA FIDEL MILITAR','RIMGMBFID17.jpg','76', '1'),"..
		"(2989,'RIMGMBFID28','GORRA FIDEL MILITAR','RIMGMBFID28.jpg','76', '1'),"..
		"(2990,'RIMGMBFID29','GORRA FIDEL MILITAR','RIMGMBFID29.jpg','76', '1'),"..
		"(2991,'RIMGMBFID30','GORRA FIDEL MILITAR','RIMGMBFID30.jpg','76', '1'),"..
		"(2992,'RIMGMBFID37','GORRA FIDEL MILITAR','RIMGMBFID37.jpg','76', '1'),"..
		"(2993,'RIMGMBFID40','GORRA FIDEL MILITAR','RIMGMBFID40.jpg','76', '1'),"..
		"(2994,'RIMGMBFID66','GORRA FIDEL MILITAR','RIMGMBFID66.jpg','76', '1'),"..
		"(2995,'RIMGMBFID71','GORRA FIDEL MILITAR','RIMGMBFID71.jpg','76', '1'),"..
		"(2996,'RIMGMBNIÑ02','GORRA DESLAVADA NIÑO','RIMGMBNIÑ02.jpg','63', '1'),"..
		"(2997,'RIMGMBNIÑ10','GORRA DESLAVADA NIÑO','RIMGMBNIÑ10.jpg','63', '1'),"..
		"(2998,'RIMGMBNIÑ11','GORRA DESLAVADA NIÑO','RIMGMBNIÑ11.jpg','63', '1'),"..
		"(2999,'RIMGMBNIÑ12','GORRA DESLAVADA NIÑO','RIMGMBNIÑ12.jpg','63', '1'),"..
		"(3000,'RIMGMBNIÑ15','GORRA DESLAVADA NIÑO','RIMGMBNIÑ15.jpg','63', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(3001,'RIMGMBNIÑ26','GORRA DESLAVADA NIÑO','RIMGMBNIÑ26.jpg','63', '1'),"..
		"(3002,'RIMGMBNMA62','GORRA NIÑA MARIPOSA','RIMGMBNMA62.jpg','68', '1'),"..
		"(3003,'RIMGMBNMA63','GORRA NIÑA MARIPOSA','RIMGMBNMA63.jpg','68', '1'),"..
		"(3004,'RIMGMBNMA64','GORRA NIÑA MARIPOSA','RIMGMBNMA64.jpg','68', '1'),"..
		"(3005,'RIMGMBNMA65','GORRA NIÑA MARIPOSA','RIMGMBNMA65.jpg','68', '1'),"..
		"(3006,'RIMGMBOXF02','GORRA OXFORD','RIMGMBOXF02.jpg','68', '1'),"..
		"(3007,'RIMGMBOXF11','GORRA OXFORD','RIMGMBOXF11.jpg','68', '1'),"..
		"(3008,'RIMGMBOXF13','GORRA OXFORD','RIMGMBOXF13.jpg','68', '1'),"..
		"(3009,'RIMGMBOXF28','GORRA OXFORD','RIMGMBOXF28.jpg','68', '1'),"..
		"(3010,'RIMGMBOXF30','GORRA OXFORD','RIMGMBOXF30.jpg','68', '1'),"..
		"(3011,'RIMGMBOXF31','GORRA OXFORD','RIMGMBOXF31.jpg','68', '1'),"..
		"(3012,'RIMGMBOXF37','GORRA OXFORD','RIMGMBOXF37.jpg','68', '1'),"..
		"(3013,'RIMGMBPES02','GORRA PESPUNTE','RIMGMBPES02.jpg','68', '1'),"..
		"(3014,'RIMGMBPES11','GORRA PESPUNTE','RIMGMBPES11.jpg','68', '1'),"..
		"(3015,'RIMGMBPES13','GORRA PESPUNTE','RIMGMBPES13.jpg','68', '1'),"..
		"(3016,'RIMGMBPES28','GORRA PESPUNTE','RIMGMBPES28.jpg','68', '1'),"..
		"(3017,'RIMGMBPES31','GORRA PESPUNTE','RIMGMBPES31.jpg','68', '1'),"..
		"(3018,'RIMGMBRAU11','GORRA RAUL','RIMGMBRAU11.jpg','76', '1'),"..
		"(3019,'RIMGMBRAU13','GORRA RAUL','RIMGMBRAU13.jpg','76', '1'),"..
		"(3020,'RIMGMBRAU28','GORRA RAUL','RIMGMBRAU28.jpg','76', '1'),"..
		"(3021,'RIMGMBRAU29','GORRA RAUL','RIMGMBRAU29.jpg','76', '1'),"..
		"(3022,'RIMGMBRAU30','GORRA RAUL','RIMGMBRAU30.jpg','76', '1'),"..
		"(3023,'RIMGMBRAU31','GORRA RAUL','RIMGMBRAU31.jpg','76', '1'),"..
		"(3024,'RIMGMBRAU66','GORRA RAUL','RIMGMBRAU66.jpg','76', '1'),"..
		"(3025,'RIMGMBSAF03','GORRA SAFARI','RIMGMBSAF03.jpg','76', '1'),"..
		"(3026,'RIMGMBSAF28','GORRA SAFARI','RIMGMBSAF28.jpg','76', '1'),"..
		"(3027,'RIMGMBSAF30','GORRA SAFARI','RIMGMBSAF30.jpg','76', '1'),"..
		"(3028,'RIMGMBSAN02','GORRA SANDWICH','RIMGMBSAN02.jpg','68', '1'),"..
		"(3029,'RIMGMBSAN03','GORRA SANDWICH','RIMGMBSAN03.jpg','68', '1'),"..
		"(3030,'RIMGMBSAN04','GORRA SANDWICH','RIMGMBSAN04.jpg','68', '1'),"..
		"(3031,'RIMGMBSAN05','GORRA SANDWICH','RIMGMBSAN05.jpg','68', '1'),"..
		"(3032,'RIMGMBSAN07','GORRA SANDWICH','RIMGMBSAN07.jpg','68', '1'),"..
		"(3033,'RIMGMBSAN11','GORRA SANDWICH','RIMGMBSAN11.jpg','68', '1'),"..
		"(3034,'RIMGMBSAN13','GORRA SANDWICH','RIMGMBSAN13.jpg','68', '1'),"..
		"(3035,'RIMGMBSAN20','GORRA SANDWICH','RIMGMBSAN20.jpg','68', '1'),"..
		"(3036,'RIMGMBSAN22','GORRA SANDWICH','RIMGMBSAN22.jpg','68', '1'),"..
		"(3037,'RIMGMBSAN30','GORRA SANDWICH','RIMGMBSAN30.jpg','68', '1'),"..
		"(3038,'RIMGMBSAN32','GORRA SANDWICH','RIMGMBSAN32.jpg','68', '1'),"..
		"(3039,'RIMGMBSAN33','GORRA SANDWICH','RIMGMBSAN33.jpg','68', '1'),"..
		"(3040,'RIMGMBSAN36','GORRA SANDWICH','RIMGMBSAN36.jpg','68', '1'),"..
		"(3041,'RIMGMBSAN39','GORRA SANDWICH','RIMGMBSAN39.jpg','68', '1'),"..
		"(3042,'RIMGMBSAN43','GORRA SANDWICH','RIMGMBSAN43.jpg','68', '1'),"..
		"(3043,'RIMGMBSAN45','GORRA SANDWICH','RIMGMBSAN45.jpg','68', '1'),"..
		"(3044,'RIMGMBSAN47','GORRA SANDWICH','RIMGMBSAN47.jpg','68', '1'),"..
		"(3045,'RIMGMBSAN49','GORRA SANDWICH','RIMGMBSAN49.jpg','68', '1'),"..
		"(3046,'RIMGMBSAN51','GORRA SANDWICH','RIMGMBSAN51.jpg','68', '1'),"..
		"(3047,'RIMGMBSAN83','GORRA SANDWICH','RIMGMBSAN83.jpg','68', '1'),"..
		"(3048,'RIMGMBVIN202','GORRA VINTAGE','RIMGMBVIN202.jpg','68', '1'),"..
		"(3049,'RIMGMBVIN203','GORRA VINTAGE','RIMGMBVIN203.jpg','68', '1'),"..
		"(3050,'RIMGMBVIN208','GORRA VINTAGE','RIMGMBVIN208.jpg','68', '1'),"..
		"(3051,'RIMGMBVIN209','GORRA VINTAGE','RIMGMBVIN209.jpg','68', '1'),"..
		"(3052,'RIMGMBVIN211','GORRA VINTAGE','RIMGMBVIN211.jpg','68', '1'),"..
		"(3053,'RIMGMBVIN212','GORRA VINTAGE','RIMGMBVIN212.jpg','68', '1'),"..
		"(3054,'RIMGMBVIN213','GORRA VINTAGE','RIMGMBVIN213.jpg','68', '1'),"..
		"(3055,'RIMGMBVIN215','GORRA VINTAGE','RIMGMBVIN215.jpg','68', '1'),"..
		"(3056,'RIMGMBVIN216','GORRA VINTAGE','RIMGMBVIN216.jpg','68', '1'),"..
		"(3057,'RIMGMBVIN226','GORRA VINTAGE','RIMGMBVIN226.jpg','68', '1'),"..
		"(3058,'RIMGMBVIN228','GORRA VINTAGE','RIMGMBVIN228.jpg','68', '1'),"..
		"(3059,'RIMGMBVIN229','GORRA VINTAGE','RIMGMBVIN229.jpg','68', '1'),"..
		"(3060,'RIMGMBVIN230','GORRA VINTAGE','RIMGMBVIN230.jpg','68', '1'),"..
		"(3061,'RIMGMBVIN231','GORRA VINTAGE','RIMGMBVIN231.jpg','68', '1'),"..
		"(3062,'RIMGMBVIN237','GORRA VINTAGE','RIMGMBVIN237.jpg','68', '1'),"..
		"(3063,'RIMGMBVIN269','GORRA VINTAGE','RIMGMBVIN269.jpg','68', '1'),"..
		"(3064,'RIMGMBVIN270','GORRA VINTAGE','RIMGMBVIN270.jpg','68', '1'),"..
		"(3065,'RIMGMBVIN272','GORRA VINTAGE','RIMGMBVIN272.jpg','68', '1'),"..
		"(3066,'RIMGMBVIN302','GORRA DESLAVADA','RIMGMBVIN302.jpg','63', '1'),"..
		"(3067,'RIMGMBVIN303','GORRA DESLAVADA','RIMGMBVIN303.jpg','63', '1'),"..
		"(3068,'RIMGMBVIN305','GORRA DESLAVADA','RIMGMBVIN305.jpg','63', '1'),"..
		"(3069,'RIMGMBVIN306','GORRA DESLAVADA','RIMGMBVIN306.jpg','63', '1'),"..
		"(3070,'RIMGMBVIN309','GORRA DESLAVADA','RIMGMBVIN309.jpg','63', '1'),"..
		"(3071,'RIMGMBVIN310','GORRA DESLAVADA','RIMGMBVIN310.jpg','63', '1'),"..
		"(3072,'RIMGMBVIN311','GORRA DESLAVADA','RIMGMBVIN311.jpg','63', '1'),"..
		"(3073,'RIMGMBVIN312','GORRA DESLAVADA','RIMGMBVIN312.jpg','63', '1'),"..
		"(3074,'RIMGMBVIN313','GORRA DESLAVADA','RIMGMBVIN313.jpg','63', '1'),"..
		"(3075,'RIMGMBVIN314','GORRA DESLAVADA','RIMGMBVIN314.jpg','63', '1'),"..
		"(3076,'RIMGMBVIN315','GORRA DESLAVADA','RIMGMBVIN315.jpg','63', '1'),"..
		"(3077,'RIMGMBVIN316','GORRA DESLAVADA','RIMGMBVIN316.jpg','63', '1'),"..
		"(3078,'RIMGMBVIN321','GORRA DESLAVADA','RIMGMBVIN321.jpg','63', '1'),"..
		"(3079,'RIMGMBVIN325','GORRA DESLAVADA','RIMGMBVIN325.jpg','63', '1'),"..
		"(3080,'RIMGMBVIN326','GORRA DESLAVADA','RIMGMBVIN326.jpg','63', '1'),"..
		"(3081,'RIMGMBVIN328','GORRA DESLAVADA','RIMGMBVIN328.jpg','63', '1'),"..
		"(3082,'RIMGMBVIN329','GORRA DESLAVADA','RIMGMBVIN329.jpg','63', '1'),"..
		"(3083,'RIMGMBVIN330','GORRA DESLAVADA','RIMGMBVIN330.jpg','63', '1'),"..
		"(3084,'RIMGMBVIN331','GORRA DESLAVADA','RIMGMBVIN331.jpg','63', '1'),"..
		"(3085,'RIMGMBVIN332','GORRA DESLAVADA','RIMGMBVIN332.jpg','63', '1'),"..
		"(3086,'RIMGMBVIN334','GORRA DESLAVADA','RIMGMBVIN334.jpg','63', '1'),"..
		"(3087,'RIMGMBVIN335','GORRA DESLAVADA','RIMGMBVIN335.jpg','63', '1'),"..
		"(3088,'RIMGMBVIN337','GORRA DESLAVADA','RIMGMBVIN337.jpg','63', '1'),"..
		"(3089,'RIMGMBVIN368','GORRA DESLAVADA','RIMGMBVIN368.jpg','63', '1'),"..
		"(3090,'RIMGMBVIN403','GORRA VINTAGE','RIMGMBVIN403.jpg','68', '1'),"..
		"(3091,'RIMGMBVIN452','GORRA VINTAGE','RIMGMBVIN452.jpg','68', '1'),"..
		"(3092,'RIMGMBVIN457','GORRA VINTAGE','RIMGMBVIN457.jpg','68', '1'),"..
		"(3093,'RIMGMBVIT02','GORRA VINTAGE','RIMGMBVIT02.jpg','68', '1'),"..
		"(3094,'RIMGMBVIT03','GORRA VINTAGE','RIMGMBVIT03.jpg','68', '1'),"..
		"(3095,'RIMGMBVIT08','GORRA VINTAGE','RIMGMBVIT08.jpg','68', '1'),"..
		"(3096,'RIMGMBVIT09','GORRA VINTAGE','RIMGMBVIT09.jpg','68', '1'),"..
		"(3097,'RIMGMBVIT11','GORRA VINTAGE','RIMGMBVIT11.jpg','68', '1'),"..
		"(3098,'RIMGMBVIT12','GORRA VINTAGE','RIMGMBVIT12.jpg','68', '1'),"..
		"(3099,'RIMGMBVIT13','GORRA VINTAGE','RIMGMBVIT13.jpg','68', '1'),"..
		"(3100,'RIMGMBVIT15','GORRA VINTAGE','RIMGMBVIT15.jpg','68', '1'),"..
		"(3101,'RIMGMBVIT16','GORRA VINTAGE','RIMGMBVIT16.jpg','68', '1'),"..
		"(3102,'RIMGMBVIT17','GORRA VINTAGE','RIMGMBVIT17.jpg','68', '1'),"..
		"(3103,'RIMGMBVIT18','GORRA VINTAGE','RIMGMBVIT18.jpg','68', '1'),"..
		"(3104,'RIMGMBVIT26','GORRA VINTAGE','RIMGMBVIT26.jpg','68', '1'),"..
		"(3105,'RIMGMBVIT28','GORRA VINTAGE','RIMGMBVIT28.jpg','68', '1'),"..
		"(3106,'RIMGMBVIT29','GORRA VINTAGE','RIMGMBVIT29.jpg','68', '1'),"..
		"(3107,'RIMGMBVIT30','GORRA VINTAGE','RIMGMBVIT30.jpg','68', '1'),"..
		"(3108,'RIMGMBVIT31','GORRA VINTAGE','RIMGMBVIT31.jpg','68', '1'),"..
		"(3109,'RIMGMBVIT32','GORRA VINTAGE','RIMGMBVIT32.jpg','68', '1'),"..
		"(3110,'RIMGMBVIT37','GORRA VINTAGE','RIMGMBVIT37.jpg','68', '1'),"..
		"(3111,'RIMGMBVIT40','GORRA VINTAGE','RIMGMBVIT40.jpg','68', '1'),"..
		"(3112,'RIMGMBVIT69','GORRA VINTAGE','RIMGMBVIT69.jpg','68', '1'),"..
		"(3113,'RIMGMBVIT70','GORRA VINTAGE','RIMGMBVIT70.jpg','68', '1'),"..
		"(3114,'RIMGMBVIT71','GORRA VINTAGE','RIMGMBVIT71.jpg','68', '1'),"..
		"(3115,'RIMGMBVIT72','GORRA VINTAGE','RIMGMBVIT72.jpg','68', '1'),"..
		"(3116,'RIMGMBVIT73','GORRA VINTAGE','RIMGMBVIT73.jpg','68', '1'),"..
		"(3117,'RIMGMBVIT86','GORRA VINTAGE','RIMGMBVIT86.jpg','68', '1'),"..
		"(3118,'RIMGMBVIT87','GORRA VINTAGE','RIMGMBVIT87.jpg','68', '1'),"..
		"(3119,'RIMPAB0009','PLAYERA ADULTO SOL PANAMA','RIMPAB0009.jpg','70', '1'),"..
		"(3120,'RIMPAB001','PLAYERA ADULTO BORDADA SURF','RIMPAB001.jpg','70', '1'),"..
		"(3121,'RIMPAB002','PLAYERA ADULTO BORDADA PALMERAS 70','RIMPAB002.jpg','70', '1'),"..
		"(3122,'RIMPAB003','PLAYERA ADULTO BORDADA DIVE DEEP','RIMPAB003.jpg','70', '1'),"..
		"(3123,'RIMPAB073','PLAYERA ADULTO 3 DELFINES BRINCANDO','RIMPAB073.jpg','70', '1'),"..
		"(3124,'RIMPAB105','PLAYERA ADULTO MARGARITAS','RIMPAB105.jpg','70', '1'),"..
		"(3125,'RIMPAB379','PLAYERA ADULTO DELFIN RECTANGULO 2','RIMPAB379.jpg','70', '1'),"..
		"(3126,'RIMPAB490','PLAYERA ADULTO PALMERA MEXICO','RIMPAB490.jpg','70', '1'),"..
		"(3127,'RIMPAB491','PLAYERA ADULTO TORTUGA NADANDO','RIMPAB491.jpg','70', '1'),"..
		"(3128,'RIMPAB492','PLAYERA ADULTO 2 GEKOS','RIMPAB492.jpg','70', '1'),"..
		"(3129,'RIMPAB493','PLAYERA ADULTO LETRAS FLORES','RIMPAB493.jpg','70', '1'),"..
		"(3130,'RIMPAB494','PLAYERA ADULTO 2 PALMERAS MX','RIMPAB494.jpg','70', '1'),"..
		"(3131,'RIMPAB495','PLAYERA ADULTO GEKO HUELLAS','RIMPAB495.jpg','70', '1'),"..
		"(3132,'RIMPAI040','PLAYERA ADULTO IGUANA FLOC','RIMPAI040.jpg','65', '1'),"..
		"(3133,'RIMPAI041','PLAYERA ADULTO GEKO OJON','RIMPAI041.jpg','65', '1'),"..
		"(3134,'RIMPAI042','PLAYERA ADULTO IGUANA GRECAS','RIMPAI042.jpg','65', '1'),"..
		"(3135,'RIMPAI043','PLAYERA ADULTO IGUANA FOIL','RIMPAI043.jpg','65', '1'),"..
		"(3136,'RIMPAI044','PLAYERA ADULTO 2 TORTUGAS CIRCULO','RIMPAI044.jpg','65', '1'),"..
		"(3137,'RIMPAI045','PLAYERA ADULTO 2 GECOS CIRCULO FOIL','RIMPAI045.jpg','65', '1'),"..
		"(3138,'RIMPAJ001','PLAYERA ADULTO PREMIER TORTUGA CASCADA NEGRO','RIMPAJ001.jpg','65', '1'),"..
		"(3139,'RIMPAJ002','PLAYERA ADULTO PREMIER TIBURON DIVE','RIMPAJ002.jpg','65', '1'),"..
		"(3140,'RIMPAJ003','PLAYERA ADULTO PREMIER 7 TIBURONES','RIMPAJ003.jpg','65', '1'),"..
		"(3141,'RIMPAJ004','PLAYERA ADULTO PREMIER GEKO CASCADA','RIMPAJ004.jpg','65', '1'),"..
		"(3142,'RIMPAJ011','PLAYERA AD PREMIER 2 GEKOS FLOK','RIMPAJ011.jpg','68', '1'),"..
		"(3143,'RIMPAJ011XXL','PLAYERA AD PREMIER 2 GEKOS FLOK','RIMPAJ011XXL.jpg','68', '1'),"..
		"(3144,'RIMPAJ012','PLAYERA AD PREMIER DELFIN FLORES','RIMPAJ012.jpg','68', '1'),"..
		"(3145,'RIMPAJ012XXL','PLAYERA AD PREMIER DELFIN FLORES','RIMPAJ012XXL.jpg','68', '1'),"..
		"(3146,'RIMPAJ013','PLAYERA AD PREMIER TIBURON RETRO','RIMPAJ013.jpg','68', '1'),"..
		"(3147,'RIMPAJ013XXL','PLAYERA AD PREMIER TIBURON RETRO','RIMPAJ013XXL.jpg','68', '1'),"..
		"(3148,'RIMPAJ014','PLAYERA AD PREMIER TORTUGA DIVE','RIMPAJ014.jpg','68', '1'),"..
		"(3149,'RIMPAJ014XXL','PLAYERA AD PREMIER TORTUGA DIVE','RIMPAJ014XXL.jpg','68', '1'),"..
		"(3150,'RIMPAJ015','PLAYERA AD PREMIER TORTUGA GREKAS','RIMPAJ015.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(3151,'RIMPAJ015XXL','PLAYERA AD PREMIER TORTUGA GREKAS','RIMPAJ015XXL.jpg','68', '1'),"..
		"(3152,'RIMPAO02011','PL AD OIL V ESCUDO GUIRNALDAS MARINO','RIMPAO02011.jpg','85', '1'),"..
		"(3153,'RIMPAO02116','PL AD OIL V MX SOMBRAS ROJO','RIMPAO02116.jpg','85', '1'),"..
		"(3154,'RIMPAO02213','PL AD OIL V SELLO VERTICAL NEGRO','RIMPAO02213.jpg','85', '1'),"..
		"(3155,'RIMPAU00113','PLAYERA ADULTO ULTRA V COLEGIAL NEGRO','RIMPAU00113.jpg','72', '1'),"..
		"(3156,'RIMPAU00211','PLAYERA ADULTO ULTRA V TIBURON CUADRO MARINO','RIMPAU00211.jpg','72', '1'),"..
		"(3157,'RIMPAU00309','PLAYERA ADULTO ULTRA V TIBURON ROMBO GRIS','RIMPAU00309.jpg','72', '1'),"..
		"(3158,'RIMPAU00416','PLAYERA ADULTO ULTRA V 3 PALMERAS ROJO','RIMPAU00416.jpg','72', '1'),"..
		"(3159,'RIMPAU00503','PLAYERA ADULTO ULTRA V ATHLETIC BLANCO','RIMPAU00503.jpg','72', '1'),"..
		"(3160,'RIMPDO02378','PL DA OIL V 3 CORAZONES SINCE AQUA','RIMPDO02378.jpg','85', '1'),"..
		"(3161,'RIMPDO02429','PL DA OIL V FLORES 70 ROSA','RIMPDO02429.jpg','85', '1'),"..
		"(3162,'RIMPDO02504','PL DA OIL V LOVE PARCHE CELESTE','RIMPDO02504.jpg','85', '1'),"..
		"(3163,'RIMPDU00171','PLAYERA DAMA ULTRA V 2 PALMERAS FIUSHA','RIMPDU00171.jpg','72', '1'),"..
		"(3164,'RIMPDU00217','PLAYERA DAMA ULTRA V EVERY DAY LIMON','RIMPDU00217.jpg','72', '1'),"..
		"(3165,'RIMPDU00378','PLAYERA DAMA ULTRA V LOVE CORAZON AQUA','RIMPDU00378.jpg','72', '1'),"..
		"(3166,'RIMPDU00413','PLAYERA DAMA ULTRA V RELAX NEGRO','RIMPDU00413.jpg','72', '1'),"..
		"(3167,'RIMPDU00503','PLAYERA DAMA ULTRA V DESTINO PINCEL BLANCO','RIMPDU00503.jpg','72', '1'),"..
		"(3168,'RIMPNB073','PLAYERA NIÑO BORDADA 3 DELFINES BRINCANDO','RIMPNB073.jpg','61', '1'),"..
		"(3169,'RIMPNB411','PLAYERA NIÑO BORDADA MARIPOSAS','RIMPNB411.jpg','61', '1'),"..
		"(3170,'RIMPNB465','PLAYERA NIÑO BORDADA 5 FLORES SMILE','RIMPNB465.jpg','61', '1'),"..
		"(3171,'RIMPNB470','PLAYERA NIÑO BORDADA CHANCLAS','RIMPNB470.jpg','61', '1'),"..
		"(3172,'RIMPNB480','PLAYERA NIÑO IGUANA SURF','RIMPNB480.jpg','61', '1'),"..
		"(3173,'RIMPNB481','PLAYERA NIÑO 2 GEKOS OJONES','RIMPNB481.jpg','61', '1'),"..
		"(3174,'RIMPNB482','PLAYERA NIÑO TORTUGA FLORES','RIMPNB482.jpg','61', '1'),"..
		"(3175,'RIMPNB483','PLAYERA NIÑO 3 DELFINES FLORES','RIMPNB483.jpg','61', '1'),"..
		"(3176,'RIMPNI050','PLAYERA NIÑO 2 GECOS RECTANGULO','RIMPNI050.jpg','59', '1'),"..
		"(3177,'RIMPNI051','PLAYERA NIÑO 4 TORTUGAS','RIMPNI051.jpg','59', '1'),"..
		"(3178,'RIMPNI052','PLAYERA NIÑO 3 TIBURONES SOMBRAS','RIMPNI052.jpg','59', '1'),"..
		"(3179,'RIMPNI053','PLAYERA NIÑO 3 TORTUGAS NADANDO','RIMPNI053.jpg','59', '1'),"..
		"(3180,'RIMPNI054','PLAYERA NIÑO GEKO PATON','RIMPNI054.jpg','59', '1'),"..
		"(3181,'RIMPNI055','PLAYERA NIÑO GEKO DOBLE CIRCULO','RIMPNI055.jpg','59', '1'),"..
		"(3182,'RIMPNI056','PLAYERA NIÑO PLAY HOOKY','RIMPNI056.jpg','59', '1'),"..
		"(3183,'RIMPNJ005','PLAYERA NIÑO PREMIER TORTUGA SELLO','RIMPNJ005.jpg','59', '1'),"..
		"(3184,'RIMPNJ006','PLAYERA NIÑO PREMIER TENIS GLITER ROSA','RIMPNJ006.jpg','59', '1'),"..
		"(3185,'RIMPNJ007','PLAYERA NIÑO PREMIER BANDERA PIRATA ROYAL','RIMPNJ007.jpg','59', '1'),"..
		"(3186,'RIMPNJ008','PLAYERA NIÑO PREMIER 2 DLFINES PALMERAS','RIMPNJ008.jpg','59', '1'),"..
		"(3187,'RIMPNJ009','PLAYERA NIÑO PREMIER GEKO MAYA','RIMPNJ009.jpg','59', '1'),"..
		"(3188,'RIMPNJ010','PLAYERA NIÑO PREMIER CALACA SURF','RIMPNJ010.jpg','59', '1'),"..
		"(3189,'RIMSAB00109','SUDADERA ADULTO CAPUCHA','RIMSAB00109.jpg','170', '1'),"..
		"(3190,'RIMSAB00111','SUDADERA ADULTO CAPUCHA','RIMSAB00111.jpg','170', '1'),"..
		"(3191,'RIMSAB00113','SUDADERA ADULTO CAPUCHA','RIMSAB00113.jpg','170', '1'),"..
		"(3192,'RIMSAB00117','SUDADERA ADULTO CAPUCHA','RIMSAB00117.jpg','170', '1'),"..
		"(3193,'RIMSAB00138','SUDADERA ADULTO CAPUCHA','RIMSAB00138.jpg','170', '1'),"..
		"(3194,'RIMSAB00140','SUDADERA ADULTO CAPUCHA','RIMSAB00140.jpg','170', '1'),"..
		"(3195,'RIMSAB00171','SUDADERA ADULTO CAPUCHA','RIMSAB00171.jpg','170', '1'),"..
		"(3196,'RIMSAB001XXL09','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL09.jpg','170', '1'),"..
		"(3197,'RIMSAB001XXL11','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL11.jpg','170', '1'),"..
		"(3198,'RIMSAB001XXL13','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL13.jpg','170', '1'),"..
		"(3199,'RIMSAB001XXL17','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL17.jpg','170', '1'),"..
		"(3200,'RIMSAB001XXL29','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL29.jpg','170', '1'),"..
		"(3201,'RIMSAB001XXL38','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL38.jpg','170', '1'),"..
		"(3202,'RIMSAB001XXL40','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL40.jpg','170', '1'),"..
		"(3203,'RIMSAB001XXL71','SUDADERA ADULTO CAPUCHA','RIMSAB001XXL71.jpg','170', '1'),"..
		"(3204,'RIMSMBGUI03','SOMBRERO GUILLIGAN','RIMSMBGUI03.jpg','73', '1'),"..
		"(3205,'RIMSMBGUI10','SOMBRERO GUILLIGAN','RIMSMBGUI10.jpg','73', '1'),"..
		"(3206,'RIMSMBGUI11','SOMBRERO GUILLIGAN','RIMSMBGUI11.jpg','73', '1'),"..
		"(3207,'RIMSMBGUI12','SOMBRERO GUILLIGAN','RIMSMBGUI12.jpg','73', '1'),"..
		"(3208,'RIMSMBGUI13','SOMBRERO GUILLIGAN','RIMSMBGUI13.jpg','73', '1'),"..
		"(3209,'RIMSMBGUI28','SOMBRERO GUILLIGAN','RIMSMBGUI28.jpg','73', '1'),"..
		"(3210,'RIMSMBGUI30','SOMBRERO GUILLIGAN','RIMSMBGUI30.jpg','73', '1'),"..
		"(3211,'RIMSNB00109','SUDADERA IMPORTACION NIÑO','RIMSNB00109.jpg','140', '1'),"..
		"(3212,'RIMSNB00111','SUDADERA IMPORTACION NIÑO','RIMSNB00111.jpg','140', '1'),"..
		"(3213,'RIMSNB00113','SUDADERA IMPORTACION NIÑO','RIMSNB00113.jpg','140', '1'),"..
		"(3214,'RIMVCOV0303','VICERA PIEDRITAS','RIMVCOV0303.jpg','62', '1'),"..
		"(3215,'RIMVCOV0304','VICERA PIEDRITAS','RIMVCOV0304.jpg','62', '1'),"..
		"(3216,'RIMVCOV0311','VICERA PIEDRITAS','RIMVCOV0311.jpg','62', '1'),"..
		"(3217,'RIMVCOV0313','VICERA PIEDRITAS','RIMVCOV0313.jpg','62', '1'),"..
		"(3218,'RIMVCOV0316','VICERA PIEDRITAS','RIMVCOV0316.jpg','62', '1'),"..
		"(3219,'RIMVCOV0329','VICERA PIEDRITAS','RIMVCOV0329.jpg','62', '1'),"..
		"(3220,'RIMVCOV0330','VICERA PIEDRITAS','RIMVCOV0330.jpg','62', '1'),"..
		"(3221,'RIMVCOV0337','VICERA PIEDRITAS','RIMVCOV0337.jpg','62', '1'),"..
		"(3222,'RIMVIBSAN03','VICERA SANDWICH','RIMVIBSAN03.jpg','62', '1'),"..
		"(3223,'RIMVIBSAN04','VICERA SANDWICH','RIMVIBSAN04.jpg','62', '1'),"..
		"(3224,'RIMVIBSAN11','VICERA SANDWICH','RIMVIBSAN11.jpg','62', '1'),"..
		"(3225,'RIMVIBSAN13','VICERA SANDWICH','RIMVIBSAN13.jpg','62', '1'),"..
		"(3226,'RIMVIBSAN16','VICERA SANDWICH','RIMVIBSAN16.jpg','62', '1'),"..
		"(3227,'RIMVIBSAN29','VICERA SANDWICH','RIMVIBSAN29.jpg','62', '1'),"..
		"(3228,'RIMVIBSAN30','VICERA SANDWICH','RIMVIBSAN30.jpg','62', '1'),"..
		"(3229,'RIMVIBSAN37','VICERA SANDWICH','RIMVIBSAN37.jpg','62', '1'),"..
		"(3230,'RIPGMBDES02','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES02.jpg','63', '1'),"..
		"(3231,'RIPGMBDES04','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES04.jpg','63', '1'),"..
		"(3232,'RIPGMBDES05','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES05.jpg','63', '1'),"..
		"(3233,'RIPGMBDES06','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES06.jpg','63', '1'),"..
		"(3234,'RIPGMBDES09','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES09.jpg','63', '1'),"..
		"(3235,'RIPGMBDES10','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES10.jpg','63', '1'),"..
		"(3236,'RIPGMBDES11','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES11.jpg','63', '1'),"..
		"(3237,'RIPGMBDES12','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES12.jpg','63', '1'),"..
		"(3238,'RIPGMBDES13','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES13.jpg','63', '1'),"..
		"(3239,'RIPGMBDES15','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES15.jpg','63', '1'),"..
		"(3240,'RIPGMBDES16','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES16.jpg','63', '1'),"..
		"(3241,'RIPGMBDES17','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES17.jpg','63', '1'),"..
		"(3242,'RIPGMBDES21','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES21.jpg','63', '1'),"..
		"(3243,'RIPGMBDES25','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES25.jpg','63', '1'),"..
		"(3244,'RIPGMBDES26','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES26.jpg','63', '1'),"..
		"(3245,'RIPGMBDES28','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES28.jpg','63', '1'),"..
		"(3246,'RIPGMBDES29','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES29.jpg','63', '1'),"..
		"(3247,'RIPGMBDES30','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES30.jpg','63', '1'),"..
		"(3248,'RIPGMBDES31','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES31.jpg','63', '1'),"..
		"(3249,'RIPGMBDES32','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES32.jpg','63', '1'),"..
		"(3250,'RIPGMBDES34','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES34.jpg','63', '1'),"..
		"(3251,'RIPGMBDES35','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES35.jpg','63', '1'),"..
		"(3252,'RIPGMBDES37','GORRA DESLAVADA RIU PLAYA DEL CARMEN','RIPGMBDES37.jpg','63', '1'),"..
		"(3253,'RIPGMBSAN02','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN02.jpg','68', '1'),"..
		"(3254,'RIPGMBSAN03','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN03.jpg','68', '1'),"..
		"(3255,'RIPGMBSAN04','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN04.jpg','68', '1'),"..
		"(3256,'RIPGMBSAN05','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN05.jpg','68', '1'),"..
		"(3257,'RIPGMBSAN07','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN07.jpg','68', '1'),"..
		"(3258,'RIPGMBSAN11','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN11.jpg','68', '1'),"..
		"(3259,'RIPGMBSAN13','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN13.jpg','68', '1'),"..
		"(3260,'RIPGMBSAN20','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN20.jpg','68', '1'),"..
		"(3261,'RIPGMBSAN22','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN22.jpg','68', '1'),"..
		"(3262,'RIPGMBSAN30','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN30.jpg','68', '1'),"..
		"(3263,'RIPGMBSAN32','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN32.jpg','68', '1'),"..
		"(3264,'RIPGMBSAN33','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN33.jpg','68', '1'),"..
		"(3265,'RIPGMBSAN36','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN36.jpg','68', '1'),"..
		"(3266,'RIPGMBSAN39','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN39.jpg','68', '1'),"..
		"(3267,'RIPGMBSAN43','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN43.jpg','68', '1'),"..
		"(3268,'RIPGMBSAN45','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN45.jpg','68', '1'),"..
		"(3269,'RIPGMBSAN47','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN47.jpg','68', '1'),"..
		"(3270,'RIPGMBSAN49','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN49.jpg','68', '1'),"..
		"(3271,'RIPGMBSAN51','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN51.jpg','68', '1'),"..
		"(3272,'RIPGMBSAN83','GORRA SANDWICH LOGO RIU PLAYA DEL CARMEN','RIPGMBSAN83.jpg','68', '1'),"..
		"(3273,'ROYGMBDES04','GORRA DESLAVADA ROYAL','ROYGMBDES04.jpg','63', '1'),"..
		"(3274,'ROYGMBDES05','GORRA DESLAVADA ROYAL','ROYGMBDES05.jpg','63', '1'),"..
		"(3275,'ROYGMBDES06','GORRA DESLAVADA ROYAL','ROYGMBDES06.jpg','63', '1'),"..
		"(3276,'ROYGMBDES10','GORRA DESLAVADA ROYAL','ROYGMBDES10.jpg','63', '1'),"..
		"(3277,'ROYGMBDES11','GORRA DESLAVADA ROYAL','ROYGMBDES11.jpg','63', '1'),"..
		"(3278,'ROYGMBDES12','GORRA DESLAVADA ROYAL','ROYGMBDES12.jpg','63', '1'),"..
		"(3279,'ROYGMBDES13','GORRA DESLAVADA ROYAL','ROYGMBDES13.jpg','63', '1'),"..
		"(3280,'ROYGMBDES15','GORRA DESLAVADA ROYAL','ROYGMBDES15.jpg','63', '1'),"..
		"(3281,'ROYGMBDES16','GORRA DESLAVADA ROYAL','ROYGMBDES16.jpg','63', '1'),"..
		"(3282,'ROYGMBDES21','GORRA DESLAVADA ROYAL','ROYGMBDES21.jpg','63', '1'),"..
		"(3283,'ROYGMBDES25','GORRA DESLAVADA ROYAL','ROYGMBDES25.jpg','63', '1'),"..
		"(3284,'ROYGMBDES26','GORRA DESLAVADA ROYAL','ROYGMBDES26.jpg','63', '1'),"..
		"(3285,'ROYGMBDES28','GORRA DESLAVADA ROYAL','ROYGMBDES28.jpg','63', '1'),"..
		"(3286,'ROYGMBDES30','GORRA DESLAVADA ROYAL','ROYGMBDES30.jpg','63', '1'),"..
		"(3287,'ROYGMBDES32','GORRA DESLAVADA ROYAL','ROYGMBDES32.jpg','63', '1'),"..
		"(3288,'ROYGMBDES34','GORRA DESLAVADA ROYAL','ROYGMBDES34.jpg','63', '1'),"..
		"(3289,'ROYGMBDES35','GORRA DESLAVADA ROYAL','ROYGMBDES35.jpg','63', '1'),"..
		"(3290,'ROYGMBDES37','GORRA DESLAVADA ROYAL','ROYGMBDES37.jpg','63', '1'),"..
		"(3291,'ROYGMBSAN02','GORRA SANDWICH ROYAL','ROYGMBSAN02.jpg','68', '1'),"..
		"(3292,'ROYGMBSAN03','GORRA SANDWICH ROYAL','ROYGMBSAN03.jpg','68', '1'),"..
		"(3293,'ROYGMBSAN05','GORRA SANDWICH ROYAL','ROYGMBSAN05.jpg','68', '1'),"..
		"(3294,'ROYGMBSAN06','GORRA SANDWICH ROYAL','ROYGMBSAN06.jpg','68', '1'),"..
		"(3295,'ROYGMBSAN07','GORRA SANDWICH ROYAL','ROYGMBSAN07.jpg','68', '1'),"..
		"(3296,'ROYGMBSAN11','GORRA SANDWICH ROYAL','ROYGMBSAN11.jpg','68', '1'),"..
		"(3297,'ROYGMBSAN13','GORRA SANDWICH ROYAL','ROYGMBSAN13.jpg','68', '1'),"..
		"(3298,'ROYGMBSAN20','GORRA SANDWICH ROYAL','ROYGMBSAN20.jpg','68', '1'),"..
		"(3299,'ROYGMBSAN22','GORRA SANDWICH ROYAL','ROYGMBSAN22.jpg','68', '1'),"..
		"(3300,'ROYGMBSAN30','GORRA SANDWICH ROYAL','ROYGMBSAN30.jpg','68', '1')";
		db:exec (query)

		query = "INSERT INTO catalogo (id, sku, descripcion, imagen, costo, activo) VALUES"..
		"(3301,'ROYGMBSAN32','GORRA SANDWICH ROYAL','ROYGMBSAN32.jpg','68', '1'),"..
		"(3302,'ROYGMBSAN33','GORRA SANDWICH ROYAL','ROYGMBSAN33.jpg','68', '1'),"..
		"(3303,'ROYGMBSAN36','GORRA SANDWICH ROYAL','ROYGMBSAN36.jpg','68', '1'),"..
		"(3304,'ROYGMBSAN39','GORRA SANDWICH ROYAL','ROYGMBSAN39.jpg','68', '1'),"..
		"(3305,'ROYGMBSAN43','GORRA SANDWICH ROYAL','ROYGMBSAN43.jpg','68', '1'),"..
		"(3306,'ROYGMBSAN45','GORRA SANDWICH ROYAL','ROYGMBSAN45.jpg','68', '1'),"..
		"(3307,'ROYGMBSAN49','GORRA SANDWICH ROYAL','ROYGMBSAN49.jpg','68', '1'),"..
		"(3308,'ROYGMBSAN51','GORRA SANDWICH ROYAL','ROYGMBSAN51.jpg','68', '1'),"..
		"(3309,'VIPCOA00102','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00102.jpg','99', '1'),"..
		"(3310,'VIPCOA00105','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00105.jpg','99', '1'),"..
		"(3311,'VIPCOA00106','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00106.jpg','99', '1'),"..
		"(3312,'VIPCOA00110','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00110.jpg','99', '1'),"..
		"(3313,'VIPCOA00111','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00111.jpg','99', '1'),"..
		"(3314,'VIPCOA00112','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00112.jpg','99', '1'),"..
		"(3315,'VIPCOA00113','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00113.jpg','99', '1'),"..
		"(3316,'VIPCOA00115','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00115.jpg','99', '1'),"..
		"(3317,'VIPCOA00121','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00121.jpg','99', '1'),"..
		"(3318,'VIPCOA00125','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00125.jpg','99', '1'),"..
		"(3319,'VIPCOA00126','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00126.jpg','99', '1'),"..
		"(3320,'VIPCOA00128','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00128.jpg','99', '1'),"..
		"(3321,'VIPCOA00130','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00130.jpg','99', '1'),"..
		"(3322,'VIPCOA00132','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00132.jpg','99', '1'),"..
		"(3323,'VIPCOA00134','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00134.jpg','99', '1'),"..
		"(3324,'VIPCOA00135','COMBO ADULTO VILLA DEL PALMAR','VIPCOA00135.jpg','99', '1'),"..
		"(3325,'VIPCOA001XXL02','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL02.jpg','110', '1'),"..
		"(3326,'VIPCOA001XXL05','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL05.jpg','110', '1'),"..
		"(3327,'VIPCOA001XXL06','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL06.jpg','110', '1'),"..
		"(3328,'VIPCOA001XXL10','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL10.jpg','110', '1'),"..
		"(3329,'VIPCOA001XXL11','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL11.jpg','110', '1'),"..
		"(3330,'VIPCOA001XXL12','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL12.jpg','110', '1'),"..
		"(3331,'VIPCOA001XXL13','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL13.jpg','110', '1'),"..
		"(3332,'VIPCOA001XXL15','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL15.jpg','110', '1'),"..
		"(3333,'VIPCOA001XXL21','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL21.jpg','110', '1'),"..
		"(3334,'VIPCOA001XXL25','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL25.jpg','110', '1'),"..
		"(3335,'VIPCOA001XXL26','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL26.jpg','110', '1'),"..
		"(3336,'VIPCOA001XXL28','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL28.jpg','110', '1'),"..
		"(3337,'VIPCOA001XXL30','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL30.jpg','110', '1'),"..
		"(3338,'VIPCOA001XXL32','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL32.jpg','110', '1'),"..
		"(3339,'VIPCOA001XXL34','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL34.jpg','110', '1'),"..
		"(3340,'VIPCOA001XXL35','COMBO ADULTO VILLA DEL PALMAR','VIPCOA001XXL35.jpg','110', '1'),"..
		"(3341,'VIPVIBSAN03','VICERA SANDWICH','VIPVIBSAN03.jpg','62', '1'),"..
		"(3342,'VIPVIBSAN04','VICERA SANDWICH','VIPVIBSAN04.jpg','62', '1'),"..
		"(3343,'VIPVIBSAN11','VICERA SANDWICH','VIPVIBSAN11.jpg','62', '1'),"..
		"(3344,'VIPVIBSAN13','VICERA SANDWICH','VIPVIBSAN13.jpg','62', '1'),"..
		"(3345,'VIPVIBSAN16','VICERA SANDWICH','VIPVIBSAN16.jpg','62', '1'),"..
		"(3346,'VIPVIBSAN29','VICERA SANDWICH','VIPVIBSAN29.jpg','62', '1'),"..
		"(3347,'VIPVIBSAN30','VICERA SANDWICH','VIPVIBSAN30.jpg','62', '1'),"..
		"(3348,'VIPVIBSAN37','VICERA SANDWICH','VIPVIBSAN37.jpg','62', '1')";
		db:exec (query)

		query = "update catalogo set tipo = 't' where sku = trim('4810103001    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030019   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103002    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030029   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103003    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030039   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103004    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030049   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103005    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030059   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103006    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030069   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103007    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030079   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103008    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030089   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103009    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030099   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103010    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030109   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103011    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030119   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103012    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030129   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103013    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030139   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103014    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030149   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103015    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030159   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103016    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030169   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103017    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030179   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103018    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030189   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103019    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030199   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103020    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030209   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103021    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030219   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103022    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030229   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103023    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030239   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103024    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030249   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103025    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030259   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103026    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030269   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103027    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030279   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103028    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030289   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103029    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030299   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103030    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030309   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103031    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030319   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103032    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030329   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103033    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030339   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103034    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030349   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103035    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030359   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103036    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030369   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103037    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030379   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103038    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030389   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103039    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030399   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103040    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030409   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103041    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030419   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103042    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030429   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103043    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030439   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103044    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103045    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030459   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103046    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030469   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103047    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030479   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103048    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030489   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103049    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030499   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103050    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030509   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103051    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030519   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103065    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030659   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103066    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030669   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103067    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030679   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103074    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030749   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103075    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030759   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103076    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030769   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103077    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030779   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103078    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030789   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103079    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030799   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103080    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030809   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103081    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030819   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103082    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030829   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103083    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030839   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103084    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101030849   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103101    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103101E   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103102    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103102E   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103104    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103104E   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103106    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103106E   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103108    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103108E   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103109    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103109E   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810103494    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48101034949   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203011    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203012    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203014    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203016    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203039    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203041    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203042    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203043    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203044    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203046    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203047    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203048    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203049    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203050    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203051    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203052    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203088    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203089    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203090    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203091    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203092    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203093    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203094    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203095    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203096    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810203097    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303019    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303020    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303021    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303054    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303055    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303056    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303057    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303058    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303060    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303061    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303062    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303063    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303064    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303068    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303069    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303085    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303086    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303098    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303101    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303102    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303106    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810303107    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810703001    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48107030019   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810703002    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48107030029   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810703003    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48107030039   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4810703004    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48107030049   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203070    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203071    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203072    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('48142030730   ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203101    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203102    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203103    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('4814203105    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCN00112');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCN00213    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCN00315 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCN004U    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCNXXL00112 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCNXXL00213 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCNXXL00315 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TCNXXL004U ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRM00112');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRM00213    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRM00315 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRM004U    ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRMXX004LU ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRMXXL00112 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRMXXL00213 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA250TRMXXL00315 ');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00173');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00324');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00417');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00624');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00810');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN00912');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01009');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01108');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01308');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01528');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01812');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN01911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02013');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02224');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02509');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02510');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02712');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02828');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN02913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03037');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03328');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03803');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN03903');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04103');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04203');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04303');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04713');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04811');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN04916');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCN05024');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00173');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00324');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00417');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00624');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00810');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL00912');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01009');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01108');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01308');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01528');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01812');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL01911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02013');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02224');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02509');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02510');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02712');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02828');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL02913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03037');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03328');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03803');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL03903');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL04003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL04103');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL04203');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL04303');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL04403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TCNXXL04503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00173');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00324');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00417');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00624');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00810');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM00912');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01009');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01108');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01308');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01528');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01812');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM01911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02013');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02103');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02224');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02509');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02510');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02712');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02828');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM02913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03037');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03328');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03803');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM03903');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04103');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04203');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04303');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04713');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04811');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM04916');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRM05024');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00173');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00324');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00417');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00624');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00810');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL00912');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01009');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01108');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01308');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01528');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01812');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL01911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02013');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02224');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02509');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02510');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02712');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02828');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL02913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03037');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03213');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03328');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03803');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL03903');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL04003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL04103');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL04203');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL04303');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL04403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA300TRMXXL04503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCN00109');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCN00216');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCN00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCN00413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCN00503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCNXXL00109');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCNXXL00216');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCNXXL00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCNXXL00413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TCNXXL00503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRM00109');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRM00216');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRM00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRM00413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRM00503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRMXXL00109');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRMXXL00216');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRMXXL00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRMXXL00413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PA310TRMXXL00503');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TCN001U');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TCN00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TCN00374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TCN00415');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TCN00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TRM001U');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TRM00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TRM00374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TRM00415');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD250TRM00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00117');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00171');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00471');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00617');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00903');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN00911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01013');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01018');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01113');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01171');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01318');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01329');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01471');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01540');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01611');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN01913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02137');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02218');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02313');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02418');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02474');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN02529');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TCN07771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00171');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM00911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01318');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01471');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01540');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01611');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM01913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02137');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02218');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02313');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02418');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02474');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM02529');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PD300TRM07771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00117');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00171');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00471');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00617');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00874');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00903');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN00911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01013');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01018');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01113');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01171');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01318');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01329');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01471');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01540');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01611');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN01913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02137');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02218');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02313');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02418');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02474');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN02529');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN10118');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN10271');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN10311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TCN10474');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00171');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00211');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00311');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00403');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00613');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM00911');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01111');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01318');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01413');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01471');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01513');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01540');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01603');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01611');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01703');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01875');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM01913');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02003');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02071');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02137');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02218');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02229');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02313');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02374');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02418');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02474');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM02529');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM09771');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PDJ300TRM098Q');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00173');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00417');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00511');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00616');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00810');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN00912');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01011');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01113');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01216');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01303');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01411');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TCN01473');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00173');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00212');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00417');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00511');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00616');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00711');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00810');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM00912');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01011');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01113');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01216');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01303');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01309');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01310');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01411');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM01473');" db:exec( query )
		query = "update catalogo set tipo = 't' where sku = trim('PN300TRM08973');" db:exec( query )







		--llenar con los datos de las tallas
		query2 = "INSERT INTO talla VALUES " .. 
        "(1, 'XS'), "..
		"(2, 'S'), " .. 
		"(3, 'M'), " .. 
		"(4, 'L'), " .. 
		"(5, 'XL'), " .. 
		"(6, 'XXL'), " .. 
		"(7, 'XXXL'), " .. 
		"(8, 'UNI'); " 

		db:exec( query2 )

		--linea
			query = "INSERT INTO linea (nombre, clave) VALUES " .. 
			"('PLAYERA ADULTO','01')," ..
			"('PLAYERA NIÑO','02')," ..
			"('PLAYERA DAMA 300','03')," ..
			"('SUDADERA IMPORTACION','06')," ..
			"('PLAYERA 310','07')," ..
			"('TANK TOP','09')," ..
			"('BEBES','10')," ..
			"('GORRAS','11')," ..
			"('TANK TOP NIÑA','14')," ..
			"('COMBOS','15')," ..
			"('SOMBREROS','17')," ..
			"('VISERAS','18')," ..
			"('PLAYERA DESLAVADA','20')," ..
			"('TANK TOP DESLAVADA','21')," ..
			"('POLO NIÑO','33')," ..
			"('POLO ADULTO','34')," ..
			"('SHORTS CABALLERO','40')," ..
			"('PLAYERA SURF','41')," ..
			"('PLAYERA DAMA JUVENIL','42')," ..
			"('MODA US APPAREL','43')," ..
			"('ACCESORIOS','44')," ..
			"('PULCERAS','45')," ..
			"('SUDADERA MODA BASIX','47')," ..
			"('PLAYERA ADULTO GILDAN','48');"
			db:exec( query )
		--linea

		--sublinea
			query = "INSERT INTO sublinea (nombre, idlinea, clave) VALUES " ..
			"('BORDADA',1,'01')," ..
			"('ESTAMPADA',1,'02')," ..
			"('TRANSFER',1,'03')," ..
			"('PREMIER',1,'04')," ..
			"('CAVIAR',1,'06')," ..
			"('PIEDRITAS',1,'07')," ..
			"('LISO',1,'08')," ..
			"('BORDADA',2,'01')," ..
			"('ESTAMPADA',2,'02')," ..
			"('TRANSFER',2,'03')," ..
			"('PREMIER',2,'04')," ..
			"('CAVIAR',2,'06')," ..
			"('PIEDRITAS',2,'07')," ..
			"('LISO',2,'08')," ..
			"('BORDADA',3,'01')," ..
			"('ESTAMPADA',3,'02')," ..
			"('TRANSFER',3,'03')," ..
			"('PREMIER',3,'04')," ..
			"('CAVIAR',3,'06')," ..
			"('PIEDRITAS',3,'07')," ..
			"('LISO',3,'08')," ..
			"('BORDADA',4,'01')," ..
			"('LISO',4,'08')," ..
			"('ESTAMPADA',5,'02')," ..
			"('TRANSFER',5,'03')," ..
			"('PREMIER',5,'04')," ..
			"('LISO',5,'08')," ..
			"('ESTAMPADA',6,'02')," ..
			"('TRANSFER',6,'03')," ..
			"('PIEDRITAS',6,'07')," ..
			"('LISO',6,'08')," ..
			"('ESTAMPADA',7,'02')," ..
			"('TRANSFER',7,'03')," ..
			"('CAVIAR',7,'06')," ..
			"('LISO',7,'08')," ..
			"('LISO',8,'06')," ..
			"('RAUL',8,'65')," ..
			"('OXFORD',8,'66')," ..
			"('PESPUNTE',8,'67')," ..
			"('BASICA',8,'77')," ..
			"('FIDEL',8,'78')," ..
			"('ARCOIRIS',8,'79')," ..
			"('CAMBAS',8,'80')," ..
			"('NIÑO',8,'81')," ..
			"('DAMA',8,'82')," ..
			"('SANDWICH',8,'83')," ..
			"('DESLAVADA',8,'85')," ..
			"('GORRAS GENERICAS',8,'86')," ..
			"('GORRA BEBE DKPS',8,'87')," ..
			"('GORRA VINTAGE',8,'89')," ..
			"('GORRA 7667',8,'90')," ..
			"('GORRA 7692',8,'91')," ..
			"('CAVIAR',9,'06')," ..
			"('LISO',10,'08')," ..
			"('DAMA',10,'64')," ..
			"('NIÑO',10,'84')," ..
			"('DAMA',10,'85')," ..
			"('ADULTO',10,'86')," ..
			"('LISO',11,'08')," ..
			"('GUILLIGAN',11,'69')," ..
			"('LISO',12,'08')," ..
			"('SANDWICH',12,'68')," ..
			"('TRANSFERS',13,'03')," ..
			"('LISA',13,'08')," ..
			"('DIVERSOS',13,'01')," ..
			"('TRANSFERS',14,'03')," ..
			"('LISA',14,'08')," ..
			"('BORDADO',15,'01')," ..
			"('ESTAMPADO',15,'02')," ..
			"('LISO',15,'08')," ..
			"('BORDADO',16,'01')," ..
			"('ESTAMPADO',16,'02')," ..
			"('LISO',16,'08')," ..
			"('LISO',17,'08')," ..
			"('LISO',18,'08')," ..
			"('TRANSFER',19,'03')," ..
			"('LISO',19,'08')," ..
			"('LISO',20,'08')," ..
			"('TELEFONICOS',21,'09')," ..
			"('ANTIMOSQUITOS',22,'10')," ..
			"('ESTAMPADA',23,'02')," ..
			"('LISA',23,'08')," ..
			"('LISA',24,'08');"
			db:exec( query )
		--sublinea

		--llenar con los datos de las tallas
		--[[query2 = "INSERT INTO refcatalogotalla VALUES " .. 
        "(1, '1', 2), "..
		"(2, '1', 3), " .. 
		"(3, '1', 4), " .. 
		"(4, '1', 5), " .. 
		"(5, '2', 2), " .. 
		"(6, '2', 2), " .. 
		"(7, '2', 4), " .. 
		"(8, '2', 5), " ..
		"(9, '3', 2), " ..
		"(10, '3', 3), " ..
		"(11, '3', 4), " ..
		"(12, '3', 5), " ..
		"(13, '4', 2), " ..
		"(14, '4', 3), " ..
		"(15, '4', 4), " ..
		"(16, '4', 5), " ..
		"(17, '5', 2), " ..
		"(18, '5', 3), " ..
		"(19, '5', 4), " ..
		"(20, '5', 5); "]]

		query2 = "INSERT INTO refcatalogotalla VALUES " ..
		"(1, (select id from catalogo where sku = '4810101009'), 2),"..
"(2, (select id from catalogo where sku = '4810101009'), 3),"..
"(3, (select id from catalogo where sku = '4810101009'), 4),"..
"(4, (select id from catalogo where sku = '4810101009'), 5),"..
"(5, (select id from catalogo where sku = '4810101073'), 2),"..
"(6, (select id from catalogo where sku = '4810101073'), 3),"..
"(7, (select id from catalogo where sku = '4810101073'), 4),"..
"(8, (select id from catalogo where sku = '4810101073'), 5),"..
"(9, (select id from catalogo where sku = '4810101105'), 2),"..
"(10, (select id from catalogo where sku = '4810101105'), 3),"..
"(11, (select id from catalogo where sku = '4810101105'), 4),"..
"(12, (select id from catalogo where sku = '4810101105'), 5),"..
"(13, (select id from catalogo where sku = '4810101382'), 2),"..
"(14, (select id from catalogo where sku = '4810101382'), 3),"..
"(15, (select id from catalogo where sku = '4810101382'), 4),"..
"(16, (select id from catalogo where sku = '4810101382'), 5),"..
"(17, (select id from catalogo where sku = '4810101459'), 2),"..
"(18, (select id from catalogo where sku = '4810101459'), 3),"..
"(19, (select id from catalogo where sku = '4810101459'), 4),"..
"(20, (select id from catalogo where sku = '4810101459'), 5),"..
"(21, (select id from catalogo where sku = '4810101470'), 2),"..
"(22, (select id from catalogo where sku = '4810101470'), 3),"..
"(23, (select id from catalogo where sku = '4810101470'), 4),"..
"(24, (select id from catalogo where sku = '4810101470'), 5),"..
"(25, (select id from catalogo where sku = '4810101485'), 2),"..
"(26, (select id from catalogo where sku = '4810101485'), 3),"..
"(27, (select id from catalogo where sku = '4810101485'), 4),"..
"(28, (select id from catalogo where sku = '4810101485'), 5),"..
"(29, (select id from catalogo where sku = '4810101486'), 2),"..
"(30, (select id from catalogo where sku = '4810101486'), 3),"..
"(31, (select id from catalogo where sku = '4810101486'), 4),"..
"(32, (select id from catalogo where sku = '4810101486'), 5),"..
"(33, (select id from catalogo where sku = '4810101487'), 2),"..
"(34, (select id from catalogo where sku = '4810101487'), 3),"..
"(35, (select id from catalogo where sku = '4810101487'), 4),"..
"(36, (select id from catalogo where sku = '4810101487'), 5),"..
"(37, (select id from catalogo where sku = '4810101490'), 2),"..
"(38, (select id from catalogo where sku = '4810101490'), 3),"..
"(39, (select id from catalogo where sku = '4810101490'), 4),"..
"(40, (select id from catalogo where sku = '4810101490'), 5),"..
"(41, (select id from catalogo where sku = '4810101491'), 2),"..
"(42, (select id from catalogo where sku = '4810101491'), 3),"..
"(43, (select id from catalogo where sku = '4810101491'), 4),"..
"(44, (select id from catalogo where sku = '4810101491'), 5),"..
"(45, (select id from catalogo where sku = '4810101492'), 2),"..
"(46, (select id from catalogo where sku = '4810101492'), 3),"..
"(47, (select id from catalogo where sku = '4810101492'), 4),"..
"(48, (select id from catalogo where sku = '4810101492'), 5),"..
"(49, (select id from catalogo where sku = '4810101493'), 2),"..
"(50, (select id from catalogo where sku = '4810101493'), 3),"..
"(51, (select id from catalogo where sku = '4810101493'), 4),"..
"(52, (select id from catalogo where sku = '4810101493'), 5),"..
"(53, (select id from catalogo where sku = '4810101494'), 2),"..
"(54, (select id from catalogo where sku = '4810101494'), 3),"..
"(55, (select id from catalogo where sku = '4810101494'), 4),"..
"(56, (select id from catalogo where sku = '4810101494'), 5),"..
"(57, (select id from catalogo where sku = '4810101495'), 2),"..
"(58, (select id from catalogo where sku = '4810101495'), 3),"..
"(59, (select id from catalogo where sku = '4810101495'), 4),"..
"(60, (select id from catalogo where sku = '4810101495'), 5),"..
"(61, (select id from catalogo where sku = '4810102001'), 2),"..
"(62, (select id from catalogo where sku = '4810102001'), 3),"..
"(63, (select id from catalogo where sku = '4810102001'), 4),"..
"(64, (select id from catalogo where sku = '4810102001'), 5),"..
"(65, (select id from catalogo where sku = '4810102002'), 2),"..
"(66, (select id from catalogo where sku = '4810102002'), 3),"..
"(67, (select id from catalogo where sku = '4810102002'), 4),"..
"(68, (select id from catalogo where sku = '4810102002'), 5),"..
"(69, (select id from catalogo where sku = '4810102003'), 2),"..
"(70, (select id from catalogo where sku = '4810102003'), 3),"..
"(71, (select id from catalogo where sku = '4810102003'), 4),"..
"(72, (select id from catalogo where sku = '4810102003'), 5),"..
"(73, (select id from catalogo where sku = '4810102004'), 2),"..
"(74, (select id from catalogo where sku = '4810102004'), 3),"..
"(75, (select id from catalogo where sku = '4810102004'), 4),"..
"(76, (select id from catalogo where sku = '4810102004'), 5),"..
"(77, (select id from catalogo where sku = '4810102005'), 2),"..
"(78, (select id from catalogo where sku = '4810102005'), 3),"..
"(79, (select id from catalogo where sku = '4810102005'), 4),"..
"(80, (select id from catalogo where sku = '4810102005'), 5),"..
"(81, (select id from catalogo where sku = '4810102006'), 2),"..
"(82, (select id from catalogo where sku = '4810102006'), 3),"..
"(83, (select id from catalogo where sku = '4810102006'), 4),"..
"(84, (select id from catalogo where sku = '4810102006'), 5),"..
"(85, (select id from catalogo where sku = '4810103001'), 2),"..
"(86, (select id from catalogo where sku = '4810103001'), 3),"..
"(87, (select id from catalogo where sku = '4810103001'), 4),"..
"(88, (select id from catalogo where sku = '4810103001'), 5),"..
"(89, (select id from catalogo where sku = '48101030019'), 6),"..
"(90, (select id from catalogo where sku = '4810103002'), 2),"..
"(91, (select id from catalogo where sku = '4810103002'), 3),"..
"(92, (select id from catalogo where sku = '4810103002'), 4),"..
"(93, (select id from catalogo where sku = '4810103002'), 5),"..
"(94, (select id from catalogo where sku = '48101030029'), 6),"..
"(95, (select id from catalogo where sku = '4810103003'), 2),"..
"(96, (select id from catalogo where sku = '4810103003'), 3),"..
"(97, (select id from catalogo where sku = '4810103003'), 4),"..
"(98, (select id from catalogo where sku = '4810103003'), 5),"..
"(99, (select id from catalogo where sku = '48101030039'), 6),"..
"(100, (select id from catalogo where sku = '4810103004'), 2),"..
"(101, (select id from catalogo where sku = '4810103004'), 3),"..
"(102, (select id from catalogo where sku = '4810103004'), 4),"..
"(103, (select id from catalogo where sku = '4810103004'), 5),"..
"(104, (select id from catalogo where sku = '48101030049'), 6),"..
"(105, (select id from catalogo where sku = '4810103005'), 2),"..
"(106, (select id from catalogo where sku = '4810103005'), 3),"..
"(107, (select id from catalogo where sku = '4810103005'), 4),"..
"(108, (select id from catalogo where sku = '4810103005'), 5),"..
"(109, (select id from catalogo where sku = '48101030059'), 6),"..
"(110, (select id from catalogo where sku = '4810103006'), 2),"..
"(111, (select id from catalogo where sku = '4810103006'), 3),"..
"(112, (select id from catalogo where sku = '4810103006'), 4),"..
"(113, (select id from catalogo where sku = '4810103006'), 5),"..
"(114, (select id from catalogo where sku = '48101030069'), 6),"..
"(115, (select id from catalogo where sku = '4810103007'), 2),"..
"(116, (select id from catalogo where sku = '4810103007'), 3),"..
"(117, (select id from catalogo where sku = '4810103007'), 4),"..
"(118, (select id from catalogo where sku = '4810103007'), 5),"..
"(119, (select id from catalogo where sku = '48101030079'), 6),"..
"(120, (select id from catalogo where sku = '4810103008'), 2),"..
"(121, (select id from catalogo where sku = '4810103008'), 3),"..
"(122, (select id from catalogo where sku = '4810103008'), 4),"..
"(123, (select id from catalogo where sku = '4810103008'), 5),"..
"(124, (select id from catalogo where sku = '48101030089'), 6),"..
"(125, (select id from catalogo where sku = '4810103009'), 2),"..
"(126, (select id from catalogo where sku = '4810103009'), 3),"..
"(127, (select id from catalogo where sku = '4810103009'), 4),"..
"(128, (select id from catalogo where sku = '4810103009'), 5),"..
"(129, (select id from catalogo where sku = '48101030099'), 6),"..
"(130, (select id from catalogo where sku = '4810103010'), 2),"..
"(131, (select id from catalogo where sku = '4810103010'), 3),"..
"(132, (select id from catalogo where sku = '4810103010'), 4),"..
"(133, (select id from catalogo where sku = '4810103010'), 5),"..
"(134, (select id from catalogo where sku = '48101030109'), 6),"..
"(135, (select id from catalogo where sku = '4810103011'), 2),"..
"(136, (select id from catalogo where sku = '4810103011'), 3),"..
"(137, (select id from catalogo where sku = '4810103011'), 4),"..
"(138, (select id from catalogo where sku = '4810103011'), 5),"..
"(139, (select id from catalogo where sku = '48101030119'), 6),"..
"(140, (select id from catalogo where sku = '4810103012'), 2),"..
"(141, (select id from catalogo where sku = '4810103012'), 3),"..
"(142, (select id from catalogo where sku = '4810103012'), 4),"..
"(143, (select id from catalogo where sku = '4810103012'), 5),"..
"(144, (select id from catalogo where sku = '48101030129'), 6),"..
"(145, (select id from catalogo where sku = '4810103013'), 2),"..
"(146, (select id from catalogo where sku = '4810103013'), 3),"..
"(147, (select id from catalogo where sku = '4810103013'), 4),"..
"(148, (select id from catalogo where sku = '4810103013'), 5),"..
"(149, (select id from catalogo where sku = '48101030139'), 6),"..
"(150, (select id from catalogo where sku = '4810103014'), 2),"..
"(151, (select id from catalogo where sku = '4810103014'), 3);"
db:exec( query2 )
--fase 2
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(152, (select id from catalogo where sku = '4810103014'), 4),"..
"(153, (select id from catalogo where sku = '4810103014'), 5),"..
"(154, (select id from catalogo where sku = '48101030149'), 6),"..
"(155, (select id from catalogo where sku = '4810103015'), 2),"..
"(156, (select id from catalogo where sku = '4810103015'), 3),"..
"(157, (select id from catalogo where sku = '4810103015'), 4),"..
"(158, (select id from catalogo where sku = '4810103015'), 5),"..
"(159, (select id from catalogo where sku = '48101030159'), 6),"..
"(160, (select id from catalogo where sku = '4810103016'), 2),"..
"(161, (select id from catalogo where sku = '4810103016'), 3),"..
"(162, (select id from catalogo where sku = '4810103016'), 4),"..
"(163, (select id from catalogo where sku = '4810103016'), 5),"..
"(164, (select id from catalogo where sku = '48101030169'), 6),"..
"(165, (select id from catalogo where sku = '4810103017'), 2),"..
"(166, (select id from catalogo where sku = '4810103017'), 3),"..
"(167, (select id from catalogo where sku = '4810103017'), 4),"..
"(168, (select id from catalogo where sku = '4810103017'), 5),"..
"(169, (select id from catalogo where sku = '48101030179'), 6),"..
"(170, (select id from catalogo where sku = '4810103018'), 2),"..
"(171, (select id from catalogo where sku = '4810103018'), 3),"..
"(172, (select id from catalogo where sku = '4810103018'), 4),"..
"(173, (select id from catalogo where sku = '4810103018'), 5),"..
"(174, (select id from catalogo where sku = '48101030189'), 6),"..
"(175, (select id from catalogo where sku = '4810103019'), 2),"..
"(176, (select id from catalogo where sku = '4810103019'), 3),"..
"(177, (select id from catalogo where sku = '4810103019'), 4),"..
"(178, (select id from catalogo where sku = '4810103019'), 5),"..
"(179, (select id from catalogo where sku = '48101030199'), 6),"..
"(180, (select id from catalogo where sku = '4810103020'), 2),"..
"(181, (select id from catalogo where sku = '4810103020'), 3),"..
"(182, (select id from catalogo where sku = '4810103020'), 4),"..
"(183, (select id from catalogo where sku = '4810103020'), 5),"..
"(184, (select id from catalogo where sku = '48101030209'), 6),"..
"(185, (select id from catalogo where sku = '4810103021'), 2),"..
"(186, (select id from catalogo where sku = '4810103021'), 3),"..
"(187, (select id from catalogo where sku = '4810103021'), 4),"..
"(188, (select id from catalogo where sku = '4810103021'), 5),"..
"(189, (select id from catalogo where sku = '48101030219'), 6),"..
"(190, (select id from catalogo where sku = '4810103022'), 2),"..
"(191, (select id from catalogo where sku = '4810103022'), 3),"..
"(192, (select id from catalogo where sku = '4810103022'), 4),"..
"(193, (select id from catalogo where sku = '4810103022'), 5),"..
"(194, (select id from catalogo where sku = '48101030229'), 6),"..
"(195, (select id from catalogo where sku = '4810103023'), 2),"..
"(196, (select id from catalogo where sku = '4810103023'), 3),"..
"(197, (select id from catalogo where sku = '4810103023'), 4),"..
"(198, (select id from catalogo where sku = '4810103023'), 5),"..
"(199, (select id from catalogo where sku = '48101030239'), 6),"..
"(200, (select id from catalogo where sku = '4810103024'), 2),"..
"(201, (select id from catalogo where sku = '4810103024'), 3),"..
"(202, (select id from catalogo where sku = '4810103024'), 4),"..
"(203, (select id from catalogo where sku = '4810103024'), 5),"..
"(204, (select id from catalogo where sku = '48101030249'), 6),"..
"(205, (select id from catalogo where sku = '4810103025'), 2),"..
"(206, (select id from catalogo where sku = '4810103025'), 3),"..
"(207, (select id from catalogo where sku = '4810103025'), 4),"..
"(208, (select id from catalogo where sku = '4810103025'), 5),"..
"(209, (select id from catalogo where sku = '48101030259'), 6),"..
"(210, (select id from catalogo where sku = '4810103026'), 2),"..
"(211, (select id from catalogo where sku = '4810103026'), 3),"..
"(212, (select id from catalogo where sku = '4810103026'), 4),"..
"(213, (select id from catalogo where sku = '4810103026'), 5),"..
"(214, (select id from catalogo where sku = '48101030269'), 6),"..
"(215, (select id from catalogo where sku = '4810103027'), 2),"..
"(216, (select id from catalogo where sku = '4810103027'), 3),"..
"(217, (select id from catalogo where sku = '4810103027'), 4),"..
"(218, (select id from catalogo where sku = '4810103027'), 5),"..
"(219, (select id from catalogo where sku = '48101030279'), 6),"..
"(220, (select id from catalogo where sku = '4810103028'), 2),"..
"(221, (select id from catalogo where sku = '4810103028'), 3),"..
"(222, (select id from catalogo where sku = '4810103028'), 4),"..
"(223, (select id from catalogo where sku = '4810103028'), 5),"..
"(224, (select id from catalogo where sku = '48101030289'), 6),"..
"(225, (select id from catalogo where sku = '4810103029'), 2),"..
"(226, (select id from catalogo where sku = '4810103029'), 3),"..
"(227, (select id from catalogo where sku = '4810103029'), 4),"..
"(228, (select id from catalogo where sku = '4810103029'), 5),"..
"(229, (select id from catalogo where sku = '48101030299'), 6),"..
"(230, (select id from catalogo where sku = '4810103030'), 2),"..
"(231, (select id from catalogo where sku = '4810103030'), 3),"..
"(232, (select id from catalogo where sku = '4810103030'), 4),"..
"(233, (select id from catalogo where sku = '4810103030'), 5),"..
"(234, (select id from catalogo where sku = '48101030309'), 6),"..
"(235, (select id from catalogo where sku = '4810103031'), 2),"..
"(236, (select id from catalogo where sku = '4810103031'), 3),"..
"(237, (select id from catalogo where sku = '4810103031'), 4),"..
"(238, (select id from catalogo where sku = '4810103031'), 5),"..
"(239, (select id from catalogo where sku = '48101030319'), 6),"..
"(240, (select id from catalogo where sku = '4810103032'), 2),"..
"(241, (select id from catalogo where sku = '4810103032'), 3),"..
"(242, (select id from catalogo where sku = '4810103032'), 4),"..
"(243, (select id from catalogo where sku = '4810103032'), 5),"..
"(244, (select id from catalogo where sku = '48101030329'), 6),"..
"(245, (select id from catalogo where sku = '4810103033'), 2),"..
"(246, (select id from catalogo where sku = '4810103033'), 3),"..
"(247, (select id from catalogo where sku = '4810103033'), 4),"..
"(248, (select id from catalogo where sku = '4810103033'), 5),"..
"(249, (select id from catalogo where sku = '48101030339'), 6),"..
"(250, (select id from catalogo where sku = '4810103034'), 2),"..
"(251, (select id from catalogo where sku = '4810103034'), 3),"..
"(252, (select id from catalogo where sku = '4810103034'), 4),"..
"(253, (select id from catalogo where sku = '4810103034'), 5),"..
"(254, (select id from catalogo where sku = '48101030349'), 6),"..
"(255, (select id from catalogo where sku = '4810103035'), 2),"..
"(256, (select id from catalogo where sku = '4810103035'), 3),"..
"(257, (select id from catalogo where sku = '4810103035'), 4),"..
"(258, (select id from catalogo where sku = '4810103035'), 5),"..
"(259, (select id from catalogo where sku = '48101030359'), 6),"..
"(260, (select id from catalogo where sku = '4810103036'), 2),"..
"(261, (select id from catalogo where sku = '4810103036'), 3),"..
"(262, (select id from catalogo where sku = '4810103036'), 4),"..
"(263, (select id from catalogo where sku = '4810103036'), 5),"..
"(264, (select id from catalogo where sku = '48101030369'), 6),"..
"(265, (select id from catalogo where sku = '4810103037'), 2),"..
"(266, (select id from catalogo where sku = '4810103037'), 3),"..
"(267, (select id from catalogo where sku = '4810103037'), 4),"..
"(268, (select id from catalogo where sku = '4810103037'), 5),"..
"(269, (select id from catalogo where sku = '48101030379'), 6),"..
"(270, (select id from catalogo where sku = '4810103038'), 2),"..
"(271, (select id from catalogo where sku = '4810103038'), 3),"..
"(272, (select id from catalogo where sku = '4810103038'), 4),"..
"(273, (select id from catalogo where sku = '4810103038'), 5),"..
"(274, (select id from catalogo where sku = '48101030389'), 6),"..
"(275, (select id from catalogo where sku = '4810103039'), 2),"..
"(276, (select id from catalogo where sku = '4810103039'), 3),"..
"(277, (select id from catalogo where sku = '4810103039'), 4),"..
"(278, (select id from catalogo where sku = '4810103039'), 5),"..
"(279, (select id from catalogo where sku = '48101030399'), 6),"..
"(280, (select id from catalogo where sku = '4810103040'), 2),"..
"(281, (select id from catalogo where sku = '4810103040'), 3),"..
"(282, (select id from catalogo where sku = '4810103040'), 4),"..
"(283, (select id from catalogo where sku = '4810103040'), 5),"..
"(284, (select id from catalogo where sku = '48101030409'), 6),"..
"(285, (select id from catalogo where sku = '4810103041'), 2),"..
"(286, (select id from catalogo where sku = '4810103041'), 3),"..
"(287, (select id from catalogo where sku = '4810103041'), 4),"..
"(288, (select id from catalogo where sku = '4810103041'), 5),"..
"(289, (select id from catalogo where sku = '48101030419'), 6),"..
"(290, (select id from catalogo where sku = '4810103042'), 2),"..
"(291, (select id from catalogo where sku = '4810103042'), 3),"..
"(292, (select id from catalogo where sku = '4810103042'), 4),"..
"(293, (select id from catalogo where sku = '4810103042'), 5),"..
"(294, (select id from catalogo where sku = '48101030429'), 6),"..
"(295, (select id from catalogo where sku = '4810103043'), 2),"..
"(296, (select id from catalogo where sku = '4810103043'), 3),"..
"(297, (select id from catalogo where sku = '4810103043'), 4),"..
"(298, (select id from catalogo where sku = '4810103043'), 5),"..
"(299, (select id from catalogo where sku = '48101030439'), 6),"..
"(300, (select id from catalogo where sku = '4810103044'), 2),"..
"(301, (select id from catalogo where sku = '4810103044'), 3),"..
"(302, (select id from catalogo where sku = '4810103044'), 4);"
db:exec( query2 )
--fase 3
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(303, (select id from catalogo where sku = '4810103044'), 5),"..
"(304, (select id from catalogo where sku = '4810103045'), 2),"..
"(305, (select id from catalogo where sku = '4810103045'), 3),"..
"(306, (select id from catalogo where sku = '4810103045'), 4),"..
"(307, (select id from catalogo where sku = '4810103045'), 5),"..
"(308, (select id from catalogo where sku = '48101030459'), 6),"..
"(309, (select id from catalogo where sku = '4810103046'), 2),"..
"(310, (select id from catalogo where sku = '4810103046'), 3),"..
"(311, (select id from catalogo where sku = '4810103046'), 4),"..
"(312, (select id from catalogo where sku = '4810103046'), 5),"..
"(313, (select id from catalogo where sku = '48101030469'), 6),"..
"(314, (select id from catalogo where sku = '4810103047'), 2),"..
"(315, (select id from catalogo where sku = '4810103047'), 3),"..
"(316, (select id from catalogo where sku = '4810103047'), 4),"..
"(317, (select id from catalogo where sku = '4810103047'), 5),"..
"(318, (select id from catalogo where sku = '48101030479'), 6),"..
"(319, (select id from catalogo where sku = '4810103048'), 2),"..
"(320, (select id from catalogo where sku = '4810103048'), 3),"..
"(321, (select id from catalogo where sku = '4810103048'), 4),"..
"(322, (select id from catalogo where sku = '4810103048'), 5),"..
"(323, (select id from catalogo where sku = '48101030489'), 6),"..
"(324, (select id from catalogo where sku = '4810103049'), 2),"..
"(325, (select id from catalogo where sku = '4810103049'), 3),"..
"(326, (select id from catalogo where sku = '4810103049'), 4),"..
"(327, (select id from catalogo where sku = '4810103049'), 5),"..
"(328, (select id from catalogo where sku = '48101030499'), 6),"..
"(329, (select id from catalogo where sku = '4810103050'), 2),"..
"(330, (select id from catalogo where sku = '4810103050'), 3),"..
"(331, (select id from catalogo where sku = '4810103050'), 4),"..
"(332, (select id from catalogo where sku = '4810103050'), 5),"..
"(333, (select id from catalogo where sku = '48101030509'), 6),"..
"(334, (select id from catalogo where sku = '4810103051'), 2),"..
"(335, (select id from catalogo where sku = '4810103051'), 3),"..
"(336, (select id from catalogo where sku = '4810103051'), 4),"..
"(337, (select id from catalogo where sku = '4810103051'), 5),"..
"(338, (select id from catalogo where sku = '48101030519'), 6),"..
"(339, (select id from catalogo where sku = '4810103065'), 2),"..
"(340, (select id from catalogo where sku = '4810103065'), 3),"..
"(341, (select id from catalogo where sku = '4810103065'), 4),"..
"(342, (select id from catalogo where sku = '4810103065'), 5),"..
"(343, (select id from catalogo where sku = '48101030659'), 6),"..
"(344, (select id from catalogo where sku = '4810103066'), 2),"..
"(345, (select id from catalogo where sku = '4810103066'), 3),"..
"(346, (select id from catalogo where sku = '4810103066'), 4),"..
"(347, (select id from catalogo where sku = '4810103066'), 5),"..
"(348, (select id from catalogo where sku = '48101030669'), 6),"..
"(349, (select id from catalogo where sku = '4810103067'), 2),"..
"(350, (select id from catalogo where sku = '4810103067'), 3),"..
"(351, (select id from catalogo where sku = '4810103067'), 4),"..
"(352, (select id from catalogo where sku = '4810103067'), 5),"..
"(353, (select id from catalogo where sku = '48101030679'), 6),"..
"(354, (select id from catalogo where sku = '4810103074'), 2),"..
"(355, (select id from catalogo where sku = '4810103074'), 3),"..
"(356, (select id from catalogo where sku = '4810103074'), 4),"..
"(357, (select id from catalogo where sku = '4810103074'), 5),"..
"(358, (select id from catalogo where sku = '48101030749'), 6),"..
"(359, (select id from catalogo where sku = '4810103075'), 2),"..
"(360, (select id from catalogo where sku = '4810103075'), 3),"..
"(361, (select id from catalogo where sku = '4810103075'), 4),"..
"(362, (select id from catalogo where sku = '4810103075'), 5),"..
"(363, (select id from catalogo where sku = '48101030759'), 6),"..
"(364, (select id from catalogo where sku = '4810103076'), 2),"..
"(365, (select id from catalogo where sku = '4810103076'), 3),"..
"(366, (select id from catalogo where sku = '4810103076'), 4),"..
"(367, (select id from catalogo where sku = '4810103076'), 5),"..
"(368, (select id from catalogo where sku = '48101030769'), 6),"..
"(369, (select id from catalogo where sku = '4810103077'), 2),"..
"(370, (select id from catalogo where sku = '4810103077'), 3),"..
"(371, (select id from catalogo where sku = '4810103077'), 4),"..
"(372, (select id from catalogo where sku = '4810103077'), 5),"..
"(373, (select id from catalogo where sku = '48101030779'), 6),"..
"(374, (select id from catalogo where sku = '4810103078'), 2),"..
"(375, (select id from catalogo where sku = '4810103078'), 3),"..
"(376, (select id from catalogo where sku = '4810103078'), 4),"..
"(377, (select id from catalogo where sku = '4810103078'), 5),"..
"(378, (select id from catalogo where sku = '48101030789'), 6),"..
"(379, (select id from catalogo where sku = '4810103079'), 2),"..
"(380, (select id from catalogo where sku = '4810103079'), 3),"..
"(381, (select id from catalogo where sku = '4810103079'), 4),"..
"(382, (select id from catalogo where sku = '4810103079'), 5),"..
"(383, (select id from catalogo where sku = '48101030799'), 6),"..
"(384, (select id from catalogo where sku = '4810103080'), 2),"..
"(385, (select id from catalogo where sku = '4810103080'), 3),"..
"(386, (select id from catalogo where sku = '4810103080'), 4),"..
"(387, (select id from catalogo where sku = '4810103080'), 5),"..
"(388, (select id from catalogo where sku = '48101030809'), 6),"..
"(389, (select id from catalogo where sku = '4810103081'), 2),"..
"(390, (select id from catalogo where sku = '4810103081'), 3),"..
"(391, (select id from catalogo where sku = '4810103081'), 4),"..
"(392, (select id from catalogo where sku = '4810103081'), 5),"..
"(393, (select id from catalogo where sku = '48101030819'), 6),"..
"(394, (select id from catalogo where sku = '4810103082'), 2),"..
"(395, (select id from catalogo where sku = '4810103082'), 3),"..
"(396, (select id from catalogo where sku = '4810103082'), 4),"..
"(397, (select id from catalogo where sku = '4810103082'), 5),"..
"(398, (select id from catalogo where sku = '48101030829'), 6),"..
"(399, (select id from catalogo where sku = '4810103083'), 2),"..
"(400, (select id from catalogo where sku = '4810103083'), 3),"..
"(401, (select id from catalogo where sku = '4810103083'), 4),"..
"(402, (select id from catalogo where sku = '4810103083'), 5),"..
"(403, (select id from catalogo where sku = '48101030839'), 6),"..
"(404, (select id from catalogo where sku = '4810103084'), 2),"..
"(405, (select id from catalogo where sku = '4810103084'), 3),"..
"(406, (select id from catalogo where sku = '4810103084'), 4),"..
"(407, (select id from catalogo where sku = '4810103084'), 5),"..
"(408, (select id from catalogo where sku = '48101030849'), 6),"..
"(409, (select id from catalogo where sku = '4810103101'), 2),"..
"(410, (select id from catalogo where sku = '4810103101'), 3),"..
"(411, (select id from catalogo where sku = '4810103101'), 4),"..
"(412, (select id from catalogo where sku = '4810103101'), 5),"..
"(413, (select id from catalogo where sku = '4810103101E'), 6),"..
"(414, (select id from catalogo where sku = '4810103102'), 2),"..
"(415, (select id from catalogo where sku = '4810103102'), 3),"..
"(416, (select id from catalogo where sku = '4810103102'), 4),"..
"(417, (select id from catalogo where sku = '4810103102'), 5),"..
"(418, (select id from catalogo where sku = '4810103104'), 2),"..
"(419, (select id from catalogo where sku = '4810103104'), 3),"..
"(420, (select id from catalogo where sku = '4810103104'), 4),"..
"(421, (select id from catalogo where sku = '4810103104'), 5),"..
"(422, (select id from catalogo where sku = '4810103104E   '), 6),"..
"(423, (select id from catalogo where sku = '4810103106'), 2),"..
"(424, (select id from catalogo where sku = '4810103106'), 3),"..
"(425, (select id from catalogo where sku = '4810103106'), 4),"..
"(426, (select id from catalogo where sku = '4810103106'), 5),"..
"(427, (select id from catalogo where sku = '4810103106E'), 6),"..
"(428, (select id from catalogo where sku = '4810103108'), 2),"..
"(429, (select id from catalogo where sku = '4810103108'), 3),"..
"(430, (select id from catalogo where sku = '4810103108'), 4),"..
"(431, (select id from catalogo where sku = '4810103108'), 5),"..
"(432, (select id from catalogo where sku = '4810103108E'), 6),"..
"(433, (select id from catalogo where sku = '4810103109'), 2),"..
"(434, (select id from catalogo where sku = '4810103109'), 3),"..
"(435, (select id from catalogo where sku = '4810103109'), 4),"..
"(436, (select id from catalogo where sku = '4810103109'), 5),"..
"(437, (select id from catalogo where sku = '4810103109E'), 6),"..
"(438, (select id from catalogo where sku = '4810103494'), 2),"..
"(439, (select id from catalogo where sku = '4810103494'), 3),"..
"(440, (select id from catalogo where sku = '4810103494'), 4),"..
"(441, (select id from catalogo where sku = '4810103494'), 5),"..
"(442, (select id from catalogo where sku = '48101034949'), 6),"..
"(443, (select id from catalogo where sku = '4810104040'), 3),"..
"(444, (select id from catalogo where sku = '4810104040'), 4),"..
"(445, (select id from catalogo where sku = '4810104040'), 5),"..
"(446, (select id from catalogo where sku = '4810104041'), 3),"..
"(447, (select id from catalogo where sku = '4810104041'), 4),"..
"(448, (select id from catalogo where sku = '4810104041'), 5),"..
"(449, (select id from catalogo where sku = '4810104042'), 3),"..
"(450, (select id from catalogo where sku = '4810104042'), 4),"..
"(451, (select id from catalogo where sku = '4810104042'), 5),"..
"(452, (select id from catalogo where sku = '4810104043'), 3),"..
"(453, (select id from catalogo where sku = '4810104043'), 4);"
db:exec( query2 )
--fase 4
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(454, (select id from catalogo where sku = '4810104043'), 5),"..
"(455, (select id from catalogo where sku = '4810104044'), 3),"..
"(456, (select id from catalogo where sku = '4810104044'), 4),"..
"(457, (select id from catalogo where sku = '4810104044'), 5),"..
"(458, (select id from catalogo where sku = '4810104045'), 3),"..
"(459, (select id from catalogo where sku = '4810104045'), 4),"..
"(460, (select id from catalogo where sku = '4810104045'), 5),"..
"(461, (select id from catalogo where sku = '4810201073'), 2),"..
"(462, (select id from catalogo where sku = '4810201073'), 3),"..
"(463, (select id from catalogo where sku = '4810201073'), 4),"..
"(464, (select id from catalogo where sku = '4810201411'), 2),"..
"(465, (select id from catalogo where sku = '4810201411'), 3),"..
"(466, (select id from catalogo where sku = '4810201411'), 4),"..
"(467, (select id from catalogo where sku = '4810201465'), 2),"..
"(468, (select id from catalogo where sku = '4810201465'), 3),"..
"(469, (select id from catalogo where sku = '4810201465'), 4),"..
"(470, (select id from catalogo where sku = '4810201467'), 2),"..
"(471, (select id from catalogo where sku = '4810201467'), 3),"..
"(472, (select id from catalogo where sku = '4810201467'), 4),"..
"(473, (select id from catalogo where sku = '4810201470'), 2),"..
"(474, (select id from catalogo where sku = '4810201470'), 3),"..
"(475, (select id from catalogo where sku = '4810201470'), 4),"..
"(476, (select id from catalogo where sku = '4810201480'), 2),"..
"(477, (select id from catalogo where sku = '4810201480'), 3),"..
"(478, (select id from catalogo where sku = '4810201480'), 4),"..
"(479, (select id from catalogo where sku = '4810201481'), 2),"..
"(480, (select id from catalogo where sku = '4810201481'), 3),"..
"(481, (select id from catalogo where sku = '4810201481'), 4),"..
"(482, (select id from catalogo where sku = '4810201482'), 2),"..
"(483, (select id from catalogo where sku = '4810201482'), 3),"..
"(484, (select id from catalogo where sku = '4810201482'), 4),"..
"(485, (select id from catalogo where sku = '4810203011'), 2),"..
"(486, (select id from catalogo where sku = '4810203011'), 3),"..
"(487, (select id from catalogo where sku = '4810203011'), 4),"..
"(488, (select id from catalogo where sku = '4810203011'), 5),"..
"(489, (select id from catalogo where sku = '4810203012'), 2),"..
"(490, (select id from catalogo where sku = '4810203012'), 3),"..
"(491, (select id from catalogo where sku = '4810203012'), 4),"..
"(492, (select id from catalogo where sku = '4810203012'), 5),"..
"(493, (select id from catalogo where sku = '4810203014'), 2),"..
"(494, (select id from catalogo where sku = '4810203014'), 3),"..
"(495, (select id from catalogo where sku = '4810203014'), 4),"..
"(496, (select id from catalogo where sku = '4810203014'), 5),"..
"(497, (select id from catalogo where sku = '4810203016'), 2),"..
"(498, (select id from catalogo where sku = '4810203016'), 3),"..
"(499, (select id from catalogo where sku = '4810203016'), 4),"..
"(500, (select id from catalogo where sku = '4810203016'), 5),"..
"(501, (select id from catalogo where sku = '4810203039'), 2),"..
"(502, (select id from catalogo where sku = '4810203039'), 3),"..
"(503, (select id from catalogo where sku = '4810203039'), 4),"..
"(504, (select id from catalogo where sku = '4810203039'), 5),"..
"(505, (select id from catalogo where sku = '4810203041'), 2),"..
"(506, (select id from catalogo where sku = '4810203041'), 3),"..
"(507, (select id from catalogo where sku = '4810203041'), 4),"..
"(508, (select id from catalogo where sku = '4810203041'), 5),"..
"(509, (select id from catalogo where sku = '4810203042'), 2),"..
"(510, (select id from catalogo where sku = '4810203042'), 3),"..
"(511, (select id from catalogo where sku = '4810203042'), 4),"..
"(512, (select id from catalogo where sku = '4810203042'), 5),"..
"(513, (select id from catalogo where sku = '4810203043'), 2),"..
"(514, (select id from catalogo where sku = '4810203043'), 3),"..
"(515, (select id from catalogo where sku = '4810203043'), 4),"..
"(516, (select id from catalogo where sku = '4810203043'), 5),"..
"(517, (select id from catalogo where sku = '4810203044'), 2),"..
"(518, (select id from catalogo where sku = '4810203044'), 3),"..
"(519, (select id from catalogo where sku = '4810203044'), 4),"..
"(520, (select id from catalogo where sku = '4810203044'), 5),"..
"(521, (select id from catalogo where sku = '4810203046'), 2),"..
"(522, (select id from catalogo where sku = '4810203046'), 3),"..
"(523, (select id from catalogo where sku = '4810203046'), 4),"..
"(524, (select id from catalogo where sku = '4810203046'), 5),"..
"(525, (select id from catalogo where sku = '4810203047'), 2),"..
"(526, (select id from catalogo where sku = '4810203047'), 3),"..
"(527, (select id from catalogo where sku = '4810203047'), 4),"..
"(528, (select id from catalogo where sku = '4810203047'), 5),"..
"(529, (select id from catalogo where sku = '4810203048'), 2),"..
"(530, (select id from catalogo where sku = '4810203048'), 3),"..
"(531, (select id from catalogo where sku = '4810203048'), 4),"..
"(532, (select id from catalogo where sku = '4810203048'), 5),"..
"(533, (select id from catalogo where sku = '4810203049'), 2),"..
"(534, (select id from catalogo where sku = '4810203049'), 3),"..
"(535, (select id from catalogo where sku = '4810203049'), 4),"..
"(536, (select id from catalogo where sku = '4810203049'), 5),"..
"(537, (select id from catalogo where sku = '4810203050'), 2),"..
"(538, (select id from catalogo where sku = '4810203050'), 3),"..
"(539, (select id from catalogo where sku = '4810203050'), 4),"..
"(540, (select id from catalogo where sku = '4810203050'), 5),"..
"(541, (select id from catalogo where sku = '4810203051'), 2),"..
"(542, (select id from catalogo where sku = '4810203051'), 3),"..
"(543, (select id from catalogo where sku = '4810203051'), 4),"..
"(544, (select id from catalogo where sku = '4810203051'), 5),"..
"(545, (select id from catalogo where sku = '4810203052'), 2),"..
"(546, (select id from catalogo where sku = '4810203052'), 3),"..
"(547, (select id from catalogo where sku = '4810203052'), 4),"..
"(548, (select id from catalogo where sku = '4810203052'), 5),"..
"(549, (select id from catalogo where sku = '4810203088'), 2),"..
"(550, (select id from catalogo where sku = '4810203088'), 3),"..
"(551, (select id from catalogo where sku = '4810203088'), 4),"..
"(552, (select id from catalogo where sku = '4810203088'), 5),"..
"(553, (select id from catalogo where sku = '4810203089'), 2),"..
"(554, (select id from catalogo where sku = '4810203089'), 3),"..
"(555, (select id from catalogo where sku = '4810203089'), 4),"..
"(556, (select id from catalogo where sku = '4810203089'), 5),"..
"(557, (select id from catalogo where sku = '4810203090'), 2),"..
"(558, (select id from catalogo where sku = '4810203090'), 3),"..
"(559, (select id from catalogo where sku = '4810203090'), 4),"..
"(560, (select id from catalogo where sku = '4810203090'), 5),"..
"(561, (select id from catalogo where sku = '4810203091'), 2),"..
"(562, (select id from catalogo where sku = '4810203091'), 3),"..
"(563, (select id from catalogo where sku = '4810203091'), 4),"..
"(564, (select id from catalogo where sku = '4810203091'), 5),"..
"(565, (select id from catalogo where sku = '4810203092'), 2),"..
"(566, (select id from catalogo where sku = '4810203092'), 3),"..
"(567, (select id from catalogo where sku = '4810203092'), 4),"..
"(568, (select id from catalogo where sku = '4810203092'), 5),"..
"(569, (select id from catalogo where sku = '4810203093'), 2),"..
"(570, (select id from catalogo where sku = '4810203093'), 3),"..
"(571, (select id from catalogo where sku = '4810203093'), 4),"..
"(572, (select id from catalogo where sku = '4810203093'), 5),"..
"(573, (select id from catalogo where sku = '4810203094'), 2),"..
"(574, (select id from catalogo where sku = '4810203094'), 3),"..
"(575, (select id from catalogo where sku = '4810203094'), 4),"..
"(576, (select id from catalogo where sku = '4810203094'), 5),"..
"(577, (select id from catalogo where sku = '4810203095'), 2),"..
"(578, (select id from catalogo where sku = '4810203095'), 3),"..
"(579, (select id from catalogo where sku = '4810203095'), 4),"..
"(580, (select id from catalogo where sku = '4810203095'), 5),"..
"(581, (select id from catalogo where sku = '4810203096'), 2),"..
"(582, (select id from catalogo where sku = '4810203096'), 3),"..
"(583, (select id from catalogo where sku = '4810203096'), 4),"..
"(584, (select id from catalogo where sku = '4810203096'), 5),"..
"(585, (select id from catalogo where sku = '4810203097'), 2),"..
"(586, (select id from catalogo where sku = '4810203097'), 3),"..
"(587, (select id from catalogo where sku = '4810203097'), 4),"..
"(588, (select id from catalogo where sku = '4810203097'), 5),"..
"(589, (select id from catalogo where sku = '4810204051'), 2),"..
"(590, (select id from catalogo where sku = '4810204051'), 3),"..
"(591, (select id from catalogo where sku = '4810204051'), 4),"..
"(592, (select id from catalogo where sku = '4810204051'), 5),"..
"(593, (select id from catalogo where sku = '4810204052'), 2),"..
"(594, (select id from catalogo where sku = '4810204052'), 3),"..
"(595, (select id from catalogo where sku = '4810204052'), 4),"..
"(596, (select id from catalogo where sku = '4810204052'), 5),"..
"(597, (select id from catalogo where sku = '4810204053'), 2),"..
"(598, (select id from catalogo where sku = '4810204053'), 3),"..
"(599, (select id from catalogo where sku = '4810204053'), 4),"..
"(600, (select id from catalogo where sku = '4810204053'), 5),"..
"(601, (select id from catalogo where sku = '4810204054'), 2),"..
"(602, (select id from catalogo where sku = '4810204054'), 3),"..
"(603, (select id from catalogo where sku = '4810204054'), 4),"..
"(604, (select id from catalogo where sku = '4810204054'), 5);"
db:exec( query2 )
--fase 5
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(605, (select id from catalogo where sku = '4810204055'), 2),"..
"(606, (select id from catalogo where sku = '4810204055'), 3),"..
"(607, (select id from catalogo where sku = '4810204055'), 4),"..
"(608, (select id from catalogo where sku = '4810204055'), 5),"..
"(609, (select id from catalogo where sku = '4810204056'), 2),"..
"(610, (select id from catalogo where sku = '4810204056'), 3),"..
"(611, (select id from catalogo where sku = '4810204056'), 4),"..
"(612, (select id from catalogo where sku = '4810204056'), 5),"..
"(613, (select id from catalogo where sku = '4810206001'), 2),"..
"(614, (select id from catalogo where sku = '4810206001'), 3),"..
"(615, (select id from catalogo where sku = '4810206001'), 4),"..
"(616, (select id from catalogo where sku = '4810206001'), 5),"..
"(617, (select id from catalogo where sku = '4810206002'), 2),"..
"(618, (select id from catalogo where sku = '4810206002'), 3),"..
"(619, (select id from catalogo where sku = '4810206002'), 4),"..
"(620, (select id from catalogo where sku = '4810206002'), 5),"..
"(621, (select id from catalogo where sku = '4810206003'), 2),"..
"(622, (select id from catalogo where sku = '4810206003'), 3),"..
"(623, (select id from catalogo where sku = '4810206003'), 4),"..
"(624, (select id from catalogo where sku = '4810206003'), 5),"..
"(625, (select id from catalogo where sku = '4810303019'), 2),"..
"(626, (select id from catalogo where sku = '4810303019'), 3),"..
"(627, (select id from catalogo where sku = '4810303019'), 4),"..
"(628, (select id from catalogo where sku = '4810303019'), 5),"..
"(629, (select id from catalogo where sku = '4810303020'), 2),"..
"(630, (select id from catalogo where sku = '4810303020'), 3),"..
"(631, (select id from catalogo where sku = '4810303020'), 4),"..
"(632, (select id from catalogo where sku = '4810303020'), 5),"..
"(633, (select id from catalogo where sku = '4810303021'), 2),"..
"(634, (select id from catalogo where sku = '4810303021'), 3),"..
"(635, (select id from catalogo where sku = '4810303021'), 4),"..
"(636, (select id from catalogo where sku = '4810303021'), 5),"..
"(637, (select id from catalogo where sku = '4810303054'), 2),"..
"(638, (select id from catalogo where sku = '4810303054'), 3),"..
"(639, (select id from catalogo where sku = '4810303054'), 4),"..
"(640, (select id from catalogo where sku = '4810303054'), 5),"..
"(641, (select id from catalogo where sku = '4810303055'), 2),"..
"(642, (select id from catalogo where sku = '4810303055'), 3),"..
"(643, (select id from catalogo where sku = '4810303055'), 4),"..
"(644, (select id from catalogo where sku = '4810303055'), 5),"..
"(645, (select id from catalogo where sku = '4810303056'), 2),"..
"(646, (select id from catalogo where sku = '4810303056'), 3),"..
"(647, (select id from catalogo where sku = '4810303056'), 4),"..
"(648, (select id from catalogo where sku = '4810303056'), 5),"..
"(649, (select id from catalogo where sku = '4810303057'), 2),"..
"(650, (select id from catalogo where sku = '4810303057'), 3),"..
"(651, (select id from catalogo where sku = '4810303057'), 4),"..
"(652, (select id from catalogo where sku = '4810303057'), 5),"..
"(653, (select id from catalogo where sku = '4810303058'), 2),"..
"(654, (select id from catalogo where sku = '4810303058'), 3),"..
"(655, (select id from catalogo where sku = '4810303058'), 4),"..
"(656, (select id from catalogo where sku = '4810303058'), 5),"..
"(657, (select id from catalogo where sku = '4810303060'), 2),"..
"(658, (select id from catalogo where sku = '4810303060'), 3),"..
"(659, (select id from catalogo where sku = '4810303060'), 4),"..
"(660, (select id from catalogo where sku = '4810303060'), 5),"..
"(661, (select id from catalogo where sku = '4810303061'), 2),"..
"(662, (select id from catalogo where sku = '4810303061'), 3),"..
"(663, (select id from catalogo where sku = '4810303061'), 4),"..
"(664, (select id from catalogo where sku = '4810303061'), 5),"..
"(665, (select id from catalogo where sku = '4810303062'), 2),"..
"(666, (select id from catalogo where sku = '4810303062'), 3),"..
"(667, (select id from catalogo where sku = '4810303062'), 4),"..
"(668, (select id from catalogo where sku = '4810303062'), 5),"..
"(669, (select id from catalogo where sku = '4810303063'), 2),"..
"(670, (select id from catalogo where sku = '4810303063'), 3),"..
"(671, (select id from catalogo where sku = '4810303063'), 4),"..
"(672, (select id from catalogo where sku = '4810303063'), 5),"..
"(673, (select id from catalogo where sku = '4810303064'), 2),"..
"(674, (select id from catalogo where sku = '4810303064'), 3),"..
"(675, (select id from catalogo where sku = '4810303064'), 4),"..
"(676, (select id from catalogo where sku = '4810303064'), 5),"..
"(677, (select id from catalogo where sku = '4810303068'), 2),"..
"(678, (select id from catalogo where sku = '4810303068'), 3),"..
"(679, (select id from catalogo where sku = '4810303068'), 4),"..
"(680, (select id from catalogo where sku = '4810303068'), 5),"..
"(681, (select id from catalogo where sku = '4810303069'), 2),"..
"(682, (select id from catalogo where sku = '4810303069'), 3),"..
"(683, (select id from catalogo where sku = '4810303069'), 4),"..
"(684, (select id from catalogo where sku = '4810303069'), 5),"..
"(685, (select id from catalogo where sku = '4810303085'), 2),"..
"(686, (select id from catalogo where sku = '4810303085'), 3),"..
"(687, (select id from catalogo where sku = '4810303085'), 4),"..
"(688, (select id from catalogo where sku = '4810303085'), 5),"..
"(689, (select id from catalogo where sku = '4810303086'), 2),"..
"(690, (select id from catalogo where sku = '4810303086'), 3),"..
"(691, (select id from catalogo where sku = '4810303086'), 4),"..
"(692, (select id from catalogo where sku = '4810303086'), 5),"..
"(693, (select id from catalogo where sku = '4810303098'), 2),"..
"(694, (select id from catalogo where sku = '4810303098'), 3),"..
"(695, (select id from catalogo where sku = '4810303098'), 4),"..
"(696, (select id from catalogo where sku = '4810303098'), 5),"..
"(697, (select id from catalogo where sku = '4810303101'), 2),"..
"(698, (select id from catalogo where sku = '4810303101'), 3),"..
"(699, (select id from catalogo where sku = '4810303101'), 4),"..
"(700, (select id from catalogo where sku = '4810303101'), 5),"..
"(701, (select id from catalogo where sku = '4810303102'), 2),"..
"(702, (select id from catalogo where sku = '4810303102'), 3),"..
"(703, (select id from catalogo where sku = '4810303102'), 4),"..
"(704, (select id from catalogo where sku = '4810303102'), 5),"..
"(705, (select id from catalogo where sku = '4810303106'), 2),"..
"(706, (select id from catalogo where sku = '4810303106'), 3),"..
"(707, (select id from catalogo where sku = '4810303106'), 4),"..
"(708, (select id from catalogo where sku = '4810303106'), 5),"..
"(709, (select id from catalogo where sku = '4810303107'), 2),"..
"(710, (select id from catalogo where sku = '4810303107'), 3),"..
"(711, (select id from catalogo where sku = '4810303107'), 4),"..
"(712, (select id from catalogo where sku = '4810303107'), 5),"..
"(713, (select id from catalogo where sku = '4810307022'), 2),"..
"(714, (select id from catalogo where sku = '4810307022'), 3),"..
"(715, (select id from catalogo where sku = '4810307022'), 4),"..
"(716, (select id from catalogo where sku = '4810307022'), 5),"..
"(717, (select id from catalogo where sku = '4810307023'), 2),"..
"(718, (select id from catalogo where sku = '4810307023'), 3),"..
"(719, (select id from catalogo where sku = '4810307023'), 4),"..
"(720, (select id from catalogo where sku = '4810307023'), 5),"..
"(721, (select id from catalogo where sku = '4810307024'), 2),"..
"(722, (select id from catalogo where sku = '4810307024'), 3),"..
"(723, (select id from catalogo where sku = '4810307024'), 4),"..
"(724, (select id from catalogo where sku = '4810307024'), 5),"..
"(725, (select id from catalogo where sku = '4810307025'), 2),"..
"(726, (select id from catalogo where sku = '4810307025'), 3),"..
"(727, (select id from catalogo where sku = '4810307025'), 4),"..
"(728, (select id from catalogo where sku = '4810307025'), 5),"..
"(729, (select id from catalogo where sku = '4810601001'), 2),"..
"(730, (select id from catalogo where sku = '4810601001'), 3),"..
"(731, (select id from catalogo where sku = '4810601001'), 4),"..
"(732, (select id from catalogo where sku = '4810601001'), 5),"..
"(733, (select id from catalogo where sku = '4810601002'), 2),"..
"(734, (select id from catalogo where sku = '4810601002'), 3),"..
"(735, (select id from catalogo where sku = '4810601002'), 4),"..
"(736, (select id from catalogo where sku = '4810601002'), 5),"..
"(737, (select id from catalogo where sku = '4810601003'), 2),"..
"(738, (select id from catalogo where sku = '4810601003'), 3),"..
"(739, (select id from catalogo where sku = '4810601003'), 4),"..
"(740, (select id from catalogo where sku = '4810601003'), 5),"..
"(741, (select id from catalogo where sku = '4810601004'), 2),"..
"(742, (select id from catalogo where sku = '4810601004'), 3),"..
"(743, (select id from catalogo where sku = '4810601004'), 4),"..
"(744, (select id from catalogo where sku = '4810601004'), 5),"..
"(745, (select id from catalogo where sku = '4810601005'), 2),"..
"(746, (select id from catalogo where sku = '4810601005'), 3),"..
"(747, (select id from catalogo where sku = '4810601005'), 4),"..
"(748, (select id from catalogo where sku = '4810601005'), 5),"..
"(749, (select id from catalogo where sku = '4810601006'), 2),"..
"(750, (select id from catalogo where sku = '4810601006'), 3),"..
"(751, (select id from catalogo where sku = '4810601006'), 4),"..
"(752, (select id from catalogo where sku = '4810601006'), 5),"..
"(753, (select id from catalogo where sku = '4810601007'), 2),"..
"(754, (select id from catalogo where sku = '4810601007'), 3),"..
"(755, (select id from catalogo where sku = '4810601007'), 4);"
db:exec( query2 )
--fase 6
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(756, (select id from catalogo where sku = '4810601007'), 5),"..
"(757, (select id from catalogo where sku = '4810703001'), 2),"..
"(758, (select id from catalogo where sku = '4810703001'), 3),"..
"(759, (select id from catalogo where sku = '4810703001'), 4),"..
"(760, (select id from catalogo where sku = '4810703001'), 5),"..
"(761, (select id from catalogo where sku = '48107030019'), 6),"..
"(762, (select id from catalogo where sku = '4810703002'), 2),"..
"(763, (select id from catalogo where sku = '4810703002'), 3),"..
"(764, (select id from catalogo where sku = '4810703002'), 4),"..
"(765, (select id from catalogo where sku = '4810703002'), 5),"..
"(766, (select id from catalogo where sku = '48107030029'), 6),"..
"(767, (select id from catalogo where sku = '4810703003'), 2),"..
"(768, (select id from catalogo where sku = '4810703003'), 3),"..
"(769, (select id from catalogo where sku = '4810703003'), 4),"..
"(770, (select id from catalogo where sku = '4810703003'), 5),"..
"(771, (select id from catalogo where sku = '48107030039'), 6),"..
"(772, (select id from catalogo where sku = '4810703004'), 2),"..
"(773, (select id from catalogo where sku = '4810703004'), 3),"..
"(774, (select id from catalogo where sku = '4810703004'), 4),"..
"(775, (select id from catalogo where sku = '4810703004'), 5),"..
"(776, (select id from catalogo where sku = '48107030049'), 6),"..
"(777, (select id from catalogo where sku = '4810907022'), 2),"..
"(778, (select id from catalogo where sku = '4810907022'), 3),"..
"(779, (select id from catalogo where sku = '4810907022'), 4),"..
"(780, (select id from catalogo where sku = '4810907022'), 5),"..
"(781, (select id from catalogo where sku = '4810907022'), 6),"..
"(782, (select id from catalogo where sku = '4810907023'), 2),"..
"(783, (select id from catalogo where sku = '4810907023'), 3),"..
"(784, (select id from catalogo where sku = '4810907023'), 4),"..
"(785, (select id from catalogo where sku = '4810907023'), 5),"..
"(786, (select id from catalogo where sku = '4810907023'), 6),"..
"(787, (select id from catalogo where sku = '4810907024'), 2),"..
"(788, (select id from catalogo where sku = '4810907024'), 3),"..
"(789, (select id from catalogo where sku = '4810907024'), 4),"..
"(790, (select id from catalogo where sku = '4810907024'), 5),"..
"(791, (select id from catalogo where sku = '4810907024'), 6),"..
"(792, (select id from catalogo where sku = '4810907025'), 2),"..
"(793, (select id from catalogo where sku = '4810907025'), 3),"..
"(794, (select id from catalogo where sku = '4810907025'), 4),"..
"(795, (select id from catalogo where sku = '4810907025'), 5),"..
"(796, (select id from catalogo where sku = '4810907025'), 6),"..
"(797, (select id from catalogo where sku = '4811003053'), 2),"..
"(798, (select id from catalogo where sku = '4811003053'), 3),"..
"(799, (select id from catalogo where sku = '4811003053'), 4),"..
"(800, (select id from catalogo where sku = '4811003053'), 5),"..
"(801, (select id from catalogo where sku = '48110060170'), 2),"..
"(802, (select id from catalogo where sku = '48110060170'), 3),"..
"(803, (select id from catalogo where sku = '48110060170'), 4),"..
"(804, (select id from catalogo where sku = '48110060170'), 5),"..
"(805, (select id from catalogo where sku = '4811006018'), 2),"..
"(806, (select id from catalogo where sku = '4811006018'), 3),"..
"(807, (select id from catalogo where sku = '4811006018'), 4),"..
"(808, (select id from catalogo where sku = '4811006018'), 5),"..
"(809, (select id from catalogo where sku = '4811006054'), 2),"..
"(810, (select id from catalogo where sku = '4811006054'), 3),"..
"(811, (select id from catalogo where sku = '4811006054'), 4),"..
"(812, (select id from catalogo where sku = '4811006054'), 5),"..
"(813, (select id from catalogo where sku = '4811006055'), 2),"..
"(814, (select id from catalogo where sku = '4811006055'), 3),"..
"(815, (select id from catalogo where sku = '4811006055'), 4),"..
"(816, (select id from catalogo where sku = '4811006055'), 5),"..
"(817, (select id from catalogo where sku = '481116500111'), 8),"..
"(818, (select id from catalogo where sku = '481116500113'), 8),"..
"(819, (select id from catalogo where sku = '481116500128'), 8),"..
"(820, (select id from catalogo where sku = '481116500130'), 8),"..
"(821, (select id from catalogo where sku = '481116500166'), 8),"..
"(822, (select id from catalogo where sku = '481116600102'), 8),"..
"(823, (select id from catalogo where sku = '481116600111'), 8),"..
"(824, (select id from catalogo where sku = '481116600113'), 8),"..
"(825, (select id from catalogo where sku = '481116600128'), 8),"..
"(826, (select id from catalogo where sku = '481116600130'), 8),"..
"(827, (select id from catalogo where sku = '481116600131'), 8),"..
"(828, (select id from catalogo where sku = '481116600137'), 8),"..
"(829, (select id from catalogo where sku = '481116700102'), 8),"..
"(830, (select id from catalogo where sku = '481116700111'), 8),"..
"(831, (select id from catalogo where sku = '481116700113'), 8),"..
"(832, (select id from catalogo where sku = '481116700128'), 8),"..
"(833, (select id from catalogo where sku = '481116700131'), 8),"..
"(834, (select id from catalogo where sku = '481116900503'), 8),"..
"(835, (select id from catalogo where sku = '481116900510'), 8),"..
"(836, (select id from catalogo where sku = '481116900511'), 8),"..
"(837, (select id from catalogo where sku = '481116900512'), 8),"..
"(838, (select id from catalogo where sku = '481116900513'), 8),"..
"(839, (select id from catalogo where sku = '481116900526'), 8),"..
"(840, (select id from catalogo where sku = '481116900528'), 8),"..
"(841, (select id from catalogo where sku = '481116900530'), 8),"..
"(842, (select id from catalogo where sku = '481117800117'), 8),"..
"(843, (select id from catalogo where sku = '481117800129'), 8),"..
"(844, (select id from catalogo where sku = '481117800130'), 8),"..
"(845, (select id from catalogo where sku = '481117800137'), 8),"..
"(846, (select id from catalogo where sku = '481117800140'), 8),"..
"(847, (select id from catalogo where sku = '481117800166'), 8),"..
"(848, (select id from catalogo where sku = '481117900104'), 8),"..
"(849, (select id from catalogo where sku = '481117900118'), 8),"..
"(850, (select id from catalogo where sku = '481117900129'), 8),"..
"(851, (select id from catalogo where sku = '481117900138'), 8),"..
"(852, (select id from catalogo where sku = '481118000113'), 8),"..
"(853, (select id from catalogo where sku = '481118000126'), 8),"..
"(854, (select id from catalogo where sku = '481118000132'), 8),"..
"(855, (select id from catalogo where sku = '481118100102'), 8),"..
"(856, (select id from catalogo where sku = '481118100110'), 8),"..
"(857, (select id from catalogo where sku = '481118100111'), 8),"..
"(858, (select id from catalogo where sku = '481118100112'), 8),"..
"(859, (select id from catalogo where sku = '481118100115'), 8),"..
"(860, (select id from catalogo where sku = '481118100126'), 8),"..
"(861, (select id from catalogo where sku = '481118200104'), 8),"..
"(862, (select id from catalogo where sku = '481118200112'), 8),"..
"(863, (select id from catalogo where sku = '481118200118'), 8),"..
"(864, (select id from catalogo where sku = '481118200119'), 8),"..
"(865, (select id from catalogo where sku = '481118200123'), 8),"..
"(866, (select id from catalogo where sku = '481118200129'), 8),"..
"(867, (select id from catalogo where sku = '481118200140'), 8),"..
"(868, (select id from catalogo where sku = '481118200141'), 8),"..
"(869, (select id from catalogo where sku = '481118200142'), 8),"..
"(870, (select id from catalogo where sku = '481118300105'), 8),"..
"(871, (select id from catalogo where sku = '481118300111'), 8),"..
"(872, (select id from catalogo where sku = '481118300113'), 8),"..
"(873, (select id from catalogo where sku = '481118300120'), 8),"..
"(874, (select id from catalogo where sku = '481118300122'), 8),"..
"(875, (select id from catalogo where sku = '481118300133'), 8),"..
"(876, (select id from catalogo where sku = '481118300136'), 8),"..
"(877, (select id from catalogo where sku = '481118300139'), 8),"..
"(878, (select id from catalogo where sku = '481118300143'), 8),"..
"(879, (select id from catalogo where sku = '481118300145'), 8),"..
"(880, (select id from catalogo where sku = '481118300147'), 8),"..
"(881, (select id from catalogo where sku = '481118300149'), 8),"..
"(882, (select id from catalogo where sku = '481118300205'), 8),"..
"(883, (select id from catalogo where sku = '481118300211'), 8),"..
"(884, (select id from catalogo where sku = '481118300213'), 8),"..
"(885, (select id from catalogo where sku = '481118300220'), 8),"..
"(886, (select id from catalogo where sku = '481118300222'), 8),"..
"(887, (select id from catalogo where sku = '481118300233'), 8),"..
"(888, (select id from catalogo where sku = '481118300236'), 8),"..
"(889, (select id from catalogo where sku = '481118300239'), 8),"..
"(890, (select id from catalogo where sku = '481118300243'), 8),"..
"(891, (select id from catalogo where sku = '481118300245'), 8),"..
"(892, (select id from catalogo where sku = '481118300247'), 8),"..
"(893, (select id from catalogo where sku = '481118300249'), 8),"..
"(894, (select id from catalogo where sku = '481118500102'), 8),"..
"(895, (select id from catalogo where sku = '481118500103'), 8),"..
"(896, (select id from catalogo where sku = '481118500105'), 8),"..
"(897, (select id from catalogo where sku = '481118500106'), 8),"..
"(898, (select id from catalogo where sku = '481118500109'), 8),"..
"(899, (select id from catalogo where sku = '481118500110'), 8),"..
"(900, (select id from catalogo where sku = '481118500111'), 8),"..
"(901, (select id from catalogo where sku = '481118500112'), 8),"..
"(902, (select id from catalogo where sku = '481118500113'), 8),"..
"(903, (select id from catalogo where sku = '481118500114'), 8),"..
"(904, (select id from catalogo where sku = '481118500115'), 8),"..
"(905, (select id from catalogo where sku = '481118500116'), 8),"..
"(906, (select id from catalogo where sku = '481118500121'), 8);"
db:exec( query2 )
--fase 7
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(907, (select id from catalogo where sku = '481118500125'), 8),"..
"(908, (select id from catalogo where sku = '481118500126'), 8),"..
"(909, (select id from catalogo where sku = '481118500128'), 8),"..
"(910, (select id from catalogo where sku = '481118500129'), 8),"..
"(911, (select id from catalogo where sku = '481118500130'), 8),"..
"(912, (select id from catalogo where sku = '481118500131'), 8),"..
"(913, (select id from catalogo where sku = '481118500132'), 8),"..
"(914, (select id from catalogo where sku = '481118500134'), 8),"..
"(915, (select id from catalogo where sku = '481118500135'), 8),"..
"(916, (select id from catalogo where sku = '481118500137'), 8),"..
"(917, (select id from catalogo where sku = '481118500138'), 8),"..
"(918, (select id from catalogo where sku = '481118500202'), 8),"..
"(919, (select id from catalogo where sku = '481118500203'), 8),"..
"(920, (select id from catalogo where sku = '481118500205'), 8),"..
"(921, (select id from catalogo where sku = '481118500206'), 8),"..
"(922, (select id from catalogo where sku = '481118500209'), 8),"..
"(923, (select id from catalogo where sku = '481118500210'), 8),"..
"(924, (select id from catalogo where sku = '481118500211'), 8),"..
"(925, (select id from catalogo where sku = '481118500212'), 8),"..
"(926, (select id from catalogo where sku = '481118500213'), 8),"..
"(927, (select id from catalogo where sku = '481118500214'), 8),"..
"(928, (select id from catalogo where sku = '481118500215'), 8),"..
"(929, (select id from catalogo where sku = '481118500216'), 8),"..
"(930, (select id from catalogo where sku = '481118500221'), 8),"..
"(931, (select id from catalogo where sku = '481118500225'), 8),"..
"(932, (select id from catalogo where sku = '481118500226'), 8),"..
"(933, (select id from catalogo where sku = '481118500228'), 8),"..
"(934, (select id from catalogo where sku = '481118500229'), 8),"..
"(935, (select id from catalogo where sku = '481118500230'), 8),"..
"(936, (select id from catalogo where sku = '481118500231'), 8),"..
"(937, (select id from catalogo where sku = '481118500232'), 8),"..
"(938, (select id from catalogo where sku = '481118500234'), 8),"..
"(939, (select id from catalogo where sku = '481118500235'), 8),"..
"(940, (select id from catalogo where sku = '481118500237'), 8),"..
"(941, (select id from catalogo where sku = '481118500238'), 8),"..
"(942, (select id from catalogo where sku = '481118500302'), 8),"..
"(943, (select id from catalogo where sku = '481118500303'), 8),"..
"(944, (select id from catalogo where sku = '481118500305'), 8),"..
"(945, (select id from catalogo where sku = '481118500306'), 8),"..
"(946, (select id from catalogo where sku = '481118500309'), 8),"..
"(947, (select id from catalogo where sku = '481118500310'), 8),"..
"(948, (select id from catalogo where sku = '481118500311'), 8),"..
"(949, (select id from catalogo where sku = '481118500312'), 8),"..
"(950, (select id from catalogo where sku = '481118500313'), 8),"..
"(951, (select id from catalogo where sku = '481118500314'), 8),"..
"(952, (select id from catalogo where sku = '481118500315'), 8),"..
"(953, (select id from catalogo where sku = '481118500316'), 8),"..
"(954, (select id from catalogo where sku = '481118500321'), 8),"..
"(955, (select id from catalogo where sku = '481118500325'), 8),"..
"(956, (select id from catalogo where sku = '481118500326'), 8),"..
"(957, (select id from catalogo where sku = '481118500328'), 8),"..
"(958, (select id from catalogo where sku = '481118500329'), 8),"..
"(959, (select id from catalogo where sku = '481118500330'), 8),"..
"(960, (select id from catalogo where sku = '481118500331'), 8),"..
"(961, (select id from catalogo where sku = '481118500332'), 8),"..
"(962, (select id from catalogo where sku = '481118500334'), 8),"..
"(963, (select id from catalogo where sku = '481118500335'), 8),"..
"(964, (select id from catalogo where sku = '481118500337'), 8),"..
"(965, (select id from catalogo where sku = '481118500338'), 8),"..
"(966, (select id from catalogo where sku = '481118500402'), 8),"..
"(967, (select id from catalogo where sku = '481118500403'), 8),"..
"(968, (select id from catalogo where sku = '481118500405'), 8),"..
"(969, (select id from catalogo where sku = '481118500406'), 8),"..
"(970, (select id from catalogo where sku = '481118500409'), 8),"..
"(971, (select id from catalogo where sku = '481118500410'), 8),"..
"(972, (select id from catalogo where sku = '481118500411'), 8),"..
"(973, (select id from catalogo where sku = '481118500412'), 8),"..
"(974, (select id from catalogo where sku = '481118500413'), 8),"..
"(975, (select id from catalogo where sku = '481118500414'), 8),"..
"(976, (select id from catalogo where sku = '481118500415'), 8),"..
"(977, (select id from catalogo where sku = '481118500416'), 8),"..
"(978, (select id from catalogo where sku = '481118500421'), 8),"..
"(979, (select id from catalogo where sku = '481118500425'), 8),"..
"(980, (select id from catalogo where sku = '481118500426'), 8),"..
"(981, (select id from catalogo where sku = '481118500428'), 8),"..
"(982, (select id from catalogo where sku = '481118500429'), 8),"..
"(983, (select id from catalogo where sku = '481118500430'), 8),"..
"(984, (select id from catalogo where sku = '481118500431'), 8),"..
"(985, (select id from catalogo where sku = '481118500432'), 8),"..
"(986, (select id from catalogo where sku = '481118500434'), 8),"..
"(987, (select id from catalogo where sku = '481118500435'), 8),"..
"(988, (select id from catalogo where sku = '481118500437'), 8),"..
"(989, (select id from catalogo where sku = '481118500438'), 8),"..
"(990, (select id from catalogo where sku = '481118500502'), 8),"..
"(991, (select id from catalogo where sku = '481118500503'), 8),"..
"(992, (select id from catalogo where sku = '481118500505'), 8),"..
"(993, (select id from catalogo where sku = '481118500506'), 8),"..
"(994, (select id from catalogo where sku = '481118500509'), 8),"..
"(995, (select id from catalogo where sku = '481118500510'), 8),"..
"(996, (select id from catalogo where sku = '481118500511'), 8),"..
"(997, (select id from catalogo where sku = '481118500512'), 8),"..
"(998, (select id from catalogo where sku = '481118500513'), 8),"..
"(999, (select id from catalogo where sku = '481118500514'), 8),"..
"(1000, (select id from catalogo where sku = '481118500515'), 8),"..
"(1001, (select id from catalogo where sku = '481118500516'), 8),"..
"(1002, (select id from catalogo where sku = '481118500521'), 8),"..
"(1003, (select id from catalogo where sku = '481118500525'), 8),"..
"(1004, (select id from catalogo where sku = '481118500526'), 8),"..
"(1005, (select id from catalogo where sku = '481118500528'), 8),"..
"(1006, (select id from catalogo where sku = '481118500529'), 8),"..
"(1007, (select id from catalogo where sku = '481118500530'), 8),"..
"(1008, (select id from catalogo where sku = '481118500531'), 8),"..
"(1009, (select id from catalogo where sku = '481118500532'), 8),"..
"(1010, (select id from catalogo where sku = '481118500534'), 8),"..
"(1011, (select id from catalogo where sku = '481118500535'), 8),"..
"(1012, (select id from catalogo where sku = '481118500537'), 8),"..
"(1013, (select id from catalogo where sku = '481118500538'), 8),"..
"(1014, (select id from catalogo where sku = '481118500602'), 8),"..
"(1015, (select id from catalogo where sku = '481118500603'), 8),"..
"(1016, (select id from catalogo where sku = '481118500605'), 8),"..
"(1017, (select id from catalogo where sku = '481118500606'), 8),"..
"(1018, (select id from catalogo where sku = '481118500609'), 8),"..
"(1019, (select id from catalogo where sku = '481118500610'), 8),"..
"(1020, (select id from catalogo where sku = '481118500611'), 8),"..
"(1021, (select id from catalogo where sku = '481118500612'), 8),"..
"(1022, (select id from catalogo where sku = '481118500613'), 8),"..
"(1023, (select id from catalogo where sku = '481118500614'), 8),"..
"(1024, (select id from catalogo where sku = '481118500615'), 8),"..
"(1025, (select id from catalogo where sku = '481118500616'), 8),"..
"(1026, (select id from catalogo where sku = '481118500621'), 8),"..
"(1027, (select id from catalogo where sku = '481118500625'), 8),"..
"(1028, (select id from catalogo where sku = '481118500626'), 8),"..
"(1029, (select id from catalogo where sku = '481118500628'), 8),"..
"(1030, (select id from catalogo where sku = '481118500629'), 8),"..
"(1031, (select id from catalogo where sku = '481118500630'), 8),"..
"(1032, (select id from catalogo where sku = '481118500631'), 8),"..
"(1033, (select id from catalogo where sku = '481118500632'), 8),"..
"(1034, (select id from catalogo where sku = '481118500634'), 8),"..
"(1035, (select id from catalogo where sku = '481118500635'), 8),"..
"(1036, (select id from catalogo where sku = '481118500637'), 8),"..
"(1037, (select id from catalogo where sku = '481118500638'), 8),"..
"(1038, (select id from catalogo where sku = '481118500702'), 8),"..
"(1039, (select id from catalogo where sku = '481118500703'), 8),"..
"(1040, (select id from catalogo where sku = '481118500705'), 8),"..
"(1041, (select id from catalogo where sku = '481118500706'), 8),"..
"(1042, (select id from catalogo where sku = '481118500709'), 8),"..
"(1043, (select id from catalogo where sku = '481118500710'), 8),"..
"(1044, (select id from catalogo where sku = '481118500711'), 8),"..
"(1045, (select id from catalogo where sku = '481118500712'), 8),"..
"(1046, (select id from catalogo where sku = '481118500713'), 8),"..
"(1047, (select id from catalogo where sku = '481118500714'), 8),"..
"(1048, (select id from catalogo where sku = '481118500715'), 8),"..
"(1049, (select id from catalogo where sku = '481118500716'), 8),"..
"(1050, (select id from catalogo where sku = '481118500721'), 8),"..
"(1051, (select id from catalogo where sku = '481118500725'), 8),"..
"(1052, (select id from catalogo where sku = '481118500726'), 8),"..
"(1053, (select id from catalogo where sku = '481118500728'), 8),"..
"(1054, (select id from catalogo where sku = '481118500729'), 8),"..
"(1055, (select id from catalogo where sku = '481118500730'), 8),"..
"(1056, (select id from catalogo where sku = '481118500731'), 8),"..
"(1057, (select id from catalogo where sku = '481118500732'), 8);"
db:exec( query2 )
--fase 8
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1058, (select id from catalogo where sku = '481118500734'), 8),"..
"(1059, (select id from catalogo where sku = '481118500735'), 8),"..
"(1060, (select id from catalogo where sku = '481118500737'), 8),"..
"(1061, (select id from catalogo where sku = '481118500738'), 8),"..
"(1062, (select id from catalogo where sku = '481118600102'), 8),"..
"(1063, (select id from catalogo where sku = '481118600103'), 8),"..
"(1064, (select id from catalogo where sku = '481118600108'), 8),"..
"(1065, (select id from catalogo where sku = '481118600109'), 8),"..
"(1066, (select id from catalogo where sku = '481118600111'), 8),"..
"(1067, (select id from catalogo where sku = '481118600112'), 8),"..
"(1068, (select id from catalogo where sku = '481118600113'), 8),"..
"(1069, (select id from catalogo where sku = '481118600115'), 8),"..
"(1070, (select id from catalogo where sku = '481118600116'), 8),"..
"(1071, (select id from catalogo where sku = '481118600117'), 8),"..
"(1072, (select id from catalogo where sku = '481118600118'), 8),"..
"(1073, (select id from catalogo where sku = '481118600128'), 8),"..
"(1074, (select id from catalogo where sku = '481118600129'), 8),"..
"(1075, (select id from catalogo where sku = '481118600130'), 8),"..
"(1076, (select id from catalogo where sku = '481118600131'), 8),"..
"(1077, (select id from catalogo where sku = '481118600132'), 8),"..
"(1078, (select id from catalogo where sku = '481118600137'), 8),"..
"(1079, (select id from catalogo where sku = '481118600140'), 8),"..
"(1080, (select id from catalogo where sku = '481118600169'), 8),"..
"(1081, (select id from catalogo where sku = '481118600170'), 8),"..
"(1082, (select id from catalogo where sku = '481118600171'), 8),"..
"(1083, (select id from catalogo where sku = '481118600172'), 8),"..
"(1084, (select id from catalogo where sku = '481118600173'), 8),"..
"(1085, (select id from catalogo where sku = '481118600186'), 8),"..
"(1086, (select id from catalogo where sku = '481118600187'), 8),"..
"(1087, (select id from catalogo where sku = '481118700103'), 8),"..
"(1088, (select id from catalogo where sku = '481118700104'), 8),"..
"(1089, (select id from catalogo where sku = '481118700110'), 8),"..
"(1090, (select id from catalogo where sku = '481118700112'), 8),"..
"(1091, (select id from catalogo where sku = '481118700129'), 8),"..
"(1092, (select id from catalogo where sku = '481118800103'), 8),"..
"(1093, (select id from catalogo where sku = '481118800104'), 8),"..
"(1094, (select id from catalogo where sku = '481118800108'), 8),"..
"(1095, (select id from catalogo where sku = '481118800110'), 8),"..
"(1096, (select id from catalogo where sku = '481118800111'), 8),"..
"(1097, (select id from catalogo where sku = '481118800112'), 8),"..
"(1098, (select id from catalogo where sku = '481118800113'), 8),"..
"(1099, (select id from catalogo where sku = '481118800116'), 8),"..
"(1100, (select id from catalogo where sku = '481118800171'), 8),"..
"(1101, (select id from catalogo where sku = '481118800173'), 8),"..
"(1102, (select id from catalogo where sku = '4811406050'), 2),"..
"(1103, (select id from catalogo where sku = '4811406050'), 3),"..
"(1104, (select id from catalogo where sku = '4811406050'), 4),"..
"(1105, (select id from catalogo where sku = '4811406050'), 5),"..
"(1106, (select id from catalogo where sku = '4811406050'), 6),"..
"(1107, (select id from catalogo where sku = '4811406051'), 2),"..
"(1108, (select id from catalogo where sku = '4811406051'), 3),"..
"(1109, (select id from catalogo where sku = '4811406051'), 4),"..
"(1110, (select id from catalogo where sku = '4811406051'), 5),"..
"(1111, (select id from catalogo where sku = '4811406051'), 6),"..
"(1112, (select id from catalogo where sku = '4811564001'), 2),"..
"(1113, (select id from catalogo where sku = '4811564001'), 3),"..
"(1114, (select id from catalogo where sku = '4811564001'), 4),"..
"(1115, (select id from catalogo where sku = '4811564001'), 5),"..
"(1116, (select id from catalogo where sku = '4811564002'), 2),"..
"(1117, (select id from catalogo where sku = '4811564002'), 3),"..
"(1118, (select id from catalogo where sku = '4811564002'), 4),"..
"(1119, (select id from catalogo where sku = '4811564002'), 5),"..
"(1120, (select id from catalogo where sku = '4811564003'), 2),"..
"(1121, (select id from catalogo where sku = '4811564003'), 3),"..
"(1122, (select id from catalogo where sku = '4811564003'), 4),"..
"(1123, (select id from catalogo where sku = '4811564003'), 5),"..
"(1124, (select id from catalogo where sku = '4811564004'), 2),"..
"(1125, (select id from catalogo where sku = '4811564004'), 3),"..
"(1126, (select id from catalogo where sku = '4811564004'), 4),"..
"(1127, (select id from catalogo where sku = '4811564004'), 5),"..
"(1128, (select id from catalogo where sku = '4811564005'), 2),"..
"(1129, (select id from catalogo where sku = '4811564005'), 3),"..
"(1130, (select id from catalogo where sku = '4811564005'), 4),"..
"(1131, (select id from catalogo where sku = '4811564005'), 5),"..
"(1132, (select id from catalogo where sku = '4811564006'), 2),"..
"(1133, (select id from catalogo where sku = '4811564006'), 3),"..
"(1134, (select id from catalogo where sku = '4811564006'), 4),"..
"(1135, (select id from catalogo where sku = '4811564006'), 5),"..
"(1136, (select id from catalogo where sku = '4811564007'), 2),"..
"(1137, (select id from catalogo where sku = '4811564007'), 3),"..
"(1138, (select id from catalogo where sku = '4811564007'), 4),"..
"(1139, (select id from catalogo where sku = '4811564007'), 5),"..
"(1140, (select id from catalogo where sku = '4811564008'), 2),"..
"(1141, (select id from catalogo where sku = '4811564008'), 3),"..
"(1142, (select id from catalogo where sku = '4811564008'), 4),"..
"(1143, (select id from catalogo where sku = '4811564008'), 5),"..
"(1144, (select id from catalogo where sku = '4811564009'), 2),"..
"(1145, (select id from catalogo where sku = '4811564009'), 3),"..
"(1146, (select id from catalogo where sku = '4811564009'), 4),"..
"(1147, (select id from catalogo where sku = '4811564009'), 5),"..
"(1148, (select id from catalogo where sku = '4811564010'), 2),"..
"(1149, (select id from catalogo where sku = '4811564010'), 3),"..
"(1150, (select id from catalogo where sku = '4811564010'), 4),"..
"(1151, (select id from catalogo where sku = '4811564010'), 5),"..
"(1152, (select id from catalogo where sku = '4811564011'), 2),"..
"(1153, (select id from catalogo where sku = '4811564011'), 3),"..
"(1154, (select id from catalogo where sku = '4811564011'), 4),"..
"(1155, (select id from catalogo where sku = '4811564011'), 5),"..
"(1156, (select id from catalogo where sku = '4811564012'), 2),"..
"(1157, (select id from catalogo where sku = '4811564012'), 3),"..
"(1158, (select id from catalogo where sku = '4811564012'), 4),"..
"(1159, (select id from catalogo where sku = '4811564012'), 5),"..
"(1160, (select id from catalogo where sku = '4811564013'), 2),"..
"(1161, (select id from catalogo where sku = '4811564013'), 3),"..
"(1162, (select id from catalogo where sku = '4811564013'), 4),"..
"(1163, (select id from catalogo where sku = '4811564013'), 5),"..
"(1164, (select id from catalogo where sku = '4811584001'), 2),"..
"(1165, (select id from catalogo where sku = '4811584001'), 3),"..
"(1166, (select id from catalogo where sku = '4811584001'), 4),"..
"(1167, (select id from catalogo where sku = '4811584001'), 5),"..
"(1168, (select id from catalogo where sku = '4811584002'), 2),"..
"(1169, (select id from catalogo where sku = '4811584002'), 3),"..
"(1170, (select id from catalogo where sku = '4811584002'), 4),"..
"(1171, (select id from catalogo where sku = '4811584002'), 5),"..
"(1172, (select id from catalogo where sku = '4811586001'), 2),"..
"(1173, (select id from catalogo where sku = '4811586001'), 3),"..
"(1174, (select id from catalogo where sku = '4811586001'), 4),"..
"(1175, (select id from catalogo where sku = '4811586001'), 5),"..
"(1176, (select id from catalogo where sku = '4811586001E'), 6),"..
"(1177, (select id from catalogo where sku = '4811586002'), 2),"..
"(1178, (select id from catalogo where sku = '4811586002'), 3),"..
"(1179, (select id from catalogo where sku = '4811586002'), 4),"..
"(1180, (select id from catalogo where sku = '4811586002'), 5),"..
"(1181, (select id from catalogo where sku = '4811586002E'), 6),"..
"(1182, (select id from catalogo where sku = '4811586003'), 2),"..
"(1183, (select id from catalogo where sku = '4811586003'), 3),"..
"(1184, (select id from catalogo where sku = '4811586003'), 4),"..
"(1185, (select id from catalogo where sku = '4811586003'), 5),"..
"(1186, (select id from catalogo where sku = '4811586003E'), 6),"..
"(1187, (select id from catalogo where sku = '4811586004'), 2),"..
"(1188, (select id from catalogo where sku = '4811586004'), 3),"..
"(1189, (select id from catalogo where sku = '4811586004'), 4),"..
"(1190, (select id from catalogo where sku = '4811586004'), 5),"..
"(1191, (select id from catalogo where sku = '4811586004E'), 6),"..
"(1192, (select id from catalogo where sku = '4811586005'), 2),"..
"(1193, (select id from catalogo where sku = '4811586005'), 3),"..
"(1194, (select id from catalogo where sku = '4811586005'), 4),"..
"(1195, (select id from catalogo where sku = '4811586005'), 5),"..
"(1196, (select id from catalogo where sku = '4811586005E'), 6),"..
"(1197, (select id from catalogo where sku = '4811586006'), 2),"..
"(1198, (select id from catalogo where sku = '4811586006'), 3),"..
"(1199, (select id from catalogo where sku = '4811586006'), 4),"..
"(1200, (select id from catalogo where sku = '4811586006'), 5),"..
"(1201, (select id from catalogo where sku = '4811586007'), 2),"..
"(1202, (select id from catalogo where sku = '4811586007'), 3),"..
"(1203, (select id from catalogo where sku = '4811586007'), 4),"..
"(1204, (select id from catalogo where sku = '4811586007'), 5),"..
"(1205, (select id from catalogo where sku = '4811586008'), 2),"..
"(1206, (select id from catalogo where sku = '4811586008'), 3),"..
"(1207, (select id from catalogo where sku = '4811586008'), 4);"
db:exec( query2 )
--fase 9
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1208, (select id from catalogo where sku = '4811586008'), 5),"..
"(1209, (select id from catalogo where sku = '4811586009'), 2),"..
"(1210, (select id from catalogo where sku = '4811586009'), 3),"..
"(1211, (select id from catalogo where sku = '4811586009'), 4),"..
"(1212, (select id from catalogo where sku = '4811586009'), 5),"..
"(1213, (select id from catalogo where sku = '4811586010'), 2),"..
"(1214, (select id from catalogo where sku = '4811586010'), 3),"..
"(1215, (select id from catalogo where sku = '4811586010'), 4),"..
"(1216, (select id from catalogo where sku = '4811586010'), 5),"..
"(1217, (select id from catalogo where sku = '4811586011'), 2),"..
"(1218, (select id from catalogo where sku = '4811586011'), 3),"..
"(1219, (select id from catalogo where sku = '4811586011'), 4),"..
"(1220, (select id from catalogo where sku = '4811586011'), 5),"..
"(1221, (select id from catalogo where sku = '481176900103'), 8),"..
"(1222, (select id from catalogo where sku = '481176900103-10'), 8),"..
"(1223, (select id from catalogo where sku = '481176900103-11'), 8),"..
"(1224, (select id from catalogo where sku = '481176900103-12'), 8),"..
"(1225, (select id from catalogo where sku = '481176900103-13'), 8),"..
"(1226, (select id from catalogo where sku = '481176900103-26'), 8),"..
"(1227, (select id from catalogo where sku = '481176900103-28'), 8),"..
"(1228, (select id from catalogo where sku = '481176900103-30'), 8),"..
"(1229, (select id from catalogo where sku = '481176900403'), 8),"..
"(1230, (select id from catalogo where sku = '481176900410'), 8),"..
"(1231, (select id from catalogo where sku = '481176900411'), 8),"..
"(1232, (select id from catalogo where sku = '481176900412'), 8),"..
"(1233, (select id from catalogo where sku = '481176900413'), 8),"..
"(1234, (select id from catalogo where sku = '481176900426'), 8),"..
"(1235, (select id from catalogo where sku = '481176900428'), 8),"..
"(1236, (select id from catalogo where sku = '481176900430'), 8),"..
"(1237, (select id from catalogo where sku = '481186800102'), 8),"..
"(1238, (select id from catalogo where sku = '481186800103'), 8),"..
"(1239, (select id from catalogo where sku = '481186800104'), 8),"..
"(1240, (select id from catalogo where sku = '481186800111'), 8),"..
"(1241, (select id from catalogo where sku = '481186800113'), 8),"..
"(1242, (select id from catalogo where sku = '481186800116'), 8),"..
"(1243, (select id from catalogo where sku = '481186800129'), 8),"..
"(1244, (select id from catalogo where sku = '481186800137'), 8),"..
"(1245, (select id from catalogo where sku = '4814006001'), 2),"..
"(1246, (select id from catalogo where sku = '4814006001'), 3),"..
"(1247, (select id from catalogo where sku = '4814006001'), 4),"..
"(1248, (select id from catalogo where sku = '4814006001'), 5),"..
"(1249, (select id from catalogo where sku = '4814006002'), 2),"..
"(1250, (select id from catalogo where sku = '4814006002'), 3),"..
"(1251, (select id from catalogo where sku = '4814006002'), 4),"..
"(1252, (select id from catalogo where sku = '4814006002'), 5),"..
"(1253, (select id from catalogo where sku = '4814008009'), 2),"..
"(1254, (select id from catalogo where sku = '4814008009'), 3),"..
"(1255, (select id from catalogo where sku = '4814008009'), 4),"..
"(1256, (select id from catalogo where sku = '4814008009'), 5),"..
"(1257, (select id from catalogo where sku = '4814008009'), 6),"..
"(1258, (select id from catalogo where sku = '4814008015'), 2),"..
"(1259, (select id from catalogo where sku = '4814008015'), 3),"..
"(1260, (select id from catalogo where sku = '4814008015'), 4),"..
"(1261, (select id from catalogo where sku = '4814008015'), 5),"..
"(1262, (select id from catalogo where sku = '4814008015'), 6),"..
"(1263, (select id from catalogo where sku = '4814008026'), 2),"..
"(1264, (select id from catalogo where sku = '4814008026'), 3),"..
"(1265, (select id from catalogo where sku = '4814008026'), 4),"..
"(1266, (select id from catalogo where sku = '4814008026'), 5),"..
"(1267, (select id from catalogo where sku = '4814008026'), 6),"..
"(1268, (select id from catalogo where sku = '4814008027'), 2),"..
"(1269, (select id from catalogo where sku = '4814008027'), 3),"..
"(1270, (select id from catalogo where sku = '4814008027'), 4),"..
"(1271, (select id from catalogo where sku = '4814008027'), 5),"..
"(1272, (select id from catalogo where sku = '4814008027'), 6),"..
"(1273, (select id from catalogo where sku = '4814008033'), 2),"..
"(1274, (select id from catalogo where sku = '4814008033'), 3),"..
"(1275, (select id from catalogo where sku = '4814008033'), 4),"..
"(1276, (select id from catalogo where sku = '4814008033'), 5),"..
"(1277, (select id from catalogo where sku = '4814008033'), 6),"..
"(1278, (select id from catalogo where sku = '4814008036'), 2),"..
"(1279, (select id from catalogo where sku = '4814008036'), 3),"..
"(1280, (select id from catalogo where sku = '4814008036'), 4),"..
"(1281, (select id from catalogo where sku = '4814008036'), 5),"..
"(1282, (select id from catalogo where sku = '4814008036'), 6),"..
"(1283, (select id from catalogo where sku = '4814008038'), 2),"..
"(1284, (select id from catalogo where sku = '4814008038'), 3),"..
"(1285, (select id from catalogo where sku = '4814008038'), 4),"..
"(1286, (select id from catalogo where sku = '4814008038'), 5),"..
"(1287, (select id from catalogo where sku = '4814008038'), 6),"..
"(1288, (select id from catalogo where sku = '4814008039'), 2),"..
"(1289, (select id from catalogo where sku = '4814008039'), 3),"..
"(1290, (select id from catalogo where sku = '4814008039'), 4),"..
"(1291, (select id from catalogo where sku = '4814008039'), 5),"..
"(1292, (select id from catalogo where sku = '4814008039'), 6),"..
"(1293, (select id from catalogo where sku = '4814008041'), 2),"..
"(1294, (select id from catalogo where sku = '4814008041'), 3),"..
"(1295, (select id from catalogo where sku = '4814008041'), 4),"..
"(1296, (select id from catalogo where sku = '4814008041'), 5),"..
"(1297, (select id from catalogo where sku = '4814008041'), 6),"..
"(1298, (select id from catalogo where sku = '4814008044'), 2),"..
"(1299, (select id from catalogo where sku = '4814008044'), 3),"..
"(1300, (select id from catalogo where sku = '4814008044'), 4),"..
"(1301, (select id from catalogo where sku = '4814008044'), 5),"..
"(1302, (select id from catalogo where sku = '4814008044'), 6),"..
"(1303, (select id from catalogo where sku = '4814008045'), 2),"..
"(1304, (select id from catalogo where sku = '4814008045'), 3),"..
"(1305, (select id from catalogo where sku = '4814008045'), 4),"..
"(1306, (select id from catalogo where sku = '4814008045'), 5),"..
"(1307, (select id from catalogo where sku = '4814008045'), 6),"..
"(1308, (select id from catalogo where sku = '4814008047'), 2),"..
"(1309, (select id from catalogo where sku = '4814008047'), 3),"..
"(1310, (select id from catalogo where sku = '4814008047'), 4),"..
"(1311, (select id from catalogo where sku = '4814008047'), 5),"..
"(1312, (select id from catalogo where sku = '4814008047'), 6),"..
"(1313, (select id from catalogo where sku = '4814008049'), 2),"..
"(1314, (select id from catalogo where sku = '4814008049'), 3),"..
"(1315, (select id from catalogo where sku = '4814008049'), 4),"..
"(1316, (select id from catalogo where sku = '4814008049'), 5),"..
"(1317, (select id from catalogo where sku = '4814008049'), 6),"..
"(1318, (select id from catalogo where sku = '4814008050'), 2),"..
"(1319, (select id from catalogo where sku = '4814008050'), 3),"..
"(1320, (select id from catalogo where sku = '4814008050'), 4),"..
"(1321, (select id from catalogo where sku = '4814008050'), 5),"..
"(1322, (select id from catalogo where sku = '4814008050'), 6),"..
"(1323, (select id from catalogo where sku = '4814008051'), 2),"..
"(1324, (select id from catalogo where sku = '4814008051'), 3),"..
"(1325, (select id from catalogo where sku = '4814008051'), 4),"..
"(1326, (select id from catalogo where sku = '4814008051'), 5),"..
"(1327, (select id from catalogo where sku = '4814008051'), 6),"..
"(1328, (select id from catalogo where sku = '4814008059'), 2),"..
"(1329, (select id from catalogo where sku = '4814008059'), 3),"..
"(1330, (select id from catalogo where sku = '4814008059'), 4),"..
"(1331, (select id from catalogo where sku = '4814008059'), 5),"..
"(1332, (select id from catalogo where sku = '4814008059'), 6),"..
"(1333, (select id from catalogo where sku = '4814008060'), 2),"..
"(1334, (select id from catalogo where sku = '4814008060'), 3),"..
"(1335, (select id from catalogo where sku = '4814008060'), 4),"..
"(1336, (select id from catalogo where sku = '4814008060'), 5),"..
"(1337, (select id from catalogo where sku = '4814008060'), 6),"..
"(1338, (select id from catalogo where sku = '4814008063'), 2),"..
"(1339, (select id from catalogo where sku = '4814008063'), 3),"..
"(1340, (select id from catalogo where sku = '4814008063'), 4),"..
"(1341, (select id from catalogo where sku = '4814008063'), 5),"..
"(1342, (select id from catalogo where sku = '4814008063'), 6),"..
"(1343, (select id from catalogo where sku = '4814008065'), 2),"..
"(1344, (select id from catalogo where sku = '4814008065'), 3),"..
"(1345, (select id from catalogo where sku = '4814008065'), 4),"..
"(1346, (select id from catalogo where sku = '4814008065'), 5),"..
"(1347, (select id from catalogo where sku = '4814008065'), 6),"..
"(1348, (select id from catalogo where sku = '4814008067'), 2),"..
"(1349, (select id from catalogo where sku = '4814008067'), 3),"..
"(1350, (select id from catalogo where sku = '4814008067'), 4),"..
"(1351, (select id from catalogo where sku = '4814008067'), 5),"..
"(1352, (select id from catalogo where sku = '4814008067'), 6),"..
"(1353, (select id from catalogo where sku = '4814008068'), 2),"..
"(1354, (select id from catalogo where sku = '4814008068'), 3),"..
"(1355, (select id from catalogo where sku = '4814008068'), 4),"..
"(1356, (select id from catalogo where sku = '4814008068'), 5),"..
"(1357, (select id from catalogo where sku = '4814008068'), 6),"..
"(1358, (select id from catalogo where sku = '4814008109'), 2);"
db:exec( query2 )
--fase 10
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1359, (select id from catalogo where sku = '4814008109'), 3),"..
"(1360, (select id from catalogo where sku = '4814008109'), 4),"..
"(1361, (select id from catalogo where sku = '4814008109'), 5),"..
"(1362, (select id from catalogo where sku = '4814008109'), 6),"..
"(1363, (select id from catalogo where sku = '4814008126'), 2),"..
"(1364, (select id from catalogo where sku = '4814008126'), 3),"..
"(1365, (select id from catalogo where sku = '4814008126'), 4),"..
"(1366, (select id from catalogo where sku = '4814008126'), 5),"..
"(1367, (select id from catalogo where sku = '4814008126'), 6),"..
"(1368, (select id from catalogo where sku = '4814008127'), 2),"..
"(1369, (select id from catalogo where sku = '4814008127'), 3),"..
"(1370, (select id from catalogo where sku = '4814008127'), 4),"..
"(1371, (select id from catalogo where sku = '4814008127'), 5),"..
"(1372, (select id from catalogo where sku = '4814008127'), 6),"..
"(1373, (select id from catalogo where sku = '4814008133'), 2),"..
"(1374, (select id from catalogo where sku = '4814008133'), 3),"..
"(1375, (select id from catalogo where sku = '4814008133'), 4),"..
"(1376, (select id from catalogo where sku = '4814008133'), 5),"..
"(1377, (select id from catalogo where sku = '4814008133'), 6),"..
"(1378, (select id from catalogo where sku = '4814008136'), 2),"..
"(1379, (select id from catalogo where sku = '4814008136'), 3),"..
"(1380, (select id from catalogo where sku = '4814008136'), 4),"..
"(1381, (select id from catalogo where sku = '4814008136'), 5),"..
"(1382, (select id from catalogo where sku = '4814008136'), 6),"..
"(1383, (select id from catalogo where sku = '4814008138'), 2),"..
"(1384, (select id from catalogo where sku = '4814008138'), 3),"..
"(1385, (select id from catalogo where sku = '4814008138'), 4),"..
"(1386, (select id from catalogo where sku = '4814008138'), 5),"..
"(1387, (select id from catalogo where sku = '4814008138'), 6),"..
"(1388, (select id from catalogo where sku = '4814008149'), 2),"..
"(1389, (select id from catalogo where sku = '4814008149'), 3),"..
"(1390, (select id from catalogo where sku = '4814008149'), 4),"..
"(1391, (select id from catalogo where sku = '4814008149'), 5),"..
"(1392, (select id from catalogo where sku = '4814008149'), 6),"..
"(1393, (select id from catalogo where sku = '4814008150'), 2),"..
"(1394, (select id from catalogo where sku = '4814008150'), 3),"..
"(1395, (select id from catalogo where sku = '4814008150'), 4),"..
"(1396, (select id from catalogo where sku = '4814008150'), 5),"..
"(1397, (select id from catalogo where sku = '4814008150'), 6),"..
"(1398, (select id from catalogo where sku = '4814008160'), 2),"..
"(1399, (select id from catalogo where sku = '4814008160'), 3),"..
"(1400, (select id from catalogo where sku = '4814008160'), 4),"..
"(1401, (select id from catalogo where sku = '4814008160'), 5),"..
"(1402, (select id from catalogo where sku = '4814008160'), 6),"..
"(1403, (select id from catalogo where sku = '4814008163'), 2),"..
"(1404, (select id from catalogo where sku = '4814008163'), 3),"..
"(1405, (select id from catalogo where sku = '4814008163'), 4),"..
"(1406, (select id from catalogo where sku = '4814008163'), 5),"..
"(1407, (select id from catalogo where sku = '4814008163'), 6),"..
"(1408, (select id from catalogo where sku = '4814008165'), 2),"..
"(1409, (select id from catalogo where sku = '4814008165'), 3),"..
"(1410, (select id from catalogo where sku = '4814008165'), 4),"..
"(1411, (select id from catalogo where sku = '4814008165'), 5),"..
"(1412, (select id from catalogo where sku = '4814008165'), 6),"..
"(1413, (select id from catalogo where sku = '4814008167'), 2),"..
"(1414, (select id from catalogo where sku = '4814008167'), 3),"..
"(1415, (select id from catalogo where sku = '4814008167'), 4),"..
"(1416, (select id from catalogo where sku = '4814008167'), 5),"..
"(1417, (select id from catalogo where sku = '4814008167'), 6),"..
"(1418, (select id from catalogo where sku = '4814008168'), 2),"..
"(1419, (select id from catalogo where sku = '4814008168'), 3),"..
"(1420, (select id from catalogo where sku = '4814008168'), 4),"..
"(1421, (select id from catalogo where sku = '4814008168'), 5),"..
"(1422, (select id from catalogo where sku = '4814008168'), 6),"..
"(1423, (select id from catalogo where sku = '4814008209'), 2),"..
"(1424, (select id from catalogo where sku = '4814008209'), 3),"..
"(1425, (select id from catalogo where sku = '4814008209'), 4),"..
"(1426, (select id from catalogo where sku = '4814008209'), 5),"..
"(1427, (select id from catalogo where sku = '4814008209'), 6),"..
"(1428, (select id from catalogo where sku = '4814008226'), 2),"..
"(1429, (select id from catalogo where sku = '4814008226'), 3),"..
"(1430, (select id from catalogo where sku = '4814008226'), 4),"..
"(1431, (select id from catalogo where sku = '4814008226'), 5),"..
"(1432, (select id from catalogo where sku = '4814008226'), 6),"..
"(1433, (select id from catalogo where sku = '4814008233'), 2),"..
"(1434, (select id from catalogo where sku = '4814008233'), 3),"..
"(1435, (select id from catalogo where sku = '4814008233'), 4),"..
"(1436, (select id from catalogo where sku = '4814008233'), 5),"..
"(1437, (select id from catalogo where sku = '4814008233'), 6),"..
"(1438, (select id from catalogo where sku = '4814008236'), 2),"..
"(1439, (select id from catalogo where sku = '4814008236'), 3),"..
"(1440, (select id from catalogo where sku = '4814008236'), 4),"..
"(1441, (select id from catalogo where sku = '4814008236'), 5),"..
"(1442, (select id from catalogo where sku = '4814008236'), 6),"..
"(1443, (select id from catalogo where sku = '4814008267'), 2),"..
"(1444, (select id from catalogo where sku = '4814008267'), 3),"..
"(1445, (select id from catalogo where sku = '4814008267'), 4),"..
"(1446, (select id from catalogo where sku = '4814008267'), 5),"..
"(1447, (select id from catalogo where sku = '4814008267'), 6),"..
"(1448, (select id from catalogo where sku = '4814008309'), 2),"..
"(1449, (select id from catalogo where sku = '4814008309'), 3),"..
"(1450, (select id from catalogo where sku = '4814008309'), 4),"..
"(1451, (select id from catalogo where sku = '4814008309'), 5),"..
"(1452, (select id from catalogo where sku = '4814008309'), 6),"..
"(1453, (select id from catalogo where sku = '4814008326'), 2),"..
"(1454, (select id from catalogo where sku = '4814008326'), 3),"..
"(1455, (select id from catalogo where sku = '4814008326'), 4),"..
"(1456, (select id from catalogo where sku = '4814008326'), 5),"..
"(1457, (select id from catalogo where sku = '4814008326'), 6),"..
"(1458, (select id from catalogo where sku = '4814008333'), 2),"..
"(1459, (select id from catalogo where sku = '4814008333'), 3),"..
"(1460, (select id from catalogo where sku = '4814008333'), 4),"..
"(1461, (select id from catalogo where sku = '4814008333'), 5),"..
"(1462, (select id from catalogo where sku = '4814008333'), 6),"..
"(1463, (select id from catalogo where sku = '4814008336'), 2),"..
"(1464, (select id from catalogo where sku = '4814008336'), 3),"..
"(1465, (select id from catalogo where sku = '4814008336'), 4),"..
"(1466, (select id from catalogo where sku = '4814008336'), 5),"..
"(1467, (select id from catalogo where sku = '4814008336'), 6),"..
"(1468, (select id from catalogo where sku = '4814008367'), 2),"..
"(1469, (select id from catalogo where sku = '4814008367'), 3),"..
"(1470, (select id from catalogo where sku = '4814008367'), 4),"..
"(1471, (select id from catalogo where sku = '4814008367'), 5),"..
"(1472, (select id from catalogo where sku = '4814008367'), 6),"..
"(1473, (select id from catalogo where sku = '4814203070'), 2),"..
"(1474, (select id from catalogo where sku = '4814203070'), 3),"..
"(1475, (select id from catalogo where sku = '4814203070'), 4),"..
"(1476, (select id from catalogo where sku = '4814203070'), 5),"..
"(1477, (select id from catalogo where sku = '4814203070'), 6),"..
"(1478, (select id from catalogo where sku = '4814203071'), 2),"..
"(1479, (select id from catalogo where sku = '4814203071'), 3),"..
"(1480, (select id from catalogo where sku = '4814203071'), 4),"..
"(1481, (select id from catalogo where sku = '4814203071'), 5),"..
"(1482, (select id from catalogo where sku = '4814203071'), 6),"..
"(1483, (select id from catalogo where sku = '4814203072'), 2),"..
"(1484, (select id from catalogo where sku = '4814203072'), 3),"..
"(1485, (select id from catalogo where sku = '4814203072'), 4),"..
"(1486, (select id from catalogo where sku = '4814203072'), 5),"..
"(1487, (select id from catalogo where sku = '4814203072'), 6),"..
"(1488, (select id from catalogo where sku = '48142030730'), 2),"..
"(1489, (select id from catalogo where sku = '48142030730'), 3),"..
"(1490, (select id from catalogo where sku = '48142030730'), 4),"..
"(1491, (select id from catalogo where sku = '48142030730'), 5),"..
"(1492, (select id from catalogo where sku = '48142030730'), 6),"..
"(1493, (select id from catalogo where sku = '4814203101'), 2),"..
"(1494, (select id from catalogo where sku = '4814203101'), 3),"..
"(1495, (select id from catalogo where sku = '4814203101'), 4),"..
"(1496, (select id from catalogo where sku = '4814203101'), 5),"..
"(1497, (select id from catalogo where sku = '4814203101'), 6),"..
"(1498, (select id from catalogo where sku = '4814203102'), 2),"..
"(1499, (select id from catalogo where sku = '4814203102'), 3),"..
"(1500, (select id from catalogo where sku = '4814203102'), 4),"..
"(1501, (select id from catalogo where sku = '4814203102'), 5),"..
"(1502, (select id from catalogo where sku = '4814203102'), 6),"..
"(1503, (select id from catalogo where sku = '4814203103'), 2),"..
"(1504, (select id from catalogo where sku = '4814203103'), 3),"..
"(1505, (select id from catalogo where sku = '4814203103'), 4),"..
"(1506, (select id from catalogo where sku = '4814203103'), 5),"..
"(1507, (select id from catalogo where sku = '4814203103'), 6),"..
"(1508, (select id from catalogo where sku = '4814203105'), 2),"..
"(1509, (select id from catalogo where sku = '4814203105'), 3);"
db:exec( query2 )
--fase 11
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1510, (select id from catalogo where sku = '4814203105'), 4),"..
"(1511, (select id from catalogo where sku = '4814203105'), 5),"..
"(1512, (select id from catalogo where sku = '4814203105'), 6),"..
"(1513, (select id from catalogo where sku = 'AZUCOA00102'), 2),"..
"(1514, (select id from catalogo where sku = 'AZUCOA00102'), 3),"..
"(1515, (select id from catalogo where sku = 'AZUCOA00102'), 4),"..
"(1516, (select id from catalogo where sku = 'AZUCOA00102'), 5),"..
"(1517, (select id from catalogo where sku = 'AZUCOA00102-05'), 2),"..
"(1518, (select id from catalogo where sku = 'AZUCOA00102-05'), 3),"..
"(1519, (select id from catalogo where sku = 'AZUCOA00102-05'), 4),"..
"(1520, (select id from catalogo where sku = 'AZUCOA00102-05'), 5),"..
"(1521, (select id from catalogo where sku = 'AZUCOA00110'), 2),"..
"(1522, (select id from catalogo where sku = 'AZUCOA00110'), 3),"..
"(1523, (select id from catalogo where sku = 'AZUCOA00110'), 4),"..
"(1524, (select id from catalogo where sku = 'AZUCOA00110'), 5),"..
"(1525, (select id from catalogo where sku = 'AZUCOA00111'), 2),"..
"(1526, (select id from catalogo where sku = 'AZUCOA00111'), 3),"..
"(1527, (select id from catalogo where sku = 'AZUCOA00111'), 4),"..
"(1528, (select id from catalogo where sku = 'AZUCOA00111'), 5),"..
"(1529, (select id from catalogo where sku = 'AZUCOA00112'), 2),"..
"(1530, (select id from catalogo where sku = 'AZUCOA00112'), 3),"..
"(1531, (select id from catalogo where sku = 'AZUCOA00112'), 4),"..
"(1532, (select id from catalogo where sku = 'AZUCOA00112'), 5),"..
"(1533, (select id from catalogo where sku = 'AZUCOA001XXL02'), 6),"..
"(1534, (select id from catalogo where sku = 'AZUCOA001XXL05'), 6),"..
"(1535, (select id from catalogo where sku = 'AZUCOA001XXL10'), 6),"..
"(1536, (select id from catalogo where sku = 'AZUCOA001XXL11'), 6),"..
"(1537, (select id from catalogo where sku = 'AZUCOA001XXL12'), 6),"..
"(1538, (select id from catalogo where sku = 'AZUGDKMFI03'), 8),"..
"(1539, (select id from catalogo where sku = 'AZUGDKMFI11'), 8),"..
"(1540, (select id from catalogo where sku = 'AZUGDKMFI13'), 8),"..
"(1541, (select id from catalogo where sku = 'AZUGDKMFI16'), 8),"..
"(1542, (select id from catalogo where sku = 'AZUGDKNBA03'), 8),"..
"(1543, (select id from catalogo where sku = 'AZUGMBCAM13'), 8),"..
"(1544, (select id from catalogo where sku = 'AZUGMBCAM26'), 8),"..
"(1545, (select id from catalogo where sku = 'AZUGMBCAM32'), 8),"..
"(1546, (select id from catalogo where sku = 'AZUGMBDAM04'), 8),"..
"(1547, (select id from catalogo where sku = 'AZUGMBDAM12'), 8),"..
"(1548, (select id from catalogo where sku = 'AZUGMBDAM17'), 8),"..
"(1549, (select id from catalogo where sku = 'AZUGMBDAM18'), 8),"..
"(1550, (select id from catalogo where sku = 'AZUGMBDAM19'), 8),"..
"(1551, (select id from catalogo where sku = 'AZUGMBDAM29'), 8),"..
"(1552, (select id from catalogo where sku = 'AZUGMBDAM40'), 8),"..
"(1553, (select id from catalogo where sku = 'AZUGMBDAM41'), 8),"..
"(1554, (select id from catalogo where sku = 'AZUGMBDES02'), 8),"..
"(1555, (select id from catalogo where sku = 'AZUGMBDES05'), 8),"..
"(1556, (select id from catalogo where sku = 'AZUGMBDES06'), 8),"..
"(1557, (select id from catalogo where sku = 'AZUGMBDES10'), 8),"..
"(1558, (select id from catalogo where sku = 'AZUGMBDES11'), 8),"..
"(1559, (select id from catalogo where sku = 'AZUGMBDES12'), 8),"..
"(1560, (select id from catalogo where sku = 'AZUGMBDES13'), 8),"..
"(1561, (select id from catalogo where sku = 'AZUGMBDES15'), 8),"..
"(1562, (select id from catalogo where sku = 'AZUGMBDES21'), 8),"..
"(1563, (select id from catalogo where sku = 'AZUGMBDES25'), 8),"..
"(1564, (select id from catalogo where sku = 'AZUGMBDES26'), 8),"..
"(1565, (select id from catalogo where sku = 'AZUGMBDES28'), 8),"..
"(1566, (select id from catalogo where sku = 'AZUGMBDES30'), 8),"..
"(1567, (select id from catalogo where sku = 'AZUGMBDES32'), 8),"..
"(1568, (select id from catalogo where sku = 'AZUGMBDES34'), 8),"..
"(1569, (select id from catalogo where sku = 'AZUGMBDES35'), 8),"..
"(1570, (select id from catalogo where sku = 'AZUGMBNIÑ02'), 8),"..
"(1571, (select id from catalogo where sku = 'AZUGMBNIÑ10'), 8),"..
"(1572, (select id from catalogo where sku = 'AZUGMBNIÑ11'), 8),"..
"(1573, (select id from catalogo where sku = 'AZUGMBNIÑ12'), 8),"..
"(1574, (select id from catalogo where sku = 'AZUGMBNIÑ15'), 8),"..
"(1575, (select id from catalogo where sku = 'AZUGMBNMA62'), 8),"..
"(1576, (select id from catalogo where sku = 'AZUGMBNMA63'), 8),"..
"(1577, (select id from catalogo where sku = 'AZUGMBNMA64'), 8),"..
"(1578, (select id from catalogo where sku = 'AZUGMBNMA65'), 8),"..
"(1579, (select id from catalogo where sku = 'AZUGMBOXF11'), 8),"..
"(1580, (select id from catalogo where sku = 'AZUGMBOXF28'), 8),"..
"(1581, (select id from catalogo where sku = 'AZUGMBOXF37'), 8),"..
"(1582, (select id from catalogo where sku = 'AZUGMBSAN02'), 8),"..
"(1583, (select id from catalogo where sku = 'AZUGMBSAN03'), 8),"..
"(1584, (select id from catalogo where sku = 'AZUGMBSAN05'), 8),"..
"(1585, (select id from catalogo where sku = 'AZUGMBSAN06'), 8),"..
"(1586, (select id from catalogo where sku = 'AZUGMBSAN07'), 8),"..
"(1587, (select id from catalogo where sku = 'AZUGMBSAN11'), 8),"..
"(1588, (select id from catalogo where sku = 'AZUGMBSAN13'), 8),"..
"(1589, (select id from catalogo where sku = 'AZUGMBSAN20'), 8),"..
"(1590, (select id from catalogo where sku = 'AZUGMBSAN22'), 8),"..
"(1591, (select id from catalogo where sku = 'AZUGMBSAN30'), 8),"..
"(1592, (select id from catalogo where sku = 'AZUGMBSAN32'), 8),"..
"(1593, (select id from catalogo where sku = 'AZUGMBSAN33'), 8),"..
"(1594, (select id from catalogo where sku = 'AZUGMBSAN36'), 8),"..
"(1595, (select id from catalogo where sku = 'AZUGMBSAN39'), 8),"..
"(1596, (select id from catalogo where sku = 'AZUGMBSAN43'), 8),"..
"(1597, (select id from catalogo where sku = 'AZUGMBSAN45'), 8),"..
"(1598, (select id from catalogo where sku = 'AZUGMBSAN49'), 8),"..
"(1599, (select id from catalogo where sku = 'BAPGDKBAS40'), 8),"..
"(1600, (select id from catalogo where sku = 'BAPGMBDES04'), 8),"..
"(1601, (select id from catalogo where sku = 'BAPGMBDES05'), 8),"..
"(1602, (select id from catalogo where sku = 'BAPGMBDES06'), 8),"..
"(1603, (select id from catalogo where sku = 'BAPGMBDES10'), 8),"..
"(1604, (select id from catalogo where sku = 'BAPGMBDES11'), 8),"..
"(1605, (select id from catalogo where sku = 'BAPGMBDES12'), 8),"..
"(1606, (select id from catalogo where sku = 'BAPGMBDES13'), 8),"..
"(1607, (select id from catalogo where sku = 'BAPGMBDES15'), 8),"..
"(1608, (select id from catalogo where sku = 'BAPGMBDES16'), 8),"..
"(1609, (select id from catalogo where sku = 'BAPGMBDES21'), 8),"..
"(1610, (select id from catalogo where sku = 'BAPGMBDES25'), 8),"..
"(1611, (select id from catalogo where sku = 'BAPGMBDES26'), 8),"..
"(1612, (select id from catalogo where sku = 'BAPGMBDES28'), 8),"..
"(1613, (select id from catalogo where sku = 'BAPGMBDES30'), 8),"..
"(1614, (select id from catalogo where sku = 'BAPGMBDES32'), 8),"..
"(1615, (select id from catalogo where sku = 'BAPGMBDES34'), 8),"..
"(1616, (select id from catalogo where sku = 'BAPGMBDES35'), 8),"..
"(1617, (select id from catalogo where sku = 'BAPGMBDES37'), 8),"..
"(1618, (select id from catalogo where sku = 'BAPGMBSAN02'), 8),"..
"(1619, (select id from catalogo where sku = 'BAPGMBSAN03'), 8),"..
"(1620, (select id from catalogo where sku = 'BAPGMBSAN05'), 8),"..
"(1621, (select id from catalogo where sku = 'BAPGMBSAN06'), 8),"..
"(1622, (select id from catalogo where sku = 'BAPGMBSAN07'), 8),"..
"(1623, (select id from catalogo where sku = 'BAPGMBSAN11'), 8),"..
"(1624, (select id from catalogo where sku = 'BAPGMBSAN13'), 8),"..
"(1625, (select id from catalogo where sku = 'BAPGMBSAN20'), 8),"..
"(1626, (select id from catalogo where sku = 'BAPGMBSAN22'), 8),"..
"(1627, (select id from catalogo where sku = 'BAPGMBSAN30'), 8),"..
"(1628, (select id from catalogo where sku = 'BAPGMBSAN32'), 8),"..
"(1629, (select id from catalogo where sku = 'BAPGMBSAN33'), 8),"..
"(1630, (select id from catalogo where sku = 'BAPGMBSAN36'), 8),"..
"(1631, (select id from catalogo where sku = 'BAPGMBSAN39'), 8),"..
"(1632, (select id from catalogo where sku = 'BAPGMBSAN43'), 8),"..
"(1633, (select id from catalogo where sku = 'BAPGMBSAN45'), 8),"..
"(1634, (select id from catalogo where sku = 'BAPGMBSAN49'), 8),"..
"(1635, (select id from catalogo where sku = 'BAPGMBSAN51'), 8),"..
"(1636, (select id from catalogo where sku = 'BRYGMBNIÑ02'), 8),"..
"(1637, (select id from catalogo where sku = 'BRYGMBNIÑ10'), 8),"..
"(1638, (select id from catalogo where sku = 'BRYGMBNIÑ11'), 8),"..
"(1639, (select id from catalogo where sku = 'BRYGMBNIÑ12'), 8),"..
"(1640, (select id from catalogo where sku = 'BRYGMBNIÑ15'), 8),"..
"(1641, (select id from catalogo where sku = 'CATCOA00510'), 2),"..
"(1642, (select id from catalogo where sku = 'CATCOA00510'), 3),"..
"(1643, (select id from catalogo where sku = 'CATCOA00510'), 4),"..
"(1644, (select id from catalogo where sku = 'CATCOA00510'), 5),"..
"(1645, (select id from catalogo where sku = 'CATCOA00511'), 2),"..
"(1646, (select id from catalogo where sku = 'CATCOA00511'), 3),"..
"(1647, (select id from catalogo where sku = 'CATCOA00511'), 4),"..
"(1648, (select id from catalogo where sku = 'CATCOA00511'), 5),"..
"(1649, (select id from catalogo where sku = 'CATCOA00512'), 2),"..
"(1650, (select id from catalogo where sku = 'CATCOA00512'), 3),"..
"(1651, (select id from catalogo where sku = 'CATCOA00512'), 4),"..
"(1652, (select id from catalogo where sku = 'CATCOA00512'), 5),"..
"(1653, (select id from catalogo where sku = 'CATCOA00515'), 2),"..
"(1654, (select id from catalogo where sku = 'CATCOA00515'), 3),"..
"(1655, (select id from catalogo where sku = 'CATCOA00515'), 4),"..
"(1656, (select id from catalogo where sku = 'CATCOA00515'), 5),"..
"(1657, (select id from catalogo where sku = 'CATCOA00526'), 2),"..
"(1658, (select id from catalogo where sku = 'CATCOA00526'), 3),"..
"(1659, (select id from catalogo where sku = 'CATCOA00526'), 4);"
db:exec( query2 )
--fase 12
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1660, (select id from catalogo where sku = 'CATCOA00526'), 5),"..
"(1661, (select id from catalogo where sku = 'CATCOA00528'), 2),"..
"(1662, (select id from catalogo where sku = 'CATCOA00528'), 3),"..
"(1663, (select id from catalogo where sku = 'CATCOA00528'), 4),"..
"(1664, (select id from catalogo where sku = 'CATCOA00528'), 5),"..
"(1665, (select id from catalogo where sku = 'CATCOA00530'), 2),"..
"(1666, (select id from catalogo where sku = 'CATCOA00530'), 3),"..
"(1667, (select id from catalogo where sku = 'CATCOA00530'), 4),"..
"(1668, (select id from catalogo where sku = 'CATCOA00530'), 5),"..
"(1669, (select id from catalogo where sku = 'CATCOA00532'), 2),"..
"(1670, (select id from catalogo where sku = 'CATCOA00532'), 3),"..
"(1671, (select id from catalogo where sku = 'CATCOA00532'), 4),"..
"(1672, (select id from catalogo where sku = 'CATCOA00532'), 5),"..
"(1673, (select id from catalogo where sku = 'CATCOA005XXL10'), 6),"..
"(1674, (select id from catalogo where sku = 'CATCOA005XXL11'), 6),"..
"(1675, (select id from catalogo where sku = 'CATCOA005XXL12'), 6),"..
"(1676, (select id from catalogo where sku = 'CATCOA005XXL15'), 6),"..
"(1677, (select id from catalogo where sku = 'CATCOA005XXL26'), 6),"..
"(1678, (select id from catalogo where sku = 'CATCOA005XXL28'), 6),"..
"(1679, (select id from catalogo where sku = 'CATCOA005XXL30'), 6),"..
"(1680, (select id from catalogo where sku = 'CATCOA005XXL32'), 6),"..
"(1681, (select id from catalogo where sku = 'CATGMBDAM04'), 8),"..
"(1682, (select id from catalogo where sku = 'CATGMBDAM12'), 8),"..
"(1683, (select id from catalogo where sku = 'CATGMBDAM17'), 8),"..
"(1684, (select id from catalogo where sku = 'CATGMBDAM18'), 8),"..
"(1685, (select id from catalogo where sku = 'CATGMBDAM19'), 8),"..
"(1686, (select id from catalogo where sku = 'CATGMBDAM29'), 8),"..
"(1687, (select id from catalogo where sku = 'CATGMBDAM40'), 8),"..
"(1688, (select id from catalogo where sku = 'CATGMBDAM41'), 8),"..
"(1689, (select id from catalogo where sku = 'CATGMBDES04'), 8),"..
"(1690, (select id from catalogo where sku = 'CATGMBDES05'), 8),"..
"(1691, (select id from catalogo where sku = 'CATGMBDES06'), 8),"..
"(1692, (select id from catalogo where sku = 'CATGMBDES10'), 8),"..
"(1693, (select id from catalogo where sku = 'CATGMBDES11'), 8),"..
"(1694, (select id from catalogo where sku = 'CATGMBDES12'), 8),"..
"(1695, (select id from catalogo where sku = 'CATGMBDES13'), 8),"..
"(1696, (select id from catalogo where sku = 'CATGMBDES15'), 8),"..
"(1697, (select id from catalogo where sku = 'CATGMBDES16'), 8),"..
"(1698, (select id from catalogo where sku = 'CATGMBDES21'), 8),"..
"(1699, (select id from catalogo where sku = 'CATGMBDES25'), 8),"..
"(1700, (select id from catalogo where sku = 'CATGMBDES26'), 8),"..
"(1701, (select id from catalogo where sku = 'CATGMBDES28'), 8),"..
"(1702, (select id from catalogo where sku = 'CATGMBDES30'), 8),"..
"(1703, (select id from catalogo where sku = 'CATGMBDES32'), 8),"..
"(1704, (select id from catalogo where sku = 'CATGMBDES34'), 8),"..
"(1705, (select id from catalogo where sku = 'CATGMBDES35'), 8),"..
"(1706, (select id from catalogo where sku = 'CATGMBDES37'), 8),"..
"(1707, (select id from catalogo where sku = 'CATGMBSAN02'), 8),"..
"(1708, (select id from catalogo where sku = 'CATGMBSAN03'), 8),"..
"(1709, (select id from catalogo where sku = 'CATGMBSAN05'), 8),"..
"(1710, (select id from catalogo where sku = 'CATGMBSAN06'), 8),"..
"(1711, (select id from catalogo where sku = 'CATGMBSAN07'), 8),"..
"(1712, (select id from catalogo where sku = 'CATGMBSAN11'), 8),"..
"(1713, (select id from catalogo where sku = 'CATGMBSAN13'), 8),"..
"(1714, (select id from catalogo where sku = 'CATGMBSAN20'), 8),"..
"(1715, (select id from catalogo where sku = 'CATGMBSAN22'), 8),"..
"(1716, (select id from catalogo where sku = 'CATGMBSAN30'), 8),"..
"(1717, (select id from catalogo where sku = 'CATGMBSAN32'), 8),"..
"(1718, (select id from catalogo where sku = 'CATGMBSAN33'), 8),"..
"(1719, (select id from catalogo where sku = 'CATGMBSAN36'), 8),"..
"(1720, (select id from catalogo where sku = 'CATGMBSAN39'), 8),"..
"(1721, (select id from catalogo where sku = 'CATGMBSAN43'), 8),"..
"(1722, (select id from catalogo where sku = 'CATGMBSAN45'), 8),"..
"(1723, (select id from catalogo where sku = 'CATGMBSAN49'), 8),"..
"(1724, (select id from catalogo where sku = 'CATGMBSAN51'), 8),"..
"(1725, (select id from catalogo where sku = 'CFB-700009'), 1),"..
"(1726, (select id from catalogo where sku = 'CFB-700009'), 2),"..
"(1727, (select id from catalogo where sku = 'CFB-700009'), 3),"..
"(1728, (select id from catalogo where sku = 'CFB-700009'), 4),"..
"(1729, (select id from catalogo where sku = 'CFB-700009'), 5),"..
"(1730, (select id from catalogo where sku = 'CFB-700009'), 6),"..
"(1731, (select id from catalogo where sku = 'CFB-700071'), 1),"..
"(1732, (select id from catalogo where sku = 'CFB-700071'), 2),"..
"(1733, (select id from catalogo where sku = 'CFB-700071'), 3),"..
"(1734, (select id from catalogo where sku = 'CFB-700071'), 4),"..
"(1735, (select id from catalogo where sku = 'CFB-700071'), 5),"..
"(1736, (select id from catalogo where sku = 'CFB-700071'), 6),"..
"(1737, (select id from catalogo where sku = 'CFB-700088'), 1),"..
"(1738, (select id from catalogo where sku = 'CFB-700088'), 2),"..
"(1739, (select id from catalogo where sku = 'CFB-700088'), 3),"..
"(1740, (select id from catalogo where sku = 'CFB-700088'), 4),"..
"(1741, (select id from catalogo where sku = 'CFB-700088'), 5),"..
"(1742, (select id from catalogo where sku = 'CFB-700088'), 6),"..
"(1743, (select id from catalogo where sku = 'CFH-700018'), 1),"..
"(1744, (select id from catalogo where sku = 'CFH-700018'), 2),"..
"(1745, (select id from catalogo where sku = 'CFH-700018'), 3),"..
"(1746, (select id from catalogo where sku = 'CFH-700018'), 4),"..
"(1747, (select id from catalogo where sku = 'CFH-700018'), 5),"..
"(1748, (select id from catalogo where sku = 'CFH-700018'), 6),"..
"(1749, (select id from catalogo where sku = 'CFS-100078'), 1),"..
"(1750, (select id from catalogo where sku = 'CFS-100078'), 2),"..
"(1751, (select id from catalogo where sku = 'CFS-100078'), 3),"..
"(1752, (select id from catalogo where sku = 'CFS-100078'), 4),"..
"(1753, (select id from catalogo where sku = 'CFS-100078'), 5),"..
"(1754, (select id from catalogo where sku = 'CFS-100078'), 6),"..
"(1755, (select id from catalogo where sku = 'CFS-1000Q'), 1),"..
"(1756, (select id from catalogo where sku = 'CFS-1000Q'), 2),"..
"(1757, (select id from catalogo where sku = 'CFS-1000Q'), 3),"..
"(1758, (select id from catalogo where sku = 'CFS-1000Q'), 4),"..
"(1759, (select id from catalogo where sku = 'CFS-1000Q'), 5),"..
"(1760, (select id from catalogo where sku = 'CFS-1000Q'), 6),"..
"(1761, (select id from catalogo where sku = 'CFS-710017'), 1),"..
"(1762, (select id from catalogo where sku = 'CFS-710017'), 2),"..
"(1763, (select id from catalogo where sku = 'CFS-710017'), 3),"..
"(1764, (select id from catalogo where sku = 'CFS-710017'), 4),"..
"(1765, (select id from catalogo where sku = 'CFS-710017'), 5),"..
"(1766, (select id from catalogo where sku = 'CFS-710017'), 6),"..
"(1767, (select id from catalogo where sku = 'CFS-710018'), 1),"..
"(1768, (select id from catalogo where sku = 'CFS-710018'), 2),"..
"(1769, (select id from catalogo where sku = 'CFS-710018'), 3),"..
"(1770, (select id from catalogo where sku = 'CFS-710018'), 4),"..
"(1771, (select id from catalogo where sku = 'CFS-710018'), 5),"..
"(1772, (select id from catalogo where sku = 'CFS-710018'), 6),"..
"(1773, (select id from catalogo where sku = 'CFS-710071'), 1),"..
"(1774, (select id from catalogo where sku = 'CFS-710071'), 2),"..
"(1775, (select id from catalogo where sku = 'CFS-710071'), 3),"..
"(1776, (select id from catalogo where sku = 'CFS-710071'), 4),"..
"(1777, (select id from catalogo where sku = 'CFS-710071'), 5),"..
"(1778, (select id from catalogo where sku = 'CFS-710071'), 6),"..
"(1779, (select id from catalogo where sku = 'CIDGMBDES04'), 8),"..
"(1780, (select id from catalogo where sku = 'CIDGMBDES05'), 8),"..
"(1781, (select id from catalogo where sku = 'CIDGMBDES06'), 8),"..
"(1782, (select id from catalogo where sku = 'CIDGMBDES10'), 8),"..
"(1783, (select id from catalogo where sku = 'CIDGMBDES11'), 8),"..
"(1784, (select id from catalogo where sku = 'CIDGMBDES12'), 8),"..
"(1785, (select id from catalogo where sku = 'CIDGMBDES13'), 8),"..
"(1786, (select id from catalogo where sku = 'CIDGMBDES15'), 8),"..
"(1787, (select id from catalogo where sku = 'CIDGMBDES16'), 8),"..
"(1788, (select id from catalogo where sku = 'CIDGMBDES21'), 8),"..
"(1789, (select id from catalogo where sku = 'CIDGMBDES25'), 8),"..
"(1790, (select id from catalogo where sku = 'CIDGMBDES26'), 8),"..
"(1791, (select id from catalogo where sku = 'CIDGMBDES28'), 8),"..
"(1792, (select id from catalogo where sku = 'CIDGMBDES30'), 8),"..
"(1793, (select id from catalogo where sku = 'CIDGMBDES32'), 8),"..
"(1794, (select id from catalogo where sku = 'CIDGMBDES34'), 8),"..
"(1795, (select id from catalogo where sku = 'CIDGMBDES35'), 8),"..
"(1796, (select id from catalogo where sku = 'CIDGMBDES37'), 8),"..
"(1797, (select id from catalogo where sku = 'CIDGMBSAN02'), 8),"..
"(1798, (select id from catalogo where sku = 'CIDGMBSAN03'), 8),"..
"(1799, (select id from catalogo where sku = 'CIDGMBSAN05'), 8),"..
"(1800, (select id from catalogo where sku = 'CIDGMBSAN06'), 8),"..
"(1801, (select id from catalogo where sku = 'CIDGMBSAN07'), 8),"..
"(1802, (select id from catalogo where sku = 'CIDGMBSAN11'), 8),"..
"(1803, (select id from catalogo where sku = 'CIDGMBSAN13'), 8),"..
"(1804, (select id from catalogo where sku = 'CIDGMBSAN20'), 8),"..
"(1805, (select id from catalogo where sku = 'CIDGMBSAN22'), 8),"..
"(1806, (select id from catalogo where sku = 'CIDGMBSAN30'), 8),"..
"(1807, (select id from catalogo where sku = 'CIDGMBSAN32'), 8),"..
"(1808, (select id from catalogo where sku = 'CIDGMBSAN33'), 8),"..
"(1809, (select id from catalogo where sku = 'CIDGMBSAN36'), 8),"..
"(1810, (select id from catalogo where sku = 'CIDGMBSAN39'), 8);"
db:exec( query2 )
--fase 13
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1811, (select id from catalogo where sku = 'CIDGMBSAN43'), 8),"..
"(1812, (select id from catalogo where sku = 'CIDGMBSAN45'), 8),"..
"(1813, (select id from catalogo where sku = 'CIDGMBSAN49'), 8),"..
"(1814, (select id from catalogo where sku = 'CIDGMBSAN51'), 8),"..
"(1815, (select id from catalogo where sku = 'COZCOA01502'), 2),"..
"(1816, (select id from catalogo where sku = 'COZCOA01502'), 3),"..
"(1817, (select id from catalogo where sku = 'COZCOA01502'), 4),"..
"(1818, (select id from catalogo where sku = 'COZCOA01502'), 5),"..
"(1819, (select id from catalogo where sku = 'COZCOA01511'), 2),"..
"(1820, (select id from catalogo where sku = 'COZCOA01511'), 3),"..
"(1821, (select id from catalogo where sku = 'COZCOA01511'), 4),"..
"(1822, (select id from catalogo where sku = 'COZCOA01511'), 5),"..
"(1823, (select id from catalogo where sku = 'COZCOA015XXL02'), 6),"..
"(1824, (select id from catalogo where sku = 'COZCOA015XXL11'), 6),"..
"(1825, (select id from catalogo where sku = 'COZCOD01540'), 2),"..
"(1826, (select id from catalogo where sku = 'COZCOD01540'), 3),"..
"(1827, (select id from catalogo where sku = 'COZCOD01540'), 4),"..
"(1828, (select id from catalogo where sku = 'COZCOD01540'), 5),"..
"(1829, (select id from catalogo where sku = 'COZCOD01571'), 2),"..
"(1830, (select id from catalogo where sku = 'COZCOD01571'), 3),"..
"(1831, (select id from catalogo where sku = 'COZCOD01571'), 4),"..
"(1832, (select id from catalogo where sku = 'COZCOD01571'), 5),"..
"(1833, (select id from catalogo where sku = 'COZCOV00303'), 2),"..
"(1834, (select id from catalogo where sku = 'COZCOV00303'), 3),"..
"(1835, (select id from catalogo where sku = 'COZCOV00303'), 4),"..
"(1836, (select id from catalogo where sku = 'COZCOV00303'), 5),"..
"(1837, (select id from catalogo where sku = 'COZCOV00304'), 2),"..
"(1838, (select id from catalogo where sku = 'COZCOV00304'), 3),"..
"(1839, (select id from catalogo where sku = 'COZCOV00304'), 4),"..
"(1840, (select id from catalogo where sku = 'COZCOV00304'), 5),"..
"(1841, (select id from catalogo where sku = 'COZCOV00311'), 2),"..
"(1842, (select id from catalogo where sku = 'COZCOV00311'), 3),"..
"(1843, (select id from catalogo where sku = 'COZCOV00311'), 4),"..
"(1844, (select id from catalogo where sku = 'COZCOV00311'), 5),"..
"(1845, (select id from catalogo where sku = 'COZCOV00313'), 2),"..
"(1846, (select id from catalogo where sku = 'COZCOV00313'), 3),"..
"(1847, (select id from catalogo where sku = 'COZCOV00313'), 4),"..
"(1848, (select id from catalogo where sku = 'COZCOV00313'), 5),"..
"(1849, (select id from catalogo where sku = 'COZCOV00316'), 2),"..
"(1850, (select id from catalogo where sku = 'COZCOV00316'), 3),"..
"(1851, (select id from catalogo where sku = 'COZCOV00316'), 4),"..
"(1852, (select id from catalogo where sku = 'COZCOV00316'), 5),"..
"(1853, (select id from catalogo where sku = 'COZCOV00329'), 2),"..
"(1854, (select id from catalogo where sku = 'COZCOV00329'), 3),"..
"(1855, (select id from catalogo where sku = 'COZCOV00329'), 4),"..
"(1856, (select id from catalogo where sku = 'COZCOV00329'), 5),"..
"(1857, (select id from catalogo where sku = 'COZCOV00330'), 2),"..
"(1858, (select id from catalogo where sku = 'COZCOV00330'), 3),"..
"(1859, (select id from catalogo where sku = 'COZCOV00330'), 4),"..
"(1860, (select id from catalogo where sku = 'COZCOV00330'), 5),"..
"(1861, (select id from catalogo where sku = 'COZCOV00337'), 2),"..
"(1862, (select id from catalogo where sku = 'COZCOV00337'), 3),"..
"(1863, (select id from catalogo where sku = 'COZCOV00337'), 4),"..
"(1864, (select id from catalogo where sku = 'COZCOV00337'), 5),"..
"(1865, (select id from catalogo where sku = 'COZGDKBBE03'), 8),"..
"(1866, (select id from catalogo where sku = 'COZGDKBBE04'), 8),"..
"(1867, (select id from catalogo where sku = 'COZGDKBBE10'), 8),"..
"(1868, (select id from catalogo where sku = 'COZGDKBBE12'), 8),"..
"(1869, (select id from catalogo where sku = 'COZGDKBBE29'), 8),"..
"(1870, (select id from catalogo where sku = 'COZGDKPLU12'), 8),"..
"(1871, (select id from catalogo where sku = 'COZGDKPLU17'), 8),"..
"(1872, (select id from catalogo where sku = 'COZGDKPLU18'), 8),"..
"(1873, (select id from catalogo where sku = 'COZGDKPLU40'), 8),"..
"(1874, (select id from catalogo where sku = 'COZGDKPLU71'), 8),"..
"(1875, (select id from catalogo where sku = 'COZGGE00111'), 8),"..
"(1876, (select id from catalogo where sku = 'COZGGE00216'), 8),"..
"(1877, (select id from catalogo where sku = 'COZGGE00373'), 8),"..
"(1878, (select id from catalogo where sku = 'COZGGE00508'), 8),"..
"(1879, (select id from catalogo where sku = 'COZGGE00713'), 8),"..
"(1880, (select id from catalogo where sku = 'COZGGE00803'), 8),"..
"(1881, (select id from catalogo where sku = 'COZGGE00971'), 8),"..
"(1882, (select id from catalogo where sku = 'COZGGE02513'), 8),"..
"(1883, (select id from catalogo where sku = 'COZGGE02611'), 8),"..
"(1884, (select id from catalogo where sku = 'COZGMBARC04'), 8),"..
"(1885, (select id from catalogo where sku = 'COZGMBARC18'), 8),"..
"(1886, (select id from catalogo where sku = 'COZGMBARC29'), 8),"..
"(1887, (select id from catalogo where sku = 'COZGMBARC38'), 8),"..
"(1888, (select id from catalogo where sku = 'COZGMBCAZ09'), 8),"..
"(1889, (select id from catalogo where sku = 'COZGMBCAZ30'), 8),"..
"(1890, (select id from catalogo where sku = 'COZGMBDAM04'), 8),"..
"(1891, (select id from catalogo where sku = 'COZGMBDAM12'), 8),"..
"(1892, (select id from catalogo where sku = 'COZGMBDAM17'), 8),"..
"(1893, (select id from catalogo where sku = 'COZGMBDAM18'), 8),"..
"(1894, (select id from catalogo where sku = 'COZGMBDAM19'), 8),"..
"(1895, (select id from catalogo where sku = 'COZGMBDAM29'), 8),"..
"(1896, (select id from catalogo where sku = 'COZGMBDAM40'), 8),"..
"(1897, (select id from catalogo where sku = 'COZGMBDAM41'), 8),"..
"(1898, (select id from catalogo where sku = 'COZGMBDES04'), 8),"..
"(1899, (select id from catalogo where sku = 'COZGMBDES05'), 8),"..
"(1900, (select id from catalogo where sku = 'COZGMBDES06'), 8),"..
"(1901, (select id from catalogo where sku = 'COZGMBDES10'), 8),"..
"(1902, (select id from catalogo where sku = 'COZGMBDES11'), 8),"..
"(1903, (select id from catalogo where sku = 'COZGMBDES12'), 8),"..
"(1904, (select id from catalogo where sku = 'COZGMBDES13'), 8),"..
"(1905, (select id from catalogo where sku = 'COZGMBDES15'), 8),"..
"(1906, (select id from catalogo where sku = 'COZGMBDES16'), 8),"..
"(1907, (select id from catalogo where sku = 'COZGMBDES21'), 8),"..
"(1908, (select id from catalogo where sku = 'COZGMBDES25'), 8),"..
"(1909, (select id from catalogo where sku = 'COZGMBDES26'), 8),"..
"(1910, (select id from catalogo where sku = 'COZGMBDES28'), 8),"..
"(1911, (select id from catalogo where sku = 'COZGMBDES30'), 8),"..
"(1912, (select id from catalogo where sku = 'COZGMBDES32'), 8),"..
"(1913, (select id from catalogo where sku = 'COZGMBDES34'), 8),"..
"(1914, (select id from catalogo where sku = 'COZGMBDES35'), 8),"..
"(1915, (select id from catalogo where sku = 'COZGMBDES37'), 8),"..
"(1916, (select id from catalogo where sku = 'COZGMBFCU17'), 8),"..
"(1917, (select id from catalogo where sku = 'COZGMBFCU40'), 8),"..
"(1918, (select id from catalogo where sku = 'COZGMBFID29'), 8),"..
"(1919, (select id from catalogo where sku = 'COZGMBFID30'), 8),"..
"(1920, (select id from catalogo where sku = 'COZGMBFID37'), 8),"..
"(1921, (select id from catalogo where sku = 'COZGMBFID66'), 8),"..
"(1922, (select id from catalogo where sku = 'COZGMBNIÑ02'), 8),"..
"(1923, (select id from catalogo where sku = 'COZGMBNIÑ10'), 8),"..
"(1924, (select id from catalogo where sku = 'COZGMBNIÑ11'), 8),"..
"(1925, (select id from catalogo where sku = 'COZGMBNIÑ12'), 8),"..
"(1926, (select id from catalogo where sku = 'COZGMBNIÑ15'), 8),"..
"(1927, (select id from catalogo where sku = 'COZGMBOXF11'), 8),"..
"(1928, (select id from catalogo where sku = 'COZGMBOXF13'), 8),"..
"(1929, (select id from catalogo where sku = 'COZGMBOXF28'), 8),"..
"(1930, (select id from catalogo where sku = 'COZGMBOXF30'), 8),"..
"(1931, (select id from catalogo where sku = 'COZGMBOXF31'), 8),"..
"(1932, (select id from catalogo where sku = 'COZGMBPES02'), 8),"..
"(1933, (select id from catalogo where sku = 'COZGMBPES11'), 8),"..
"(1934, (select id from catalogo where sku = 'COZGMBPES13'), 8),"..
"(1935, (select id from catalogo where sku = 'COZGMBPES28'), 8),"..
"(1936, (select id from catalogo where sku = 'COZGMBRAU11'), 8),"..
"(1937, (select id from catalogo where sku = 'COZGMBRAU13'), 8),"..
"(1938, (select id from catalogo where sku = 'COZGMBRAU28'), 8),"..
"(1939, (select id from catalogo where sku = 'COZGMBRAU30'), 8),"..
"(1940, (select id from catalogo where sku = 'COZGMBRAU31'), 8),"..
"(1941, (select id from catalogo where sku = 'COZGMBSAF03'), 8),"..
"(1942, (select id from catalogo where sku = 'COZGMBSAF28'), 8),"..
"(1943, (select id from catalogo where sku = 'COZGMBSAF30'), 8),"..
"(1944, (select id from catalogo where sku = 'COZGMBSAN02'), 8),"..
"(1945, (select id from catalogo where sku = 'COZGMBSAN03'), 8),"..
"(1946, (select id from catalogo where sku = 'COZGMBSAN05'), 8),"..
"(1947, (select id from catalogo where sku = 'COZGMBSAN06'), 8),"..
"(1948, (select id from catalogo where sku = 'COZGMBSAN07'), 8),"..
"(1949, (select id from catalogo where sku = 'COZGMBSAN11'), 8),"..
"(1950, (select id from catalogo where sku = 'COZGMBSAN13'), 8),"..
"(1951, (select id from catalogo where sku = 'COZGMBSAN20'), 8),"..
"(1952, (select id from catalogo where sku = 'COZGMBSAN22'), 8),"..
"(1953, (select id from catalogo where sku = 'COZGMBSAN30'), 8),"..
"(1954, (select id from catalogo where sku = 'COZGMBSAN32'), 8),"..
"(1955, (select id from catalogo where sku = 'COZGMBSAN33'), 8),"..
"(1956, (select id from catalogo where sku = 'COZGMBSAN36'), 8),"..
"(1957, (select id from catalogo where sku = 'COZGMBSAN39'), 8),"..
"(1958, (select id from catalogo where sku = 'COZGMBSAN43'), 8),"..
"(1959, (select id from catalogo where sku = 'COZGMBSAN45'), 8),"..
"(1960, (select id from catalogo where sku = 'COZGMBSAN49'), 8),"..
"(1961, (select id from catalogo where sku = 'COZGMBSAN51'), 8);"
db:exec( query2 )
--fase 14
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(1962, (select id from catalogo where sku = 'COZGMBVIN202'), 8),"..
"(1963, (select id from catalogo where sku = 'COZGMBVIN203'), 8),"..
"(1964, (select id from catalogo where sku = 'COZGMBVIN208'), 8),"..
"(1965, (select id from catalogo where sku = 'COZGMBVIN209'), 8),"..
"(1966, (select id from catalogo where sku = 'COZGMBVIN211'), 8),"..
"(1967, (select id from catalogo where sku = 'COZGMBVIN212'), 8),"..
"(1968, (select id from catalogo where sku = 'COZGMBVIN213'), 8),"..
"(1969, (select id from catalogo where sku = 'COZGMBVIN215'), 8),"..
"(1970, (select id from catalogo where sku = 'COZGMBVIN216'), 8),"..
"(1971, (select id from catalogo where sku = 'COZGMBVIN226'), 8),"..
"(1972, (select id from catalogo where sku = 'COZGMBVIN228'), 8),"..
"(1973, (select id from catalogo where sku = 'COZGMBVIN229'), 8),"..
"(1974, (select id from catalogo where sku = 'COZGMBVIN230'), 8),"..
"(1975, (select id from catalogo where sku = 'COZGMBVIN231'), 8),"..
"(1976, (select id from catalogo where sku = 'COZGMBVIN237'), 8),"..
"(1977, (select id from catalogo where sku = 'COZGMBVIN269'), 8),"..
"(1978, (select id from catalogo where sku = 'COZGMBVIN270'), 8),"..
"(1979, (select id from catalogo where sku = 'COZGMBVIN272'), 8),"..
"(1980, (select id from catalogo where sku = 'COZGMBVIN302'), 8),"..
"(1981, (select id from catalogo where sku = 'COZGMBVIN303'), 8),"..
"(1982, (select id from catalogo where sku = 'COZGMBVIN305'), 8),"..
"(1983, (select id from catalogo where sku = 'COZGMBVIN306'), 8),"..
"(1984, (select id from catalogo where sku = 'COZGMBVIN309'), 8),"..
"(1985, (select id from catalogo where sku = 'COZGMBVIN310'), 8),"..
"(1986, (select id from catalogo where sku = 'COZGMBVIN311'), 8),"..
"(1987, (select id from catalogo where sku = 'COZGMBVIN312'), 8),"..
"(1988, (select id from catalogo where sku = 'COZGMBVIN313'), 8),"..
"(1989, (select id from catalogo where sku = 'COZGMBVIN314'), 8),"..
"(1990, (select id from catalogo where sku = 'COZGMBVIN315'), 8),"..
"(1991, (select id from catalogo where sku = 'COZGMBVIN316'), 8),"..
"(1992, (select id from catalogo where sku = 'COZGMBVIN321'), 8),"..
"(1993, (select id from catalogo where sku = 'COZGMBVIN325'), 8),"..
"(1994, (select id from catalogo where sku = 'COZGMBVIN326'), 8),"..
"(1995, (select id from catalogo where sku = 'COZGMBVIN328'), 8),"..
"(1996, (select id from catalogo where sku = 'COZGMBVIN329'), 8),"..
"(1997, (select id from catalogo where sku = 'COZGMBVIN330'), 8),"..
"(1998, (select id from catalogo where sku = 'COZGMBVIN331'), 8),"..
"(1999, (select id from catalogo where sku = 'COZGMBVIN332'), 8),"..
"(2000, (select id from catalogo where sku = 'COZGMBVIN334'), 8),"..
"(2001, (select id from catalogo where sku = 'COZGMBVIN335'), 8),"..
"(2002, (select id from catalogo where sku = 'COZGMBVIN337'), 8),"..
"(2003, (select id from catalogo where sku = 'COZGMBVIN368'), 8),"..
"(2004, (select id from catalogo where sku = 'COZGMBVIT02'), 8),"..
"(2005, (select id from catalogo where sku = 'COZGMBVIT03'), 8),"..
"(2006, (select id from catalogo where sku = 'COZGMBVIT08'), 8),"..
"(2007, (select id from catalogo where sku = 'COZGMBVIT09'), 8),"..
"(2008, (select id from catalogo where sku = 'COZGMBVIT11'), 8),"..
"(2009, (select id from catalogo where sku = 'COZGMBVIT12'), 8),"..
"(2010, (select id from catalogo where sku = 'COZGMBVIT13'), 8),"..
"(2011, (select id from catalogo where sku = 'COZGMBVIT15'), 8),"..
"(2012, (select id from catalogo where sku = 'COZGMBVIT16'), 8),"..
"(2013, (select id from catalogo where sku = 'COZGMBVIT17'), 8),"..
"(2014, (select id from catalogo where sku = 'COZGMBVIT18'), 8),"..
"(2015, (select id from catalogo where sku = 'COZGMBVIT26'), 8),"..
"(2016, (select id from catalogo where sku = 'COZGMBVIT28'), 8),"..
"(2017, (select id from catalogo where sku = 'COZGMBVIT29'), 8),"..
"(2018, (select id from catalogo where sku = 'COZGMBVIT30'), 8),"..
"(2019, (select id from catalogo where sku = 'COZGMBVIT31'), 8),"..
"(2020, (select id from catalogo where sku = 'COZGMBVIT32'), 8),"..
"(2021, (select id from catalogo where sku = 'COZGMBVIT37'), 8),"..
"(2022, (select id from catalogo where sku = 'COZGMBVIT40'), 8),"..
"(2023, (select id from catalogo where sku = 'COZGMBVIT69'), 8),"..
"(2024, (select id from catalogo where sku = 'COZGMBVIT70'), 8),"..
"(2025, (select id from catalogo where sku = 'COZGMBVIT71'), 8),"..
"(2026, (select id from catalogo where sku = 'COZGMBVIT72'), 8),"..
"(2027, (select id from catalogo where sku = 'COZGMBVIT73'), 8),"..
"(2028, (select id from catalogo where sku = 'COZGMBVIT86'), 8),"..
"(2029, (select id from catalogo where sku = 'COZGMBVIT87'), 8),"..
"(2030, (select id from catalogo where sku = 'COZGMBVITQ'), 8),"..
"(2031, (select id from catalogo where sku = 'CUNCCMCV04'), 2),"..
"(2032, (select id from catalogo where sku = 'CUNCCMCV04'), 3),"..
"(2033, (select id from catalogo where sku = 'CUNCCMCV04'), 4),"..
"(2034, (select id from catalogo where sku = 'CUNCCMCV04'), 5),"..
"(2035, (select id from catalogo where sku = 'CUNCCMCV18'), 2),"..
"(2036, (select id from catalogo where sku = 'CUNCCMCV18'), 3),"..
"(2037, (select id from catalogo where sku = 'CUNCCMCV18'), 4),"..
"(2038, (select id from catalogo where sku = 'CUNCCMCV18'), 5),"..
"(2039, (select id from catalogo where sku = 'CUNCCMCV29'), 2),"..
"(2040, (select id from catalogo where sku = 'CUNCCMCV29'), 3),"..
"(2041, (select id from catalogo where sku = 'CUNCCMCV29'), 4),"..
"(2042, (select id from catalogo where sku = 'CUNCCMCV29'), 5),"..
"(2043, (select id from catalogo where sku = 'CUNCOA001'), 2),"..
"(2044, (select id from catalogo where sku = 'CUNCOA001'), 3),"..
"(2045, (select id from catalogo where sku = 'CUNCOA001'), 4),"..
"(2046, (select id from catalogo where sku = 'CUNCOA001'), 5),"..
"(2047, (select id from catalogo where sku = 'CUNCOA001'), 6),"..
"(2048, (select id from catalogo where sku = 'CUNCOA001XXL'), 6),"..
"(2049, (select id from catalogo where sku = 'CUNCOA002'), 2),"..
"(2050, (select id from catalogo where sku = 'CUNCOA002'), 3),"..
"(2051, (select id from catalogo where sku = 'CUNCOA002'), 4),"..
"(2052, (select id from catalogo where sku = 'CUNCOA002'), 5),"..
"(2053, (select id from catalogo where sku = 'CUNCOA002XXL'), 6),"..
"(2054, (select id from catalogo where sku = 'CUNCOA00311'), 2),"..
"(2055, (select id from catalogo where sku = 'CUNCOA00311'), 3),"..
"(2056, (select id from catalogo where sku = 'CUNCOA00311'), 4),"..
"(2057, (select id from catalogo where sku = 'CUNCOA00311'), 5),"..
"(2058, (select id from catalogo where sku = 'CUNCOA00328'), 2),"..
"(2059, (select id from catalogo where sku = 'CUNCOA00328'), 3),"..
"(2060, (select id from catalogo where sku = 'CUNCOA00328'), 4),"..
"(2061, (select id from catalogo where sku = 'CUNCOA00328'), 5),"..
"(2062, (select id from catalogo where sku = 'CUNCOA00330'), 2),"..
"(2063, (select id from catalogo where sku = 'CUNCOA00330'), 3),"..
"(2064, (select id from catalogo where sku = 'CUNCOA00330'), 4),"..
"(2065, (select id from catalogo where sku = 'CUNCOA00330'), 5),"..
"(2066, (select id from catalogo where sku = 'CUNCOA003XXL11'), 6),"..
"(2067, (select id from catalogo where sku = 'CUNCOA003XXL28'), 6),"..
"(2068, (select id from catalogo where sku = 'CUNCOA003XXL30'), 6),"..
"(2069, (select id from catalogo where sku = 'CUNCOA00402'), 2),"..
"(2070, (select id from catalogo where sku = 'CUNCOA00402'), 3),"..
"(2071, (select id from catalogo where sku = 'CUNCOA00402'), 4),"..
"(2072, (select id from catalogo where sku = 'CUNCOA00402'), 5),"..
"(2073, (select id from catalogo where sku = 'CUNCOA00411'), 2),"..
"(2074, (select id from catalogo where sku = 'CUNCOA00411'), 3),"..
"(2075, (select id from catalogo where sku = 'CUNCOA00411'), 4),"..
"(2076, (select id from catalogo where sku = 'CUNCOA00411'), 5),"..
"(2077, (select id from catalogo where sku = 'CUNCOA00413'), 2),"..
"(2078, (select id from catalogo where sku = 'CUNCOA00413'), 3),"..
"(2079, (select id from catalogo where sku = 'CUNCOA00413'), 4),"..
"(2080, (select id from catalogo where sku = 'CUNCOA00413'), 5),"..
"(2081, (select id from catalogo where sku = 'CUNCOA004XXL02'), 6),"..
"(2082, (select id from catalogo where sku = 'CUNCOA004XXL11'), 6),"..
"(2083, (select id from catalogo where sku = 'CUNCOA004XXL13'), 6),"..
"(2084, (select id from catalogo where sku = 'CUNCOA00502'), 2),"..
"(2085, (select id from catalogo where sku = 'CUNCOA00502'), 3),"..
"(2086, (select id from catalogo where sku = 'CUNCOA00502'), 4),"..
"(2087, (select id from catalogo where sku = 'CUNCOA00502'), 5),"..
"(2088, (select id from catalogo where sku = 'CUNCOA00510'), 2),"..
"(2089, (select id from catalogo where sku = 'CUNCOA00510'), 3),"..
"(2090, (select id from catalogo where sku = 'CUNCOA00510'), 4),"..
"(2091, (select id from catalogo where sku = 'CUNCOA00510'), 5),"..
"(2092, (select id from catalogo where sku = 'CUNCOA00511'), 2),"..
"(2093, (select id from catalogo where sku = 'CUNCOA00511'), 3),"..
"(2094, (select id from catalogo where sku = 'CUNCOA00511'), 4),"..
"(2095, (select id from catalogo where sku = 'CUNCOA00511'), 5),"..
"(2096, (select id from catalogo where sku = 'CUNCOA00512'), 2),"..
"(2097, (select id from catalogo where sku = 'CUNCOA00512'), 3),"..
"(2098, (select id from catalogo where sku = 'CUNCOA00512'), 4),"..
"(2099, (select id from catalogo where sku = 'CUNCOA00512'), 5),"..
"(2100, (select id from catalogo where sku = 'CUNCOA00515'), 2),"..
"(2101, (select id from catalogo where sku = 'CUNCOA00515'), 3),"..
"(2102, (select id from catalogo where sku = 'CUNCOA00515'), 4),"..
"(2103, (select id from catalogo where sku = 'CUNCOA00515'), 5),"..
"(2104, (select id from catalogo where sku = 'CUNCOA00521'), 2),"..
"(2105, (select id from catalogo where sku = 'CUNCOA00521'), 3),"..
"(2106, (select id from catalogo where sku = 'CUNCOA00521'), 4),"..
"(2107, (select id from catalogo where sku = 'CUNCOA00521'), 5),"..
"(2108, (select id from catalogo where sku = 'CUNCOA00526'), 2),"..
"(2109, (select id from catalogo where sku = 'CUNCOA00526'), 3),"..
"(2110, (select id from catalogo where sku = 'CUNCOA00526'), 4),"..
"(2111, (select id from catalogo where sku = 'CUNCOA00526'), 5),"..
"(2112, (select id from catalogo where sku = 'CUNCOA00528'), 2);"
db:exec( query2 )
--fase 15
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(2113, (select id from catalogo where sku = 'CUNCOA00528'), 3),"..
"(2114, (select id from catalogo where sku = 'CUNCOA00528'), 4),"..
"(2115, (select id from catalogo where sku = 'CUNCOA00528'), 5),"..
"(2116, (select id from catalogo where sku = 'CUNCOA00530'), 2),"..
"(2117, (select id from catalogo where sku = 'CUNCOA00530'), 3),"..
"(2118, (select id from catalogo where sku = 'CUNCOA00530'), 4),"..
"(2119, (select id from catalogo where sku = 'CUNCOA00530'), 5),"..
"(2120, (select id from catalogo where sku = 'CUNCOA00532'), 2),"..
"(2121, (select id from catalogo where sku = 'CUNCOA00532'), 3),"..
"(2122, (select id from catalogo where sku = 'CUNCOA00532'), 4),"..
"(2123, (select id from catalogo where sku = 'CUNCOA00532'), 5),"..
"(2124, (select id from catalogo where sku = 'CUNCOA005XXL02'), 6),"..
"(2125, (select id from catalogo where sku = 'CUNCOA005XXL10'), 6),"..
"(2126, (select id from catalogo where sku = 'CUNCOA005XXL11'), 6),"..
"(2127, (select id from catalogo where sku = 'CUNCOA005XXL12'), 6),"..
"(2128, (select id from catalogo where sku = 'CUNCOA005XXL15'), 6),"..
"(2129, (select id from catalogo where sku = 'CUNCOA005XXL21'), 6),"..
"(2130, (select id from catalogo where sku = 'CUNCOA005XXL26'), 6),"..
"(2131, (select id from catalogo where sku = 'CUNCOA005XXL28'), 6),"..
"(2132, (select id from catalogo where sku = 'CUNCOA005XXL30'), 6),"..
"(2133, (select id from catalogo where sku = 'CUNCOA005XXL32'), 6),"..
"(2134, (select id from catalogo where sku = 'CUNCOA01502'), 2),"..
"(2135, (select id from catalogo where sku = 'CUNCOA01502'), 3),"..
"(2136, (select id from catalogo where sku = 'CUNCOA01502'), 4),"..
"(2137, (select id from catalogo where sku = 'CUNCOA01502'), 5),"..
"(2138, (select id from catalogo where sku = 'CUNCOA01511'), 2),"..
"(2139, (select id from catalogo where sku = 'CUNCOA01511'), 3),"..
"(2140, (select id from catalogo where sku = 'CUNCOA01511'), 4),"..
"(2141, (select id from catalogo where sku = 'CUNCOA01511'), 5),"..
"(2142, (select id from catalogo where sku = 'CUNCOA015XXL02'), 6),"..
"(2143, (select id from catalogo where sku = 'CUNCOA015XXL11'), 6),"..
"(2144, (select id from catalogo where sku = 'CUNCOA02012'), 2),"..
"(2145, (select id from catalogo where sku = 'CUNCOA02012'), 3),"..
"(2146, (select id from catalogo where sku = 'CUNCOA02012'), 4),"..
"(2147, (select id from catalogo where sku = 'CUNCOA02012'), 5),"..
"(2148, (select id from catalogo where sku = 'CUNCOA02017'), 2),"..
"(2149, (select id from catalogo where sku = 'CUNCOA02017'), 3),"..
"(2150, (select id from catalogo where sku = 'CUNCOA02017'), 4),"..
"(2151, (select id from catalogo where sku = 'CUNCOA02017'), 5),"..
"(2152, (select id from catalogo where sku = 'CUNCOA02018'), 2),"..
"(2153, (select id from catalogo where sku = 'CUNCOA02018'), 3),"..
"(2154, (select id from catalogo where sku = 'CUNCOA02018'), 4),"..
"(2155, (select id from catalogo where sku = 'CUNCOA02018'), 5),"..
"(2156, (select id from catalogo where sku = 'CUNCOA02071'), 2),"..
"(2157, (select id from catalogo where sku = 'CUNCOA02071'), 3),"..
"(2158, (select id from catalogo where sku = 'CUNCOA02071'), 4),"..
"(2159, (select id from catalogo where sku = 'CUNCOA02071'), 5),"..
"(2160, (select id from catalogo where sku = 'CUNCOA13'), 2),"..
"(2161, (select id from catalogo where sku = 'CUNCOA13'), 3),"..
"(2162, (select id from catalogo where sku = 'CUNCOA13'), 4),"..
"(2163, (select id from catalogo where sku = 'CUNCOA13'), 5),"..
"(2164, (select id from catalogo where sku = 'CUNCOA13XXL'), 6),"..
"(2165, (select id from catalogo where sku = 'CUNCOD00129'), 2),"..
"(2166, (select id from catalogo where sku = 'CUNCOD00129'), 3),"..
"(2167, (select id from catalogo where sku = 'CUNCOD00129'), 4),"..
"(2168, (select id from catalogo where sku = 'CUNCOD00129'), 5),"..
"(2169, (select id from catalogo where sku = 'CUNCOD00204'), 2),"..
"(2170, (select id from catalogo where sku = 'CUNCOD00204'), 3),"..
"(2171, (select id from catalogo where sku = 'CUNCOD00204'), 4),"..
"(2172, (select id from catalogo where sku = 'CUNCOD00204'), 5),"..
"(2173, (select id from catalogo where sku = 'CUNCOD00212'), 2),"..
"(2174, (select id from catalogo where sku = 'CUNCOD00212'), 3),"..
"(2175, (select id from catalogo where sku = 'CUNCOD00212'), 4),"..
"(2176, (select id from catalogo where sku = 'CUNCOD00212'), 5),"..
"(2177, (select id from catalogo where sku = 'CUNCOD00217'), 2),"..
"(2178, (select id from catalogo where sku = 'CUNCOD00217'), 3),"..
"(2179, (select id from catalogo where sku = 'CUNCOD00217'), 4),"..
"(2180, (select id from catalogo where sku = 'CUNCOD00217'), 5),"..
"(2181, (select id from catalogo where sku = 'CUNCOD00218'), 2),"..
"(2182, (select id from catalogo where sku = 'CUNCOD00218'), 3),"..
"(2183, (select id from catalogo where sku = 'CUNCOD00218'), 4),"..
"(2184, (select id from catalogo where sku = 'CUNCOD00218'), 5),"..
"(2185, (select id from catalogo where sku = 'CUNCOD00219'), 2),"..
"(2186, (select id from catalogo where sku = 'CUNCOD00219'), 3),"..
"(2187, (select id from catalogo where sku = 'CUNCOD00219'), 4),"..
"(2188, (select id from catalogo where sku = 'CUNCOD00219'), 5),"..
"(2189, (select id from catalogo where sku = 'CUNCOD00223'), 2),"..
"(2190, (select id from catalogo where sku = 'CUNCOD00223'), 3),"..
"(2191, (select id from catalogo where sku = 'CUNCOD00223'), 4),"..
"(2192, (select id from catalogo where sku = 'CUNCOD00223'), 5),"..
"(2193, (select id from catalogo where sku = 'CUNCOD00240'), 2),"..
"(2194, (select id from catalogo where sku = 'CUNCOD00240'), 3),"..
"(2195, (select id from catalogo where sku = 'CUNCOD00240'), 4),"..
"(2196, (select id from catalogo where sku = 'CUNCOD00240'), 5),"..
"(2197, (select id from catalogo where sku = 'CUNCOD00242'), 2),"..
"(2198, (select id from catalogo where sku = 'CUNCOD00242'), 3),"..
"(2199, (select id from catalogo where sku = 'CUNCOD00242'), 4),"..
"(2200, (select id from catalogo where sku = 'CUNCOD00242'), 5),"..
"(2201, (select id from catalogo where sku = 'CUNCOD01540'), 2),"..
"(2202, (select id from catalogo where sku = 'CUNCOD01540'), 3),"..
"(2203, (select id from catalogo where sku = 'CUNCOD01540'), 4),"..
"(2204, (select id from catalogo where sku = 'CUNCOD01540'), 5),"..
"(2205, (select id from catalogo where sku = 'CUNCOD01571'), 2),"..
"(2206, (select id from catalogo where sku = 'CUNCOD01571'), 3),"..
"(2207, (select id from catalogo where sku = 'CUNCOD01571'), 4),"..
"(2208, (select id from catalogo where sku = 'CUNCOD01571'), 5),"..
"(2209, (select id from catalogo where sku = 'CUNCON001'), 2),"..
"(2210, (select id from catalogo where sku = 'CUNCON001'), 3),"..
"(2211, (select id from catalogo where sku = 'CUNCON001'), 4),"..
"(2212, (select id from catalogo where sku = 'CUNCON001'), 5),"..
"(2213, (select id from catalogo where sku = 'CUNCON002'), 2),"..
"(2214, (select id from catalogo where sku = 'CUNCON002'), 3),"..
"(2215, (select id from catalogo where sku = 'CUNCON002'), 4),"..
"(2216, (select id from catalogo where sku = 'CUNCON002'), 5),"..
"(2217, (select id from catalogo where sku = 'CUNCSMCV04'), 2),"..
"(2218, (select id from catalogo where sku = 'CUNCSMCV04'), 3),"..
"(2219, (select id from catalogo where sku = 'CUNCSMCV04'), 4),"..
"(2220, (select id from catalogo where sku = 'CUNCSMCV04'), 5),"..
"(2221, (select id from catalogo where sku = 'CUNCSMCV18'), 2),"..
"(2222, (select id from catalogo where sku = 'CUNCSMCV18'), 3),"..
"(2223, (select id from catalogo where sku = 'CUNCSMCV18'), 4),"..
"(2224, (select id from catalogo where sku = 'CUNCSMCV18'), 5),"..
"(2225, (select id from catalogo where sku = 'CUNCSMCV29'), 2),"..
"(2226, (select id from catalogo where sku = 'CUNCSMCV29'), 3),"..
"(2227, (select id from catalogo where sku = 'CUNCSMCV29'), 4),"..
"(2228, (select id from catalogo where sku = 'CUNCSMCV29'), 5),"..
"(2229, (select id from catalogo where sku = 'CUNGDKBBE03'), 8),"..
"(2230, (select id from catalogo where sku = 'CUNGDKBBE04'), 8),"..
"(2231, (select id from catalogo where sku = 'CUNGDKBBE10'), 8),"..
"(2232, (select id from catalogo where sku = 'CUNGDKBBE12'), 8),"..
"(2233, (select id from catalogo where sku = 'CUNGDKBBE29'), 8),"..
"(2234, (select id from catalogo where sku = 'CUNGDKDES11'), 8),"..
"(2235, (select id from catalogo where sku = 'CUNGDKDES13'), 8),"..
"(2236, (select id from catalogo where sku = 'CUNGDKPLU12'), 8),"..
"(2237, (select id from catalogo where sku = 'CUNGDKPLU17'), 8),"..
"(2238, (select id from catalogo where sku = 'CUNGDKPLU18'), 8),"..
"(2239, (select id from catalogo where sku = 'CUNGDKPLU40'), 8),"..
"(2240, (select id from catalogo where sku = 'CUNGDKPLU71'), 8),"..
"(2241, (select id from catalogo where sku = 'CUNGGE001'), 8),"..
"(2242, (select id from catalogo where sku = 'CUNGGE002'), 8),"..
"(2243, (select id from catalogo where sku = 'CUNGGE003'), 8),"..
"(2244, (select id from catalogo where sku = 'CUNGGE004'), 8),"..
"(2245, (select id from catalogo where sku = 'CUNGGE005'), 8),"..
"(2246, (select id from catalogo where sku = 'CUNGGE006'), 8),"..
"(2247, (select id from catalogo where sku = 'CUNGGE007'), 8),"..
"(2248, (select id from catalogo where sku = 'CUNGGE008'), 8),"..
"(2249, (select id from catalogo where sku = 'CUNGGE009'), 8),"..
"(2250, (select id from catalogo where sku = 'CUNGGE010'), 8),"..
"(2251, (select id from catalogo where sku = 'CUNGGE013'), 8),"..
"(2252, (select id from catalogo where sku = 'CUNGGE019'), 8),"..
"(2253, (select id from catalogo where sku = 'CUNGGE020'), 8),"..
"(2254, (select id from catalogo where sku = 'CUNGGE021'), 8),"..
"(2255, (select id from catalogo where sku = 'CUNGGE022'), 8),"..
"(2256, (select id from catalogo where sku = 'CUNGGE023'), 8),"..
"(2257, (select id from catalogo where sku = 'CUNGGE025'), 8),"..
"(2258, (select id from catalogo where sku = 'CUNGGE026'), 8),"..
"(2259, (select id from catalogo where sku = 'CUNGMBARC04'), 8),"..
"(2260, (select id from catalogo where sku = 'CUNGMBARC18'), 8),"..
"(2261, (select id from catalogo where sku = 'CUNGMBARC29'), 8),"..
"(2262, (select id from catalogo where sku = 'CUNGMBARC37'), 8),"..
"(2263, (select id from catalogo where sku = 'CUNGMBBAS04'), 8);"
db:exec( query2 )
--fase 16
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(2264, (select id from catalogo where sku = 'CUNGMBBAS05'), 8),"..
"(2265, (select id from catalogo where sku = 'CUNGMBBAS11'), 8),"..
"(2266, (select id from catalogo where sku = 'CUNGMBBAS12'), 8),"..
"(2267, (select id from catalogo where sku = 'CUNGMBBAS28'), 8),"..
"(2268, (select id from catalogo where sku = 'CUNGMBBCA10'), 8),"..
"(2269, (select id from catalogo where sku = 'CUNGMBBCA12'), 8),"..
"(2270, (select id from catalogo where sku = 'CUNGMBCAM13'), 8),"..
"(2271, (select id from catalogo where sku = 'CUNGMBCAM26'), 8),"..
"(2272, (select id from catalogo where sku = 'CUNGMBCAM32'), 8),"..
"(2273, (select id from catalogo where sku = 'CUNGMBCAZ09'), 8),"..
"(2274, (select id from catalogo where sku = 'CUNGMBCAZ11'), 8),"..
"(2275, (select id from catalogo where sku = 'CUNGMBCAZ30'), 8),"..
"(2276, (select id from catalogo where sku = 'CUNGMBDAM04'), 8),"..
"(2277, (select id from catalogo where sku = 'CUNGMBDAM12'), 8),"..
"(2278, (select id from catalogo where sku = 'CUNGMBDAM17'), 8),"..
"(2279, (select id from catalogo where sku = 'CUNGMBDAM18'), 8),"..
"(2280, (select id from catalogo where sku = 'CUNGMBDAM19'), 8),"..
"(2281, (select id from catalogo where sku = 'CUNGMBDAM23'), 8),"..
"(2282, (select id from catalogo where sku = 'CUNGMBDAM29'), 8),"..
"(2283, (select id from catalogo where sku = 'CUNGMBDAM40'), 8),"..
"(2284, (select id from catalogo where sku = 'CUNGMBDAM41'), 8),"..
"(2285, (select id from catalogo where sku = 'CUNGMBDAM42'), 8),"..
"(2286, (select id from catalogo where sku = 'CUNGMBDES02'), 8),"..
"(2287, (select id from catalogo where sku = 'CUNGMBDES04'), 8),"..
"(2288, (select id from catalogo where sku = 'CUNGMBDES05'), 8),"..
"(2289, (select id from catalogo where sku = 'CUNGMBDES06'), 8),"..
"(2290, (select id from catalogo where sku = 'CUNGMBDES09'), 8),"..
"(2291, (select id from catalogo where sku = 'CUNGMBDES10'), 8),"..
"(2292, (select id from catalogo where sku = 'CUNGMBDES11'), 8),"..
"(2293, (select id from catalogo where sku = 'CUNGMBDES12'), 8),"..
"(2294, (select id from catalogo where sku = 'CUNGMBDES13'), 8),"..
"(2295, (select id from catalogo where sku = 'CUNGMBDES15'), 8),"..
"(2296, (select id from catalogo where sku = 'CUNGMBDES16'), 8),"..
"(2297, (select id from catalogo where sku = 'CUNGMBDES17'), 8),"..
"(2298, (select id from catalogo where sku = 'CUNGMBDES21'), 8),"..
"(2299, (select id from catalogo where sku = 'CUNGMBDES25'), 8),"..
"(2300, (select id from catalogo where sku = 'CUNGMBDES26'), 8),"..
"(2301, (select id from catalogo where sku = 'CUNGMBDES28'), 8),"..
"(2302, (select id from catalogo where sku = 'CUNGMBDES29'), 8),"..
"(2303, (select id from catalogo where sku = 'CUNGMBDES30'), 8),"..
"(2304, (select id from catalogo where sku = 'CUNGMBDES31'), 8),"..
"(2305, (select id from catalogo where sku = 'CUNGMBDES32'), 8),"..
"(2306, (select id from catalogo where sku = 'CUNGMBDES34'), 8),"..
"(2307, (select id from catalogo where sku = 'CUNGMBDES35'), 8),"..
"(2308, (select id from catalogo where sku = 'CUNGMBDES37'), 8),"..
"(2309, (select id from catalogo where sku = 'CUNGMBDES68'), 8),"..
"(2310, (select id from catalogo where sku = 'CUNGMBDES74'), 8),"..
"(2311, (select id from catalogo where sku = 'CUNGMBFCU17'), 8),"..
"(2312, (select id from catalogo where sku = 'CUNGMBFCU40'), 8),"..
"(2313, (select id from catalogo where sku = 'CUNGMBFID11'), 8),"..
"(2314, (select id from catalogo where sku = 'CUNGMBFID13'), 8),"..
"(2315, (select id from catalogo where sku = 'CUNGMBFID17'), 8),"..
"(2316, (select id from catalogo where sku = 'CUNGMBFID28'), 8),"..
"(2317, (select id from catalogo where sku = 'CUNGMBFID29'), 8),"..
"(2318, (select id from catalogo where sku = 'CUNGMBFID30'), 8),"..
"(2319, (select id from catalogo where sku = 'CUNGMBFID37'), 8),"..
"(2320, (select id from catalogo where sku = 'CUNGMBFID40'), 8),"..
"(2321, (select id from catalogo where sku = 'CUNGMBFID66'), 8),"..
"(2322, (select id from catalogo where sku = 'CUNGMBFID71'), 8),"..
"(2323, (select id from catalogo where sku = 'CUNGMBNIÑ02'), 8),"..
"(2324, (select id from catalogo where sku = 'CUNGMBNIÑ10'), 8),"..
"(2325, (select id from catalogo where sku = 'CUNGMBNIÑ11'), 8),"..
"(2326, (select id from catalogo where sku = 'CUNGMBNIÑ12'), 8),"..
"(2327, (select id from catalogo where sku = 'CUNGMBNIÑ15'), 8),"..
"(2328, (select id from catalogo where sku = 'CUNGMBNIÑ26'), 8),"..
"(2329, (select id from catalogo where sku = 'CUNGMBNMA62'), 8),"..
"(2330, (select id from catalogo where sku = 'CUNGMBNMA63'), 8),"..
"(2331, (select id from catalogo where sku = 'CUNGMBNMA64'), 8),"..
"(2332, (select id from catalogo where sku = 'CUNGMBNMA65'), 8),"..
"(2333, (select id from catalogo where sku = 'CUNGMBOXF02'), 8),"..
"(2334, (select id from catalogo where sku = 'CUNGMBOXF11'), 8),"..
"(2335, (select id from catalogo where sku = 'CUNGMBOXF13'), 8),"..
"(2336, (select id from catalogo where sku = 'CUNGMBOXF28'), 8),"..
"(2337, (select id from catalogo where sku = 'CUNGMBOXF30'), 8),"..
"(2338, (select id from catalogo where sku = 'CUNGMBOXF31'), 8),"..
"(2339, (select id from catalogo where sku = 'CUNGMBOXF37'), 8),"..
"(2340, (select id from catalogo where sku = 'CUNGMBPES02'), 8),"..
"(2341, (select id from catalogo where sku = 'CUNGMBPES11'), 8),"..
"(2342, (select id from catalogo where sku = 'CUNGMBPES13'), 8),"..
"(2343, (select id from catalogo where sku = 'CUNGMBPES28'), 8),"..
"(2344, (select id from catalogo where sku = 'CUNGMBPES31'), 8),"..
"(2345, (select id from catalogo where sku = 'CUNGMBRAU11'), 8),"..
"(2346, (select id from catalogo where sku = 'CUNGMBRAU13'), 8),"..
"(2347, (select id from catalogo where sku = 'CUNGMBRAU28'), 8),"..
"(2348, (select id from catalogo where sku = 'CUNGMBRAU29'), 8),"..
"(2349, (select id from catalogo where sku = 'CUNGMBRAU30'), 8),"..
"(2350, (select id from catalogo where sku = 'CUNGMBRAU31'), 8),"..
"(2351, (select id from catalogo where sku = 'CUNGMBRAU66'), 8),"..
"(2352, (select id from catalogo where sku = 'CUNGMBSAF03'), 8),"..
"(2353, (select id from catalogo where sku = 'CUNGMBSAF28'), 8),"..
"(2354, (select id from catalogo where sku = 'CUNGMBSAF30'), 8),"..
"(2355, (select id from catalogo where sku = 'CUNGMBSAN02'), 8),"..
"(2356, (select id from catalogo where sku = 'CUNGMBSAN03'), 8),"..
"(2357, (select id from catalogo where sku = 'CUNGMBSAN04'), 8),"..
"(2358, (select id from catalogo where sku = 'CUNGMBSAN05'), 8),"..
"(2359, (select id from catalogo where sku = 'CUNGMBSAN07'), 8),"..
"(2360, (select id from catalogo where sku = 'CUNGMBSAN11'), 8),"..
"(2361, (select id from catalogo where sku = 'CUNGMBSAN13'), 8),"..
"(2362, (select id from catalogo where sku = 'CUNGMBSAN20'), 8),"..
"(2363, (select id from catalogo where sku = 'CUNGMBSAN22'), 8),"..
"(2364, (select id from catalogo where sku = 'CUNGMBSAN30'), 8),"..
"(2365, (select id from catalogo where sku = 'CUNGMBSAN32'), 8),"..
"(2366, (select id from catalogo where sku = 'CUNGMBSAN33'), 8),"..
"(2367, (select id from catalogo where sku = 'CUNGMBSAN36'), 8),"..
"(2368, (select id from catalogo where sku = 'CUNGMBSAN39'), 8),"..
"(2369, (select id from catalogo where sku = 'CUNGMBSAN43'), 8),"..
"(2370, (select id from catalogo where sku = 'CUNGMBSAN45'), 8),"..
"(2371, (select id from catalogo where sku = 'CUNGMBSAN47'), 8),"..
"(2372, (select id from catalogo where sku = 'CUNGMBSAN49'), 8),"..
"(2373, (select id from catalogo where sku = 'CUNGMBSAN51'), 8),"..
"(2374, (select id from catalogo where sku = 'CUNGMBSAN83'), 8),"..
"(2375, (select id from catalogo where sku = 'CUNGMBVIN202'), 8),"..
"(2376, (select id from catalogo where sku = 'CUNGMBVIN203'), 8),"..
"(2377, (select id from catalogo where sku = 'CUNGMBVIN208'), 8),"..
"(2378, (select id from catalogo where sku = 'CUNGMBVIN209'), 8),"..
"(2379, (select id from catalogo where sku = 'CUNGMBVIN211'), 8),"..
"(2380, (select id from catalogo where sku = 'CUNGMBVIN212'), 8),"..
"(2381, (select id from catalogo where sku = 'CUNGMBVIN213'), 8),"..
"(2382, (select id from catalogo where sku = 'CUNGMBVIN215'), 8),"..
"(2383, (select id from catalogo where sku = 'CUNGMBVIN216'), 8),"..
"(2384, (select id from catalogo where sku = 'CUNGMBVIN226'), 8),"..
"(2385, (select id from catalogo where sku = 'CUNGMBVIN228'), 8),"..
"(2386, (select id from catalogo where sku = 'CUNGMBVIN229'), 8),"..
"(2387, (select id from catalogo where sku = 'CUNGMBVIN230'), 8),"..
"(2388, (select id from catalogo where sku = 'CUNGMBVIN231'), 8),"..
"(2389, (select id from catalogo where sku = 'CUNGMBVIN237'), 8),"..
"(2390, (select id from catalogo where sku = 'CUNGMBVIN269'), 8),"..
"(2391, (select id from catalogo where sku = 'CUNGMBVIN270'), 8),"..
"(2392, (select id from catalogo where sku = 'CUNGMBVIN272'), 8),"..
"(2393, (select id from catalogo where sku = 'CUNGMBVIN302'), 8),"..
"(2394, (select id from catalogo where sku = 'CUNGMBVIN303'), 8),"..
"(2395, (select id from catalogo where sku = 'CUNGMBVIN305'), 8),"..
"(2396, (select id from catalogo where sku = 'CUNGMBVIN306'), 8),"..
"(2397, (select id from catalogo where sku = 'CUNGMBVIN309'), 8),"..
"(2398, (select id from catalogo where sku = 'CUNGMBVIN310'), 8),"..
"(2399, (select id from catalogo where sku = 'CUNGMBVIN311'), 8),"..
"(2400, (select id from catalogo where sku = 'CUNGMBVIN312'), 8),"..
"(2401, (select id from catalogo where sku = 'CUNGMBVIN313'), 8),"..
"(2402, (select id from catalogo where sku = 'CUNGMBVIN314'), 8),"..
"(2403, (select id from catalogo where sku = 'CUNGMBVIN315'), 8),"..
"(2404, (select id from catalogo where sku = 'CUNGMBVIN316'), 8),"..
"(2405, (select id from catalogo where sku = 'CUNGMBVIN321'), 8),"..
"(2406, (select id from catalogo where sku = 'CUNGMBVIN325'), 8),"..
"(2407, (select id from catalogo where sku = 'CUNGMBVIN326'), 8),"..
"(2408, (select id from catalogo where sku = 'CUNGMBVIN328'), 8),"..
"(2409, (select id from catalogo where sku = 'CUNGMBVIN329'), 8),"..
"(2410, (select id from catalogo where sku = 'CUNGMBVIN330'), 8),"..
"(2411, (select id from catalogo where sku = 'CUNGMBVIN331'), 8),"..
"(2412, (select id from catalogo where sku = 'CUNGMBVIN332'), 8),"..
"(2413, (select id from catalogo where sku = 'CUNGMBVIN334'), 8),"..
"(2414, (select id from catalogo where sku = 'CUNGMBVIN335'), 8);"
db:exec( query2 )
--fase 17
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(2415, (select id from catalogo where sku = 'CUNGMBVIN337'), 8),"..
"(2416, (select id from catalogo where sku = 'CUNGMBVIN368'), 8),"..
"(2417, (select id from catalogo where sku = 'CUNGMBVIN403'), 8),"..
"(2418, (select id from catalogo where sku = 'CUNGMBVIN452'), 8),"..
"(2419, (select id from catalogo where sku = 'CUNGMBVIN457'), 8),"..
"(2420, (select id from catalogo where sku = 'CUNGMBVIT02'), 8),"..
"(2421, (select id from catalogo where sku = 'CUNGMBVIT03'), 8),"..
"(2422, (select id from catalogo where sku = 'CUNGMBVIT08'), 8),"..
"(2423, (select id from catalogo where sku = 'CUNGMBVIT09'), 8),"..
"(2424, (select id from catalogo where sku = 'CUNGMBVIT11'), 8),"..
"(2425, (select id from catalogo where sku = 'CUNGMBVIT12'), 8),"..
"(2426, (select id from catalogo where sku = 'CUNGMBVIT13'), 8),"..
"(2427, (select id from catalogo where sku = 'CUNGMBVIT15'), 8),"..
"(2428, (select id from catalogo where sku = 'CUNGMBVIT16'), 8),"..
"(2429, (select id from catalogo where sku = 'CUNGMBVIT17'), 8),"..
"(2430, (select id from catalogo where sku = 'CUNGMBVIT18'), 8),"..
"(2431, (select id from catalogo where sku = 'CUNGMBVIT26'), 8),"..
"(2432, (select id from catalogo where sku = 'CUNGMBVIT28'), 8),"..
"(2433, (select id from catalogo where sku = 'CUNGMBVIT29'), 8),"..
"(2434, (select id from catalogo where sku = 'CUNGMBVIT30'), 8),"..
"(2435, (select id from catalogo where sku = 'CUNGMBVIT31'), 8),"..
"(2436, (select id from catalogo where sku = 'CUNGMBVIT32'), 8),"..
"(2437, (select id from catalogo where sku = 'CUNGMBVIT37'), 8),"..
"(2438, (select id from catalogo where sku = 'CUNGMBVIT40'), 8),"..
"(2439, (select id from catalogo where sku = 'CUNGMBVIT69'), 8),"..
"(2440, (select id from catalogo where sku = 'CUNGMBVIT70'), 8),"..
"(2441, (select id from catalogo where sku = 'CUNGMBVIT71'), 8),"..
"(2442, (select id from catalogo where sku = 'CUNGMBVIT72'), 8),"..
"(2443, (select id from catalogo where sku = 'CUNGMBVIT73'), 8),"..
"(2444, (select id from catalogo where sku = 'CUNGMBVIT86'), 8),"..
"(2445, (select id from catalogo where sku = 'CUNGMBVIT87'), 8),"..
"(2446, (select id from catalogo where sku = 'CUNPAB0009'), 3),"..
"(2447, (select id from catalogo where sku = 'CUNPAB0009'), 4),"..
"(2448, (select id from catalogo where sku = 'CUNPAB0009'), 5),"..
"(2449, (select id from catalogo where sku = 'CUNPAB001'), 3),"..
"(2450, (select id from catalogo where sku = 'CUNPAB001'), 4),"..
"(2451, (select id from catalogo where sku = 'CUNPAB001'), 5),"..
"(2452, (select id from catalogo where sku = 'CUNPAB002'), 3),"..
"(2453, (select id from catalogo where sku = 'CUNPAB002'), 4),"..
"(2454, (select id from catalogo where sku = 'CUNPAB002'), 5),"..
"(2455, (select id from catalogo where sku = 'CUNPAB003'), 3),"..
"(2456, (select id from catalogo where sku = 'CUNPAB003'), 4),"..
"(2457, (select id from catalogo where sku = 'CUNPAB003'), 5),"..
"(2458, (select id from catalogo where sku = 'CUNPAB073'), 3),"..
"(2459, (select id from catalogo where sku = 'CUNPAB073'), 4),"..
"(2460, (select id from catalogo where sku = 'CUNPAB073'), 5),"..
"(2461, (select id from catalogo where sku = 'CUNPAB105'), 3),"..
"(2462, (select id from catalogo where sku = 'CUNPAB105'), 4),"..
"(2463, (select id from catalogo where sku = 'CUNPAB105'), 5),"..
"(2464, (select id from catalogo where sku = 'CUNPAB379'), 3),"..
"(2465, (select id from catalogo where sku = 'CUNPAB379'), 4),"..
"(2466, (select id from catalogo where sku = 'CUNPAB379'), 5),"..
"(2467, (select id from catalogo where sku = 'CUNPAB490'), 3),"..
"(2468, (select id from catalogo where sku = 'CUNPAB490'), 4),"..
"(2469, (select id from catalogo where sku = 'CUNPAB490'), 5),"..
"(2470, (select id from catalogo where sku = 'CUNPAB491'), 3),"..
"(2471, (select id from catalogo where sku = 'CUNPAB491'), 4),"..
"(2472, (select id from catalogo where sku = 'CUNPAB491'), 5),"..
"(2473, (select id from catalogo where sku = 'CUNPAB492'), 3),"..
"(2474, (select id from catalogo where sku = 'CUNPAB492'), 4),"..
"(2475, (select id from catalogo where sku = 'CUNPAB492'), 5),"..
"(2476, (select id from catalogo where sku = 'CUNPAB493'), 3),"..
"(2477, (select id from catalogo where sku = 'CUNPAB493'), 4),"..
"(2478, (select id from catalogo where sku = 'CUNPAB493'), 5),"..
"(2479, (select id from catalogo where sku = 'CUNPAB494'), 3),"..
"(2480, (select id from catalogo where sku = 'CUNPAB494'), 4),"..
"(2481, (select id from catalogo where sku = 'CUNPAB494'), 5),"..
"(2482, (select id from catalogo where sku = 'CUNPAB495'), 3),"..
"(2483, (select id from catalogo where sku = 'CUNPAB495'), 4),"..
"(2484, (select id from catalogo where sku = 'CUNPAB495'), 5),"..
"(2485, (select id from catalogo where sku = 'CUNPAI040'), 3),"..
"(2486, (select id from catalogo where sku = 'CUNPAI040'), 4),"..
"(2487, (select id from catalogo where sku = 'CUNPAI040'), 5),"..
"(2488, (select id from catalogo where sku = 'CUNPAI041'), 3),"..
"(2489, (select id from catalogo where sku = 'CUNPAI041'), 4),"..
"(2490, (select id from catalogo where sku = 'CUNPAI041'), 5),"..
"(2491, (select id from catalogo where sku = 'CUNPAI042'), 3),"..
"(2492, (select id from catalogo where sku = 'CUNPAI042'), 4),"..
"(2493, (select id from catalogo where sku = 'CUNPAI042'), 5),"..
"(2494, (select id from catalogo where sku = 'CUNPAI043'), 3),"..
"(2495, (select id from catalogo where sku = 'CUNPAI043'), 4),"..
"(2496, (select id from catalogo where sku = 'CUNPAI043'), 5),"..
"(2497, (select id from catalogo where sku = 'CUNPAI044'), 3),"..
"(2498, (select id from catalogo where sku = 'CUNPAI044'), 4),"..
"(2499, (select id from catalogo where sku = 'CUNPAI044'), 5),"..
"(2500, (select id from catalogo where sku = 'CUNPAI045'), 3),"..
"(2501, (select id from catalogo where sku = 'CUNPAI045'), 4),"..
"(2502, (select id from catalogo where sku = 'CUNPAI045'), 5),"..
"(2503, (select id from catalogo where sku = 'CUNPAJ001'), 3),"..
"(2504, (select id from catalogo where sku = 'CUNPAJ001'), 4),"..
"(2505, (select id from catalogo where sku = 'CUNPAJ001'), 5),"..
"(2506, (select id from catalogo where sku = 'CUNPAJ002'), 3),"..
"(2507, (select id from catalogo where sku = 'CUNPAJ002'), 4),"..
"(2508, (select id from catalogo where sku = 'CUNPAJ002'), 5),"..
"(2509, (select id from catalogo where sku = 'CUNPAJ003'), 3),"..
"(2510, (select id from catalogo where sku = 'CUNPAJ003'), 4),"..
"(2511, (select id from catalogo where sku = 'CUNPAJ003'), 5),"..
"(2512, (select id from catalogo where sku = 'CUNPAJ004'), 3),"..
"(2513, (select id from catalogo where sku = 'CUNPAJ004'), 4),"..
"(2514, (select id from catalogo where sku = 'CUNPAJ004'), 5),"..
"(2515, (select id from catalogo where sku = 'CUNPAJ011'), 3),"..
"(2516, (select id from catalogo where sku = 'CUNPAJ011'), 4),"..
"(2517, (select id from catalogo where sku = 'CUNPAJ011'), 5),"..
"(2518, (select id from catalogo where sku = 'CUNPAJ011XXL'), 6),"..
"(2519, (select id from catalogo where sku = 'CUNPAJ012'), 3),"..
"(2520, (select id from catalogo where sku = 'CUNPAJ012'), 4),"..
"(2521, (select id from catalogo where sku = 'CUNPAJ012'), 5),"..
"(2522, (select id from catalogo where sku = 'CUNPAJ012XXL'), 6),"..
"(2523, (select id from catalogo where sku = 'CUNPAJ013'), 3),"..
"(2524, (select id from catalogo where sku = 'CUNPAJ013'), 4),"..
"(2525, (select id from catalogo where sku = 'CUNPAJ013'), 5),"..
"(2526, (select id from catalogo where sku = 'CUNPAJ013XXL'), 6),"..
"(2527, (select id from catalogo where sku = 'CUNPAJ014'), 3),"..
"(2528, (select id from catalogo where sku = 'CUNPAJ014'), 4),"..
"(2529, (select id from catalogo where sku = 'CUNPAJ014'), 5),"..
"(2530, (select id from catalogo where sku = 'CUNPAJ014XXL'), 6),"..
"(2531, (select id from catalogo where sku = 'CUNPAJ015'), 3),"..
"(2532, (select id from catalogo where sku = 'CUNPAJ015'), 4),"..
"(2533, (select id from catalogo where sku = 'CUNPAJ015'), 5),"..
"(2534, (select id from catalogo where sku = 'CUNPAJ015XXL'), 6),"..
"(2535, (select id from catalogo where sku = 'CUNPNB073'), 2),"..
"(2536, (select id from catalogo where sku = 'CUNPNB073'), 3),"..
"(2537, (select id from catalogo where sku = 'CUNPNB073'), 4),"..
"(2538, (select id from catalogo where sku = 'CUNPNB411'), 2),"..
"(2539, (select id from catalogo where sku = 'CUNPNB411'), 3),"..
"(2540, (select id from catalogo where sku = 'CUNPNB411'), 4),"..
"(2541, (select id from catalogo where sku = 'CUNPNB465'), 2),"..
"(2542, (select id from catalogo where sku = 'CUNPNB465'), 3),"..
"(2543, (select id from catalogo where sku = 'CUNPNB465'), 4),"..
"(2544, (select id from catalogo where sku = 'CUNPNB470'), 2),"..
"(2545, (select id from catalogo where sku = 'CUNPNB470'), 3),"..
"(2546, (select id from catalogo where sku = 'CUNPNB470'), 4),"..
"(2547, (select id from catalogo where sku = 'CUNPNB480'), 2),"..
"(2548, (select id from catalogo where sku = 'CUNPNB480'), 3),"..
"(2549, (select id from catalogo where sku = 'CUNPNB480'), 4),"..
"(2550, (select id from catalogo where sku = 'CUNPNB481'), 2),"..
"(2551, (select id from catalogo where sku = 'CUNPNB481'), 3),"..
"(2552, (select id from catalogo where sku = 'CUNPNB481'), 4),"..
"(2553, (select id from catalogo where sku = 'CUNPNB482'), 2),"..
"(2554, (select id from catalogo where sku = 'CUNPNB482'), 3),"..
"(2555, (select id from catalogo where sku = 'CUNPNB482'), 4),"..
"(2556, (select id from catalogo where sku = 'CUNPNB483'), 2),"..
"(2557, (select id from catalogo where sku = 'CUNPNB483'), 3),"..
"(2558, (select id from catalogo where sku = 'CUNPNB483'), 4),"..
"(2559, (select id from catalogo where sku = 'CUNPNI050'), 2),"..
"(2560, (select id from catalogo where sku = 'CUNPNI050'), 3),"..
"(2561, (select id from catalogo where sku = 'CUNPNI050'), 4),"..
"(2562, (select id from catalogo where sku = 'CUNPNI050'), 5),"..
"(2563, (select id from catalogo where sku = 'CUNPNI051'), 2),"..
"(2564, (select id from catalogo where sku = 'CUNPNI051'), 3),"..
"(2565, (select id from catalogo where sku = 'CUNPNI051'), 4);"
db:exec( query2 )
--fase 18
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(2566, (select id from catalogo where sku = 'CUNPNI051'), 5),"..
"(2567, (select id from catalogo where sku = 'CUNPNI052'), 2),"..
"(2568, (select id from catalogo where sku = 'CUNPNI052'), 3),"..
"(2569, (select id from catalogo where sku = 'CUNPNI052'), 4),"..
"(2570, (select id from catalogo where sku = 'CUNPNI052'), 5),"..
"(2571, (select id from catalogo where sku = 'CUNPNI053'), 2),"..
"(2572, (select id from catalogo where sku = 'CUNPNI053'), 3),"..
"(2573, (select id from catalogo where sku = 'CUNPNI053'), 4),"..
"(2574, (select id from catalogo where sku = 'CUNPNI053'), 5),"..
"(2575, (select id from catalogo where sku = 'CUNPNI054'), 2),"..
"(2576, (select id from catalogo where sku = 'CUNPNI054'), 3),"..
"(2577, (select id from catalogo where sku = 'CUNPNI054'), 4),"..
"(2578, (select id from catalogo where sku = 'CUNPNI054'), 5),"..
"(2579, (select id from catalogo where sku = 'CUNPNI055'), 2),"..
"(2580, (select id from catalogo where sku = 'CUNPNI055'), 3),"..
"(2581, (select id from catalogo where sku = 'CUNPNI055'), 4),"..
"(2582, (select id from catalogo where sku = 'CUNPNI055'), 5),"..
"(2583, (select id from catalogo where sku = 'CUNPNI056'), 2),"..
"(2584, (select id from catalogo where sku = 'CUNPNI056'), 3),"..
"(2585, (select id from catalogo where sku = 'CUNPNI056'), 4),"..
"(2586, (select id from catalogo where sku = 'CUNPNI056'), 5),"..
"(2587, (select id from catalogo where sku = 'CUNPNJ005'), 2),"..
"(2588, (select id from catalogo where sku = 'CUNPNJ005'), 3),"..
"(2589, (select id from catalogo where sku = 'CUNPNJ005'), 4),"..
"(2590, (select id from catalogo where sku = 'CUNPNJ005'), 5),"..
"(2591, (select id from catalogo where sku = 'CUNPNJ006'), 2),"..
"(2592, (select id from catalogo where sku = 'CUNPNJ006'), 3),"..
"(2593, (select id from catalogo where sku = 'CUNPNJ006'), 4),"..
"(2594, (select id from catalogo where sku = 'CUNPNJ006'), 5),"..
"(2595, (select id from catalogo where sku = 'CUNPNJ007'), 2),"..
"(2596, (select id from catalogo where sku = 'CUNPNJ007'), 3),"..
"(2597, (select id from catalogo where sku = 'CUNPNJ007'), 4),"..
"(2598, (select id from catalogo where sku = 'CUNPNJ007'), 5),"..
"(2599, (select id from catalogo where sku = 'CUNPNJ008'), 2),"..
"(2600, (select id from catalogo where sku = 'CUNPNJ008'), 3),"..
"(2601, (select id from catalogo where sku = 'CUNPNJ008'), 4),"..
"(2602, (select id from catalogo where sku = 'CUNPNJ008'), 5),"..
"(2603, (select id from catalogo where sku = 'CUNPNJ009'), 2),"..
"(2604, (select id from catalogo where sku = 'CUNPNJ009'), 3),"..
"(2605, (select id from catalogo where sku = 'CUNPNJ009'), 4),"..
"(2606, (select id from catalogo where sku = 'CUNPNJ009'), 5),"..
"(2607, (select id from catalogo where sku = 'CUNPNJ010'), 2),"..
"(2608, (select id from catalogo where sku = 'CUNPNJ010'), 3),"..
"(2609, (select id from catalogo where sku = 'CUNPNJ010'), 4),"..
"(2610, (select id from catalogo where sku = 'CUNPNJ010'), 5),"..
"(2611, (select id from catalogo where sku = 'CUNSAB00109'), 2),"..
"(2612, (select id from catalogo where sku = 'CUNSAB00109'), 3),"..
"(2613, (select id from catalogo where sku = 'CUNSAB00109'), 4),"..
"(2614, (select id from catalogo where sku = 'CUNSAB00109'), 5),"..
"(2615, (select id from catalogo where sku = 'CUNSAB00111'), 2),"..
"(2616, (select id from catalogo where sku = 'CUNSAB00111'), 3),"..
"(2617, (select id from catalogo where sku = 'CUNSAB00111'), 4),"..
"(2618, (select id from catalogo where sku = 'CUNSAB00111'), 5),"..
"(2619, (select id from catalogo where sku = 'CUNSAB00113'), 2),"..
"(2620, (select id from catalogo where sku = 'CUNSAB00113'), 3),"..
"(2621, (select id from catalogo where sku = 'CUNSAB00113'), 4),"..
"(2622, (select id from catalogo where sku = 'CUNSAB00113'), 5),"..
"(2623, (select id from catalogo where sku = 'CUNSAB00117'), 2),"..
"(2624, (select id from catalogo where sku = 'CUNSAB00117'), 3),"..
"(2625, (select id from catalogo where sku = 'CUNSAB00117'), 4),"..
"(2626, (select id from catalogo where sku = 'CUNSAB00117'), 5),"..
"(2627, (select id from catalogo where sku = 'CUNSAB00138'), 2),"..
"(2628, (select id from catalogo where sku = 'CUNSAB00138'), 3),"..
"(2629, (select id from catalogo where sku = 'CUNSAB00138'), 4),"..
"(2630, (select id from catalogo where sku = 'CUNSAB00138'), 5),"..
"(2631, (select id from catalogo where sku = 'CUNSAB00140'), 2),"..
"(2632, (select id from catalogo where sku = 'CUNSAB00140'), 3),"..
"(2633, (select id from catalogo where sku = 'CUNSAB00140'), 4),"..
"(2634, (select id from catalogo where sku = 'CUNSAB00140'), 5),"..
"(2635, (select id from catalogo where sku = 'CUNSAB00171'), 2),"..
"(2636, (select id from catalogo where sku = 'CUNSAB00171'), 3),"..
"(2637, (select id from catalogo where sku = 'CUNSAB00171'), 4),"..
"(2638, (select id from catalogo where sku = 'CUNSAB00171'), 5),"..
"(2639, (select id from catalogo where sku = 'CUNSAB001XXL09'), 6),"..
"(2640, (select id from catalogo where sku = 'CUNSAB001XXL11'), 6),"..
"(2641, (select id from catalogo where sku = 'CUNSAB001XXL13'), 6),"..
"(2642, (select id from catalogo where sku = 'CUNSAB001XXL17'), 6),"..
"(2643, (select id from catalogo where sku = 'CUNSAB001XXL29'), 6),"..
"(2644, (select id from catalogo where sku = 'CUNSAB001XXL38'), 6),"..
"(2645, (select id from catalogo where sku = 'CUNSAB001XXL40'), 6),"..
"(2646, (select id from catalogo where sku = 'CUNSNB00109'), 2),"..
"(2647, (select id from catalogo where sku = 'CUNSNB00109'), 3),"..
"(2648, (select id from catalogo where sku = 'CUNSNB00109'), 4),"..
"(2649, (select id from catalogo where sku = 'CUNSNB00109'), 5),"..
"(2650, (select id from catalogo where sku = 'CUNSNB00111'), 2),"..
"(2651, (select id from catalogo where sku = 'CUNSNB00111'), 3),"..
"(2652, (select id from catalogo where sku = 'CUNSNB00111'), 4),"..
"(2653, (select id from catalogo where sku = 'CUNSNB00111'), 5),"..
"(2654, (select id from catalogo where sku = 'CUNSNB00113'), 2),"..
"(2655, (select id from catalogo where sku = 'CUNSNB00113'), 3),"..
"(2656, (select id from catalogo where sku = 'CUNSNB00113'), 4),"..
"(2657, (select id from catalogo where sku = 'CUNSNB00113'), 5),"..
"(2658, (select id from catalogo where sku = 'CUNVCOV0303'), 2),"..
"(2659, (select id from catalogo where sku = 'CUNVCOV0303'), 3),"..
"(2660, (select id from catalogo where sku = 'CUNVCOV0303'), 4),"..
"(2661, (select id from catalogo where sku = 'CUNVCOV0303'), 5),"..
"(2662, (select id from catalogo where sku = 'CUNVCOV0304'), 2),"..
"(2663, (select id from catalogo where sku = 'CUNVCOV0304'), 3),"..
"(2664, (select id from catalogo where sku = 'CUNVCOV0304'), 4),"..
"(2665, (select id from catalogo where sku = 'CUNVCOV0304'), 5),"..
"(2666, (select id from catalogo where sku = 'CUNVCOV0311'), 2),"..
"(2667, (select id from catalogo where sku = 'CUNVCOV0311'), 3),"..
"(2668, (select id from catalogo where sku = 'CUNVCOV0311'), 4),"..
"(2669, (select id from catalogo where sku = 'CUNVCOV0311'), 5),"..
"(2670, (select id from catalogo where sku = 'CUNVCOV0313'), 2),"..
"(2671, (select id from catalogo where sku = 'CUNVCOV0313'), 3),"..
"(2672, (select id from catalogo where sku = 'CUNVCOV0313'), 4),"..
"(2673, (select id from catalogo where sku = 'CUNVCOV0313'), 5),"..
"(2674, (select id from catalogo where sku = 'CUNVCOV0316'), 2),"..
"(2675, (select id from catalogo where sku = 'CUNVCOV0316'), 3),"..
"(2676, (select id from catalogo where sku = 'CUNVCOV0316'), 4),"..
"(2677, (select id from catalogo where sku = 'CUNVCOV0316'), 5),"..
"(2678, (select id from catalogo where sku = 'CUNVCOV0329'), 2),"..
"(2679, (select id from catalogo where sku = 'CUNVCOV0329'), 3),"..
"(2680, (select id from catalogo where sku = 'CUNVCOV0329'), 4),"..
"(2681, (select id from catalogo where sku = 'CUNVCOV0329'), 5),"..
"(2682, (select id from catalogo where sku = 'CUNVCOV0330'), 2),"..
"(2683, (select id from catalogo where sku = 'CUNVCOV0330'), 3),"..
"(2684, (select id from catalogo where sku = 'CUNVCOV0330'), 4),"..
"(2685, (select id from catalogo where sku = 'CUNVCOV0330'), 5),"..
"(2686, (select id from catalogo where sku = 'CUNVCOV0337'), 2),"..
"(2687, (select id from catalogo where sku = 'CUNVCOV0337'), 3),"..
"(2688, (select id from catalogo where sku = 'CUNVCOV0337'), 4),"..
"(2689, (select id from catalogo where sku = 'CUNVCOV0337'), 5),"..
"(2690, (select id from catalogo where sku = 'CUNVIBSAN03'), 8),"..
"(2691, (select id from catalogo where sku = 'CUNVIBSAN04'), 8),"..
"(2692, (select id from catalogo where sku = 'CUNVIBSAN11'), 8),"..
"(2693, (select id from catalogo where sku = 'CUNVIBSAN13'), 8),"..
"(2694, (select id from catalogo where sku = 'CUNVIBSAN16'), 8),"..
"(2695, (select id from catalogo where sku = 'CUNVIBSAN29'), 8),"..
"(2696, (select id from catalogo where sku = 'CUNVIBSAN30'), 8),"..
"(2697, (select id from catalogo where sku = 'CUNVIBSAN37'), 8),"..
"(2698, (select id from catalogo where sku = 'DELCOA00111'), 2),"..
"(2699, (select id from catalogo where sku = 'DELCOA00111'), 3),"..
"(2700, (select id from catalogo where sku = 'DELCOA00111'), 4),"..
"(2701, (select id from catalogo where sku = 'DELCOA00111'), 5),"..
"(2702, (select id from catalogo where sku = 'DELCOA00112'), 2),"..
"(2703, (select id from catalogo where sku = 'DELCOA00112'), 3),"..
"(2704, (select id from catalogo where sku = 'DELCOA00112'), 4),"..
"(2705, (select id from catalogo where sku = 'DELCOA00112'), 5),"..
"(2706, (select id from catalogo where sku = 'DELCOA00128'), 2),"..
"(2707, (select id from catalogo where sku = 'DELCOA00128'), 3),"..
"(2708, (select id from catalogo where sku = 'DELCOA00128'), 4),"..
"(2709, (select id from catalogo where sku = 'DELCOA00128'), 5),"..
"(2710, (select id from catalogo where sku = 'DELCOA00129'), 2),"..
"(2711, (select id from catalogo where sku = 'DELCOA00129'), 3),"..
"(2712, (select id from catalogo where sku = 'DELCOA00129'), 4),"..
"(2713, (select id from catalogo where sku = 'DELCOA00129'), 5),"..
"(2714, (select id from catalogo where sku = 'DELCOA00130'), 2),"..
"(2715, (select id from catalogo where sku = 'DELCOA00130'), 3),"..
"(2716, (select id from catalogo where sku = 'DELCOA00130'), 4);"
db:exec( query2 )
--fase 19
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(2717, (select id from catalogo where sku = 'DELCOA00130'), 5),"..
"(2718, (select id from catalogo where sku = 'DELCOA00130'), 6),"..
"(2719, (select id from catalogo where sku = 'DELCOA00140'), 2),"..
"(2720, (select id from catalogo where sku = 'DELCOA00140'), 3),"..
"(2721, (select id from catalogo where sku = 'DELCOA00140'), 4),"..
"(2722, (select id from catalogo where sku = 'DELCOA00140'), 5),"..
"(2723, (select id from catalogo where sku = 'DELGDKPLU12'), 8),"..
"(2724, (select id from catalogo where sku = 'DELGDKPLU17'), 8),"..
"(2725, (select id from catalogo where sku = 'DELGDKPLU18'), 8),"..
"(2726, (select id from catalogo where sku = 'DELGDKPLU40'), 8),"..
"(2727, (select id from catalogo where sku = 'DELGDKPLU71'), 8),"..
"(2728, (select id from catalogo where sku = 'DELGMBDAM04'), 8),"..
"(2729, (select id from catalogo where sku = 'DELGMBDAM12'), 8),"..
"(2730, (select id from catalogo where sku = 'DELGMBDAM17'), 8),"..
"(2731, (select id from catalogo where sku = 'DELGMBDAM18'), 8),"..
"(2732, (select id from catalogo where sku = 'DELGMBDAM19'), 8),"..
"(2733, (select id from catalogo where sku = 'DELGMBDAM29'), 8),"..
"(2734, (select id from catalogo where sku = 'DELGMBDAM40'), 8),"..
"(2735, (select id from catalogo where sku = 'DELGMBDAM41'), 8),"..
"(2736, (select id from catalogo where sku = 'DELGMBDES04'), 8),"..
"(2737, (select id from catalogo where sku = 'DELGMBDES05'), 8),"..
"(2738, (select id from catalogo where sku = 'DELGMBDES06'), 8),"..
"(2739, (select id from catalogo where sku = 'DELGMBDES10'), 8),"..
"(2740, (select id from catalogo where sku = 'DELGMBDES11'), 8),"..
"(2741, (select id from catalogo where sku = 'DELGMBDES12'), 8),"..
"(2742, (select id from catalogo where sku = 'DELGMBDES13'), 8),"..
"(2743, (select id from catalogo where sku = 'DELGMBDES15'), 8),"..
"(2744, (select id from catalogo where sku = 'DELGMBDES16'), 8),"..
"(2745, (select id from catalogo where sku = 'DELGMBDES21'), 8),"..
"(2746, (select id from catalogo where sku = 'DELGMBDES25'), 8),"..
"(2747, (select id from catalogo where sku = 'DELGMBDES26'), 8),"..
"(2748, (select id from catalogo where sku = 'DELGMBDES28'), 8),"..
"(2749, (select id from catalogo where sku = 'DELGMBDES30'), 8),"..
"(2750, (select id from catalogo where sku = 'DELGMBDES32'), 8),"..
"(2751, (select id from catalogo where sku = 'DELGMBDES34'), 8),"..
"(2752, (select id from catalogo where sku = 'DELGMBDES35'), 8),"..
"(2753, (select id from catalogo where sku = 'DELGMBDES37'), 8),"..
"(2754, (select id from catalogo where sku = 'DELGMBPES11'), 8),"..
"(2755, (select id from catalogo where sku = 'DRPCOA00105'), 2),"..
"(2756, (select id from catalogo where sku = 'DRPCOA00105'), 3),"..
"(2757, (select id from catalogo where sku = 'DRPCOA00105'), 4),"..
"(2758, (select id from catalogo where sku = 'DRPCOA00105'), 5),"..
"(2759, (select id from catalogo where sku = 'DRPCOA00105-05'), 2),"..
"(2760, (select id from catalogo where sku = 'DRPCOA00105-05'), 3),"..
"(2761, (select id from catalogo where sku = 'DRPCOA00105-05'), 4),"..
"(2762, (select id from catalogo where sku = 'DRPCOA00105-05'), 5),"..
"(2763, (select id from catalogo where sku = 'DRPCOA00111'), 2),"..
"(2764, (select id from catalogo where sku = 'DRPCOA00111'), 3),"..
"(2765, (select id from catalogo where sku = 'DRPCOA00111'), 4),"..
"(2766, (select id from catalogo where sku = 'DRPCOA00111'), 5),"..
"(2767, (select id from catalogo where sku = 'DRPCOA00115'), 2),"..
"(2768, (select id from catalogo where sku = 'DRPCOA00115'), 3),"..
"(2769, (select id from catalogo where sku = 'DRPCOA00115'), 4),"..
"(2770, (select id from catalogo where sku = 'DRPCOA00115'), 5),"..
"(2771, (select id from catalogo where sku = 'DRPCOA00128'), 2),"..
"(2772, (select id from catalogo where sku = 'DRPCOA00128'), 3),"..
"(2773, (select id from catalogo where sku = 'DRPCOA00128'), 4),"..
"(2774, (select id from catalogo where sku = 'DRPCOA00128'), 5),"..
"(2775, (select id from catalogo where sku = 'DRPCOA00130'), 2),"..
"(2776, (select id from catalogo where sku = 'DRPCOA00130'), 3),"..
"(2777, (select id from catalogo where sku = 'DRPCOA00130'), 4),"..
"(2778, (select id from catalogo where sku = 'DRPCOA00130'), 5),"..
"(2779, (select id from catalogo where sku = 'DRPCOA001XXL05'), 6),"..
"(2780, (select id from catalogo where sku = 'DRPCOA001XXL11'), 6),"..
"(2781, (select id from catalogo where sku = 'DRPCOA001XXL15'), 6),"..
"(2782, (select id from catalogo where sku = 'DRPCOA001XXL28'), 6),"..
"(2783, (select id from catalogo where sku = 'DRPCOA001XXL30'), 6),"..
"(2784, (select id from catalogo where sku = 'DRPGMBDES04'), 8),"..
"(2785, (select id from catalogo where sku = 'DRPGMBDES05'), 8),"..
"(2786, (select id from catalogo where sku = 'DRPGMBDES06'), 8),"..
"(2787, (select id from catalogo where sku = 'DRPGMBDES10'), 8),"..
"(2788, (select id from catalogo where sku = 'DRPGMBDES11'), 8),"..
"(2789, (select id from catalogo where sku = 'DRPGMBDES12'), 8),"..
"(2790, (select id from catalogo where sku = 'DRPGMBDES13'), 8),"..
"(2791, (select id from catalogo where sku = 'DRPGMBDES15'), 8),"..
"(2792, (select id from catalogo where sku = 'DRPGMBDES16'), 8),"..
"(2793, (select id from catalogo where sku = 'DRPGMBDES21'), 8),"..
"(2794, (select id from catalogo where sku = 'DRPGMBDES25'), 8),"..
"(2795, (select id from catalogo where sku = 'DRPGMBDES26'), 8),"..
"(2796, (select id from catalogo where sku = 'DRPGMBDES28'), 8),"..
"(2797, (select id from catalogo where sku = 'DRPGMBDES30'), 8),"..
"(2798, (select id from catalogo where sku = 'DRPGMBDES32'), 8),"..
"(2799, (select id from catalogo where sku = 'DRPGMBDES34'), 8),"..
"(2800, (select id from catalogo where sku = 'DRPGMBDES35'), 8),"..
"(2801, (select id from catalogo where sku = 'DRPGMBDES37'), 8),"..
"(2802, (select id from catalogo where sku = 'DRPGMBNIÑ02'), 8),"..
"(2803, (select id from catalogo where sku = 'DRPGMBNIÑ10'), 8),"..
"(2804, (select id from catalogo where sku = 'DRPGMBNIÑ11'), 8),"..
"(2805, (select id from catalogo where sku = 'DRPGMBNIÑ12'), 8),"..
"(2806, (select id from catalogo where sku = 'DRPGMBNIÑ15'), 8),"..
"(2807, (select id from catalogo where sku = 'DRTGMBDES04'), 8),"..
"(2808, (select id from catalogo where sku = 'DRTGMBDES05'), 8),"..
"(2809, (select id from catalogo where sku = 'DRTGMBDES06'), 8),"..
"(2810, (select id from catalogo where sku = 'DRTGMBDES10'), 8),"..
"(2811, (select id from catalogo where sku = 'DRTGMBDES11'), 8),"..
"(2812, (select id from catalogo where sku = 'DRTGMBDES12'), 8),"..
"(2813, (select id from catalogo where sku = 'DRTGMBDES13'), 8),"..
"(2814, (select id from catalogo where sku = 'DRTGMBDES15'), 8),"..
"(2815, (select id from catalogo where sku = 'DRTGMBDES16'), 8),"..
"(2816, (select id from catalogo where sku = 'DRTGMBDES21'), 8),"..
"(2817, (select id from catalogo where sku = 'DRTGMBDES25'), 8),"..
"(2818, (select id from catalogo where sku = 'DRTGMBDES26'), 8),"..
"(2819, (select id from catalogo where sku = 'DRTGMBDES28'), 8),"..
"(2820, (select id from catalogo where sku = 'DRTGMBDES30'), 8),"..
"(2821, (select id from catalogo where sku = 'DRTGMBDES32'), 8),"..
"(2822, (select id from catalogo where sku = 'DRTGMBDES34'), 8),"..
"(2823, (select id from catalogo where sku = 'DRTGMBDES35'), 8),"..
"(2824, (select id from catalogo where sku = 'DRTGMBDES37'), 8),"..
"(2825, (select id from catalogo where sku = 'DRTGMBSAN02'), 8),"..
"(2826, (select id from catalogo where sku = 'DRTGMBSAN03'), 8),"..
"(2827, (select id from catalogo where sku = 'DRTGMBSAN05'), 8),"..
"(2828, (select id from catalogo where sku = 'DRTGMBSAN06'), 8),"..
"(2829, (select id from catalogo where sku = 'DRTGMBSAN07'), 8),"..
"(2830, (select id from catalogo where sku = 'DRTGMBSAN11'), 8),"..
"(2831, (select id from catalogo where sku = 'DRTGMBSAN13'), 8),"..
"(2832, (select id from catalogo where sku = 'DRTGMBSAN20'), 8),"..
"(2833, (select id from catalogo where sku = 'DRTGMBSAN22'), 8),"..
"(2834, (select id from catalogo where sku = 'DRTGMBSAN30'), 8),"..
"(2835, (select id from catalogo where sku = 'DRTGMBSAN32'), 8),"..
"(2836, (select id from catalogo where sku = 'DRTGMBSAN33'), 8),"..
"(2837, (select id from catalogo where sku = 'DRTGMBSAN36'), 8),"..
"(2838, (select id from catalogo where sku = 'DRTGMBSAN39'), 8),"..
"(2839, (select id from catalogo where sku = 'DRTGMBSAN43'), 8),"..
"(2840, (select id from catalogo where sku = 'DRTGMBSAN45'), 8),"..
"(2841, (select id from catalogo where sku = 'DRTGMBSAN49'), 8),"..
"(2842, (select id from catalogo where sku = 'DRTGMBSAN51'), 8),"..
"(2843, (select id from catalogo where sku = 'EDMCOA00102'), 2),"..
"(2844, (select id from catalogo where sku = 'EDMCOA00102'), 3),"..
"(2845, (select id from catalogo where sku = 'EDMCOA00102'), 4),"..
"(2846, (select id from catalogo where sku = 'EDMCOA00102'), 5),"..
"(2847, (select id from catalogo where sku = 'EDMCOA00106'), 2),"..
"(2848, (select id from catalogo where sku = 'EDMCOA00106'), 3),"..
"(2849, (select id from catalogo where sku = 'EDMCOA00106'), 4),"..
"(2850, (select id from catalogo where sku = 'EDMCOA00106'), 5),"..
"(2851, (select id from catalogo where sku = 'EDMCOA00111'), 2),"..
"(2852, (select id from catalogo where sku = 'EDMCOA00111'), 3),"..
"(2853, (select id from catalogo where sku = 'EDMCOA00111'), 4),"..
"(2854, (select id from catalogo where sku = 'EDMCOA00111'), 5),"..
"(2855, (select id from catalogo where sku = 'EDMCOA00112'), 2),"..
"(2856, (select id from catalogo where sku = 'EDMCOA00112'), 3),"..
"(2857, (select id from catalogo where sku = 'EDMCOA00112'), 4),"..
"(2858, (select id from catalogo where sku = 'EDMCOA00112'), 5),"..
"(2859, (select id from catalogo where sku = 'EDMCOA00113'), 2),"..
"(2860, (select id from catalogo where sku = 'EDMCOA00113'), 3),"..
"(2861, (select id from catalogo where sku = 'EDMCOA00113'), 4),"..
"(2862, (select id from catalogo where sku = 'EDMCOA00113'), 5),"..
"(2863, (select id from catalogo where sku = 'EDMCOA00115'), 2),"..
"(2864, (select id from catalogo where sku = 'EDMCOA00115'), 3),"..
"(2865, (select id from catalogo where sku = 'EDMCOA00115'), 4),"..
"(2866, (select id from catalogo where sku = 'EDMCOA00115'), 5),"..
"(2867, (select id from catalogo where sku = 'EDMCOA00126'), 2);"
db:exec( query2 )
--fase 20
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(2868, (select id from catalogo where sku = 'EDMCOA00126'), 3),"..
"(2869, (select id from catalogo where sku = 'EDMCOA00126'), 4),"..
"(2870, (select id from catalogo where sku = 'EDMCOA00126'), 5),"..
"(2871, (select id from catalogo where sku = 'EDMCOA00128'), 2),"..
"(2872, (select id from catalogo where sku = 'EDMCOA00128'), 3),"..
"(2873, (select id from catalogo where sku = 'EDMCOA00128'), 4),"..
"(2874, (select id from catalogo where sku = 'EDMCOA00128'), 5),"..
"(2875, (select id from catalogo where sku = 'EDMCOA00130'), 2),"..
"(2876, (select id from catalogo where sku = 'EDMCOA00130'), 3),"..
"(2877, (select id from catalogo where sku = 'EDMCOA00130'), 4),"..
"(2878, (select id from catalogo where sku = 'EDMCOA00130'), 5),"..
"(2879, (select id from catalogo where sku = 'EDMCOA00132'), 2),"..
"(2880, (select id from catalogo where sku = 'EDMCOA00132'), 3),"..
"(2881, (select id from catalogo where sku = 'EDMCOA00132'), 4),"..
"(2882, (select id from catalogo where sku = 'EDMCOA00132'), 5),"..
"(2883, (select id from catalogo where sku = 'EDMCOA00135'), 2),"..
"(2884, (select id from catalogo where sku = 'EDMCOA00135'), 3),"..
"(2885, (select id from catalogo where sku = 'EDMCOA00135'), 4),"..
"(2886, (select id from catalogo where sku = 'EDMCOA00135'), 5),"..
"(2887, (select id from catalogo where sku = 'EDMCOA001XXL02'), 6),"..
"(2888, (select id from catalogo where sku = 'EDMCOA001XXL06'), 6),"..
"(2889, (select id from catalogo where sku = 'EDMCOA001XXL11'), 6),"..
"(2890, (select id from catalogo where sku = 'EDMCOA001XXL12'), 6),"..
"(2891, (select id from catalogo where sku = 'EDMCOA001XXL13'), 6),"..
"(2892, (select id from catalogo where sku = 'EDMCOA001XXL15'), 6),"..
"(2893, (select id from catalogo where sku = 'EDMCOA001XXL26'), 6),"..
"(2894, (select id from catalogo where sku = 'EDMCOA001XXL28'), 6),"..
"(2895, (select id from catalogo where sku = 'EDMCOA001XXL30'), 6),"..
"(2896, (select id from catalogo where sku = 'EDMCOA001XXL32'), 6),"..
"(2897, (select id from catalogo where sku = 'EDMCOA001XXL35'), 6),"..
"(2898, (select id from catalogo where sku = 'EDMGDKMFI03'), 8),"..
"(2899, (select id from catalogo where sku = 'EDMGDKMFI11'), 8),"..
"(2900, (select id from catalogo where sku = 'EDMGDKMFI13'), 8),"..
"(2901, (select id from catalogo where sku = 'EDMGDKMFI16'), 8),"..
"(2902, (select id from catalogo where sku = 'EDMGMBDAM04'), 8),"..
"(2903, (select id from catalogo where sku = 'EDMGMBDAM12'), 8),"..
"(2904, (select id from catalogo where sku = 'EDMGMBDAM17'), 8),"..
"(2905, (select id from catalogo where sku = 'EDMGMBDAM18'), 8),"..
"(2906, (select id from catalogo where sku = 'EDMGMBDAM19'), 8),"..
"(2907, (select id from catalogo where sku = 'EDMGMBDAM29'), 8),"..
"(2908, (select id from catalogo where sku = 'EDMGMBDAM40'), 8),"..
"(2909, (select id from catalogo where sku = 'EDMGMBDAM41'), 8),"..
"(2910, (select id from catalogo where sku = 'EDMGMBDES04'), 8),"..
"(2911, (select id from catalogo where sku = 'EDMGMBDES05'), 8),"..
"(2912, (select id from catalogo where sku = 'EDMGMBDES06'), 8),"..
"(2913, (select id from catalogo where sku = 'EDMGMBDES10'), 8),"..
"(2914, (select id from catalogo where sku = 'EDMGMBDES11'), 8),"..
"(2915, (select id from catalogo where sku = 'EDMGMBDES12'), 8),"..
"(2916, (select id from catalogo where sku = 'EDMGMBDES13'), 8),"..
"(2917, (select id from catalogo where sku = 'EDMGMBDES15'), 8),"..
"(2918, (select id from catalogo where sku = 'EDMGMBDES16'), 8),"..
"(2919, (select id from catalogo where sku = 'EDMGMBDES21'), 8),"..
"(2920, (select id from catalogo where sku = 'EDMGMBDES25'), 8),"..
"(2921, (select id from catalogo where sku = 'EDMGMBDES26'), 8),"..
"(2922, (select id from catalogo where sku = 'EDMGMBDES28'), 8),"..
"(2923, (select id from catalogo where sku = 'EDMGMBDES30'), 8),"..
"(2924, (select id from catalogo where sku = 'EDMGMBDES32'), 8),"..
"(2925, (select id from catalogo where sku = 'EDMGMBDES34'), 8),"..
"(2926, (select id from catalogo where sku = 'EDMGMBDES35'), 8),"..
"(2927, (select id from catalogo where sku = 'EDMGMBDES37'), 8),"..
"(2928, (select id from catalogo where sku = 'EDMGMBSAN02'), 8),"..
"(2929, (select id from catalogo where sku = 'EDMGMBSAN03'), 8),"..
"(2930, (select id from catalogo where sku = 'EDMGMBSAN05'), 8),"..
"(2931, (select id from catalogo where sku = 'EDMGMBSAN06'), 8),"..
"(2932, (select id from catalogo where sku = 'EDMGMBSAN07'), 8),"..
"(2933, (select id from catalogo where sku = 'EDMGMBSAN11'), 8),"..
"(2934, (select id from catalogo where sku = 'EDMGMBSAN13'), 8),"..
"(2935, (select id from catalogo where sku = 'EDMGMBSAN20'), 8),"..
"(2936, (select id from catalogo where sku = 'EDMGMBSAN22'), 8),"..
"(2937, (select id from catalogo where sku = 'EDMGMBSAN30'), 8),"..
"(2938, (select id from catalogo where sku = 'EDMGMBSAN32'), 8),"..
"(2939, (select id from catalogo where sku = 'EDMGMBSAN33'), 8),"..
"(2940, (select id from catalogo where sku = 'EDMGMBSAN36'), 8),"..
"(2941, (select id from catalogo where sku = 'EDMGMBSAN39'), 8),"..
"(2942, (select id from catalogo where sku = 'EDMGMBSAN43'), 8),"..
"(2943, (select id from catalogo where sku = 'EDMGMBSAN45'), 8),"..
"(2944, (select id from catalogo where sku = 'EDMGMBSAN49'), 8),"..
"(2945, (select id from catalogo where sku = 'EDMGMBSAN51'), 8),"..
"(2946, (select id from catalogo where sku = 'EDOCOA0102'), 2),"..
"(2947, (select id from catalogo where sku = 'EDOCOA0102'), 3),"..
"(2948, (select id from catalogo where sku = 'EDOCOA0102'), 4),"..
"(2949, (select id from catalogo where sku = 'EDOCOA0102'), 5),"..
"(2950, (select id from catalogo where sku = 'EDOCOA0105'), 2),"..
"(2951, (select id from catalogo where sku = 'EDOCOA0105'), 3),"..
"(2952, (select id from catalogo where sku = 'EDOCOA0105'), 4),"..
"(2953, (select id from catalogo where sku = 'EDOCOA0105'), 5),"..
"(2954, (select id from catalogo where sku = 'EDOCOA0106'), 2),"..
"(2955, (select id from catalogo where sku = 'EDOCOA0106'), 3),"..
"(2956, (select id from catalogo where sku = 'EDOCOA0106'), 4),"..
"(2957, (select id from catalogo where sku = 'EDOCOA0106'), 5),"..
"(2958, (select id from catalogo where sku = 'EDOCOA0110'), 2),"..
"(2959, (select id from catalogo where sku = 'EDOCOA0110'), 3),"..
"(2960, (select id from catalogo where sku = 'EDOCOA0110'), 4),"..
"(2961, (select id from catalogo where sku = 'EDOCOA0110'), 5),"..
"(2962, (select id from catalogo where sku = 'EDOCOA0111'), 2),"..
"(2963, (select id from catalogo where sku = 'EDOCOA0111'), 3),"..
"(2964, (select id from catalogo where sku = 'EDOCOA0111'), 4),"..
"(2965, (select id from catalogo where sku = 'EDOCOA0111'), 5),"..
"(2966, (select id from catalogo where sku = 'EDOCOA0112'), 2),"..
"(2967, (select id from catalogo where sku = 'EDOCOA0112'), 3),"..
"(2968, (select id from catalogo where sku = 'EDOCOA0112'), 4),"..
"(2969, (select id from catalogo where sku = 'EDOCOA0112'), 5),"..
"(2970, (select id from catalogo where sku = 'EDOCOA0113'), 2),"..
"(2971, (select id from catalogo where sku = 'EDOCOA0113'), 3),"..
"(2972, (select id from catalogo where sku = 'EDOCOA0113'), 4),"..
"(2973, (select id from catalogo where sku = 'EDOCOA0113'), 5),"..
"(2974, (select id from catalogo where sku = 'EDOCOA0115'), 2),"..
"(2975, (select id from catalogo where sku = 'EDOCOA0115'), 3),"..
"(2976, (select id from catalogo where sku = 'EDOCOA0115'), 4),"..
"(2977, (select id from catalogo where sku = 'EDOCOA0115'), 5),"..
"(2978, (select id from catalogo where sku = 'EDOCOA0121'), 2),"..
"(2979, (select id from catalogo where sku = 'EDOCOA0121'), 3),"..
"(2980, (select id from catalogo where sku = 'EDOCOA0121'), 4),"..
"(2981, (select id from catalogo where sku = 'EDOCOA0121'), 5),"..
"(2982, (select id from catalogo where sku = 'EDOCOA0125'), 2),"..
"(2983, (select id from catalogo where sku = 'EDOCOA0125'), 3),"..
"(2984, (select id from catalogo where sku = 'EDOCOA0125'), 4),"..
"(2985, (select id from catalogo where sku = 'EDOCOA0125'), 5),"..
"(2986, (select id from catalogo where sku = 'EDOCOA0126'), 2),"..
"(2987, (select id from catalogo where sku = 'EDOCOA0126'), 3),"..
"(2988, (select id from catalogo where sku = 'EDOCOA0126'), 4),"..
"(2989, (select id from catalogo where sku = 'EDOCOA0126'), 5),"..
"(2990, (select id from catalogo where sku = 'EDOCOA0128'), 2),"..
"(2991, (select id from catalogo where sku = 'EDOCOA0128'), 3),"..
"(2992, (select id from catalogo where sku = 'EDOCOA0128'), 4),"..
"(2993, (select id from catalogo where sku = 'EDOCOA0128'), 5),"..
"(2994, (select id from catalogo where sku = 'EDOCOA0130'), 2),"..
"(2995, (select id from catalogo where sku = 'EDOCOA0130'), 3),"..
"(2996, (select id from catalogo where sku = 'EDOCOA0130'), 4),"..
"(2997, (select id from catalogo where sku = 'EDOCOA0130'), 5),"..
"(2998, (select id from catalogo where sku = 'EDOCOA0132'), 2),"..
"(2999, (select id from catalogo where sku = 'EDOCOA0132'), 3),"..
"(3000, (select id from catalogo where sku = 'EDOCOA0132'), 4),"..
"(3001, (select id from catalogo where sku = 'EDOCOA0132'), 5),"..
"(3002, (select id from catalogo where sku = 'EDOCOA0134'), 2),"..
"(3003, (select id from catalogo where sku = 'EDOCOA0134'), 3),"..
"(3004, (select id from catalogo where sku = 'EDOCOA0134'), 4),"..
"(3005, (select id from catalogo where sku = 'EDOCOA0134'), 5),"..
"(3006, (select id from catalogo where sku = 'EDOCOA0135'), 2),"..
"(3007, (select id from catalogo where sku = 'EDOCOA0135'), 3),"..
"(3008, (select id from catalogo where sku = 'EDOCOA0135'), 4),"..
"(3009, (select id from catalogo where sku = 'EDOCOA0135'), 5),"..
"(3010, (select id from catalogo where sku = 'EDOCOA01XXL02'), 6),"..
"(3011, (select id from catalogo where sku = 'EDOCOA01XXL05'), 6),"..
"(3012, (select id from catalogo where sku = 'EDOCOA01XXL06'), 6),"..
"(3013, (select id from catalogo where sku = 'EDOCOA01XXL10'), 6),"..
"(3014, (select id from catalogo where sku = 'EDOCOA01XXL11'), 6),"..
"(3015, (select id from catalogo where sku = 'EDOCOA01XXL12'), 6),"..
"(3016, (select id from catalogo where sku = 'EDOCOA01XXL13'), 6),"..
"(3017, (select id from catalogo where sku = 'EDOCOA01XXL15'), 6),"..
"(3018, (select id from catalogo where sku = 'EDOCOA01XXL21'), 6);"
db:exec( query2 )
--fase 21
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3019, (select id from catalogo where sku = 'EDOCOA01XXL25'), 6),"..
"(3020, (select id from catalogo where sku = 'EDOCOA01XXL26'), 6),"..
"(3021, (select id from catalogo where sku = 'EDOCOA01XXL28'), 6),"..
"(3022, (select id from catalogo where sku = 'EDOCOA01XXL30'), 6),"..
"(3023, (select id from catalogo where sku = 'EDOCOA01XXL32'), 6),"..
"(3024, (select id from catalogo where sku = 'EDOCOA01XXL34'), 6),"..
"(3025, (select id from catalogo where sku = 'EDOCOA01XXL35'), 6),"..
"(3026, (select id from catalogo where sku = 'EDOGDKMFI03'), 8),"..
"(3027, (select id from catalogo where sku = 'EDOGDKMFI11'), 8),"..
"(3028, (select id from catalogo where sku = 'EDOGDKMFI13'), 8),"..
"(3029, (select id from catalogo where sku = 'EDOGDKMFI16'), 8),"..
"(3030, (select id from catalogo where sku = 'EDOGDKNBA03'), 8),"..
"(3031, (select id from catalogo where sku = 'EDOGMBARC04'), 8),"..
"(3032, (select id from catalogo where sku = 'EDOGMBARC18'), 8),"..
"(3033, (select id from catalogo where sku = 'EDOGMBARC29'), 8),"..
"(3034, (select id from catalogo where sku = 'EDOGMBARC38'), 8),"..
"(3035, (select id from catalogo where sku = 'EDOGMBDAM04'), 8),"..
"(3036, (select id from catalogo where sku = 'EDOGMBDAM12'), 8),"..
"(3037, (select id from catalogo where sku = 'EDOGMBDAM17'), 8),"..
"(3038, (select id from catalogo where sku = 'EDOGMBDAM18'), 8),"..
"(3039, (select id from catalogo where sku = 'EDOGMBDAM19'), 8),"..
"(3040, (select id from catalogo where sku = 'EDOGMBDAM29'), 8),"..
"(3041, (select id from catalogo where sku = 'EDOGMBDAM40'), 8),"..
"(3042, (select id from catalogo where sku = 'EDOGMBDAM41'), 8),"..
"(3043, (select id from catalogo where sku = 'EDOGMBDES04'), 8),"..
"(3044, (select id from catalogo where sku = 'EDOGMBDES05'), 8),"..
"(3045, (select id from catalogo where sku = 'EDOGMBDES06'), 8),"..
"(3046, (select id from catalogo where sku = 'EDOGMBDES10'), 8),"..
"(3047, (select id from catalogo where sku = 'EDOGMBDES11'), 8),"..
"(3048, (select id from catalogo where sku = 'EDOGMBDES12'), 8),"..
"(3049, (select id from catalogo where sku = 'EDOGMBDES13'), 8),"..
"(3050, (select id from catalogo where sku = 'EDOGMBDES15'), 8),"..
"(3051, (select id from catalogo where sku = 'EDOGMBDES16'), 8),"..
"(3052, (select id from catalogo where sku = 'EDOGMBDES21'), 8),"..
"(3053, (select id from catalogo where sku = 'EDOGMBDES25'), 8),"..
"(3054, (select id from catalogo where sku = 'EDOGMBDES26'), 8),"..
"(3055, (select id from catalogo where sku = 'EDOGMBDES28'), 8),"..
"(3056, (select id from catalogo where sku = 'EDOGMBDES30'), 8),"..
"(3057, (select id from catalogo where sku = 'EDOGMBDES32'), 8),"..
"(3058, (select id from catalogo where sku = 'EDOGMBDES34'), 8),"..
"(3059, (select id from catalogo where sku = 'EDOGMBDES35'), 8),"..
"(3060, (select id from catalogo where sku = 'EDOGMBDES37'), 8),"..
"(3061, (select id from catalogo where sku = 'EDOGMBNIÑ02'), 8),"..
"(3062, (select id from catalogo where sku = 'EDOGMBNIÑ10'), 8),"..
"(3063, (select id from catalogo where sku = 'EDOGMBNIÑ11'), 8),"..
"(3064, (select id from catalogo where sku = 'EDOGMBNIÑ12'), 8),"..
"(3065, (select id from catalogo where sku = 'EDOGMBNIÑ15'), 8),"..
"(3066, (select id from catalogo where sku = 'EDOGMBNMA62'), 8),"..
"(3067, (select id from catalogo where sku = 'EDOGMBNMA63'), 8),"..
"(3068, (select id from catalogo where sku = 'EDOGMBNMA64'), 8),"..
"(3069, (select id from catalogo where sku = 'EDOGMBNMA65'), 8),"..
"(3070, (select id from catalogo where sku = 'EDOGMBSAN02'), 8),"..
"(3071, (select id from catalogo where sku = 'EDOGMBSAN03'), 8),"..
"(3072, (select id from catalogo where sku = 'EDOGMBSAN05'), 8),"..
"(3073, (select id from catalogo where sku = 'EDOGMBSAN06'), 8),"..
"(3074, (select id from catalogo where sku = 'EDOGMBSAN07'), 8),"..
"(3075, (select id from catalogo where sku = 'EDOGMBSAN11'), 8),"..
"(3076, (select id from catalogo where sku = 'EDOGMBSAN13'), 8),"..
"(3077, (select id from catalogo where sku = 'EDOGMBSAN20'), 8),"..
"(3078, (select id from catalogo where sku = 'EDOGMBSAN22'), 8),"..
"(3079, (select id from catalogo where sku = 'EDOGMBSAN30'), 8),"..
"(3080, (select id from catalogo where sku = 'EDOGMBSAN32'), 8),"..
"(3081, (select id from catalogo where sku = 'EDOGMBSAN33'), 8),"..
"(3082, (select id from catalogo where sku = 'EDOGMBSAN36'), 8),"..
"(3083, (select id from catalogo where sku = 'EDOGMBSAN39'), 8),"..
"(3084, (select id from catalogo where sku = 'EDOGMBSAN43'), 8),"..
"(3085, (select id from catalogo where sku = 'EDOGMBSAN45'), 8),"..
"(3086, (select id from catalogo where sku = 'EDOGMBSAN49'), 8),"..
"(3087, (select id from catalogo where sku = 'EDOGMBSAN51'), 8),"..
"(3088, (select id from catalogo where sku = 'EDRGDKMFI03'), 8),"..
"(3089, (select id from catalogo where sku = 'EDRGDKMFI11'), 8),"..
"(3090, (select id from catalogo where sku = 'EDRGDKMFI13'), 8),"..
"(3091, (select id from catalogo where sku = 'EDRGDKMFI16'), 8),"..
"(3092, (select id from catalogo where sku = 'EDRGGE00111'), 8),"..
"(3093, (select id from catalogo where sku = 'EDRGGE00216'), 8),"..
"(3094, (select id from catalogo where sku = 'EDRGGE00373'), 8),"..
"(3095, (select id from catalogo where sku = 'EDRGGE00713'), 8),"..
"(3096, (select id from catalogo where sku = 'EDRGGE00803'), 8),"..
"(3097, (select id from catalogo where sku = 'EDRGMBARC04'), 8),"..
"(3098, (select id from catalogo where sku = 'EDRGMBARC18'), 8),"..
"(3099, (select id from catalogo where sku = 'EDRGMBARC29'), 8),"..
"(3100, (select id from catalogo where sku = 'EDRGMBARC38'), 8),"..
"(3101, (select id from catalogo where sku = 'EDRGMBDAM04'), 8),"..
"(3102, (select id from catalogo where sku = 'EDRGMBDAM12'), 8),"..
"(3103, (select id from catalogo where sku = 'EDRGMBDAM17'), 8),"..
"(3104, (select id from catalogo where sku = 'EDRGMBDAM18'), 8),"..
"(3105, (select id from catalogo where sku = 'EDRGMBDAM19'), 8),"..
"(3106, (select id from catalogo where sku = 'EDRGMBDAM29'), 8),"..
"(3107, (select id from catalogo where sku = 'EDRGMBDAM40'), 8);"
db:exec( query2 )
--fase 22
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3108, (select id from catalogo where sku = 'EDRGMBDAM41'), 8),"..
"(3109, (select id from catalogo where sku = 'EDRGMBDES04'), 8),"..
"(3110, (select id from catalogo where sku = 'EDRGMBDES05'), 8),"..
"(3111, (select id from catalogo where sku = 'EDRGMBDES06'), 8),"..
"(3112, (select id from catalogo where sku = 'EDRGMBDES10'), 8),"..
"(3113, (select id from catalogo where sku = 'EDRGMBDES11'), 8),"..
"(3114, (select id from catalogo where sku = 'EDRGMBDES12'), 8),"..
"(3115, (select id from catalogo where sku = 'EDRGMBDES13'), 8),"..
"(3116, (select id from catalogo where sku = 'EDRGMBDES15'), 8),"..
"(3117, (select id from catalogo where sku = 'EDRGMBDES16'), 8),"..
"(3118, (select id from catalogo where sku = 'EDRGMBDES21'), 8),"..
"(3119, (select id from catalogo where sku = 'EDRGMBDES25'), 8),"..
"(3120, (select id from catalogo where sku = 'EDRGMBDES26'), 8),"..
"(3121, (select id from catalogo where sku = 'EDRGMBDES28'), 8),"..
"(3122, (select id from catalogo where sku = 'EDRGMBDES30'), 8),"..
"(3123, (select id from catalogo where sku = 'EDRGMBDES32'), 8),"..
"(3124, (select id from catalogo where sku = 'EDRGMBDES34'), 8),"..
"(3125, (select id from catalogo where sku = 'EDRGMBDES35'), 8),"..
"(3126, (select id from catalogo where sku = 'EDRGMBDES37'), 8),"..
"(3127, (select id from catalogo where sku = 'EDRGMBNIÑ02'), 8),"..
"(3128, (select id from catalogo where sku = 'EDRGMBNIÑ10'), 8),"..
"(3129, (select id from catalogo where sku = 'EDRGMBNIÑ11'), 8),"..
"(3130, (select id from catalogo where sku = 'EDRGMBNIÑ12'), 8),"..
"(3131, (select id from catalogo where sku = 'EDRGMBNIÑ15'), 8),"..
"(3132, (select id from catalogo where sku = 'EDRGMBSAN02'), 8),"..
"(3133, (select id from catalogo where sku = 'EDRGMBSAN03'), 8),"..
"(3134, (select id from catalogo where sku = 'EDRGMBSAN05'), 8),"..
"(3135, (select id from catalogo where sku = 'EDRGMBSAN06'), 8),"..
"(3136, (select id from catalogo where sku = 'EDRGMBSAN07'), 8),"..
"(3137, (select id from catalogo where sku = 'EDRGMBSAN11'), 8),"..
"(3138, (select id from catalogo where sku = 'EDRGMBSAN13'), 8),"..
"(3139, (select id from catalogo where sku = 'EDRGMBSAN20'), 8),"..
"(3140, (select id from catalogo where sku = 'EDRGMBSAN22'), 8),"..
"(3141, (select id from catalogo where sku = 'EDRGMBSAN30'), 8),"..
"(3142, (select id from catalogo where sku = 'EDRGMBSAN32'), 8),"..
"(3143, (select id from catalogo where sku = 'EDRGMBSAN33'), 8),"..
"(3144, (select id from catalogo where sku = 'EDRGMBSAN36'), 8),"..
"(3145, (select id from catalogo where sku = 'EDRGMBSAN39'), 8),"..
"(3146, (select id from catalogo where sku = 'EDRGMBSAN43'), 8),"..
"(3147, (select id from catalogo where sku = 'EDRGMBSAN45'), 8),"..
"(3148, (select id from catalogo where sku = 'EDRGMBSAN49'), 8),"..
"(3149, (select id from catalogo where sku = 'EDRGMBSAN51'), 8),"..
"(3150, (select id from catalogo where sku = 'EDSSGDKMFI03'), 8),"..
"(3151, (select id from catalogo where sku = 'EDSSGDKMFI11'), 8),"..
"(3152, (select id from catalogo where sku = 'EDSSGDKMFI13'), 8),"..
"(3153, (select id from catalogo where sku = 'EDSSGDKMFI16'), 8),"..
"(3154, (select id from catalogo where sku = 'EDSSGMBDAM04'), 8),"..
"(3155, (select id from catalogo where sku = 'EDSSGMBDAM12'), 8),"..
"(3156, (select id from catalogo where sku = 'EDSSGMBDAM17'), 8),"..
"(3157, (select id from catalogo where sku = 'EDSSGMBDAM18'), 8),"..
"(3158, (select id from catalogo where sku = 'EDSSGMBDAM19'), 8),"..
"(3159, (select id from catalogo where sku = 'EDSSGMBDAM29'), 8),"..
"(3160, (select id from catalogo where sku = 'EDSSGMBDAM40'), 8),"..
"(3161, (select id from catalogo where sku = 'EDSSGMBDAM41'), 8),"..
"(3162, (select id from catalogo where sku = 'EDSSGMBNIÑ02'), 8),"..
"(3163, (select id from catalogo where sku = 'EDSSGMBNIÑ10'), 8),"..
"(3164, (select id from catalogo where sku = 'EDSSGMBNIÑ11'), 8),"..
"(3165, (select id from catalogo where sku = 'EDSSGMBNIÑ12'), 8),"..
"(3166, (select id from catalogo where sku = 'EDSSGMBNIÑ15'), 8),"..
"(3167, (select id from catalogo where sku = 'EDSSGMBSAN02'), 8),"..
"(3168, (select id from catalogo where sku = 'EDSSGMBSAN03'), 8),"..
"(3169, (select id from catalogo where sku = 'EDSSGMBSAN05'), 8),"..
"(3170, (select id from catalogo where sku = 'EDSSGMBSAN06'), 8),"..
"(3171, (select id from catalogo where sku = 'EDSSGMBSAN07'), 8),"..
"(3172, (select id from catalogo where sku = 'EDSSGMBSAN11'), 8),"..
"(3173, (select id from catalogo where sku = 'EDSSGMBSAN13'), 8),"..
"(3174, (select id from catalogo where sku = 'EDSSGMBSAN20'), 8),"..
"(3175, (select id from catalogo where sku = 'EDSSGMBSAN22'), 8),"..
"(3176, (select id from catalogo where sku = 'EDSSGMBSAN30'), 8),"..
"(3177, (select id from catalogo where sku = 'EDSSGMBSAN32'), 8),"..
"(3178, (select id from catalogo where sku = 'EDSSGMBSAN33'), 8),"..
"(3179, (select id from catalogo where sku = 'EDSSGMBSAN36'), 8),"..
"(3180, (select id from catalogo where sku = 'EDSSGMBSAN39'), 8),"..
"(3181, (select id from catalogo where sku = 'EDSSGMBSAN43'), 8),"..
"(3182, (select id from catalogo where sku = 'EDSSGMBSAN45'), 8),"..
"(3183, (select id from catalogo where sku = 'EDSSGMBSAN49'), 8),"..
"(3184, (select id from catalogo where sku = 'EDSSGMBSAN51'), 8),"..
"(3185, (select id from catalogo where sku = 'EMPCOA00102'), 2),"..
"(3186, (select id from catalogo where sku = 'EMPCOA00102'), 3),"..
"(3187, (select id from catalogo where sku = 'EMPCOA00102'), 4),"..
"(3188, (select id from catalogo where sku = 'EMPCOA00102'), 5),"..
"(3189, (select id from catalogo where sku = 'EMPCOA00105'), 2),"..
"(3190, (select id from catalogo where sku = 'EMPCOA00105'), 3),"..
"(3191, (select id from catalogo where sku = 'EMPCOA00105'), 4),"..
"(3192, (select id from catalogo where sku = 'EMPCOA00105'), 5),"..
"(3193, (select id from catalogo where sku = 'EMPCOA00106'), 2),"..
"(3194, (select id from catalogo where sku = 'EMPCOA00106'), 3),"..
"(3195, (select id from catalogo where sku = 'EMPCOA00106'), 4),"..
"(3196, (select id from catalogo where sku = 'EMPCOA00106'), 5),"..
"(3197, (select id from catalogo where sku = 'EMPCOA00110'), 2),"..
"(3198, (select id from catalogo where sku = 'EMPCOA00110'), 3),"..
"(3199, (select id from catalogo where sku = 'EMPCOA00110'), 4),"..
"(3200, (select id from catalogo where sku = 'EMPCOA00110'), 5),"..
"(3201, (select id from catalogo where sku = 'EMPCOA00111'), 2),"..
"(3202, (select id from catalogo where sku = 'EMPCOA00111'), 3),"..
"(3203, (select id from catalogo where sku = 'EMPCOA00111'), 4),"..
"(3204, (select id from catalogo where sku = 'EMPCOA00111'), 5),"..
"(3205, (select id from catalogo where sku = 'EMPCOA00112'), 2),"..
"(3206, (select id from catalogo where sku = 'EMPCOA00112'), 3),"..
"(3207, (select id from catalogo where sku = 'EMPCOA00112'), 4),"..
"(3208, (select id from catalogo where sku = 'EMPCOA00112'), 5),"..
"(3209, (select id from catalogo where sku = 'EMPCOA00113'), 2),"..
"(3210, (select id from catalogo where sku = 'EMPCOA00113'), 3),"..
"(3211, (select id from catalogo where sku = 'EMPCOA00113'), 4),"..
"(3212, (select id from catalogo where sku = 'EMPCOA00113'), 5),"..
"(3213, (select id from catalogo where sku = 'EMPCOA00115'), 2),"..
"(3214, (select id from catalogo where sku = 'EMPCOA00115'), 3),"..
"(3215, (select id from catalogo where sku = 'EMPCOA00115'), 4),"..
"(3216, (select id from catalogo where sku = 'EMPCOA00115'), 5),"..
"(3217, (select id from catalogo where sku = 'EMPCOA00121'), 2),"..
"(3218, (select id from catalogo where sku = 'EMPCOA00121'), 3),"..
"(3219, (select id from catalogo where sku = 'EMPCOA00121'), 4),"..
"(3220, (select id from catalogo where sku = 'EMPCOA00121'), 5),"..
"(3221, (select id from catalogo where sku = 'EMPCOA00125'), 2),"..
"(3222, (select id from catalogo where sku = 'EMPCOA00125'), 3),"..
"(3223, (select id from catalogo where sku = 'EMPCOA00125'), 4),"..
"(3224, (select id from catalogo where sku = 'EMPCOA00125'), 5),"..
"(3225, (select id from catalogo where sku = 'EMPCOA00126'), 2),"..
"(3226, (select id from catalogo where sku = 'EMPCOA00126'), 3),"..
"(3227, (select id from catalogo where sku = 'EMPCOA00126'), 4),"..
"(3228, (select id from catalogo where sku = 'EMPCOA00126'), 5),"..
"(3229, (select id from catalogo where sku = 'EMPCOA00128'), 2),"..
"(3230, (select id from catalogo where sku = 'EMPCOA00128'), 3),"..
"(3231, (select id from catalogo where sku = 'EMPCOA00128'), 4),"..
"(3232, (select id from catalogo where sku = 'EMPCOA00128'), 5),"..
"(3233, (select id from catalogo where sku = 'EMPCOA00130'), 2),"..
"(3234, (select id from catalogo where sku = 'EMPCOA00130'), 3),"..
"(3235, (select id from catalogo where sku = 'EMPCOA00130'), 4),"..
"(3236, (select id from catalogo where sku = 'EMPCOA00130'), 5),"..
"(3237, (select id from catalogo where sku = 'EMPCOA00132'), 2),"..
"(3238, (select id from catalogo where sku = 'EMPCOA00132'), 3),"..
"(3239, (select id from catalogo where sku = 'EMPCOA00132'), 4),"..
"(3240, (select id from catalogo where sku = 'EMPCOA00132'), 5),"..
"(3241, (select id from catalogo where sku = 'EMPCOA00134'), 2),"..
"(3242, (select id from catalogo where sku = 'EMPCOA00134'), 3),"..
"(3243, (select id from catalogo where sku = 'EMPCOA00134'), 4),"..
"(3244, (select id from catalogo where sku = 'EMPCOA00134'), 5),"..
"(3245, (select id from catalogo where sku = 'EMPCOA00135'), 2),"..
"(3246, (select id from catalogo where sku = 'EMPCOA00135'), 3),"..
"(3247, (select id from catalogo where sku = 'EMPCOA00135'), 4),"..
"(3248, (select id from catalogo where sku = 'EMPCOA00135'), 5),"..
"(3249, (select id from catalogo where sku = 'EMPCOA001XXL02'), 6),"..
"(3250, (select id from catalogo where sku = 'EMPCOA001XXL05'), 6),"..
"(3251, (select id from catalogo where sku = 'EMPCOA001XXL06'), 6),"..
"(3252, (select id from catalogo where sku = 'EMPCOA001XXL10'), 6),"..
"(3253, (select id from catalogo where sku = 'EMPCOA001XXL11'), 6),"..
"(3254, (select id from catalogo where sku = 'EMPCOA001XXL12'), 6),"..
"(3255, (select id from catalogo where sku = 'EMPCOA001XXL13'), 6),"..
"(3256, (select id from catalogo where sku = 'EMPCOA001XXL15'), 6),"..
"(3257, (select id from catalogo where sku = 'EMPCOA001XXL21'), 6),"..
"(3258, (select id from catalogo where sku = 'EMPCOA001XXL25'), 6);"
db:exec( query2 )
--fase 23
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3259, (select id from catalogo where sku = 'EMPCOA001XXL26'), 6),"..
"(3260, (select id from catalogo where sku = 'EMPCOA001XXL28'), 6),"..
"(3261, (select id from catalogo where sku = 'EMPCOA001XXL30'), 6),"..
"(3262, (select id from catalogo where sku = 'EMPCOA001XXL32'), 6),"..
"(3263, (select id from catalogo where sku = 'EMPCOA001XXL34'), 6),"..
"(3264, (select id from catalogo where sku = 'EMPCOA001XXL35'), 6),"..
"(3265, (select id from catalogo where sku = 'FTS-100009'), 1),"..
"(3266, (select id from catalogo where sku = 'FTS-100009'), 2),"..
"(3267, (select id from catalogo where sku = 'FTS-100009'), 3),"..
"(3268, (select id from catalogo where sku = 'FTS-100009'), 4),"..
"(3269, (select id from catalogo where sku = 'FTS-100009'), 5),"..
"(3270, (select id from catalogo where sku = 'FTS-100011'), 1),"..
"(3271, (select id from catalogo where sku = 'FTS-100011'), 2),"..
"(3272, (select id from catalogo where sku = 'FTS-100011'), 3),"..
"(3273, (select id from catalogo where sku = 'FTS-100011'), 4),"..
"(3274, (select id from catalogo where sku = 'FTS-100011'), 5),"..
"(3275, (select id from catalogo where sku = 'FTS-100013'), 1),"..
"(3276, (select id from catalogo where sku = 'FTS-100013'), 2),"..
"(3277, (select id from catalogo where sku = 'FTS-100013'), 3),"..
"(3278, (select id from catalogo where sku = 'FTS-100013'), 4),"..
"(3279, (select id from catalogo where sku = 'FTS-100013'), 5),"..
"(3280, (select id from catalogo where sku = 'GRSCOA00102'), 2),"..
"(3281, (select id from catalogo where sku = 'GRSCOA00102'), 3),"..
"(3282, (select id from catalogo where sku = 'GRSCOA00102'), 4),"..
"(3283, (select id from catalogo where sku = 'GRSCOA00102'), 5),"..
"(3284, (select id from catalogo where sku = 'GRSCOA00105'), 2),"..
"(3285, (select id from catalogo where sku = 'GRSCOA00105'), 3),"..
"(3286, (select id from catalogo where sku = 'GRSCOA00105'), 4),"..
"(3287, (select id from catalogo where sku = 'GRSCOA00105'), 5),"..
"(3288, (select id from catalogo where sku = 'GRSCOA00106'), 2),"..
"(3289, (select id from catalogo where sku = 'GRSCOA00106'), 3),"..
"(3290, (select id from catalogo where sku = 'GRSCOA00106'), 4),"..
"(3291, (select id from catalogo where sku = 'GRSCOA00106'), 5),"..
"(3292, (select id from catalogo where sku = 'GRSCOA00110'), 2),"..
"(3293, (select id from catalogo where sku = 'GRSCOA00110'), 3),"..
"(3294, (select id from catalogo where sku = 'GRSCOA00110'), 4),"..
"(3295, (select id from catalogo where sku = 'GRSCOA00110'), 5),"..
"(3296, (select id from catalogo where sku = 'GRSCOA00111'), 2),"..
"(3297, (select id from catalogo where sku = 'GRSCOA00111'), 3),"..
"(3298, (select id from catalogo where sku = 'GRSCOA00111'), 4),"..
"(3299, (select id from catalogo where sku = 'GRSCOA00111'), 5),"..
"(3300, (select id from catalogo where sku = 'GRSCOA00112'), 2),"..
"(3301, (select id from catalogo where sku = 'GRSCOA00112'), 3),"..
"(3302, (select id from catalogo where sku = 'GRSCOA00112'), 4),"..
"(3303, (select id from catalogo where sku = 'GRSCOA00112'), 5),"..
"(3304, (select id from catalogo where sku = 'GRSCOA00113'), 2),"..
"(3305, (select id from catalogo where sku = 'GRSCOA00113'), 3),"..
"(3306, (select id from catalogo where sku = 'GRSCOA00113'), 4),"..
"(3307, (select id from catalogo where sku = 'GRSCOA00113'), 5),"..
"(3308, (select id from catalogo where sku = 'GRSCOA00115'), 2),"..
"(3309, (select id from catalogo where sku = 'GRSCOA00115'), 3),"..
"(3310, (select id from catalogo where sku = 'GRSCOA00115'), 4),"..
"(3311, (select id from catalogo where sku = 'GRSCOA00115'), 5),"..
"(3312, (select id from catalogo where sku = 'GRSCOA00121'), 2),"..
"(3313, (select id from catalogo where sku = 'GRSCOA00121'), 3),"..
"(3314, (select id from catalogo where sku = 'GRSCOA00121'), 4),"..
"(3315, (select id from catalogo where sku = 'GRSCOA00121'), 5),"..
"(3316, (select id from catalogo where sku = 'GRSCOA00125'), 2),"..
"(3317, (select id from catalogo where sku = 'GRSCOA00125'), 3),"..
"(3318, (select id from catalogo where sku = 'GRSCOA00125'), 4),"..
"(3319, (select id from catalogo where sku = 'GRSCOA00125'), 5),"..
"(3320, (select id from catalogo where sku = 'GRSCOA00126'), 2),"..
"(3321, (select id from catalogo where sku = 'GRSCOA00126'), 3),"..
"(3322, (select id from catalogo where sku = 'GRSCOA00126'), 4),"..
"(3323, (select id from catalogo where sku = 'GRSCOA00126'), 5),"..
"(3324, (select id from catalogo where sku = 'GRSCOA00128'), 2),"..
"(3325, (select id from catalogo where sku = 'GRSCOA00128'), 3),"..
"(3326, (select id from catalogo where sku = 'GRSCOA00128'), 4),"..
"(3327, (select id from catalogo where sku = 'GRSCOA00128'), 5),"..
"(3328, (select id from catalogo where sku = 'GRSCOA00130'), 2),"..
"(3329, (select id from catalogo where sku = 'GRSCOA00130'), 3),"..
"(3330, (select id from catalogo where sku = 'GRSCOA00130'), 4),"..
"(3331, (select id from catalogo where sku = 'GRSCOA00130'), 5),"..
"(3332, (select id from catalogo where sku = 'GRSCOA00132'), 2),"..
"(3333, (select id from catalogo where sku = 'GRSCOA00132'), 3),"..
"(3334, (select id from catalogo where sku = 'GRSCOA00132'), 4),"..
"(3335, (select id from catalogo where sku = 'GRSCOA00132'), 5),"..
"(3336, (select id from catalogo where sku = 'GRSCOA00134'), 2),"..
"(3337, (select id from catalogo where sku = 'GRSCOA00134'), 3),"..
"(3338, (select id from catalogo where sku = 'GRSCOA00134'), 4),"..
"(3339, (select id from catalogo where sku = 'GRSCOA00134'), 5),"..
"(3340, (select id from catalogo where sku = 'GRSCOA00135'), 2),"..
"(3341, (select id from catalogo where sku = 'GRSCOA00135'), 3),"..
"(3342, (select id from catalogo where sku = 'GRSCOA00135'), 4),"..
"(3343, (select id from catalogo where sku = 'GRSCOA00135'), 5),"..
"(3344, (select id from catalogo where sku = 'GRSCOA001XXL02'), 6),"..
"(3345, (select id from catalogo where sku = 'GRSCOA001XXL05'), 6),"..
"(3346, (select id from catalogo where sku = 'GRSCOA001XXL06'), 6),"..
"(3347, (select id from catalogo where sku = 'GRSCOA001XXL10'), 6),"..
"(3348, (select id from catalogo where sku = 'GRSCOA001XXL11'), 6),"..
"(3349, (select id from catalogo where sku = 'GRSCOA001XXL12'), 6),"..
"(3350, (select id from catalogo where sku = 'GRSCOA001XXL13'), 6),"..
"(3351, (select id from catalogo where sku = 'GRSCOA001XXL15'), 6),"..
"(3352, (select id from catalogo where sku = 'GRSCOA001XXL21'), 6),"..
"(3353, (select id from catalogo where sku = 'GRSCOA001XXL25'), 6),"..
"(3354, (select id from catalogo where sku = 'GRSCOA001XXL26'), 6),"..
"(3355, (select id from catalogo where sku = 'GRSCOA001XXL28'), 6),"..
"(3356, (select id from catalogo where sku = 'GRSCOA001XXL30'), 6),"..
"(3357, (select id from catalogo where sku = 'GRSCOA001XXL32'), 6),"..
"(3358, (select id from catalogo where sku = 'GRSCOA001XXL34'), 6),"..
"(3359, (select id from catalogo where sku = 'GRSCOA001XXL35'), 6),"..
"(3360, (select id from catalogo where sku = 'GRSGMBDES04'), 8),"..
"(3361, (select id from catalogo where sku = 'GRSGMBDES05'), 8),"..
"(3362, (select id from catalogo where sku = 'GRSGMBDES06'), 8),"..
"(3363, (select id from catalogo where sku = 'GRSGMBDES10'), 8),"..
"(3364, (select id from catalogo where sku = 'GRSGMBDES11'), 8),"..
"(3365, (select id from catalogo where sku = 'GRSGMBDES12'), 8),"..
"(3366, (select id from catalogo where sku = 'GRSGMBDES13'), 8),"..
"(3367, (select id from catalogo where sku = 'GRSGMBDES15'), 8),"..
"(3368, (select id from catalogo where sku = 'GRSGMBDES16'), 8),"..
"(3369, (select id from catalogo where sku = 'GRSGMBDES21'), 8),"..
"(3370, (select id from catalogo where sku = 'GRSGMBDES25'), 8),"..
"(3371, (select id from catalogo where sku = 'GRSGMBDES26'), 8),"..
"(3372, (select id from catalogo where sku = 'GRSGMBDES28'), 8),"..
"(3373, (select id from catalogo where sku = 'GRSGMBDES30'), 8),"..
"(3374, (select id from catalogo where sku = 'GRSGMBDES32'), 8),"..
"(3375, (select id from catalogo where sku = 'GRSGMBDES34'), 8),"..
"(3376, (select id from catalogo where sku = 'GRSGMBDES35'), 8),"..
"(3377, (select id from catalogo where sku = 'GRSGMBDES37'), 8),"..
"(3378, (select id from catalogo where sku = 'GRSGMBSAN02'), 8),"..
"(3379, (select id from catalogo where sku = 'GRSGMBSAN03'), 8),"..
"(3380, (select id from catalogo where sku = 'GRSGMBSAN05'), 8),"..
"(3381, (select id from catalogo where sku = 'GRSGMBSAN06'), 8),"..
"(3382, (select id from catalogo where sku = 'GRSGMBSAN07'), 8),"..
"(3383, (select id from catalogo where sku = 'GRSGMBSAN11'), 8),"..
"(3384, (select id from catalogo where sku = 'GRSGMBSAN13'), 8),"..
"(3385, (select id from catalogo where sku = 'GRSGMBSAN20'), 8),"..
"(3386, (select id from catalogo where sku = 'GRSGMBSAN22'), 8),"..
"(3387, (select id from catalogo where sku = 'GRSGMBSAN30'), 8),"..
"(3388, (select id from catalogo where sku = 'GRSGMBSAN32'), 8),"..
"(3389, (select id from catalogo where sku = 'GRSGMBSAN33'), 8),"..
"(3390, (select id from catalogo where sku = 'GRSGMBSAN36'), 8),"..
"(3391, (select id from catalogo where sku = 'GRSGMBSAN39'), 8),"..
"(3392, (select id from catalogo where sku = 'GRSGMBSAN43'), 8),"..
"(3393, (select id from catalogo where sku = 'GRSGMBSAN45'), 8),"..
"(3394, (select id from catalogo where sku = 'GRSGMBSAN49'), 8),"..
"(3395, (select id from catalogo where sku = 'GRSGMBSAN51'), 8),"..
"(3396, (select id from catalogo where sku = 'HIDCOA00102'), 2),"..
"(3397, (select id from catalogo where sku = 'HIDCOA00102'), 3),"..
"(3398, (select id from catalogo where sku = 'HIDCOA00102'), 4),"..
"(3399, (select id from catalogo where sku = 'HIDCOA00102'), 5),"..
"(3400, (select id from catalogo where sku = 'HIDCOA00105'), 2),"..
"(3401, (select id from catalogo where sku = 'HIDCOA00105'), 3),"..
"(3402, (select id from catalogo where sku = 'HIDCOA00105'), 4),"..
"(3403, (select id from catalogo where sku = 'HIDCOA00105'), 5),"..
"(3404, (select id from catalogo where sku = 'HIDCOA00106'), 2),"..
"(3405, (select id from catalogo where sku = 'HIDCOA00106'), 3),"..
"(3406, (select id from catalogo where sku = 'HIDCOA00106'), 4),"..
"(3407, (select id from catalogo where sku = 'HIDCOA00106'), 5),"..
"(3408, (select id from catalogo where sku = 'HIDCOA00110'), 2),"..
"(3409, (select id from catalogo where sku = 'HIDCOA00110'), 3);"
db:exec( query2 )
--fase 24
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3410, (select id from catalogo where sku = 'HIDCOA00110'), 4),"..
"(3411, (select id from catalogo where sku = 'HIDCOA00110'), 5),"..
"(3412, (select id from catalogo where sku = 'HIDCOA00111'), 2),"..
"(3413, (select id from catalogo where sku = 'HIDCOA00111'), 3),"..
"(3414, (select id from catalogo where sku = 'HIDCOA00111'), 4),"..
"(3415, (select id from catalogo where sku = 'HIDCOA00111'), 5),"..
"(3416, (select id from catalogo where sku = 'HIDCOA00112'), 2),"..
"(3417, (select id from catalogo where sku = 'HIDCOA00112'), 3),"..
"(3418, (select id from catalogo where sku = 'HIDCOA00112'), 4),"..
"(3419, (select id from catalogo where sku = 'HIDCOA00112'), 5),"..
"(3420, (select id from catalogo where sku = 'HIDCOA00113'), 2),"..
"(3421, (select id from catalogo where sku = 'HIDCOA00113'), 3),"..
"(3422, (select id from catalogo where sku = 'HIDCOA00113'), 4),"..
"(3423, (select id from catalogo where sku = 'HIDCOA00113'), 5),"..
"(3424, (select id from catalogo where sku = 'HIDCOA00115'), 2),"..
"(3425, (select id from catalogo where sku = 'HIDCOA00115'), 3),"..
"(3426, (select id from catalogo where sku = 'HIDCOA00115'), 4),"..
"(3427, (select id from catalogo where sku = 'HIDCOA00115'), 5),"..
"(3428, (select id from catalogo where sku = 'HIDCOA00121'), 2),"..
"(3429, (select id from catalogo where sku = 'HIDCOA00121'), 3),"..
"(3430, (select id from catalogo where sku = 'HIDCOA00121'), 4),"..
"(3431, (select id from catalogo where sku = 'HIDCOA00121'), 5),"..
"(3432, (select id from catalogo where sku = 'HIDCOA00125'), 2),"..
"(3433, (select id from catalogo where sku = 'HIDCOA00125'), 3),"..
"(3434, (select id from catalogo where sku = 'HIDCOA00125'), 4),"..
"(3435, (select id from catalogo where sku = 'HIDCOA00125'), 5),"..
"(3436, (select id from catalogo where sku = 'HIDCOA00126'), 2),"..
"(3437, (select id from catalogo where sku = 'HIDCOA00126'), 3),"..
"(3438, (select id from catalogo where sku = 'HIDCOA00126'), 4),"..
"(3439, (select id from catalogo where sku = 'HIDCOA00126'), 5),"..
"(3440, (select id from catalogo where sku = 'HIDCOA00128'), 2),"..
"(3441, (select id from catalogo where sku = 'HIDCOA00128'), 3),"..
"(3442, (select id from catalogo where sku = 'HIDCOA00128'), 4),"..
"(3443, (select id from catalogo where sku = 'HIDCOA00128'), 5),"..
"(3444, (select id from catalogo where sku = 'HIDCOA00130'), 2),"..
"(3445, (select id from catalogo where sku = 'HIDCOA00130'), 3),"..
"(3446, (select id from catalogo where sku = 'HIDCOA00130'), 4),"..
"(3447, (select id from catalogo where sku = 'HIDCOA00130'), 5),"..
"(3448, (select id from catalogo where sku = 'HIDCOA00132'), 2),"..
"(3449, (select id from catalogo where sku = 'HIDCOA00132'), 3),"..
"(3450, (select id from catalogo where sku = 'HIDCOA00132'), 4),"..
"(3451, (select id from catalogo where sku = 'HIDCOA00132'), 5),"..
"(3452, (select id from catalogo where sku = 'HIDCOA00134'), 2),"..
"(3453, (select id from catalogo where sku = 'HIDCOA00134'), 3),"..
"(3454, (select id from catalogo where sku = 'HIDCOA00134'), 4),"..
"(3455, (select id from catalogo where sku = 'HIDCOA00134'), 5),"..
"(3456, (select id from catalogo where sku = 'HIDCOA00135'), 2),"..
"(3457, (select id from catalogo where sku = 'HIDCOA00135'), 3),"..
"(3458, (select id from catalogo where sku = 'HIDCOA00135'), 4),"..
"(3459, (select id from catalogo where sku = 'HIDCOA00135'), 5),"..
"(3460, (select id from catalogo where sku = 'HIDCOA001XXL02'), 6),"..
"(3461, (select id from catalogo where sku = 'HIDCOA001XXL05'), 6),"..
"(3462, (select id from catalogo where sku = 'HIDCOA001XXL06'), 6),"..
"(3463, (select id from catalogo where sku = 'HIDCOA001XXL10'), 6),"..
"(3464, (select id from catalogo where sku = 'HIDCOA001XXL11'), 6),"..
"(3465, (select id from catalogo where sku = 'HIDCOA001XXL12'), 6),"..
"(3466, (select id from catalogo where sku = 'HIDCOA001XXL13'), 6),"..
"(3467, (select id from catalogo where sku = 'HIDCOA001XXL15'), 6),"..
"(3468, (select id from catalogo where sku = 'HIDCOA001XXL21'), 6),"..
"(3469, (select id from catalogo where sku = 'HIDCOA001XXL25'), 6),"..
"(3470, (select id from catalogo where sku = 'HIDCOA001XXL26'), 6),"..
"(3471, (select id from catalogo where sku = 'HIDCOA001XXL28'), 6),"..
"(3472, (select id from catalogo where sku = 'HIDCOA001XXL30'), 6),"..
"(3473, (select id from catalogo where sku = 'HIDCOA001XXL32'), 6),"..
"(3474, (select id from catalogo where sku = 'HIDCOA001XXL34'), 6),"..
"(3475, (select id from catalogo where sku = 'HIDCOA001XXL35'), 6),"..
"(3476, (select id from catalogo where sku = 'HIDGDKMFI03'), 8),"..
"(3477, (select id from catalogo where sku = 'HIDGDKMFI11'), 8),"..
"(3478, (select id from catalogo where sku = 'HIDGDKMFI13'), 8),"..
"(3479, (select id from catalogo where sku = 'HIDGDKMFI16'), 8),"..
"(3480, (select id from catalogo where sku = 'HIDGMBDAM04'), 8),"..
"(3481, (select id from catalogo where sku = 'HIDGMBDAM12'), 8),"..
"(3482, (select id from catalogo where sku = 'HIDGMBDAM17'), 8),"..
"(3483, (select id from catalogo where sku = 'HIDGMBDAM18'), 8),"..
"(3484, (select id from catalogo where sku = 'HIDGMBDAM19'), 8),"..
"(3485, (select id from catalogo where sku = 'HIDGMBDAM29'), 8),"..
"(3486, (select id from catalogo where sku = 'HIDGMBDAM40'), 8),"..
"(3487, (select id from catalogo where sku = 'HIDGMBDAM41'), 8),"..
"(3488, (select id from catalogo where sku = 'HIDGMBDES04'), 8),"..
"(3489, (select id from catalogo where sku = 'HIDGMBDES05'), 8),"..
"(3490, (select id from catalogo where sku = 'HIDGMBDES06'), 8),"..
"(3491, (select id from catalogo where sku = 'HIDGMBDES10'), 8),"..
"(3492, (select id from catalogo where sku = 'HIDGMBDES11'), 8),"..
"(3493, (select id from catalogo where sku = 'HIDGMBDES12'), 8),"..
"(3494, (select id from catalogo where sku = 'HIDGMBDES13'), 8),"..
"(3495, (select id from catalogo where sku = 'HIDGMBDES15'), 8),"..
"(3496, (select id from catalogo where sku = 'HIDGMBDES16'), 8),"..
"(3497, (select id from catalogo where sku = 'HIDGMBDES21'), 8),"..
"(3498, (select id from catalogo where sku = 'HIDGMBDES25'), 8),"..
"(3499, (select id from catalogo where sku = 'HIDGMBDES26'), 8),"..
"(3500, (select id from catalogo where sku = 'HIDGMBDES28'), 8),"..
"(3501, (select id from catalogo where sku = 'HIDGMBDES30'), 8),"..
"(3502, (select id from catalogo where sku = 'HIDGMBDES32'), 8),"..
"(3503, (select id from catalogo where sku = 'HIDGMBDES34'), 8),"..
"(3504, (select id from catalogo where sku = 'HIDGMBDES35'), 8),"..
"(3505, (select id from catalogo where sku = 'HIDGMBDES37'), 8),"..
"(3506, (select id from catalogo where sku = 'HIDGMBSAN02'), 8),"..
"(3507, (select id from catalogo where sku = 'HIDGMBSAN03'), 8),"..
"(3508, (select id from catalogo where sku = 'HIDGMBSAN05'), 8),"..
"(3509, (select id from catalogo where sku = 'HIDGMBSAN06'), 8),"..
"(3510, (select id from catalogo where sku = 'HIDGMBSAN07'), 8),"..
"(3511, (select id from catalogo where sku = 'HIDGMBSAN11'), 8),"..
"(3512, (select id from catalogo where sku = 'HIDGMBSAN13'), 8),"..
"(3513, (select id from catalogo where sku = 'HIDGMBSAN20'), 8),"..
"(3514, (select id from catalogo where sku = 'HIDGMBSAN22'), 8),"..
"(3515, (select id from catalogo where sku = 'HIDGMBSAN30'), 8),"..
"(3516, (select id from catalogo where sku = 'HIDGMBSAN32'), 8),"..
"(3517, (select id from catalogo where sku = 'HIDGMBSAN33'), 8),"..
"(3518, (select id from catalogo where sku = 'HIDGMBSAN36'), 8),"..
"(3519, (select id from catalogo where sku = 'HIDGMBSAN39'), 8),"..
"(3520, (select id from catalogo where sku = 'HIDGMBSAN43'), 8),"..
"(3521, (select id from catalogo where sku = 'HIDGMBSAN45'), 8),"..
"(3522, (select id from catalogo where sku = 'HIDGMBSAN49'), 8),"..
"(3523, (select id from catalogo where sku = 'HIDGMBSAN51'), 8),"..
"(3524, (select id from catalogo where sku = 'LBS-03513'), 1),"..
"(3525, (select id from catalogo where sku = 'LBS-03513'), 2),"..
"(3526, (select id from catalogo where sku = 'LBS-03513'), 3),"..
"(3527, (select id from catalogo where sku = 'LBS-03513'), 4),"..
"(3528, (select id from catalogo where sku = 'LBS-03513'), 5),"..
"(3529, (select id from catalogo where sku = 'LBS-03529'), 1),"..
"(3530, (select id from catalogo where sku = 'LBS-03529'), 2),"..
"(3531, (select id from catalogo where sku = 'LBS-03529'), 3),"..
"(3532, (select id from catalogo where sku = 'LBS-03529'), 4),"..
"(3533, (select id from catalogo where sku = 'LBS-03529'), 5),"..
"(3534, (select id from catalogo where sku = 'LBS-03578'), 1),"..
"(3535, (select id from catalogo where sku = 'LBS-03578'), 2),"..
"(3536, (select id from catalogo where sku = 'LBS-03578'), 3),"..
"(3537, (select id from catalogo where sku = 'LBS-03578'), 4),"..
"(3538, (select id from catalogo where sku = 'LBS-03578'), 5),"..
"(3539, (select id from catalogo where sku = 'LBS-100212'), 1),"..
"(3540, (select id from catalogo where sku = 'LBS-100212'), 2),"..
"(3541, (select id from catalogo where sku = 'LBS-100212'), 3),"..
"(3542, (select id from catalogo where sku = 'LBS-100212'), 4),"..
"(3543, (select id from catalogo where sku = 'LBS-100212'), 5),"..
"(3544, (select id from catalogo where sku = 'LBS-100213'), 1),"..
"(3545, (select id from catalogo where sku = 'LBS-100213'), 2),"..
"(3546, (select id from catalogo where sku = 'LBS-100213'), 3),"..
"(3547, (select id from catalogo where sku = 'LBS-100213'), 4),"..
"(3548, (select id from catalogo where sku = 'LBS-100213'), 5),"..
"(3549, (select id from catalogo where sku = 'LBS-100217'), 1),"..
"(3550, (select id from catalogo where sku = 'LBS-100217'), 2),"..
"(3551, (select id from catalogo where sku = 'LBS-100217'), 3),"..
"(3552, (select id from catalogo where sku = 'LBS-100217'), 4),"..
"(3553, (select id from catalogo where sku = 'LBS-100217'), 5),"..
"(3554, (select id from catalogo where sku = 'LBS-100271'), 1),"..
"(3555, (select id from catalogo where sku = 'LBS-100271'), 2),"..
"(3556, (select id from catalogo where sku = 'LBS-100271'), 3),"..
"(3557, (select id from catalogo where sku = 'LBS-100271'), 4),"..
"(3558, (select id from catalogo where sku = 'LBS-100271'), 5),"..
"(3559, (select id from catalogo where sku = 'LBS-10312'), 1),"..
"(3560, (select id from catalogo where sku = 'LBS-10312'), 2);"
db:exec( query2 )
--fase 25
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3561, (select id from catalogo where sku = 'LBS-10312'), 3),"..
"(3562, (select id from catalogo where sku = 'LBS-10312'), 4),"..
"(3563, (select id from catalogo where sku = 'LBS-10312'), 5),"..
"(3564, (select id from catalogo where sku = 'LBS-10317'), 1),"..
"(3565, (select id from catalogo where sku = 'LBS-10317'), 2),"..
"(3566, (select id from catalogo where sku = 'LBS-10317'), 3),"..
"(3567, (select id from catalogo where sku = 'LBS-10317'), 4),"..
"(3568, (select id from catalogo where sku = 'LBS-10317'), 5),"..
"(3569, (select id from catalogo where sku = 'LBS-10318'), 1),"..
"(3570, (select id from catalogo where sku = 'LBS-10318'), 2),"..
"(3571, (select id from catalogo where sku = 'LBS-10318'), 3),"..
"(3572, (select id from catalogo where sku = 'LBS-10318'), 4),"..
"(3573, (select id from catalogo where sku = 'LBS-10318'), 5),"..
"(3574, (select id from catalogo where sku = 'LBS-10371'), 1),"..
"(3575, (select id from catalogo where sku = 'LBS-10371'), 2),"..
"(3576, (select id from catalogo where sku = 'LBS-10371'), 3),"..
"(3577, (select id from catalogo where sku = 'LBS-10371'), 4),"..
"(3578, (select id from catalogo where sku = 'LBS-10371'), 5),"..
"(3579, (select id from catalogo where sku = 'LFT-30013'), 1),"..
"(3580, (select id from catalogo where sku = 'LFT-30013'), 2),"..
"(3581, (select id from catalogo where sku = 'LFT-30013'), 3),"..
"(3582, (select id from catalogo where sku = 'LFT-30013'), 4),"..
"(3583, (select id from catalogo where sku = 'LFT-30013'), 5),"..
"(3584, (select id from catalogo where sku = 'LFT-30029'), 1),"..
"(3585, (select id from catalogo where sku = 'LFT-30029'), 2),"..
"(3586, (select id from catalogo where sku = 'LFT-30029'), 3),"..
"(3587, (select id from catalogo where sku = 'LFT-30029'), 4),"..
"(3588, (select id from catalogo where sku = 'LFT-30029'), 5),"..
"(3589, (select id from catalogo where sku = 'LJT-10217'), 1),"..
"(3590, (select id from catalogo where sku = 'LJT-10217'), 2),"..
"(3591, (select id from catalogo where sku = 'LJT-10217'), 3),"..
"(3592, (select id from catalogo where sku = 'LJT-10217'), 4),"..
"(3593, (select id from catalogo where sku = 'LJT-10217'), 5),"..
"(3594, (select id from catalogo where sku = 'LJT-10229'), 1),"..
"(3595, (select id from catalogo where sku = 'LJT-10229'), 2),"..
"(3596, (select id from catalogo where sku = 'LJT-10229'), 3),"..
"(3597, (select id from catalogo where sku = 'LJT-10229'), 4),"..
"(3598, (select id from catalogo where sku = 'LJT-10229'), 5),"..
"(3599, (select id from catalogo where sku = 'LJT-10278'), 1),"..
"(3600, (select id from catalogo where sku = 'LJT-10278'), 2),"..
"(3601, (select id from catalogo where sku = 'LJT-10278'), 3),"..
"(3602, (select id from catalogo where sku = 'LJT-10278'), 4),"..
"(3603, (select id from catalogo where sku = 'LJT-10278'), 5),"..
"(3604, (select id from catalogo where sku = 'LJT-20029'), 1),"..
"(3605, (select id from catalogo where sku = 'LJT-20029'), 2),"..
"(3606, (select id from catalogo where sku = 'LJT-20029'), 3),"..
"(3607, (select id from catalogo where sku = 'LJT-20029'), 4),"..
"(3608, (select id from catalogo where sku = 'LJT-20029'), 5),"..
"(3609, (select id from catalogo where sku = 'LMT-10012'), 1),"..
"(3610, (select id from catalogo where sku = 'LMT-10012'), 2),"..
"(3611, (select id from catalogo where sku = 'LMT-10012'), 3),"..
"(3612, (select id from catalogo where sku = 'LMT-10012'), 4),"..
"(3613, (select id from catalogo where sku = 'LMT-10012'), 5),"..
"(3614, (select id from catalogo where sku = 'LMT-10013'), 1),"..
"(3615, (select id from catalogo where sku = 'LMT-10013'), 2),"..
"(3616, (select id from catalogo where sku = 'LMT-10013'), 3),"..
"(3617, (select id from catalogo where sku = 'LMT-10013'), 4),"..
"(3618, (select id from catalogo where sku = 'LMT-10013'), 5),"..
"(3619, (select id from catalogo where sku = 'LMT-10017'), 1),"..
"(3620, (select id from catalogo where sku = 'LMT-10017'), 2),"..
"(3621, (select id from catalogo where sku = 'LMT-10017'), 3),"..
"(3622, (select id from catalogo where sku = 'LMT-10017'), 4),"..
"(3623, (select id from catalogo where sku = 'LMT-10017'), 5),"..
"(3624, (select id from catalogo where sku = 'LMT-10018'), 1),"..
"(3625, (select id from catalogo where sku = 'LMT-10018'), 2),"..
"(3626, (select id from catalogo where sku = 'LMT-10018'), 3),"..
"(3627, (select id from catalogo where sku = 'LMT-10018'), 4),"..
"(3628, (select id from catalogo where sku = 'LMT-10018'), 5),"..
"(3629, (select id from catalogo where sku = 'LMT-10071'), 1),"..
"(3630, (select id from catalogo where sku = 'LMT-10071'), 2),"..
"(3631, (select id from catalogo where sku = 'LMT-10071'), 3),"..
"(3632, (select id from catalogo where sku = 'LMT-10071'), 4),"..
"(3633, (select id from catalogo where sku = 'LMT-10071'), 5),"..
"(3634, (select id from catalogo where sku = 'LSV-10012'), 1),"..
"(3635, (select id from catalogo where sku = 'LSV-10012'), 2),"..
"(3636, (select id from catalogo where sku = 'LSV-10012'), 3),"..
"(3637, (select id from catalogo where sku = 'LSV-10012'), 4),"..
"(3638, (select id from catalogo where sku = 'LSV-10012'), 5),"..
"(3639, (select id from catalogo where sku = 'LSV-10017'), 1),"..
"(3640, (select id from catalogo where sku = 'LSV-10017'), 2),"..
"(3641, (select id from catalogo where sku = 'LSV-10017'), 3),"..
"(3642, (select id from catalogo where sku = 'LSV-10017'), 4),"..
"(3643, (select id from catalogo where sku = 'LSV-10017'), 5),"..
"(3644, (select id from catalogo where sku = 'LSV-10071'), 1),"..
"(3645, (select id from catalogo where sku = 'LSV-10071'), 2),"..
"(3646, (select id from catalogo where sku = 'LSV-10071'), 3),"..
"(3647, (select id from catalogo where sku = 'LSV-10071'), 4),"..
"(3648, (select id from catalogo where sku = 'LSV-10071'), 5),"..
"(3649, (select id from catalogo where sku = 'MARGDKMFI03'), 8),"..
"(3650, (select id from catalogo where sku = 'MARGDKMFI11'), 8),"..
"(3651, (select id from catalogo where sku = 'MARGDKMFI13'), 8),"..
"(3652, (select id from catalogo where sku = 'MARGDKMFI16'), 8),"..
"(3653, (select id from catalogo where sku = 'MARGMBDAM04'), 8),"..
"(3654, (select id from catalogo where sku = 'MARGMBDAM12'), 8),"..
"(3655, (select id from catalogo where sku = 'MARGMBDAM17'), 8),"..
"(3656, (select id from catalogo where sku = 'MARGMBDAM18'), 8),"..
"(3657, (select id from catalogo where sku = 'MARGMBDAM19'), 8),"..
"(3658, (select id from catalogo where sku = 'MARGMBDAM29'), 8),"..
"(3659, (select id from catalogo where sku = 'MARGMBDAM40'), 8),"..
"(3660, (select id from catalogo where sku = 'MARGMBDAM41'), 8),"..
"(3661, (select id from catalogo where sku = 'MARGMBDES04'), 8),"..
"(3662, (select id from catalogo where sku = 'MARGMBDES05'), 8),"..
"(3663, (select id from catalogo where sku = 'MARGMBDES06'), 8),"..
"(3664, (select id from catalogo where sku = 'MARGMBDES10'), 8),"..
"(3665, (select id from catalogo where sku = 'MARGMBDES11'), 8),"..
"(3666, (select id from catalogo where sku = 'MARGMBDES12'), 8),"..
"(3667, (select id from catalogo where sku = 'MARGMBDES13'), 8),"..
"(3668, (select id from catalogo where sku = 'MARGMBDES15'), 8),"..
"(3669, (select id from catalogo where sku = 'MARGMBDES16'), 8),"..
"(3670, (select id from catalogo where sku = 'MARGMBDES21'), 8),"..
"(3671, (select id from catalogo where sku = 'MARGMBDES25'), 8),"..
"(3672, (select id from catalogo where sku = 'MARGMBDES26'), 8),"..
"(3673, (select id from catalogo where sku = 'MARGMBDES28'), 8),"..
"(3674, (select id from catalogo where sku = 'MARGMBDES30'), 8),"..
"(3675, (select id from catalogo where sku = 'MARGMBDES32'), 8),"..
"(3676, (select id from catalogo where sku = 'MARGMBDES34'), 8),"..
"(3677, (select id from catalogo where sku = 'MARGMBDES35'), 8),"..
"(3678, (select id from catalogo where sku = 'MARGMBDES37'), 8),"..
"(3679, (select id from catalogo where sku = 'MARGMBSAN02'), 8),"..
"(3680, (select id from catalogo where sku = 'MARGMBSAN03'), 8),"..
"(3681, (select id from catalogo where sku = 'MARGMBSAN05'), 8),"..
"(3682, (select id from catalogo where sku = 'MARGMBSAN06'), 8),"..
"(3683, (select id from catalogo where sku = 'MARGMBSAN07'), 8),"..
"(3684, (select id from catalogo where sku = 'MARGMBSAN11'), 8),"..
"(3685, (select id from catalogo where sku = 'MARGMBSAN13'), 8),"..
"(3686, (select id from catalogo where sku = 'MARGMBSAN20'), 8),"..
"(3687, (select id from catalogo where sku = 'MARGMBSAN22'), 8),"..
"(3688, (select id from catalogo where sku = 'MARGMBSAN30'), 8),"..
"(3689, (select id from catalogo where sku = 'MARGMBSAN32'), 8),"..
"(3690, (select id from catalogo where sku = 'MARGMBSAN33'), 8),"..
"(3691, (select id from catalogo where sku = 'MARGMBSAN36'), 8),"..
"(3692, (select id from catalogo where sku = 'MARGMBSAN39'), 8),"..
"(3693, (select id from catalogo where sku = 'MARGMBSAN43'), 8),"..
"(3694, (select id from catalogo where sku = 'MARGMBSAN45'), 8),"..
"(3695, (select id from catalogo where sku = 'MARGMBSAN49'), 8),"..
"(3696, (select id from catalogo where sku = 'MARGMBSAN51'), 8),"..
"(3697, (select id from catalogo where sku = 'MERCOA01502'), 2),"..
"(3698, (select id from catalogo where sku = 'MERCOA01502'), 3),"..
"(3699, (select id from catalogo where sku = 'MERCOA01502'), 4),"..
"(3700, (select id from catalogo where sku = 'MERCOA01502'), 5),"..
"(3701, (select id from catalogo where sku = 'MERCOA01511'), 2),"..
"(3702, (select id from catalogo where sku = 'MERCOA01511'), 3),"..
"(3703, (select id from catalogo where sku = 'MERCOA01511'), 4),"..
"(3704, (select id from catalogo where sku = 'MERCOA01511'), 5),"..
"(3705, (select id from catalogo where sku = 'MERCOA015XXL02'), 6),"..
"(3706, (select id from catalogo where sku = 'MERCOA015XXL11'), 6),"..
"(3707, (select id from catalogo where sku = 'MERCOD01540'), 2),"..
"(3708, (select id from catalogo where sku = 'MERCOD01540'), 3),"..
"(3709, (select id from catalogo where sku = 'MERCOD01540'), 4),"..
"(3710, (select id from catalogo where sku = 'MERCOD01540'), 5),"..
"(3711, (select id from catalogo where sku = 'MERCOD01571'), 2);"
db:exec( query2 )
--fase 26
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3712, (select id from catalogo where sku = 'MERCOD01571'), 3),"..
"(3713, (select id from catalogo where sku = 'MERCOD01571'), 4),"..
"(3714, (select id from catalogo where sku = 'MERCOD01571'), 5),"..
"(3715, (select id from catalogo where sku = 'MERGMBDAM04'), 8),"..
"(3716, (select id from catalogo where sku = 'MERGMBDAM12'), 8),"..
"(3717, (select id from catalogo where sku = 'MERGMBDAM17'), 8),"..
"(3718, (select id from catalogo where sku = 'MERGMBDAM18'), 8),"..
"(3719, (select id from catalogo where sku = 'MERGMBDAM19'), 8),"..
"(3720, (select id from catalogo where sku = 'MERGMBDAM29'), 8),"..
"(3721, (select id from catalogo where sku = 'MERGMBDAM40'), 8),"..
"(3722, (select id from catalogo where sku = 'MERGMBDAM41'), 8),"..
"(3723, (select id from catalogo where sku = 'MERGMBDES04'), 8),"..
"(3724, (select id from catalogo where sku = 'MERGMBDES05'), 8),"..
"(3725, (select id from catalogo where sku = 'MERGMBDES06'), 8),"..
"(3726, (select id from catalogo where sku = 'MERGMBDES10'), 8),"..
"(3727, (select id from catalogo where sku = 'MERGMBDES11'), 8),"..
"(3728, (select id from catalogo where sku = 'MERGMBDES12'), 8),"..
"(3729, (select id from catalogo where sku = 'MERGMBDES13'), 8),"..
"(3730, (select id from catalogo where sku = 'MERGMBDES15'), 8),"..
"(3731, (select id from catalogo where sku = 'MERGMBDES16'), 8),"..
"(3732, (select id from catalogo where sku = 'MERGMBDES21'), 8),"..
"(3733, (select id from catalogo where sku = 'MERGMBDES25'), 8),"..
"(3734, (select id from catalogo where sku = 'MERGMBDES26'), 8),"..
"(3735, (select id from catalogo where sku = 'MERGMBDES28'), 8),"..
"(3736, (select id from catalogo where sku = 'MERGMBDES30'), 8),"..
"(3737, (select id from catalogo where sku = 'MERGMBDES32'), 8),"..
"(3738, (select id from catalogo where sku = 'MERGMBDES34'), 8),"..
"(3739, (select id from catalogo where sku = 'MERGMBDES35'), 8),"..
"(3740, (select id from catalogo where sku = 'MERGMBDES37'), 8),"..
"(3741, (select id from catalogo where sku = 'MN-00902'), 2),"..
"(3742, (select id from catalogo where sku = 'MN-00902'), 3),"..
"(3743, (select id from catalogo where sku = 'MN-00902'), 4),"..
"(3744, (select id from catalogo where sku = 'MN-00902'), 5),"..
"(3745, (select id from catalogo where sku = 'MN-00902'), 6),"..
"(3746, (select id from catalogo where sku = 'MN-00911'), 2),"..
"(3747, (select id from catalogo where sku = 'MN-00911'), 3),"..
"(3748, (select id from catalogo where sku = 'MN-00911'), 4),"..
"(3749, (select id from catalogo where sku = 'MN-00911'), 5),"..
"(3750, (select id from catalogo where sku = 'MN-00911'), 6),"..
"(3751, (select id from catalogo where sku = 'MN-00913'), 2),"..
"(3752, (select id from catalogo where sku = 'MN-00913'), 3),"..
"(3753, (select id from catalogo where sku = 'MN-00913'), 4),"..
"(3754, (select id from catalogo where sku = 'MN-00913'), 5),"..
"(3755, (select id from catalogo where sku = 'MN-00913'), 6),"..
"(3756, (select id from catalogo where sku = 'MN-009D'), 2),"..
"(3757, (select id from catalogo where sku = 'MN-009D'), 3),"..
"(3758, (select id from catalogo where sku = 'MN-009D'), 4),"..
"(3759, (select id from catalogo where sku = 'MN-009D'), 5),"..
"(3760, (select id from catalogo where sku = 'MN-009D'), 6),"..
"(3761, (select id from catalogo where sku = 'MN-02612'), 2),"..
"(3762, (select id from catalogo where sku = 'MN-02612'), 3),"..
"(3763, (select id from catalogo where sku = 'MN-02612'), 4),"..
"(3764, (select id from catalogo where sku = 'MN-02612'), 5),"..
"(3765, (select id from catalogo where sku = 'MN-02612'), 6),"..
"(3766, (select id from catalogo where sku = 'MN-02613'), 2),"..
"(3767, (select id from catalogo where sku = 'MN-02613'), 3),"..
"(3768, (select id from catalogo where sku = 'MN-02613'), 4),"..
"(3769, (select id from catalogo where sku = 'MN-02613'), 5),"..
"(3770, (select id from catalogo where sku = 'MN-02613'), 6),"..
"(3771, (select id from catalogo where sku = 'MN-02617'), 2),"..
"(3772, (select id from catalogo where sku = 'MN-02617'), 3),"..
"(3773, (select id from catalogo where sku = 'MN-02617'), 4),"..
"(3774, (select id from catalogo where sku = 'MN-02617'), 5),"..
"(3775, (select id from catalogo where sku = 'MN-02617'), 6),"..
"(3776, (select id from catalogo where sku = 'MN-026G'), 2),"..
"(3777, (select id from catalogo where sku = 'MN-026G'), 3),"..
"(3778, (select id from catalogo where sku = 'MN-026G'), 4),"..
"(3779, (select id from catalogo where sku = 'MN-026G'), 5),"..
"(3780, (select id from catalogo where sku = 'MN-026G'), 6),"..
"(3781, (select id from catalogo where sku = 'MN-026H'), 2),"..
"(3782, (select id from catalogo where sku = 'MN-026H'), 3),"..
"(3783, (select id from catalogo where sku = 'MN-026H'), 4),"..
"(3784, (select id from catalogo where sku = 'MN-026H'), 5),"..
"(3785, (select id from catalogo where sku = 'MN-026H'), 6),"..
"(3786, (select id from catalogo where sku = 'MN-026M'), 2),"..
"(3787, (select id from catalogo where sku = 'MN-026M'), 3),"..
"(3788, (select id from catalogo where sku = 'MN-026M'), 4),"..
"(3789, (select id from catalogo where sku = 'MN-026M'), 5),"..
"(3790, (select id from catalogo where sku = 'MN-026M'), 6),"..
"(3791, (select id from catalogo where sku = 'MN-05103'), 2),"..
"(3792, (select id from catalogo where sku = 'MN-05103'), 3),"..
"(3793, (select id from catalogo where sku = 'MN-05103'), 4),"..
"(3794, (select id from catalogo where sku = 'MN-05103'), 5),"..
"(3795, (select id from catalogo where sku = 'MN-05103'), 6),"..
"(3796, (select id from catalogo where sku = 'MN-05189'), 2),"..
"(3797, (select id from catalogo where sku = 'MN-05189'), 3),"..
"(3798, (select id from catalogo where sku = 'MN-05189'), 4),"..
"(3799, (select id from catalogo where sku = 'MN-05189'), 5),"..
"(3800, (select id from catalogo where sku = 'MN-05189'), 6),"..
"(3801, (select id from catalogo where sku = 'MN-05913'), 2),"..
"(3802, (select id from catalogo where sku = 'MN-05913'), 3),"..
"(3803, (select id from catalogo where sku = 'MN-05913'), 4),"..
"(3804, (select id from catalogo where sku = 'MN-05913'), 5),"..
"(3805, (select id from catalogo where sku = 'MN-05913'), 6),"..
"(3806, (select id from catalogo where sku = 'MN-059G'), 2),"..
"(3807, (select id from catalogo where sku = 'MN-059G'), 3),"..
"(3808, (select id from catalogo where sku = 'MN-059G'), 4),"..
"(3809, (select id from catalogo where sku = 'MN-059G'), 5),"..
"(3810, (select id from catalogo where sku = 'MN-059G'), 6),"..
"(3811, (select id from catalogo where sku = 'MN-06511'), 2),"..
"(3812, (select id from catalogo where sku = 'MN-06511'), 3),"..
"(3813, (select id from catalogo where sku = 'MN-06511'), 4),"..
"(3814, (select id from catalogo where sku = 'MN-06511'), 5),"..
"(3815, (select id from catalogo where sku = 'MN-06511'), 6),"..
"(3816, (select id from catalogo where sku = 'MN-06513'), 2),"..
"(3817, (select id from catalogo where sku = 'MN-06513'), 3),"..
"(3818, (select id from catalogo where sku = 'MN-06513'), 4),"..
"(3819, (select id from catalogo where sku = 'MN-06513'), 5),"..
"(3820, (select id from catalogo where sku = 'MN-06513'), 6),"..
"(3821, (select id from catalogo where sku = 'MN-077B'), 2),"..
"(3822, (select id from catalogo where sku = 'MN-077B'), 3),"..
"(3823, (select id from catalogo where sku = 'MN-077B'), 4),"..
"(3824, (select id from catalogo where sku = 'MN-077B'), 5),"..
"(3825, (select id from catalogo where sku = 'MN-077B'), 6),"..
"(3826, (select id from catalogo where sku = 'MN-077H'), 2),"..
"(3827, (select id from catalogo where sku = 'MN-077H'), 3),"..
"(3828, (select id from catalogo where sku = 'MN-077H'), 4),"..
"(3829, (select id from catalogo where sku = 'MN-077H'), 5),"..
"(3830, (select id from catalogo where sku = 'MN-077H'), 6),"..
"(3831, (select id from catalogo where sku = 'MN-07811'), 2),"..
"(3832, (select id from catalogo where sku = 'MN-07811'), 3),"..
"(3833, (select id from catalogo where sku = 'MN-07811'), 4),"..
"(3834, (select id from catalogo where sku = 'MN-07811'), 5),"..
"(3835, (select id from catalogo where sku = 'MN-07811'), 6),"..
"(3836, (select id from catalogo where sku = 'MN-07878'), 2),"..
"(3837, (select id from catalogo where sku = 'MN-07878'), 3),"..
"(3838, (select id from catalogo where sku = 'MN-07878'), 4),"..
"(3839, (select id from catalogo where sku = 'MN-07878'), 5),"..
"(3840, (select id from catalogo where sku = 'MN-07878'), 6),"..
"(3841, (select id from catalogo where sku = 'MN-078R'), 2),"..
"(3842, (select id from catalogo where sku = 'MN-078R'), 3),"..
"(3843, (select id from catalogo where sku = 'MN-078R'), 4),"..
"(3844, (select id from catalogo where sku = 'MN-078R'), 5),"..
"(3845, (select id from catalogo where sku = 'MN-078R'), 6),"..
"(3846, (select id from catalogo where sku = 'MN-08878'), 2),"..
"(3847, (select id from catalogo where sku = 'MN-08878'), 3),"..
"(3848, (select id from catalogo where sku = 'MN-08878'), 4),"..
"(3849, (select id from catalogo where sku = 'MN-08878'), 5),"..
"(3850, (select id from catalogo where sku = 'MN-08878'), 6),"..
"(3851, (select id from catalogo where sku = 'MN-088B'), 2),"..
"(3852, (select id from catalogo where sku = 'MN-088B'), 3),"..
"(3853, (select id from catalogo where sku = 'MN-088B'), 4),"..
"(3854, (select id from catalogo where sku = 'MN-088B'), 5),"..
"(3855, (select id from catalogo where sku = 'MN-088B'), 6),"..
"(3856, (select id from catalogo where sku = 'MN-088K'), 2),"..
"(3857, (select id from catalogo where sku = 'MN-088K'), 3),"..
"(3858, (select id from catalogo where sku = 'MN-088K'), 4),"..
"(3859, (select id from catalogo where sku = 'MN-088K'), 5),"..
"(3860, (select id from catalogo where sku = 'MN-088K'), 6),"..
"(3861, (select id from catalogo where sku = 'MN-088R'), 2),"..
"(3862, (select id from catalogo where sku = 'MN-088R'), 3),"..
"(3863, (select id from catalogo where sku = 'MN-088R'), 4),"..
"(3864, (select id from catalogo where sku = 'MN-088R'), 5),"..
"(3865, (select id from catalogo where sku = 'MN-088R'), 6),"..
"(3866, (select id from catalogo where sku = 'MN-08990'), 2),"..
"(3867, (select id from catalogo where sku = 'MN-08990'), 3),"..
"(3868, (select id from catalogo where sku = 'MN-08990'), 4),"..
"(3869, (select id from catalogo where sku = 'MN-08990'), 5),"..
"(3870, (select id from catalogo where sku = 'MN-08990'), 6),"..
"(3871, (select id from catalogo where sku = 'MN-089K'), 2),"..
"(3872, (select id from catalogo where sku = 'MN-089K'), 3),"..
"(3873, (select id from catalogo where sku = 'MN-089K'), 4),"..
"(3874, (select id from catalogo where sku = 'MN-089K'), 5),"..
"(3875, (select id from catalogo where sku = 'MN-089K'), 6),"..
"(3876, (select id from catalogo where sku = 'MN-090B'), 2),"..
"(3877, (select id from catalogo where sku = 'MN-090B'), 3),"..
"(3878, (select id from catalogo where sku = 'MN-090B'), 4),"..
"(3879, (select id from catalogo where sku = 'MN-090B'), 5),"..
"(3880, (select id from catalogo where sku = 'MN-090B'), 6),"..
"(3881, (select id from catalogo where sku = 'MN-090G'), 2),"..
"(3882, (select id from catalogo where sku = 'MN-090G'), 3),"..
"(3883, (select id from catalogo where sku = 'MN-090G'), 4),"..
"(3884, (select id from catalogo where sku = 'MN-090G'), 5),"..
"(3885, (select id from catalogo where sku = 'MN-090G'), 6),"..
"(3886, (select id from catalogo where sku = 'MN-090R'), 2),"..
"(3887, (select id from catalogo where sku = 'MN-090R'), 3),"..
"(3888, (select id from catalogo where sku = 'MN-090R'), 4),"..
"(3889, (select id from catalogo where sku = 'MN-090R'), 5),"..
"(3890, (select id from catalogo where sku = 'MN-090R'), 6),"..
"(3891, (select id from catalogo where sku = 'MN-09103'), 2),"..
"(3892, (select id from catalogo where sku = 'MN-09103'), 3),"..
"(3893, (select id from catalogo where sku = 'MN-09103'), 4),"..
"(3894, (select id from catalogo where sku = 'MN-09103'), 5),"..
"(3895, (select id from catalogo where sku = 'MN-09103'), 6),"..
"(3896, (select id from catalogo where sku = 'MN-09113'), 2),"..
"(3897, (select id from catalogo where sku = 'MN-09113'), 3),"..
"(3898, (select id from catalogo where sku = 'MN-09113'), 4),"..
"(3899, (select id from catalogo where sku = 'MN-09113'), 5),"..
"(3900, (select id from catalogo where sku = 'MN-09113'), 6);"
db:exec( query2 )
--fase 27
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3901, (select id from catalogo where sku = 'MN-091G'), 2),"..
"(3902, (select id from catalogo where sku = 'MN-091G'), 3),"..
"(3903, (select id from catalogo where sku = 'MN-091G'), 4),"..
"(3904, (select id from catalogo where sku = 'MN-091G'), 5),"..
"(3905, (select id from catalogo where sku = 'MN-091G'), 6),"..
"(3906, (select id from catalogo where sku = 'MN-09403'), 2),"..
"(3907, (select id from catalogo where sku = 'MN-09403'), 3),"..
"(3908, (select id from catalogo where sku = 'MN-09403'), 4),"..
"(3909, (select id from catalogo where sku = 'MN-09403'), 5),"..
"(3910, (select id from catalogo where sku = 'MN-09403'), 6),"..
"(3911, (select id from catalogo where sku = 'MN-09415'), 2),"..
"(3912, (select id from catalogo where sku = 'MN-09415'), 3),"..
"(3913, (select id from catalogo where sku = 'MN-09415'), 4),"..
"(3914, (select id from catalogo where sku = 'MN-09415'), 5),"..
"(3915, (select id from catalogo where sku = 'MN-09415'), 6),"..
"(3916, (select id from catalogo where sku = 'MN-09429'), 2),"..
"(3917, (select id from catalogo where sku = 'MN-09429'), 3),"..
"(3918, (select id from catalogo where sku = 'MN-09429'), 4),"..
"(3919, (select id from catalogo where sku = 'MN-09429'), 5),"..
"(3920, (select id from catalogo where sku = 'MN-09429'), 6),"..
"(3921, (select id from catalogo where sku = 'MN-094B'), 2),"..
"(3922, (select id from catalogo where sku = 'MN-094B'), 3),"..
"(3923, (select id from catalogo where sku = 'MN-094B'), 4),"..
"(3924, (select id from catalogo where sku = 'MN-094B'), 5),"..
"(3925, (select id from catalogo where sku = 'MN-094B'), 6),"..
"(3926, (select id from catalogo where sku = 'MN-094K'), 2),"..
"(3927, (select id from catalogo where sku = 'MN-094K'), 3),"..
"(3928, (select id from catalogo where sku = 'MN-094K'), 4),"..
"(3929, (select id from catalogo where sku = 'MN-094K'), 5),"..
"(3930, (select id from catalogo where sku = 'MN-094K'), 6),"..
"(3931, (select id from catalogo where sku = 'MN-094R'), 2),"..
"(3932, (select id from catalogo where sku = 'MN-094R'), 3),"..
"(3933, (select id from catalogo where sku = 'MN-094R'), 4),"..
"(3934, (select id from catalogo where sku = 'MN-094R'), 5),"..
"(3935, (select id from catalogo where sku = 'MN-094R'), 6),"..
"(3936, (select id from catalogo where sku = 'MN-09709'), 2),"..
"(3937, (select id from catalogo where sku = 'MN-09709'), 3),"..
"(3938, (select id from catalogo where sku = 'MN-09709'), 4),"..
"(3939, (select id from catalogo where sku = 'MN-09709'), 5);"
db:exec( query2 )
--fase 27
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(3940, (select id from catalogo where sku = 'MN-09709'), 6),"..
"(3941, (select id from catalogo where sku = 'MN-09713'), 2),"..
"(3942, (select id from catalogo where sku = 'MN-09713'), 3),"..
"(3943, (select id from catalogo where sku = 'MN-09713'), 4),"..
"(3944, (select id from catalogo where sku = 'MN-09713'), 5),"..
"(3945, (select id from catalogo where sku = 'MN-09713'), 6),"..
"(3946, (select id from catalogo where sku = 'OMNGMBDES04'), 8),"..
"(3947, (select id from catalogo where sku = 'OMNGMBDES05'), 8),"..
"(3948, (select id from catalogo where sku = 'OMNGMBDES06'), 8),"..
"(3949, (select id from catalogo where sku = 'OMNGMBDES10'), 8),"..
"(3950, (select id from catalogo where sku = 'OMNGMBDES11'), 8),"..
"(3951, (select id from catalogo where sku = 'OMNGMBDES12'), 8),"..
"(3952, (select id from catalogo where sku = 'OMNGMBDES13'), 8),"..
"(3953, (select id from catalogo where sku = 'OMNGMBDES15'), 8),"..
"(3954, (select id from catalogo where sku = 'OMNGMBDES16'), 8),"..
"(3955, (select id from catalogo where sku = 'OMNGMBDES21'), 8),"..
"(3956, (select id from catalogo where sku = 'OMNGMBDES25'), 8),"..
"(3957, (select id from catalogo where sku = 'OMNGMBDES26'), 8),"..
"(3958, (select id from catalogo where sku = 'OMNGMBDES28'), 8),"..
"(3959, (select id from catalogo where sku = 'OMNGMBDES30'), 8),"..
"(3960, (select id from catalogo where sku = 'OMNGMBDES32'), 8),"..
"(3961, (select id from catalogo where sku = 'OMNGMBDES34'), 8),"..
"(3962, (select id from catalogo where sku = 'OMNGMBDES35'), 8),"..
"(3963, (select id from catalogo where sku = 'OMNGMBDES37'), 8),"..
"(3964, (select id from catalogo where sku = 'PA250TCN00112'), 2),"..
"(3965, (select id from catalogo where sku = 'PA250TCN00112'), 3),"..
"(3966, (select id from catalogo where sku = 'PA250TCN00112'), 4),"..
"(3967, (select id from catalogo where sku = 'PA250TCN00112'), 5),"..
"(3968, (select id from catalogo where sku = 'PA250TCN00213'), 2),"..
"(3969, (select id from catalogo where sku = 'PA250TCN00213'), 3),"..
"(3970, (select id from catalogo where sku = 'PA250TCN00213'), 4),"..
"(3971, (select id from catalogo where sku = 'PA250TCN00213'), 5),"..
"(3972, (select id from catalogo where sku = 'PA250TCN00315'), 2),"..
"(3973, (select id from catalogo where sku = 'PA250TCN00315'), 3),"..
"(3974, (select id from catalogo where sku = 'PA250TCN00315'), 4),"..
"(3975, (select id from catalogo where sku = 'PA250TCN00315'), 5),"..
"(3976, (select id from catalogo where sku = 'PA250TCN004U'), 2),"..
"(3977, (select id from catalogo where sku = 'PA250TCN004U'), 3),"..
"(3978, (select id from catalogo where sku = 'PA250TCN004U'), 4),"..
"(3979, (select id from catalogo where sku = 'PA250TCN004U'), 5),"..
"(3980, (select id from catalogo where sku = 'PA250TCNXXL00112'), 6),"..
"(3981, (select id from catalogo where sku = 'PA250TCNXXL00213'), 6),"..
"(3982, (select id from catalogo where sku = 'PA250TCNXXL00315'), 6),"..
"(3983, (select id from catalogo where sku = 'PA250TCNXXL004U'), 6),"..
"(3984, (select id from catalogo where sku = 'PA250TRM00112'), 2),"..
"(3985, (select id from catalogo where sku = 'PA250TRM00112'), 3),"..
"(3986, (select id from catalogo where sku = 'PA250TRM00112'), 4),"..
"(3987, (select id from catalogo where sku = 'PA250TRM00112'), 5),"..
"(3988, (select id from catalogo where sku = 'PA250TRM00213'), 2),"..
"(3989, (select id from catalogo where sku = 'PA250TRM00213'), 3),"..
"(3990, (select id from catalogo where sku = 'PA250TRM00213'), 4),"..
"(3991, (select id from catalogo where sku = 'PA250TRM00213'), 5),"..
"(3992, (select id from catalogo where sku = 'PA250TRM00315'), 2),"..
"(3993, (select id from catalogo where sku = 'PA250TRM00315'), 3),"..
"(3994, (select id from catalogo where sku = 'PA250TRM00315'), 4),"..
"(3995, (select id from catalogo where sku = 'PA250TRM00315'), 5),"..
"(3996, (select id from catalogo where sku = 'PA250TRM004U'), 2),"..
"(3997, (select id from catalogo where sku = 'PA250TRM004U'), 3),"..
"(3998, (select id from catalogo where sku = 'PA250TRM004U'), 4),"..
"(3999, (select id from catalogo where sku = 'PA250TRM004U'), 5),"..
"(4000, (select id from catalogo where sku = 'PA250TRMXX004LU'), 6),"..
"(4001, (select id from catalogo where sku = 'PA250TRMXXL00112'), 6),"..
"(4002, (select id from catalogo where sku = 'PA250TRMXXL00213'), 6),"..
"(4003, (select id from catalogo where sku = 'PA250TRMXXL00315'), 6),"..
"(4004, (select id from catalogo where sku = 'PA300TCN00173'), 2),"..
"(4005, (select id from catalogo where sku = 'PA300TCN00173'), 3),"..
"(4006, (select id from catalogo where sku = 'PA300TCN00173'), 4),"..
"(4007, (select id from catalogo where sku = 'PA300TCN00173'), 5),"..
"(4008, (select id from catalogo where sku = 'PA300TCN00212'), 2),"..
"(4009, (select id from catalogo where sku = 'PA300TCN00212'), 3),"..
"(4010, (select id from catalogo where sku = 'PA300TCN00212'), 4),"..
"(4011, (select id from catalogo where sku = 'PA300TCN00212'), 5),"..
"(4012, (select id from catalogo where sku = 'PA300TCN00324'), 2),"..
"(4013, (select id from catalogo where sku = 'PA300TCN00324'), 3),"..
"(4014, (select id from catalogo where sku = 'PA300TCN00324'), 4),"..
"(4015, (select id from catalogo where sku = 'PA300TCN00324'), 5),"..
"(4016, (select id from catalogo where sku = 'PA300TCN00417'), 2),"..
"(4017, (select id from catalogo where sku = 'PA300TCN00417'), 3),"..
"(4018, (select id from catalogo where sku = 'PA300TCN00417'), 4),"..
"(4019, (select id from catalogo where sku = 'PA300TCN00417'), 5),"..
"(4020, (select id from catalogo where sku = 'PA300TCN00513'), 2),"..
"(4021, (select id from catalogo where sku = 'PA300TCN00513'), 3),"..
"(4022, (select id from catalogo where sku = 'PA300TCN00513'), 4),"..
"(4023, (select id from catalogo where sku = 'PA300TCN00513'), 5),"..
"(4024, (select id from catalogo where sku = 'PA300TCN00624'), 2),"..
"(4025, (select id from catalogo where sku = 'PA300TCN00624'), 3),"..
"(4026, (select id from catalogo where sku = 'PA300TCN00624'), 4),"..
"(4027, (select id from catalogo where sku = 'PA300TCN00624'), 5),"..
"(4028, (select id from catalogo where sku = 'PA300TCN00711'), 2),"..
"(4029, (select id from catalogo where sku = 'PA300TCN00711'), 3),"..
"(4030, (select id from catalogo where sku = 'PA300TCN00711'), 4),"..
"(4031, (select id from catalogo where sku = 'PA300TCN00711'), 5),"..
"(4032, (select id from catalogo where sku = 'PA300TCN00810'), 2),"..
"(4033, (select id from catalogo where sku = 'PA300TCN00810'), 3),"..
"(4034, (select id from catalogo where sku = 'PA300TCN00810'), 4),"..
"(4035, (select id from catalogo where sku = 'PA300TCN00810'), 5),"..
"(4036, (select id from catalogo where sku = 'PA300TCN00912'), 2),"..
"(4037, (select id from catalogo where sku = 'PA300TCN00912'), 3),"..
"(4038, (select id from catalogo where sku = 'PA300TCN00912'), 4),"..
"(4039, (select id from catalogo where sku = 'PA300TCN00912'), 5),"..
"(4040, (select id from catalogo where sku = 'PA300TCN01009'), 2),"..
"(4041, (select id from catalogo where sku = 'PA300TCN01009'), 3),"..
"(4042, (select id from catalogo where sku = 'PA300TCN01009'), 4),"..
"(4043, (select id from catalogo where sku = 'PA300TCN01009'), 5),"..
"(4044, (select id from catalogo where sku = 'PA300TCN01108'), 2),"..
"(4045, (select id from catalogo where sku = 'PA300TCN01108'), 3),"..
"(4046, (select id from catalogo where sku = 'PA300TCN01108'), 4),"..
"(4047, (select id from catalogo where sku = 'PA300TCN01108'), 5),"..
"(4048, (select id from catalogo where sku = 'PA300TCN01213'), 2),"..
"(4049, (select id from catalogo where sku = 'PA300TCN01213'), 3),"..
"(4050, (select id from catalogo where sku = 'PA300TCN01213'), 4),"..
"(4051, (select id from catalogo where sku = 'PA300TCN01213'), 5),"..
"(4052, (select id from catalogo where sku = 'PA300TCN01308'), 2),"..
"(4053, (select id from catalogo where sku = 'PA300TCN01308'), 3),"..
"(4054, (select id from catalogo where sku = 'PA300TCN01308'), 4),"..
"(4055, (select id from catalogo where sku = 'PA300TCN01308'), 5),"..
"(4056, (select id from catalogo where sku = 'PA300TCN01413'), 2),"..
"(4057, (select id from catalogo where sku = 'PA300TCN01413'), 3),"..
"(4058, (select id from catalogo where sku = 'PA300TCN01413'), 4),"..
"(4059, (select id from catalogo where sku = 'PA300TCN01413'), 5),"..
"(4060, (select id from catalogo where sku = 'PA300TCN01528'), 2),"..
"(4061, (select id from catalogo where sku = 'PA300TCN01528'), 3),"..
"(4062, (select id from catalogo where sku = 'PA300TCN01528'), 4),"..
"(4063, (select id from catalogo where sku = 'PA300TCN01528'), 5),"..
"(4064, (select id from catalogo where sku = 'PA300TCN01613'), 2),"..
"(4065, (select id from catalogo where sku = 'PA300TCN01613'), 3),"..
"(4066, (select id from catalogo where sku = 'PA300TCN01613'), 4),"..
"(4067, (select id from catalogo where sku = 'PA300TCN01613'), 5),"..
"(4068, (select id from catalogo where sku = 'PA300TCN01711'), 2),"..
"(4069, (select id from catalogo where sku = 'PA300TCN01711'), 3),"..
"(4070, (select id from catalogo where sku = 'PA300TCN01711'), 4),"..
"(4071, (select id from catalogo where sku = 'PA300TCN01711'), 5),"..
"(4072, (select id from catalogo where sku = 'PA300TCN01812'), 2),"..
"(4073, (select id from catalogo where sku = 'PA300TCN01812'), 3),"..
"(4074, (select id from catalogo where sku = 'PA300TCN01812'), 4),"..
"(4075, (select id from catalogo where sku = 'PA300TCN01812'), 5),"..
"(4076, (select id from catalogo where sku = 'PA300TCN01911'), 2),"..
"(4077, (select id from catalogo where sku = 'PA300TCN01911'), 3),"..
"(4078, (select id from catalogo where sku = 'PA300TCN01911'), 4),"..
"(4079, (select id from catalogo where sku = 'PA300TCN01911'), 5),"..
"(4080, (select id from catalogo where sku = 'PA300TCN02013'), 2),"..
"(4081, (select id from catalogo where sku = 'PA300TCN02013'), 3),"..
"(4082, (select id from catalogo where sku = 'PA300TCN02013'), 4),"..
"(4083, (select id from catalogo where sku = 'PA300TCN02013'), 5),"..
"(4084, (select id from catalogo where sku = 'PA300TCN02111'), 2),"..
"(4085, (select id from catalogo where sku = 'PA300TCN02111'), 3),"..
"(4086, (select id from catalogo where sku = 'PA300TCN02111'), 4),"..
"(4087, (select id from catalogo where sku = 'PA300TCN02111'), 5),"..
"(4088, (select id from catalogo where sku = 'PA300TCN02224'), 2),"..
"(4089, (select id from catalogo where sku = 'PA300TCN02224'), 3),"..
"(4090, (select id from catalogo where sku = 'PA300TCN02224'), 4);"
db:exec( query2 )
--fase 28
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4091, (select id from catalogo where sku = 'PA300TCN02224'), 5),"..
"(4092, (select id from catalogo where sku = 'PA300TCN02309'), 2),"..
"(4093, (select id from catalogo where sku = 'PA300TCN02309'), 3),"..
"(4094, (select id from catalogo where sku = 'PA300TCN02309'), 4),"..
"(4095, (select id from catalogo where sku = 'PA300TCN02309'), 5),"..
"(4096, (select id from catalogo where sku = 'PA300TCN02310'), 2),"..
"(4097, (select id from catalogo where sku = 'PA300TCN02310'), 3),"..
"(4098, (select id from catalogo where sku = 'PA300TCN02310'), 4),"..
"(4099, (select id from catalogo where sku = 'PA300TCN02310'), 5),"..
"(4100, (select id from catalogo where sku = 'PA300TCN02413'), 2),"..
"(4101, (select id from catalogo where sku = 'PA300TCN02413'), 3),"..
"(4102, (select id from catalogo where sku = 'PA300TCN02413'), 4),"..
"(4103, (select id from catalogo where sku = 'PA300TCN02413'), 5),"..
"(4104, (select id from catalogo where sku = 'PA300TCN02509'), 2),"..
"(4105, (select id from catalogo where sku = 'PA300TCN02509'), 3),"..
"(4106, (select id from catalogo where sku = 'PA300TCN02509'), 4),"..
"(4107, (select id from catalogo where sku = 'PA300TCN02509'), 5),"..
"(4108, (select id from catalogo where sku = 'PA300TCN02510'), 2),"..
"(4109, (select id from catalogo where sku = 'PA300TCN02510'), 3),"..
"(4110, (select id from catalogo where sku = 'PA300TCN02510'), 4),"..
"(4111, (select id from catalogo where sku = 'PA300TCN02510'), 5),"..
"(4112, (select id from catalogo where sku = 'PA300TCN02613'), 2),"..
"(4113, (select id from catalogo where sku = 'PA300TCN02613'), 3),"..
"(4114, (select id from catalogo where sku = 'PA300TCN02613'), 4),"..
"(4115, (select id from catalogo where sku = 'PA300TCN02613'), 5),"..
"(4116, (select id from catalogo where sku = 'PA300TCN02712'), 2),"..
"(4117, (select id from catalogo where sku = 'PA300TCN02712'), 3),"..
"(4118, (select id from catalogo where sku = 'PA300TCN02712'), 4),"..
"(4119, (select id from catalogo where sku = 'PA300TCN02712'), 5),"..
"(4120, (select id from catalogo where sku = 'PA300TCN02828'), 2),"..
"(4121, (select id from catalogo where sku = 'PA300TCN02828'), 3),"..
"(4122, (select id from catalogo where sku = 'PA300TCN02828'), 4),"..
"(4123, (select id from catalogo where sku = 'PA300TCN02828'), 5),"..
"(4124, (select id from catalogo where sku = 'PA300TCN02913'), 2),"..
"(4125, (select id from catalogo where sku = 'PA300TCN02913'), 3),"..
"(4126, (select id from catalogo where sku = 'PA300TCN02913'), 4),"..
"(4127, (select id from catalogo where sku = 'PA300TCN02913'), 5),"..
"(4128, (select id from catalogo where sku = 'PA300TCN03037'), 2),"..
"(4129, (select id from catalogo where sku = 'PA300TCN03037'), 3),"..
"(4130, (select id from catalogo where sku = 'PA300TCN03037'), 4),"..
"(4131, (select id from catalogo where sku = 'PA300TCN03037'), 5),"..
"(4132, (select id from catalogo where sku = 'PA300TCN03211'), 2),"..
"(4133, (select id from catalogo where sku = 'PA300TCN03211'), 3),"..
"(4134, (select id from catalogo where sku = 'PA300TCN03211'), 4),"..
"(4135, (select id from catalogo where sku = 'PA300TCN03211'), 5),"..
"(4136, (select id from catalogo where sku = 'PA300TCN03213'), 2),"..
"(4137, (select id from catalogo where sku = 'PA300TCN03213'), 3),"..
"(4138, (select id from catalogo where sku = 'PA300TCN03213'), 4),"..
"(4139, (select id from catalogo where sku = 'PA300TCN03213'), 5),"..
"(4140, (select id from catalogo where sku = 'PA300TCN03309'), 2),"..
"(4141, (select id from catalogo where sku = 'PA300TCN03309'), 3),"..
"(4142, (select id from catalogo where sku = 'PA300TCN03309'), 4),"..
"(4143, (select id from catalogo where sku = 'PA300TCN03309'), 5),"..
"(4144, (select id from catalogo where sku = 'PA300TCN03328'), 2),"..
"(4145, (select id from catalogo where sku = 'PA300TCN03328'), 3),"..
"(4146, (select id from catalogo where sku = 'PA300TCN03328'), 4),"..
"(4147, (select id from catalogo where sku = 'PA300TCN03328'), 5),"..
"(4148, (select id from catalogo where sku = 'PA300TCN03403'), 2),"..
"(4149, (select id from catalogo where sku = 'PA300TCN03403'), 3),"..
"(4150, (select id from catalogo where sku = 'PA300TCN03403'), 4),"..
"(4151, (select id from catalogo where sku = 'PA300TCN03403'), 5),"..
"(4152, (select id from catalogo where sku = 'PA300TCN03503'), 2),"..
"(4153, (select id from catalogo where sku = 'PA300TCN03503'), 3),"..
"(4154, (select id from catalogo where sku = 'PA300TCN03503'), 4),"..
"(4155, (select id from catalogo where sku = 'PA300TCN03503'), 5),"..
"(4156, (select id from catalogo where sku = 'PA300TCN03603'), 2),"..
"(4157, (select id from catalogo where sku = 'PA300TCN03603'), 3),"..
"(4158, (select id from catalogo where sku = 'PA300TCN03603'), 4),"..
"(4159, (select id from catalogo where sku = 'PA300TCN03603'), 5),"..
"(4160, (select id from catalogo where sku = 'PA300TCN03703'), 2),"..
"(4161, (select id from catalogo where sku = 'PA300TCN03703'), 3),"..
"(4162, (select id from catalogo where sku = 'PA300TCN03703'), 4),"..
"(4163, (select id from catalogo where sku = 'PA300TCN03703'), 5),"..
"(4164, (select id from catalogo where sku = 'PA300TCN03803'), 2),"..
"(4165, (select id from catalogo where sku = 'PA300TCN03803'), 3),"..
"(4166, (select id from catalogo where sku = 'PA300TCN03803'), 4),"..
"(4167, (select id from catalogo where sku = 'PA300TCN03803'), 5),"..
"(4168, (select id from catalogo where sku = 'PA300TCN03903'), 2),"..
"(4169, (select id from catalogo where sku = 'PA300TCN03903'), 3),"..
"(4170, (select id from catalogo where sku = 'PA300TCN03903'), 4),"..
"(4171, (select id from catalogo where sku = 'PA300TCN03903'), 5),"..
"(4172, (select id from catalogo where sku = 'PA300TCN04003'), 2),"..
"(4173, (select id from catalogo where sku = 'PA300TCN04003'), 3),"..
"(4174, (select id from catalogo where sku = 'PA300TCN04003'), 4),"..
"(4175, (select id from catalogo where sku = 'PA300TCN04003'), 5),"..
"(4176, (select id from catalogo where sku = 'PA300TCN04103'), 2),"..
"(4177, (select id from catalogo where sku = 'PA300TCN04103'), 3),"..
"(4178, (select id from catalogo where sku = 'PA300TCN04103'), 4),"..
"(4179, (select id from catalogo where sku = 'PA300TCN04103'), 5),"..
"(4180, (select id from catalogo where sku = 'PA300TCN04203'), 2),"..
"(4181, (select id from catalogo where sku = 'PA300TCN04203'), 3),"..
"(4182, (select id from catalogo where sku = 'PA300TCN04203'), 4),"..
"(4183, (select id from catalogo where sku = 'PA300TCN04203'), 5),"..
"(4184, (select id from catalogo where sku = 'PA300TCN04303'), 2),"..
"(4185, (select id from catalogo where sku = 'PA300TCN04303'), 3),"..
"(4186, (select id from catalogo where sku = 'PA300TCN04303'), 4),"..
"(4187, (select id from catalogo where sku = 'PA300TCN04303'), 5),"..
"(4188, (select id from catalogo where sku = 'PA300TCN04403'), 2),"..
"(4189, (select id from catalogo where sku = 'PA300TCN04403'), 3),"..
"(4190, (select id from catalogo where sku = 'PA300TCN04403'), 4),"..
"(4191, (select id from catalogo where sku = 'PA300TCN04403'), 5),"..
"(4192, (select id from catalogo where sku = 'PA300TCN04503'), 2),"..
"(4193, (select id from catalogo where sku = 'PA300TCN04503'), 3),"..
"(4194, (select id from catalogo where sku = 'PA300TCN04503'), 4),"..
"(4195, (select id from catalogo where sku = 'PA300TCN04503'), 5),"..
"(4196, (select id from catalogo where sku = 'PA300TCNXXL00173'), 6),"..
"(4197, (select id from catalogo where sku = 'PA300TCNXXL00212'), 6),"..
"(4198, (select id from catalogo where sku = 'PA300TCNXXL00324'), 6),"..
"(4199, (select id from catalogo where sku = 'PA300TCNXXL00417'), 6),"..
"(4200, (select id from catalogo where sku = 'PA300TCNXXL00513'), 6),"..
"(4201, (select id from catalogo where sku = 'PA300TCNXXL00624'), 6),"..
"(4202, (select id from catalogo where sku = 'PA300TCNXXL00711'), 6),"..
"(4203, (select id from catalogo where sku = 'PA300TCNXXL00810'), 6),"..
"(4204, (select id from catalogo where sku = 'PA300TCNXXL00912'), 6),"..
"(4205, (select id from catalogo where sku = 'PA300TCNXXL01009'), 6),"..
"(4206, (select id from catalogo where sku = 'PA300TCNXXL01108'), 6),"..
"(4207, (select id from catalogo where sku = 'PA300TCNXXL01213'), 6),"..
"(4208, (select id from catalogo where sku = 'PA300TCNXXL01308'), 6),"..
"(4209, (select id from catalogo where sku = 'PA300TCNXXL01413'), 6),"..
"(4210, (select id from catalogo where sku = 'PA300TCNXXL01528'), 6),"..
"(4211, (select id from catalogo where sku = 'PA300TCNXXL01613'), 6),"..
"(4212, (select id from catalogo where sku = 'PA300TCNXXL01711'), 6),"..
"(4213, (select id from catalogo where sku = 'PA300TCNXXL01812'), 6),"..
"(4214, (select id from catalogo where sku = 'PA300TCNXXL01911'), 6),"..
"(4215, (select id from catalogo where sku = 'PA300TCNXXL02013'), 6),"..
"(4216, (select id from catalogo where sku = 'PA300TCNXXL02111'), 6),"..
"(4217, (select id from catalogo where sku = 'PA300TCNXXL02224'), 6),"..
"(4218, (select id from catalogo where sku = 'PA300TCNXXL02309'), 6),"..
"(4219, (select id from catalogo where sku = 'PA300TCNXXL02310'), 6),"..
"(4220, (select id from catalogo where sku = 'PA300TCNXXL02413'), 6),"..
"(4221, (select id from catalogo where sku = 'PA300TCNXXL02509'), 6),"..
"(4222, (select id from catalogo where sku = 'PA300TCNXXL02510'), 6),"..
"(4223, (select id from catalogo where sku = 'PA300TCNXXL02613'), 6),"..
"(4224, (select id from catalogo where sku = 'PA300TCNXXL02712'), 6),"..
"(4225, (select id from catalogo where sku = 'PA300TCNXXL02828'), 6),"..
"(4226, (select id from catalogo where sku = 'PA300TCNXXL02913'), 6),"..
"(4227, (select id from catalogo where sku = 'PA300TCNXXL03037'), 6),"..
"(4228, (select id from catalogo where sku = 'PA300TCNXXL03211'), 6),"..
"(4229, (select id from catalogo where sku = 'PA300TCNXXL03213'), 6),"..
"(4230, (select id from catalogo where sku = 'PA300TCNXXL03309'), 6),"..
"(4231, (select id from catalogo where sku = 'PA300TCNXXL03328'), 6),"..
"(4232, (select id from catalogo where sku = 'PA300TCNXXL03403'), 6),"..
"(4233, (select id from catalogo where sku = 'PA300TCNXXL03503'), 6),"..
"(4234, (select id from catalogo where sku = 'PA300TCNXXL03603'), 6),"..
"(4235, (select id from catalogo where sku = 'PA300TCNXXL03703'), 6),"..
"(4236, (select id from catalogo where sku = 'PA300TCNXXL03803'), 6),"..
"(4237, (select id from catalogo where sku = 'PA300TCNXXL03903'), 6),"..
"(4238, (select id from catalogo where sku = 'PA300TCNXXL04003'), 6),"..
"(4239, (select id from catalogo where sku = 'PA300TCNXXL04103'), 6),"..
"(4240, (select id from catalogo where sku = 'PA300TCNXXL04203'), 6),"..
"(4241, (select id from catalogo where sku = 'PA300TCNXXL04303'), 6);"
db:exec( query2 )
--fase 29
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4242, (select id from catalogo where sku = 'PA300TCNXXL04403'), 6),"..
"(4243, (select id from catalogo where sku = 'PA300TCNXXL04503'), 6),"..
"(4244, (select id from catalogo where sku = 'PA300TRM00173'), 2),"..
"(4245, (select id from catalogo where sku = 'PA300TRM00173'), 3),"..
"(4246, (select id from catalogo where sku = 'PA300TRM00173'), 4),"..
"(4247, (select id from catalogo where sku = 'PA300TRM00173'), 5),"..
"(4248, (select id from catalogo where sku = 'PA300TRM00212'), 2),"..
"(4249, (select id from catalogo where sku = 'PA300TRM00212'), 3),"..
"(4250, (select id from catalogo where sku = 'PA300TRM00212'), 4),"..
"(4251, (select id from catalogo where sku = 'PA300TRM00212'), 5),"..
"(4252, (select id from catalogo where sku = 'PA300TRM00324'), 2),"..
"(4253, (select id from catalogo where sku = 'PA300TRM00324'), 3),"..
"(4254, (select id from catalogo where sku = 'PA300TRM00324'), 4),"..
"(4255, (select id from catalogo where sku = 'PA300TRM00324'), 5),"..
"(4256, (select id from catalogo where sku = 'PA300TRM00417'), 2),"..
"(4257, (select id from catalogo where sku = 'PA300TRM00417'), 3),"..
"(4258, (select id from catalogo where sku = 'PA300TRM00417'), 4),"..
"(4259, (select id from catalogo where sku = 'PA300TRM00417'), 5),"..
"(4260, (select id from catalogo where sku = 'PA300TRM00513'), 2),"..
"(4261, (select id from catalogo where sku = 'PA300TRM00513'), 3),"..
"(4262, (select id from catalogo where sku = 'PA300TRM00513'), 4),"..
"(4263, (select id from catalogo where sku = 'PA300TRM00513'), 5),"..
"(4264, (select id from catalogo where sku = 'PA300TRM00624'), 2),"..
"(4265, (select id from catalogo where sku = 'PA300TRM00624'), 3),"..
"(4266, (select id from catalogo where sku = 'PA300TRM00624'), 4),"..
"(4267, (select id from catalogo where sku = 'PA300TRM00624'), 5),"..
"(4268, (select id from catalogo where sku = 'PA300TRM00711'), 2),"..
"(4269, (select id from catalogo where sku = 'PA300TRM00711'), 3),"..
"(4270, (select id from catalogo where sku = 'PA300TRM00711'), 4),"..
"(4271, (select id from catalogo where sku = 'PA300TRM00711'), 5),"..
"(4272, (select id from catalogo where sku = 'PA300TRM00810'), 2),"..
"(4273, (select id from catalogo where sku = 'PA300TRM00810'), 3),"..
"(4274, (select id from catalogo where sku = 'PA300TRM00810'), 4),"..
"(4275, (select id from catalogo where sku = 'PA300TRM00810'), 5),"..
"(4276, (select id from catalogo where sku = 'PA300TRM00912'), 2),"..
"(4277, (select id from catalogo where sku = 'PA300TRM00912'), 3),"..
"(4278, (select id from catalogo where sku = 'PA300TRM00912'), 4),"..
"(4279, (select id from catalogo where sku = 'PA300TRM00912'), 5),"..
"(4280, (select id from catalogo where sku = 'PA300TRM01009'), 2),"..
"(4281, (select id from catalogo where sku = 'PA300TRM01009'), 3),"..
"(4282, (select id from catalogo where sku = 'PA300TRM01009'), 4),"..
"(4283, (select id from catalogo where sku = 'PA300TRM01009'), 5),"..
"(4284, (select id from catalogo where sku = 'PA300TRM01108'), 2),"..
"(4285, (select id from catalogo where sku = 'PA300TRM01108'), 3),"..
"(4286, (select id from catalogo where sku = 'PA300TRM01108'), 4),"..
"(4287, (select id from catalogo where sku = 'PA300TRM01108'), 5),"..
"(4288, (select id from catalogo where sku = 'PA300TRM01213'), 2),"..
"(4289, (select id from catalogo where sku = 'PA300TRM01213'), 3),"..
"(4290, (select id from catalogo where sku = 'PA300TRM01213'), 4),"..
"(4291, (select id from catalogo where sku = 'PA300TRM01213'), 5),"..
"(4292, (select id from catalogo where sku = 'PA300TRM01308'), 2),"..
"(4293, (select id from catalogo where sku = 'PA300TRM01308'), 3),"..
"(4294, (select id from catalogo where sku = 'PA300TRM01308'), 4),"..
"(4295, (select id from catalogo where sku = 'PA300TRM01308'), 5),"..
"(4296, (select id from catalogo where sku = 'PA300TRM01413'), 2),"..
"(4297, (select id from catalogo where sku = 'PA300TRM01413'), 3),"..
"(4298, (select id from catalogo where sku = 'PA300TRM01413'), 4),"..
"(4299, (select id from catalogo where sku = 'PA300TRM01413'), 5),"..
"(4300, (select id from catalogo where sku = 'PA300TRM01528'), 2),"..
"(4301, (select id from catalogo where sku = 'PA300TRM01528'), 3),"..
"(4302, (select id from catalogo where sku = 'PA300TRM01528'), 4),"..
"(4303, (select id from catalogo where sku = 'PA300TRM01528'), 5),"..
"(4304, (select id from catalogo where sku = 'PA300TRM01613'), 2),"..
"(4305, (select id from catalogo where sku = 'PA300TRM01613'), 3),"..
"(4306, (select id from catalogo where sku = 'PA300TRM01613'), 4),"..
"(4307, (select id from catalogo where sku = 'PA300TRM01613'), 5),"..
"(4308, (select id from catalogo where sku = 'PA300TRM01711'), 2),"..
"(4309, (select id from catalogo where sku = 'PA300TRM01711'), 3),"..
"(4310, (select id from catalogo where sku = 'PA300TRM01711'), 4),"..
"(4311, (select id from catalogo where sku = 'PA300TRM01711'), 5),"..
"(4312, (select id from catalogo where sku = 'PA300TRM01812'), 2),"..
"(4313, (select id from catalogo where sku = 'PA300TRM01812'), 3),"..
"(4314, (select id from catalogo where sku = 'PA300TRM01812'), 4),"..
"(4315, (select id from catalogo where sku = 'PA300TRM01812'), 5),"..
"(4316, (select id from catalogo where sku = 'PA300TRM01911'), 2),"..
"(4317, (select id from catalogo where sku = 'PA300TRM01911'), 3),"..
"(4318, (select id from catalogo where sku = 'PA300TRM01911'), 4),"..
"(4319, (select id from catalogo where sku = 'PA300TRM01911'), 5),"..
"(4320, (select id from catalogo where sku = 'PA300TRM02013'), 2),"..
"(4321, (select id from catalogo where sku = 'PA300TRM02013'), 3),"..
"(4322, (select id from catalogo where sku = 'PA300TRM02013'), 4),"..
"(4323, (select id from catalogo where sku = 'PA300TRM02013'), 5),"..
"(4324, (select id from catalogo where sku = 'PA300TRM02103'), 2),"..
"(4325, (select id from catalogo where sku = 'PA300TRM02103'), 3),"..
"(4326, (select id from catalogo where sku = 'PA300TRM02103'), 4),"..
"(4327, (select id from catalogo where sku = 'PA300TRM02103'), 5),"..
"(4328, (select id from catalogo where sku = 'PA300TRM02111'), 2),"..
"(4329, (select id from catalogo where sku = 'PA300TRM02111'), 3),"..
"(4330, (select id from catalogo where sku = 'PA300TRM02111'), 4),"..
"(4331, (select id from catalogo where sku = 'PA300TRM02111'), 5),"..
"(4332, (select id from catalogo where sku = 'PA300TRM02224'), 2),"..
"(4333, (select id from catalogo where sku = 'PA300TRM02224'), 3),"..
"(4334, (select id from catalogo where sku = 'PA300TRM02224'), 4),"..
"(4335, (select id from catalogo where sku = 'PA300TRM02224'), 5),"..
"(4336, (select id from catalogo where sku = 'PA300TRM02309'), 2),"..
"(4337, (select id from catalogo where sku = 'PA300TRM02309'), 3),"..
"(4338, (select id from catalogo where sku = 'PA300TRM02309'), 4),"..
"(4339, (select id from catalogo where sku = 'PA300TRM02309'), 5),"..
"(4340, (select id from catalogo where sku = 'PA300TRM02310'), 2),"..
"(4341, (select id from catalogo where sku = 'PA300TRM02310'), 3),"..
"(4342, (select id from catalogo where sku = 'PA300TRM02310'), 4),"..
"(4343, (select id from catalogo where sku = 'PA300TRM02310'), 5),"..
"(4344, (select id from catalogo where sku = 'PA300TRM02413'), 2),"..
"(4345, (select id from catalogo where sku = 'PA300TRM02413'), 3),"..
"(4346, (select id from catalogo where sku = 'PA300TRM02413'), 4),"..
"(4347, (select id from catalogo where sku = 'PA300TRM02413'), 5),"..
"(4348, (select id from catalogo where sku = 'PA300TRM02509'), 2),"..
"(4349, (select id from catalogo where sku = 'PA300TRM02509'), 3),"..
"(4350, (select id from catalogo where sku = 'PA300TRM02509'), 4),"..
"(4351, (select id from catalogo where sku = 'PA300TRM02509'), 5),"..
"(4352, (select id from catalogo where sku = 'PA300TRM02510'), 2),"..
"(4353, (select id from catalogo where sku = 'PA300TRM02510'), 3),"..
"(4354, (select id from catalogo where sku = 'PA300TRM02510'), 4),"..
"(4355, (select id from catalogo where sku = 'PA300TRM02510'), 5),"..
"(4356, (select id from catalogo where sku = 'PA300TRM02613'), 2),"..
"(4357, (select id from catalogo where sku = 'PA300TRM02613'), 3),"..
"(4358, (select id from catalogo where sku = 'PA300TRM02613'), 4),"..
"(4359, (select id from catalogo where sku = 'PA300TRM02613'), 5),"..
"(4360, (select id from catalogo where sku = 'PA300TRM02712'), 2),"..
"(4361, (select id from catalogo where sku = 'PA300TRM02712'), 3),"..
"(4362, (select id from catalogo where sku = 'PA300TRM02712'), 4),"..
"(4363, (select id from catalogo where sku = 'PA300TRM02712'), 5),"..
"(4364, (select id from catalogo where sku = 'PA300TRM02828'), 2),"..
"(4365, (select id from catalogo where sku = 'PA300TRM02828'), 3),"..
"(4366, (select id from catalogo where sku = 'PA300TRM02828'), 4),"..
"(4367, (select id from catalogo where sku = 'PA300TRM02828'), 5),"..
"(4368, (select id from catalogo where sku = 'PA300TRM02913'), 2),"..
"(4369, (select id from catalogo where sku = 'PA300TRM02913'), 3),"..
"(4370, (select id from catalogo where sku = 'PA300TRM02913'), 4),"..
"(4371, (select id from catalogo where sku = 'PA300TRM02913'), 5),"..
"(4372, (select id from catalogo where sku = 'PA300TRM03037'), 2),"..
"(4373, (select id from catalogo where sku = 'PA300TRM03037'), 3),"..
"(4374, (select id from catalogo where sku = 'PA300TRM03037'), 4),"..
"(4375, (select id from catalogo where sku = 'PA300TRM03037'), 5),"..
"(4376, (select id from catalogo where sku = 'PA300TRM03211'), 2),"..
"(4377, (select id from catalogo where sku = 'PA300TRM03211'), 3),"..
"(4378, (select id from catalogo where sku = 'PA300TRM03211'), 4),"..
"(4379, (select id from catalogo where sku = 'PA300TRM03211'), 5),"..
"(4380, (select id from catalogo where sku = 'PA300TRM03213'), 2),"..
"(4381, (select id from catalogo where sku = 'PA300TRM03213'), 3),"..
"(4382, (select id from catalogo where sku = 'PA300TRM03213'), 4),"..
"(4383, (select id from catalogo where sku = 'PA300TRM03213'), 5),"..
"(4384, (select id from catalogo where sku = 'PA300TRM03309'), 2),"..
"(4385, (select id from catalogo where sku = 'PA300TRM03309'), 3),"..
"(4386, (select id from catalogo where sku = 'PA300TRM03309'), 4),"..
"(4387, (select id from catalogo where sku = 'PA300TRM03309'), 5),"..
"(4388, (select id from catalogo where sku = 'PA300TRM03328'), 2),"..
"(4389, (select id from catalogo where sku = 'PA300TRM03328'), 3),"..
"(4390, (select id from catalogo where sku = 'PA300TRM03328'), 4),"..
"(4391, (select id from catalogo where sku = 'PA300TRM03328'), 5),"..
"(4392, (select id from catalogo where sku = 'PA300TRM03403'), 2);"
db:exec( query2 )
--fase 30
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4393, (select id from catalogo where sku = 'PA300TRM03403'), 3),"..
"(4394, (select id from catalogo where sku = 'PA300TRM03403'), 4),"..
"(4395, (select id from catalogo where sku = 'PA300TRM03403'), 5),"..
"(4396, (select id from catalogo where sku = 'PA300TRM03503'), 2),"..
"(4397, (select id from catalogo where sku = 'PA300TRM03503'), 3),"..
"(4398, (select id from catalogo where sku = 'PA300TRM03503'), 4),"..
"(4399, (select id from catalogo where sku = 'PA300TRM03503'), 5),"..
"(4400, (select id from catalogo where sku = 'PA300TRM03603'), 2),"..
"(4401, (select id from catalogo where sku = 'PA300TRM03603'), 3),"..
"(4402, (select id from catalogo where sku = 'PA300TRM03603'), 4),"..
"(4403, (select id from catalogo where sku = 'PA300TRM03603'), 5),"..
"(4404, (select id from catalogo where sku = 'PA300TRM03703'), 2),"..
"(4405, (select id from catalogo where sku = 'PA300TRM03703'), 3),"..
"(4406, (select id from catalogo where sku = 'PA300TRM03703'), 4),"..
"(4407, (select id from catalogo where sku = 'PA300TRM03703'), 5),"..
"(4408, (select id from catalogo where sku = 'PA300TRM03803'), 2),"..
"(4409, (select id from catalogo where sku = 'PA300TRM03803'), 3),"..
"(4410, (select id from catalogo where sku = 'PA300TRM03803'), 4),"..
"(4411, (select id from catalogo where sku = 'PA300TRM03803'), 5),"..
"(4412, (select id from catalogo where sku = 'PA300TRM03903'), 2),"..
"(4413, (select id from catalogo where sku = 'PA300TRM03903'), 3),"..
"(4414, (select id from catalogo where sku = 'PA300TRM03903'), 4),"..
"(4415, (select id from catalogo where sku = 'PA300TRM03903'), 5),"..
"(4416, (select id from catalogo where sku = 'PA300TRM04003'), 2),"..
"(4417, (select id from catalogo where sku = 'PA300TRM04003'), 3),"..
"(4418, (select id from catalogo where sku = 'PA300TRM04003'), 4),"..
"(4419, (select id from catalogo where sku = 'PA300TRM04003'), 5),"..
"(4420, (select id from catalogo where sku = 'PA300TRM04103'), 2),"..
"(4421, (select id from catalogo where sku = 'PA300TRM04103'), 3),"..
"(4422, (select id from catalogo where sku = 'PA300TRM04103'), 4),"..
"(4423, (select id from catalogo where sku = 'PA300TRM04103'), 5),"..
"(4424, (select id from catalogo where sku = 'PA300TRM04203'), 2),"..
"(4425, (select id from catalogo where sku = 'PA300TRM04203'), 3),"..
"(4426, (select id from catalogo where sku = 'PA300TRM04203'), 4),"..
"(4427, (select id from catalogo where sku = 'PA300TRM04203'), 5),"..
"(4428, (select id from catalogo where sku = 'PA300TRM04303'), 2),"..
"(4429, (select id from catalogo where sku = 'PA300TRM04303'), 3),"..
"(4430, (select id from catalogo where sku = 'PA300TRM04303'), 4),"..
"(4431, (select id from catalogo where sku = 'PA300TRM04303'), 5),"..
"(4432, (select id from catalogo where sku = 'PA300TRM04403'), 2),"..
"(4433, (select id from catalogo where sku = 'PA300TRM04403'), 3),"..
"(4434, (select id from catalogo where sku = 'PA300TRM04403'), 4),"..
"(4435, (select id from catalogo where sku = 'PA300TRM04403'), 5),"..
"(4436, (select id from catalogo where sku = 'PA300TRM04503'), 2),"..
"(4437, (select id from catalogo where sku = 'PA300TRM04503'), 3),"..
"(4438, (select id from catalogo where sku = 'PA300TRM04503'), 4),"..
"(4439, (select id from catalogo where sku = 'PA300TRM04503'), 5),"..
"(4440, (select id from catalogo where sku = 'PA300TRMXXL00173'), 6),"..
"(4441, (select id from catalogo where sku = 'PA300TRMXXL00212'), 6),"..
"(4442, (select id from catalogo where sku = 'PA300TRMXXL00324'), 6),"..
"(4443, (select id from catalogo where sku = 'PA300TRMXXL00417'), 6),"..
"(4444, (select id from catalogo where sku = 'PA300TRMXXL00513'), 6),"..
"(4445, (select id from catalogo where sku = 'PA300TRMXXL00624'), 6),"..
"(4446, (select id from catalogo where sku = 'PA300TRMXXL00711'), 6),"..
"(4447, (select id from catalogo where sku = 'PA300TRMXXL00810'), 6),"..
"(4448, (select id from catalogo where sku = 'PA300TRMXXL00912'), 6),"..
"(4449, (select id from catalogo where sku = 'PA300TRMXXL01009'), 6),"..
"(4450, (select id from catalogo where sku = 'PA300TRMXXL01108'), 6),"..
"(4451, (select id from catalogo where sku = 'PA300TRMXXL01213'), 6),"..
"(4452, (select id from catalogo where sku = 'PA300TRMXXL01308'), 6),"..
"(4453, (select id from catalogo where sku = 'PA300TRMXXL01413'), 6),"..
"(4454, (select id from catalogo where sku = 'PA300TRMXXL01528'), 6),"..
"(4455, (select id from catalogo where sku = 'PA300TRMXXL01613'), 6),"..
"(4456, (select id from catalogo where sku = 'PA300TRMXXL01711'), 6),"..
"(4457, (select id from catalogo where sku = 'PA300TRMXXL01812'), 6),"..
"(4458, (select id from catalogo where sku = 'PA300TRMXXL01911'), 6),"..
"(4459, (select id from catalogo where sku = 'PA300TRMXXL02013'), 6),"..
"(4460, (select id from catalogo where sku = 'PA300TRMXXL02111'), 6),"..
"(4461, (select id from catalogo where sku = 'PA300TRMXXL02224'), 6),"..
"(4462, (select id from catalogo where sku = 'PA300TRMXXL02309'), 6),"..
"(4463, (select id from catalogo where sku = 'PA300TRMXXL02310'), 6),"..
"(4464, (select id from catalogo where sku = 'PA300TRMXXL02413'), 6),"..
"(4465, (select id from catalogo where sku = 'PA300TRMXXL02509'), 6),"..
"(4466, (select id from catalogo where sku = 'PA300TRMXXL02510'), 6),"..
"(4467, (select id from catalogo where sku = 'PA300TRMXXL02613'), 6),"..
"(4468, (select id from catalogo where sku = 'PA300TRMXXL02712'), 6),"..
"(4469, (select id from catalogo where sku = 'PA300TRMXXL02828'), 6),"..
"(4470, (select id from catalogo where sku = 'PA300TRMXXL02913'), 6),"..
"(4471, (select id from catalogo where sku = 'PA300TRMXXL03037'), 6),"..
"(4472, (select id from catalogo where sku = 'PA300TRMXXL03211'), 6),"..
"(4473, (select id from catalogo where sku = 'PA300TRMXXL03213'), 6),"..
"(4474, (select id from catalogo where sku = 'PA300TRMXXL03309'), 6),"..
"(4475, (select id from catalogo where sku = 'PA300TRMXXL03328'), 6),"..
"(4476, (select id from catalogo where sku = 'PA300TRMXXL03403'), 6),"..
"(4477, (select id from catalogo where sku = 'PA300TRMXXL03503'), 6),"..
"(4478, (select id from catalogo where sku = 'PA300TRMXXL03603'), 6),"..
"(4479, (select id from catalogo where sku = 'PA300TRMXXL03703'), 6),"..
"(4480, (select id from catalogo where sku = 'PA300TRMXXL03803'), 6),"..
"(4481, (select id from catalogo where sku = 'PA300TRMXXL03903'), 6),"..
"(4482, (select id from catalogo where sku = 'PA300TRMXXL04003'), 6),"..
"(4483, (select id from catalogo where sku = 'PA300TRMXXL04103'), 6),"..
"(4484, (select id from catalogo where sku = 'PA300TRMXXL04203'), 6),"..
"(4485, (select id from catalogo where sku = 'PA300TRMXXL04303'), 6),"..
"(4486, (select id from catalogo where sku = 'PA300TRMXXL04403'), 6),"..
"(4487, (select id from catalogo where sku = 'PA300TRMXXL04503'), 6),"..
"(4488, (select id from catalogo where sku = 'PA310TCN00109'), 2),"..
"(4489, (select id from catalogo where sku = 'PA310TCN00109'), 3),"..
"(4490, (select id from catalogo where sku = 'PA310TCN00109'), 4),"..
"(4491, (select id from catalogo where sku = 'PA310TCN00109'), 5),"..
"(4492, (select id from catalogo where sku = 'PA310TCN00216'), 2),"..
"(4493, (select id from catalogo where sku = 'PA310TCN00216'), 3),"..
"(4494, (select id from catalogo where sku = 'PA310TCN00216'), 4),"..
"(4495, (select id from catalogo where sku = 'PA310TCN00216'), 5),"..
"(4496, (select id from catalogo where sku = 'PA310TCN00311'), 2),"..
"(4497, (select id from catalogo where sku = 'PA310TCN00311'), 3),"..
"(4498, (select id from catalogo where sku = 'PA310TCN00311'), 4),"..
"(4499, (select id from catalogo where sku = 'PA310TCN00311'), 5),"..
"(4500, (select id from catalogo where sku = 'PA310TCN00413'), 2),"..
"(4501, (select id from catalogo where sku = 'PA310TCN00413'), 3),"..
"(4502, (select id from catalogo where sku = 'PA310TCN00413'), 4),"..
"(4503, (select id from catalogo where sku = 'PA310TCN00413'), 5),"..
"(4504, (select id from catalogo where sku = 'PA310TCN00503'), 2),"..
"(4505, (select id from catalogo where sku = 'PA310TCN00503'), 3),"..
"(4506, (select id from catalogo where sku = 'PA310TCN00503'), 4),"..
"(4507, (select id from catalogo where sku = 'PA310TCN00503'), 5),"..
"(4508, (select id from catalogo where sku = 'PA310TCNXXL00109'), 6),"..
"(4509, (select id from catalogo where sku = 'PA310TCNXXL00216'), 6),"..
"(4510, (select id from catalogo where sku = 'PA310TCNXXL00311'), 6),"..
"(4511, (select id from catalogo where sku = 'PA310TCNXXL00413'), 6),"..
"(4512, (select id from catalogo where sku = 'PA310TCNXXL00503'), 6),"..
"(4513, (select id from catalogo where sku = 'PA310TRM00109'), 2),"..
"(4514, (select id from catalogo where sku = 'PA310TRM00109'), 3),"..
"(4515, (select id from catalogo where sku = 'PA310TRM00109'), 4),"..
"(4516, (select id from catalogo where sku = 'PA310TRM00109'), 5),"..
"(4517, (select id from catalogo where sku = 'PA310TRM00216'), 2),"..
"(4518, (select id from catalogo where sku = 'PA310TRM00216'), 3),"..
"(4519, (select id from catalogo where sku = 'PA310TRM00216'), 4),"..
"(4520, (select id from catalogo where sku = 'PA310TRM00216'), 5),"..
"(4521, (select id from catalogo where sku = 'PA310TRM00311'), 2),"..
"(4522, (select id from catalogo where sku = 'PA310TRM00311'), 3),"..
"(4523, (select id from catalogo where sku = 'PA310TRM00311'), 4),"..
"(4524, (select id from catalogo where sku = 'PA310TRM00311'), 5),"..
"(4525, (select id from catalogo where sku = 'PA310TRM00413'), 2),"..
"(4526, (select id from catalogo where sku = 'PA310TRM00413'), 3),"..
"(4527, (select id from catalogo where sku = 'PA310TRM00413'), 4),"..
"(4528, (select id from catalogo where sku = 'PA310TRM00413'), 5),"..
"(4529, (select id from catalogo where sku = 'PA310TRM00503'), 2),"..
"(4530, (select id from catalogo where sku = 'PA310TRM00503'), 3),"..
"(4531, (select id from catalogo where sku = 'PA310TRM00503'), 4),"..
"(4532, (select id from catalogo where sku = 'PA310TRM00503'), 5),"..
"(4533, (select id from catalogo where sku = 'PA310TRMXXL00109'), 6),"..
"(4534, (select id from catalogo where sku = 'PA310TRMXXL00216'), 6),"..
"(4535, (select id from catalogo where sku = 'PA310TRMXXL00311'), 6),"..
"(4536, (select id from catalogo where sku = 'PA310TRMXXL00413'), 6),"..
"(4537, (select id from catalogo where sku = 'PA310TRMXXL00503'), 6),"..
"(4538, (select id from catalogo where sku = 'PB165TRM0104'), 2),"..
"(4539, (select id from catalogo where sku = 'PB165TRM0104'), 3),"..
"(4540, (select id from catalogo where sku = 'PB165TRM0104'), 4),"..
"(4541, (select id from catalogo where sku = 'PB165TRM0104'), 5),"..
"(4542, (select id from catalogo where sku = 'PB165TRM0118'), 2),"..
"(4543, (select id from catalogo where sku = 'PB165TRM0118'), 3);"
db:exec( query2 )
--fase 31
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4544, (select id from catalogo where sku = 'PB165TRM0118'), 4),"..
"(4545, (select id from catalogo where sku = 'PB165TRM0118'), 5),"..
"(4546, (select id from catalogo where sku = 'PB165TRM0129'), 2),"..
"(4547, (select id from catalogo where sku = 'PB165TRM0129'), 3),"..
"(4548, (select id from catalogo where sku = 'PB165TRM0129'), 4),"..
"(4549, (select id from catalogo where sku = 'PB165TRM0129'), 5),"..
"(4550, (select id from catalogo where sku = 'PD250TCN001U'), 2),"..
"(4551, (select id from catalogo where sku = 'PD250TCN001U'), 3),"..
"(4552, (select id from catalogo where sku = 'PD250TCN001U'), 4),"..
"(4553, (select id from catalogo where sku = 'PD250TCN001U'), 5),"..
"(4554, (select id from catalogo where sku = 'PD250TCN00212'), 2),"..
"(4555, (select id from catalogo where sku = 'PD250TCN00212'), 3),"..
"(4556, (select id from catalogo where sku = 'PD250TCN00212'), 4),"..
"(4557, (select id from catalogo where sku = 'PD250TCN00212'), 5),"..
"(4558, (select id from catalogo where sku = 'PD250TCN00374'), 2),"..
"(4559, (select id from catalogo where sku = 'PD250TCN00374'), 3),"..
"(4560, (select id from catalogo where sku = 'PD250TCN00374'), 4),"..
"(4561, (select id from catalogo where sku = 'PD250TCN00374'), 5),"..
"(4562, (select id from catalogo where sku = 'PD250TCN00415'), 2),"..
"(4563, (select id from catalogo where sku = 'PD250TCN00415'), 3),"..
"(4564, (select id from catalogo where sku = 'PD250TCN00415'), 4),"..
"(4565, (select id from catalogo where sku = 'PD250TCN00415'), 5),"..
"(4566, (select id from catalogo where sku = 'PD250TCN00513'), 2),"..
"(4567, (select id from catalogo where sku = 'PD250TCN00513'), 3),"..
"(4568, (select id from catalogo where sku = 'PD250TCN00513'), 4),"..
"(4569, (select id from catalogo where sku = 'PD250TCN00513'), 5),"..
"(4570, (select id from catalogo where sku = 'PD250TRM001U'), 2),"..
"(4571, (select id from catalogo where sku = 'PD250TRM001U'), 3),"..
"(4572, (select id from catalogo where sku = 'PD250TRM001U'), 4),"..
"(4573, (select id from catalogo where sku = 'PD250TRM001U'), 5),"..
"(4574, (select id from catalogo where sku = 'PD250TRM00212'), 2),"..
"(4575, (select id from catalogo where sku = 'PD250TRM00212'), 3),"..
"(4576, (select id from catalogo where sku = 'PD250TRM00212'), 4),"..
"(4577, (select id from catalogo where sku = 'PD250TRM00212'), 5),"..
"(4578, (select id from catalogo where sku = 'PD250TRM00374'), 2),"..
"(4579, (select id from catalogo where sku = 'PD250TRM00374'), 3),"..
"(4580, (select id from catalogo where sku = 'PD250TRM00374'), 4),"..
"(4581, (select id from catalogo where sku = 'PD250TRM00374'), 5),"..
"(4582, (select id from catalogo where sku = 'PD250TRM00415'), 2),"..
"(4583, (select id from catalogo where sku = 'PD250TRM00415'), 3),"..
"(4584, (select id from catalogo where sku = 'PD250TRM00415'), 4),"..
"(4585, (select id from catalogo where sku = 'PD250TRM00415'), 5),"..
"(4586, (select id from catalogo where sku = 'PD250TRM00513'), 2),"..
"(4587, (select id from catalogo where sku = 'PD250TRM00513'), 3),"..
"(4588, (select id from catalogo where sku = 'PD250TRM00513'), 4),"..
"(4589, (select id from catalogo where sku = 'PD250TRM00513'), 5),"..
"(4590, (select id from catalogo where sku = 'PD300TCN00111'), 2),"..
"(4591, (select id from catalogo where sku = 'PD300TCN00111'), 3),"..
"(4592, (select id from catalogo where sku = 'PD300TCN00111'), 4),"..
"(4593, (select id from catalogo where sku = 'PD300TCN00111'), 5),"..
"(4594, (select id from catalogo where sku = 'PD300TCN00117'), 2),"..
"(4595, (select id from catalogo where sku = 'PD300TCN00117'), 3),"..
"(4596, (select id from catalogo where sku = 'PD300TCN00117'), 4),"..
"(4597, (select id from catalogo where sku = 'PD300TCN00117'), 5),"..
"(4598, (select id from catalogo where sku = 'PD300TCN00171'), 2),"..
"(4599, (select id from catalogo where sku = 'PD300TCN00171'), 3),"..
"(4600, (select id from catalogo where sku = 'PD300TCN00171'), 4),"..
"(4601, (select id from catalogo where sku = 'PD300TCN00171'), 5),"..
"(4602, (select id from catalogo where sku = 'PD300TCN00211'), 2),"..
"(4603, (select id from catalogo where sku = 'PD300TCN00211'), 3),"..
"(4604, (select id from catalogo where sku = 'PD300TCN00211'), 4),"..
"(4605, (select id from catalogo where sku = 'PD300TCN00211'), 5),"..
"(4606, (select id from catalogo where sku = 'PD300TCN00311'), 2),"..
"(4607, (select id from catalogo where sku = 'PD300TCN00311'), 3),"..
"(4608, (select id from catalogo where sku = 'PD300TCN00311'), 4),"..
"(4609, (select id from catalogo where sku = 'PD300TCN00311'), 5),"..
"(4610, (select id from catalogo where sku = 'PD300TCN00403'), 2),"..
"(4611, (select id from catalogo where sku = 'PD300TCN00403'), 3),"..
"(4612, (select id from catalogo where sku = 'PD300TCN00403'), 4),"..
"(4613, (select id from catalogo where sku = 'PD300TCN00403'), 5),"..
"(4614, (select id from catalogo where sku = 'PD300TCN00471'), 2),"..
"(4615, (select id from catalogo where sku = 'PD300TCN00471'), 3),"..
"(4616, (select id from catalogo where sku = 'PD300TCN00471'), 4),"..
"(4617, (select id from catalogo where sku = 'PD300TCN00471'), 5),"..
"(4618, (select id from catalogo where sku = 'PD300TCN00513'), 2),"..
"(4619, (select id from catalogo where sku = 'PD300TCN00513'), 3),"..
"(4620, (select id from catalogo where sku = 'PD300TCN00513'), 4),"..
"(4621, (select id from catalogo where sku = 'PD300TCN00513'), 5),"..
"(4622, (select id from catalogo where sku = 'PD300TCN00613'), 2),"..
"(4623, (select id from catalogo where sku = 'PD300TCN00613'), 3),"..
"(4624, (select id from catalogo where sku = 'PD300TCN00613'), 4),"..
"(4625, (select id from catalogo where sku = 'PD300TCN00613'), 5),"..
"(4626, (select id from catalogo where sku = 'PD300TCN00617'), 2),"..
"(4627, (select id from catalogo where sku = 'PD300TCN00617'), 3),"..
"(4628, (select id from catalogo where sku = 'PD300TCN00617'), 4),"..
"(4629, (select id from catalogo where sku = 'PD300TCN00617'), 5),"..
"(4630, (select id from catalogo where sku = 'PD300TCN00771'), 2),"..
"(4631, (select id from catalogo where sku = 'PD300TCN00771'), 3),"..
"(4632, (select id from catalogo where sku = 'PD300TCN00771'), 4),"..
"(4633, (select id from catalogo where sku = 'PD300TCN00771'), 5),"..
"(4634, (select id from catalogo where sku = 'PD300TCN00875'), 2),"..
"(4635, (select id from catalogo where sku = 'PD300TCN00875'), 3),"..
"(4636, (select id from catalogo where sku = 'PD300TCN00875'), 4),"..
"(4637, (select id from catalogo where sku = 'PD300TCN00875'), 5),"..
"(4638, (select id from catalogo where sku = 'PD300TCN00903'), 2),"..
"(4639, (select id from catalogo where sku = 'PD300TCN00903'), 3),"..
"(4640, (select id from catalogo where sku = 'PD300TCN00903'), 4),"..
"(4641, (select id from catalogo where sku = 'PD300TCN00903'), 5),"..
"(4642, (select id from catalogo where sku = 'PD300TCN00911'), 2),"..
"(4643, (select id from catalogo where sku = 'PD300TCN00911'), 3),"..
"(4644, (select id from catalogo where sku = 'PD300TCN00911'), 4),"..
"(4645, (select id from catalogo where sku = 'PD300TCN00911'), 5),"..
"(4646, (select id from catalogo where sku = 'PD300TCN01013'), 2),"..
"(4647, (select id from catalogo where sku = 'PD300TCN01013'), 3),"..
"(4648, (select id from catalogo where sku = 'PD300TCN01013'), 4),"..
"(4649, (select id from catalogo where sku = 'PD300TCN01013'), 5),"..
"(4650, (select id from catalogo where sku = 'PD300TCN01018'), 2),"..
"(4651, (select id from catalogo where sku = 'PD300TCN01018'), 3),"..
"(4652, (select id from catalogo where sku = 'PD300TCN01018'), 4),"..
"(4653, (select id from catalogo where sku = 'PD300TCN01018'), 5),"..
"(4654, (select id from catalogo where sku = 'PD300TCN01071'), 2),"..
"(4655, (select id from catalogo where sku = 'PD300TCN01071'), 3),"..
"(4656, (select id from catalogo where sku = 'PD300TCN01071'), 4),"..
"(4657, (select id from catalogo where sku = 'PD300TCN01071'), 5),"..
"(4658, (select id from catalogo where sku = 'PD300TCN01111'), 2),"..
"(4659, (select id from catalogo where sku = 'PD300TCN01111'), 3),"..
"(4660, (select id from catalogo where sku = 'PD300TCN01111'), 4),"..
"(4661, (select id from catalogo where sku = 'PD300TCN01111'), 5),"..
"(4662, (select id from catalogo where sku = 'PD300TCN01113'), 2),"..
"(4663, (select id from catalogo where sku = 'PD300TCN01113'), 3),"..
"(4664, (select id from catalogo where sku = 'PD300TCN01113'), 4),"..
"(4665, (select id from catalogo where sku = 'PD300TCN01113'), 5),"..
"(4666, (select id from catalogo where sku = 'PD300TCN01171'), 2),"..
"(4667, (select id from catalogo where sku = 'PD300TCN01171'), 3),"..
"(4668, (select id from catalogo where sku = 'PD300TCN01171'), 4),"..
"(4669, (select id from catalogo where sku = 'PD300TCN01171'), 5),"..
"(4670, (select id from catalogo where sku = 'PD300TCN01229'), 2),"..
"(4671, (select id from catalogo where sku = 'PD300TCN01229'), 3),"..
"(4672, (select id from catalogo where sku = 'PD300TCN01229'), 4),"..
"(4673, (select id from catalogo where sku = 'PD300TCN01229'), 5),"..
"(4674, (select id from catalogo where sku = 'PD300TCN01318'), 2),"..
"(4675, (select id from catalogo where sku = 'PD300TCN01318'), 3),"..
"(4676, (select id from catalogo where sku = 'PD300TCN01318'), 4),"..
"(4677, (select id from catalogo where sku = 'PD300TCN01318'), 5),"..
"(4678, (select id from catalogo where sku = 'PD300TCN01329'), 2),"..
"(4679, (select id from catalogo where sku = 'PD300TCN01329'), 3),"..
"(4680, (select id from catalogo where sku = 'PD300TCN01329'), 4),"..
"(4681, (select id from catalogo where sku = 'PD300TCN01329'), 5),"..
"(4682, (select id from catalogo where sku = 'PD300TCN01413'), 2),"..
"(4683, (select id from catalogo where sku = 'PD300TCN01413'), 3),"..
"(4684, (select id from catalogo where sku = 'PD300TCN01413'), 4),"..
"(4685, (select id from catalogo where sku = 'PD300TCN01413'), 5),"..
"(4686, (select id from catalogo where sku = 'PD300TCN01413-X'), 2),"..
"(4687, (select id from catalogo where sku = 'PD300TCN01413-X'), 3),"..
"(4688, (select id from catalogo where sku = 'PD300TCN01413-X'), 4),"..
"(4689, (select id from catalogo where sku = 'PD300TCN01413-X'), 5),"..
"(4690, (select id from catalogo where sku = 'PD300TCN01471'), 2),"..
"(4691, (select id from catalogo where sku = 'PD300TCN01471'), 3),"..
"(4692, (select id from catalogo where sku = 'PD300TCN01471'), 4),"..
"(4693, (select id from catalogo where sku = 'PD300TCN01471'), 5),"..
"(4694, (select id from catalogo where sku = 'PD300TCN01513'), 2);"
db:exec( query2 )
--fase 32
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4695, (select id from catalogo where sku = 'PD300TCN01513'), 3),"..
"(4696, (select id from catalogo where sku = 'PD300TCN01513'), 4),"..
"(4697, (select id from catalogo where sku = 'PD300TCN01513'), 5),"..
"(4698, (select id from catalogo where sku = 'PD300TCN01540'), 2),"..
"(4699, (select id from catalogo where sku = 'PD300TCN01540'), 3),"..
"(4700, (select id from catalogo where sku = 'PD300TCN01540'), 4),"..
"(4701, (select id from catalogo where sku = 'PD300TCN01540'), 5),"..
"(4702, (select id from catalogo where sku = 'PD300TCN01603'), 2),"..
"(4703, (select id from catalogo where sku = 'PD300TCN01603'), 3),"..
"(4704, (select id from catalogo where sku = 'PD300TCN01603'), 4),"..
"(4705, (select id from catalogo where sku = 'PD300TCN01603'), 5),"..
"(4706, (select id from catalogo where sku = 'PD300TCN01611'), 2),"..
"(4707, (select id from catalogo where sku = 'PD300TCN01611'), 3),"..
"(4708, (select id from catalogo where sku = 'PD300TCN01611'), 4),"..
"(4709, (select id from catalogo where sku = 'PD300TCN01611'), 5),"..
"(4710, (select id from catalogo where sku = 'PD300TCN01703'), 2),"..
"(4711, (select id from catalogo where sku = 'PD300TCN01703'), 3),"..
"(4712, (select id from catalogo where sku = 'PD300TCN01703'), 4),"..
"(4713, (select id from catalogo where sku = 'PD300TCN01703'), 5),"..
"(4714, (select id from catalogo where sku = 'PD300TCN01875'), 2),"..
"(4715, (select id from catalogo where sku = 'PD300TCN01875'), 3),"..
"(4716, (select id from catalogo where sku = 'PD300TCN01875'), 4),"..
"(4717, (select id from catalogo where sku = 'PD300TCN01875'), 5),"..
"(4718, (select id from catalogo where sku = 'PD300TCN01913'), 2),"..
"(4719, (select id from catalogo where sku = 'PD300TCN01913'), 3),"..
"(4720, (select id from catalogo where sku = 'PD300TCN01913'), 4),"..
"(4721, (select id from catalogo where sku = 'PD300TCN01913'), 5),"..
"(4722, (select id from catalogo where sku = 'PD300TCN02003'), 2),"..
"(4723, (select id from catalogo where sku = 'PD300TCN02003'), 3),"..
"(4724, (select id from catalogo where sku = 'PD300TCN02003'), 4),"..
"(4725, (select id from catalogo where sku = 'PD300TCN02003'), 5),"..
"(4726, (select id from catalogo where sku = 'PD300TCN02071'), 2),"..
"(4727, (select id from catalogo where sku = 'PD300TCN02071'), 3),"..
"(4728, (select id from catalogo where sku = 'PD300TCN02071'), 4),"..
"(4729, (select id from catalogo where sku = 'PD300TCN02071'), 5),"..
"(4730, (select id from catalogo where sku = 'PD300TCN02137'), 2),"..
"(4731, (select id from catalogo where sku = 'PD300TCN02137'), 3),"..
"(4732, (select id from catalogo where sku = 'PD300TCN02137'), 4),"..
"(4733, (select id from catalogo where sku = 'PD300TCN02137'), 5),"..
"(4734, (select id from catalogo where sku = 'PD300TCN02218'), 2),"..
"(4735, (select id from catalogo where sku = 'PD300TCN02218'), 3),"..
"(4736, (select id from catalogo where sku = 'PD300TCN02218'), 4),"..
"(4737, (select id from catalogo where sku = 'PD300TCN02218'), 5),"..
"(4738, (select id from catalogo where sku = 'PD300TCN02229'), 2),"..
"(4739, (select id from catalogo where sku = 'PD300TCN02229'), 3),"..
"(4740, (select id from catalogo where sku = 'PD300TCN02229'), 4),"..
"(4741, (select id from catalogo where sku = 'PD300TCN02229'), 5),"..
"(4742, (select id from catalogo where sku = 'PD300TCN02313'), 2),"..
"(4743, (select id from catalogo where sku = 'PD300TCN02313'), 3),"..
"(4744, (select id from catalogo where sku = 'PD300TCN02313'), 4),"..
"(4745, (select id from catalogo where sku = 'PD300TCN02313'), 5),"..
"(4746, (select id from catalogo where sku = 'PD300TCN02374'), 2),"..
"(4747, (select id from catalogo where sku = 'PD300TCN02374'), 3),"..
"(4748, (select id from catalogo where sku = 'PD300TCN02374'), 4),"..
"(4749, (select id from catalogo where sku = 'PD300TCN02374'), 5),"..
"(4750, (select id from catalogo where sku = 'PD300TCN02418'), 2),"..
"(4751, (select id from catalogo where sku = 'PD300TCN02418'), 3),"..
"(4752, (select id from catalogo where sku = 'PD300TCN02418'), 4),"..
"(4753, (select id from catalogo where sku = 'PD300TCN02418'), 5),"..
"(4754, (select id from catalogo where sku = 'PD300TCN02474'), 2),"..
"(4755, (select id from catalogo where sku = 'PD300TCN02474'), 3),"..
"(4756, (select id from catalogo where sku = 'PD300TCN02474'), 4),"..
"(4757, (select id from catalogo where sku = 'PD300TCN02474'), 5),"..
"(4758, (select id from catalogo where sku = 'PD300TCN02529'), 2),"..
"(4759, (select id from catalogo where sku = 'PD300TCN02529'), 3),"..
"(4760, (select id from catalogo where sku = 'PD300TCN02529'), 4),"..
"(4761, (select id from catalogo where sku = 'PD300TCN02529'), 5),"..
"(4762, (select id from catalogo where sku = 'PD300TRM00171'), 2),"..
"(4763, (select id from catalogo where sku = 'PD300TRM00171'), 3),"..
"(4764, (select id from catalogo where sku = 'PD300TRM00171'), 4),"..
"(4765, (select id from catalogo where sku = 'PD300TRM00171'), 5),"..
"(4766, (select id from catalogo where sku = 'PD300TRM00211'), 2),"..
"(4767, (select id from catalogo where sku = 'PD300TRM00211'), 3),"..
"(4768, (select id from catalogo where sku = 'PD300TRM00211'), 4),"..
"(4769, (select id from catalogo where sku = 'PD300TRM00211'), 5),"..
"(4770, (select id from catalogo where sku = 'PD300TRM00311'), 2),"..
"(4771, (select id from catalogo where sku = 'PD300TRM00311'), 3),"..
"(4772, (select id from catalogo where sku = 'PD300TRM00311'), 4),"..
"(4773, (select id from catalogo where sku = 'PD300TRM00311'), 5),"..
"(4774, (select id from catalogo where sku = 'PD300TRM00403'), 2),"..
"(4775, (select id from catalogo where sku = 'PD300TRM00403'), 3),"..
"(4776, (select id from catalogo where sku = 'PD300TRM00403'), 4),"..
"(4777, (select id from catalogo where sku = 'PD300TRM00403'), 5),"..
"(4778, (select id from catalogo where sku = 'PD300TRM00513'), 2),"..
"(4779, (select id from catalogo where sku = 'PD300TRM00513'), 3),"..
"(4780, (select id from catalogo where sku = 'PD300TRM00513'), 4),"..
"(4781, (select id from catalogo where sku = 'PD300TRM00513'), 5),"..
"(4782, (select id from catalogo where sku = 'PD300TRM00613'), 2),"..
"(4783, (select id from catalogo where sku = 'PD300TRM00613'), 3),"..
"(4784, (select id from catalogo where sku = 'PD300TRM00613'), 4),"..
"(4785, (select id from catalogo where sku = 'PD300TRM00613'), 5),"..
"(4786, (select id from catalogo where sku = 'PD300TRM00771'), 2),"..
"(4787, (select id from catalogo where sku = 'PD300TRM00771'), 3),"..
"(4788, (select id from catalogo where sku = 'PD300TRM00771'), 4),"..
"(4789, (select id from catalogo where sku = 'PD300TRM00771'), 5),"..
"(4790, (select id from catalogo where sku = 'PD300TRM00875'), 2),"..
"(4791, (select id from catalogo where sku = 'PD300TRM00875'), 3),"..
"(4792, (select id from catalogo where sku = 'PD300TRM00875'), 4),"..
"(4793, (select id from catalogo where sku = 'PD300TRM00875'), 5),"..
"(4794, (select id from catalogo where sku = 'PD300TRM00911'), 2),"..
"(4795, (select id from catalogo where sku = 'PD300TRM00911'), 3),"..
"(4796, (select id from catalogo where sku = 'PD300TRM00911'), 4),"..
"(4797, (select id from catalogo where sku = 'PD300TRM00911'), 5),"..
"(4798, (select id from catalogo where sku = 'PD300TRM01071'), 2),"..
"(4799, (select id from catalogo where sku = 'PD300TRM01071'), 3),"..
"(4800, (select id from catalogo where sku = 'PD300TRM01071'), 4),"..
"(4801, (select id from catalogo where sku = 'PD300TRM01071'), 5),"..
"(4802, (select id from catalogo where sku = 'PD300TRM01111'), 2),"..
"(4803, (select id from catalogo where sku = 'PD300TRM01111'), 3),"..
"(4804, (select id from catalogo where sku = 'PD300TRM01111'), 4),"..
"(4805, (select id from catalogo where sku = 'PD300TRM01111'), 5),"..
"(4806, (select id from catalogo where sku = 'PD300TRM01229'), 2),"..
"(4807, (select id from catalogo where sku = 'PD300TRM01229'), 3),"..
"(4808, (select id from catalogo where sku = 'PD300TRM01229'), 4),"..
"(4809, (select id from catalogo where sku = 'PD300TRM01229'), 5),"..
"(4810, (select id from catalogo where sku = 'PD300TRM01318'), 2),"..
"(4811, (select id from catalogo where sku = 'PD300TRM01318'), 3),"..
"(4812, (select id from catalogo where sku = 'PD300TRM01318'), 4),"..
"(4813, (select id from catalogo where sku = 'PD300TRM01318'), 5),"..
"(4814, (select id from catalogo where sku = 'PD300TRM01413'), 2),"..
"(4815, (select id from catalogo where sku = 'PD300TRM01413'), 3),"..
"(4816, (select id from catalogo where sku = 'PD300TRM01413'), 4),"..
"(4817, (select id from catalogo where sku = 'PD300TRM01413'), 5),"..
"(4818, (select id from catalogo where sku = 'PD300TRM01471'), 2),"..
"(4819, (select id from catalogo where sku = 'PD300TRM01471'), 3),"..
"(4820, (select id from catalogo where sku = 'PD300TRM01471'), 4),"..
"(4821, (select id from catalogo where sku = 'PD300TRM01471'), 5),"..
"(4822, (select id from catalogo where sku = 'PD300TRM01513'), 2),"..
"(4823, (select id from catalogo where sku = 'PD300TRM01513'), 3),"..
"(4824, (select id from catalogo where sku = 'PD300TRM01513'), 4),"..
"(4825, (select id from catalogo where sku = 'PD300TRM01513'), 5),"..
"(4826, (select id from catalogo where sku = 'PD300TRM01540'), 2),"..
"(4827, (select id from catalogo where sku = 'PD300TRM01540'), 3),"..
"(4828, (select id from catalogo where sku = 'PD300TRM01540'), 4),"..
"(4829, (select id from catalogo where sku = 'PD300TRM01540'), 5),"..
"(4830, (select id from catalogo where sku = 'PD300TRM01603'), 2),"..
"(4831, (select id from catalogo where sku = 'PD300TRM01603'), 3),"..
"(4832, (select id from catalogo where sku = 'PD300TRM01603'), 4),"..
"(4833, (select id from catalogo where sku = 'PD300TRM01603'), 5),"..
"(4834, (select id from catalogo where sku = 'PD300TRM01611'), 2),"..
"(4835, (select id from catalogo where sku = 'PD300TRM01611'), 3),"..
"(4836, (select id from catalogo where sku = 'PD300TRM01611'), 4),"..
"(4837, (select id from catalogo where sku = 'PD300TRM01611'), 5),"..
"(4838, (select id from catalogo where sku = 'PD300TRM01703'), 2),"..
"(4839, (select id from catalogo where sku = 'PD300TRM01703'), 3),"..
"(4840, (select id from catalogo where sku = 'PD300TRM01703'), 4),"..
"(4841, (select id from catalogo where sku = 'PD300TRM01703'), 5),"..
"(4842, (select id from catalogo where sku = 'PD300TRM01875'), 2),"..
"(4843, (select id from catalogo where sku = 'PD300TRM01875'), 3),"..
"(4844, (select id from catalogo where sku = 'PD300TRM01875'), 4),"..
"(4845, (select id from catalogo where sku = 'PD300TRM01875'), 5);"
db:exec( query2 )
--fase 33
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4846, (select id from catalogo where sku = 'PD300TRM01913'), 2),"..
"(4847, (select id from catalogo where sku = 'PD300TRM01913'), 3),"..
"(4848, (select id from catalogo where sku = 'PD300TRM01913'), 4),"..
"(4849, (select id from catalogo where sku = 'PD300TRM01913'), 5),"..
"(4850, (select id from catalogo where sku = 'PD300TRM02003'), 2),"..
"(4851, (select id from catalogo where sku = 'PD300TRM02003'), 3),"..
"(4852, (select id from catalogo where sku = 'PD300TRM02003'), 4),"..
"(4853, (select id from catalogo where sku = 'PD300TRM02003'), 5),"..
"(4854, (select id from catalogo where sku = 'PD300TRM02071'), 2),"..
"(4855, (select id from catalogo where sku = 'PD300TRM02071'), 3),"..
"(4856, (select id from catalogo where sku = 'PD300TRM02071'), 4),"..
"(4857, (select id from catalogo where sku = 'PD300TRM02071'), 5),"..
"(4858, (select id from catalogo where sku = 'PD300TRM02137'), 2),"..
"(4859, (select id from catalogo where sku = 'PD300TRM02137'), 3),"..
"(4860, (select id from catalogo where sku = 'PD300TRM02137'), 4),"..
"(4861, (select id from catalogo where sku = 'PD300TRM02137'), 5),"..
"(4862, (select id from catalogo where sku = 'PD300TRM02218'), 2),"..
"(4863, (select id from catalogo where sku = 'PD300TRM02218'), 3),"..
"(4864, (select id from catalogo where sku = 'PD300TRM02218'), 4),"..
"(4865, (select id from catalogo where sku = 'PD300TRM02218'), 5),"..
"(4866, (select id from catalogo where sku = 'PD300TRM02229'), 2),"..
"(4867, (select id from catalogo where sku = 'PD300TRM02229'), 3),"..
"(4868, (select id from catalogo where sku = 'PD300TRM02229'), 4),"..
"(4869, (select id from catalogo where sku = 'PD300TRM02229'), 5),"..
"(4870, (select id from catalogo where sku = 'PD300TRM02313'), 2),"..
"(4871, (select id from catalogo where sku = 'PD300TRM02313'), 3),"..
"(4872, (select id from catalogo where sku = 'PD300TRM02313'), 4),"..
"(4873, (select id from catalogo where sku = 'PD300TRM02313'), 5),"..
"(4874, (select id from catalogo where sku = 'PD300TRM02374'), 2),"..
"(4875, (select id from catalogo where sku = 'PD300TRM02374'), 3),"..
"(4876, (select id from catalogo where sku = 'PD300TRM02374'), 4),"..
"(4877, (select id from catalogo where sku = 'PD300TRM02374'), 5),"..
"(4878, (select id from catalogo where sku = 'PD300TRM02418'), 2),"..
"(4879, (select id from catalogo where sku = 'PD300TRM02418'), 3),"..
"(4880, (select id from catalogo where sku = 'PD300TRM02418'), 4),"..
"(4881, (select id from catalogo where sku = 'PD300TRM02418'), 5),"..
"(4882, (select id from catalogo where sku = 'PD300TRM02474'), 2),"..
"(4883, (select id from catalogo where sku = 'PD300TRM02474'), 3),"..
"(4884, (select id from catalogo where sku = 'PD300TRM02474'), 4),"..
"(4885, (select id from catalogo where sku = 'PD300TRM02474'), 5),"..
"(4886, (select id from catalogo where sku = 'PD300TRM02529'), 2),"..
"(4887, (select id from catalogo where sku = 'PD300TRM02529'), 3),"..
"(4888, (select id from catalogo where sku = 'PD300TRM02529'), 4),"..
"(4889, (select id from catalogo where sku = 'PD300TRM02529'), 5),"..
"(4890, (select id from catalogo where sku = 'PDJ300TCN00111'), 2),"..
"(4891, (select id from catalogo where sku = 'PDJ300TCN00111'), 3),"..
"(4892, (select id from catalogo where sku = 'PDJ300TCN00111'), 4),"..
"(4893, (select id from catalogo where sku = 'PDJ300TCN00111'), 5),"..
"(4894, (select id from catalogo where sku = 'PDJ300TCN00117'), 2),"..
"(4895, (select id from catalogo where sku = 'PDJ300TCN00117'), 3),"..
"(4896, (select id from catalogo where sku = 'PDJ300TCN00117'), 4),"..
"(4897, (select id from catalogo where sku = 'PDJ300TCN00117'), 5),"..
"(4898, (select id from catalogo where sku = 'PDJ300TCN00171'), 2),"..
"(4899, (select id from catalogo where sku = 'PDJ300TCN00171'), 3),"..
"(4900, (select id from catalogo where sku = 'PDJ300TCN00171'), 4),"..
"(4901, (select id from catalogo where sku = 'PDJ300TCN00171'), 5),"..
"(4902, (select id from catalogo where sku = 'PDJ300TCN00211'), 2),"..
"(4903, (select id from catalogo where sku = 'PDJ300TCN00211'), 3),"..
"(4904, (select id from catalogo where sku = 'PDJ300TCN00211'), 4),"..
"(4905, (select id from catalogo where sku = 'PDJ300TCN00211'), 5),"..
"(4906, (select id from catalogo where sku = 'PDJ300TCN00311'), 2),"..
"(4907, (select id from catalogo where sku = 'PDJ300TCN00311'), 3),"..
"(4908, (select id from catalogo where sku = 'PDJ300TCN00311'), 4),"..
"(4909, (select id from catalogo where sku = 'PDJ300TCN00311'), 5),"..
"(4910, (select id from catalogo where sku = 'PDJ300TCN00374'), 2),"..
"(4911, (select id from catalogo where sku = 'PDJ300TCN00374'), 3),"..
"(4912, (select id from catalogo where sku = 'PDJ300TCN00374'), 4),"..
"(4913, (select id from catalogo where sku = 'PDJ300TCN00374'), 5),"..
"(4914, (select id from catalogo where sku = 'PDJ300TCN00403'), 2),"..
"(4915, (select id from catalogo where sku = 'PDJ300TCN00403'), 3),"..
"(4916, (select id from catalogo where sku = 'PDJ300TCN00403'), 4),"..
"(4917, (select id from catalogo where sku = 'PDJ300TCN00403'), 5),"..
"(4918, (select id from catalogo where sku = 'PDJ300TCN00471'), 2),"..
"(4919, (select id from catalogo where sku = 'PDJ300TCN00471'), 3),"..
"(4920, (select id from catalogo where sku = 'PDJ300TCN00471'), 4),"..
"(4921, (select id from catalogo where sku = 'PDJ300TCN00471'), 5),"..
"(4922, (select id from catalogo where sku = 'PDJ300TCN00513'), 2),"..
"(4923, (select id from catalogo where sku = 'PDJ300TCN00513'), 3),"..
"(4924, (select id from catalogo where sku = 'PDJ300TCN00513'), 4),"..
"(4925, (select id from catalogo where sku = 'PDJ300TCN00513'), 5),"..
"(4926, (select id from catalogo where sku = 'PDJ300TCN00613'), 2),"..
"(4927, (select id from catalogo where sku = 'PDJ300TCN00613'), 3),"..
"(4928, (select id from catalogo where sku = 'PDJ300TCN00613'), 4),"..
"(4929, (select id from catalogo where sku = 'PDJ300TCN00613'), 5),"..
"(4930, (select id from catalogo where sku = 'PDJ300TCN00617'), 2),"..
"(4931, (select id from catalogo where sku = 'PDJ300TCN00617'), 3),"..
"(4932, (select id from catalogo where sku = 'PDJ300TCN00617'), 4),"..
"(4933, (select id from catalogo where sku = 'PDJ300TCN00617'), 5),"..
"(4934, (select id from catalogo where sku = 'PDJ300TCN00771'), 2),"..
"(4935, (select id from catalogo where sku = 'PDJ300TCN00771'), 3),"..
"(4936, (select id from catalogo where sku = 'PDJ300TCN00771'), 4),"..
"(4937, (select id from catalogo where sku = 'PDJ300TCN00771'), 5),"..
"(4938, (select id from catalogo where sku = 'PDJ300TCN00874'), 2),"..
"(4939, (select id from catalogo where sku = 'PDJ300TCN00874'), 3),"..
"(4940, (select id from catalogo where sku = 'PDJ300TCN00874'), 4),"..
"(4941, (select id from catalogo where sku = 'PDJ300TCN00874'), 5),"..
"(4942, (select id from catalogo where sku = 'PDJ300TCN00903'), 2),"..
"(4943, (select id from catalogo where sku = 'PDJ300TCN00903'), 3),"..
"(4944, (select id from catalogo where sku = 'PDJ300TCN00903'), 4),"..
"(4945, (select id from catalogo where sku = 'PDJ300TCN00903'), 5),"..
"(4946, (select id from catalogo where sku = 'PDJ300TCN00911'), 2),"..
"(4947, (select id from catalogo where sku = 'PDJ300TCN00911'), 3),"..
"(4948, (select id from catalogo where sku = 'PDJ300TCN00911'), 4),"..
"(4949, (select id from catalogo where sku = 'PDJ300TCN00911'), 5),"..
"(4950, (select id from catalogo where sku = 'PDJ300TCN01013'), 2),"..
"(4951, (select id from catalogo where sku = 'PDJ300TCN01013'), 3),"..
"(4952, (select id from catalogo where sku = 'PDJ300TCN01013'), 4),"..
"(4953, (select id from catalogo where sku = 'PDJ300TCN01013'), 5),"..
"(4954, (select id from catalogo where sku = 'PDJ300TCN01018'), 2),"..
"(4955, (select id from catalogo where sku = 'PDJ300TCN01018'), 3),"..
"(4956, (select id from catalogo where sku = 'PDJ300TCN01018'), 4),"..
"(4957, (select id from catalogo where sku = 'PDJ300TCN01018'), 5),"..
"(4958, (select id from catalogo where sku = 'PDJ300TCN01071'), 2),"..
"(4959, (select id from catalogo where sku = 'PDJ300TCN01071'), 3),"..
"(4960, (select id from catalogo where sku = 'PDJ300TCN01071'), 4),"..
"(4961, (select id from catalogo where sku = 'PDJ300TCN01071'), 5),"..
"(4962, (select id from catalogo where sku = 'PDJ300TCN01111'), 2),"..
"(4963, (select id from catalogo where sku = 'PDJ300TCN01111'), 3),"..
"(4964, (select id from catalogo where sku = 'PDJ300TCN01111'), 4),"..
"(4965, (select id from catalogo where sku = 'PDJ300TCN01111'), 5),"..
"(4966, (select id from catalogo where sku = 'PDJ300TCN01113'), 2),"..
"(4967, (select id from catalogo where sku = 'PDJ300TCN01113'), 3),"..
"(4968, (select id from catalogo where sku = 'PDJ300TCN01113'), 4),"..
"(4969, (select id from catalogo where sku = 'PDJ300TCN01113'), 5),"..
"(4970, (select id from catalogo where sku = 'PDJ300TCN01171'), 2),"..
"(4971, (select id from catalogo where sku = 'PDJ300TCN01171'), 3),"..
"(4972, (select id from catalogo where sku = 'PDJ300TCN01171'), 4),"..
"(4973, (select id from catalogo where sku = 'PDJ300TCN01171'), 5),"..
"(4974, (select id from catalogo where sku = 'PDJ300TCN01229'), 2),"..
"(4975, (select id from catalogo where sku = 'PDJ300TCN01229'), 3),"..
"(4976, (select id from catalogo where sku = 'PDJ300TCN01229'), 4),"..
"(4977, (select id from catalogo where sku = 'PDJ300TCN01229'), 5),"..
"(4978, (select id from catalogo where sku = 'PDJ300TCN01318'), 2),"..
"(4979, (select id from catalogo where sku = 'PDJ300TCN01318'), 3),"..
"(4980, (select id from catalogo where sku = 'PDJ300TCN01318'), 4),"..
"(4981, (select id from catalogo where sku = 'PDJ300TCN01318'), 5),"..
"(4982, (select id from catalogo where sku = 'PDJ300TCN01329'), 2),"..
"(4983, (select id from catalogo where sku = 'PDJ300TCN01329'), 3),"..
"(4984, (select id from catalogo where sku = 'PDJ300TCN01329'), 4),"..
"(4985, (select id from catalogo where sku = 'PDJ300TCN01329'), 5),"..
"(4986, (select id from catalogo where sku = 'PDJ300TCN01413'), 2),"..
"(4987, (select id from catalogo where sku = 'PDJ300TCN01413'), 3),"..
"(4988, (select id from catalogo where sku = 'PDJ300TCN01413'), 4),"..
"(4989, (select id from catalogo where sku = 'PDJ300TCN01413'), 5),"..
"(4990, (select id from catalogo where sku = 'PDJ300TCN01413-X'), 2),"..
"(4991, (select id from catalogo where sku = 'PDJ300TCN01413-X'), 3),"..
"(4992, (select id from catalogo where sku = 'PDJ300TCN01413-X'), 4),"..
"(4993, (select id from catalogo where sku = 'PDJ300TCN01413-X'), 5),"..
"(4994, (select id from catalogo where sku = 'PDJ300TCN01471'), 2),"..
"(4995, (select id from catalogo where sku = 'PDJ300TCN01471'), 3),"..
"(4996, (select id from catalogo where sku = 'PDJ300TCN01471'), 4);"
db:exec( query2 )
--fase 34
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(4997, (select id from catalogo where sku = 'PDJ300TCN01471'), 5),"..
"(4998, (select id from catalogo where sku = 'PDJ300TCN01513'), 2),"..
"(4999, (select id from catalogo where sku = 'PDJ300TCN01513'), 3),"..
"(5000, (select id from catalogo where sku = 'PDJ300TCN01513'), 4),"..
"(5001, (select id from catalogo where sku = 'PDJ300TCN01513'), 5),"..
"(5002, (select id from catalogo where sku = 'PDJ300TCN01540'), 2),"..
"(5003, (select id from catalogo where sku = 'PDJ300TCN01540'), 3),"..
"(5004, (select id from catalogo where sku = 'PDJ300TCN01540'), 4),"..
"(5005, (select id from catalogo where sku = 'PDJ300TCN01540'), 5),"..
"(5006, (select id from catalogo where sku = 'PDJ300TCN01603'), 2),"..
"(5007, (select id from catalogo where sku = 'PDJ300TCN01603'), 3),"..
"(5008, (select id from catalogo where sku = 'PDJ300TCN01603'), 4),"..
"(5009, (select id from catalogo where sku = 'PDJ300TCN01603'), 5),"..
"(5010, (select id from catalogo where sku = 'PDJ300TCN01611'), 2),"..
"(5011, (select id from catalogo where sku = 'PDJ300TCN01611'), 3),"..
"(5012, (select id from catalogo where sku = 'PDJ300TCN01611'), 4),"..
"(5013, (select id from catalogo where sku = 'PDJ300TCN01611'), 5),"..
"(5014, (select id from catalogo where sku = 'PDJ300TCN01703'), 2),"..
"(5015, (select id from catalogo where sku = 'PDJ300TCN01703'), 3),"..
"(5016, (select id from catalogo where sku = 'PDJ300TCN01703'), 4),"..
"(5017, (select id from catalogo where sku = 'PDJ300TCN01703'), 5),"..
"(5018, (select id from catalogo where sku = 'PDJ300TCN01875'), 2),"..
"(5019, (select id from catalogo where sku = 'PDJ300TCN01875'), 3),"..
"(5020, (select id from catalogo where sku = 'PDJ300TCN01875'), 4),"..
"(5021, (select id from catalogo where sku = 'PDJ300TCN01875'), 5),"..
"(5022, (select id from catalogo where sku = 'PDJ300TCN01913'), 2),"..
"(5023, (select id from catalogo where sku = 'PDJ300TCN01913'), 3),"..
"(5024, (select id from catalogo where sku = 'PDJ300TCN01913'), 4),"..
"(5025, (select id from catalogo where sku = 'PDJ300TCN01913'), 5),"..
"(5026, (select id from catalogo where sku = 'PDJ300TCN02003'), 2),"..
"(5027, (select id from catalogo where sku = 'PDJ300TCN02003'), 3),"..
"(5028, (select id from catalogo where sku = 'PDJ300TCN02003'), 4),"..
"(5029, (select id from catalogo where sku = 'PDJ300TCN02003'), 5),"..
"(5030, (select id from catalogo where sku = 'PDJ300TCN02071'), 2),"..
"(5031, (select id from catalogo where sku = 'PDJ300TCN02071'), 3),"..
"(5032, (select id from catalogo where sku = 'PDJ300TCN02071'), 4),"..
"(5033, (select id from catalogo where sku = 'PDJ300TCN02071'), 5),"..
"(5034, (select id from catalogo where sku = 'PDJ300TCN02137'), 2),"..
"(5035, (select id from catalogo where sku = 'PDJ300TCN02137'), 3),"..
"(5036, (select id from catalogo where sku = 'PDJ300TCN02137'), 4),"..
"(5037, (select id from catalogo where sku = 'PDJ300TCN02137'), 5),"..
"(5038, (select id from catalogo where sku = 'PDJ300TCN02218'), 2),"..
"(5039, (select id from catalogo where sku = 'PDJ300TCN02218'), 3),"..
"(5040, (select id from catalogo where sku = 'PDJ300TCN02218'), 4),"..
"(5041, (select id from catalogo where sku = 'PDJ300TCN02218'), 5),"..
"(5042, (select id from catalogo where sku = 'PDJ300TCN02229'), 2),"..
"(5043, (select id from catalogo where sku = 'PDJ300TCN02229'), 3),"..
"(5044, (select id from catalogo where sku = 'PDJ300TCN02229'), 4),"..
"(5045, (select id from catalogo where sku = 'PDJ300TCN02229'), 5),"..
"(5046, (select id from catalogo where sku = 'PDJ300TCN02313'), 2),"..
"(5047, (select id from catalogo where sku = 'PDJ300TCN02313'), 3),"..
"(5048, (select id from catalogo where sku = 'PDJ300TCN02313'), 4),"..
"(5049, (select id from catalogo where sku = 'PDJ300TCN02313'), 5),"..
"(5050, (select id from catalogo where sku = 'PDJ300TCN02374'), 2),"..
"(5051, (select id from catalogo where sku = 'PDJ300TCN02374'), 3),"..
"(5052, (select id from catalogo where sku = 'PDJ300TCN02374'), 4),"..
"(5053, (select id from catalogo where sku = 'PDJ300TCN02374'), 5),"..
"(5054, (select id from catalogo where sku = 'PDJ300TCN02418'), 2),"..
"(5055, (select id from catalogo where sku = 'PDJ300TCN02418'), 3),"..
"(5056, (select id from catalogo where sku = 'PDJ300TCN02418'), 4),"..
"(5057, (select id from catalogo where sku = 'PDJ300TCN02418'), 5),"..
"(5058, (select id from catalogo where sku = 'PDJ300TCN02474'), 2),"..
"(5059, (select id from catalogo where sku = 'PDJ300TCN02474'), 3),"..
"(5060, (select id from catalogo where sku = 'PDJ300TCN02474'), 4),"..
"(5061, (select id from catalogo where sku = 'PDJ300TCN02474'), 5),"..
"(5062, (select id from catalogo where sku = 'PDJ300TCN02529'), 2),"..
"(5063, (select id from catalogo where sku = 'PDJ300TCN02529'), 3),"..
"(5064, (select id from catalogo where sku = 'PDJ300TCN02529'), 4),"..
"(5065, (select id from catalogo where sku = 'PDJ300TCN02529'), 5),"..
"(5066, (select id from catalogo where sku = 'PDJ300TRM00171'), 2),"..
"(5067, (select id from catalogo where sku = 'PDJ300TRM00171'), 3),"..
"(5068, (select id from catalogo where sku = 'PDJ300TRM00171'), 4),"..
"(5069, (select id from catalogo where sku = 'PDJ300TRM00171'), 5),"..
"(5070, (select id from catalogo where sku = 'PDJ300TRM00211'), 2),"..
"(5071, (select id from catalogo where sku = 'PDJ300TRM00211'), 3),"..
"(5072, (select id from catalogo where sku = 'PDJ300TRM00211'), 4),"..
"(5073, (select id from catalogo where sku = 'PDJ300TRM00211'), 5),"..
"(5074, (select id from catalogo where sku = 'PDJ300TRM00311'), 2),"..
"(5075, (select id from catalogo where sku = 'PDJ300TRM00311'), 3),"..
"(5076, (select id from catalogo where sku = 'PDJ300TRM00311'), 4),"..
"(5077, (select id from catalogo where sku = 'PDJ300TRM00311'), 5),"..
"(5078, (select id from catalogo where sku = 'PDJ300TRM00403'), 2),"..
"(5079, (select id from catalogo where sku = 'PDJ300TRM00403'), 3),"..
"(5080, (select id from catalogo where sku = 'PDJ300TRM00403'), 4),"..
"(5081, (select id from catalogo where sku = 'PDJ300TRM00403'), 5),"..
"(5082, (select id from catalogo where sku = 'PDJ300TRM00513'), 2),"..
"(5083, (select id from catalogo where sku = 'PDJ300TRM00513'), 3),"..
"(5084, (select id from catalogo where sku = 'PDJ300TRM00513'), 4),"..
"(5085, (select id from catalogo where sku = 'PDJ300TRM00513'), 5),"..
"(5086, (select id from catalogo where sku = 'PDJ300TRM00613'), 2),"..
"(5087, (select id from catalogo where sku = 'PDJ300TRM00613'), 3),"..
"(5088, (select id from catalogo where sku = 'PDJ300TRM00613'), 4),"..
"(5089, (select id from catalogo where sku = 'PDJ300TRM00613'), 5),"..
"(5090, (select id from catalogo where sku = 'PDJ300TRM00771'), 2),"..
"(5091, (select id from catalogo where sku = 'PDJ300TRM00771'), 3),"..
"(5092, (select id from catalogo where sku = 'PDJ300TRM00771'), 4),"..
"(5093, (select id from catalogo where sku = 'PDJ300TRM00771'), 5),"..
"(5094, (select id from catalogo where sku = 'PDJ300TRM00875'), 2),"..
"(5095, (select id from catalogo where sku = 'PDJ300TRM00875'), 3),"..
"(5096, (select id from catalogo where sku = 'PDJ300TRM00875'), 4),"..
"(5097, (select id from catalogo where sku = 'PDJ300TRM00875'), 5),"..
"(5098, (select id from catalogo where sku = 'PDJ300TRM00911'), 2),"..
"(5099, (select id from catalogo where sku = 'PDJ300TRM00911'), 3),"..
"(5100, (select id from catalogo where sku = 'PDJ300TRM00911'), 4),"..
"(5101, (select id from catalogo where sku = 'PDJ300TRM00911'), 5),"..
"(5102, (select id from catalogo where sku = 'PDJ300TRM01071'), 2),"..
"(5103, (select id from catalogo where sku = 'PDJ300TRM01071'), 3),"..
"(5104, (select id from catalogo where sku = 'PDJ300TRM01071'), 4),"..
"(5105, (select id from catalogo where sku = 'PDJ300TRM01071'), 5),"..
"(5106, (select id from catalogo where sku = 'PDJ300TRM01111'), 2),"..
"(5107, (select id from catalogo where sku = 'PDJ300TRM01111'), 3),"..
"(5108, (select id from catalogo where sku = 'PDJ300TRM01111'), 4),"..
"(5109, (select id from catalogo where sku = 'PDJ300TRM01111'), 5),"..
"(5110, (select id from catalogo where sku = 'PDJ300TRM01229'), 2),"..
"(5111, (select id from catalogo where sku = 'PDJ300TRM01229'), 3),"..
"(5112, (select id from catalogo where sku = 'PDJ300TRM01229'), 4),"..
"(5113, (select id from catalogo where sku = 'PDJ300TRM01229'), 5),"..
"(5114, (select id from catalogo where sku = 'PDJ300TRM01318'), 2),"..
"(5115, (select id from catalogo where sku = 'PDJ300TRM01318'), 3),"..
"(5116, (select id from catalogo where sku = 'PDJ300TRM01318'), 4),"..
"(5117, (select id from catalogo where sku = 'PDJ300TRM01318'), 5),"..
"(5118, (select id from catalogo where sku = 'PDJ300TRM01413'), 2),"..
"(5119, (select id from catalogo where sku = 'PDJ300TRM01413'), 3),"..
"(5120, (select id from catalogo where sku = 'PDJ300TRM01413'), 4),"..
"(5121, (select id from catalogo where sku = 'PDJ300TRM01413'), 5),"..
"(5122, (select id from catalogo where sku = 'PDJ300TRM01471'), 2),"..
"(5123, (select id from catalogo where sku = 'PDJ300TRM01471'), 3),"..
"(5124, (select id from catalogo where sku = 'PDJ300TRM01471'), 4),"..
"(5125, (select id from catalogo where sku = 'PDJ300TRM01471'), 5),"..
"(5126, (select id from catalogo where sku = 'PDJ300TRM01513'), 2),"..
"(5127, (select id from catalogo where sku = 'PDJ300TRM01513'), 3),"..
"(5128, (select id from catalogo where sku = 'PDJ300TRM01513'), 4),"..
"(5129, (select id from catalogo where sku = 'PDJ300TRM01513'), 5),"..
"(5130, (select id from catalogo where sku = 'PDJ300TRM01540'), 2),"..
"(5131, (select id from catalogo where sku = 'PDJ300TRM01540'), 3),"..
"(5132, (select id from catalogo where sku = 'PDJ300TRM01540'), 4),"..
"(5133, (select id from catalogo where sku = 'PDJ300TRM01540'), 5),"..
"(5134, (select id from catalogo where sku = 'PDJ300TRM01603'), 2),"..
"(5135, (select id from catalogo where sku = 'PDJ300TRM01603'), 3),"..
"(5136, (select id from catalogo where sku = 'PDJ300TRM01603'), 4),"..
"(5137, (select id from catalogo where sku = 'PDJ300TRM01603'), 5),"..
"(5138, (select id from catalogo where sku = 'PDJ300TRM01611'), 2),"..
"(5139, (select id from catalogo where sku = 'PDJ300TRM01611'), 3),"..
"(5140, (select id from catalogo where sku = 'PDJ300TRM01611'), 4),"..
"(5141, (select id from catalogo where sku = 'PDJ300TRM01611'), 5),"..
"(5142, (select id from catalogo where sku = 'PDJ300TRM01703'), 2),"..
"(5143, (select id from catalogo where sku = 'PDJ300TRM01703'), 3),"..
"(5144, (select id from catalogo where sku = 'PDJ300TRM01703'), 4),"..
"(5145, (select id from catalogo where sku = 'PDJ300TRM01703'), 5),"..
"(5146, (select id from catalogo where sku = 'PDJ300TRM01875'), 2),"..
"(5147, (select id from catalogo where sku = 'PDJ300TRM01875'), 3);"
db:exec( query2 )
--fase 35
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(5148, (select id from catalogo where sku = 'PDJ300TRM01875'), 4),"..
"(5149, (select id from catalogo where sku = 'PDJ300TRM01875'), 5),"..
"(5150, (select id from catalogo where sku = 'PDJ300TRM01913'), 2),"..
"(5151, (select id from catalogo where sku = 'PDJ300TRM01913'), 3),"..
"(5152, (select id from catalogo where sku = 'PDJ300TRM01913'), 4),"..
"(5153, (select id from catalogo where sku = 'PDJ300TRM01913'), 5),"..
"(5154, (select id from catalogo where sku = 'PDJ300TRM02003'), 2),"..
"(5155, (select id from catalogo where sku = 'PDJ300TRM02003'), 3),"..
"(5156, (select id from catalogo where sku = 'PDJ300TRM02003'), 4),"..
"(5157, (select id from catalogo where sku = 'PDJ300TRM02003'), 5),"..
"(5158, (select id from catalogo where sku = 'PDJ300TRM02071'), 2),"..
"(5159, (select id from catalogo where sku = 'PDJ300TRM02071'), 3),"..
"(5160, (select id from catalogo where sku = 'PDJ300TRM02071'), 4),"..
"(5161, (select id from catalogo where sku = 'PDJ300TRM02071'), 5),"..
"(5162, (select id from catalogo where sku = 'PDJ300TRM02137'), 2),"..
"(5163, (select id from catalogo where sku = 'PDJ300TRM02137'), 3),"..
"(5164, (select id from catalogo where sku = 'PDJ300TRM02137'), 4),"..
"(5165, (select id from catalogo where sku = 'PDJ300TRM02137'), 5),"..
"(5166, (select id from catalogo where sku = 'PDJ300TRM02218'), 2),"..
"(5167, (select id from catalogo where sku = 'PDJ300TRM02218'), 3),"..
"(5168, (select id from catalogo where sku = 'PDJ300TRM02218'), 4),"..
"(5169, (select id from catalogo where sku = 'PDJ300TRM02218'), 5),"..
"(5170, (select id from catalogo where sku = 'PDJ300TRM02229'), 2),"..
"(5171, (select id from catalogo where sku = 'PDJ300TRM02229'), 3),"..
"(5172, (select id from catalogo where sku = 'PDJ300TRM02229'), 4),"..
"(5173, (select id from catalogo where sku = 'PDJ300TRM02229'), 5),"..
"(5174, (select id from catalogo where sku = 'PDJ300TRM02313'), 2),"..
"(5175, (select id from catalogo where sku = 'PDJ300TRM02313'), 3),"..
"(5176, (select id from catalogo where sku = 'PDJ300TRM02313'), 4),"..
"(5177, (select id from catalogo where sku = 'PDJ300TRM02313'), 5),"..
"(5178, (select id from catalogo where sku = 'PDJ300TRM02374'), 2),"..
"(5179, (select id from catalogo where sku = 'PDJ300TRM02374'), 3),"..
"(5180, (select id from catalogo where sku = 'PDJ300TRM02374'), 4),"..
"(5181, (select id from catalogo where sku = 'PDJ300TRM02374'), 5),"..
"(5182, (select id from catalogo where sku = 'PDJ300TRM02418'), 2),"..
"(5183, (select id from catalogo where sku = 'PDJ300TRM02418'), 3),"..
"(5184, (select id from catalogo where sku = 'PDJ300TRM02418'), 4),"..
"(5185, (select id from catalogo where sku = 'PDJ300TRM02418'), 5),"..
"(5186, (select id from catalogo where sku = 'PDJ300TRM02474'), 2),"..
"(5187, (select id from catalogo where sku = 'PDJ300TRM02474'), 3),"..
"(5188, (select id from catalogo where sku = 'PDJ300TRM02474'), 4),"..
"(5189, (select id from catalogo where sku = 'PDJ300TRM02474'), 5),"..
"(5190, (select id from catalogo where sku = 'PDJ300TRM02529'), 2),"..
"(5191, (select id from catalogo where sku = 'PDJ300TRM02529'), 3),"..
"(5192, (select id from catalogo where sku = 'PDJ300TRM02529'), 4),"..
"(5193, (select id from catalogo where sku = 'PDJ300TRM02529'), 5),"..
"(5194, (select id from catalogo where sku = 'PDTTTCN00103'), 2),"..
"(5195, (select id from catalogo where sku = 'PDTTTCN00103'), 3),"..
"(5196, (select id from catalogo where sku = 'PDTTTCN00103'), 4),"..
"(5197, (select id from catalogo where sku = 'PDTTTCN00103'), 5),"..
"(5198, (select id from catalogo where sku = 'PDTTTCN00103'), 6),"..
"(5199, (select id from catalogo where sku = 'PDTTTCN00113'), 2),"..
"(5200, (select id from catalogo where sku = 'PDTTTCN00113'), 3),"..
"(5201, (select id from catalogo where sku = 'PDTTTCN00113'), 4),"..
"(5202, (select id from catalogo where sku = 'PDTTTCN00113'), 5),"..
"(5203, (select id from catalogo where sku = 'PDTTTCN00113'), 6),"..
"(5204, (select id from catalogo where sku = 'PDTTTCN00117'), 2),"..
"(5205, (select id from catalogo where sku = 'PDTTTCN00117'), 3),"..
"(5206, (select id from catalogo where sku = 'PDTTTCN00117'), 4),"..
"(5207, (select id from catalogo where sku = 'PDTTTCN00117'), 5),"..
"(5208, (select id from catalogo where sku = 'PDTTTCN00117'), 6),"..
"(5209, (select id from catalogo where sku = 'PDTTTCN00118'), 2),"..
"(5210, (select id from catalogo where sku = 'PDTTTCN00118'), 3),"..
"(5211, (select id from catalogo where sku = 'PDTTTCN00118'), 4),"..
"(5212, (select id from catalogo where sku = 'PDTTTCN00118'), 5),"..
"(5213, (select id from catalogo where sku = 'PDTTTCN00118'), 6),"..
"(5214, (select id from catalogo where sku = 'PDTTTCN00140'), 2),"..
"(5215, (select id from catalogo where sku = 'PDTTTCN00140'), 3),"..
"(5216, (select id from catalogo where sku = 'PDTTTCN00140'), 4),"..
"(5217, (select id from catalogo where sku = 'PDTTTCN00140'), 5),"..
"(5218, (select id from catalogo where sku = 'PDTTTCN00140'), 6),"..
"(5219, (select id from catalogo where sku = 'PDTTTCN00171'), 2),"..
"(5220, (select id from catalogo where sku = 'PDTTTCN00171'), 3),"..
"(5221, (select id from catalogo where sku = 'PDTTTCN00171'), 4),"..
"(5222, (select id from catalogo where sku = 'PDTTTCN00171'), 5),"..
"(5223, (select id from catalogo where sku = 'PDTTTCN00171'), 6),"..
"(5224, (select id from catalogo where sku = 'PDTTTRM00103'), 2),"..
"(5225, (select id from catalogo where sku = 'PDTTTRM00103'), 3),"..
"(5226, (select id from catalogo where sku = 'PDTTTRM00103'), 4),"..
"(5227, (select id from catalogo where sku = 'PDTTTRM00103'), 5),"..
"(5228, (select id from catalogo where sku = 'PDTTTRM00103'), 6),"..
"(5229, (select id from catalogo where sku = 'PDTTTRM00113'), 2),"..
"(5230, (select id from catalogo where sku = 'PDTTTRM00113'), 3),"..
"(5231, (select id from catalogo where sku = 'PDTTTRM00113'), 4),"..
"(5232, (select id from catalogo where sku = 'PDTTTRM00113'), 5),"..
"(5233, (select id from catalogo where sku = 'PDTTTRM00113'), 6),"..
"(5234, (select id from catalogo where sku = 'PDTTTRM00117'), 2),"..
"(5235, (select id from catalogo where sku = 'PDTTTRM00117'), 3),"..
"(5236, (select id from catalogo where sku = 'PDTTTRM00117'), 4),"..
"(5237, (select id from catalogo where sku = 'PDTTTRM00117'), 5),"..
"(5238, (select id from catalogo where sku = 'PDTTTRM00117'), 6),"..
"(5239, (select id from catalogo where sku = 'PDTTTRM00118'), 2),"..
"(5240, (select id from catalogo where sku = 'PDTTTRM00118'), 3),"..
"(5241, (select id from catalogo where sku = 'PDTTTRM00118'), 4),"..
"(5242, (select id from catalogo where sku = 'PDTTTRM00118'), 5),"..
"(5243, (select id from catalogo where sku = 'PDTTTRM00118'), 6),"..
"(5244, (select id from catalogo where sku = 'PDTTTRM00140'), 2),"..
"(5245, (select id from catalogo where sku = 'PDTTTRM00140'), 3),"..
"(5246, (select id from catalogo where sku = 'PDTTTRM00140'), 4),"..
"(5247, (select id from catalogo where sku = 'PDTTTRM00140'), 5),"..
"(5248, (select id from catalogo where sku = 'PDTTTRM00140'), 6),"..
"(5249, (select id from catalogo where sku = 'PDTTTRM00171'), 2),"..
"(5250, (select id from catalogo where sku = 'PDTTTRM00171'), 3),"..
"(5251, (select id from catalogo where sku = 'PDTTTRM00171'), 4),"..
"(5252, (select id from catalogo where sku = 'PDTTTRM00171'), 5),"..
"(5253, (select id from catalogo where sku = 'PDTTTRM00171'), 6),"..
"(5254, (select id from catalogo where sku = 'PN300TCN00173'), 2),"..
"(5255, (select id from catalogo where sku = 'PN300TCN00173'), 3),"..
"(5256, (select id from catalogo where sku = 'PN300TCN00173'), 4),"..
"(5257, (select id from catalogo where sku = 'PN300TCN00173'), 5),"..
"(5258, (select id from catalogo where sku = 'PN300TCN00212'), 2),"..
"(5259, (select id from catalogo where sku = 'PN300TCN00212'), 3),"..
"(5260, (select id from catalogo where sku = 'PN300TCN00212'), 4),"..
"(5261, (select id from catalogo where sku = 'PN300TCN00212'), 5),"..
"(5262, (select id from catalogo where sku = 'PN300TCN00310'), 2),"..
"(5263, (select id from catalogo where sku = 'PN300TCN00310'), 3),"..
"(5264, (select id from catalogo where sku = 'PN300TCN00310'), 4),"..
"(5265, (select id from catalogo where sku = 'PN300TCN00310'), 5),"..
"(5266, (select id from catalogo where sku = 'PN300TCN00417'), 2),"..
"(5267, (select id from catalogo where sku = 'PN300TCN00417'), 3),"..
"(5268, (select id from catalogo where sku = 'PN300TCN00417'), 4),"..
"(5269, (select id from catalogo where sku = 'PN300TCN00417'), 5),"..
"(5270, (select id from catalogo where sku = 'PN300TCN00511'), 2),"..
"(5271, (select id from catalogo where sku = 'PN300TCN00511'), 3),"..
"(5272, (select id from catalogo where sku = 'PN300TCN00511'), 4),"..
"(5273, (select id from catalogo where sku = 'PN300TCN00511'), 5),"..
"(5274, (select id from catalogo where sku = 'PN300TCN00616'), 2),"..
"(5275, (select id from catalogo where sku = 'PN300TCN00616'), 3),"..
"(5276, (select id from catalogo where sku = 'PN300TCN00616'), 4),"..
"(5277, (select id from catalogo where sku = 'PN300TCN00616'), 5),"..
"(5278, (select id from catalogo where sku = 'PN300TCN00711'), 2),"..
"(5279, (select id from catalogo where sku = 'PN300TCN00711'), 3),"..
"(5280, (select id from catalogo where sku = 'PN300TCN00711'), 4),"..
"(5281, (select id from catalogo where sku = 'PN300TCN00711'), 5),"..
"(5282, (select id from catalogo where sku = 'PN300TCN00810'), 2),"..
"(5283, (select id from catalogo where sku = 'PN300TCN00810'), 3),"..
"(5284, (select id from catalogo where sku = 'PN300TCN00810'), 4),"..
"(5285, (select id from catalogo where sku = 'PN300TCN00810'), 5),"..
"(5286, (select id from catalogo where sku = 'PN300TCN00912'), 2),"..
"(5287, (select id from catalogo where sku = 'PN300TCN00912'), 3),"..
"(5288, (select id from catalogo where sku = 'PN300TCN00912'), 4),"..
"(5289, (select id from catalogo where sku = 'PN300TCN00912'), 5),"..
"(5290, (select id from catalogo where sku = 'PN300TCN01011'), 2),"..
"(5291, (select id from catalogo where sku = 'PN300TCN01011'), 3),"..
"(5292, (select id from catalogo where sku = 'PN300TCN01011'), 4),"..
"(5293, (select id from catalogo where sku = 'PN300TCN01011'), 5),"..
"(5294, (select id from catalogo where sku = 'PN300TCN01113'), 2),"..
"(5295, (select id from catalogo where sku = 'PN300TCN01113'), 3),"..
"(5296, (select id from catalogo where sku = 'PN300TCN01113'), 4),"..
"(5297, (select id from catalogo where sku = 'PN300TCN01113'), 5),"..
"(5298, (select id from catalogo where sku = 'PN300TCN01216'), 2);"
db:exec( query2 )
--fase 36
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(5299, (select id from catalogo where sku = 'PN300TCN01216'), 3),"..
"(5300, (select id from catalogo where sku = 'PN300TCN01216'), 4),"..
"(5301, (select id from catalogo where sku = 'PN300TCN01216'), 5),"..
"(5302, (select id from catalogo where sku = 'PN300TCN01303'), 2),"..
"(5303, (select id from catalogo where sku = 'PN300TCN01303'), 3),"..
"(5304, (select id from catalogo where sku = 'PN300TCN01303'), 4),"..
"(5305, (select id from catalogo where sku = 'PN300TCN01303'), 5),"..
"(5306, (select id from catalogo where sku = 'PN300TCN01309'), 2),"..
"(5307, (select id from catalogo where sku = 'PN300TCN01309'), 3),"..
"(5308, (select id from catalogo where sku = 'PN300TCN01309'), 4),"..
"(5309, (select id from catalogo where sku = 'PN300TCN01309'), 5),"..
"(5310, (select id from catalogo where sku = 'PN300TCN01310'), 2),"..
"(5311, (select id from catalogo where sku = 'PN300TCN01310'), 3),"..
"(5312, (select id from catalogo where sku = 'PN300TCN01310'), 4),"..
"(5313, (select id from catalogo where sku = 'PN300TCN01310'), 5),"..
"(5314, (select id from catalogo where sku = 'PN300TCN01411'), 2),"..
"(5315, (select id from catalogo where sku = 'PN300TCN01411'), 3),"..
"(5316, (select id from catalogo where sku = 'PN300TCN01411'), 4),"..
"(5317, (select id from catalogo where sku = 'PN300TCN01411'), 5),"..
"(5318, (select id from catalogo where sku = 'PN300TCN01473'), 2),"..
"(5319, (select id from catalogo where sku = 'PN300TCN01473'), 3),"..
"(5320, (select id from catalogo where sku = 'PN300TCN01473'), 4),"..
"(5321, (select id from catalogo where sku = 'PN300TCN01473'), 5),"..
"(5322, (select id from catalogo where sku = 'PN300TRM00173'), 2),"..
"(5323, (select id from catalogo where sku = 'PN300TRM00173'), 3),"..
"(5324, (select id from catalogo where sku = 'PN300TRM00173'), 4),"..
"(5325, (select id from catalogo where sku = 'PN300TRM00173'), 5),"..
"(5326, (select id from catalogo where sku = 'PN300TRM00212'), 2),"..
"(5327, (select id from catalogo where sku = 'PN300TRM00212'), 3),"..
"(5328, (select id from catalogo where sku = 'PN300TRM00212'), 4),"..
"(5329, (select id from catalogo where sku = 'PN300TRM00212'), 5),"..
"(5330, (select id from catalogo where sku = 'PN300TRM00310'), 2),"..
"(5331, (select id from catalogo where sku = 'PN300TRM00310'), 3),"..
"(5332, (select id from catalogo where sku = 'PN300TRM00310'), 4),"..
"(5333, (select id from catalogo where sku = 'PN300TRM00310'), 5),"..
"(5334, (select id from catalogo where sku = 'PN300TRM00417'), 2),"..
"(5335, (select id from catalogo where sku = 'PN300TRM00417'), 3),"..
"(5336, (select id from catalogo where sku = 'PN300TRM00417'), 4),"..
"(5337, (select id from catalogo where sku = 'PN300TRM00417'), 5),"..
"(5338, (select id from catalogo where sku = 'PN300TRM00511'), 2),"..
"(5339, (select id from catalogo where sku = 'PN300TRM00511'), 3),"..
"(5340, (select id from catalogo where sku = 'PN300TRM00511'), 4),"..
"(5341, (select id from catalogo where sku = 'PN300TRM00511'), 5),"..
"(5342, (select id from catalogo where sku = 'PN300TRM00616'), 2),"..
"(5343, (select id from catalogo where sku = 'PN300TRM00616'), 3),"..
"(5344, (select id from catalogo where sku = 'PN300TRM00616'), 4),"..
"(5345, (select id from catalogo where sku = 'PN300TRM00616'), 5),"..
"(5346, (select id from catalogo where sku = 'PN300TRM00711'), 2),"..
"(5347, (select id from catalogo where sku = 'PN300TRM00711'), 3),"..
"(5348, (select id from catalogo where sku = 'PN300TRM00711'), 4),"..
"(5349, (select id from catalogo where sku = 'PN300TRM00711'), 5),"..
"(5350, (select id from catalogo where sku = 'PN300TRM00810'), 2),"..
"(5351, (select id from catalogo where sku = 'PN300TRM00810'), 3),"..
"(5352, (select id from catalogo where sku = 'PN300TRM00810'), 4),"..
"(5353, (select id from catalogo where sku = 'PN300TRM00810'), 5),"..
"(5354, (select id from catalogo where sku = 'PN300TRM00912'), 2),"..
"(5355, (select id from catalogo where sku = 'PN300TRM00912'), 3),"..
"(5356, (select id from catalogo where sku = 'PN300TRM00912'), 4),"..
"(5357, (select id from catalogo where sku = 'PN300TRM00912'), 5),"..
"(5358, (select id from catalogo where sku = 'PN300TRM01011'), 2),"..
"(5359, (select id from catalogo where sku = 'PN300TRM01011'), 3),"..
"(5360, (select id from catalogo where sku = 'PN300TRM01011'), 4),"..
"(5361, (select id from catalogo where sku = 'PN300TRM01011'), 5),"..
"(5362, (select id from catalogo where sku = 'PN300TRM01113'), 2),"..
"(5363, (select id from catalogo where sku = 'PN300TRM01113'), 3),"..
"(5364, (select id from catalogo where sku = 'PN300TRM01113'), 4),"..
"(5365, (select id from catalogo where sku = 'PN300TRM01113'), 5),"..
"(5366, (select id from catalogo where sku = 'PN300TRM01216'), 2),"..
"(5367, (select id from catalogo where sku = 'PN300TRM01216'), 3),"..
"(5368, (select id from catalogo where sku = 'PN300TRM01216'), 4),"..
"(5369, (select id from catalogo where sku = 'PN300TRM01216'), 5),"..
"(5370, (select id from catalogo where sku = 'PN300TRM01303'), 2),"..
"(5371, (select id from catalogo where sku = 'PN300TRM01303'), 3),"..
"(5372, (select id from catalogo where sku = 'PN300TRM01303'), 4),"..
"(5373, (select id from catalogo where sku = 'PN300TRM01303'), 5),"..
"(5374, (select id from catalogo where sku = 'PN300TRM01309'), 2),"..
"(5375, (select id from catalogo where sku = 'PN300TRM01309'), 3),"..
"(5376, (select id from catalogo where sku = 'PN300TRM01309'), 4),"..
"(5377, (select id from catalogo where sku = 'PN300TRM01309'), 5),"..
"(5378, (select id from catalogo where sku = 'PN300TRM01310'), 2),"..
"(5379, (select id from catalogo where sku = 'PN300TRM01310'), 3),"..
"(5380, (select id from catalogo where sku = 'PN300TRM01310'), 4),"..
"(5381, (select id from catalogo where sku = 'PN300TRM01310'), 5),"..
"(5382, (select id from catalogo where sku = 'PN300TRM01411'), 2),"..
"(5383, (select id from catalogo where sku = 'PN300TRM01411'), 3),"..
"(5384, (select id from catalogo where sku = 'PN300TRM01411'), 4),"..
"(5385, (select id from catalogo where sku = 'PN300TRM01411'), 5),"..
"(5386, (select id from catalogo where sku = 'PN300TRM01473'), 2),"..
"(5387, (select id from catalogo where sku = 'PN300TRM01473'), 3),"..
"(5388, (select id from catalogo where sku = 'PN300TRM01473'), 4),"..
"(5389, (select id from catalogo where sku = 'PN300TRM01473'), 5),"..
"(5390, (select id from catalogo where sku = 'PNTTTCN00103'), 2),"..
"(5391, (select id from catalogo where sku = 'PNTTTCN00103'), 3),"..
"(5392, (select id from catalogo where sku = 'PNTTTCN00103'), 4),"..
"(5393, (select id from catalogo where sku = 'PNTTTCN00103'), 5),"..
"(5394, (select id from catalogo where sku = 'PNTTTCN00103'), 6),"..
"(5395, (select id from catalogo where sku = 'PNTTTCN00117'), 2),"..
"(5396, (select id from catalogo where sku = 'PNTTTCN00117'), 3),"..
"(5397, (select id from catalogo where sku = 'PNTTTCN00117'), 4),"..
"(5398, (select id from catalogo where sku = 'PNTTTCN00117'), 5),"..
"(5399, (select id from catalogo where sku = 'PNTTTCN00117'), 6),"..
"(5400, (select id from catalogo where sku = 'PNTTTCN00118'), 2),"..
"(5401, (select id from catalogo where sku = 'PNTTTCN00118'), 3),"..
"(5402, (select id from catalogo where sku = 'PNTTTCN00118'), 4),"..
"(5403, (select id from catalogo where sku = 'PNTTTCN00118'), 5),"..
"(5404, (select id from catalogo where sku = 'PNTTTCN00118'), 6),"..
"(5405, (select id from catalogo where sku = 'PNTTTCN00140'), 2),"..
"(5406, (select id from catalogo where sku = 'PNTTTCN00140'), 3),"..
"(5407, (select id from catalogo where sku = 'PNTTTCN00140'), 4),"..
"(5408, (select id from catalogo where sku = 'PNTTTCN00140'), 5),"..
"(5409, (select id from catalogo where sku = 'PNTTTCN00140'), 6),"..
"(5410, (select id from catalogo where sku = 'PNTTTCN00171'), 2),"..
"(5411, (select id from catalogo where sku = 'PNTTTCN00171'), 3),"..
"(5412, (select id from catalogo where sku = 'PNTTTCN00171'), 4),"..
"(5413, (select id from catalogo where sku = 'PNTTTCN00171'), 5),"..
"(5414, (select id from catalogo where sku = 'PNTTTCN00171'), 6),"..
"(5415, (select id from catalogo where sku = 'PNTTTRM00103'), 2),"..
"(5416, (select id from catalogo where sku = 'PNTTTRM00103'), 3),"..
"(5417, (select id from catalogo where sku = 'PNTTTRM00103'), 4),"..
"(5418, (select id from catalogo where sku = 'PNTTTRM00103'), 5),"..
"(5419, (select id from catalogo where sku = 'PNTTTRM00103'), 6),"..
"(5420, (select id from catalogo where sku = 'PNTTTRM00117'), 2),"..
"(5421, (select id from catalogo where sku = 'PNTTTRM00117'), 3),"..
"(5422, (select id from catalogo where sku = 'PNTTTRM00117'), 4),"..
"(5423, (select id from catalogo where sku = 'PNTTTRM00117'), 5),"..
"(5424, (select id from catalogo where sku = 'PNTTTRM00117'), 6),"..
"(5425, (select id from catalogo where sku = 'PNTTTRM00118'), 2),"..
"(5426, (select id from catalogo where sku = 'PNTTTRM00118'), 3),"..
"(5427, (select id from catalogo where sku = 'PNTTTRM00118'), 4),"..
"(5428, (select id from catalogo where sku = 'PNTTTRM00118'), 5),"..
"(5429, (select id from catalogo where sku = 'PNTTTRM00118'), 6),"..
"(5430, (select id from catalogo where sku = 'PNTTTRM00140'), 2),"..
"(5431, (select id from catalogo where sku = 'PNTTTRM00140'), 3),"..
"(5432, (select id from catalogo where sku = 'PNTTTRM00140'), 4),"..
"(5433, (select id from catalogo where sku = 'PNTTTRM00140'), 5),"..
"(5434, (select id from catalogo where sku = 'PNTTTRM00140'), 6),"..
"(5435, (select id from catalogo where sku = 'PNTTTRM00171'), 2),"..
"(5436, (select id from catalogo where sku = 'PNTTTRM00171'), 3),"..
"(5437, (select id from catalogo where sku = 'PNTTTRM00171'), 4),"..
"(5438, (select id from catalogo where sku = 'PNTTTRM00171'), 5),"..
"(5439, (select id from catalogo where sku = 'PNTTTRM00171'), 6),"..
"(5440, (select id from catalogo where sku = 'PROCOA01502'), 2),"..
"(5441, (select id from catalogo where sku = 'PROCOA01502'), 3),"..
"(5442, (select id from catalogo where sku = 'PROCOA01502'), 4),"..
"(5443, (select id from catalogo where sku = 'PROCOA01502'), 5),"..
"(5444, (select id from catalogo where sku = 'PROCOA01511'), 2),"..
"(5445, (select id from catalogo where sku = 'PROCOA01511'), 3),"..
"(5446, (select id from catalogo where sku = 'PROCOA01511'), 4),"..
"(5447, (select id from catalogo where sku = 'PROCOA01511'), 5),"..
"(5448, (select id from catalogo where sku = 'PROCOA015XXL02'), 6),"..
"(5449, (select id from catalogo where sku = 'PROCOA015XXL11'), 6);"
db:exec( query2 )
--fase 37
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(5450, (select id from catalogo where sku = 'PROCOD01540'), 2),"..
"(5451, (select id from catalogo where sku = 'PROCOD01540'), 3),"..
"(5452, (select id from catalogo where sku = 'PROCOD01540'), 4),"..
"(5453, (select id from catalogo where sku = 'PROCOD01540'), 5),"..
"(5454, (select id from catalogo where sku = 'PROCOD01571'), 2),"..
"(5455, (select id from catalogo where sku = 'PROCOD01571'), 3),"..
"(5456, (select id from catalogo where sku = 'PROCOD01571'), 4),"..
"(5457, (select id from catalogo where sku = 'PROCOD01571'), 5),"..
"(5458, (select id from catalogo where sku = 'PROGMBDES04'), 8),"..
"(5459, (select id from catalogo where sku = 'PROGMBDES05'), 8),"..
"(5460, (select id from catalogo where sku = 'PROGMBDES06'), 8),"..
"(5461, (select id from catalogo where sku = 'PROGMBDES10'), 8),"..
"(5462, (select id from catalogo where sku = 'PROGMBDES11'), 8),"..
"(5463, (select id from catalogo where sku = 'PROGMBDES12'), 8),"..
"(5464, (select id from catalogo where sku = 'PROGMBDES13'), 8),"..
"(5465, (select id from catalogo where sku = 'PROGMBDES15'), 8),"..
"(5466, (select id from catalogo where sku = 'PROGMBDES16'), 8),"..
"(5467, (select id from catalogo where sku = 'PROGMBDES21'), 8),"..
"(5468, (select id from catalogo where sku = 'PROGMBDES25'), 8),"..
"(5469, (select id from catalogo where sku = 'PROGMBDES26'), 8),"..
"(5470, (select id from catalogo where sku = 'PROGMBDES28'), 8),"..
"(5471, (select id from catalogo where sku = 'PROGMBDES30'), 8),"..
"(5472, (select id from catalogo where sku = 'PROGMBDES32'), 8),"..
"(5473, (select id from catalogo where sku = 'PROGMBDES34'), 8),"..
"(5474, (select id from catalogo where sku = 'PROGMBDES35'), 8),"..
"(5475, (select id from catalogo where sku = 'PROGMBDES37'), 8),"..
"(5476, (select id from catalogo where sku = 'PROGMBNIÑ02'), 8),"..
"(5477, (select id from catalogo where sku = 'PROGMBNIÑ10'), 8),"..
"(5478, (select id from catalogo where sku = 'PROGMBNIÑ11'), 8),"..
"(5479, (select id from catalogo where sku = 'PROGMBNIÑ12'), 8),"..
"(5480, (select id from catalogo where sku = 'PROGMBNIÑ15'), 8),"..
"(5481, (select id from catalogo where sku = 'RIMGDKBBE03'), 8),"..
"(5482, (select id from catalogo where sku = 'RIMGDKBBE04'), 8),"..
"(5483, (select id from catalogo where sku = 'RIMGDKBBE10'), 8),"..
"(5484, (select id from catalogo where sku = 'RIMGDKBBE12'), 8),"..
"(5485, (select id from catalogo where sku = 'RIMGDKBBE29'), 8),"..
"(5486, (select id from catalogo where sku = 'RIMGDKDES11'), 8),"..
"(5487, (select id from catalogo where sku = 'RIMGDKDES13'), 8),"..
"(5488, (select id from catalogo where sku = 'RIMGDKPLU12'), 8),"..
"(5489, (select id from catalogo where sku = 'RIMGDKPLU17'), 8),"..
"(5490, (select id from catalogo where sku = 'RIMGDKPLU18'), 8),"..
"(5491, (select id from catalogo where sku = 'RIMGDKPLU40'), 8),"..
"(5492, (select id from catalogo where sku = 'RIMGDKPLU71'), 8),"..
"(5493, (select id from catalogo where sku = 'RIMGGE00111'), 8),"..
"(5494, (select id from catalogo where sku = 'RIMGGE00216'), 8),"..
"(5495, (select id from catalogo where sku = 'RIMGGE00373'), 8),"..
"(5496, (select id from catalogo where sku = 'RIMGGE00412'), 8),"..
"(5497, (select id from catalogo where sku = 'RIMGGE00508'), 8),"..
"(5498, (select id from catalogo where sku = 'RIMGGE00604'), 8),"..
"(5499, (select id from catalogo where sku = 'RIMGGE00713'), 8),"..
"(5500, (select id from catalogo where sku = 'RIMGGE00803'), 8),"..
"(5501, (select id from catalogo where sku = 'RIMGGE00971'), 8),"..
"(5502, (select id from catalogo where sku = 'RIMGGE01003'), 8),"..
"(5503, (select id from catalogo where sku = 'RIMGGE01304'), 8),"..
"(5504, (select id from catalogo where sku = 'RIMGGE01917'), 8),"..
"(5505, (select id from catalogo where sku = 'RIMGGE02009'), 8),"..
"(5506, (select id from catalogo where sku = 'RIMGGE02118'), 8),"..
"(5507, (select id from catalogo where sku = 'RIMGGE02229'), 8),"..
"(5508, (select id from catalogo where sku = 'RIMGGE02311'), 8),"..
"(5509, (select id from catalogo where sku = 'RIMGGE02513'), 8),"..
"(5510, (select id from catalogo where sku = 'RIMGGE02611'), 8),"..
"(5511, (select id from catalogo where sku = 'RIMGMBARC04'), 8),"..
"(5512, (select id from catalogo where sku = 'RIMGMBARC18'), 8),"..
"(5513, (select id from catalogo where sku = 'RIMGMBARC29'), 8),"..
"(5514, (select id from catalogo where sku = 'RIMGMBARC37'), 8),"..
"(5515, (select id from catalogo where sku = 'RIMGMBBAS04'), 8),"..
"(5516, (select id from catalogo where sku = 'RIMGMBBAS05'), 8),"..
"(5517, (select id from catalogo where sku = 'RIMGMBBAS11'), 8),"..
"(5518, (select id from catalogo where sku = 'RIMGMBBAS12'), 8),"..
"(5519, (select id from catalogo where sku = 'RIMGMBBAS28'), 8),"..
"(5520, (select id from catalogo where sku = 'RIMGMBBCA10'), 8),"..
"(5521, (select id from catalogo where sku = 'RIMGMBBCA12'), 8),"..
"(5522, (select id from catalogo where sku = 'RIMGMBCAM13'), 8),"..
"(5523, (select id from catalogo where sku = 'RIMGMBCAM26'), 8),"..
"(5524, (select id from catalogo where sku = 'RIMGMBCAM32'), 8),"..
"(5525, (select id from catalogo where sku = 'RIMGMBCAZ09'), 8),"..
"(5526, (select id from catalogo where sku = 'RIMGMBCAZ11'), 8),"..
"(5527, (select id from catalogo where sku = 'RIMGMBCAZ30'), 8),"..
"(5528, (select id from catalogo where sku = 'RIMGMBDAM04'), 8),"..
"(5529, (select id from catalogo where sku = 'RIMGMBDAM12'), 8),"..
"(5530, (select id from catalogo where sku = 'RIMGMBDAM17'), 8),"..
"(5531, (select id from catalogo where sku = 'RIMGMBDAM18'), 8),"..
"(5532, (select id from catalogo where sku = 'RIMGMBDAM19'), 8),"..
"(5533, (select id from catalogo where sku = 'RIMGMBDAM23'), 8),"..
"(5534, (select id from catalogo where sku = 'RIMGMBDAM29'), 8),"..
"(5535, (select id from catalogo where sku = 'RIMGMBDAM40'), 8),"..
"(5536, (select id from catalogo where sku = 'RIMGMBDAM41'), 8),"..
"(5537, (select id from catalogo where sku = 'RIMGMBDAM42'), 8),"..
"(5538, (select id from catalogo where sku = 'RIMGMBDES02'), 8),"..
"(5539, (select id from catalogo where sku = 'RIMGMBDES04'), 8),"..
"(5540, (select id from catalogo where sku = 'RIMGMBDES05'), 8),"..
"(5541, (select id from catalogo where sku = 'RIMGMBDES06'), 8),"..
"(5542, (select id from catalogo where sku = 'RIMGMBDES09'), 8),"..
"(5543, (select id from catalogo where sku = 'RIMGMBDES10'), 8),"..
"(5544, (select id from catalogo where sku = 'RIMGMBDES11'), 8),"..
"(5545, (select id from catalogo where sku = 'RIMGMBDES12'), 8),"..
"(5546, (select id from catalogo where sku = 'RIMGMBDES13'), 8),"..
"(5547, (select id from catalogo where sku = 'RIMGMBDES15'), 8),"..
"(5548, (select id from catalogo where sku = 'RIMGMBDES16'), 8),"..
"(5549, (select id from catalogo where sku = 'RIMGMBDES17'), 8),"..
"(5550, (select id from catalogo where sku = 'RIMGMBDES21'), 8),"..
"(5551, (select id from catalogo where sku = 'RIMGMBDES25'), 8),"..
"(5552, (select id from catalogo where sku = 'RIMGMBDES26'), 8),"..
"(5553, (select id from catalogo where sku = 'RIMGMBDES28'), 8),"..
"(5554, (select id from catalogo where sku = 'RIMGMBDES29'), 8),"..
"(5555, (select id from catalogo where sku = 'RIMGMBDES30'), 8),"..
"(5556, (select id from catalogo where sku = 'RIMGMBDES31'), 8),"..
"(5557, (select id from catalogo where sku = 'RIMGMBDES32'), 8),"..
"(5558, (select id from catalogo where sku = 'RIMGMBDES34'), 8),"..
"(5559, (select id from catalogo where sku = 'RIMGMBDES35'), 8),"..
"(5560, (select id from catalogo where sku = 'RIMGMBDES37'), 8),"..
"(5561, (select id from catalogo where sku = 'RIMGMBDES68'), 8),"..
"(5562, (select id from catalogo where sku = 'RIMGMBDES74'), 8),"..
"(5563, (select id from catalogo where sku = 'RIMGMBFCU17'), 8),"..
"(5564, (select id from catalogo where sku = 'RIMGMBFCU40'), 8),"..
"(5565, (select id from catalogo where sku = 'RIMGMBFID11'), 8),"..
"(5566, (select id from catalogo where sku = 'RIMGMBFID13'), 8),"..
"(5567, (select id from catalogo where sku = 'RIMGMBFID17'), 8),"..
"(5568, (select id from catalogo where sku = 'RIMGMBFID28'), 8),"..
"(5569, (select id from catalogo where sku = 'RIMGMBFID29'), 8),"..
"(5570, (select id from catalogo where sku = 'RIMGMBFID30'), 8),"..
"(5571, (select id from catalogo where sku = 'RIMGMBFID37'), 8),"..
"(5572, (select id from catalogo where sku = 'RIMGMBFID40'), 8),"..
"(5573, (select id from catalogo where sku = 'RIMGMBFID66'), 8),"..
"(5574, (select id from catalogo where sku = 'RIMGMBFID71'), 8),"..
"(5575, (select id from catalogo where sku = 'RIMGMBNIÑ02'), 8),"..
"(5576, (select id from catalogo where sku = 'RIMGMBNIÑ10'), 8),"..
"(5577, (select id from catalogo where sku = 'RIMGMBNIÑ11'), 8),"..
"(5578, (select id from catalogo where sku = 'RIMGMBNIÑ12'), 8),"..
"(5579, (select id from catalogo where sku = 'RIMGMBNIÑ15'), 8),"..
"(5580, (select id from catalogo where sku = 'RIMGMBNIÑ26'), 8),"..
"(5581, (select id from catalogo where sku = 'RIMGMBNMA62'), 8),"..
"(5582, (select id from catalogo where sku = 'RIMGMBNMA63'), 8),"..
"(5583, (select id from catalogo where sku = 'RIMGMBNMA64'), 8),"..
"(5584, (select id from catalogo where sku = 'RIMGMBNMA65'), 8),"..
"(5585, (select id from catalogo where sku = 'RIMGMBOXF02'), 8),"..
"(5586, (select id from catalogo where sku = 'RIMGMBOXF11'), 8),"..
"(5587, (select id from catalogo where sku = 'RIMGMBOXF13'), 8),"..
"(5588, (select id from catalogo where sku = 'RIMGMBOXF28'), 8),"..
"(5589, (select id from catalogo where sku = 'RIMGMBOXF30'), 8),"..
"(5590, (select id from catalogo where sku = 'RIMGMBOXF31'), 8),"..
"(5591, (select id from catalogo where sku = 'RIMGMBOXF37'), 8),"..
"(5592, (select id from catalogo where sku = 'RIMGMBPES02'), 8),"..
"(5593, (select id from catalogo where sku = 'RIMGMBPES11'), 8),"..
"(5594, (select id from catalogo where sku = 'RIMGMBPES13'), 8),"..
"(5595, (select id from catalogo where sku = 'RIMGMBPES28'), 8),"..
"(5596, (select id from catalogo where sku = 'RIMGMBPES31'), 8),"..
"(5597, (select id from catalogo where sku = 'RIMGMBRAU11'), 8),"..
"(5598, (select id from catalogo where sku = 'RIMGMBRAU13'), 8),"..
"(5599, (select id from catalogo where sku = 'RIMGMBRAU28'), 8),"..
"(5600, (select id from catalogo where sku = 'RIMGMBRAU29'), 8);"
db:exec( query2 )
--fase 38
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(5601, (select id from catalogo where sku = 'RIMGMBRAU30'), 8),"..
"(5602, (select id from catalogo where sku = 'RIMGMBRAU31'), 8),"..
"(5603, (select id from catalogo where sku = 'RIMGMBRAU66'), 8),"..
"(5604, (select id from catalogo where sku = 'RIMGMBSAF03'), 8),"..
"(5605, (select id from catalogo where sku = 'RIMGMBSAF28'), 8),"..
"(5606, (select id from catalogo where sku = 'RIMGMBSAF30'), 8),"..
"(5607, (select id from catalogo where sku = 'RIMGMBSAN02'), 8),"..
"(5608, (select id from catalogo where sku = 'RIMGMBSAN03'), 8),"..
"(5609, (select id from catalogo where sku = 'RIMGMBSAN04'), 8),"..
"(5610, (select id from catalogo where sku = 'RIMGMBSAN05'), 8),"..
"(5611, (select id from catalogo where sku = 'RIMGMBSAN07'), 8),"..
"(5612, (select id from catalogo where sku = 'RIMGMBSAN11'), 8),"..
"(5613, (select id from catalogo where sku = 'RIMGMBSAN13'), 8),"..
"(5614, (select id from catalogo where sku = 'RIMGMBSAN20'), 8),"..
"(5615, (select id from catalogo where sku = 'RIMGMBSAN22'), 8),"..
"(5616, (select id from catalogo where sku = 'RIMGMBSAN30'), 8),"..
"(5617, (select id from catalogo where sku = 'RIMGMBSAN32'), 8),"..
"(5618, (select id from catalogo where sku = 'RIMGMBSAN33'), 8),"..
"(5619, (select id from catalogo where sku = 'RIMGMBSAN36'), 8),"..
"(5620, (select id from catalogo where sku = 'RIMGMBSAN39'), 8),"..
"(5621, (select id from catalogo where sku = 'RIMGMBSAN43'), 8),"..
"(5622, (select id from catalogo where sku = 'RIMGMBSAN45'), 8),"..
"(5623, (select id from catalogo where sku = 'RIMGMBSAN47'), 8),"..
"(5624, (select id from catalogo where sku = 'RIMGMBSAN49'), 8),"..
"(5625, (select id from catalogo where sku = 'RIMGMBSAN51'), 8),"..
"(5626, (select id from catalogo where sku = 'RIMGMBSAN83'), 8),"..
"(5627, (select id from catalogo where sku = 'RIMGMBVIN202'), 8),"..
"(5628, (select id from catalogo where sku = 'RIMGMBVIN203'), 8),"..
"(5629, (select id from catalogo where sku = 'RIMGMBVIN208'), 8),"..
"(5630, (select id from catalogo where sku = 'RIMGMBVIN209'), 8),"..
"(5631, (select id from catalogo where sku = 'RIMGMBVIN211'), 8),"..
"(5632, (select id from catalogo where sku = 'RIMGMBVIN212'), 8),"..
"(5633, (select id from catalogo where sku = 'RIMGMBVIN213'), 8),"..
"(5634, (select id from catalogo where sku = 'RIMGMBVIN215'), 8),"..
"(5635, (select id from catalogo where sku = 'RIMGMBVIN216'), 8),"..
"(5636, (select id from catalogo where sku = 'RIMGMBVIN226'), 8),"..
"(5637, (select id from catalogo where sku = 'RIMGMBVIN228'), 8),"..
"(5638, (select id from catalogo where sku = 'RIMGMBVIN229'), 8),"..
"(5639, (select id from catalogo where sku = 'RIMGMBVIN230'), 8),"..
"(5640, (select id from catalogo where sku = 'RIMGMBVIN231'), 8),"..
"(5641, (select id from catalogo where sku = 'RIMGMBVIN237'), 8),"..
"(5642, (select id from catalogo where sku = 'RIMGMBVIN269'), 8),"..
"(5643, (select id from catalogo where sku = 'RIMGMBVIN270'), 8),"..
"(5644, (select id from catalogo where sku = 'RIMGMBVIN272'), 8),"..
"(5645, (select id from catalogo where sku = 'RIMGMBVIN302'), 8),"..
"(5646, (select id from catalogo where sku = 'RIMGMBVIN303'), 8),"..
"(5647, (select id from catalogo where sku = 'RIMGMBVIN305'), 8),"..
"(5648, (select id from catalogo where sku = 'RIMGMBVIN306'), 8),"..
"(5649, (select id from catalogo where sku = 'RIMGMBVIN309'), 8),"..
"(5650, (select id from catalogo where sku = 'RIMGMBVIN310'), 8),"..
"(5651, (select id from catalogo where sku = 'RIMGMBVIN311'), 8),"..
"(5652, (select id from catalogo where sku = 'RIMGMBVIN312'), 8),"..
"(5653, (select id from catalogo where sku = 'RIMGMBVIN313'), 8),"..
"(5654, (select id from catalogo where sku = 'RIMGMBVIN314'), 8),"..
"(5655, (select id from catalogo where sku = 'RIMGMBVIN315'), 8),"..
"(5656, (select id from catalogo where sku = 'RIMGMBVIN316'), 8),"..
"(5657, (select id from catalogo where sku = 'RIMGMBVIN321'), 8),"..
"(5658, (select id from catalogo where sku = 'RIMGMBVIN325'), 8),"..
"(5659, (select id from catalogo where sku = 'RIMGMBVIN326'), 8),"..
"(5660, (select id from catalogo where sku = 'RIMGMBVIN328'), 8),"..
"(5661, (select id from catalogo where sku = 'RIMGMBVIN329'), 8),"..
"(5662, (select id from catalogo where sku = 'RIMGMBVIN330'), 8),"..
"(5663, (select id from catalogo where sku = 'RIMGMBVIN331'), 8),"..
"(5664, (select id from catalogo where sku = 'RIMGMBVIN332'), 8),"..
"(5665, (select id from catalogo where sku = 'RIMGMBVIN334'), 8),"..
"(5666, (select id from catalogo where sku = 'RIMGMBVIN335'), 8),"..
"(5667, (select id from catalogo where sku = 'RIMGMBVIN337'), 8),"..
"(5668, (select id from catalogo where sku = 'RIMGMBVIN368'), 8),"..
"(5669, (select id from catalogo where sku = 'RIMGMBVIN403'), 8),"..
"(5670, (select id from catalogo where sku = 'RIMGMBVIN452'), 8),"..
"(5671, (select id from catalogo where sku = 'RIMGMBVIN457'), 8),"..
"(5672, (select id from catalogo where sku = 'RIMGMBVIT02'), 8),"..
"(5673, (select id from catalogo where sku = 'RIMGMBVIT03'), 8),"..
"(5674, (select id from catalogo where sku = 'RIMGMBVIT08'), 8),"..
"(5675, (select id from catalogo where sku = 'RIMGMBVIT09'), 8),"..
"(5676, (select id from catalogo where sku = 'RIMGMBVIT11'), 8),"..
"(5677, (select id from catalogo where sku = 'RIMGMBVIT12'), 8),"..
"(5678, (select id from catalogo where sku = 'RIMGMBVIT13'), 8),"..
"(5679, (select id from catalogo where sku = 'RIMGMBVIT15'), 8),"..
"(5680, (select id from catalogo where sku = 'RIMGMBVIT16'), 8),"..
"(5681, (select id from catalogo where sku = 'RIMGMBVIT17'), 8),"..
"(5682, (select id from catalogo where sku = 'RIMGMBVIT18'), 8),"..
"(5683, (select id from catalogo where sku = 'RIMGMBVIT26'), 8),"..
"(5684, (select id from catalogo where sku = 'RIMGMBVIT28'), 8),"..
"(5685, (select id from catalogo where sku = 'RIMGMBVIT29'), 8),"..
"(5686, (select id from catalogo where sku = 'RIMGMBVIT30'), 8),"..
"(5687, (select id from catalogo where sku = 'RIMGMBVIT31'), 8),"..
"(5688, (select id from catalogo where sku = 'RIMGMBVIT32'), 8),"..
"(5689, (select id from catalogo where sku = 'RIMGMBVIT37'), 8),"..
"(5690, (select id from catalogo where sku = 'RIMGMBVIT40'), 8),"..
"(5691, (select id from catalogo where sku = 'RIMGMBVIT69'), 8),"..
"(5692, (select id from catalogo where sku = 'RIMGMBVIT70'), 8),"..
"(5693, (select id from catalogo where sku = 'RIMGMBVIT71'), 8),"..
"(5694, (select id from catalogo where sku = 'RIMGMBVIT72'), 8),"..
"(5695, (select id from catalogo where sku = 'RIMGMBVIT73'), 8),"..
"(5696, (select id from catalogo where sku = 'RIMGMBVIT86'), 8),"..
"(5697, (select id from catalogo where sku = 'RIMGMBVIT87'), 8),"..
"(5698, (select id from catalogo where sku = 'RIMPAB0009'), 3),"..
"(5699, (select id from catalogo where sku = 'RIMPAB0009'), 4),"..
"(5700, (select id from catalogo where sku = 'RIMPAB0009'), 5),"..
"(5701, (select id from catalogo where sku = 'RIMPAB001'), 3),"..
"(5702, (select id from catalogo where sku = 'RIMPAB001'), 4),"..
"(5703, (select id from catalogo where sku = 'RIMPAB001'), 5),"..
"(5704, (select id from catalogo where sku = 'RIMPAB002'), 3),"..
"(5705, (select id from catalogo where sku = 'RIMPAB002'), 4),"..
"(5706, (select id from catalogo where sku = 'RIMPAB002'), 5),"..
"(5707, (select id from catalogo where sku = 'RIMPAB003'), 3),"..
"(5708, (select id from catalogo where sku = 'RIMPAB003'), 4),"..
"(5709, (select id from catalogo where sku = 'RIMPAB003'), 5),"..
"(5710, (select id from catalogo where sku = 'RIMPAB073'), 3),"..
"(5711, (select id from catalogo where sku = 'RIMPAB073'), 4),"..
"(5712, (select id from catalogo where sku = 'RIMPAB073'), 5),"..
"(5713, (select id from catalogo where sku = 'RIMPAB105'), 3),"..
"(5714, (select id from catalogo where sku = 'RIMPAB105'), 4),"..
"(5715, (select id from catalogo where sku = 'RIMPAB105'), 5),"..
"(5716, (select id from catalogo where sku = 'RIMPAB379'), 3),"..
"(5717, (select id from catalogo where sku = 'RIMPAB379'), 4),"..
"(5718, (select id from catalogo where sku = 'RIMPAB379'), 5),"..
"(5719, (select id from catalogo where sku = 'RIMPAB490'), 3),"..
"(5720, (select id from catalogo where sku = 'RIMPAB490'), 4),"..
"(5721, (select id from catalogo where sku = 'RIMPAB490'), 5),"..
"(5722, (select id from catalogo where sku = 'RIMPAB491'), 3),"..
"(5723, (select id from catalogo where sku = 'RIMPAB491'), 4),"..
"(5724, (select id from catalogo where sku = 'RIMPAB491'), 5),"..
"(5725, (select id from catalogo where sku = 'RIMPAB492'), 3),"..
"(5726, (select id from catalogo where sku = 'RIMPAB492'), 4),"..
"(5727, (select id from catalogo where sku = 'RIMPAB492'), 5),"..
"(5728, (select id from catalogo where sku = 'RIMPAB493'), 3),"..
"(5729, (select id from catalogo where sku = 'RIMPAB493'), 4),"..
"(5730, (select id from catalogo where sku = 'RIMPAB493'), 5),"..
"(5731, (select id from catalogo where sku = 'RIMPAB494'), 3),"..
"(5732, (select id from catalogo where sku = 'RIMPAB494'), 4),"..
"(5733, (select id from catalogo where sku = 'RIMPAB494'), 5),"..
"(5734, (select id from catalogo where sku = 'RIMPAB495'), 3),"..
"(5735, (select id from catalogo where sku = 'RIMPAB495'), 4),"..
"(5736, (select id from catalogo where sku = 'RIMPAB495'), 5),"..
"(5737, (select id from catalogo where sku = 'RIMPAI040'), 3),"..
"(5738, (select id from catalogo where sku = 'RIMPAI040'), 4),"..
"(5739, (select id from catalogo where sku = 'RIMPAI040'), 5),"..
"(5740, (select id from catalogo where sku = 'RIMPAI041'), 3),"..
"(5741, (select id from catalogo where sku = 'RIMPAI041'), 4),"..
"(5742, (select id from catalogo where sku = 'RIMPAI041'), 5),"..
"(5743, (select id from catalogo where sku = 'RIMPAI042'), 3),"..
"(5744, (select id from catalogo where sku = 'RIMPAI042'), 4),"..
"(5745, (select id from catalogo where sku = 'RIMPAI042'), 5),"..
"(5746, (select id from catalogo where sku = 'RIMPAI043'), 3),"..
"(5747, (select id from catalogo where sku = 'RIMPAI043'), 4),"..
"(5748, (select id from catalogo where sku = 'RIMPAI043'), 5),"..
"(5749, (select id from catalogo where sku = 'RIMPAI044'), 3),"..
"(5750, (select id from catalogo where sku = 'RIMPAI044'), 4),"..
"(5751, (select id from catalogo where sku = 'RIMPAI044'), 5);"
db:exec( query2 )
--fase 39
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(5752, (select id from catalogo where sku = 'RIMPAI045'), 3),"..
"(5753, (select id from catalogo where sku = 'RIMPAI045'), 4),"..
"(5754, (select id from catalogo where sku = 'RIMPAI045'), 5),"..
"(5755, (select id from catalogo where sku = 'RIMPAJ001'), 3),"..
"(5756, (select id from catalogo where sku = 'RIMPAJ001'), 4),"..
"(5757, (select id from catalogo where sku = 'RIMPAJ001'), 5),"..
"(5758, (select id from catalogo where sku = 'RIMPAJ002'), 3),"..
"(5759, (select id from catalogo where sku = 'RIMPAJ002'), 4),"..
"(5760, (select id from catalogo where sku = 'RIMPAJ002'), 5),"..
"(5761, (select id from catalogo where sku = 'RIMPAJ003'), 3),"..
"(5762, (select id from catalogo where sku = 'RIMPAJ003'), 4),"..
"(5763, (select id from catalogo where sku = 'RIMPAJ003'), 5),"..
"(5764, (select id from catalogo where sku = 'RIMPAJ004'), 3),"..
"(5765, (select id from catalogo where sku = 'RIMPAJ004'), 4),"..
"(5766, (select id from catalogo where sku = 'RIMPAJ004'), 5),"..
"(5767, (select id from catalogo where sku = 'RIMPAJ011'), 3),"..
"(5768, (select id from catalogo where sku = 'RIMPAJ011'), 4),"..
"(5769, (select id from catalogo where sku = 'RIMPAJ011'), 5),"..
"(5770, (select id from catalogo where sku = 'RIMPAJ011XXL'), 6),"..
"(5771, (select id from catalogo where sku = 'RIMPAJ012'), 3),"..
"(5772, (select id from catalogo where sku = 'RIMPAJ012'), 4),"..
"(5773, (select id from catalogo where sku = 'RIMPAJ012'), 5),"..
"(5774, (select id from catalogo where sku = 'RIMPAJ012XXL'), 6),"..
"(5775, (select id from catalogo where sku = 'RIMPAJ013'), 3),"..
"(5776, (select id from catalogo where sku = 'RIMPAJ013'), 4),"..
"(5777, (select id from catalogo where sku = 'RIMPAJ013'), 5),"..
"(5778, (select id from catalogo where sku = 'RIMPAJ013XXL'), 6),"..
"(5779, (select id from catalogo where sku = 'RIMPAJ014'), 3),"..
"(5780, (select id from catalogo where sku = 'RIMPAJ014'), 4),"..
"(5781, (select id from catalogo where sku = 'RIMPAJ014'), 5),"..
"(5782, (select id from catalogo where sku = 'RIMPAJ014XXL'), 6),"..
"(5783, (select id from catalogo where sku = 'RIMPAJ015'), 3),"..
"(5784, (select id from catalogo where sku = 'RIMPAJ015'), 4),"..
"(5785, (select id from catalogo where sku = 'RIMPAJ015'), 5),"..
"(5786, (select id from catalogo where sku = 'RIMPAJ015XXL'), 6),"..
"(5787, (select id from catalogo where sku = 'RIMPNB073'), 2),"..
"(5788, (select id from catalogo where sku = 'RIMPNB073'), 3),"..
"(5789, (select id from catalogo where sku = 'RIMPNB073'), 4),"..
"(5790, (select id from catalogo where sku = 'RIMPNB411'), 2),"..
"(5791, (select id from catalogo where sku = 'RIMPNB411'), 3),"..
"(5792, (select id from catalogo where sku = 'RIMPNB411'), 4),"..
"(5793, (select id from catalogo where sku = 'RIMPNB465'), 2),"..
"(5794, (select id from catalogo where sku = 'RIMPNB465'), 3),"..
"(5795, (select id from catalogo where sku = 'RIMPNB465'), 4),"..
"(5796, (select id from catalogo where sku = 'RIMPNB470'), 2),"..
"(5797, (select id from catalogo where sku = 'RIMPNB470'), 3),"..
"(5798, (select id from catalogo where sku = 'RIMPNB470'), 4),"..
"(5799, (select id from catalogo where sku = 'RIMPNB480'), 2),"..
"(5800, (select id from catalogo where sku = 'RIMPNB480'), 3),"..
"(5801, (select id from catalogo where sku = 'RIMPNB480'), 4),"..
"(5802, (select id from catalogo where sku = 'RIMPNB481'), 2),"..
"(5803, (select id from catalogo where sku = 'RIMPNB481'), 3),"..
"(5804, (select id from catalogo where sku = 'RIMPNB481'), 4),"..
"(5805, (select id from catalogo where sku = 'RIMPNB482'), 2),"..
"(5806, (select id from catalogo where sku = 'RIMPNB482'), 3),"..
"(5807, (select id from catalogo where sku = 'RIMPNB482'), 4),"..
"(5808, (select id from catalogo where sku = 'RIMPNB483'), 2),"..
"(5809, (select id from catalogo where sku = 'RIMPNB483'), 3),"..
"(5810, (select id from catalogo where sku = 'RIMPNB483'), 4),"..
"(5811, (select id from catalogo where sku = 'RIMPNI050'), 2),"..
"(5812, (select id from catalogo where sku = 'RIMPNI050'), 3),"..
"(5813, (select id from catalogo where sku = 'RIMPNI050'), 4),"..
"(5814, (select id from catalogo where sku = 'RIMPNI050'), 5),"..
"(5815, (select id from catalogo where sku = 'RIMPNI051'), 2),"..
"(5816, (select id from catalogo where sku = 'RIMPNI051'), 3),"..
"(5817, (select id from catalogo where sku = 'RIMPNI051'), 4),"..
"(5818, (select id from catalogo where sku = 'RIMPNI051'), 5),"..
"(5819, (select id from catalogo where sku = 'RIMPNI052'), 2),"..
"(5820, (select id from catalogo where sku = 'RIMPNI052'), 3),"..
"(5821, (select id from catalogo where sku = 'RIMPNI052'), 4),"..
"(5822, (select id from catalogo where sku = 'RIMPNI052'), 5),"..
"(5823, (select id from catalogo where sku = 'RIMPNI053'), 2),"..
"(5824, (select id from catalogo where sku = 'RIMPNI053'), 3),"..
"(5825, (select id from catalogo where sku = 'RIMPNI053'), 4),"..
"(5826, (select id from catalogo where sku = 'RIMPNI053'), 5),"..
"(5827, (select id from catalogo where sku = 'RIMPNI054'), 2),"..
"(5828, (select id from catalogo where sku = 'RIMPNI054'), 3),"..
"(5829, (select id from catalogo where sku = 'RIMPNI054'), 4),"..
"(5830, (select id from catalogo where sku = 'RIMPNI054'), 5),"..
"(5831, (select id from catalogo where sku = 'RIMPNI055'), 2),"..
"(5832, (select id from catalogo where sku = 'RIMPNI055'), 3),"..
"(5833, (select id from catalogo where sku = 'RIMPNI055'), 4),"..
"(5834, (select id from catalogo where sku = 'RIMPNI055'), 5),"..
"(5835, (select id from catalogo where sku = 'RIMPNI056'), 2),"..
"(5836, (select id from catalogo where sku = 'RIMPNI056'), 3),"..
"(5837, (select id from catalogo where sku = 'RIMPNI056'), 4),"..
"(5838, (select id from catalogo where sku = 'RIMPNI056'), 5),"..
"(5839, (select id from catalogo where sku = 'RIMPNJ005'), 2),"..
"(5840, (select id from catalogo where sku = 'RIMPNJ005'), 3),"..
"(5841, (select id from catalogo where sku = 'RIMPNJ005'), 4),"..
"(5842, (select id from catalogo where sku = 'RIMPNJ005'), 5),"..
"(5843, (select id from catalogo where sku = 'RIMPNJ006'), 2),"..
"(5844, (select id from catalogo where sku = 'RIMPNJ006'), 3),"..
"(5845, (select id from catalogo where sku = 'RIMPNJ006'), 4),"..
"(5846, (select id from catalogo where sku = 'RIMPNJ006'), 5),"..
"(5847, (select id from catalogo where sku = 'RIMPNJ007'), 2),"..
"(5848, (select id from catalogo where sku = 'RIMPNJ007'), 3),"..
"(5849, (select id from catalogo where sku = 'RIMPNJ007'), 4),"..
"(5850, (select id from catalogo where sku = 'RIMPNJ007'), 5),"..
"(5851, (select id from catalogo where sku = 'RIMPNJ008'), 2),"..
"(5852, (select id from catalogo where sku = 'RIMPNJ008'), 3),"..
"(5853, (select id from catalogo where sku = 'RIMPNJ008'), 4),"..
"(5854, (select id from catalogo where sku = 'RIMPNJ008'), 5),"..
"(5855, (select id from catalogo where sku = 'RIMPNJ009'), 2),"..
"(5856, (select id from catalogo where sku = 'RIMPNJ009'), 3),"..
"(5857, (select id from catalogo where sku = 'RIMPNJ009'), 4),"..
"(5858, (select id from catalogo where sku = 'RIMPNJ009'), 5),"..
"(5859, (select id from catalogo where sku = 'RIMPNJ010'), 2),"..
"(5860, (select id from catalogo where sku = 'RIMPNJ010'), 3),"..
"(5861, (select id from catalogo where sku = 'RIMPNJ010'), 4),"..
"(5862, (select id from catalogo where sku = 'RIMPNJ010'), 5),"..
"(5863, (select id from catalogo where sku = 'RIMSAB00109'), 2),"..
"(5864, (select id from catalogo where sku = 'RIMSAB00109'), 3),"..
"(5865, (select id from catalogo where sku = 'RIMSAB00109'), 4),"..
"(5866, (select id from catalogo where sku = 'RIMSAB00109'), 5),"..
"(5867, (select id from catalogo where sku = 'RIMSAB00111'), 2),"..
"(5868, (select id from catalogo where sku = 'RIMSAB00111'), 3),"..
"(5869, (select id from catalogo where sku = 'RIMSAB00111'), 4),"..
"(5870, (select id from catalogo where sku = 'RIMSAB00111'), 5),"..
"(5871, (select id from catalogo where sku = 'RIMSAB00113'), 2),"..
"(5872, (select id from catalogo where sku = 'RIMSAB00113'), 3),"..
"(5873, (select id from catalogo where sku = 'RIMSAB00113'), 4),"..
"(5874, (select id from catalogo where sku = 'RIMSAB00113'), 5),"..
"(5875, (select id from catalogo where sku = 'RIMSAB00117'), 2),"..
"(5876, (select id from catalogo where sku = 'RIMSAB00117'), 3),"..
"(5877, (select id from catalogo where sku = 'RIMSAB00117'), 4),"..
"(5878, (select id from catalogo where sku = 'RIMSAB00117'), 5),"..
"(5879, (select id from catalogo where sku = 'RIMSAB00138'), 2),"..
"(5880, (select id from catalogo where sku = 'RIMSAB00138'), 3),"..
"(5881, (select id from catalogo where sku = 'RIMSAB00138'), 4),"..
"(5882, (select id from catalogo where sku = 'RIMSAB00138'), 5),"..
"(5883, (select id from catalogo where sku = 'RIMSAB00140'), 2),"..
"(5884, (select id from catalogo where sku = 'RIMSAB00140'), 3),"..
"(5885, (select id from catalogo where sku = 'RIMSAB00140'), 4),"..
"(5886, (select id from catalogo where sku = 'RIMSAB00140'), 5),"..
"(5887, (select id from catalogo where sku = 'RIMSAB00171'), 2),"..
"(5888, (select id from catalogo where sku = 'RIMSAB00171'), 3),"..
"(5889, (select id from catalogo where sku = 'RIMSAB00171'), 4),"..
"(5890, (select id from catalogo where sku = 'RIMSAB00171'), 5),"..
"(5891, (select id from catalogo where sku = 'RIMSAB001XXL09'), 6),"..
"(5892, (select id from catalogo where sku = 'RIMSAB001XXL11'), 6),"..
"(5893, (select id from catalogo where sku = 'RIMSAB001XXL13'), 6),"..
"(5894, (select id from catalogo where sku = 'RIMSAB001XXL17'), 6),"..
"(5895, (select id from catalogo where sku = 'RIMSAB001XXL29'), 6),"..
"(5896, (select id from catalogo where sku = 'RIMSAB001XXL38'), 6),"..
"(5897, (select id from catalogo where sku = 'RIMSAB001XXL40'), 6),"..
"(5898, (select id from catalogo where sku = 'RIMSAB001XXL71'), 6),"..
"(5899, (select id from catalogo where sku = 'RIMSNB00109'), 2),"..
"(5900, (select id from catalogo where sku = 'RIMSNB00109'), 3),"..
"(5901, (select id from catalogo where sku = 'RIMSNB00109'), 4),"..
"(5902, (select id from catalogo where sku = 'RIMSNB00109'), 5);"
db:exec( query2 )
--fase 40
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(5903, (select id from catalogo where sku = 'RIMSNB00111'), 2),"..
"(5904, (select id from catalogo where sku = 'RIMSNB00111'), 3),"..
"(5905, (select id from catalogo where sku = 'RIMSNB00111'), 4),"..
"(5906, (select id from catalogo where sku = 'RIMSNB00111'), 5),"..
"(5907, (select id from catalogo where sku = 'RIMSNB00113'), 2),"..
"(5908, (select id from catalogo where sku = 'RIMSNB00113'), 3),"..
"(5909, (select id from catalogo where sku = 'RIMSNB00113'), 4),"..
"(5910, (select id from catalogo where sku = 'RIMSNB00113'), 5),"..
"(5911, (select id from catalogo where sku = 'RIMVCOV0303'), 2),"..
"(5912, (select id from catalogo where sku = 'RIMVCOV0303'), 3),"..
"(5913, (select id from catalogo where sku = 'RIMVCOV0303'), 4),"..
"(5914, (select id from catalogo where sku = 'RIMVCOV0303'), 5),"..
"(5915, (select id from catalogo where sku = 'RIMVCOV0304'), 2),"..
"(5916, (select id from catalogo where sku = 'RIMVCOV0304'), 3),"..
"(5917, (select id from catalogo where sku = 'RIMVCOV0304'), 4),"..
"(5918, (select id from catalogo where sku = 'RIMVCOV0304'), 5),"..
"(5919, (select id from catalogo where sku = 'RIMVCOV0311'), 2),"..
"(5920, (select id from catalogo where sku = 'RIMVCOV0311'), 3),"..
"(5921, (select id from catalogo where sku = 'RIMVCOV0311'), 4),"..
"(5922, (select id from catalogo where sku = 'RIMVCOV0311'), 5),"..
"(5923, (select id from catalogo where sku = 'RIMVCOV0313'), 2),"..
"(5924, (select id from catalogo where sku = 'RIMVCOV0313'), 3),"..
"(5925, (select id from catalogo where sku = 'RIMVCOV0313'), 4),"..
"(5926, (select id from catalogo where sku = 'RIMVCOV0313'), 5),"..
"(5927, (select id from catalogo where sku = 'RIMVCOV0316'), 2),"..
"(5928, (select id from catalogo where sku = 'RIMVCOV0316'), 3),"..
"(5929, (select id from catalogo where sku = 'RIMVCOV0316'), 4),"..
"(5930, (select id from catalogo where sku = 'RIMVCOV0316'), 5),"..
"(5931, (select id from catalogo where sku = 'RIMVCOV0329'), 2),"..
"(5932, (select id from catalogo where sku = 'RIMVCOV0329'), 3),"..
"(5933, (select id from catalogo where sku = 'RIMVCOV0329'), 4),"..
"(5934, (select id from catalogo where sku = 'RIMVCOV0329'), 5),"..
"(5935, (select id from catalogo where sku = 'RIMVCOV0330'), 2),"..
"(5936, (select id from catalogo where sku = 'RIMVCOV0330'), 3),"..
"(5937, (select id from catalogo where sku = 'RIMVCOV0330'), 4),"..
"(5938, (select id from catalogo where sku = 'RIMVCOV0330'), 5),"..
"(5939, (select id from catalogo where sku = 'RIMVCOV0337'), 2),"..
"(5940, (select id from catalogo where sku = 'RIMVCOV0337'), 3),"..
"(5941, (select id from catalogo where sku = 'RIMVCOV0337'), 4),"..
"(5942, (select id from catalogo where sku = 'RIMVCOV0337'), 5),"..
"(5943, (select id from catalogo where sku = 'RIMVIBSAN03'), 8),"..
"(5944, (select id from catalogo where sku = 'RIMVIBSAN04'), 8),"..
"(5945, (select id from catalogo where sku = 'RIMVIBSAN11'), 8),"..
"(5946, (select id from catalogo where sku = 'RIMVIBSAN13'), 8),"..
"(5947, (select id from catalogo where sku = 'RIMVIBSAN16'), 8),"..
"(5948, (select id from catalogo where sku = 'RIMVIBSAN29'), 8),"..
"(5949, (select id from catalogo where sku = 'RIMVIBSAN30'), 8),"..
"(5950, (select id from catalogo where sku = 'RIMVIBSAN37'), 8),"..
"(5951, (select id from catalogo where sku = 'RIPGMBDES02'), 8),"..
"(5952, (select id from catalogo where sku = 'RIPGMBDES04'), 8),"..
"(5953, (select id from catalogo where sku = 'RIPGMBDES05'), 8),"..
"(5954, (select id from catalogo where sku = 'RIPGMBDES06'), 8),"..
"(5955, (select id from catalogo where sku = 'RIPGMBDES09'), 8),"..
"(5956, (select id from catalogo where sku = 'RIPGMBDES10'), 8),"..
"(5957, (select id from catalogo where sku = 'RIPGMBDES11'), 8),"..
"(5958, (select id from catalogo where sku = 'RIPGMBDES12'), 8),"..
"(5959, (select id from catalogo where sku = 'RIPGMBDES13'), 8),"..
"(5960, (select id from catalogo where sku = 'RIPGMBDES15'), 8),"..
"(5961, (select id from catalogo where sku = 'RIPGMBDES16'), 8),"..
"(5962, (select id from catalogo where sku = 'RIPGMBDES17'), 8),"..
"(5963, (select id from catalogo where sku = 'RIPGMBDES21'), 8),"..
"(5964, (select id from catalogo where sku = 'RIPGMBDES25'), 8),"..
"(5965, (select id from catalogo where sku = 'RIPGMBDES26'), 8),"..
"(5966, (select id from catalogo where sku = 'RIPGMBDES28'), 8),"..
"(5967, (select id from catalogo where sku = 'RIPGMBDES29'), 8),"..
"(5968, (select id from catalogo where sku = 'RIPGMBDES30'), 8),"..
"(5969, (select id from catalogo where sku = 'RIPGMBDES31'), 8),"..
"(5970, (select id from catalogo where sku = 'RIPGMBDES32'), 8),"..
"(5971, (select id from catalogo where sku = 'RIPGMBDES34'), 8),"..
"(5972, (select id from catalogo where sku = 'RIPGMBDES35'), 8),"..
"(5973, (select id from catalogo where sku = 'RIPGMBDES37'), 8),"..
"(5974, (select id from catalogo where sku = 'RIPGMBSAN02'), 8),"..
"(5975, (select id from catalogo where sku = 'RIPGMBSAN03'), 8),"..
"(5976, (select id from catalogo where sku = 'RIPGMBSAN04'), 8),"..
"(5977, (select id from catalogo where sku = 'RIPGMBSAN05'), 8),"..
"(5978, (select id from catalogo where sku = 'RIPGMBSAN07'), 8),"..
"(5979, (select id from catalogo where sku = 'RIPGMBSAN11'), 8),"..
"(5980, (select id from catalogo where sku = 'RIPGMBSAN13'), 8),"..
"(5981, (select id from catalogo where sku = 'RIPGMBSAN20'), 8),"..
"(5982, (select id from catalogo where sku = 'RIPGMBSAN22'), 8),"..
"(5983, (select id from catalogo where sku = 'RIPGMBSAN30'), 8),"..
"(5984, (select id from catalogo where sku = 'RIPGMBSAN32'), 8),"..
"(5985, (select id from catalogo where sku = 'RIPGMBSAN33'), 8),"..
"(5986, (select id from catalogo where sku = 'RIPGMBSAN36'), 8),"..
"(5987, (select id from catalogo where sku = 'RIPGMBSAN39'), 8),"..
"(5988, (select id from catalogo where sku = 'RIPGMBSAN43'), 8),"..
"(5989, (select id from catalogo where sku = 'RIPGMBSAN45'), 8),"..
"(5990, (select id from catalogo where sku = 'RIPGMBSAN47'), 8),"..
"(5991, (select id from catalogo where sku = 'RIPGMBSAN49'), 8),"..
"(5992, (select id from catalogo where sku = 'RIPGMBSAN51'), 8),"..
"(5993, (select id from catalogo where sku = 'RIPGMBSAN83'), 8),"..
"(5994, (select id from catalogo where sku = 'ROYGMBDES04'), 8),"..
"(5995, (select id from catalogo where sku = 'ROYGMBDES05'), 8),"..
"(5996, (select id from catalogo where sku = 'ROYGMBDES06'), 8),"..
"(5997, (select id from catalogo where sku = 'ROYGMBDES10'), 8),"..
"(5998, (select id from catalogo where sku = 'ROYGMBDES11'), 8),"..
"(5999, (select id from catalogo where sku = 'ROYGMBDES12'), 8),"..
"(6000, (select id from catalogo where sku = 'ROYGMBDES13'), 8),"..
"(6001, (select id from catalogo where sku = 'ROYGMBDES15'), 8),"..
"(6002, (select id from catalogo where sku = 'ROYGMBDES16'), 8),"..
"(6003, (select id from catalogo where sku = 'ROYGMBDES21'), 8),"..
"(6004, (select id from catalogo where sku = 'ROYGMBDES25'), 8),"..
"(6005, (select id from catalogo where sku = 'ROYGMBDES26'), 8),"..
"(6006, (select id from catalogo where sku = 'ROYGMBDES28'), 8),"..
"(6007, (select id from catalogo where sku = 'ROYGMBDES30'), 8),"..
"(6008, (select id from catalogo where sku = 'ROYGMBDES32'), 8),"..
"(6009, (select id from catalogo where sku = 'ROYGMBDES34'), 8),"..
"(6010, (select id from catalogo where sku = 'ROYGMBDES35'), 8),"..
"(6011, (select id from catalogo where sku = 'ROYGMBDES37'), 8),"..
"(6012, (select id from catalogo where sku = 'ROYGMBSAN02'), 8),"..
"(6013, (select id from catalogo where sku = 'ROYGMBSAN03'), 8),"..
"(6014, (select id from catalogo where sku = 'ROYGMBSAN05'), 8),"..
"(6015, (select id from catalogo where sku = 'ROYGMBSAN06'), 8),"..
"(6016, (select id from catalogo where sku = 'ROYGMBSAN07'), 8),"..
"(6017, (select id from catalogo where sku = 'ROYGMBSAN11'), 8),"..
"(6018, (select id from catalogo where sku = 'ROYGMBSAN13'), 8),"..
"(6019, (select id from catalogo where sku = 'ROYGMBSAN20'), 8),"..
"(6020, (select id from catalogo where sku = 'ROYGMBSAN22'), 8),"..
"(6021, (select id from catalogo where sku = 'ROYGMBSAN30'), 8),"..
"(6022, (select id from catalogo where sku = 'ROYGMBSAN32'), 8),"..
"(6023, (select id from catalogo where sku = 'ROYGMBSAN33'), 8),"..
"(6024, (select id from catalogo where sku = 'ROYGMBSAN36'), 8),"..
"(6025, (select id from catalogo where sku = 'ROYGMBSAN39'), 8),"..
"(6026, (select id from catalogo where sku = 'ROYGMBSAN43'), 8),"..
"(6027, (select id from catalogo where sku = 'ROYGMBSAN45'), 8),"..
"(6028, (select id from catalogo where sku = 'ROYGMBSAN49'), 8),"..
"(6029, (select id from catalogo where sku = 'ROYGMBSAN51'), 8),"..
"(6030, (select id from catalogo where sku = 'VIPCOA00102'), 2),"..
"(6031, (select id from catalogo where sku = 'VIPCOA00102'), 3),"..
"(6032, (select id from catalogo where sku = 'VIPCOA00102'), 4),"..
"(6033, (select id from catalogo where sku = 'VIPCOA00102'), 5),"..
"(6034, (select id from catalogo where sku = 'VIPCOA00105'), 2),"..
"(6035, (select id from catalogo where sku = 'VIPCOA00105'), 3),"..
"(6036, (select id from catalogo where sku = 'VIPCOA00105'), 4),"..
"(6037, (select id from catalogo where sku = 'VIPCOA00105'), 5),"..
"(6038, (select id from catalogo where sku = 'VIPCOA00106'), 2),"..
"(6039, (select id from catalogo where sku = 'VIPCOA00106'), 3),"..
"(6040, (select id from catalogo where sku = 'VIPCOA00106'), 4),"..
"(6041, (select id from catalogo where sku = 'VIPCOA00106'), 5),"..
"(6042, (select id from catalogo where sku = 'VIPCOA00110'), 2),"..
"(6043, (select id from catalogo where sku = 'VIPCOA00110'), 3),"..
"(6044, (select id from catalogo where sku = 'VIPCOA00110'), 4),"..
"(6045, (select id from catalogo where sku = 'VIPCOA00110'), 5),"..
"(6046, (select id from catalogo where sku = 'VIPCOA00111'), 2),"..
"(6047, (select id from catalogo where sku = 'VIPCOA00111'), 3),"..
"(6048, (select id from catalogo where sku = 'VIPCOA00111'), 4),"..
"(6049, (select id from catalogo where sku = 'VIPCOA00111'), 5),"..
"(6050, (select id from catalogo where sku = 'VIPCOA00112'), 2),"..
"(6051, (select id from catalogo where sku = 'VIPCOA00112'), 3),"..
"(6052, (select id from catalogo where sku = 'VIPCOA00112'), 4),"..
"(6053, (select id from catalogo where sku = 'VIPCOA00112'), 5);"
db:exec( query2 )
--fase 41
query2 = "INSERT INTO refcatalogotalla VALUES " ..
"(6054, (select id from catalogo where sku = 'VIPCOA00113'), 2),"..
"(6055, (select id from catalogo where sku = 'VIPCOA00113'), 3),"..
"(6056, (select id from catalogo where sku = 'VIPCOA00113'), 4),"..
"(6057, (select id from catalogo where sku = 'VIPCOA00113'), 5),"..
"(6058, (select id from catalogo where sku = 'VIPCOA00115'), 2),"..
"(6059, (select id from catalogo where sku = 'VIPCOA00115'), 3),"..
"(6060, (select id from catalogo where sku = 'VIPCOA00115'), 4),"..
"(6061, (select id from catalogo where sku = 'VIPCOA00115'), 5),"..
"(6062, (select id from catalogo where sku = 'VIPCOA00121'), 2),"..
"(6063, (select id from catalogo where sku = 'VIPCOA00121'), 3),"..
"(6064, (select id from catalogo where sku = 'VIPCOA00121'), 4),"..
"(6065, (select id from catalogo where sku = 'VIPCOA00121'), 5),"..
"(6066, (select id from catalogo where sku = 'VIPCOA00125'), 2),"..
"(6067, (select id from catalogo where sku = 'VIPCOA00125'), 3),"..
"(6068, (select id from catalogo where sku = 'VIPCOA00125'), 4),"..
"(6069, (select id from catalogo where sku = 'VIPCOA00125'), 5),"..
"(6070, (select id from catalogo where sku = 'VIPCOA00126'), 2),"..
"(6071, (select id from catalogo where sku = 'VIPCOA00126'), 3),"..
"(6072, (select id from catalogo where sku = 'VIPCOA00126'), 4),"..
"(6073, (select id from catalogo where sku = 'VIPCOA00126'), 5),"..
"(6074, (select id from catalogo where sku = 'VIPCOA00128'), 2),"..
"(6075, (select id from catalogo where sku = 'VIPCOA00128'), 3),"..
"(6076, (select id from catalogo where sku = 'VIPCOA00128'), 4),"..
"(6077, (select id from catalogo where sku = 'VIPCOA00128'), 5),"..
"(6078, (select id from catalogo where sku = 'VIPCOA00130'), 2),"..
"(6079, (select id from catalogo where sku = 'VIPCOA00130'), 3),"..
"(6080, (select id from catalogo where sku = 'VIPCOA00130'), 4),"..
"(6081, (select id from catalogo where sku = 'VIPCOA00130'), 5),"..
"(6082, (select id from catalogo where sku = 'VIPCOA00132'), 2),"..
"(6083, (select id from catalogo where sku = 'VIPCOA00132'), 3),"..
"(6084, (select id from catalogo where sku = 'VIPCOA00132'), 4),"..
"(6085, (select id from catalogo where sku = 'VIPCOA00132'), 5),"..
"(6086, (select id from catalogo where sku = 'VIPCOA00134'), 2),"..
"(6087, (select id from catalogo where sku = 'VIPCOA00134'), 3),"..
"(6088, (select id from catalogo where sku = 'VIPCOA00134'), 4),"..
"(6089, (select id from catalogo where sku = 'VIPCOA00134'), 5),"..
"(6090, (select id from catalogo where sku = 'VIPCOA00135'), 2),"..
"(6091, (select id from catalogo where sku = 'VIPCOA00135'), 3),"..
"(6092, (select id from catalogo where sku = 'VIPCOA00135'), 4),"..
"(6093, (select id from catalogo where sku = 'VIPCOA00135'), 5),"..
"(6094, (select id from catalogo where sku = 'VIPCOA001XXL02'), 6),"..
"(6095, (select id from catalogo where sku = 'VIPCOA001XXL05'), 6),"..
"(6096, (select id from catalogo where sku = 'VIPCOA001XXL06'), 6),"..
"(6097, (select id from catalogo where sku = 'VIPCOA001XXL10'), 6),"..
"(6098, (select id from catalogo where sku = 'VIPCOA001XXL11'), 6),"..
"(6099, (select id from catalogo where sku = 'VIPCOA001XXL12'), 6),"..
"(6100, (select id from catalogo where sku = 'VIPCOA001XXL13'), 6),"..
"(6101, (select id from catalogo where sku = 'VIPCOA001XXL15'), 6),"..
"(6102, (select id from catalogo where sku = 'VIPCOA001XXL21'), 6),"..
"(6103, (select id from catalogo where sku = 'VIPCOA001XXL25'), 6),"..
"(6104, (select id from catalogo where sku = 'VIPCOA001XXL26'), 6),"..
"(6105, (select id from catalogo where sku = 'VIPCOA001XXL28'), 6),"..
"(6106, (select id from catalogo where sku = 'VIPCOA001XXL30'), 6),"..
"(6107, (select id from catalogo where sku = 'VIPCOA001XXL32'), 6),"..
"(6108, (select id from catalogo where sku = 'VIPCOA001XXL34'), 6),"..
"(6109, (select id from catalogo where sku = 'VIPCOA001XXL35'), 6),"..
"(6110, (select id from catalogo where sku = 'VIPVIBSAN03'), 8),"..
"(6111, (select id from catalogo where sku = 'VIPVIBSAN04'), 8),"..
"(6112, (select id from catalogo where sku = 'VIPVIBSAN11'), 8),"..
"(6113, (select id from catalogo where sku = 'VIPVIBSAN13'), 8),"..
"(6114, (select id from catalogo where sku = 'VIPVIBSAN16'), 8),"..
"(6115, (select id from catalogo where sku = 'VIPVIBSAN29'), 8),"..
"(6116, (select id from catalogo where sku = 'VIPVIBSAN30'), 8),"..
"(6117, (select id from catalogo where sku = 'VIPVIBSAN37'), 8),"..
"(6118, (select id from catalogo where sku = 'GV 300'), 8),"..
"(6121, (select id from catalogo where sku = 'pa250tcn-xxx'), 2),"..
"(6122, (select id from catalogo where sku = 'pa250tcn-xxx'), 3),"..
"(6123, (select id from catalogo where sku = 'pa250tcn-xxx'), 4),"..
"(6124, (select id from catalogo where sku = 'RIMPBE165'), 2),"..
"(6125, (select id from catalogo where sku = 'RIMPBE165'), 3),"..
"(6126, (select id from catalogo where sku = 'RIMPBE165'), 4),"..
"(6127, (select id from catalogo where sku = 'RIMPBE165'), 5);"

db:exec( query2 )
		

		--llenar con los datos de los colores
		query2 = "INSERT INTO color VALUES " .. 
        "(1, 'ARENA'), "..
		"(2, 'BEIGE'), " .. 
		"(3, 'BLANCO'), " .. 
		"(4, 'CELESTE'), " .. 
		"(5, 'BEIGE / MARINO'), " .. 
		"(6, 'BEIGE / BARK'), " .. 
		"(7, 'BEIGE / MARINO / BEIGE'), " .. 
		"(8, 'DELFIN'), " ..
		"(9, 'GRIS'), " ..
		"(10, 'MANGO'), " ..
		"(11, 'MARINO'); "
		db:exec( query2 )

		--llenar con los datos de los colores de los productos
		query2 = "INSERT INTO refcatalogocolor VALUES " .. 
        "(1, 1, 3), "..
		"(2, 2, 11), " .. 
		"(3, 3, 3); "
		db:exec( query2 )


		--REGISTRO CLIENTES
		query2 = "INSERT INTO cliente VALUES " .. 
		"(1,4,(select trim('30')),(select trim('SERVICIOS DE OPERACIONES HOTELERAS S.A D')),(select trim('logoshop@originalresorts.com')),(select trim('')),1),"..
		"(2,6,(select trim('42')),(select trim('TIFFANYS DE MEXICO S.A.DE C.V.')),(select trim('aespinosa@realresorts.com')),(select trim('8817300')),1),"..
		"(3,9,(select trim('55')),(select trim('OP. DE RESTAURANTES Y SUPERMERCADOS COST')),(select trim('pvargas75@hotmail.com')),(select trim('85 38 05 8853904')),1),"..
		"(4,10,(select trim('64')),(select trim('OPERADORA SUPER GOURMET S.A.DE C.V')),(select trim('ddelltam@hotmail.com')),(select trim('83-44-71 AL 75')),1),"..
		"(5,11,(select trim('65')),(select trim('OPERADORA SUPER GOURMET S.A.DE C.V')),(select trim('ddelltam@hotmail.com')),(select trim('')),1),"..
		"(6,12,(select trim('70')),(select trim('ALTER COMERCIAL S.A. DE C.V')),(select trim('mmartinez@altercomercial.com')),(select trim('01-555-813-00-06')),1),"..
		"(7,13,(select trim('97')),(select trim('SERVICIOS DE OPERACIONES HOTELERAS S.A.')),(select trim('logoshop@originalresorts.com')),(select trim('8 48 79 00 EXT. 1521')),1),"..
		"(8,14,(select trim('100')),(select trim('ARI ADLER BROTMAN')),(select trim('aadler@prodigy.net.mx')),(select trim('8833229')),1),"..
		"(9,15,(select trim('129')),(select trim('SUPER GOURMET LA ISLA, S.A DE C.V.')),(select trim('lennyvargashe@hotmail.com')),(select trim('83-55-00')),1),"..
		"(10,18,(select trim('229')),(select trim('BJM DELIVERY S.A. DE C.V.')),(select trim('tesoreria@aquaworld.com.mx')),(select trim('848 83 00  EXT.8108')),1),"..
		"(11,19,(select trim('242')),(select trim('RIVERA MAYAN S.A DE C.V')),(select trim('facturaelectronica.cun@grupovidanta.com')),(select trim('Q.ROO  019842064000')),1),"..
		"(12,20,(select trim('305')),(select trim('ABASTECEDORA CANCUN, S.A. DE C.V.')),(select trim('facturas@royalresorts.com')),(select trim('881 01 00')),1),"..
		"(13,23,(select trim('313')),(select trim('SERVICIOS DE OPERACIONES HOTELERAS S.A D')),(select trim('logoshop@originalresorts.com')),(select trim('8487900')),1),"..
		"(14,25,(select trim('370')),(select trim('DISTRIBUCIONES GP. SA. DE CV')),(select trim('franciscopech@yahoo.com')),(select trim('8833688  EXT 103')),1),"..
		"(15,26,(select trim('450')),(select trim('SABELDOS, S.A. DE C.V.')),(select trim('mexico.cxp1@hoteles-catalonia.es')),(select trim('0198487 51-020')),1),"..
		"(16,29,(select trim('481')),(select trim('OPERADORA AERO-BOUTIQUES SA DE CV')),(select trim('fact_elect_ger@areasmail.com')),(select trim('')),1),"..
		"(17,37,(select trim('518')),(select trim('OPERADORA TURISTICA EL CID RIVIERA MAYA')),(select trim('cxpotrm@elcid.com.mx')),(select trim('8728999')),1),"..
		"(18,40,(select trim('584')),(select trim('SERVICIOS MARITIMOS Y ACUATICOS DEL CARI')),(select trim('rachelescandell@hotmail.com')),(select trim('8 494746')),1),"..
		"(19,44,(select trim('596')),(select trim('DELI LA ISLA, S.A DE C.V')),(select trim('lennyvargashe@hotmail.com')),(select trim('8835500')),1),"..
		"(20,46,(select trim('599')),(select trim('EVENT SOLUTIONS SA DE CV.')),(select trim('nerea@corporativogourmet.com')),(select trim('8491612')),1),"..
		"(21,52,(select trim('623')),(select trim('SOL MAR CARIBE S.A. DE C.V.')),(select trim('solmarfacturas@haciendatequila.com.mx')),(select trim('(01984) 8 03 17 79')),1),"..
		"(22,53,(select trim('624')),(select trim('AZUL MAR DEL CARIBE S.A. DE C.V.')),(select trim('azulmarfacturas@haciendatequila.com.mx')),(select trim('(01984) 8 03 17 79')),1),"..
		"(23,57,(select trim('628')),(select trim('SUPERMERCADO DEL CARIBE S.A. DE C.V.')),(select trim('supermercadofacturas@haciendatequila.com.mx')),(select trim('01984 80 3 17 79')),1),"..
		"(24,60,(select trim('639')),(select trim('INVENTOS Y TESOROS S.A DE C.V.')),(select trim('crodriguez@inventosytesoros.com')),(select trim('8728450')),1),"..
		"(25,62,(select trim('648')),(select trim('CONFETI CARIBE S.A DE C.V.')),(select trim('confetItresrios@yahoo.com.mx')),(select trim('19848772400')),1),"..
		"(26,64,(select trim('657')),(select trim('PROMOTORA DE INMUEBLES DEL CARIBE S. A D')),(select trim('cxpcun@park-royalhotels.com')),(select trim('8851333')),1),"..
		"(27,67,(select trim('661')),(select trim('BCO TUCANCUN S. DE R.L. DE C.V.')),(select trim('tucancun.costos@barcelo.com')),(select trim('8 915900 EXT. 5902')),1),"..
		"(28,68,(select trim('662')),(select trim('OPERADORA XPETIA DEL SUR, S.A DE C.V')),(select trim('')),(select trim('')),1),"..
		"(29,77,(select trim('676')),(select trim('AZUL Y SOL, S.A DE C.V.')),(select trim('')),(select trim('CEL.9985774551')),1),"..
		"(30,78,(select trim('677')),(select trim('SUPERINTENDENTES DE CAMPO DE GOLF DE MEX')),(select trim('')),(select trim('')),1),"..
		"(31,93,(select trim('682')),(select trim('REMTEX, S.A DE C.V.')),(select trim('remtexempresa@prodigy.net.mx')),(select trim('8835109')),1),"..
		"(32,94,(select trim('683')),(select trim('TPE, S.A DE C.V.')),(select trim('tpeempresa@prodigy.net.mx')),(select trim('883 51 09')),1),"..
		"(33,99,(select trim('688')),(select trim('OPERADORA CARIBEÑA DE INMUEBLES, S.A. DE')),(select trim('proveedoresoci@oasishoteles.com')),(select trim('')),1),"..
		"(34,100,(select trim('689')),(select trim('NAVIERA OCEAN GM SA DE CV')),(select trim('cxp@granpuerto.com.mx')),(select trim('8 81 58 90')),1),"..
		"(35,104,(select trim('693')),(select trim('GIOMAYAL, S.A DE C.V.')),(select trim('segio_verdi@grupopresidente.com')),(select trim('019878729500 EXT. 6230.')),1),"..
		"(36,105,(select trim('694')),(select trim('OPERADORA DE HOTELES DE LUJO, S.A DE C.V')),(select trim('')),(select trim('1931770')),1),"..
		"(37,109,(select trim('698')),(select trim('CORPORATIVO ENIDAN DEL CARIBE, S.A DE C.')),(select trim('nadersalim@msn.com')),(select trim('8831259')),1),"..
		"(38,110,(select trim('699')),(select trim('NAJIM DEL CARIBE, S.A DE C.V')),(select trim('nadersalim@msn.com')),(select trim('8831259')),1),"..
		"(39,112,(select trim('701')),(select trim('LIDYON S.A DE C.V.')),(select trim('maurita31@hotmail.com')),(select trim('998 163 92 48')),1),"..
		"(40,116,(select trim('705')),(select trim('OPERADORA DE MARINAS S.A DE C.V.')),(select trim('rrodriguez@albatrossailaway.com')),(select trim('9987353074')),1),"..
		"(41,129,(select trim('719')),(select trim('PROMOTORES INMOBILIARIOS EL CARACOL,S.A')),(select trim('facturas@omnicancun.com.mx')),(select trim('')),1),"..
		"(42,131,(select trim('721')),(select trim('JCVGOLF, S.A DE C.V.')),(select trim('ivan.dominguez@jcvgolf.com')),(select trim('')),1),"..
		"(43,133,(select trim('723')),(select trim('OPERADORA HOTELERA VILLA GROUP CANCUN, S')),(select trim('cpagarcancun@villagroup.com')),(select trim('1932600')),1),"..
		"(44,135,(select trim('725')),(select trim('PROMOTORA HOTELERA  ORIGINAL, S.A. DE C.')),(select trim('sdelapena@originalresorts.com')),(select trim('')),1),"..
		"(45,137,(select trim('727')),(select trim('VALENTIN PLAYA DEL SECRETO S.A DE C.V.')),(select trim('costos.vim@valentinmaya.com')),(select trim('019842063670  EXT. 3661')),1),"..
		"(46,140,(select trim('730')),(select trim('BOUTIKIS DE ORO, S.A DE C.V.')),(select trim('facturasboutikis@gmail.com')),(select trim('8810088 EXT. 6695')),1),"..
		"(47,150,(select trim('741')),(select trim('OASIS RESORTS, S.A DE C.V')),(select trim('proveedoresocancun@oasishoteles.com')),(select trim('')),1),"..
		"(48,152,(select trim('743')),(select trim('ARENA DE VERANO, S.A DE C.V.')),(select trim('administracion2@qbaycancun.com')),(select trim('')),1),"..
		"(49,157,(select trim('748')),(select trim('MANAGEMET GROUP, S.A DE C.V.')),(select trim('logoshop@seaadventure.com')),(select trim('8817962')),1),"..
		"(50,162,(select trim('753')),(select trim('OPERADORA TURISTICA HOTELERA, S.A DE C.V')),(select trim('')),(select trim('')),1),"..
		"(51,165,(select trim('756')),(select trim('GRUPO OPERADOR RENFER, S.A DE C.V.')),(select trim('')),(select trim('')),1),"..
		"(52,171,(select trim('762')),(select trim('OPERADORA DIESTRA CANCUN, S.A DE C.V')),(select trim('Cancun.cxp@hotelesemporio.com')),(select trim('')),1),"..
		"(53,175,(select trim('766')),(select trim('GRUPO VIA DELPHI, S.A DE C.V.')),(select trim('ezequiel.colin@delphinus.com.mx')),(select trim('')),1),"..
		"(54,178,(select trim('769')),(select trim('ORQUIDEA RESORTS, S.A DE C.V.')),(select trim('proveedoresocancun@oasishoteles.com')),(select trim('')),1),"..
		"(55,179,(select trim('770')),(select trim('ALEJANDRO MOREDIA LOPEZ')),(select trim('cecilialujambio86@gmail.com')),(select trim('9981253794')),1),"..
		"(56,180,(select trim('771')),(select trim('VAL BREN DE MEXICO SA DE CV')),(select trim('e.mendoza@valbren.com')),(select trim('8 43 30 00')),1),"..
		"(57,186,(select trim('777')),(select trim('OPERADORA NEW LIFE, S.A DE C.V.')),(select trim('cfdi_onl@originalresorts.com')),(select trim('')),1);"
		db:exec( query2 ) 

		--REGISTRO SUCURSALES llenar con los datos de los sucursales

		query2 = "INSERT INTO sucursal VALUES " ..
		"(1,24,(select trim('XXXX')),(select trim('Sucursal SEA ADVENTUR   PTO. JUAREZ')),(select trim('4')),1),"..
		"(2,47,(select trim('XXXX')),(select trim('Sucursal TIFANYS DE MEXICO S.A. DE C.V.')),(select trim('6')),1),"..
		"(3,48,(select trim('1')),(select trim('PORTO REAL- TGPR')),(select trim('6')),1),"..
		"(4,49,(select trim('2')),(select trim('ROYAL PORTO-  TROYA')),(select trim('6')),1),"..
		"(5,50,(select trim('3')),(select trim('ALMACEN GENERAL-CANCUN TGRAL')),(select trim('6')),1),"..
		"(6,51,(select trim('4')),(select trim('REAL BAZAR PLAYA DEL CARMEN- TPC')),(select trim('6')),1),"..
		"(7,52,(select trim('8')),(select trim('ALMACEN GENERAL-PLAYA   ( TALMP)')),(select trim('6')),1),"..
		"(8,66,(select trim('XXXX')),(select trim('Sucursal OP. DE RESTAURANTES Y SUPERMERCADOS COST')),(select trim('9')),1),"..
		"(9,67,(select trim('XXXX')),(select trim('Sucursal OPERADORA SUPER GOURMET S.A. DE C.V')),(select trim('10')),1),"..
		"(10,68,(select trim('XXXX')),(select trim('Sucursal OPERADORA SUPER GOURMET S.A. DE C.V')),(select trim('11')),1),"..
		"(11,69,(select trim('XXXX')),(select trim('Sucursal ALTER COMERCIAL S.A. DE C.V')),(select trim('12')),1),"..
		"(12,70,(select trim('1')),(select trim('FIESTA AMERICANA CONDESA CANCUN')),(select trim('12')),1),"..
		"(13,71,(select trim('2')),(select trim('FIESTA AMERICANA COZUMEL')),(select trim('12')),1),"..
		"(14,74,(select trim('5')),(select trim('DELI CANCUN')),(select trim('12')),1),"..
		"(15,73,(select trim('4')),(select trim('FIESTA AMERICANA CANCUN')),(select trim('12')),1),"..
		"(16,75,(select trim('XXXX')),(select trim('Sucursal TEMPTATION')),(select trim('13')),1),"..
		"(17,76,(select trim('1')),(select trim('PTO.JUAREZ')),(select trim('13')),1),"..
		"(18,77,(select trim('2')),(select trim('PTO.MORELOS')),(select trim('13')),1),"..
		"(19,78,(select trim('XXXX')),(select trim('Sucursal ARI ADLER BROTMAN')),(select trim('14')),1),"..
		"(20,79,(select trim('1')),(select trim('CARACOL')),(select trim('14')),1),"..
		"(21,80,(select trim('2')),(select trim('SOLARIS')),(select trim('14')),1),"..
		"(22,81,(select trim('3')),(select trim('COSTA MAYA')),(select trim('14')),1),"..
		"(23,82,(select trim('4')),(select trim('JW')),(select trim('14')),1),"..
		"(24,83,(select trim('5')),(select trim('PARNASUS')),(select trim('14')),1),"..
		"(25,84,(select trim('XXXX')),(select trim('Sucursal SUPER GOURMET LA ISLA, S.A DE C.V.')),(select trim('15')),1),"..
		"(26,112,(select trim('XXXX')),(select trim('Sucursal BJM DELIVERY S.A. DE C.V.')),(select trim('18')),1),"..
		"(27,113,(select trim('1')),(select trim('PARADISUS')),(select trim('18')),1),"..
		"(28,114,(select trim('2')),(select trim('BOUTIQUE')),(select trim('18')),1),"..
		"(29,115,(select trim('3')),(select trim('COZUMEL')),(select trim('18')),1),"..
		"(30,116,(select trim('XXXX')),(select trim('Sucursal RIVERA MAYAN S.A DE C.V.')),(select trim('19')),1),"..
		"(31,117,(select trim('XXXX')),(select trim('Sucursal ABASTECEDORA CANCUN, S.A. DE C.V.')),(select trim('20')),1),"..
		"(32,118,(select trim('1')),(select trim('ROYAL CARIBBEAN')),(select trim('20')),1),"..
		"(33,119,(select trim('2')),(select trim('ROYAL SANDS')),(select trim('20')),1),"..
		"(34,120,(select trim('3')),(select trim('ALMACEN GENERAL')),(select trim('20')),1),"..
		"(35,121,(select trim('4')),(select trim('ROYAL MAYAN')),(select trim('20')),1),"..
		"(36,122,(select trim('5')),(select trim('ROYAL ISLANDER')),(select trim('20')),1),"..
		"(37,123,(select trim('6')),(select trim('CLUB INTERNACIONAL')),(select trim('20')),1),"..
		"(38,124,(select trim('7')),(select trim('VIILLA DEL MAR')),(select trim('20')),1),"..
		"(39,125,(select trim('8')),(select trim('REAL ISLEÑO')),(select trim('20')),1),"..
		"(40,126,(select trim('9')),(select trim('ROYAL MARKET')),(select trim('20')),1),"..
		"(41,127,(select trim('10')),(select trim('REAL MAYA')),(select trim('20')),1),"..
		"(42,128,(select trim('11')),(select trim('REAL ARENAS')),(select trim('20')),1),"..
		"(43,129,(select trim('12')),(select trim('ROYAL CANCUN')),(select trim('20')),1),"..
		"(44,130,(select trim('13')),(select trim('ROYAL MAYA')),(select trim('20')),1),"..
		"(45,133,(select trim('XXXX')),(select trim('Sucursal DESIRE PTO.MORELOS')),(select trim('23')),1),"..
		"(46,144,(select trim('XXXX')),(select trim('Sucursal DISTRIBUCIONES GP. SA. DE CV')),(select trim('25')),1),"..
		"(47,145,(select trim('1')),(select trim('RECUERDOS DEL CARIBE')),(select trim('25')),1),"..
		"(48,146,(select trim('2')),(select trim('ARTESANIAS DEL CARIBE')),(select trim('25')),1),"..
		"(49,147,(select trim('3')),(select trim('SUEÑO MEXICANO')),(select trim('25')),1),"..
		"(50,148,(select trim('4')),(select trim('LA FIESTA PTA CANCUN')),(select trim('25')),1),"..
		"(51,149,(select trim('5')),(select trim('ORGULLO DEL CARIBE')),(select trim('25')),1),"..
		"(52,150,(select trim('6')),(select trim('RECUERDOS LA ISLA')),(select trim('25')),1),"..
		"(53,151,(select trim('7')),(select trim('TRADICIONES DEL CARIBE')),(select trim('25')),1),"..
		"(54,152,(select trim('8')),(select trim('CARACOL SUEÑO MEXICANO')),(select trim('25')),1),"..
		"(55,153,(select trim('9')),(select trim('TESOROS DEL CARIBE')),(select trim('25')),1),"..
		"(56,154,(select trim('10')),(select trim('COZUMEL')),(select trim('25')),1),"..
		"(57,155,(select trim('11')),(select trim('TIENDA TULUM')),(select trim('25')),1),"..
		"(58,156,(select trim('12')),(select trim('PLAYA DEL CARMEN')),(select trim('25')),1),"..
		"(59,157,(select trim('13')),(select trim('CC9')),(select trim('25')),1),"..
		"(60,158,(select trim('XXXX')),(select trim('Sucursal SABELDOS, S.A. DE C.V.')),(select trim('26')),1),"..
		"(61,159,(select trim('1')),(select trim('CATALONIA PTO. AVENTURAS')),(select trim('26')),1),"..
		"(62,160,(select trim('2')),(select trim('TIENDA LOGO')),(select trim('26')),1),"..
		"(63,161,(select trim('3')),(select trim('ROYAL TULUM CATALONIA')),(select trim('26')),1),"..
		"(64,162,(select trim('4')),(select trim('CATALONIA PLAYA MAROMA')),(select trim('26')),1),"..
		"(65,165,(select trim('XXXX')),(select trim('Sucursal OPERADORA AERO-BOUTIQUES SA DE CV')),(select trim('29')),1),"..
		"(66,166,(select trim('1')),(select trim('A01 HOTEL PRESIDENTE INTERCONTIE')),(select trim('29')),1),"..
		"(67,167,(select trim('2')),(select trim('A02 HOTEL PRESIDENTE INTERC')),(select trim('29')),1),"..
		"(68,168,(select trim('4')),(select trim('A04 INTERIOR HOTEL HOLIDAY INN')),(select trim('29')),1),"..
		"(69,169,(select trim('5')),(select trim('A05  INTERIOR HOTEL NH MEXICO C')),(select trim('29')),1),"..
		"(70,170,(select trim('8')),(select trim('A08 RADISSON HOTEL FLAMINGOS')),(select trim('29')),1),"..
		"(71,171,(select trim('10')),(select trim('A10 HOTEL SEVILLA PALACE')),(select trim('29')),1),"..
		"(72,172,(select trim('11')),(select trim('A11 EDIFICIO WORLD TRADE CENTER')),(select trim('29')),1),"..
		"(73,173,(select trim('12')),(select trim('A12 EDIFICIO REFORMA 265 PASEO')),(select trim('29')),1),"..
		"(74,174,(select trim('13')),(select trim('A13 HOTEL CROWNE PLAZA TLALNEPA')),(select trim('29')),1),"..
		"(75,175,(select trim('20')),(select trim('A20 REVOLUCION #583')),(select trim('29')),1),"..
		"(76,176,(select trim('21')),(select trim('A21 HOTEL FIESTA INN AEROPUERTO')),(select trim('29')),1),"..
		"(77,177,(select trim('22')),(select trim('A22 HOTEL MELIA MEXICO REFORMA')),(select trim('29')),1),"..
		"(78,178,(select trim('23')),(select trim('A23 HOTEL SHERATON Ma.ISABEL')),(select trim('29')),1),"..
		"(79,179,(select trim('24')),(select trim('A24  HOTEL CAMINO REAL MEXICO')),(select trim('29')),1),"..
		"(80,180,(select trim('26')),(select trim('A26 HOTEL SHERATON CENTRO HISTOR')),(select trim('29')),1),"..
		"(81,181,(select trim('28')),(select trim('A28 HOTEL FOUR SEASONS')),(select trim('29')),1),"..
		"(82,182,(select trim('29')),(select trim('A29  HOTEL NIKKO MEXICO')),(select trim('29')),1),"..
		"(83,183,(select trim('30')),(select trim('A30 HOTEL FOUR SEASONS')),(select trim('29')),1),"..
		"(84,184,(select trim('31')),(select trim('A31 EDIFICIO TORRE MAYOR')),(select trim('29')),1),"..
		"(85,185,(select trim('32')),(select trim('A32 HOTEL NIKKO MEXICO')),(select trim('29')),1),"..
		"(86,186,(select trim('33')),(select trim('A33 HOTEL CAMINO REAL AEROPUERT')),(select trim('29')),1),"..
		"(87,187,(select trim('50')),(select trim('A50 TERMINAL INTERNACIONAL')),(select trim('29')),1),"..
		"(88,188,(select trim('51')),(select trim('A51 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(89,189,(select trim('52')),(select trim('A52 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(90,190,(select trim('53')),(select trim('A53 TERMINAL INTERNACIONAL')),(select trim('29')),1),"..
		"(91,191,(select trim('56')),(select trim('A56 TERMINAL INTERNACIONAL')),(select trim('29')),1),"..
		"(92,192,(select trim('58')),(select trim('A58 TERMINAL DEL A.I.C.M.PRIMER')),(select trim('29')),1),"..
		"(93,193,(select trim('59')),(select trim('A59 ERMINAL DEL A.I.C.M.PRIMER')),(select trim('29')),1),"..
		"(94,194,(select trim('60')),(select trim('A60 KIOSCO ONA A-12 1er.NIVEL')),(select trim('29')),1),"..
		"(95,195,(select trim('61')),(select trim('A61 CAPITAN CARLOS LEON')),(select trim('29')),1),"..
		"(96,196,(select trim('62')),(select trim('A62 1er.NIVEL DEL EDIFICIO A')),(select trim('29')),1),"..
		"(97,197,(select trim('63')),(select trim('A63 PLANTA ALTA MODULO V')),(select trim('29')),1),"..
		"(98,198,(select trim('64')),(select trim('A64 SALAS DE ULTIMA ESPERA')),(select trim('29')),1),"..
		"(99,199,(select trim('65')),(select trim('A65 EDIFICIO A PLANTA BAJA')),(select trim('29')),1),"..
		"(100,200,(select trim('66')),(select trim('A66 AEROPUERTO INTERNACIONAL')),(select trim('29')),1);"
		db:exec( query2 )

		query2 = "INSERT INTO sucursal VALUES " .. 
		"(101,201,(select trim('67')),(select trim('A-67 AEROPUERTO MINI MARKET')),(select trim('29')),1),"..
		"(102,202,(select trim('68')),(select trim('A68  AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(103,203,(select trim('69')),(select trim('ALMACEN')),(select trim('29')),1),"..
		"(104,204,(select trim('70')),(select trim('A69 AEROPUERTO T2 LOCAL TLL-27 S')),(select trim('29')),1),"..
		"(105,205,(select trim('71')),(select trim('A 71 AEROPUERTO MEXICO T2 - LOC2')),(select trim('29')),1),"..
		"(106,206,(select trim('72')),(select trim('A 72 AEROPUERTO MEXICO T2 - LOC9')),(select trim('29')),1),"..
		"(107,207,(select trim('73')),(select trim('A 70 AEROPUERTO MEXICO T2 - LOC8')),(select trim('29')),1),"..
		"(108,208,(select trim('74')),(select trim('A75 AEROPUERTO MEXICO T2 - LOCA4')),(select trim('29')),1),"..
		"(109,209,(select trim('75')),(select trim('A 76 AEROPUERTO MEXICO T2 - LOC6')),(select trim('29')),1),"..
		"(110,210,(select trim('76')),(select trim('A 77 AEROPUERTO MEXICO T2 - LOC8')),(select trim('29')),1),"..
		"(111,211,(select trim('77')),(select trim('A 78 AEROPUERTO MEXICO T2 - LOC9')),(select trim('29')),1),"..
		"(112,212,(select trim('78')),(select trim('A-74  MEXICO')),(select trim('29')),1),"..
		"(113,213,(select trim('79')),(select trim('A-73')),(select trim('29')),1),"..
		"(114,214,(select trim('86')),(select trim('A-86 MEXICO')),(select trim('29')),1),"..
		"(115,215,(select trim('101')),(select trim('B01 HOTEL PRESIDENTE INTERCONTI')),(select trim('29')),1),"..
		"(116,216,(select trim('102')),(select trim('B02  HOTEL WESTIN REGINA')),(select trim('29')),1),"..
		"(117,217,(select trim('104')),(select trim('B04 HOTEL FIESTA AMERICANA CORA')),(select trim('29')),1),"..
		"(118,218,(select trim('106')),(select trim('B06 HOTEL NH CRISTAL')),(select trim('29')),1),"..
		"(119,219,(select trim('107')),(select trim('B07 HOTEL MELIA CANCUN')),(select trim('29')),1),"..
		"(120,220,(select trim('108')),(select trim('B08 HYATT REGENCY')),(select trim('29')),1),"..
		"(121,221,(select trim('109')),(select trim('B09 HOTEL ROYAL SOLARIS CARIBE')),(select trim('29')),1),"..
		"(122,222,(select trim('110')),(select trim('B10 HOTEL VILLAS SOLARIS')),(select trim('29')),1),"..
		"(123,223,(select trim('112')),(select trim('B12  HILTON CANCUN BEACH & GOLF')),(select trim('29')),1),"..
		"(124,224,(select trim('114')),(select trim('B14 HOTEL LE MERIDIEN')),(select trim('29')),1),"..
		"(125,225,(select trim('116')),(select trim('B16 CENTRO COMERCIAL PLAYACAR')),(select trim('29')),1),"..
		"(126,226,(select trim('117')),(select trim('B17 MUELLE FISCAL PLAYA DEL CAR')),(select trim('29')),1),"..
		"(127,227,(select trim('118')),(select trim('B18 HOTEL PARADISUS')),(select trim('29')),1),"..
		"(128,228,(select trim('120')),(select trim('B20 HOTEL PARADISUS')),(select trim('29')),1),"..
		"(129,229,(select trim('122')),(select trim('B22 HYATT REGENCY')),(select trim('29')),1),"..
		"(130,230,(select trim('123')),(select trim('B23 HOTEL RIU PLAYACAR')),(select trim('29')),1),"..
		"(131,231,(select trim('124')),(select trim('B24 HOTEL RIU PALACE')),(select trim('29')),1),"..
		"(132,232,(select trim('125')),(select trim('B-25 HOTEL RIU YUCATAN')),(select trim('29')),1),"..
		"(133,233,(select trim('126')),(select trim('B26 HOTEL RIU TEQUILA')),(select trim('29')),1),"..
		"(134,234,(select trim('127')),(select trim('B27 HOTEL MANDARIN')),(select trim('29')),1),"..
		"(135,235,(select trim('128')),(select trim('B28 HOTEL ALEGRO RESORT')),(select trim('29')),1),"..
		"(136,236,(select trim('129')),(select trim('B29 HOTEL DREAMS TULUM RESOTR &')),(select trim('29')),1),"..
		"(137,237,(select trim('130')),(select trim('B30 HOTEL OCCIDENTAL CARIBBEAN')),(select trim('29')),1),"..
		"(138,238,(select trim('133')),(select trim('B33  RIU CANCUN')),(select trim('29')),1),"..
		"(139,239,(select trim('134')),(select trim('B34  HOTEL SECRETS CAPRI')),(select trim('29')),1),"..
		"(140,240,(select trim('135')),(select trim('B35  HOTEL RIU PALACE LAS AMERI')),(select trim('29')),1),"..
		"(141,241,(select trim('136')),(select trim('B36 HOTEL GR SOLARIS')),(select trim('29')),1),"..
		"(142,242,(select trim('137')),(select trim('B37  HOTEL RIU LUPITA')),(select trim('29')),1),"..
		"(143,243,(select trim('139')),(select trim('B39 HOTEL RIU CARIBE')),(select trim('29')),1),"..
		"(144,244,(select trim('140')),(select trim('B40 HOTEL RIU PALACE LAS AMERICS')),(select trim('29')),1),"..
		"(145,245,(select trim('141')),(select trim('B41 RIU YUCATAN')),(select trim('29')),1),"..
		"(146,246,(select trim('142')),(select trim('B42 RIU PALACE RIVIERA MAYA')),(select trim('29')),1),"..
		"(147,247,(select trim('143')),(select trim('B43 RIU PALACE RIVIERA MAYA')),(select trim('29')),1),"..
		"(148,248,(select trim('144')),(select trim('B44  HOTEL BARCELO MAYA COLONIA')),(select trim('29')),1),"..
		"(149,249,(select trim('145')),(select trim('B45 HOTEL DREAMS TULUM RESORT &')),(select trim('29')),1),"..
		"(150,250,(select trim('146')),(select trim('B46 MINIMARKET NOW JADE')),(select trim('29')),1),"..
		"(151,251,(select trim('147')),(select trim('B47 LA BOUTIQUE')),(select trim('29')),1),"..
		"(152,252,(select trim('148')),(select trim('CORAL BEACH')),(select trim('29')),1),"..
		"(153,253,(select trim('149')),(select trim('B-49  WHITE SANDS')),(select trim('29')),1),"..
		"(154,254,(select trim('150')),(select trim('B-50 DIVERS KANTENAH')),(select trim('29')),1),"..
		"(155,255,(select trim('200')),(select trim('Sucursal OPERADORA AERO-BOUTIQUES SA DE CV')),(select trim('29')),1),"..
		"(156,256,(select trim('201')),(select trim('C01 HOTEL PRESIDENTE INTERCONTIN')),(select trim('29')),1),"..
		"(157,257,(select trim('202')),(select trim('C02  HOTELWESTIN REGINA')),(select trim('29')),1),"..
		"(158,258,(select trim('203')),(select trim('C03 HOTEL FIESTA AMERICANA')),(select trim('29')),1),"..
		"(159,259,(select trim('205')),(select trim('C05 HOTEL NH KRYSTAL')),(select trim('29')),1),"..
		"(160,260,(select trim('206')),(select trim('C06 HOTEL NH KRYSTAL')),(select trim('29')),1),"..
		"(161,261,(select trim('207')),(select trim('C07 HOTEL MELIA')),(select trim('29')),1),"..
		"(162,262,(select trim('210')),(select trim('C10  HOTEL NH KRYSTAL')),(select trim('29')),1),"..
		"(163,263,(select trim('211')),(select trim('C11 HOTEL WESTIN REGINA')),(select trim('29')),1),"..
		"(164,264,(select trim('212')),(select trim('C12 RUI JALISCO')),(select trim('29')),1),"..
		"(165,265,(select trim('213')),(select trim('C13 HOTEL OCCIDENTAL GRAND')),(select trim('29')),1),"..
		"(166,266,(select trim('214')),(select trim('C14 RUI JALISCO')),(select trim('29')),1),"..
		"(167,267,(select trim('215')),(select trim('C15 HOTEL DREAMS')),(select trim('29')),1),"..
		"(168,268,(select trim('216')),(select trim('C16 HOTEL RIU')),(select trim('29')),1),"..
		"(169,269,(select trim('217')),(select trim('C17 HOTEL RIU')),(select trim('29')),1),"..
		"(170,270,(select trim('218')),(select trim('C-18  RIU PALACE PACIFICO')),(select trim('29')),1),"..
		"(171,271,(select trim('219')),(select trim('C-19  MINIMARKET HOTEL VALLARTA')),(select trim('29')),1),"..
		"(172,272,(select trim('220')),(select trim('C-20 OCCIDENTAL')),(select trim('29')),1),"..
		"(173,273,(select trim('221')),(select trim('C-21  VALLARTA')),(select trim('29')),1),"..
		"(174,274,(select trim('250')),(select trim('C50  AEROPUERTO INTERNACIONA')),(select trim('29')),1),"..
		"(175,275,(select trim('251')),(select trim('C51 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(176,276,(select trim('252')),(select trim('C52 AMBULATORIO PLANTA ALTA')),(select trim('29')),1),"..
		"(177,277,(select trim('253')),(select trim('C-53')),(select trim('29')),1),"..
		"(178,278,(select trim('255')),(select trim('C-55 DIVERS')),(select trim('29')),1),"..
		"(179,279,(select trim('256')),(select trim('C-56  NEWS & BOOKS')),(select trim('29')),1),"..
		"(180,280,(select trim('258')),(select trim('C-58  NEWS & BOOKS')),(select trim('29')),1),"..
		"(181,281,(select trim('301')),(select trim('D01 HOTEL PRESIDENTE INTERCONTI')),(select trim('29')),1),"..
		"(182,282,(select trim('303')),(select trim('D03 HOTEL TESORO IXTAPA')),(select trim('29')),1),"..
		"(183,283,(select trim('304')),(select trim('D04 HOTEL NH KRYSTAL')),(select trim('29')),1),"..
		"(184,284,(select trim('305')),(select trim('D05 HOTEL NH KRYSTAL')),(select trim('29')),1),"..
		"(185,285,(select trim('308')),(select trim('D08  HOTEL RADISSON RESORT')),(select trim('29')),1),"..
		"(186,286,(select trim('309')),(select trim('D09 HOTEL FONTAN IXTAPA')),(select trim('29')),1),"..
		"(187,287,(select trim('312')),(select trim('D12 CENTRO COMERCIAL GALERIAS')),(select trim('29')),1),"..
		"(188,288,(select trim('314')),(select trim('D-14 IXTAPA')),(select trim('29')),1),"..
		"(189,289,(select trim('350')),(select trim('D50 EDIFICIO TERMINAL AEROPUERT')),(select trim('29')),1),"..
		"(190,290,(select trim('351')),(select trim('D51  SALA DE ULTIMA ESPERA INT.')),(select trim('29')),1),"..
		"(191,291,(select trim('352')),(select trim('D-52  DIVERS')),(select trim('29')),1);"
		db:exec( query2 )

		query2 = "INSERT INTO sucursal VALUES " .. 
		
		"(192,292,(select trim('353')),(select trim('D-53   MINIMARKET')),(select trim('29')),1),"..
		"(193,293,(select trim('401')),(select trim('E01  HOLIDAY INN')),(select trim('29')),1),"..
		"(194,294,(select trim('402')),(select trim('E02 HOTEL WESTIN REGINA')),(select trim('29')),1),"..
		"(195,295,(select trim('403')),(select trim('E03 HOTEL FIESTA INN')),(select trim('29')),1),"..
		"(196,296,(select trim('404')),(select trim('E04 HOTEL MELIA CABO REAL')),(select trim('29')),1),"..
		"(197,297,(select trim('406')),(select trim('E06 HOTEL MELIA SAN LUCAS')),(select trim('29')),1),"..
		"(198,298,(select trim('408')),(select trim('E08 DREAMS LOS CABOS')),(select trim('29')),1),"..
		"(199,299,(select trim('409')),(select trim('E09')),(select trim('29')),1),"..
		"(200,300,(select trim('412')),(select trim('E12 HOTEL ROYAL SOLARIS LOS CABO')),(select trim('29')),1),"..
		"(201,301,(select trim('413')),(select trim('E13 HOTEL ROYAL SOLARIS LOS CABO')),(select trim('29')),1),"..
		"(202,302,(select trim('414')),(select trim('E14 HOTEL CROWNE PLAZA RESORT LO')),(select trim('29')),1),"..
		"(203,303,(select trim('415')),(select trim('E15')),(select trim('29')),1),"..
		"(204,304,(select trim('416')),(select trim('E16')),(select trim('29')),1),"..
		"(205,305,(select trim('417')),(select trim('E17 HOTEL RIU PALACE LOS CABOS')),(select trim('29')),1),"..
		"(206,306,(select trim('418')),(select trim('E18 HOTEL RIU SANTA FE LOS CABOS')),(select trim('29')),1),"..
		"(207,307,(select trim('419')),(select trim('CASA DORADA MEDANO BEACH')),(select trim('29')),1),"..
		"(208,308,(select trim('420')),(select trim('E-20 INT. HOTEL MELIA CABO REAL')),(select trim('29')),1),"..
		"(209,309,(select trim('450')),(select trim('E50 AEROPUERTO INTERNACIONAL SAN')),(select trim('29')),1),"..
		"(210,310,(select trim('451')),(select trim('E51 AEROPUERTO INTERNACIONAL SAN')),(select trim('29')),1),"..
		"(211,311,(select trim('452')),(select trim('E52 NT.AEROPUERTO INTERNACIONALR')),(select trim('29')),1),"..
		"(212,312,(select trim('453')),(select trim('E53 NT.AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(213,313,(select trim('455')),(select trim('E-55 AEROPUERTO INTERNACIONAL CS')),(select trim('29')),1),"..
		"(214,314,(select trim('456')),(select trim('E-56')),(select trim('29')),1),"..
		"(215,315,(select trim('457')),(select trim('E-57')),(select trim('29')),1),"..
		"(216,316,(select trim('458')),(select trim('E-58 DIVERS')),(select trim('29')),1),"..
		"(217,317,(select trim('459')),(select trim('E-59 CABOS')),(select trim('29')),1),"..
		"(218,318,(select trim('501')),(select trim('F01 HOTEL CONTINENTAL EMPORIO')),(select trim('29')),1),"..
		"(219,319,(select trim('504')),(select trim('F04 HOTEL PLAYA SUITES')),(select trim('29')),1),"..
		"(220,320,(select trim('505')),(select trim('F05')),(select trim('29')),1),"..
		"(221,321,(select trim('506')),(select trim('F06 HOTEL AVALON EXCALIBUR')),(select trim('29')),1),"..
		"(222,322,(select trim('507')),(select trim('F07 HOTEL QUINTA REAL')),(select trim('29')),1),"..
		"(223,323,(select trim('508')),(select trim('F08 HOTEL PARK ROYAL ACAPULCO')),(select trim('29')),1),"..
		"(224,324,(select trim('509')),(select trim('F09 HOTEL RITZ ACAPULCO')),(select trim('29')),1),"..
		"(225,325,(select trim('550')),(select trim('F-50 NEWS & BOOKS')),(select trim('29')),1),"..
		"(226,326,(select trim('551')),(select trim('F-51 AEROPUERTO')),(select trim('29')),1),"..
		"(227,327,(select trim('552')),(select trim('F-52 ACAPULCO AEROPUERTO.')),(select trim('29')),1),"..
		"(228,328,(select trim('553')),(select trim('MEXICAN SOUVENIRS & GIFTS')),(select trim('29')),1),"..
		"(229,329,(select trim('601')),(select trim('G01 HOTEL PRESIDENTE INTERCONTIN')),(select trim('29')),1),"..
		"(230,330,(select trim('602')),(select trim('G02')),(select trim('29')),1),"..
		"(231,331,(select trim('603')),(select trim('G03 HOTEL HOLIDAY INN EXPRESS')),(select trim('29')),1),"..
		"(232,332,(select trim('604')),(select trim('G04 .HOTEL HOLIDAY INN MONTERRE')),(select trim('29')),1),"..
		"(233,333,(select trim('605')),(select trim('G05 HOTEL HOLIDAY INN PARQUE FUN')),(select trim('29')),1),"..
		"(234,334,(select trim('606')),(select trim('G06 HOTEL CROWNE PLAZA')),(select trim('29')),1),"..
		"(235,335,(select trim('607')),(select trim('G07 HOTEL RADISSON PLAZA GRAN')),(select trim('29')),1),"..
		"(236,336,(select trim('608')),(select trim('G08 .HOTEL FIESTA INN MONTERREY')),(select trim('29')),1),"..
		"(237,337,(select trim('610')),(select trim('G10')),(select trim('29')),1),"..
		"(238,338,(select trim('611')),(select trim('G11 HOTEL FIESTA INN')),(select trim('29')),1),"..
		"(239,339,(select trim('612')),(select trim('G12 .HOTEL QUINTA REAL')),(select trim('29')),1),"..
		"(240,340,(select trim('613')),(select trim('G13 HOTEL SHERATON AMBASSADOR')),(select trim('29')),1),"..
		"(241,341,(select trim('614')),(select trim('G14 HOTEL HOLIDAY INN CENTRO')),(select trim('29')),1),"..
		"(242,342,(select trim('615')),(select trim('G15 INT.HOTEL HOLIDAY INN EXPRE')),(select trim('29')),1),"..
		"(243,343,(select trim('616')),(select trim('G16')),(select trim('29')),1),"..
		"(244,344,(select trim('650')),(select trim('G50 EDIFICIO TERMINAL DEL AEROPU')),(select trim('29')),1),"..
		"(245,345,(select trim('651')),(select trim('G51 EDIFICIO TERMINAL DEL AEROPU')),(select trim('29')),1),"..
		"(246,346,(select trim('652')),(select trim('G52 MINI MARKET LOC.1')),(select trim('29')),1),"..
		"(247,347,(select trim('653')),(select trim('G53 BOOKS & GITTS LOC.2')),(select trim('29')),1),"..
		"(248,348,(select trim('654')),(select trim('G54 SNACK BAR PLANTA BAJA AMBULI')),(select trim('29')),1),"..
		"(249,349,(select trim('655')),(select trim('G-55 DIVERS')),(select trim('29')),1),"..
		"(250,350,(select trim('656')),(select trim('G-56')),(select trim('29')),1),"..
		"(251,351,(select trim('658')),(select trim('G-58 MINI MARKET')),(select trim('29')),1),"..
		"(252,352,(select trim('661')),(select trim('G-61')),(select trim('29')),1),"..
		"(253,353,(select trim('662')),(select trim('G-62')),(select trim('29')),1),"..
		"(254,354,(select trim('663')),(select trim('G-63')),(select trim('29')),1),"..
		"(255,355,(select trim('664')),(select trim('G-64')),(select trim('29')),1),"..
		"(256,356,(select trim('701')),(select trim('H01 HOTEL PRESIDENTE INTERCONTIN')),(select trim('29')),1),"..
		"(257,357,(select trim('703')),(select trim('H03 HOTEL FIESTA AMERICANA AUREL')),(select trim('29')),1),"..
		"(258,358,(select trim('704')),(select trim('H04 CERRADA')),(select trim('29')),1),"..
		"(259,359,(select trim('705')),(select trim('H05 .HOTEL HILTON GUADALAJARA A.')),(select trim('29')),1),"..
		"(260,360,(select trim('706')),(select trim('H06 HOTEL MISION CARLTON GUADALA')),(select trim('29')),1),"..
		"(261,361,(select trim('707')),(select trim('H07 HOTEL FIESTA AMERICANA GRAND')),(select trim('29')),1),"..
		"(262,362,(select trim('750')),(select trim('H50 AEROPUERTO INTERNACIONAL MIG')),(select trim('29')),1),"..
		"(263,363,(select trim('751')),(select trim('H51 AEROPUERTO INTERNACIONAL MIG')),(select trim('29')),1),"..
		"(264,364,(select trim('752')),(select trim('H52 PLANTA BAJA EDIF.TERMINAL AE')),(select trim('29')),1),"..
		"(265,365,(select trim('753')),(select trim('H53 PLANTA BAJA EDIF.TERMINAL AE')),(select trim('29')),1),"..
		"(266,366,(select trim('754')),(select trim('H54 SALA DE ULITIMA ESPERA NACIO')),(select trim('29')),1),"..
		"(267,367,(select trim('755')),(select trim('H55 SALA DE ULITIMA ESPERA NACIO')),(select trim('29')),1),"..
		"(268,368,(select trim('756')),(select trim('H56 .EDIF.DE AVIACION REGIONAL E')),(select trim('29')),1),"..
		"(269,369,(select trim('757')),(select trim('H57 EDIF.DE AVIACION REGIONAL AE')),(select trim('29')),1),"..
		"(270,370,(select trim('758')),(select trim('H58 MARKET SEROPUERTO GUADALAJA')),(select trim('29')),1),"..
		"(271,371,(select trim('759')),(select trim('H59  NEWS & BOOKS AEROPUERTO GD.')),(select trim('29')),1),"..
		"(272,372,(select trim('801')),(select trim('I01 HOTEL TESORO')),(select trim('29')),1),"..
		"(273,373,(select trim('802')),(select trim('I02 HOTEL KARMINA PALACE')),(select trim('29')),1),"..
		"(274,374,(select trim('901')),(select trim('J01 HOTEL FIESTA AMERICANA PASEO')),(select trim('29')),1),"..
		"(275,375,(select trim('902')),(select trim('J02 HOTEL HAYATT REGENCY')),(select trim('29')),1),"..
		"(276,376,(select trim('903')),(select trim('J03 HOTEL MISION MERIDA')),(select trim('29')),1),"..
		"(277,377,(select trim('904')),(select trim('J04 HOTEL PRESIDENTE INTERNACION')),(select trim('29')),1),"..
		"(278,378,(select trim('1001')),(select trim('K01 HOTEL CROWNE PLAZA')),(select trim('29')),1),"..
		"(279,379,(select trim('1002')),(select trim('K02 HOTEL REAL DE PUEBLA')),(select trim('29')),1),"..
		"(280,380,(select trim('1003')),(select trim('K03  HOTEL FIESTA INN')),(select trim('29')),1),"..
		"(281,381,(select trim('1004')),(select trim('K04 HOTEL RADISSON')),(select trim('29')),1),"..
		"(282,382,(select trim('2001')),(select trim('L01 HOTEL FARO MAZATLAN')),(select trim('29')),1),"..
		"(283,383,(select trim('2002')),(select trim('L02 HOTEL HOLIDAY INN SUNSPREE')),(select trim('29')),1),"..
		"(284,384,(select trim('2003')),(select trim('L03')),(select trim('29')),1),"..
		"(285,385,(select trim('2050')),(select trim('L50 AEROPUERTO INTERNACIONAL GRA')),(select trim('29')),1),"..
		"(286,386,(select trim('2051')),(select trim('L-51  MAZATLAN')),(select trim('29')),1),"..
		"(287,387,(select trim('2052')),(select trim('L-52')),(select trim('29')),1),"..
		"(288,388,(select trim('3001')),(select trim('N01')),(select trim('29')),1),"..
		"(289,389,(select trim('3001')),(select trim('N01')),(select trim('29')),1),"..
		"(290,390,(select trim('3002')),(select trim('M02 HOTEL OCCIDENTAL ALLEGRO COZ')),(select trim('29')),1),"..
		"(291,391,(select trim('3007')),(select trim('N07 .HOTEL MISION JURIQUILLA')),(select trim('29')),1),"..
		"(292,392,(select trim('3009')),(select trim('N09 AUTOPISTA MEXICO-QUERETARO')),(select trim('29')),1),"..
		"(293,393,(select trim('3050')),(select trim('N50 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(294,394,(select trim('3051')),(select trim('N51 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(295,395,(select trim('4050')),(select trim('O50')),(select trim('29')),1),"..
		"(296,396,(select trim('4051')),(select trim('O51')),(select trim('29')),1),"..
		"(297,397,(select trim('4052')),(select trim('O52 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(298,398,(select trim('4053')),(select trim('O53 AEROPUERTO INTERNACIONAL')),(select trim('29')),1),"..
		"(299,399,(select trim('4054')),(select trim('O54 AEROPUERTO INTERNACIONAL')),(select trim('29')),1);"

		db:exec( query2 )

		query2 = "INSERT INTO sucursal VALUES " .. 
		"(300,400,(select trim('5001')),(select trim('P01HOTEL DREAMS HUATULCO RESORTS')),(select trim('29')),1),"..
		"(301,401,(select trim('5002')),(select trim('P-02 SECRETS HUATULCO')),(select trim('29')),1),"..
		"(302,402,(select trim('6050')),(select trim('S-50 AEROPUERTO HERMOSILLO')),(select trim('29')),1),"..
		"(303,403,(select trim('6051')),(select trim('S-51 NEWS & BOOKS')),(select trim('29')),1),"..
		"(304,404,(select trim('6150')),(select trim('V-50 CULIACAN')),(select trim('29')),1),"..
		"(305,405,(select trim('6151')),(select trim('V-51 CULIACAN')),(select trim('29')),1),"..
		"(306,431,(select trim('XXXX')),(select trim('Sucursal OPERADORA TURISTCA EL CID RIVIERA MAYA')),(select trim('37')),1),"..
		"(307,434,(select trim('XXXX')),(select trim('Sucursal SERVICIOS MARITIMOS Y ACUATICOS DEL CARI')),(select trim('40')),1),"..
		"(308,440,(select trim('XXXX')),(select trim('Sucursal DELI LA ISLA, S.A DE C.V')),(select trim('44')),1),"..
		"(309,459,(select trim('XXXX')),(select trim('Sucursal EVENT SOLUTIONS SA DE C.V')),(select trim('46')),1),"..
		"(310,478,(select trim('XXXX')),(select trim('Sucursal SOL MAR CARIBE S.A. DE C.V.')),(select trim('52')),1),"..
		"(311,479,(select trim('1')),(select trim('CANCUN MART')),(select trim('52')),1),"..
		"(312,480,(select trim('2')),(select trim('LE BEST PLAYA')),(select trim('52')),1),"..
		"(313,481,(select trim('3')),(select trim('FIESTA CARACOL')),(select trim('52')),1),"..
		"(314,482,(select trim('4')),(select trim('BODEGA CARACOL')),(select trim('52')),1),"..
		"(315,483,(select trim('5')),(select trim('PLAZA LA ISLA')),(select trim('52')),1),"..
		"(316,484,(select trim('6')),(select trim('PLAZA FLAMINGOS')),(select trim('52')),1),"..
		"(317,485,(select trim('7')),(select trim('CASA MEXICANA PTO VALLARTA')),(select trim('52')),1),"..
		"(318,486,(select trim('XXXX')),(select trim('Sucursal AZUL MAR DEL CARIBE S.A. DE C.V.')),(select trim('53')),1),"..
		"(319,487,(select trim('1')),(select trim('FIESTA KUKULCAN')),(select trim('53')),1),"..
		"(320,488,(select trim('2')),(select trim('CEDI PALYA')),(select trim('53')),1),"..
		"(321,489,(select trim('3')),(select trim('PLAYA MAR II')),(select trim('53')),1),"..
		"(322,490,(select trim('4')),(select trim('CEDI COZUMEL')),(select trim('53')),1),"..
		"(323,491,(select trim('5')),(select trim('CEDI CANCUN')),(select trim('53')),1),"..
		"(324,510,(select trim('XXXX')),(select trim('Sucursal SUPERMERCARDO DEL CARIBE S.A. DE C.V.')),(select trim('57')),1),"..
		"(325,511,(select trim('1')),(select trim('TEQUILA PASEOS')),(select trim('57')),1),"..
		"(326,512,(select trim('2')),(select trim('COZUMEL MART')),(select trim('57')),1),"..
		"(327,513,(select trim('3')),(select trim('CASA TEQUILA')),(select trim('57')),1),"..
		"(328,514,(select trim('4')),(select trim('CASA LA ISLA')),(select trim('57')),1),"..
		"(329,515,(select trim('5')),(select trim('PUERTA MAYA')),(select trim('57')),1),"..
		"(330,516,(select trim('6')),(select trim('HACIENDA  CANCUN')),(select trim('57')),1),"..
		"(331,528,(select trim('XXXX')),(select trim('Sucursal AZUL SENSATORI')),(select trim('60')),1),"..
		"(332,529,(select trim('1')),(select trim('AZUL FIVES')),(select trim('60')),1),"..
		"(333,535,(select trim('XXXX')),(select trim('Sucursal CONFETI CARIBE S.A DE C.V.')),(select trim('62')),1),"..
		"(334,536,(select trim('1')),(select trim('TRES RIOS')),(select trim('62')),1),"..
		"(335,537,(select trim('2')),(select trim('OCEAN')),(select trim('62')),1),"..
		"(336,538,(select trim('3')),(select trim('SUNSET LAGOON')),(select trim('62')),1),"..
		"(337,539,(select trim('4')),(select trim('ROYAL SUNSET')),(select trim('62')),1),"..
		"(338,540,(select trim('5')),(select trim('SUNSET WORLD')),(select trim('62')),1),"..
		"(339,541,(select trim('6')),(select trim('CLUB LAGOON')),(select trim('62')),1),"..
		"(340,543,(select trim('XXXX')),(select trim('Sucursal PROMOTORA DE INMUEBLES DEL CARIBE S. A D')),(select trim('64')),1),"..
		"(341,544,(select trim('1')),(select trim('PARK ROYAL')),(select trim('64')),1),"..
		"(342,547,(select trim('XXXX')),(select trim('Sucursal BARCELO TUCANCUN')),(select trim('67')),1),"..
		"(343,548,(select trim('XXXX')),(select trim('Sucursal OPERADORA XPETIA DEL SUR, S.A DE C.V')),(select trim('68')),1),"..
		"(344,584,(select trim('XXXX')),(select trim('Sucursal MARINA BLUE RAY')),(select trim('77')),1),"..
		"(345,585,(select trim('XXXX')),(select trim('Sucursal SUPERINTENDENTES DE CAMPO DE GOLF DE MEX')),(select trim('78')),1),"..
		"(346,590,(select trim('XXXX')),(select trim('Sucursal REMTEX, S.A DE C.V.')),(select trim('93')),1),"..
		"(347,591,(select trim('1')),(select trim('RED FORUM')),(select trim('93')),1),"..
		"(348,592,(select trim('2')),(select trim('TOMMY')),(select trim('93')),1),"..
		"(349,593,(select trim('3')),(select trim('ACUARIO')),(select trim('93')),1),"..
		"(350,594,(select trim('4')),(select trim('CRAZY')),(select trim('93')),1),"..
		"(351,595,(select trim('5')),(select trim('TRECE')),(select trim('93')),1),"..
		"(352,596,(select trim('XXXX')),(select trim('Sucursal TPE, S.A DE C.V.')),(select trim('94')),1),"..
		"(353,597,(select trim('1')),(select trim('MOLCAS DOS')),(select trim('94')),1),"..
		"(354,598,(select trim('2')),(select trim('MOLCAS CUATRO')),(select trim('94')),1),"..
		"(355,599,(select trim('3')),(select trim('MOLCAS QUINTA')),(select trim('94')),1),"..
		"(356,600,(select trim('4')),(select trim('CARAMBA')),(select trim('94')),1),"..
		"(357,601,(select trim('5')),(select trim('MARIACHI')),(select trim('94')),1),"..
		"(358,602,(select trim('6')),(select trim('PARADISE')),(select trim('94')),1),"..
		"(359,603,(select trim('7')),(select trim('CARACOL')),(select trim('94')),1),"..
		"(360,604,(select trim('8')),(select trim('NAUTICA')),(select trim('94')),1),"..
		"(361,605,(select trim('9')),(select trim('RED PUERTA MAYA')),(select trim('94')),1),"..
		"(362,606,(select trim('10')),(select trim('REEF PUERTA MAYA')),(select trim('94')),1),"..
		"(363,607,(select trim('11')),(select trim('QUINTA AVENIDA')),(select trim('94')),1),"..
		"(364,608,(select trim('12')),(select trim('DEL SOL')),(select trim('94')),1),"..
		"(365,613,(select trim('XXXX')),(select trim('Sucursal OPERADORA CARIBEÑA DE INMUEBLES, S.A. DE ')),(select trim('99')),1),"..
		"(366,614,(select trim('1')),(select trim('LA MAR')),(select trim('99')),1),"..
		"(367,615,(select trim('2')),(select trim('PIRAMIDE')),(select trim('99')),1),"..
		"(368,616,(select trim('3')),(select trim('LA LAGUNA')),(select trim('99')),1),"..
		"(369,617,(select trim('4')),(select trim('TAB. NIZUC')),(select trim('99')),1),"..
		"(370,618,(select trim('5')),(select trim('MAÑANITAS')),(select trim('99')),1),"..
		"(371,619,(select trim('6')),(select trim('TABAQUERIA CARIBE')),(select trim('99')),1),"..
		"(372,620,(select trim('7')),(select trim('ALMACEN COMERCIOS')),(select trim('99')),1),"..
		"(373,621,(select trim('8')),(select trim('LA LUNA')),(select trim('99')),1),"..
		"(374,622,(select trim('9')),(select trim('TABAQUERIA TULUM')),(select trim('99')),1),"..
		"(375,623,(select trim('XXXX')),(select trim('Sucursal NAVIERA OCEAN GM SA DE CV')),(select trim('100')),1),"..
		"(376,627,(select trim('XXXX')),(select trim('Sucursal GIOMAYAL, S.A DE C.V.')),(select trim('104')),1),"..
		"(377,628,(select trim('XXXX')),(select trim('Sucursal OPERADORA DE HOTELES DE LUJO, S.A DE C.V')),(select trim('105')),1),"..
		"(378,633,(select trim('XXXX')),(select trim('Sucursal CORPORATIVO ENIDAN DEL CARIBE, S.A DE C.')),(select trim('109')),1),"..
		"(379,634,(select trim('XXXX')),(select trim('Sucursal NAJIM DEL CARIBE, S.A DE C.V')),(select trim('110')),1),"..
		"(380,636,(select trim('XXXX')),(select trim('Sucursal LIDYON S.A DE C.V.')),(select trim('112')),1),"..
		"(381,642,(select trim('XXXX')),(select trim('Sucursal OPERADORA DE MARINAS S.A DE C.V.')),(select trim('116')),1),"..
		"(382,666,(select trim('XXXX')),(select trim('Sucursal HOTEL OMNI')),(select trim('129')),1),"..
		"(383,667,(select trim('1')),(select trim('PARASOL')),(select trim('129')),1),"..
		"(384,668,(select trim('2')),(select trim('TABAQUERIA')),(select trim('129')),1),"..
		"(385,670,(select trim('XXXX')),(select trim('Sucursal JCV')),(select trim('131')),1),"..
		"(386,672,(select trim('XXXX')),(select trim('Sucursal HOTEL VILLA DEL PALMAR')),(select trim('133')),1),"..
		"(387,674,(select trim('XXXX')),(select trim('Sucursal DESIRE LA PERLA')),(select trim('135')),1),"..
		"(388,676,(select trim('XXXX')),(select trim('Sucursal VALENTIN PLAYA DEL SECRETO S.A DE C.V.')),(select trim('137')),1),"..
		"(389,681,(select trim('XXXX')),(select trim('Sucursal BOUTIKIS DE ORO, S.A DE C.V.')),(select trim('140')),1),"..
		"(390,682,(select trim('1')),(select trim('INT.HOTEL CROWN PARADISE LOC.1-D')),(select trim('140')),1),"..
		"(391,683,(select trim('2')),(select trim('LOCAL 1-C LA BOUTIQUE')),(select trim('140')),1),"..
		"(392,684,(select trim('3')),(select trim('GREAT PARNASSUS')),(select trim('140')),1),"..
		"(393,685,(select trim('4')),(select trim('HOTEL GOLDEN PARNASUS LOCAL 1')),(select trim('140')),1),"..
		"(394,686,(select trim('5')),(select trim('BOUTIKIS-TEQUILA LOC-3-A')),(select trim('140')),1),"..
		"(395,687,(select trim('6')),(select trim('MINISUPER LOC-2-B')),(select trim('140')),1),"..
		"(396,697,(select trim('XXXX')),(select trim('Sucursal OASIS RESORTS, S.A DE C.V')),(select trim('150')),1),"..
		"(397,698,(select trim('1')),(select trim('LA LAGUNA')),(select trim('150')),1),"..
		"(398,699,(select trim('2')),(select trim('PIRAMIDE')),(select trim('150')),1),"..
		"(399,700,(select trim('3')),(select trim('CARIBE')),(select trim('150')),1),"..
		"(400,701,(select trim('4')),(select trim('LA MAR')),(select trim('150')),1),"..
		"(401,702,(select trim('5')),(select trim('TULUM')),(select trim('150')),1),"..
		"(402,703,(select trim('6')),(select trim('TAB. LA LUNA')),(select trim('150')),1),"..
		"(403,704,(select trim('7')),(select trim('TAB. NIZUC')),(select trim('150')),1),"..
		"(404,705,(select trim('8')),(select trim('TAB. MAÑANITAS')),(select trim('150')),1),"..
		"(405,706,(select trim('9')),(select trim('ALMACEN')),(select trim('150')),1),"..
		"(406,708,(select trim('XXXX')),(select trim('Sucursal ARENA DE VERANO, S.A DE C.V.')),(select trim('152')),1),"..
		"(407,709,(select trim('1')),(select trim('LOBBY')),(select trim('152')),1),"..
		"(408,710,(select trim('2')),(select trim('DELLY')),(select trim('152')),1),"..
		"(409,737,(select trim('XXXX')),(select trim('Sucursal HOTEL SEA ADVENTURE RESORTS')),(select trim('157')),1),"..
		"(410,742,(select trim('XXXX')),(select trim('Sucursal OPERADORA TURISTICA HOTELERA, S.A DE C.V')),(select trim('162')),1),"..
		"(411,745,(select trim('XXXX')),(select trim('Sucursal MARINA SUNRISE')),(select trim('165')),1),"..
		"(412,751,(select trim('XXXX')),(select trim('Sucursal OPERADORA DIESTRA CANCUN, S.A DE C.V')),(select trim('171')),1),"..
		"(413,755,(select trim('XXXX')),(select trim('Sucursal GRUPO VIA DELPHI, S.A DE C.V.')),(select trim('175')),1),"..
		"(414,758,(select trim('XXXX')),(select trim('Sucursal ORQUIDEA RESORTS, S.A DE C.V.')),(select trim('178')),1),"..
		"(415,759,(select trim('1')),(select trim('LA LAGUNA')),(select trim('178')),1),"..
		"(416,760,(select trim('2')),(select trim('PIRAMIDE')),(select trim('178')),1),"..
		"(417,761,(select trim('3')),(select trim('CARIBE')),(select trim('178')),1),"..
		"(418,762,(select trim('4')),(select trim('LA MAR')),(select trim('178')),1),"..
		"(419,763,(select trim('5')),(select trim('TULUM')),(select trim('178')),1),"..
		"(420,764,(select trim('6')),(select trim('TAB. LA LUNA')),(select trim('178')),1),"..
		"(421,765,(select trim('7')),(select trim('TAB. NIZUC')),(select trim('178')),1),"..
		"(422,766,(select trim('8')),(select trim('TAB. MAÑANITAS')),(select trim('178')),1),"..
		"(423,767,(select trim('9')),(select trim('ALMACEN')),(select trim('178')),1),"..
		"(424,768,(select trim('XXXX')),(select trim('Sucursal ALEJANDRO MOREDIA LOPEZ')),(select trim('179')),1),"..
		"(425,769,(select trim('XXXX')),(select trim('Sucursal VAL BREN DE MEXICO SA DE CV')),(select trim('180')),1),"..
		"(426,775,(select trim('XXXX')),(select trim('Sucursal MINI SUPER ORIGINAL')),(select trim('186')),1);"

		db:exec( query2 )


		--llenar con los datos de los catalogos de las sucursales
        query2 = "INSERT INTO refsucursalcatalogo VALUES " .. 
        "(1, 1, '1'), " ..
        "(2, 1, '2'), " ..
        "(3, 1, '3'), " ..
        "(4, 1, '5'), " ..
        "(5, 2, '1'), " ..
        "(6, 2, '2'), " ..
        "(7, 2, '3'), " ..
        "(8, 2, '4'), " ..
        "(9, 2, '5'), " ..
        "(10, 2, '7'), " ..
        "(11, 2, '8'), " ..
        "(12, 2, '9'), " ..
        "(13, 2, '10'), " ..
        "(14, 2, '11'), " ..
        "(15, 2, '12'), " ..
        "(16, 2, '13'), " ..
        "(17, 2, '14'), " ..
        "(18, 2, '15'), " ..
        "(19, 2, '16'), " ..
        "(34, 2, '1'), " ..
        "(34, 2, '2');" 

		db:exec( query2 )


		--llenar con los datos de los pedidos
       	--[[query2 = "INSERT INTO pedidotemporal (id, idsucursal, fecha, estado) VALUES " .. 
        "(1, 1, '2015-07-14', 1), " ..
		"(2, 2, '2015-05-14', 1); "

		db:exec( query2 )]]


		--llenar con los datos de los pedidos
        query2 = "INSERT INTO pedido VALUES " .. 
        "(1, 1, 1, '2015-05-12', 5600,  1); "

		db:exec( query2 )


		--llenar con los datos de los detalles de los pedidos
        query2 = "INSERT INTO detallepedido VALUES " .. 
        "(1, 1, 1, 2, 10), "..
		"(2, 1, 1, 3, 15), "..
		"(3, 1, 1, 4, 10), "..
		"(4, 1, 2, 3, 25), "..
		"(5, 1, 2, 4, 20); "


		db:exec( query2 )
		

		--[[llenar con los datos de los detalles de los pedidos
        query2 = "INSERT INTO detallepedido VALUES " .. 
        "(1, 1, 1, 2, 10), "..
		"(2, 1, 1, 3, 15), "..
		"(3, 1, 1, 4, 10), "..
		"(4, 1, 2, 2, 10), "..
		"(5, 1, 2, 3, 15), "..
		"(6, 1, 2, 4, 10), "..
		"(7, 1, 1, 2, 10), "..
		"(8, 1, 1, 3, 15), "..
		"(9, 1, 1, 4, 10), "..
		"(10, 1, 3, 2, 10), "..
		"(11, 1, 3, 3, 15), "..
		"(12, 1, 3, 4, 10); "
		
		db:exec( query2 )]]

        --populate config

        --llenar con los datos del vendedor
        query = "INSERT INTO config VALUES " .. 
        "(1, 1, 'ABRAHAM SALAME', 1);"
		db:exec( query )

		--query2 = "INSERT INTO catalogo VALUES (1, '4810101009', 'PL AD SOL PANAMA BLANCO', 	'4810101009.jpg', 69.00, 'pt', 1);"
		--"(2, '4810101073', 'PL AD 3 DELFINES BRINCANDO MARINO', '4810101073.jpg', 69.00, 'pt', 1), " .. 
		--"(3, '4810101105', 'PL AD MARGARITAS BLANCO', 			'4810101105.jpg', 69.00, 'pt', 1), " ..
		--"(4, '4810101382', 'PL AD PEZ VELA MARINO', 			'4810101382.jpg', 69.00, 'pt', 1), " ..
		--"(5, '4810101459', 'PL AD GEKO RECTANGULO OLIVO', 		'4810101459.jpg', 69.00, 'pt', 1)  " ..
		--";"
		
		closeConnection( )
    
        return false
	end
	

	--setup the system listener to catch applicationExit
	Runtime:addEventListener( "system", onSystemEvent )
    

return dbManager