#include <amxmisc> 
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <engine>
#include <sqlx>
#include <sqlsmart>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new const Tag[] = "[Dr.FioriGinal.Ro]";

new Handle:SqlTuple, InTable, WasNotDevOffAllRound;
new Trie:GravityInfo;
public WasNot800AllRound;

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "Gravity Sql",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_clcmd("say", "hookChat");
	RegisterHam(Ham_Spawn, "player", "playerSpawn", 1);
	
	GravityInfo = TrieCreate();
	
	if (WasNotDevOffAllRound == 0)
	{
		WasNotDevOffAllRound = get_xvar_id("WasNotDevOffAllRound");
	}
}

public onSqlConnection(Handle:Tuple)
{
	SqlTuple = Tuple;
	new SqlError[512];
	new ErrorCode, Handle:SqlConnection = SQL_Connect(SqlTuple, ErrorCode, SqlError, charsmax(SqlError));
	if (SqlConnection == Empty_Handle)
	{
		set_fail_state(SqlError);
	}
   
	new Handle:Query  = SQL_PrepareQuery(SqlConnection,\
			  "CREATE TABLE IF NOT EXISTS Gravity (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, NickName varchar(32) UNIQUE, GravityId int(8))");
 
	if (!SQL_Execute(Query))
	{
		SQL_QueryError(Query, SqlError, charsmax(SqlError));
		set_fail_state(SqlError);
	}
   
	SQL_FreeHandle(Query);
}

public client_authorized(Index)
{
	new Cache[120], NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(NickName, charsmax(NickName), "'", " ");

	formatex(Cache, charsmax(Cache), "SELECT * FROM Gravity WHERE NickName = '%s'", NickName);
	SQL_ThreadQuery(SqlTuple, "getSqlValue", Cache, NickName, charsmax(NickName));
}

public client_disconnected(Index)
{
	DelBit(InTable, Index);
	DelBit(WasNot800AllRound, Index);
	if (WasNotDevOffAllRound != 0)
	{
		new Value = get_xvar_num(WasNotDevOffAllRound);
		DelBit(Value, Index);
		set_xvar_num(WasNotDevOffAllRound, Value);
	}
}

public hookChat(Index)
{
	new Said[32];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if (Said[0] != '!')
	{
		return PLUGIN_CONTINUE;
	}
	
	new GravityIdent[] = "!gravity", ShowGravityIdent[] = "!showgravity", Gravity800Ident[] = "!800", Gravity700Ident[] = "!700";
	
	if ( equali(Said, ShowGravityIdent, charsmax(ShowGravityIdent)) ) 
	{
		new Target[32];
		split(Said, Said, charsmax(Said), Target, charsmax(Target), " ");
		if (equal(Target, ""))
		{
			showGravity(Index, Index);
		}
		else
		{
			showGravity(Index, cmd_target(Index, Target, CMDTARGET_NO_BOTS));
		}
		return PLUGIN_HANDLED;
	}
	
	if ( equali(Said, GravityIdent, charsmax(GravityIdent)) )
	{
		client_print_color(Index, print_team_red, "^4%s^3 !gravity ^1 a fost înlocuit cu ^3 !showgravity^1!", Tag);
		return PLUGIN_HANDLED;
	}

	if (equali(Said, Gravity700Ident, charsmax(Gravity700Ident)))
	{
		setGravity(Index, 0.875);
		putInTable(Index, 0);
		return PLUGIN_HANDLED;
	}

	if (equali(Said, Gravity800Ident, charsmax(Gravity800Ident)))
	{
		setGravity(Index, 1.0);
		putInTable(Index, 1);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public playerSpawn(Index)
{
	if (is_user_alive(Index) && cs_get_user_team(Index) == CS_TEAM_CT)
	{
		DelBit(WasNot800AllRound, Index);
		if (WasNotDevOffAllRound != 0)
		{
			new Value = get_xvar_num(WasNotDevOffAllRound);
			DelBit(Value, Index);
			set_xvar_num(WasNotDevOffAllRound, Value);
		}	
	
		new GravityIndex, NickName[MAX_NAME_LENGTH];
		get_user_name(Index, NickName, charsmax(NickName));
		
		if (TrieKeyExists(GravityInfo, NickName))
		{
			TrieGetCell(GravityInfo, NickName, GravityIndex);
		}
		setGravity(Index, getFloatValue(GravityIndex), false);
	}
	
	return HAM_IGNORED;
} 

showGravity(Index, Target)
{
	if (Target == 0)
	{
		client_print_color(Index, print_team_red, "^4%s^1 Jucătorul nu se află pe server sau sunt mai mulți jucători cu același nume!", Tag);
		return;
	}
	
	if (Index == Target)
	{
		if( !is_user_alive(Index) ) 
		{
			showGravity(Index, pev(Index, pev_iuser2));
			return;
		}
		
		if (cs_get_user_team(Index) == CS_TEAM_T)
		{
			client_print_color(Index, print_team_red, "^4%s^1 Tero poate să folosească doar 800 gravity!", Tag);
			return;
		}
		
		new Float:Gravity = get_user_gravity(Index);
		client_print_color(Index, print_team_red,"^3%s^1 Folosești^3 %s^1 gravity!", Tag, Gravity == 1.0 ? "800" : (Gravity == 0.875 ? "700" : "850"));
	}
	else
	{
		if (!is_user_alive(Target)) 
		{
			client_print_color(Index, print_team_red, "^4%s^1 Jucătorul trebuie să fie în viață!", Tag);
			return;
		}
		if (cs_get_user_team(Target) == CS_TEAM_T)
		{
			client_print_color(Index, print_team_red, "^4%s^1 Tero poate să folosească doar 800 gravity!", Tag);
			return;
		}
		
		new Name[MAX_NAME_LENGTH], Float:Gravity = get_user_gravity(Target);
		get_user_name(Target, Name, charsmax(Name));
		
		client_print_color(Index, print_team_red,"^3%s^1 %s folosește^3 %s^1 gravity!", Tag, Name, Gravity == 1.0 ? "800" : (Gravity == 0.875 ? "700" : "850"));
	}
}

setGravity(Index, Float:Value, bool:Messages = true)
{
	if (!is_user_alive(Index))
	{
		return;
	}
	
	if (cs_get_user_team(Index) != CS_TEAM_CT)
	{
		return;
	}
	
	if (Value != 1.0)
	{
		SetBit(WasNot800AllRound, Index);
	}
	
	if (!Messages)
	{
		set_user_gravity(Index, Value);
		return;
	}
	
	new Float:GravityValue = get_user_gravity(Index);
	if (Value == GravityValue)
	{
		client_print_color(Index, print_team_red, "^3%s^1 Folosești deja^3 %s^1 gravity!", Tag, Value == 1.0 ? "800" : (Value == 0.875 ? "700" : "850"));
		return;
	}
	
	set_user_gravity(Index, Value);
	client_print_color(Index, print_team_red,"^3%s^1 Ți-ai setat^3 %s^1 gravity.", Tag, Value == 1.0 ? "800" : (Value == 0.875 ? "700" : "850"));
}

public putInTable(Index, Gravity)
{
	new Cache[120], NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(NickName, charsmax(NickName), "'", " ");
	
	if ( !GetBit(InTable, Index) )
	{
		formatex(Cache, charsmax(Cache), "INSERT INTO Gravity(NickName, GravityId) VALUES('%s', '%d')", NickName, Gravity);
	}
	else
	{
		formatex(Cache, charsmax(Cache), "UPDATE Gravity SET GravityId = '%d' WHERE NickName = '%s'", Gravity, NickName);
	}
	TrieSetCell(GravityInfo, NickName, Gravity);
	SQL_ThreadQuery(SqlTuple, "checkForErrors", Cache);
}

public checkForErrors(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if ( FailState == TQUERY_CONNECT_FAILED )
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		reconnectToSqlDataBase();
		return;
	}
	else if ( FailState == TQUERY_QUERY_FAILED )
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		//reconnectToSqlDataBase();
		return;
	}
	
	if ( Errcode )
	{
		log_error(AMX_ERR_GENERAL, "Error on query: %s", Error);
		return;
	}
}

public getSqlValue(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (FailState == TQUERY_CONNECT_FAILED)
	{
		log_error(AMX_ERR_GENERAL, "Could not connect to SQL database.");
		reconnectToSqlDataBase();
		return;
	}
	else if (FailState == TQUERY_QUERY_FAILED)
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		//reconnectToSqlDataBase();
		return;
	}
	if (Errcode)
	{
		log_error(AMX_ERR_GENERAL, "Error on query: %s", Error);
		return;
	}
	
	new Index = get_user_index(Data);
	
	if (SQL_NumResults(Query) != 1)
	{
		return;
	}
	
	SetBit(InTable, Index);
	TrieSetCell(GravityInfo, Data, SQL_ReadResult(Query, 2));
}

Float:getFloatValue(GravityIndex)
{
	switch(GravityIndex)
	{
		case 0:
		{
			return 0.875;
		}
		case 1:
		{
			return 1.0;
		}
		case 2:
		{
			return 1.063;
		}
	}
	return -1.0;
}