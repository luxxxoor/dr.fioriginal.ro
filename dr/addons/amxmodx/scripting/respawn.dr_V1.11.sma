#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

#define TASK_HIDE_TUTOR 8800

enum
{	
	RED = 1,
	BLUE,
	YELLOW,
	GREEN
}

new g_counter 
new Float:RoundStartTime

new g_Time_Interval;
//const MAX_PLAYERS = 32;
new gMsgTutorText, gMsgTutorClose, maxplayers;

new g_iRespawn[MAX_PLAYERS + 1], g_TeamInfoCounter[MAX_PLAYERS + 1], CsTeams:g_iPlayerTeam[MAX_PLAYERS + 1];
new g_pCvarRespawnTime, g_pCvarRespawnDelay, g_pCvarMaxHealth;

new g_isconnected[ 33 ], g_isbot[ 33 ];

public plugin_init()
{
	register_plugin("Dr.Respawn", "1.1", "Vicious Vixen"); 
	RegisterHam(Ham_Killed, "player", "fwdPlayerKilledPost", 1);
	RegisterHam(Ham_Spawn, "player", "fwdPlayerSpawnPost", 1);
	register_event("TeamInfo", "eTeamInfo", "a");
	register_logevent( "LogEventRoundStart", 2, "1=Round_Start" )
	g_pCvarRespawnTime = register_cvar("amx_respawn_tickets", "0"); //Set to 0 for unlimited respawns
	g_pCvarRespawnDelay = register_cvar("amx_respawn_delay", "1");
	g_pCvarMaxHealth = register_cvar("amx_max_health", "100");
	g_Time_Interval = register_cvar("amx_max_time", "30");
	set_msg_block( get_user_msgid( "ClCorpse" ), BLOCK_SET );
	
	//g_SyncRestartTimer = CreateHudSyncObj()
	//g_SyncGameStart = CreateHudSyncObj()
	
	gMsgTutorClose = get_user_msgid("TutorClose")
	gMsgTutorText = get_user_msgid("TutorText")
	maxplayers = get_maxplayers()
	
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	if( contain( szMapName, "deathrun_training" ) != -1 ) {
    set_pcvar_num(g_Time_Interval, 1500)
    server_cmd("zpnm_auto_respawn 1");
	}
	else {
    set_pcvar_num(g_Time_Interval, 30)
    server_cmd("zpnm_auto_respawn 0");
	}	
}

public client_putinserver ( id )
{
	g_isconnected[ id ] = true;

	if( is_user_bot( id ) )
		g_isbot[ id ] = true;

       /* if ( !is_user_bot ( id ) )
        {
                 client_cmd ( id , "wait;wait;wait;wait;wait;^"_restart^" ");
        }*/
}

public plugin_precache(){
	precache_generic("gfx/career/icon_!.tga");
	precache_generic("gfx/career/icon_!-bigger.tga");
	precache_generic("gfx/career/icon_i.tga");
	precache_generic("gfx/career/icon_i-bigger.tga");
	precache_generic("gfx/career/icon_skulls.tga");
	precache_generic("gfx/career/round_corner_ne.tga");
	precache_generic("gfx/career/round_corner_nw.tga");
	precache_generic("gfx/career/round_corner_se.tga");
	precache_generic("gfx/career/round_corner_sw.tga");

	precache_generic("resource/TutorScheme.res");
	precache_generic("resource/UI/TutorTextWindow.res");

	precache_sound("events/enemy_died.wav");
	precache_sound("events/friend_died.wav");
	precache_sound("events/task_complete.wav");
	precache_sound("events/tutor_msg.wav");
}

public client_disconnect( id )
{
	g_isconnected[ id ] = false;
	g_isbot[ id ] = false;
}

public LogEventRoundStart()
{
	RoundStartTime = get_gametime()
	
	new iPlayers[32]
	new iNum
	
	get_players( iPlayers, iNum )
	
	for( new i = 0; i < iNum; i++ )
	{
		g_iRespawn[iPlayers[i]] = true
	}
	set_task(1.0,"TimeCounter",123456,_,_,"a",get_pcvar_num(g_Time_Interval))
	set_task(get_pcvar_float(g_Time_Interval),"Runda_Terminata",789123)
}

public Runda_Terminata()
{
	if(RoundStartTime)
	{
		//set_hudmessage( 255, 0, 0, 0.09, 0.00, 1, 0.5, 1.0, 0.5, 15.0, -1)
		//ShowSyncHudMsg( 0, g_SyncGameStart, "Modul respawn este dezactivat!")
		for(new i = 1; i <= maxplayers; i++ )
		{
			/*if(!is_user_connected(i))
			{
				return PLUGIN_HANDLED;
			}*/
			if( !g_isconnected[ i ] || g_isbot[ i ] )
			        continue;
			
			Create_TutorMsg(i, "Modul respawn este dezactivat!", RED, false);
		}
	}
	return PLUGIN_CONTINUE;
}

public fwdPlayerKilledPost(iVictim, iKiller, iShoudlGib)
{
	if(g_iRespawn[iVictim]++ < get_pcvar_num(g_pCvarRespawnTime) || get_pcvar_num(g_pCvarRespawnTime) == 0)
	{
		set_task(get_pcvar_float(g_pCvarRespawnDelay), "taskRespawnPlayer", iVictim);
	}
	return HAM_IGNORED;
}

public fwdPlayerSpawnPost(iClient)
{
	if(is_user_alive(iClient))
	{
		set_pev(iClient, pev_health, get_pcvar_float(g_pCvarMaxHealth));
	}
}

public taskRespawnPlayer(id)
{
	if(is_user_connected(id) && RoundStartTime + get_pcvar_num(g_Time_Interval) >= get_gametime() && g_iRespawn[id] && !is_user_alive(id) && cs_get_user_team(id) != CS_TEAM_SPECTATOR) {
		ExecuteHamB(Ham_CS_RoundRespawn, id)
		g_iRespawn[id] = false
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}  

public eTeamInfo() 
{ 
	new iClient = read_data(1);
	new szTeam[2];
	read_data(2, szTeam, charsmax(szTeam));
	switch(szTeam[0])
	{
		case 'T': 
		{
			if(g_TeamInfoCounter[iClient] == 2 || g_iPlayerTeam[iClient] == CS_TEAM_SPECTATOR)
			{
				set_task(get_pcvar_float(g_pCvarRespawnDelay), "taskRespawnPlayer",  iClient);
			}
			g_iPlayerTeam[iClient] = CS_TEAM_T;
		}
		case 'C': 
		{
			if(g_TeamInfoCounter[iClient] == 2 || g_iPlayerTeam[iClient] == CS_TEAM_SPECTATOR)
			{
				set_task(get_pcvar_float(g_pCvarRespawnDelay), "taskRespawnPlayer",  iClient);
			}
			g_iPlayerTeam[iClient] = CS_TEAM_CT;
		}
		case 'S':
		{
			remove_task(iClient);
			g_iPlayerTeam[iClient] = CS_TEAM_SPECTATOR;
		}
	}
}

public TimeCounter() 
{
	g_counter++
	
	new Float:iRestartTime = get_pcvar_float(g_Time_Interval) - g_counter
	new Float:fSec
	fSec = iRestartTime 
	
	//set_hudmessage( 255, 0, 0, 0.09, 0.0, 1, 0.0, 1.0, 0.0, 0.0, -1)
	//ShowSyncHudMsg( 0, g_SyncRestartTimer, "Au mai ramas %d secunde de respawn", floatround(fSec))
	if(floatround(fSec) == 29)
	{
	for(new i = 1; i <= maxplayers; i++ )
	{
		/*if(!is_user_connected(i))
		{
			return PLUGIN_HANDLED;
		}*/
		if( !g_isconnected[ i ] || g_isbot[ i ] )
			continue;
		
		Create_TutorMsg(i, "Au mai ramas 30 secunde de respawn" ,GREEN, false)
	}
	}
	if(floatround(fSec) == 19)
	{
	for(new i = 1; i <= maxplayers; i++ )
	{
		/*if(!is_user_connected(i))
		{
			return PLUGIN_HANDLED;
		}*/
		if( !g_isconnected[ i ] || g_isbot[ i ] )
			continue;
		
		Create_TutorMsg(i, "Au mai ramas 20 secunde de respawn" ,GREEN, false)
	}
	}
	if(floatround(fSec) == 9)
	{
	for(new i = 1; i <= maxplayers; i++ )
	{
		/*if(!is_user_connected(i))
		{
			return PLUGIN_HANDLED;
		}*/
		if( !g_isconnected[ i ] || g_isbot[ i ] )
			continue;
		Create_TutorMsg(i, "Au mai ramas 10 secunde de respawn" ,YELLOW, false)
	}
	}
	if(get_pcvar_num(g_Time_Interval) - g_counter < 11 && get_pcvar_num(g_Time_Interval) - g_counter !=0)
	{
		static szNum[32]
		num_to_word(get_pcvar_num(g_Time_Interval) - g_counter, szNum, 31)
	}
	if(g_counter == get_pcvar_num(g_Time_Interval))
	{
		g_counter = 0
	}
	return PLUGIN_CONTINUE;
}

stock Create_TutorMsg(id, szMsg[], iStyle, bool:bSound){

	// Emulate played sounds of the original tutor
	// Don't play this sounds for automatic messages on dead players
	if (bSound){
		switch(iStyle)
		{
			case 0: emit_sound(id, CHAN_ITEM, "events/tutor_msg.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			case 1: emit_sound(id, CHAN_ITEM, "events/task_complete.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			case 2: emit_sound(id, CHAN_ITEM, "events/enemy_died.wav", VOL_NORM, ATTN_NORM, 0, PITCH_LOW)
			case 3: emit_sound(id, CHAN_ITEM, "events/friend_died.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
		}
	}

	// I think we can remove this but this is called by the original
	// Hide Tutor
	message_begin(MSG_ONE_UNRELIABLE , gMsgTutorClose, {0, 0, 0}, id)
	message_end()

	// Create a Tutor message
	message_begin(MSG_ONE_UNRELIABLE , gMsgTutorText, {0, 0, 0}, id)
	write_string(szMsg)		// displayed message
	write_byte(0)		// ???
	write_short(0)		// ???
	write_short(0)		// ???
	write_short(1<<iStyle)	// class of a message
	message_end()

	// Hide Tutor in ... seconds
	remove_task(TASK_HIDE_TUTOR+id)
	set_task( 5.0 , "Remove_TutorMsg", TASK_HIDE_TUTOR+id)

}

public Remove_TutorMsg(taskid){
	new id = (taskid > TASK_HIDE_TUTOR) ? (taskid - TASK_HIDE_TUTOR) : taskid
	message_begin(MSG_ONE_UNRELIABLE , gMsgTutorClose, {0, 0, 0}, id)
	message_end()
}
