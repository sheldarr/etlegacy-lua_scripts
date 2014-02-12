luasql = {}  -- sql driver
env = {}     -- environment object
con = {}     -- database connection
cur = {}     -- cursor

dofile("./" .. et.trap_Cvar_Get("fs_game") .. "/ladm/ladm.cfg")

-- 1) load the chosen driver
-- 2) create environement object
-- 3) connect to database
function db_init ( )
	et.G_Print ( "Connecting to " .. dbdriver .. " database..." )

	if ( dbdriver == "mysql" ) then
		luasql = require "luasql.mysql"
		env = assert ( luasql.mysql() )
		con = assert ( env:connect( dbdatabase, dbuser, dbpassword, dbhost, dbport ) )
	elseif ( dbdriver == "sqlite" or dbdriver == "sqlite3") then
		luasql = require "luasql.sqlite3"
		env = assert ( luasql.sqlite3() )
		con = assert ( env:connect( dbdatabase .. ".sqlite" ) ) 
	--elseif ( dbdriver == "postgres") then
	--	luasql = require "luasql.postgres"	
	--	env = assert ( luasql.postgres() )	
	--	con = assert ( env:connect( dbdatabase, ... ) ) 
	else
		print ( "Unsupported database driver. Please set either mysql or sqlite in the config file." )
		return
	end

	if not installed then db_create() end
	
	cur = assert ( con:execute ( string.format ( "SELECT COUNT(*) FROM %susers", dbprefix ) ) )
	et.G_Print("There are " .. tonumber(cur:fetch(row, 'a')) .. " users in the database.\n")

	cur = assert ( con:execute ( string.format ( "SELECT COUNT(*) FROM %svariables", dbprefix ) ) )
	et.G_Print("There are " .. tonumber(cur:fetch(row, 'a')) .. " variables in the database.\n")
end

-- database  helper function  
-- returns database rows matching sql_statement 
function db_rows ( connection, sql_statement )  
	local cursor =  assert (connection:execute  (sql_statement)) 
	return function () 
		return cursor:fetch() 
	end 
end -- rows

-- called only the first time ladm starts
function db_create ()
	print ( "INSTALLING DATABASE RECORDS" )
	--cur = assert (con:execute( "DROP TABLE users" ))
	
	cur = assert ( con:execute ( string.format ( [[
		CREATE TABLE IF NOT EXISTS %susers(
			id INT(11) NOT NULL AUTO_INCREMENT,
			guid VARCHAR(64),
			first_seen VARCHAR(64),
			last_seen VARCHAR(64),

			xp_battlesense REAL,
			xp_engineering REAL,
			xp_medic REAL,
			xp_fieldops REAL,
			xp_lightweapons REAL,
			xp_heavyweapons REAL,
			xp_covertops REAL,	

			PRIMARY KEY (id),
			UNIQUE (guid)
		);
	]], dbprefix ) ) )

	cur = assert ( con:execute ( string.format ( [[	
		CREATE TABLE IF NOT EXISTS %svariables(
			id INT(11) NOT NULL AUTO_INCREMENT,
			type VARCHAR(128) NOT NULL,
			name VARCHAR(128) NOT NULL,
			value VARCHAR(128) NOT NULL,
			description TEXT NOT NULL,

			PRIMARY KEY (id),
			UNIQUE KEY name (name)
		);
	]], dbprefix ) ) )
	
	local configfile = io.open ( "ladm.cfg", "a" )
	configfile:write ( "\ninstalled = true\n" )
	configfile:close()
	
	--et.G_Print ("^4List of users in the database:\n")
	--for guid, date in rows (con, "SELECT * FROM users") do
	--	et.G_Print (string.format ("\tGUID %s was last seen on %s\n", guid, date))
	--end
end