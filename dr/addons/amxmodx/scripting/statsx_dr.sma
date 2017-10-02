/* Credite: amxmodx team*/

#include <amxmodx>
#include <amxmisc>
#include <csx>

#define STATS_KILLS             0

new t_sName[MAX_NAME_LENGTH];


public plugin_init()
{
	// Register plugin.
	register_plugin("top 15 deathrun", "1.1", "Vicious Vixen");
	
	register_clcmd("say !rank", "cmdRank", 0, "- display your rank (chat)");
	register_clcmd("say !top10", "cmdTop10", 0, "- display top 10 players (MOTD)");
	
	
	// Init buffers and some global vars.
	
}

public cmdTop10(id)
{
	
	new menu = menu_create( "Topul celor mai buni 10 jucatori :", "menu_handled" )
	
	new iMax = get_statsnum();
	new izStats[8], izBody[8], message[120];
	
	if (iMax > 10)
		iMax = 10;
	
	for (new i = 0; i < iMax; i++)
	{
		get_stats(i, izStats, izBody, t_sName, charsmax(t_sName));
		formatex(message, charsmax(message), "\r \y%s    \w-  \r%d", t_sName, izStats[STATS_KILLS]);
		menu_additem( menu, message, "", 0 );
	}
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, menu, 0 );
}

public menu_handled( id, menu, item ) 
{
	if( item == MENU_EXIT ) 
	{
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public cmdRank(id)
{
	new izStats[8], izBody[8];
	new iRankPos, iRankMax;
	
	
	iRankMax = get_statsnum();
	
	client_print_color(id, print_team_grey, "^1[^4Dr.FioriGinal.Ro^1] ^3Poziția ta este ^1[^4%d^1] ^3din ^1[^4%d^1] ^3cu ^1[^4%d^1] ^3puncte.", iRankPos, iRankMax, izStats[STATS_KILLS]);
	return PLUGIN_CONTINUE;
}