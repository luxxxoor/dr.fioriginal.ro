#include <amxmisc>
#include <cstrike>
#include <fakemeta>

#pragma semicolon 1

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new Float:GameTime[MAX_PLAYERS+1], FramesPer[MAX_PLAYERS+1], CurFps[MAX_PLAYERS+1], Fps[MAX_PLAYERS+1];//, UseSteam;
new const Tag[] = "[Dr.FioriGinal.Ro]";
public WasNotDevOffAllRound;

public plugin_init() 
{	
	register_plugin
	(
		.plugin_name = "Give Fps",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);

	register_clcmd("say", "hookChat");

	register_forward(FM_PlayerPreThink,"fwdPlayerPreThink");
}

/*public client_connect(Index)
{
	if (is_user_steam(Index))
	{
		SetBit(UseSteam, Index);
	}
	else
	{
		DelBit(UseSteam, Index);
	}
}*/

public hookChat(Index) 
{	
	new Said[192];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if ( Said[0] != '!' )
	{
		return PLUGIN_CONTINUE;
	}
	
	new const GetFpsIdent[] = "!getfps", ShowFpsIdent[] = "!showfps";
	
	if ( equali(Said, ShowFpsIdent, charsmax(ShowFpsIdent)) ) 
	{
		new Target[32];
		split(Said, Said, charsmax(Said), Target, charsmax(Target), " ");
		if ( equal(Target, "") )
		{
			showFps(Index, Index);
		}
		else
		{
			showFps(Index, cmd_target(Index, Target, CMDTARGET_NO_BOTS));
		}
		return PLUGIN_HANDLED;
	}
	if ( equal(Said, GetFpsIdent, charsmax(GetFpsIdent)) )
	{
		client_print_color(Index, print_team_red, "^4%s^3 !getfps ^1 a fost înlocuit cu ^3 !showfps^1!", Tag);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public showFps(Index, Target)  
{	
	if ( Target == 0 )
	{
		client_print_color(Index, print_team_red, "^4%s^1 Jucătorul nu se află pe server sau sunt mai mulți jucători cu același nume!", Tag);
		return;
	}
	
	if ( Index == Target )
	{
		if( !is_user_alive(Index) ) 
		{
			showFps(Index, pev(Index, pev_iuser2));
			return;
		}
		client_print_color(Index, print_team_red, "^4%s^1 Serverul a calculat că ai^3 %d^1 fps !", Tag, CurFps[Target]);
	}
	else
	{
		if( !is_user_alive(Target) ) 
		{
			client_print_color(Index, print_team_red, "^4%s^3 ^1 Jucătorul trebuie să fie în viață !", Tag);
			return;
		}
		new TargetName[MAX_NAME_LENGTH];
		get_user_name(Target, TargetName, charsmax(TargetName));
		client_print_color(Index, print_team_red, "^4%s^1 Serverul a calculat că^3 %s^1 are^3 %d^1 fps !", Tag, TargetName, CurFps[Target]);
	}
}

public fwdPlayerPreThink(Index) 
{
	if( is_user_alive(Index) ) // era is_user_connected()
	{
		GameTime[Index] = get_gametime();
				
		if(FramesPer[Index] >= GameTime[Index])
		{
			Fps[Index] += 1;
		}
		else 
		{
			FramesPer[Index]	+= 1;
			CurFps[Index]	= Fps[Index];
			Fps[Index]		= 0;
			/*if (cs_get_user_team(Index) == CS_TEAM_CT && !GetBit(UseSteam, Index) && CurFps[Index] > 260)
			{
				user_kill(Index);
				client_print_color(Index, print_team_red, "^4%s^1 Ai fost detectat că folosești %d fps. Limita maximă e de 250 fps.", Tag, CurFps[Index]);
			}*/
			if (CurFps[Index] > 110)
			{
				SetBit(WasNotDevOffAllRound, Index);
				//console_print(Index, "dev on %d fps", CurFps[Index]);
			}
		}
	}
	return FMRES_IGNORED;
}

stock bool:is_user_steam(Index)
{
	static dp_pointer;
	if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", Index);
		server_exec();
		return (get_pcvar_num(dp_pointer) == 2) ? true : false;
	}
	return false;
}