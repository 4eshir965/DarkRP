/*---------------------------------------------------------------------------
interface functions
---------------------------------------------------------------------------*/
local pmeta = FindMetaTable("Player")
function pmeta:getDarkRPVar(var)
	self.DarkRPVars = self.DarkRPVars or {}
	return self.DarkRPVars[var]
end

/*---------------------------------------------------------------------------
Retrieve the information of a player var
---------------------------------------------------------------------------*/
local function RetrievePlayerVar(entIndex, var, value, tries)
	local ply = Entity(entIndex)

	-- Usermessages _can_ arrive before the player is valid.
	-- In this case, chances are huge that this player will become valid.
	if not IsValid(ply) then
		if (tries or 0) >= 5 then return end
		print("DARKRPDEBUG", "retrying DarkRPVar for ", entIndex, var, tries)
		timer.Simple(0.5, function() RetrievePlayerVar(entIndex, var, value, (tries or 0) + 1) end)
		return
	end

	print("DARKRPDEBUG", "Retrieving single DarkRPVar succesful for ", entIndex, var, tries)
	ply.DarkRPVars = ply.DarkRPVars or {}

	hook.Call("DarkRPVarChanged", nil, ply, var, ply.DarkRPVars[var], value)
	ply.DarkRPVars[var] = value
end

/*---------------------------------------------------------------------------
Retrieve a player var.
Read the usermessage and attempt to set the DarkRP var
---------------------------------------------------------------------------*/
local function doRetrieve()
	local entIndex = net.ReadFloat()
	local var = net.ReadString()
	local valueType = net.ReadUInt(8)
	local value = net.ReadType(valueType)
	print("DARKRPDEBUG", "RETRIEVING DARKRPVAR", entIndex, Entity(entIndex), var, valueType, value)

	RetrievePlayerVar(entIndex, var, value)
end
net.Receive("DarkRP_PlayerVar", doRetrieve)

/*---------------------------------------------------------------------------
Initialize the DarkRPVars at the start of the game
---------------------------------------------------------------------------*/
local function InitializeDarkRPVars(len)
	local vars = net.ReadTable()
	print("DARKRPDEBUG INIT VARS", "A = VARS", vars)
	A = A or {}
	table.insert(A, vars)

	if not vars then return end
	for k,v in pairs(vars) do
		if not IsValid(k) then print("DARKRPDEBUG", "PLAYER NOT VALID!", k, v) continue end
		k.DarkRPVars = k.DarkRPVars or {}

		-- Merge the tables
		for a, b in pairs(v) do
			k.DarkRPVars[a] = b
		end
	end
end
net.Receive("DarkRP_InitializeVars", InitializeDarkRPVars)

/*---------------------------------------------------------------------------
Request the DarkRPVars
---------------------------------------------------------------------------*/
timer.Simple(1, fn.Curry(RunConsoleCommand, 2)("_sendDarkRPvars"))

timer.Create("DarkRPCheckifitcamethrough", 15, 0, function()
	print("DARKRPDEBUG", "CHECKING CAME THROUGH")
	for k,v in pairs(player.GetAll()) do
		if v.DarkRPVars and v:getDarkRPVar("rpname") then continue end
		print("DARKRPDEBUG", "CHECKING CAME THROUGH", "NOPE DID NOT COME THROUGH")

		RunConsoleCommand("_sendDarkRPvars")
		return
	end

	print("DARKRPDEBUG", "CHECKING CAME THROUGH", "YES DID COME THROUGH")

	timer.Destroy("DarkRPCheckifitcamethrough")
end)

/*---------------------------------------------------------------------------
RP name override
---------------------------------------------------------------------------*/
pmeta.SteamName = pmeta.SteamName or pmeta.Name
function pmeta:Name()
	return GAMEMODE.Config.allowrpnames and self:getDarkRPVar("rpname")
		or self:SteamName()
end

pmeta.GetName = pmeta.Name
pmeta.Nick = pmeta.Name
