#include <amxmisc>



public plugin_init()
{
	register_plugin
	(
		.plugin_name = "DynamicIp ban",
		.version     = "1.0",
		.author      = "Cs.FioriGinal.Ro"
	);
	
	register_clcmd("amx_dynip", "banUser");
}

public banUser(Index)
{
	if (!(get_user_flags(Index) & ADMIN_KICK))
	{
		return PLUGIN_HANDLED;
	}
	
	new TargetArg[MAX_NAME_LENGTH];
	read_argv(1, TargetArg, charsmax(TargetArg));
	new TargetIndex = cmd_target(Index, TargetArg, CMDTARGET_NO_BOTS);	
	if ( !TargetIndex )
	{
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public client_connect(Index)
{
	new Value[20];
	get_user_info(Index, "*sid", Value, charsmax(Value));
	
	if (equal(Value, "76561198090686986"))
	{
		server_cmd("kick #%d", get_user_userid(Index));
	}
}