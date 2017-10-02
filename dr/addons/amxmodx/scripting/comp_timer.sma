#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <xs>

#define PORTAL_FLAG 172
#define TIMER_FLAG 5551

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new Float:PortalOrigin[3], Float:PortalOrigin2[3];
new PortalEntity, PortalEntity2;
new Finished, Aim, DontShowTimer, DontUseTimer, HidePortal;
new TimeSec[MAX_PLAYERS+1], TimeMin[MAX_PLAYERS+1];
new GivedLife, InUseLife;
new StatusText;

public plugin_init()
{
	register_plugin("Timer", "1.0-beta", "Dr.FioriGinal.Ro");
	
	register_logevent("roundStart", 2, "1=Round_Start");
	
	RegisterHam(Ham_Spawn, "player", "playerSpawn", 1);
	//RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0);
	RegisterHam(Ham_Think, "info_target", "onThink");

	register_clcmd("amx_set_portal", "CommandPortal", ADMIN_RCON, "- sets a map portal");
	register_clcmd("amx_set_portal2", "CommandPortal2", ADMIN_RCON, "- sets a map portal");
	register_clcmd("say", "hookChat");
	register_touch("finish_portal", "player", "touchFinish");
	register_forward(FM_AddToFullPack, "pfnAddToFullPack", true);


	StatusText = get_user_msgid("StatusText");
}

public pfnAddToFullPack(es_handle, e, ent, host, hostflags, player, pSet)
{
    if(GetBit(HidePortal, host) || GetBit(DontUseTimer, host))
    {
		if(ent == PortalEntity)
		{
			set_es(es_handle, ES_RenderMode, kRenderTransTexture);
			set_es(es_handle, ES_RenderAmt, 0);
		}
    }

    return FMRES_IGNORED;
}


public hookChat(Index)
{
	new Said[192];
	read_args(Said, charsmax(Said));
	
	if (!Said[0])
	{
		return PLUGIN_CONTINUE;
	}
	
	new const ShowTimerIdent[] = "!showtimer", UseTimerIdent[] = "!usetimer", HidePortalIdent[] = "!hideportal";
		
	remove_quotes(Said);
	
	if (equal(Said, HidePortalIdent, charsmax(HidePortalIdent)))
	{
		GetBit(HidePortal, Index) ? DelBit(HidePortal, Index) : SetBit(HidePortal, Index);
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Ți-ai %s afișarea portalului.", GetBit(HidePortal, Index) ? "oprit" : "repornit");
	}
	
	if (equal(Said, ShowTimerIdent, charsmax(ShowTimerIdent)))
	{
		GetBit(DontShowTimer, Index) ? DelBit(DontShowTimer, Index) : SetBit(DontShowTimer, Index);
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Ți-ai %s afișarea timer-ului.", GetBit(DontShowTimer, Index) ? "oprit" : "repornit");
		
		if (GetBit(DontShowTimer, Index))
		{
			sendStatusText(Index, " ");
		}
	}
	
	if (equal(Said, UseTimerIdent, charsmax(UseTimerIdent)))
	{
		GetBit(DontUseTimer, Index) ? DelBit(DontUseTimer, Index) : SetBit(DontUseTimer, Index);
		client_print_color(Index, print_team_red, "^3^^Timer ^1: %s", GetBit(DontUseTimer, Index) ? "Ți-ai oprit afișarea timer-ului" : "Timer-ul se va reporni la următorul tău spawn.");
		
		if (GetBit(DontUseTimer, Index))
		{
			TimeSec[Index] = 0;
			TimeMin[Index] = 0;
			sendStatusText(Index, " ");
		}
	}
	
	return PLUGIN_CONTINUE;
}

public touchFinish(Touched, Toucher)
{	
	if (GetBit(DontUseTimer, Toucher))
	{
		return;
	}
	
	if (GivedLife != -1 && InUseLife != -1)
	{
		if (GetBit(get_xvar_num(GivedLife), Toucher) || GetBit(get_xvar_num(InUseLife), Toucher))
		{
			return;
		}
	}
	
	if (!GetBit(Finished, Toucher) && (TimeMin[Toucher] != 0 || TimeSec[Toucher] != 0) && cs_get_user_team(Toucher) == CS_TEAM_CT)
	{
		new Name[MAX_NAME_LENGTH];
		get_user_name(Toucher, Name, charsmax(Name));
		client_print_color(0, print_team_red, "^3^^Timer ^1: ^4%s^1 a terminat harta în %02d:%02d minute!", Name, TimeMin[Toucher], TimeSec[Toucher]);
		SetBit(Finished, Toucher);
	}
}

public playerSpawn(Index)
{
	if (!is_user_alive(Index) || PortalEntity == 0 || GetBit(DontUseTimer, Index))
	{
		return;
	}
	
	if (GivedLife == 0)
	{
		GivedLife = get_xvar_id("GivedLife");
	}
	
	if (InUseLife == 0)
	{
		InUseLife = get_xvar_id("InUseLife");
	}
	
	if (GivedLife != -1 && InUseLife != -1)
	{
		if (GetBit(get_xvar_num(GivedLife), Index) || GetBit(get_xvar_num(InUseLife), Index))
		{
			remove_task(Index+TIMER_FLAG);
			return;
		}
	}
	
	if (task_exists(Index+TIMER_FLAG))
	{
		remove_task(Index+TIMER_FLAG);
		TimeSec[Index] = 0;
		TimeMin[Index] = 0;
	}

	
	if (cs_get_user_team(Index) == CS_TEAM_CT && !is_user_bot(Index))
	{
		set_task(1.0, "roundTimer", Index+TIMER_FLAG, .flags = "b");
		set_task(0.1, "clearMessage", Index, .flags = "b");
	}
}

public roundTimer(Index)
{
	Index -= TIMER_FLAG;
	if (!is_user_alive(Index) || GetBit(DontUseTimer, Index))
	{
		remove_task(Index+TIMER_FLAG);
		TimeSec[Index] = 0;
		TimeMin[Index] = 0;
		return;
	}
	
	TimeSec[Index]++;
	if (TimeSec[Index] == 60)
	{
		TimeSec[Index] = 0;
		TimeMin[Index]++;
	}
	
	if (!GetBit(Aim, Index) && !GetBit(Finished, Index) && !GetBit(DontShowTimer, Index))
	{
		new Message[32];
		formatex(Message, charsmax(Message), "Your time: %02d:%02d", TimeMin[Index], TimeSec[Index]);
		sendStatusText(Index, Message);
	}
}

public clearMessage(Index)
{	
	new Target, Body;
	get_user_aiming(Index, Target, Body);
	if (1 <= Target <= MaxClients)
	{
		sendStatusText(Index, "1 %c1: %p2^n2  %h: %i3%%");		
		SetBit(Aim, Index);
	}
	else
	{
		if (GetBit(Finished, Index))
		{
			sendStatusText(Index, " ")
		}
		DelBit(Aim, Index);
	}
}

public roundStart()
{
	Finished = 0;
}

public onThink(Entity)
{
	if (pev_valid(Entity) && pev(Entity, pev_iuser4) == PORTAL_FLAG)
	{
		static Float:Angles[3];

		pev(Entity, pev_angles, Angles);
		Angles[1] += 5.0;

		if (Angles[1] > 360.0)
		{
			Angles[1] = 0.0;
		}

		set_pev(Entity, pev_angles, Angles);
		set_pev(Entity, pev_nextthink, get_gametime() + 0.5);
	}
}

public plugin_precache()
{
	precache_model("models/gate2.mdl");
	
	new Map[32], Buffer[128], Configurations[64], Origin[3][16];
	get_mapname(Map, charsmax(Map));
	get_localinfo("amxx_configsdir", Configurations, charsmax(Configurations));
	formatex(Buffer, charsmax(Buffer), "%s/Portals", Configurations);
	if (!dir_exists(Buffer))
	{
		mkdir(Buffer);
	}

	formatex(Buffer, charsmax(Buffer), "%s/Portals/%s.ini", Configurations, Map);

	new File = fopen(Buffer, "r");
	if (File)
	{
		while (!feof(File))
		{
			fgets(File, Buffer, charsmax(Buffer));
			trim(Buffer);

			if (parse(Buffer, Origin[0], charsmax(Origin[]), Origin[1], charsmax(Origin[]), Origin[2], charsmax(Origin[])) == 3)
			{
				for (new i = 0; i < sizeof(Origin); i++)
				{
					PortalOrigin[i] = str_to_float(Origin[i]);
				}
			}
		}
		fclose(File);

		setFinishPortal();
	}
}

public CommandPortal2(Index, Level, Command)
{
	if (!cmd_access(Index, Level, Command, 1))
	{
		return PLUGIN_HANDLED;
	}

	get_aim_origin(Index, PortalOrigin2); //pev(Index, pev_origin, PortalOrigin);
	PortalOrigin2[2] += 125;

	setFinishPortal2();
	
	return PLUGIN_HANDLED;
}

public CommandPortal(Index, Level, Command)
{
	if (!cmd_access(Index, Level, Command, 1))
	{
		return PLUGIN_HANDLED;
	}

	new Buffer[128], Map[32], Configurations[64];

	get_localinfo("amxx_configsdir", Configurations, charsmax(Configurations));
	get_mapname(Map, charsmax(Map));
	formatex(Buffer, charsmax(Buffer), "%s/Portals/%s.ini", Configurations, Map);

	get_aim_origin(Index, PortalOrigin); //pev(Index, pev_origin, PortalOrigin);
	PortalOrigin[2] += 125;

	new File = fopen(Buffer, "w");
	if (File)
	{
		fprintf(File, "%f %f %f", PortalOrigin[0], PortalOrigin[1], PortalOrigin[2]);

		fclose(File);
	}

	setFinishPortal();
	
	return PLUGIN_HANDLED;
}

get_aim_origin(index, Float:origin[3]) 
{
	new Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	new Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);

	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);
}

sendStatusText(Index, const Message[])
{
	message_begin(MSG_ONE, StatusText, {0,0,0}, Index);
	write_byte(0);
	write_string(Message);
	message_end();
}

setFinishPortal()
{
	if (pev_valid(PortalEntity))
	{
		engfunc(EngFunc_RemoveEntity, PortalEntity);
	}
	
	if (task_exists(PORTAL_FLAG))
	{
		remove_task(PORTAL_FLAG);
	}

	PortalEntity = create_entity("info_target");

	if (pev_valid(PortalEntity))
	{
		new Float:EntityMins[3];
		EntityMins = Float:{-100.0, -100.0, -100.0};
		new Float:EntityMaxs[3];
		EntityMaxs = Float:{100.0, 100.0, 100.0};

		engfunc(EngFunc_SetOrigin, PortalEntity, PortalOrigin);
		engfunc(EngFunc_SetModel, PortalEntity, "models/gate2.mdl");
		set_pev(PortalEntity, pev_classname, "finish_portal");

		engfunc(EngFunc_SetSize, PortalEntity, EntityMins,  EntityMaxs);

		set_pev(PortalEntity, pev_solid, SOLID_TRIGGER);
		set_pev(PortalEntity, pev_movetype, MOVETYPE_FLY);
		set_pev(PortalEntity, pev_iuser4, PORTAL_FLAG);
		set_pev(PortalEntity, pev_nextthink, get_gametime() + 0.5);
		set_pev(PortalEntity, pev_classname, "finish_portal");
	}
}

setFinishPortal2()
{
	if (pev_valid(PortalEntity2))
	{
		engfunc(EngFunc_RemoveEntity, PortalEntity2);
	}
	
	if (task_exists(PORTAL_FLAG))
	{
		remove_task(PORTAL_FLAG);
	}

	PortalEntity2 = create_entity("info_target");

	if (pev_valid(PortalEntity2))
	{
		new Float:EntityMins[3];
		EntityMins = Float:{-100.0, -100.0, -100.0};
		new Float:EntityMaxs[3];
		EntityMaxs = Float:{100.0, 100.0, 100.0};

		engfunc(EngFunc_SetOrigin, PortalEntity2, PortalOrigin2);
		engfunc(EngFunc_SetModel, PortalEntity2, "models/gate2.mdl");
		set_pev(PortalEntity2, pev_classname, "finish_portal");

		engfunc(EngFunc_SetSize, PortalEntity2, EntityMins,  EntityMaxs);

		set_pev(PortalEntity2, pev_solid, SOLID_TRIGGER);
		set_pev(PortalEntity2, pev_movetype, MOVETYPE_FLY);
		set_pev(PortalEntity2, pev_iuser4, PORTAL_FLAG);
		set_pev(PortalEntity2, pev_nextthink, get_gametime() + 0.5);
		set_pev(PortalEntity2, pev_classname, "finish_portal");
	}
}