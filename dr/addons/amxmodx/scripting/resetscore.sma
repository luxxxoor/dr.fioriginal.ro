#include <amxmodx>
#include <cstrike>
#include <fun>

public plugin_init() 
{
	register_plugin("Reset score", "1.0", "Dr.FioriGinal.Ro");
	
	register_clcmd("say", "hookChat");
}

public hookChat(Index)
{
	new Said[32];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if (!Said[0])
	{
		return PLUGIN_CONTINUE;
	}
	
	new const ResetScoreIdent[] = "!resetscore";
	
	if (equali(Said, ResetScoreIdent, charsmax(ResetScoreIdent)))
	{
		resetScore(Index)
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public resetScore(Index)
{	
	cs_set_user_deaths(Index, 0);
	set_user_frags(Index, 0);
	
	static ScoreInfo;
	if (ScoreInfo == 0)
	{
		ScoreInfo = get_user_msgid("ScoreInfo")
	}
	message_begin(MSG_BROADCAST, ScoreInfo);
	write_byte(Index);
	write_short(0); // frags
	write_short(0); // deaths
	write_short(0);
	write_short(get_user_team(Index));
	message_end();
	
	client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Ți-ai resetat scorul.");
}