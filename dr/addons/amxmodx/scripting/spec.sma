#include <amxmisc>
#include <engine>
#include <cstrike>

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "Comanzi Chat + Gravity",
		.version     = "1.1",
		.author      = "Cs.FioriGinal.Ro"
	);
	register_clcmd("say", "hookChat");
}

public hookChat(Index)
{
	new Said[32];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if ( !Said[0] )
	{
		return PLUGIN_CONTINUE;
	}
	
	new const Spec[] = "/spec";
	
	if (get_user_flags(Index) & ADMIN_KICK && equali(Said, Spec))
	{		
		if (cs_get_user_team(Index) == CS_TEAM_SPECTATOR)
		{
			cs_set_user_team(Index, random_num(0, 1) ? CS_TEAM_CT : CS_TEAM_T);
			return PLUGIN_HANDLED;
		}
		else
		{
			cs_set_user_team(Index, CS_TEAM_SPECTATOR);
			user_silentkill(Index);
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}