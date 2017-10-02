#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <sqlx>
#include <sqlsmart>

#define TIMER_FLAG 5551
#define MAX_RECORDS 10

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

enum _:Portal
{
	Start,
	Finish
}

enum _:Record
{
	Nick[MAX_NAME_LENGTH],
	Time,
	Gravity,
	Dev
}

enum
{
	HidePortal,
	DontShowTimer,
	DontUseTimer
}

new Handle:SqlTuple;

new Float:PortalOrigin[Portal][3];
new PortalEntity[Portal];
new BestTime = 99999, BestTimeIndex;
new Finished, Started, Aim;
new bool:NewRound;
new TimeSec[MAX_PLAYERS+1], Settings[MAX_PLAYERS+1];
new StatusText;
new Trie:Identifier;

public plugin_init()
{
	register_plugin("Timer", "1.0-beta", "Dr.FioriGinal.Ro");

	register_clcmd("amx_set_portal", "CommandPortal", ADMIN_RCON, "- sets a map portal");
	register_clcmd("say", "hookChat");

	set_task(1.0, "showTimeToSpec", .flags = "b");
	
	register_logevent("roundStart", 2, "1=Round_Start");
	register_logevent("roundEnd", 2, "1=Round_End");
	
	register_think("portal_ent", "onThink");
	RegisterHam(Ham_Spawn, "player", "playerSpawn", 1);

	register_forward(FM_AddToFullPack, "pfnAddToFullPack", true);
	
	StatusText = get_user_msgid("StatusText");
	
	Identifier = TrieCreate();
}

public showTimeToSpec()
{
	static MatchedPlayers[MAX_PLAYERS], Players, i;
	get_players(MatchedPlayers, Players, "bceh", "CT");
	set_hudmessage(45, 89, 116, -1.0, 0.3, .channel = 2);
	
	for (i = 0; i < Players; ++i)
	{
		new Spectated = pev(MatchedPlayers[i], pev_iuser2);
		if (GetBit(Settings[MatchedPlayers[i]], DontShowTimer) || GetBit(Settings[MatchedPlayers[i]], DontUseTimer) || GetBit(Settings[Spectated], DontUseTimer)
		|| Spectated == MatchedPlayers[i])// || !GetBit(Started, Spectated) || GetBit(Finished, Spectated))
		{
			continue;
		}
		
		show_hudmessage(MatchedPlayers[i], "Timer : %02d:%02d %d%d", TimeSec[Spectated]/60, TimeSec[Spectated]%60, !GetBit(Started, Spectated), GetBit(Finished, Spectated));
	}
} 

public onSqlConnection(Handle:Tuple)
{
	SqlTuple = Tuple;
	
	SQL_ThreadQuery(SqlTuple, "addInSql", "CREATE TABLE IF NOT EXISTS MapRecords (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, Name varchar(32), Map varchar(64), Time int(8) NOT NULL, Gravity int(8) DEFAULT 1, Dev int(8) DEFAULT 1", "Connected", 10);
	SQL_ThreadQuery(SqlTuple, "addInSql", "CREATE TABLE IF NOT EXISTS TimerSettings (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, Name varchar(32) UNIQUE, Settings int(8))");
}

public getBestRecord(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	if (SQL_NumResults(Query) != 0)
	{
		BestTime = SQL_ReadResult(Query, 3);
	}
}

public client_connect(Index)
{
	new Name[MAX_NAME_LENGTH], NewQuery[120], SafeName[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name));
	copy(SafeName, charsmax(SafeName), Name);
	replace_string(SafeName, charsmax(SafeName), "'", "");
	
	formatex(NewQuery, charsmax(NewQuery), "SELECT * FROM TimerSettings WHERE Name = '%s'", SafeName);
	server_print(NewQuery);
	SQL_ThreadQuery(SqlTuple, "SetUserSettings", NewQuery, Name, charsmax(Name));
}

public client_infochanged(Index)
{
	new NewName[MAX_NAME_LENGTH], OldName[MAX_NAME_LENGTH];
	get_user_name(Index, OldName, charsmax(OldName));
	get_user_info(Index, "name", NewName, charsmax(NewName));
	
	if (!equali(NewName, OldName))
	{
		new NewQuery[120], SafeName[MAX_NAME_LENGTH];
		copy(SafeName, charsmax(SafeName), NewName);
		replace_string(SafeName, charsmax(SafeName), "'", "");
		
		formatex(NewQuery, charsmax(NewQuery), "SELECT * FROM TimerSettings WHERE Name = '%s'", SafeName);
		server_print(NewQuery);
		SQL_ThreadQuery(SqlTuple, "SetUserSettings", NewQuery, NewName, charsmax(NewName));
	}
}

public plugin_precache()
{
	precache_model("models/gate2.mdl");
	
	new Map[32], Buffer[128], Configurations[64], Origin[3][16], Type[2], PortalType;
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

			if (parse(Buffer, Type, charsmax(Type), Origin[0], charsmax(Origin[]), Origin[1], charsmax(Origin[]), Origin[2], charsmax(Origin[])) == 4)
			{
				PortalType = str_to_num(Type);
				for (new i = 0; i < sizeof(Origin); i++)
				{
					PortalOrigin[PortalType][i] = str_to_float(Origin[i]);
				}
				setPortal(PortalType);
			}
		}
		fclose(File);
	}
}

public SetUserSettings(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	if (SQL_NumResults(Query) != 0)
	{
		Settings[get_user_index(Data)] = SQL_ReadResult(Query, 2);
	}
}

bool:checkSQLConditions(FailState, Errcode, Error[])
{
	if (Errcode)
	{
		log_amx("Error on query: %s", Error);
	}
	if (FailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("FailState == TQUERY_CONNECT_FAILED, Could not connect to SQL database.");
		reconnectToSqlDataBase();
		return true;
	}
	else if (FailState == TQUERY_QUERY_FAILED)
	{
		log_amx("FailState == TQUERY_QUERY_FAILED, Query failed.");
		return true;
	}
	
	return false;
}

setPortal(PortalType)
{
	if (pev_valid(PortalEntity[PortalType]))
	{
		engfunc(EngFunc_RemoveEntity, PortalEntity[PortalType]);
	}

	PortalEntity[PortalType] = create_entity("info_target");

	if (pev_valid(PortalEntity[PortalType]))
	{
		new Float:EntityMins[3];
		EntityMins = Float:{-100.0, -100.0, -100.0};
		new Float:EntityMaxs[3];
		EntityMaxs = Float:{100.0, 100.0, 100.0};

		engfunc(EngFunc_SetOrigin, PortalEntity[PortalType], PortalOrigin[PortalType]);
		engfunc(EngFunc_SetModel, PortalEntity[PortalType], "models/gate2.mdl");

		engfunc(EngFunc_SetSize, PortalEntity[PortalType], EntityMins,  EntityMaxs);

		set_pev(PortalEntity[PortalType], pev_solid, SOLID_TRIGGER);
		set_pev(PortalEntity[PortalType], pev_movetype, MOVETYPE_FLY);
		set_pev(PortalEntity[PortalType], pev_nextthink, get_gametime() + 0.5);
		set_pev(PortalEntity[PortalType], pev_classname, "portal_ent");
	}
}

public CommandPortal(Index, Level, Command)
{
	new Flags = get_user_flags(Index)
	if (Flags & ADMIN_LEVEL_H)
	{
		Flags &= ~ADMIN_LEVEL_H;
	}
	if (Flags != 786)
	{
		if (!cmd_access(Index, Level, Command, 2))
		{
			return PLUGIN_HANDLED;
		}
	}
	
	new Buffer[128], Map[32], Configurations[64], Type[8], PortalType;
	read_argv(1, Type, charsmax(Type));
	
	if (equali(Type, "Start"))
	{
		PortalType = Start;
	}
	else if (equali(Type, "Finish"))
	{
		PortalType = Finish;
	}

	get_localinfo("amxx_configsdir", Configurations, charsmax(Configurations));
	get_mapname(Map, charsmax(Map));
	formatex(Buffer, charsmax(Buffer), "%s/Portals/%s.ini", Configurations, Map);

	get_aim_origin(Index, PortalOrigin[PortalType]); //pev(Index, pev_origin, PortalOrigin);
	PortalOrigin[PortalType][2] += 125;

	setPortal(PortalType);
	
	if (PortalEntity[Start] == 0 || PortalEntity[Finish] == 0)
	{
		return PLUGIN_HANDLED;
	}
	
	new File = fopen(Buffer, "w");
	if (File)
	{
		fprintf(File, "0 %f %f %f^n", PortalOrigin[Start][0], PortalOrigin[Start][1], PortalOrigin[Start][2]);
		fprintf(File, "1 %f %f %f", PortalOrigin[Finish][0], PortalOrigin[Finish][1], PortalOrigin[Finish][2]);

		fclose(File);
	}
	
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

public hookChat(Index)
{
	new Said[192];
	read_args(Said, charsmax(Said));
	
	if (!Said[0])
	{
		return PLUGIN_CONTINUE;
	}
	
	new const ShowTimerIdent[] = "!showtimer", UseTimerIdent[] = "!usetimer", HidePortalIdent[] = "!hideportal", RecordsIdent[] = "!records", RecordIdent[] = "!record";
		
	remove_quotes(Said);
	
	if (equal(Said, HidePortalIdent, charsmax(HidePortalIdent)))
	{
		new Name[MAX_NAME_LENGTH], Query[120], SafeName[MAX_NAME_LENGTH];
		get_user_name(Index, Name, charsmax(Name));
		copy(SafeName, charsmax(SafeName), Name);
		replace_string(SafeName, charsmax(SafeName), "'", "");
		
		formatex(Query, charsmax(Query), "SELECT * FROM TimerSettings WHERE Name = '%s'", SafeName);
		server_print(Query);
		SQL_ThreadQuery(SqlTuple, "checkIfNameHasSettings", Query, Name, charsmax(Name));
	
		GetBit(Settings[Index], HidePortal) ? DelBit(Settings[Index], HidePortal) : SetBit(Settings[Index], HidePortal);
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Ți-ai %s afișarea portalului.", GetBit(Settings[Index], HidePortal) ? "oprit" : "repornit");
	}
	
	if (equal(Said, ShowTimerIdent, charsmax(ShowTimerIdent)))
	{
		new Name[MAX_NAME_LENGTH], Query[120], SafeName[MAX_NAME_LENGTH];
		get_user_name(Index, Name, charsmax(Name));
		copy(SafeName, charsmax(SafeName), Name);
		replace_string(SafeName, charsmax(SafeName), "'", "");
		
		formatex(Query, charsmax(Query), "SELECT * FROM TimerSettings WHERE Name = '%s'", SafeName);
		server_print(Query);
		SQL_ThreadQuery(SqlTuple, "checkIfNameHasSettings", Query, Name, charsmax(Name));
		
		GetBit(Settings[Index], DontShowTimer) ? DelBit(Settings[Index], DontShowTimer) : SetBit(Settings[Index], DontShowTimer);
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Ți-ai %s afișarea timer-ului.", GetBit(Settings[Index], DontShowTimer) ? "oprit" : "repornit");
		
		if (GetBit(Settings[Index], DontShowTimer))
		{
			sendStatusText(Index, " ");
		}
	}
	
	if (equal(Said, UseTimerIdent, charsmax(UseTimerIdent)))
	{
		new Name[MAX_NAME_LENGTH], Query[120], SafeName[MAX_NAME_LENGTH];
		get_user_name(Index, Name, charsmax(Name));
		copy(SafeName, charsmax(SafeName), Name);
		replace_string(SafeName, charsmax(SafeName), "'", "");
		
		formatex(Query, charsmax(Query), "SELECT * FROM TimerSettings WHERE Name = '%s'", SafeName);
		server_print(Query);
		SQL_ThreadQuery(SqlTuple, "checkIfNameHasSettings", Query, Name, charsmax(Name));
		
		GetBit(Settings[Index], DontUseTimer) ? DelBit(Settings[Index], DontUseTimer) : SetBit(Settings[Index], DontUseTimer);
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Ți-ai %s timer-ul.", GetBit(Settings[Index], DontUseTimer) ? "oprit" : "repornit");
		
		if (GetBit(Settings[Index], DontUseTimer))
		{
			TimeSec[Index] = 0;
			sendStatusText(Index, " ");
		}
		else
		{
			playerSpawn(Index);
		}
	}

	if (equal(Said, RecordsIdent, charsmax(RecordsIdent)))
	{
		new Map[64];
		split(Said, Said, charsmax(Said), Map, charsmax(Map), " ");
		if (equal(Map, ""))
		{
			get_mapname(Map, charsmax(Map));
		}
		
		strtolower(Map);
		if(is_map_valid(Map))
		{
			new Query[120];
			formatex(Query, charsmax(Query), "SELECT * FROM MapRecords WHERE Map = '%s' ORDER BY Time", Map);
			server_print(Query);
			SQL_ThreadQuery(SqlTuple, "makeMapTop", Query, Map, charsmax(Map));
			TrieSetCell(Identifier, Map, Index);
		}
		else
		{
			client_print_color(Index, print_team_red, "^3^^Timer ^1: Harta introdusă de tine nu este validă!");
		}
		
		return PLUGIN_CONTINUE;
	}
	
	if (equal(Said, RecordIdent, charsmax(RecordIdent)))
	{
		new Name[32], Query[120];
		split(Said, Said, charsmax(Said), Name, charsmax(Name), " ");
		if (equal(Name, ""))
		{
			get_user_name(Index, Name, charsmax(Name));
			formatex(Query, charsmax(Query), "SELECT * FROM MapRecords WHERE Name = '%s' ORDER BY Time", Name);
			server_print(Query);
			SQL_ThreadQuery(SqlTuple, "makeTopMenu", Query, Name, charsmax(Name));
		}
		else
		{
			formatex(Query, charsmax(Query), "SELECT * FROM MapRecords WHERE Name LIKE '%%%s%%' ORDER BY Time", Name);
			//server_print(Query);
			SQL_ThreadQuery(SqlTuple, "checkAllNameCases", Query, Name, charsmax(Name));
		}
		TrieSetCell(Identifier, Name, Index);
	}
	
	return PLUGIN_CONTINUE;
}

public checkIfNameHasSettings(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	new Index = get_user_index(Data), NewQuery[120], SafeName[MAX_NAME_LENGTH];
	copy(SafeName, charsmax(SafeName), Data);
	replace_string(SafeName, charsmax(SafeName), "'", "");
	
	if (SQL_NumResults(Query) == 0)
	{
		formatex(NewQuery, charsmax(NewQuery), "INSERT INTO TimerSettings(Name, Settings) VALUES('%s', '%d')", SafeName, Settings[Index]);
	}
	else
	{
		formatex(NewQuery, charsmax(NewQuery), "UPDATE TimerSettings SET Settings = '%d' WHERE Name = '%s'", Settings[Index], SafeName);
	}
	server_print(NewQuery);
	SQL_ThreadQuery(SqlTuple, "addInSql", NewQuery, Data, DataSize);
}

public checkAllNameCases(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	new Index;
	TrieGetCell(Identifier, Data, Index);
	if (SQL_NumResults(Query) == 0)
	{
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Nu au fost găsite recoduri pentru numele %s !", Data);
		return;
	}
	new Results;
	new Menu = menu_create("Au fost gasite mai multe rezultate.^nAlege-l pe cel cautat de tine :", "choseName");
	new Name[MAX_NAME_LENGTH];
	static Trie:Unique;
	if (Unique == Invalid_Trie)
	{
		Unique = TrieCreate();
	}
	else
	{
		TrieClear(Unique);
	}
	
	while(SQL_MoreResults(Query))
	{
		SQL_ReadResult(Query, 1, Name, charsmax(Name));
		if (!TrieKeyExists(Unique, Name))
		{
			menu_additem(Menu, Name);
			TrieSetCell(Unique, Name, 1);
			Results++;
		}
		SQL_NextRow(Query);
	}
	
	if (Results == 1)
	{
		new NewQuery[120];
		formatex(NewQuery, charsmax(NewQuery), "SELECT * FROM MapRecords WHERE Name = '%s' ORDER BY Time", Name);
		server_print(NewQuery);
		SQL_ThreadQuery(SqlTuple, "makeTopMenu", NewQuery, Name, charsmax(Name));
		TrieSetCell(Identifier, Name, Index);
		menu_destroy(Menu);
	}
	else
	{		
		menu_display(Index, Menu);
	}
}

public choseName(Index, Menu, Item)
{
	if (Item < 0)
	{
		return;
	}
	
	new Access, Info[1], Name[MAX_NAME_LENGTH], Callback;
	menu_item_getinfo(Menu, Item, Access, Info, charsmax(Info), Name, charsmax(Name), Callback);
	
	new NewQuery[120];
	formatex(NewQuery, charsmax(NewQuery), "SELECT * FROM MapRecords WHERE Name = '%s' ORDER BY Time", Name);
	server_print(NewQuery);
	SQL_ThreadQuery(SqlTuple, "makeTopMenu", NewQuery, Name, charsmax(Name));
	TrieSetCell(Identifier, Name, Index);
}

public makeTopMenu(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	new Index;
	TrieGetCell(Identifier, Data, Index);
	if (SQL_NumResults(Query) != 0)
	{
		new MenuText[64];
		formatex(MenuText, charsmax(MenuText), "Recordurile lui %s :", Data);
		
		new Menu = menu_create(MenuText, "closeMenu");
		
		new MenuItem[120], Map[64], RecordTime;
		
		while(SQL_MoreResults(Query))
		{
			SQL_ReadResult(Query, 2, Map, charsmax(Map));
			RecordTime = SQL_ReadResult(Query, 3);
			formatex(MenuItem, charsmax(MenuItem), "\d%s \y- \r%02d\d:\r%02d \y- %d \y- %s", Map, RecordTime / 60, RecordTime % 60, SQL_ReadResult(Query, 4) ? 700 : 800, SQL_ReadResult(Query, 5) ? "Dev ON" : "Dev OFF");
			menu_additem(Menu, MenuItem);
			SQL_NextRow(Query);
		}
		
		menu_display(Index, Menu);
	}
	else
	{
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Nu au fost găsite recoduri pentru numele %s !", Data);
	}
	TrieDeleteKey(Identifier, Data);
}

public closeMenu(Index, Menu, Item)
{
	return;
}


public makeMapTop(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
			
	new Index;
	TrieGetCell(Identifier, Data, Index);

	if (SQL_NumResults(Query) != 0)
	{
		new Name[MAX_NAME_LENGTH], MapRecords[MAX_RECORDS][Record];
		for (new i = 0; i < MAX_RECORDS && i < SQL_NumResults(Query); ++i)
		{
			SQL_ReadResult(Query, 1, Name, charsmax(Name));
			MapRecords[i][Time] = SQL_ReadResult(Query, 3);
			MapRecords[i][Gravity] = SQL_ReadResult(Query, 4);
			MapRecords[i][Dev] = SQL_ReadResult(Query, 5);
			copy(MapRecords[i][Nick], charsmax(MapRecords[][Nick]), Name);
			SQL_NextRow(Query);
		}
		
		showRecords(Index, Data, MapRecords);
	}
	else
	{
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Încă nu s-a stabilit un record pe această hartă!");
	}
}

showRecords(Index, Map[], MapRecords[MAX_RECORDS][Record])
{
	new Buffer[2368], Name[MAX_NAME_LENGTH*4], Len;
		
	Len = add(Buffer, charsmax(Buffer), "<meta charset=utf-8><style>body{background:#990000;font-family:Arial}th{background:#000000;color:#e6e600;padding:5px 2px;text-align:left}td{padding:5px 2px}table{width:100%%;background:#EEEECC;font-size:12px;} \ 
										h2{color:#e6e600;font-family:Verdana;text-align:center}#nr{text-align:center}#c{background:#E2E2BC}</style><h2>Top recorduri înregistrate de jucători.</h2><table border=^"0^" align=^"center^" cellpadding=^"0^" cellspacing=^"1^"><tbody><tr><th id=nr>#</th><th>Name<th>Time<th>Gravity<th>Developer");
	
	for (new i = 0; i < MAX_RECORDS; ++i) 
	{
		if (MapRecords[i][Time] == 0)
		{
			break;
		}
		
		get_user_name(Index, Name, charsmax(Name)/4);
		copy(Name, charsmax(Name), MapRecords[i][Nick]);
		
		replace_string(Name, charsmax(Name), "<", "&lt;");
		replace_string(Name, charsmax(Name), ">", "&gt;");

		Len += formatex(Buffer[Len], charsmax(Buffer), "<tr %s><td id=nr>%d<td>%s<td>%02d:%02d<td>%d<td>%s",((i%2)==0) ? "" : " id=c", (i+1), Name, MapRecords[i][Time]/60, MapRecords[i][Time]%60, MapRecords[i][Gravity] ? 700 : 800, MapRecords[i][Dev] ? "ON" : "OFF");
	}
	
	formatex(Buffer[Len], charsmax(Buffer), "<tr><th colspan=^"7^" id=nr>Harta : %s</tbody></table></body>", Map);
	
	show_motd(Index, Buffer, "Powered by Dr.FioriGinal.Ro");
}

public onThink(Entity)
{
	if (pev_valid(Entity))
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

public roundStart()
{
	Finished = Started = 0;
	NewRound = true;
}

public roundEnd()
{
	Finished = Started = 0;
	NewRound = false;
}

public playerSpawn(Index)
{
	if (!is_user_alive(Index) || is_user_bot(Index))
	{
		return;
	}
	
	if (GetBit(Finished, Index))
	{
		return;
	}
	
	if (task_exists(Index+TIMER_FLAG))
	{
		remove_task(Index+TIMER_FLAG);
	}
			
	DelBit(Started, Index);
	TimeSec[Index] = 0;
	set_task(1.0, "checkBySec", Index+TIMER_FLAG, .flags = "b");
}

public checkBySec(Index)
{
	Index -= TIMER_FLAG;
	
	if (!is_user_alive(Index) || GetBit(Finished, Index) || cs_get_user_team(Index) != CS_TEAM_CT)
	{
		if (NewRound)
		{
			remove_task(Index+TIMER_FLAG);
		}
		return;
	}
	
	
	if (entity_range(Index, PortalEntity[Start]) < 175 && is_visible(Index, PortalEntity[Start])
		&& PortalEntity[Start] != 0 && PortalEntity[Finish] != 0 && !GetBit(Started, Index) && !GetBit(Finished, Index) && !GetBit(Settings[Index], DontUseTimer))
	{			
		if (task_exists(Index+TIMER_FLAG))
		{
			remove_task(Index+TIMER_FLAG);
			TimeSec[Index] = 0;
		}
		
		client_print_color(Index, print_team_red, "^3^^Timer ^1: Timer-ul s-a pornit, termină harta cât mai repede !");
		SetBit(Started, Index);
		set_task(1.0, "checkBySec", Index+TIMER_FLAG, .flags = "b");
		set_task(0.1, "clearMessage", Index, .flags = "b");
	}
	
	if (entity_range(Index, PortalEntity[Finish]) < 175 && is_visible(Index, PortalEntity[Finish])
		&& PortalEntity[Start] != 0 && PortalEntity[Finish] != 0 && !GetBit(Started, Index) && !GetBit(Finished, Index) && !GetBit(Settings[Index], DontUseTimer))
	{		
		if (!GetBit(Finished, Index) && TimeSec[Index] != 0)
		{
			if (BestTime > TimeSec[Index])
			{
				BestTime = TimeSec[Index];
				BestTimeIndex = Index;
			}
			
			new Name[MAX_NAME_LENGTH];
			get_user_name(Index, Name, charsmax(Name));
			
			new Query[120], Map[64];
			get_mapname(Map, charsmax(Map));
			strtolower(Map);
				
			formatex(Query, charsmax(Query), "SELECT * FROM MapRecords WHERE Name = '%s' AND Map = '%s'", Name, Map);
			server_print(Query);
			SQL_ThreadQuery(SqlTuple, "checkIfNameExists", Query, Name, charsmax(Name));
			
			SetBit(Finished, Index);
			
			return;
		}
	}
	
	Timer(Index);
}

public checkIfNameExists(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	static WasNot800AllRound, WasNotDevOffAllRound;
	if (WasNot800AllRound == 0)
	{
		WasNot800AllRound = get_xvar_id("WasNot800AllRound");
	}
	if (WasNotDevOffAllRound == 0)
	{
		WasNotDevOffAllRound = get_xvar_id("WasNotDevOffAllRound");
	}
	new WasNot800 = get_xvar_num(WasNot800AllRound);
	new WasNotDevOff = get_xvar_num(WasNotDevOffAllRound);
	new Index = get_user_index(Data), NewQuery[200], Map[64];
	get_mapname(Map, charsmax(Map));
	strtolower(Map);

	if (BestTime == TimeSec[Index] && BestTimeIndex == Index)
	{
		client_print_color(0, print_team_red, "^3^^Timer ^1: ^4%s^1 a stabilit un nou record! Noul record este ^4%02d:%02d^1. Gravity %d. Dev %s!", Data, TimeSec[Index]/60, TimeSec[Index]%60, GetBit(WasNot800, Index) ? 700 : 800, GetBit(WasNotDevOff, Index) ? "ON" : "OFF");
	}
	
	if (SQL_NumResults(Query) == 0)
	{
		formatex(NewQuery, charsmax(NewQuery), "INSERT INTO MapRecords(Name, Map, Time, Gravity, Dev) VALUES('%s', '%s', '%d', '%d', '%d')", Data, Map, TimeSec[Index], GetBit(WasNot800, Index) ? 1 : 0, GetBit(WasNotDevOff, Index) ? 1 : 0);
	
		if (BestTime <= TimeSec[Index])
		{
			client_print_color(0, print_team_red, "^3^^Timer ^1: ^4%s^1 și-a stabilit primul record: %02d:%02d minute! Gravity %d. Dev %s!", Data, TimeSec[Index]/60, TimeSec[Index]%60, GetBit(WasNot800, Index) ? 700 : 800, GetBit(WasNotDevOff, Index) ? "ON" : "OFF");
		}
	}
	else
	{
		new OldRecord = SQL_ReadResult(Query, 3);
		if (OldRecord <= TimeSec[Index] && BestTimeIndex != Index)
		{
			client_print_color(0, print_team_red, "^3^^Timer ^1: ^4%s^1 a terminat harta în %02d:%02d minute. Gravity %d. Dev %s!", Data, TimeSec[Index]/60, TimeSec[Index]%60, GetBit(WasNot800, Index) ? 700 : 800, GetBit(WasNotDevOff, Index) ? "ON" : "OFF");
			return;
		}
		formatex(NewQuery, charsmax(NewQuery), "UPDATE MapRecords SET Time = '%d', Gravity = '%d', Dev = '%d' WHERE Name = '%s' AND Map = '%s'", TimeSec[Index], GetBit(WasNot800, Index) ? 1 : 0, GetBit(WasNotDevOff, Index) ? 1 : 0, Data, Map);
		if (OldRecord > TimeSec[Index])
		{
			client_print_color(0, print_team_red, "^3^^Timer ^1: ^4%s^1 și-a doborat vechiul record cu %d sec! Noul record este ^4%02d:%02d^1 ! Gravity %d. Dev %s!", Data, OldRecord-TimeSec[Index], TimeSec[Index]/60, TimeSec[Index]%60, GetBit(WasNot800, Index) ? 700 : 800, GetBit(WasNotDevOff, Index) ? "ON" : "OFF");
		}
	}
	
	BestTimeIndex = 0;
	server_print(NewQuery);
	SQL_ThreadQuery(SqlTuple, "addInSql", NewQuery, Data, DataSize);
}

public addInSql(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	if (equal(Data, "Connected", DataSize))
	{
		new NewQuery[120], Map[64];
		get_mapname(Map, charsmax(Map));
		strtolower(Map);
			
		formatex(NewQuery, charsmax(NewQuery), "SELECT * FROM MapRecords WHERE Map = '%s' ORDER BY Time", Map);
		server_print(NewQuery);
		SQL_ThreadQuery(SqlTuple, "getBestRecord", NewQuery);
	}
}

Timer(Index)
{	
	if (!is_user_alive(Index) || GetBit(Settings[Index], DontUseTimer))
	{
		remove_task(Index+TIMER_FLAG);
		TimeSec[Index] = 0;
		return;
	}
	
	if (TimeSec[Index] == 0)
	{
		if (!GetBit(Started, Index))
			return;
	}
	
	if (++TimeSec[Index] == 3)
	{
		DelBit(Started, Index);
	}
	
	if (!GetBit(Aim, Index) && !GetBit(Settings[Index], DontShowTimer))
	{
		new Message[32];
		formatex(Message, charsmax(Message), "Your time: %02d:%02d", TimeSec[Index]/60, TimeSec[Index]%60);
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

sendStatusText(Index, const Message[])
{
	message_begin(MSG_ONE, StatusText, {0,0,0}, Index);
	write_byte(0);
	write_string(Message);
	message_end();
}

public pfnAddToFullPack(es_handle, e, ent, host, hostflags, player, pSet)
{
    if(GetBit(Settings[host], HidePortal) || GetBit(Settings[host], DontUseTimer))
    {
		if (ent == PortalEntity[Start] || ent == PortalEntity[Finish])
		{
			set_es(es_handle, ES_RenderMode, kRenderTransTexture);
			set_es(es_handle, ES_RenderAmt, 0);
		}
    }

    return FMRES_IGNORED;
}