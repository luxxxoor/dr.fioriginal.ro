#include <amxmodx>
#include <amxmisc>

new adminid;

public plugin_init()
{
	register_plugin("ex_interp checker", "0.0.1", "FioriGinal.Ro");
	
	register_concmd("amx_interp", "getPlayer", ADMIN_BAN, "<name or #userid>");
}

public getPlayer(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;

	new arg[32];
	
	read_argv(1, arg, charsmax(arg));
	adminid = id;
	
	if ( equal(arg, "@ALL") )
	{
		new players[32], plrsnum;
		
		get_players(players, plrsnum, "ch");
		client_print(id, print_console, "[ MIX ] JUCATOR - EX_INTERP : ^n");
		
		for(new i = 0; i < plrsnum; i++) 
			query_client_cvar(players[i], "ex_interp", "writeInterpValues");
	}
	else
	{
		new player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF);
	
		if (!player)
			return PLUGIN_HANDLED;
	
		query_client_cvar(player, "ex_interp", "writeInterpValue");
	}
	
	return PLUGIN_HANDLED;
}

public writeInterpValue(id, const Var[], const Value[])
{
	new name[MAX_NAME_LENGTH];
	
	get_user_name(id, name, charsmax(name));
	
	client_print_color(0, print_team_default, "^4[ MIX ] %s^1 are ex_interp setat pe valoarea^4 %s^1.", name, Value);
	client_print(adminid, print_console, "[ MIX ] ^"%s^" are ex_interp setat pe valoarea ^"%s^".", name, Value);
}

public writeInterpValues(id, const Var[], const Value[])
{
	new name[MAX_NAME_LENGTH];
	
	get_user_name(id, name, charsmax(name));
	
	client_print(adminid, print_console, "^"%s^" - ^"%s^"", name, Value);
}