#include <amxmisc>

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Show IP using SteamID",
		.version     = "1.1",
		.author      = "Dr.FioriGinal.Ro"
	);
	register_concmd("amx_showip", "showIp");
}

public showIp(Index)
{
	new const Tag[] = "Dr.FioriGinal.Ro";
	if ( !(get_user_flags(Index) & ADMIN_KICK) )
	{
		console_print(Index, "[%s] Nu ai acces la această comandă.", Tag);
		return PLUGIN_HANDLED;
	}	
	
	console_print(Index, "Nume                                        Ip                                 SteamID");
	new Players[MAX_PLAYERS], MatchedPlayers, Name[MAX_NAME_LENGTH], AuthId[35], Ip[20];
	get_players(Players, MatchedPlayers);
	for(new i = 0 ; i < MatchedPlayers; i++)
	{
		get_user_name(Players[i], Name, charsmax(Name));
		get_user_ip(Players[i], Ip, charsmax(Ip), any:true);
		get_user_authid(Players[i], AuthId, charsmax(AuthId));
  
		console_print(Index, "%32s - %20s - %s", Name, Ip, AuthId);
	}
	
	return PLUGIN_HANDLED;
}