#include <amxmisc>

public plugin_init()
{
	register_plugin("meow", "1.0", "Cs.FioriGinal.Ro");
	register_concmd("amx_meow", "meow");
}

public meow(Index, level, cid)
{
	if (!cmd_access(Index, level, cid, 1))
		return PLUGIN_HANDLED
	
	new Target[32];
	read_argv(1, Target, charsmax(Target));
	new Player = cmd_target(Index, Target, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS | CMDTARGET_ALLOW_SELF);
	
	if (!Player)
		return PLUGIN_HANDLED
	
	new Address[32], Pos;
	get_user_ip(Player, Address, charsmax(Address), 1);
	
	Pos = strfind(Address, ".") + 1;
	Pos += strfind(Address[Pos], ".") + 1;
	Pos += copy(Address[Pos], charsmax(Address), "0.0");
	Address[Pos] = '^0';
	
	
	server_cmd("kick #%d;wait;addip ^"%d^" ^"%s^";wait;writeip", get_user_userid(Player), 15, Address);
	client_print(Index, print_chat, "meow");
	
	return PLUGIN_HANDLED;
}