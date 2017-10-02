/**
 *
 * Demo HUD Fix
 *  by Numb
 *
 *
 * Description:
 *  Have you ever watch a demo? Ever noticed slight but annoying little glitches at the
 *  beginning of it? Or maybe you like to play on a server which forces you to record it,
 *  but at that moment players appear to fly in mid air, or walk below the ground as if
 *  half-buried until they move up/down or respawn? Well, my plugin fixes this issues. I
 *  would really recommend it to be installed on servers what are using auto demo recorder
 *  plugins like this one ( http://forums.alliedmods.net/showthread.php?p=770786 ). Cause
 *  take a look how many bugs are fixed with it:
 *  + ScoreBoard will always work, even if you just launched the game.
 *  + ScoreBoard will show proper server name.
 *  + ScoreBoard will show on which team what players are at.
 *  + ScoreBoard will properly show who's dead, has the bomb, or is a VIP.
 *  + ScoreBoard will show proper player score.
 *  + Death messages and chat will be in accurate team color.
 *  + HUD flashlight icon will be properly filled to the point where it has to be.
 *  + HUD backup ammo will show the proper ammunition value
 *  + HUD zoom will always work, and always have the accurate crosshair.
 *  + HUD will show the actual armor type.
 *  + HUD nightvision will be enabled if it needs to be.
 *  + HUD hide function will work if other plugins are using it properly.
 *  + HUD round timer will be hidden if bomb is planted, and shown otherwise no matter
 *   what.
 *  + HUD planted bomb radar location will be there if needed.
 *  + HUD player names and hostage hp will show when looking at them (in demo and while
 *   recording).
 *  + When recording is started players will be at their right positions - no flying and no
 *   half-buried bodies.
 *
 *
 * Requires:
 *  FakeMeta
 *  HamSandWich
 *
 *
 * Additional Info:
 *  Tested in Counter-Strike 1.6 with amxmodx 1.8.2. For those of you who don't know, demo
 *  is a recording of your or somebody else's game. Demo can be recorded via "record
 *  my_demo_name" command, stopped via "stop" command, and watched via "viewdemo
 *  my_demo_name" or "playdemo my_demo_name" commands. You can download a demo example,
 *  which was recorded with this plugin and see for yourself the results (put the "*.dem"
 *  file in your "/cstrike" folder, and watch with "playdemo demo_example" console
 *  command).
 *
 *
 * Notes:
 *  When recording is started or "fullupdate" command is sent, chat will be forced up to
 *  console, and scoreboard will be closed if was open, since it needs to be refreshed.
 *
 *
 * Warnings:
 *  If you are using some kind of a plugin which blocks "fullupdate" command, chances are
 *  that the only glitch this plugin will fix for you is hostage hp and player names not
 *  being shown when looking at them. Also in order to fix vertical player positions,
 *  plugin blocks information sent about them for a single update pack. So it is possible
 *  that for the first one or three frames players will be invisible, however I personally
 *  don't even notice that.
 *
 *
 * ChangeLog:
 *
 *  + 1.0
 *  - First release.
 *
 *
 * Downloads:
 *  Amx Mod X forums: https://forums.alliedmods.net/showthread.php?p=2094293#post2094293
 *
**/


#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME	"Demo HUD Fix"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"Numb"

#pragma semicolon 1

#define SetPlayerBit(%1,%2)    ( %1 |=  ( 1 << ( %2 & 31 ) ) )
#define ClearPlayerBit(%1,%2)  ( %1 &= ~( 1 << ( %2 & 31 ) ) )
#define CheckPlayerBit(%1,%2)  ( %1 &   ( 1 << ( %2 & 31 ) ) )


#define m_iKevlarType 112
#define m_iTeam 114
#define TEAM_CS_UNASSIGNED 0
#define TEAM_CS_T 1
#define TEAM_CS_CT 2
#define TEAM_CS_SPECTATOR 3
#define m_fNvgState 129
#define NVG_ACTIVATED (1<<8) // 256
#define m_bHasC4 193
#define HAS_BOMB (1<<8) // 256
#define m_bIsVIP 209
#define m_flNextRadarUpdateTime 210
#define m_iFlashBattery 244
#define m_fInitHUD 348
#define m_fGameHUDInitialized 349
#define m_iHideHUD 361
#define m_iClientHideHUD 362
#define m_iFOV 363
#define m_iClientFOV 364
#define m_pActiveItem 373
#define m_rgAmmo_player 376
#define m_iDeaths 444
#define m_izSBarState 446 // [3]
#define m_flNextSBarUpdateTime 449
#define m_flStatusBarDisappearDelay 450
#define m_SbarString0 451 // 128/4=32 // [SBAR_STRING_SIZE] [128]
#define m_flNextFullUpdateTime 614 // float. changes at fullupdate to gametime+0.6

#define m_iId 43

#define m_fBombStatus 96
#define BOMB_DEFUSING (1<<0) // m_fStartDefuse
#define BOMB_PLANTED (1<<8) // m_fPlantedC4

new g_iMsgId_Flashlight;
new g_iMsgId_NVGToggle;
new g_iMsgId_AmmoX;
new g_iMsgId_TeamInfo;
new g_iMsgId_ScoreInfo;
new g_iMsgId_CurWeapon;
new g_iMsgId_ShowTimer;
new g_iMsgId_BombDrop;
new g_iMsgId_ArmorType;
new g_iMsgId_InitHUD;
new g_iMsgId_GameTitle;
new g_iMsgId_ServerName;

new HamHook:HamFwd_UpdateClData_Pre;
new HamHook:HamFwd_UpdateClData_Post;
new bool:g_bFwdEnabledPre;
new bool:g_bFwdEnabledPost;
new g_iFMFwd_AddToFullPack_Pre;

new bool:g_bBombPlanted;
new bool:g_bFixScoreAttrib;
new g_iFullUpdate;
new g_iCvar_HostName;
new g_iMaxPlayers;
new g_iFixPlayers[33];
new Float:g_fBombPos[3];

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_clcmd("fullupdate", "clcmd_fullupdate");
	
	register_event("HLTV",     "Event_NewRound",  "a", "1=0", "2=0");
	register_event("BombDrop", "Event_BombPlant", "a", "4=1");
	register_event("ResetHUD", "Event_ResetHUD",  "b");
	
	register_message(get_user_msgid("ScoreAttrib"), "Message_ScoreAttrib");
	register_message(get_user_msgid("RoundTime"),   "Message_RoundTime");
	register_message(get_user_msgid("Battery"),     "Message_Battery");
	
	HamFwd_UpdateClData_Pre  = RegisterHam(Ham_Player_UpdateClientData, "player", "Ham_UpdateCleintData_Pre",  0);
	HamFwd_UpdateClData_Post = RegisterHam(Ham_Player_UpdateClientData, "player", "Ham_UpdateCleintData_Post", 1);
	DisableHamForward(HamFwd_UpdateClData_Pre);
	DisableHamForward(HamFwd_UpdateClData_Post);
	
	g_iMsgId_Flashlight = get_user_msgid("Flashlight");
	g_iMsgId_NVGToggle  = get_user_msgid("NVGToggle");
	g_iMsgId_AmmoX      = get_user_msgid("AmmoX");
	g_iMsgId_TeamInfo   = get_user_msgid("TeamInfo");
	g_iMsgId_ScoreInfo  = get_user_msgid("ScoreInfo");
	g_iMsgId_CurWeapon  = get_user_msgid("CurWeapon");
	g_iMsgId_ShowTimer  = get_user_msgid("ShowTimer");
	g_iMsgId_BombDrop   = get_user_msgid("BombDrop");
	g_iMsgId_ArmorType  = get_user_msgid("ArmorType");
	g_iMsgId_InitHUD    = get_user_msgid("InitHUD");
	g_iMsgId_GameTitle  = get_user_msgid("GameTitle");
	g_iMsgId_ServerName = get_user_msgid("ServerName");
	
	g_iCvar_HostName = get_cvar_pointer("hostname");
	
	g_iMaxPlayers = clamp(get_maxplayers(), 1, 32);
}

public plugin_unpause()
{
	new iEnt;
	while( (iEnt=engfunc(EngFunc_FindEntityByString, iEnt, "classname", "grenade"))>0 )
	{
		if( pev_valid(iEnt) )
		{
			if( get_pdata_int(iEnt, m_fBombStatus, 5)&BOMB_PLANTED )
			{
				g_bBombPlanted = true;
				break;
			}
		}
	}
	if( iEnt<=0 )
		g_bBombPlanted = false;
	g_bFixScoreAttrib = false;
	g_iFullUpdate = 0;
	g_iFixPlayers[0] = 0;
	
	for( iEnt=1; iEnt<=g_iMaxPlayers; iEnt++ )
	{
		if( task_exists(iEnt) )
			remove_task(iEnt);
		g_iFixPlayers[iEnt] = 0;
	}
	
	if( g_bFwdEnabledPre )
	{
		DisableHamForward(HamFwd_UpdateClData_Pre);
		g_bFwdEnabledPre = false;
	}
	
	if( g_bFwdEnabledPost )
	{
		DisableHamForward(HamFwd_UpdateClData_Post);
		g_bFwdEnabledPost = false;
	}
	
	if( g_iFMFwd_AddToFullPack_Pre )
	{
		unregister_forward(FM_AddToFullPack, g_iFMFwd_AddToFullPack_Pre, 1);
		g_iFMFwd_AddToFullPack_Pre = 0;
	}
}

public client_disconnected(iPlrId)
{
	ClearPlayerBit(g_iFullUpdate, iPlrId);
	
	if( !g_iFullUpdate && g_bFwdEnabledPre )
	{
		DisableHamForward(HamFwd_UpdateClData_Pre);
		g_bFwdEnabledPre = false;
	}
	
	ClearPlayerBit(g_iFixPlayers[0], iPlrId);
	g_iFixPlayers[iPlrId] = 0;
	
	if( !g_iFixPlayers[0] && g_iFMFwd_AddToFullPack_Pre )
	{
		unregister_forward(FM_AddToFullPack, g_iFMFwd_AddToFullPack_Pre, 1);
		g_iFMFwd_AddToFullPack_Pre = 0;
	}
	
	if( task_exists(iPlrId) )
		remove_task(iPlrId);
}

public clcmd_fullupdate(iPlrId)
{
	if( is_user_connected(iPlrId) )
	{
		SetPlayerBit(g_iFullUpdate, iPlrId);
		
		if( !g_bFwdEnabledPre )
		{
			EnableHamForward(HamFwd_UpdateClData_Pre);
			g_bFwdEnabledPre = true;
		}
	}
}

public Event_ResetHUD(iPlrId) // this is needed to be fixed even on normal respwan
{
	new iLoop;
	for( iLoop=0; iLoop<3; iLoop++ )
		set_pdata_int(iPlrId, (m_izSBarState+iLoop), 0, 5);
	set_pdata_float(iPlrId, m_flNextSBarUpdateTime, (get_gametime()+0.2), 5);
	set_pdata_float(iPlrId, m_flStatusBarDisappearDelay, 0.0, 5);
	for( iLoop=0; iLoop<32; iLoop++ )
		set_pdata_int(iPlrId, (m_SbarString0+iLoop), 0, 5);
	
	if( g_bFwdEnabledPost || !get_pdata_int(iPlrId, m_fGameHUDInitialized, 5) )
		set_pdata_int(iPlrId, m_iClientHideHUD, !get_pdata_int(iPlrId, m_iHideHUD, 5), 5); // auto hud-hide update and flashlight (if needed)
}

public Event_NewRound()
	g_bBombPlanted = false;

public Event_BombPlant()
{
	g_bBombPlanted = true;
	read_data(1, g_fBombPos[0]);
	read_data(2, g_fBombPos[1]);
	read_data(3, g_fBombPos[2]);
}

public Message_ScoreAttrib(iMsgId, iMsgType, iPlrId) // update team color
{
	if( g_bFwdEnabledPost )
	{
		if( g_bFixScoreAttrib )
		{
			g_bFixScoreAttrib = false;
			
			client_print(iPlrId, print_chat, " "); // push chat in console (will be lost if not)
			client_print(iPlrId, print_chat, " ");
			client_print(iPlrId, print_chat, " ");
			client_print(iPlrId, print_chat, " ");
			client_print(iPlrId, print_chat, " ");
			
			message_begin(MSG_ONE, g_iMsgId_InitHUD, _, iPlrId); // scoreboard fix
			message_end();
			
			message_begin(MSG_ONE, g_iMsgId_GameTitle, _, iPlrId); // scoreboard fix again
			write_byte(0);
			message_end();
			
			new iHostName[32];
			get_pcvar_string(g_iCvar_HostName, iHostName, 31);
			
			message_begin(MSG_ONE, g_iMsgId_ServerName, _, iPlrId); // scoreboard server name
			write_string(iHostName);
			message_end();
		
			new iPlayers[32], iPlayerNum, iPlayer, iTemp;
			get_players(iPlayers, iPlayerNum);
			
			for( new iLoopId; iLoopId<iPlayerNum; iLoopId++ )
			{
				iPlayer = iPlayers[iLoopId];
				iTemp = get_pdata_int(iPlayer, m_iTeam, 5);
				
				message_begin(MSG_ONE, g_iMsgId_TeamInfo, _, iPlrId);
				write_byte(iPlayer);
				switch( iTemp )
				{
					case TEAM_CS_T: write_string("TERRORIST");
					case TEAM_CS_CT: write_string("CT");
					case TEAM_CS_SPECTATOR: write_string("SPECTATOR");
					default: write_string("UNASSIGNED");
				}
				message_end();
				
				message_begin(MSG_ONE, g_iMsgId_ScoreInfo, _, iPlrId);
				write_byte(iPlayer);
				write_short(get_user_frags(iPlayer));
				write_short(get_pdata_int(iPlayer, m_iDeaths, 5));
				write_short(0);
				write_short(iTemp);
				message_end();
				
				if( iPlayer==iPlrId )
					continue;
				
				if( is_user_alive(iPlayer) )
				{
					iTemp = 0;
					
					if( get_pdata_int(iPlayer, m_bHasC4, 5)&HAS_BOMB ) // pev(iPlayer, pev_weapons)&(1<<CSW_C4)
						iTemp |= (1<<1);
					if( get_pdata_int(iPlayer, m_bIsVIP, 5) )
						iTemp |= (1<<2);
				}
				else
					iTemp = (1<<0);
				
				message_begin(iMsgType, iMsgId, _, iPlrId);
				write_byte(iPlayer);
				write_byte(iTemp);
				message_end();
			}
		}
	}
}

public Message_RoundTime(iMsgId, iMsgType, iPlrId) // fix round timer if bomb is planted or was planted before watching demo
{
	if( g_bFwdEnabledPost )
	{
		if( g_bBombPlanted )
		{
			message_begin(MSG_ONE, g_iMsgId_BombDrop, _, iPlrId);
			engfunc(EngFunc_WriteCoord, g_fBombPos[0]);
			engfunc(EngFunc_WriteCoord, g_fBombPos[1]);
			engfunc(EngFunc_WriteCoord, g_fBombPos[2]);
			write_byte(1);
			message_end();
			
			return PLUGIN_HANDLED;
		}
		else
		{
			message_begin(MSG_ONE, g_iMsgId_ShowTimer, _, iPlrId);
			message_end();
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Message_Battery(iMsgId, iMsgType, iPlrId) // fix armor type
{
	if( g_bFwdEnabledPost )
	{
		message_begin(MSG_ONE, g_iMsgId_ArmorType, _, iPlrId);
		write_byte(((get_pdata_int(iPlrId, m_iKevlarType, 5)>1)?1:0));
		message_end();
	}
}

public Ham_UpdateCleintData_Pre(iPlrId)
{
	if( CheckPlayerBit(g_iFullUpdate, iPlrId) )
	{
		ClearPlayerBit(g_iFullUpdate, iPlrId);
			
		if( !g_iFullUpdate && g_bFwdEnabledPre )
		{
			DisableHamForward(HamFwd_UpdateClData_Pre);
			g_bFwdEnabledPre = false;
		}
		
		if( get_pdata_int(iPlrId, m_fInitHUD, 5) )
		{
			set_pdata_int(iPlrId, m_iClientFOV, !get_pdata_int(iPlrId, m_iFOV, 5), 5); // fix field of view
			
			if( task_exists(iPlrId) ) // update nightvision
				remove_task(iPlrId);
			set_task(0.1, "task_nightvision", iPlrId, "", 0, "a", 3);
			
			if( !g_bFwdEnabledPost )
			{
				EnableHamForward(HamFwd_UpdateClData_Post);
				g_bFwdEnabledPost = true;
			}
			
			g_bFixScoreAttrib = true;
		}
		else if( g_bFwdEnabledPost )
		{
			DisableHamForward(HamFwd_UpdateClData_Post);
			g_bFwdEnabledPost = false;
		}
	
	}
	else if( g_bFwdEnabledPost )
	{
		DisableHamForward(HamFwd_UpdateClData_Post);
		g_bFwdEnabledPost = false;
	}
}

public Ham_UpdateCleintData_Post(iPlrId)
{
	set_pdata_float(iPlrId, m_flNextRadarUpdateTime, get_pdata_float(iPlrId, m_flNextFullUpdateTime, 5), 5); // gametime+0.6
	
	if( g_bFwdEnabledPost )
	{
		DisableHamForward(HamFwd_UpdateClData_Post);
		g_bFwdEnabledPost = false;
	}
	
	g_bFixScoreAttrib = false;
	
	if( !g_iFMFwd_AddToFullPack_Pre )
	{
		SetPlayerBit(g_iFixPlayers[0], iPlrId);
		g_iFixPlayers[iPlrId] = 0;
		g_iFMFwd_AddToFullPack_Pre = register_forward(FM_AddToFullPack, "FM_AddToFullPack_Pre", 0);
	}
	
	if( is_user_alive(iPlrId) )
	{
		static s_iAmmoIndex;
		for( s_iAmmoIndex=1; s_iAmmoIndex<=14; s_iAmmoIndex++ ) // update backup ammo
		{
			message_begin(MSG_ONE, g_iMsgId_AmmoX, _, iPlrId);
			write_byte(s_iAmmoIndex);
			write_byte(get_pdata_int(iPlrId, (m_rgAmmo_player+s_iAmmoIndex), 5));
			message_end();
		}
		
		message_begin(MSG_ONE, g_iMsgId_Flashlight, _, iPlrId); // update flashlight
		write_byte(((pev(iPlrId, pev_effects)&EF_DIMLIGHT)?1:0));
		write_byte(get_pdata_int(iPlrId, m_iFlashBattery, 5));
		message_end();
	}
	else if( pev(iPlrId, pev_iuser1)==4 )
	{
		static s_iPlayer;
		s_iPlayer = pev(iPlrId, pev_iuser2);
		
		if( is_user_alive(s_iPlayer) ) // fix weapon
		{
			new iWpnEnt = get_pdata_cbase(s_iPlayer, m_pActiveItem, 5);
			if( pev_valid(iWpnEnt) )
			{
				message_begin(MSG_ONE, g_iMsgId_CurWeapon, _, iPlrId);
				write_byte(1);
				write_byte(get_pdata_int(iWpnEnt, m_iId, 4));
				write_byte(0);
				message_end();
			}
		}
	}
}

public FM_AddToFullPack_Pre(iHandle, iE, iEnt, iHost, iHostFlags, iPlayer, iPset)
{
	if( 0<iHost<=g_iMaxPlayers )
	{
		if( iPlayer && 0<iEnt<=g_iMaxPlayers && CheckPlayerBit(g_iFixPlayers[0], iHost) )
		{
			if( CheckPlayerBit(g_iFixPlayers[iHost], iEnt) )
			{
				ClearPlayerBit(g_iFixPlayers[0], iHost);
				g_iFixPlayers[iHost] = 0;
				
				if( !g_iFixPlayers[0] && g_iFMFwd_AddToFullPack_Pre )
				{
					unregister_forward(FM_AddToFullPack, g_iFMFwd_AddToFullPack_Pre, 1);
					g_iFMFwd_AddToFullPack_Pre = 0;
				}
			}
			else
			{
				SetPlayerBit(g_iFixPlayers[iHost], iEnt);
				
				if( iHost!=iEnt )
					return FMRES_SUPERCEDE; // fix player positions
			}
		}
	}
	
	return FMRES_IGNORED;
}

public task_nightvision(iPlrId) // needs delay for some reason
{
	static bool:s_bNvg;
	
	if( is_user_alive(iPlrId) )
		s_bNvg = ((get_pdata_int(iPlrId, m_fNvgState, 5)&NVG_ACTIVATED)?true:false);
	else if( pev(iPlrId, pev_iuser1)==4 )
	{
		static s_iPlayer;
		s_iPlayer = pev(iPlrId, pev_iuser2);
		
		if( is_user_alive(s_iPlayer) )
			s_bNvg = ((get_pdata_int(s_iPlayer, m_fNvgState, 5)&NVG_ACTIVATED)?true:false);
		else
			s_bNvg = ((get_pdata_int(iPlrId, m_fNvgState, 5)&NVG_ACTIVATED)?true:false);
	}
	else
		s_bNvg = ((get_pdata_int(iPlrId, m_fNvgState, 5)&NVG_ACTIVATED)?true:false);
	
	if( s_bNvg ) // resetHUD auto-disables it
	{
		emessage_begin(MSG_ONE, g_iMsgId_NVGToggle, _, iPlrId);
		ewrite_byte(1);
		emessage_end();
	}
}
