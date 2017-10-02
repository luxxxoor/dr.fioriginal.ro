#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <sqlx>
#include <sqlsmart>

#define PLUGIN	"Bhop Abilities"
#define VERSION "0.5.2"
#define AUTHOR	"ConnorMcLeod" 

#define PLAYER_JUMP	 6

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new Alive, AutoBhop = ~0, InTable;
new Handle:SqlTuple;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("bhop_abilities", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);
	
	RegisterHam(Ham_Player_Jump, "player", "Player_Jump");
	RegisterHam(Ham_Spawn, "player", "Check_Alive", 1);
	RegisterHam(Ham_Killed, "player", "Check_Alive", 1);
	
	register_clcmd("say", "hookChat");
}

public onSqlConnection(Handle:Tuple)
{
	SqlTuple = Tuple;
	SQL_ThreadQuery(SqlTuple, "addInSql", "CREATE TABLE IF NOT EXISTS Bhop (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, NickName varchar(32) UNIQUE, Bhop int(8))");
}

public addInSql(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
}

public client_authorized(Index)
{
	new Cache[120], Name[MAX_NAME_LENGTH], SafeName[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name));
	copy(SafeName, charsmax(SafeName), Name);
	replace_string(SafeName, charsmax(SafeName), "'", "");

	formatex(Cache, charsmax(Cache), "SELECT * FROM Bhop WHERE NickName = '%s'", SafeName);
	SQL_ThreadQuery(SqlTuple, "getSettings", Cache, Name, charsmax(Name));
}

public client_infochanged(Index)
{
	if (!is_user_connected(Index))
	{
		return;
	}
	
	new NewName[MAX_NAME_LENGTH], OldName[MAX_NAME_LENGTH];
	get_user_name(Index, OldName, charsmax(OldName));
	get_user_info(Index, "name", NewName, charsmax(NewName));
		
	if (equali(NewName, OldName))
	{
		return;
	}
	
	new SafeName[MAX_NAME_LENGTH], Cache[120];
	copy(SafeName, charsmax(SafeName), NewName);
	replace_string(SafeName, charsmax(SafeName), "'", "");
	formatex(Cache, charsmax(Cache), "SELECT * FROM Bhop WHERE NickName = '%s'", SafeName);
	SQL_ThreadQuery(SqlTuple, "getSettings", Cache, NewName, charsmax(NewName));
}

public getSettings(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
	
	new Index = get_user_index(Data);
	
	if (SQL_NumResults(Query) != 1)
	{
		DelBit(InTable, Index);
		SetBit(AutoBhop, Index);
		return;
	}
	
	SetBit(InTable, Index);
	
	if (SQL_ReadResult(Query, 2) == 1)
	{
		SetBit(AutoBhop, Index);
	}
	else
	{
		DelBit(AutoBhop, Index);
	}
}

public Check_Alive(Index)
{
	is_user_alive(Index) ? SetBit(Alive, Index) : DelBit(Alive, Index);
}

public Player_Jump(Index)
{
	if (!GetBit(Alive, Index))
	{
		return;
	}
	
	static OldButtons ; OldButtons = pev(Index, pev_oldbuttons)
	if (GetBit(AutoBhop, Index) && OldButtons & IN_JUMP && pev(Index, pev_flags) & FL_ONGROUND)
	{
		OldButtons &= ~IN_JUMP
		set_pev(Index, pev_oldbuttons, OldButtons)
		set_pev(Index, pev_gaitsequence, PLAYER_JUMP)
		set_pev(Index, pev_frame, 0.0)
	}
}

public hookChat(Index) 
{	
	new Said[192];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if ( Said[0] != '!' )
	{
		return PLUGIN_CONTINUE;
	}
	
	new const BhopIdent[] = "!bhop";
	if (equali(Said, BhopIdent, charsmax(BhopIdent))) 
	{
		new SafeName[MAX_NAME_LENGTH], Cache[120];
		get_user_name(Index, SafeName, charsmax(SafeName));
		replace_string(SafeName, charsmax(SafeName), "'", "");
		
		
		if (GetBit(AutoBhop, Index))
		{
			DelBit(AutoBhop, Index);
			client_print(Index, print_chat, "AUTO BHOP DEZACTIVAT");
		}
		else
		{
			SetBit(AutoBhop, Index);
			client_print(Index, print_chat, "AUTO BHOP ACTIVAT");
		}
		
		if (!GetBit(InTable, Index))
		{
			formatex(Cache, charsmax(Cache), "INSERT INTO Bhop(NickName, Bhop) VALUES('%s', '%d')", SafeName, GetBit(AutoBhop, Index) ? 1 : 0);
			SetBit(InTable, Index);
		}
		else
		{
			formatex(Cache, charsmax(Cache), "UPDATE Bhop SET Bhop = '%d' WHERE NickName = '%s'", GetBit(AutoBhop, Index) ? 1 : 0, SafeName);
		}
		SQL_ThreadQuery(SqlTuple, "checkForErrors", Cache);
	}
	
	return PLUGIN_CONTINUE;
}

public checkForErrors(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	checkSQLConditions(FailState, Errcode, Error)
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