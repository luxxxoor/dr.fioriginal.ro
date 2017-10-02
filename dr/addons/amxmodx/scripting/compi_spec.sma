#include <amxmodx>
#include <fakemeta>
#include <cstrike>

const m_iMenu = 205 
const Menu_OFF = 0
const Menu_ChooseAppearance = 3

public plugin_init()
{
register_forward(FM_ClientCommand, "pfnClientCommand", false)  
register_clcmd("spec", "spec")
}

public spec(id)
{
	cs_set_user_team(id, CS_TEAM_SPECTATOR)
	user_kill(id, 1)
}

public client_command(Index)
{
	new Command[15];
	read_argv(0, Command, charsmax(Command));
	if(equali(Command, "joinclass") || (equali(Command, "menuselect") && get_pdata_int(id, m_iMenu) == Menu_ChooseAppearance))
	{
		if(get_user_team(id) == 3)
		{
			set_pdata_int(id, m_iMenu, Menu_OFF);
			engclient_cmd(id, "jointeam", "6");
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}
