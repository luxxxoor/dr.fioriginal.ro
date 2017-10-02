#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <regex>

#define PLUGIN_NAME	"Advanced Bans"
#define PLUGIN_VERSION	"0.8.1"
#define PLUGIN_AUTHOR	"Exolent"

#pragma semicolon 1

#include <sqlx>

#define TABLE_NAME		"advanced_bans"
#define KEY_NAME		"name"
#define KEY_STEAMID		"steamid"
#define KEY_BANLENGTH		"banlength"
#define KEY_UNBANTIME		"unbantime"
#define KEY_REASON		"reason"
#define KEY_ADMIN_NAME		"admin_name"
#define KEY_ADMIN_STEAMID	"admin_steamid"
#define KEY_SERVER          "server"
new const Server[] = "Cs.FioriGinal.Ro";

#define RELOAD_BANS_INTERVAL	60.0

#define REGEX_IP_PATTERN "\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
#define REGEX_STEAMID_PATTERN "^^STEAM_0:(0|1):\d+$"

new Regex:g_IP_pattern;
new Regex:g_SteamID_pattern;
new g_regex_return;

#define IsValidIP(%1) (regex_match_c(%1, g_IP_pattern, g_regex_return) > 0)

#define IsValidAuthid(%1) (regex_match_c(%1, g_SteamID_pattern, g_regex_return) > 0)

enum _:BannedData
{
	bd_name[32],
	bd_steamid[35],
	bd_banlength,
	bd_unbantime[32],
	bd_reason[128],
	bd_admin_name[64],
	bd_admin_steamid[35],
	bd_server_name[64]
};

new Trie:g_trie;
new Array:g_array;

new g_total_bans;

new Handle:g_sql_tuple;
new bool:g_loading_bans = true;

new ab_immunity;
new ab_bandelay;
new ab_unbancheck;

new Array:g_maxban_times;
new Array:g_maxban_flags;

new g_total_maxban_times;

new g_unban_entity;

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_cvar("advanced_bans", PLUGIN_VERSION, FCVAR_SPONLY);
	
	register_dictionary("advanced_bans.txt");
	
	register_concmd("amx_ban", "CmdBan", ADMIN_BAN|ADMIN_BAN_TEMP, "<nick, #userid, authid> <time in minutes> <reason>");
	register_concmd("amx_banip", "CmdBanIp", ADMIN_BAN|ADMIN_BAN_TEMP, "<nick, #userid, authid> <time in minutes> <reason>");
	register_concmd("amx_addban", "CmdAddBan", ADMIN_BAN|ADMIN_BAN_TEMP, "<name> <authid or ip> <time in minutes> <reason>");
	register_concmd("amx_unban", "CmdUnban", ADMIN_BAN|ADMIN_BAN_TEMP, "<authid or ip>");
	register_concmd("amx_banlist", "CmdBanList", ADMIN_BAN|ADMIN_BAN_TEMP, "[start] -- shows everyone who is banned");
	register_srvcmd("amx_addbanlimit", "CmdAddBanLimit", -1, "<flag> <time in minutes>");
	
	ab_immunity = register_cvar("ab_immunity", "1");
	ab_bandelay = register_cvar("ab_bandelay", "1.0");
	ab_unbancheck = register_cvar("ab_unbancheck", "5.0");
	
	g_trie = TrieCreate();
	g_array = ArrayCreate(BannedData);
	
	new const Host[] = "89.40.104.2",
			  User[] = "vuser154",
			  Pass[] = "clawsiluxor",
			  Db[]   = "vuser154";
			  
	g_sql_tuple = SQL_MakeDbTuple(Host, User, Pass, Db);
	new ErrorCode, SqlError[512], Handle:SqlConnection = SQL_Connect(g_sql_tuple, ErrorCode, SqlError, charsmax(SqlError));
	if (SqlConnection == Empty_Handle)
	{
		set_fail_state(SqlError);
	}
	PrepareTable();
	
	g_maxban_times = ArrayCreate(1);
	g_maxban_flags = ArrayCreate(1);
	
	new error[2];
	g_IP_pattern = regex_compile(REGEX_IP_PATTERN, g_regex_return, error, charsmax(error));
	g_SteamID_pattern = regex_compile(REGEX_STEAMID_PATTERN, g_regex_return, error, charsmax(error));
}

PrepareTable()
{
	new query[320];
	formatex(query, charsmax(query),\
		"CREATE TABLE IF NOT EXISTS `%s` (`%s` varchar(32) NOT NULL, `%s` varchar(35) NOT NULL, `%s` int(10) NOT NULL, `%s` varchar(32) NOT NULL, `%s` varchar(128) NOT NULL, `%s` varchar(64) NOT NULL, `%s` varchar(35) NOT NULL,  `%s` varchar(64) NOT NULL);",\
		TABLE_NAME, KEY_NAME, KEY_STEAMID, KEY_BANLENGTH, KEY_UNBANTIME, KEY_REASON, KEY_ADMIN_NAME, KEY_ADMIN_STEAMID, KEY_SERVER
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryCreateTable", query);
}

public QueryCreateTable(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		LoadBans();
	}
}

public plugin_cfg()
{
	CreateUnbanEntity();
}

public CreateUnbanEntity()
{
	static failtimes;
	
	g_unban_entity = create_entity("info_target");
	
	if( !is_valid_ent(g_unban_entity) )
	{
		++failtimes;
		
		log_amx("[ERROR] Failed to create unban entity (%i/10)", failtimes);
		
		if( failtimes < 10 )
		{
			set_task(1.0, "CreateUnbanEntity");
		}
		else
		{
			log_amx("[ERROR] Could not create unban entity!");
		}
		
		return;
	}
	
	entity_set_string(g_unban_entity, EV_SZ_classname, "unban_entity");
	entity_set_float(g_unban_entity, EV_FL_nextthink, get_gametime() + 1.0);
	
	register_think("unban_entity", "FwdThink");
}

public client_authorized(client)
{
	static authid[35];
	get_user_authid(client, authid, charsmax(authid));
	
	static ip[35];
	get_user_ip(client, ip, charsmax(ip), 1);
	
	static array_pos;
	
	if( TrieGetCell(g_trie, authid, array_pos) || TrieGetCell(g_trie, ip, array_pos) )
	{
		static data[BannedData];
		ArrayGetArray(g_array, array_pos, data);
		
		server_print("test");
		PrintBanInformation(client, data[bd_name], data[bd_steamid], data[bd_reason], data[bd_banlength], data[bd_unbantime], data[bd_admin_name], data[bd_admin_steamid], data[bd_server_name], true);
		server_print("test2");
		
		set_task(get_pcvar_float(ab_bandelay), "TaskDisconnectPlayer", client);
	}
}

public CmdBan(client, level, cid)
{
	if( !cmd_access(client, level, cid, 4) ) return PLUGIN_HANDLED;
	
	static arg[128];
	read_argv(1, arg, charsmax(arg));
	
	new target = cmd_target(client, arg, GetTargetFlags(client));
	if( !target ) return PLUGIN_HANDLED;
	
	static target_authid[35];
	get_user_authid(target, target_authid, charsmax(target_authid));
	
	if( !IsValidAuthid(target_authid) )
	{
		console_print(client, "%L", client, "AB_NOT_AUTHORIZED");
		new target_ip[35];
		get_user_ip(target, target_ip, charsmax(target_ip), 1);
		new length = str_to_num(arg);
		BanIp(client, target, target_ip, length, arg, GetMaxBanTime(client));
		return PLUGIN_HANDLED;
	}
	
	if( TrieKeyExists(g_trie, target_authid) )
	{
		console_print(client, "%L", client, "AB_ALREADY_BANNED_STEAMID");
		return PLUGIN_HANDLED;
	}
	
	read_argv(2, arg, charsmax(arg));
	
	new length = str_to_num(arg);
	new maxlength = GetMaxBanTime(client);
	
	read_argv(3, arg, charsmax(arg));
	
	if( maxlength && (!length || length > maxlength) )
	{
		console_print(client, "%L", client, "AB_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
	
	static unban_time[64];
	if( length == 0 )
	{
		console_print(client, "%L", client, "AB_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
	else
	{
		GenerateUnbanTime(length, unban_time, charsmax(unban_time));
	}
	
	static admin_name[64], target_name[32];
	get_user_name(client, admin_name, charsmax(admin_name));
	get_user_name(target, target_name, charsmax(target_name));
	
	static admin_authid[35];
	get_user_authid(client, admin_authid, charsmax(admin_authid));
	
	AddBan(target_name, target_authid, arg, length, unban_time, admin_name, admin_authid);
	
	PrintBanInformation(target, target_name, target_authid, arg, length, unban_time, admin_name, admin_authid, Server, true);
	PrintBanInformation(client, target_name, target_authid, arg, length, unban_time, admin_name, admin_authid, Server, false);
	
	set_task(get_pcvar_float(ab_bandelay), "TaskDisconnectPlayer", target);
	
	GetBanTime(length, unban_time, charsmax(unban_time));
	
	PrintActivity(admin_name, "$name :  banned %s. Reason: %s. Ban Length: %s", target_name, arg, unban_time);
	
	Log("%s <%s> banned %s <%s> || Reason: ^"%s^" || Ban Length: %s", admin_name, admin_authid, target_name, target_authid, arg, unban_time);
	
	return PLUGIN_HANDLED;
}

public CmdBanIp(client, level, cid)
{
	if( !cmd_access(client, level, cid, 4) ) return PLUGIN_HANDLED;
	
	static arg[128];
	read_argv(1, arg, charsmax(arg));
	
	new target = cmd_target(client, arg, GetTargetFlags(client));
	if( !target ) return PLUGIN_HANDLED;
	
	static target_ip[35];
	get_user_ip(target, target_ip, charsmax(target_ip), 1);
	
	if( TrieKeyExists(g_trie, target_ip) )
	{
		console_print(client, "%L", client, "AB_ALREADY_BANNED_IP");
		return PLUGIN_HANDLED;
	}
	
	read_argv(2, arg, charsmax(arg));
	
	new length = str_to_num(arg);
	new maxlength = GetMaxBanTime(client);
	
	if( maxlength && (!length || length > maxlength) )
	{
		console_print(client, "%L", client, "AB_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
		
	read_argv(3, arg, charsmax(arg));
	
	BanIp(client, target, target_ip, length, arg, maxlength);
	return PLUGIN_HANDLED;
}
	
BanIp(client, target, target_ip[], length, reason[], maxlength)
{
	static unban_time[32];
	
	if( length == 0 )
	{
		console_print(client, "%L", client, "AB_MAX_BAN_TIME", maxlength);
		return;
	}
	else
	{
		GenerateUnbanTime(length, unban_time, charsmax(unban_time));
	}
	
	static admin_name[64], target_name[32];
	get_user_name(client, admin_name, charsmax(admin_name));
	get_user_name(target, target_name, charsmax(target_name));
	
	static admin_authid[35];
	get_user_authid(client, admin_authid, charsmax(admin_authid));
	
	AddBan(target_name, target_ip, reason, length, unban_time, admin_name, admin_authid);
	
	PrintBanInformation(target, target_name, target_ip, reason, length, unban_time, admin_name, admin_authid, Server, true);
	PrintBanInformation(client, target_name, target_ip, reason, length, unban_time, admin_name, admin_authid, Server, false);
	
	set_task(get_pcvar_float(ab_bandelay), "TaskDisconnectPlayer", target);
	
	GetBanTime(length, unban_time, charsmax(unban_time));
	
	PrintActivity(admin_name, "$name : banned %s. Reason: %s. Ban Length: %s", target_name, reason, unban_time);
	
	Log("%s <%s> banned %s <%s> || Reason: ^"%s^" || Ban Length: %s", admin_name, admin_authid, target_name, target_ip, reason, unban_time);
}

public CmdAddBan(client, level, cid)
{
	if( !cmd_access(client, level, cid, 5) ) return PLUGIN_HANDLED;
	
	static target_name[32], target_authid[35], bantime[10], reason[128];
	read_argv(1, target_name, charsmax(target_name));
	read_argv(2, target_authid, charsmax(target_authid));
	read_argv(3, bantime, charsmax(bantime));
	read_argv(4, reason, charsmax(reason));
	
	new bool:is_ip = bool:(containi(target_authid, ".") != -1);
	
	if( !is_ip && !IsValidAuthid(target_authid) )
	{
		console_print(client, "%L", client, "AB_INVALID_STEAMID");
		console_print(client, "%L", client, "AB_VALID_STEAMID_FORMAT");
		
		return PLUGIN_HANDLED;
	}
	else if( is_ip )
	{
		new pos = contain(target_authid, ":");
		if( pos > 0 )
		{
			target_authid[pos] = 0;
		}
		
		if( !IsValidIP(target_authid) )
		{
			console_print(client, "%L", client, "AB_INVALID_IP");
			
			return PLUGIN_HANDLED;
		}
	}
	
	if( TrieKeyExists(g_trie, target_authid) )
	{
		console_print(client, "%L", client, is_ip ? "AB_ALREADY_BANNED_IP" : "AB_ALREADY_BANNED_STEAMID");
		return PLUGIN_HANDLED;
	}

	
	new length = str_to_num(bantime);
	new maxlength = GetMaxBanTime(client);
	
	if( maxlength && (!length || length > maxlength) )
	{
		console_print(client, "%L", client, "AB_MAX_BAN_TIME", maxlength);
		return PLUGIN_HANDLED;
	}
	
	if( is_user_connected(find_player(is_ip ? "d" : "c", target_authid)) )
	{
		client_cmd(client, "amx_ban ^"%s^" %i ^"%s^"", target_authid, length, reason);
		return PLUGIN_HANDLED;
	}
	
	static unban_time[32];
	if( length == 0 )
	{
		formatex(unban_time, charsmax(unban_time), "%L", client, "AB_PERMANENT_BAN");
	}
	else
	{
		GenerateUnbanTime(length, unban_time, charsmax(unban_time));
	}
	
	static admin_name[64], admin_authid[35];
	get_user_name(client, admin_name, charsmax(admin_name));
	get_user_authid(client, admin_authid, charsmax(admin_authid));
	
	AddBan(target_name, target_authid, reason, length, unban_time, admin_name, admin_authid);
	
	PrintBanInformation(client, target_name, target_authid, reason, length, unban_time, "", "", Server, false);
	
	GetBanTime(length, unban_time, charsmax(unban_time));
	
	PrintActivity(admin_name, "$name :  banned %s %s. Reason: %s. Ban Length: %s", is_ip ? "IP" : "SteamID", target_authid, reason, unban_time);
	
	Log("%s <%s> banned %s <%s> || Reason: ^"%s^" || Ban Length: %s", admin_name, admin_authid, target_name, target_authid, reason, unban_time);
	
	return PLUGIN_HANDLED;
}

public CmdUnban(client, level, cid)
{
	if( !cmd_access(client, level, cid, 2) ) return PLUGIN_HANDLED;
	
	static arg[35];
	read_argv(1, arg, charsmax(arg));
	
	
	if( TrieKeyExists(g_trie, arg) )
	{
		static array_pos;
		TrieGetCell(g_trie, arg, array_pos);
		
		static data[BannedData];
		ArrayGetArray(g_array, array_pos, data);
		
		static unban_name[32];
		get_user_name(client, unban_name, charsmax(unban_name));
		
		PrintActivity(unban_name, "$name :  unbanned %s [%s] [Ban Reason: %s]", data[bd_name], data[bd_steamid], data[bd_reason]);
		
		static admin_name[64];
		get_user_name(client, admin_name, charsmax(admin_name));
		
		static authid[35];
		get_user_authid(client, authid, charsmax(authid));
		
		Log("%s <%s> unbanned %s <%s> || Ban Reason: ^"%s^"", admin_name, authid, data[bd_name], data[bd_steamid], data[bd_reason]);
		
		RemoveBan(array_pos, data[bd_steamid]);
		
		return PLUGIN_HANDLED;
	}
	
	console_print(client, "%L", client, "AB_NOT_IN_BAN_LIST", arg);
	
	return PLUGIN_HANDLED;
}

public CmdBanList(client, level, cid)
{
	if( !cmd_access(client, level, cid, 1) ) return PLUGIN_HANDLED;
	
	if( !g_total_bans )
	{
		console_print(client, "%L", client, "AB_NO_BANS");
		return PLUGIN_HANDLED;
	}
	
	static start;
	
	if( read_argc() > 1 )
	{
		static arg[5];
		read_argv(1, arg, charsmax(arg));
		
		start = min(str_to_num(arg), g_total_bans) - 1;
	}
	else
	{
		start = 0;
	}
	
	new last = min(start + 10, g_total_bans);
	
	console_print(client, "^"%L^"", client, "AB_BAN_LIST_NUM", start + 1, last);
	
	for( new i = start; i < last; i++ )
	{
		static data[BannedData];
		ArrayGetArray(g_array, i, data);
		
		PrintBanInformation(client, data[bd_name], data[bd_steamid], data[bd_reason], data[bd_banlength], data[bd_unbantime], data[bd_admin_name], data[bd_admin_steamid], data[bd_server_name], true);
	}
	
	if( ++last < g_total_bans )
	{
		console_print(client, "^"%L^"", client, "AB_BAN_LIST_NEXT", last);
	}
	
	return PLUGIN_HANDLED;
}

public CmdAddBanLimit()
{
	if( read_argc() != 3 )
	{
		log_amx("amx_addbanlimit was used with incorrect parameters!");
		log_amx("Usage: amx_addbanlimit <flags> <time in minutes>");
		return PLUGIN_HANDLED;
	}
	
	static arg[16];
	
	read_argv(1, arg, charsmax(arg));
	new flags = read_flags(arg);
	
	read_argv(2, arg, charsmax(arg));
	new minutes = str_to_num(arg);
	
	ArrayPushCell(g_maxban_flags, flags);
	ArrayPushCell(g_maxban_times, minutes);

	g_total_maxban_times++;
	
	return PLUGIN_HANDLED;
}

public FwdThink(entity)
{
	if( entity != g_unban_entity ) return;
	
	if( g_total_bans > 0 && !g_loading_bans )
	{
		static _hours[5], _minutes[5], _seconds[5], _month[5], _day[5], _year[7];
		format_time(_hours, charsmax(_hours), "%H");
		format_time(_minutes, charsmax(_minutes), "%M");
		format_time(_seconds, charsmax(_seconds), "%S");
		format_time(_month, charsmax(_month), "%m");
		format_time(_day, charsmax(_day), "%d");
		format_time(_year, charsmax(_year), "%Y");
		
		// c = current
		// u = unban
		
		new c_hours = str_to_num(_hours);
		new c_minutes = str_to_num(_minutes);
		new c_seconds = str_to_num(_seconds);
		new c_month = str_to_num(_month);
		new c_day = str_to_num(_day);
		new c_year = str_to_num(_year);
		
		static unban_time[32];
		static u_hours, u_minutes, u_seconds, u_month, u_day, u_year;
		
		for( new i = 0; i < g_total_bans; i++ )
		{
			static data[BannedData];
			ArrayGetArray(g_array, i, data);
			
			if( data[bd_banlength] == 0 ) continue;
			
			copy(unban_time, charsmax(unban_time), data[bd_unbantime]);

			replace_all(unban_time, charsmax(unban_time), ":", " ");
			replace_all(unban_time, charsmax(unban_time), "/", " ");
			
			parse(unban_time,\
				_hours, charsmax(_hours),\
				_minutes, charsmax(_minutes),\
				_seconds, charsmax(_seconds),\
				_month, charsmax(_month),\
				_day, charsmax(_day),\
				_year, charsmax(_year)
				);
			
			u_hours = str_to_num(_hours);
			u_minutes = str_to_num(_minutes);
			u_seconds = str_to_num(_seconds);
			u_month = str_to_num(_month);
			u_day = str_to_num(_day);
			u_year = str_to_num(_year);
			
			if( u_year < c_year
			|| u_year == c_year && u_month < c_month
			|| u_year == c_year && u_month == c_month && u_day < c_day
			|| u_year == c_year && u_month == c_month && u_day == c_day && u_hours < c_hours
			|| u_year == c_year && u_month == c_month && u_day == c_day && u_hours == c_hours && u_minutes < c_minutes
			|| u_year == c_year && u_month == c_month && u_day == c_day && u_hours == c_hours && u_minutes == c_minutes && u_seconds <= c_seconds )
			{
				Log("Ban time is up for: %s [%s]", data[bd_name], data[bd_steamid]);
				
				Print("%s [%s] ban time is up! [Ban Reason: %s]", data[bd_name], data[bd_steamid], data[bd_reason]);
				
				RemoveBan(i, data[bd_steamid]);
				
				i--; // current pos was replaced with another ban, so we need to check it again.
			}
		}
	}
	
	entity_set_float(g_unban_entity, EV_FL_nextthink, get_gametime() + get_pcvar_float(ab_unbancheck));
}

public TaskDisconnectPlayer(client)
{
	server_cmd("kick #%i ^"You are banned from this server. Check your console^"", get_user_userid(client));
}

AddBan(const target_name[], const target_steamid[], const reason[], const length, const unban_time[], const admin_name[], const admin_steamid[])
{	
	static target_name2[32], reason2[128], admin_name2[32];
	MakeStringSQLSafe(target_name, target_name2, charsmax(target_name2));
	MakeStringSQLSafe(reason, reason2, charsmax(reason2));
	MakeStringSQLSafe(admin_name, admin_name2, charsmax(admin_name2));
	
	static query[512];
	formatex(query, charsmax(query),\
		"INSERT INTO `%s` (`%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`, `%s`) VALUES ('%s', '%s', '%i', '%s', '%s', '%s', '%s', '%s');",\
		TABLE_NAME, KEY_NAME, KEY_STEAMID, KEY_BANLENGTH, KEY_UNBANTIME, KEY_REASON, KEY_ADMIN_NAME, KEY_ADMIN_STEAMID, KEY_SERVER,\
		target_name2, target_steamid, length, unban_time, reason2, admin_name2, admin_steamid, Server
		);
		
	server_print(query);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryAddBan", query);
	
	
	static data[BannedData];
	copy(data[bd_name], charsmax(data[bd_name]), target_name);
	copy(data[bd_steamid], charsmax(data[bd_steamid]), target_steamid);
	data[bd_banlength] = length;
	copy(data[bd_unbantime], charsmax(data[bd_unbantime]), unban_time);
	copy(data[bd_reason], charsmax(data[bd_reason]), reason);
	copy(data[bd_admin_name], charsmax(data[bd_admin_name]), admin_name);
	copy(data[bd_admin_steamid], charsmax(data[bd_admin_steamid]), admin_steamid);
	copy(data[bd_server_name], charsmax(data[bd_server_name]), Server);
	
	TrieSetCell(g_trie, target_steamid, g_total_bans);
	ArrayPushArray(g_array, data);
	
	g_total_bans++;
	
}

public QueryAddBan(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		// Yay, ban was added! We can all rejoice!
	}
}

public QueryDeleteBan(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		// Yay, ban was deleted! We can all rejoice!
	}
}

public QueryLoadBans(failstate, Handle:query, error[], errcode, data[], datasize, Float:queuetime)
{
	if( failstate == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to database.");
	}
	else if( failstate == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
	}
	else if( errcode )
	{
		log_amx("Error on query: %s", error);
	}
	else
	{
		if( SQL_NumResults(query) )
		{
			static data[BannedData];
			while( SQL_MoreResults(query) )
			{
				SQL_ReadResult(query, 0, data[bd_name], charsmax(data[bd_name]));
				SQL_ReadResult(query, 1, data[bd_steamid], charsmax(data[bd_steamid]));
				data[bd_banlength] = SQL_ReadResult(query, 2);
				SQL_ReadResult(query, 3, data[bd_unbantime], charsmax(data[bd_unbantime]));
				SQL_ReadResult(query, 4, data[bd_reason], charsmax(data[bd_reason]));
				SQL_ReadResult(query, 5, data[bd_admin_name], charsmax(data[bd_admin_name]));
				SQL_ReadResult(query, 6, data[bd_admin_steamid], charsmax(data[bd_admin_steamid]));
				SQL_ReadResult(query, 7, data[bd_server_name], charsmax(data[bd_server_name]));
				
				ArrayPushArray(g_array, data);
				TrieSetCell(g_trie, data[bd_steamid], g_total_bans);
				
				g_total_bans++;
				
				SQL_NextRow(query);
			}
		}
		
		set_task(RELOAD_BANS_INTERVAL, "LoadBans");
		
		g_loading_bans = false;
	}
}

RemoveBan(pos, const authid[])
{
	TrieDeleteKey(g_trie, authid);
	ArrayDeleteItem(g_array, pos);
	
	g_total_bans--;
	
	static query[128];
	formatex(query, charsmax(query),\
		"DELETE FROM `%s` WHERE `%s` = '%s';",\
		TABLE_NAME, KEY_STEAMID, authid
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryDeleteBan", query);
	
	new data[BannedData];
	for( new i = 0; i < g_total_bans; i++ )
	{
		ArrayGetArray(g_array, i, data);
		TrieSetCell(g_trie, data[bd_steamid], i);
	}
}

public LoadBans()
{
	if( g_total_bans )
	{
		TrieClear(g_trie);
		ArrayClear(g_array);
		
		g_total_bans = 0;
	}
	
	static query[128];
	formatex(query, charsmax(query),\
		"SELECT * FROM `%s`;",\
		TABLE_NAME
		);
	
	SQL_ThreadQuery(g_sql_tuple, "QueryLoadBans", query);
	
	g_loading_bans = true;
}

MakeStringSQLSafe(const input[], output[], len)
{
	copy(output, len, input);
	replace_all(output, len, "'", "*");
	replace_all(output, len, "^"", "*");
	replace_all(output, len, "`", "*");
}

GetBanTime(const bantime, length[], len)
{
	new minutes = bantime;
	new hours = 0;
	new days = 0;
	
	while( minutes >= 60 )
	{
		minutes -= 60;
		hours++;
	}
	
	while( hours >= 24 )
	{
		hours -= 24;
		days++;
	}
	
	new bool:add_before;
	if( minutes )
	{
		formatex(length, len, "%i minute%s", minutes, minutes == 1 ? "" : "s");
		
		add_before = true;
	}
	if( hours )
	{
		if( add_before )
		{
			format(length, len, "%i hour%s, %s", hours, hours == 1 ? "" : "s", length);
		}
		else
		{
			formatex(length, len, "%i hour%s", hours, hours == 1 ? "" : "s");
			
			add_before = true;
		}
	}
	if( days )
	{
		if( add_before )
		{
			format(length, len, "%i day%s, %s", days, days == 1 ? "" : "s", length);
		}
		else
		{
			formatex(length, len, "%i day%s", days, days == 1 ? "" : "s");
			
			add_before = true;
		}
	}
	if( !add_before )
	{
		// minutes, hours, and days = 0
		// assume permanent ban
		copy(length, len, "Permanent Ban");
	}
}

GenerateUnbanTime(const bantime, unban_time[], len)
{
	static _hours[5], _minutes[5], _seconds[5], _month[5], _day[5], _year[7];
	format_time(_hours, charsmax(_hours), "%H");
	format_time(_minutes, charsmax(_minutes), "%M");
	format_time(_seconds, charsmax(_seconds), "%S");
	format_time(_month, charsmax(_month), "%m");
	format_time(_day, charsmax(_day), "%d");
	format_time(_year, charsmax(_year), "%Y");
	
	new hours = str_to_num(_hours);
	new minutes = str_to_num(_minutes);
	new seconds = str_to_num(_seconds);
	new month = str_to_num(_month);
	new day = str_to_num(_day);
	new year = str_to_num(_year);
	
	minutes += bantime;
	
	while( minutes >= 60 )
	{
		minutes -= 60;
		hours++;
	}
	
	while( hours >= 24 )
	{
		hours -= 24;
		day++;
	}
	
	new max_days = GetDaysInMonth(month, year);
	while( day > max_days )
	{
		day -= max_days;
		month++;
	}
	
	while( month > 12 )
	{
		month -= 12;
		year++;
	}
	
	formatex(unban_time, len, "%i:%02i:%02i %i/%i/%i", hours, minutes, seconds, month, day, year);
}

GetDaysInMonth(month, year=0)
{
	switch( month )
	{
		case 1:		return 31; // january
		case 2:		return ((year % 4) == 0) ? 29 : 28; // february
		case 3:		return 31; // march
		case 4:		return 30; // april
		case 5:		return 31; // may
		case 6:		return 30; // june
		case 7:		return 31; // july
		case 8:		return 31; // august
		case 9:		return 30; // september
		case 10:	return 31; // october
		case 11:	return 30; // november
		case 12:	return 31; // december
	}
	
	return 30;
}

GetTargetFlags(client)
{
	if (client == 0)
	{
		return 0;
	}
	static const flags_no_immunity = (CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS);
	static const flags_immunity = (CMDTARGET_ALLOW_SELF|CMDTARGET_NO_BOTS|CMDTARGET_OBEY_IMMUNITY);
	
	switch( get_pcvar_num(ab_immunity) )
	{
		case 1: return flags_immunity;
		case 2: return access(client, ADMIN_IMMUNITY) ? flags_no_immunity : flags_immunity;
	}
	
	return flags_no_immunity;
}

GetMaxBanTime(client)
{
	if( !g_total_maxban_times ) return 0;
	
	new flags = get_user_flags(client);
	
	for( new i = 0; i < g_total_maxban_times; i++ )
	{
		if( flags & ArrayGetCell(g_maxban_flags, i) )
		{
			return ArrayGetCell(g_maxban_times, i);
		}
	}
	
	return 0;
}

PrintBanInformation(client, const target_name[], const target_authid[], const reason[], const length, const unban_time[], const admin_name[], const admin_authid[], const server[], bool:show_admin)
{
	static ban_length[64];
	if (is_user_connecting(client))
	{
		engclient_print(client, engprint_console, "************************************************");
		engclient_print(client, engprint_console, "%L", client, "AB_BAN_INFORMATION");
		engclient_print(client, engprint_console, "%L: %s", client, "AB_NAME", target_name);
		engclient_print(client, engprint_console, "%L: %s", client, IsValidAuthid(target_authid) ? "AB_STEAMID" : "AB_IP", target_authid);
		engclient_print(client, engprint_console, "%L: %s", client, "AB_REASON", reason);
		if( length > 0 )
		{
			GetBanTime(length, ban_length, charsmax(ban_length));
			engclient_print(client, engprint_console, "%L: %s", client, "AB_BAN_LENGTH", ban_length);
		}
		engclient_print(client, engprint_console, "%L: %s", client, "AB_UNBAN_TIME", unban_time);
		engclient_print(client, engprint_console, "%L: %s", client, "AB_SERVER", server);
		if( show_admin )
		{
			engclient_print(client, engprint_console, "%L: %s", client, "AB_ADMIN_NAME", admin_name);
			engclient_print(client, engprint_console, "%L: %s", client, "AB_ADMIN_STEAMID", admin_authid);
		}
		engclient_print(client, engprint_console, "************************************************");
	} 
	else
	{
		console_print(client, "************************************************");
		console_print(client, "%L", client, "AB_BAN_INFORMATION");
		console_print(client, "%L: %s", client, "AB_NAME", target_name);
		console_print(client, "%L: %s", client, IsValidAuthid(target_authid) ? "AB_STEAMID" : "AB_IP", target_authid);
		console_print(client, "%L: %s", client, "AB_REASON", reason);
		if( length > 0 )
		{
			GetBanTime(length, ban_length, charsmax(ban_length));
			console_print(client, "%L: %s", client, "AB_BAN_LENGTH", ban_length);
		}
		console_print(client, "%L: %s", client, "AB_UNBAN_TIME", unban_time);
		console_print(client, "%L: %s", client, "AB_SERVER", server);
		if( show_admin )
		{
			console_print(client, "%L: %s", client, "AB_ADMIN_NAME", admin_name);
			console_print(client, "%L: %s", client, "AB_ADMIN_STEAMID", admin_authid);
		}
		console_print(client, "************************************************");
	} 
}

PrintActivity(const admin_name[], const message_fmt[], any:...)
{
	if( !get_playersnum() ) return;	
	
	static message[192], temp[192], AdminName[70];
	formatex(AdminName, charsmax(AdminName), "%s", admin_name);
	vformat(message, charsmax(message), message_fmt, 3);
	
	for( new client = 1; client <= MaxClients; client++ )
	{
		if (!is_user_connected(client)) continue;
		
		if (is_user_admin(client))
		{
			copy(temp, charsmax(temp), message);
			replace(temp, charsmax(temp), "$name", AdminName);
				
			client_print(client, print_chat, temp);
		}
		else
		{
			copy(temp, charsmax(temp), message);
			replace(temp, charsmax(temp), "$name", "ADMIN");
				
			client_print(client, print_chat, temp);
		}
	}
}

Print(const message_fmt[], any:...)
{
	if( !get_playersnum() ) return;
	
	static message[192];
	vformat(message, charsmax(message), message_fmt, 2);
	
	client_print(0, print_chat, message);
}

Log(const message_fmt[], any:...)
{
	static message[256];
	vformat(message, charsmax(message), message_fmt, 2);
	
	static filename[96];
	
	static dir[64];
	if( !dir[0] )
	{
		get_basedir(dir, charsmax(dir));
		add(dir, charsmax(dir), "/logs");
	}
	
	format_time(filename, charsmax(filename), "%m%d%Y");
	format(filename, charsmax(filename), "%s/BAN_HISTORY_%s.log", dir, filename);

	
	log_amx("%s", message);
	log_to_file(filename, "%s", message);
}