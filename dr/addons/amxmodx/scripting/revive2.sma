#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <sqlx>
#include <sqlsmart>

#pragma semicolon 1

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

const TrialReviveTask = 9234;

new TrialReviveName[MAX_NAME_LENGTH], TrialReviveWord[9];
new bool:Competition;
public TrialReviveIndex = -2, UsedRevive;
new Handle:SqlTuple, AutoRevive = ~0, InTable;

public plugin_init()
{	
	register_plugin
	(
		.plugin_name = "The new revive",
		.version     = "2.6",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_concmd("amx_revive", "commandRevive");
	register_clcmd("say", "hookChat");
	register_event("HLTV", "newRound", "a", "1=0", "2=0") ;
	register_event("DeathMsg", "clientDeath", "a");
	
	set_task(30.0, "startTrialRevive");
}

public plugin_natives()
{
    register_library("revive");
    
    register_native("revivePlayer", "_revivePlayer");
}


public onSqlConnection(Handle:Tuple)
{
	SqlTuple = Tuple;
	SQL_ThreadQuery(SqlTuple, "addInSql", "CREATE TABLE IF NOT EXISTS Revive (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, NickName varchar(32) UNIQUE, Revive int(8))");
}

public addInSql(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (checkSQLConditions(FailState, Errcode, Error))
	{
		return;
	}
}

public startTrialRevive()
{
	TrialReviveIndex = -1;
}

public newRound() 
{
	static TrialReviveRoundCounter;
	if (TrialReviveIndex >= -1)
	{
		if (TrialReviveRoundCounter == 0)
		{
			if (task_exists(TrialReviveTask))
			{
				remove_task(TrialReviveTask);
			}
			TrialReviveIndex = -1;
			setTrialReviveWord();
			TrialReviveRoundCounter = 3;
		}
		TrialReviveRoundCounter--;
	}

	UsedRevive = 0;
}

setTrialReviveWord()
{
	for (new i = 0; i < charsmax(TrialReviveWord); ++i)
	{
		TrialReviveWord[i] = random_num(65, 90) + (random_num(0, 1) ? 0 : 32); 
	}
	set_task(1.0, "showTrialReviveHud", TrialReviveTask, .flags = "b");
}

public clientDeath()
{
	if (UsedRevive == 0)
	{
		return;
	}
	
	new Players[MAX_PLAYERS], MatchedPlayers, bool:DidNotUsedRevive;
	get_players(Players, MatchedPlayers, "ache", "CT");
	for (new i = 0; i < MatchedPlayers; ++i)
	{
		if (!GetBit(UsedRevive, Players[i]))
		{
			DidNotUsedRevive = true;
			break;
		}
	}
	if (!DidNotUsedRevive)
	{
		for (new i = 0; i < MatchedPlayers; ++i)
		{
			UsedRevive = 0;
			user_silentkill(Players[i]);
		}
		client_print_color(0, print_team_red, "^4[^3REVIVE^4]^1 Ne pare rău dar toti jucatorii au murit, cei care au dat ^4revive^1 au primit slay.");
	}
}

public commandRevive(Index)
{
	if (!(get_user_flags(Index) & ADMIN_IMMUNITY))
	{
		return PLUGIN_HANDLED;
	}
	
	new Argument[32];
	new const AllIndent[] = "#ALL", TeroIdent[] = "#T", CouterIdent[] = "#CT";
	read_argv(1, Argument, charsmax(Argument));
	
	if (Argument[0] == '#' && (get_user_flags(Index) & ADMIN_RCON))
	{ 
		new Players[MAX_PLAYERS], MatchedPlayers;
		if (equal(Argument, AllIndent, charsmax(AllIndent)))
		{    
			get_players(Players, MatchedPlayers);
			for (new i = 0; i <= MatchedPlayers; ++i)
			{
				if (!is_user_bot(Index))
				{
					ExecuteHamB(Ham_CS_RoundRespawn, Players[i]);
				}
			}
						
			return PLUGIN_HANDLED; 
		}
		if (equal(Argument, TeroIdent, charsmax(TeroIdent)))
		{
			get_players(Players, MatchedPlayers, "e", "TERRORIST");   
			for (new i = 0; i <= MatchedPlayers; ++i)
			{
				if (!is_user_bot(Index))
				{
					ExecuteHamB(Ham_CS_RoundRespawn, Players[i]);
				}
			}

			return PLUGIN_HANDLED; 
		}
		if (equal(Argument, CouterIdent, charsmax(CouterIdent)))
		{
			get_players(Players, MatchedPlayers, "e", "CT");        
			for (new i = 0; i <= MatchedPlayers; ++i)
			{
				if (!is_user_bot(Index))
				{
					ExecuteHamB(Ham_CS_RoundRespawn, Players[i]);
				}
			}
			
			return PLUGIN_HANDLED; 
		}
	}
	
	new TargetIndex = cmd_target(Index, Argument, CMDTARGET_NO_BOTS);
	if (!TargetIndex)
	{
		return PLUGIN_HANDLED;
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, TargetIndex);
	
	return PLUGIN_HANDLED;
}

public _revivePlayer(PluginId, Parameters)
{	
	new Index;
	if (PluginId == get_plugin(-1))
	{
		Index = Parameters;
	}
	else
	{
		if (Parameters != 1)
		{
			return;
		}
		Index = get_param(1);
	}
	
	
	
	if (is_user_alive(Index))
	{
		return;
	}
	
	static GivedLife, ReviveForce;
	if (GivedLife == 0)
	{
		GivedLife = get_xvar_id("GivedLife");
	}
	if (ReviveForce == 0)
	{
		ReviveForce = get_xvar_id("ReviveForce");
	}
	if (GivedLife != -1 && ReviveForce != -1)
	{
		if (GetBit(get_xvar_num(GivedLife), Index))
		{
			if (GetBit(get_xvar_num(ReviveForce), Index))
			{
				ExecuteHamB(Ham_CS_RoundRespawn, Index);
				SetBit(UsedRevive, Index);
				client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Deoarece ai dat life în această rundă, vei primi slay când toți jucătorii vor muri.");
			}
			return; 
		}
	}
	
	new Players[MAX_PLAYERS], MatchedPlayers, AllPlayers, Counter;
	get_players(Players, AllPlayers, "ace", "TERRORIST");
	if (AllPlayers == 0)
	{
		return;
	}
	
	get_players(Players, AllPlayers, "bce", "CT");
	for(new i = 0; i < AllPlayers; ++i)
	{
		if (get_user_flags(Players[i]) & ADMIN_LEVEL_H || Players[i] == TrialReviveIndex)
		{
			++Counter;
		}
	}
	AllPlayers -= Counter; // jucatorii morti fara revive
	get_players(Players, MatchedPlayers, "ace", "CT");

	
	ExecuteHamB(Ham_CS_RoundRespawn, Index);
	
	Counter = 0;
	for(new i = 0; i < MatchedPlayers; ++i)
	{
		if (get_user_flags(Players[i]) & ADMIN_LEVEL_H || Players[i] == TrialReviveIndex)
		{
			++Counter;
		}
	}
	MatchedPlayers -= Counter;

	if (MatchedPlayers <= (AllPlayers+MatchedPlayers)/4)
	{
		SetBit(UsedRevive, Index);
		client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Sunt mai puțin de un sfert din jucători in viață, vei primi slay când toți jucătorii vor muri.");
	}
}

public client_authorized(Index)
{
	new Cache[120], Name[MAX_NAME_LENGTH], SafeName[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name));
	copy(SafeName, charsmax(SafeName), Name);
	replace_string(SafeName, charsmax(SafeName), "'", "");

	formatex(Cache, charsmax(Cache), "SELECT * FROM Revive WHERE NickName = '%s'", SafeName);
	SQL_ThreadQuery(SqlTuple, "getSettings", Cache, Name, charsmax(Name));
}

public client_infochanged(Index)
{
	if (!is_user_connected(Index))
	{
		return;
	}
	
	if (TrialReviveIndex == Index)
	{
		get_user_info(Index, "name", TrialReviveName, charsmax(TrialReviveName));
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
	formatex(Cache, charsmax(Cache), "SELECT * FROM Revive WHERE NickName = '%s'", SafeName);
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
		SetBit(AutoRevive, Index);
		return;
	}
	
	SetBit(InTable, Index);
	
	if (SQL_ReadResult(Query, 2) == 1)
	{
		SetBit(AutoRevive, Index);
	}
	else
	{
		DelBit(AutoRevive, Index);
	}
}

public client_disconnected(Index)
{	
	if (TrialReviveIndex == Index)
	{
		TrialReviveIndex = -1;
		client_print_color(0, print_team_red, "^4[^3REVIVE^4]^1 %s s-a deconectat. Curând se va alege un nou Trial-Revive.", TrialReviveName);
		setTrialReviveWord();
	}
	DelBit(AutoRevive, Index);
}

public hookChat(Index)
{
	new Said[192];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if (!Said[0])
	{
		return PLUGIN_CONTINUE;
	}
	
	new const TrialReviveIdent[] = "!trialrevive", ReviveIdent[] = "!revive", AutoReviveIdent[] = "!autorevive", CompetitionIdent[] = "!concurs";	
	
	if (!(get_user_flags(Index) & ADMIN_LEVEL_H) && TrialReviveWord[0] != 0 && equal(Said, TrialReviveWord, charsmax(TrialReviveWord)) && !Competition)
	{
		static Trie:TrialReviveIndentificators;
		if (TrialReviveIndentificators == Invalid_Trie)
		{
			TrialReviveIndentificators = TrieCreate();
		}
		
		new Data[3][MAX_NAME_LENGTH];
		get_user_name(Index, Data[0], charsmax(Data[]));
		get_user_authid(Index, Data[1], charsmax(Data[]));
		get_user_ip(Index, Data[2], charsmax(Data[]), any:true);
		
		if (TrieKeyExists(TrialReviveIndentificators, Data[0]) || TrieKeyExists(TrialReviveIndentificators, Data[1]) || TrieKeyExists(TrialReviveIndentificators, Data[2]))
		{
			client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Ai câștigat deja Trial-Revive o dată pe această hartă.");
			return PLUGIN_HANDLED;
		}
		
		get_user_name(Index, TrialReviveName, charsmax(TrialReviveName));
		TrieSetCell(TrialReviveIndentificators, Data[0], 0);		
		TrieSetCell(TrialReviveIndentificators, Data[1], 0);
		TrieSetCell(TrialReviveIndentificators, Data[2], 0);
		
		TrialReviveIndex = Index;
		remove_task(TrialReviveTask);
		
		client_print_color(0, print_team_red, "^4[^3REVIVE^4]^1 %s a câștigat ^3Trial-Revive^1 pentru 3 runde!", TrialReviveName);
		TrialReviveWord[0] = 0;
	}
	
	if (equal(Said, TrialReviveIdent, charsmax(TrialReviveIdent)) && (get_user_flags(Index) & ADMIN_LEVEL_H))
	{
		if (Competition)
		{
			client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Acest beneficiu este suspendat pe durata concursului.");
			return PLUGIN_HANDLED;
		}
		if (TrialReviveIndex > 0)
		{
			client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Trial-Revive-ul a fost acordat lui %s.", TrialReviveName);
		}
		else
		{
			client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Încă nu a fost acordat Trial-Revive-ul.");
		}
		return PLUGIN_HANDLED;
	}
	
	if (get_user_flags(Index) & ADMIN_LEVEL_H || Index == TrialReviveIndex)
	{
		if (equal(Said, ReviveIdent, charsmax(ReviveIdent)))
		{
			_revivePlayer(get_plugin(-1), Index);
			return PLUGIN_HANDLED;
		}
	
		if (equal(Said, AutoReviveIdent, charsmax(AutoReviveIdent)))
		{
			if (Competition)
			{
				client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Acest beneficiu este suspendat pe durata concursului.");
			}
			
			if (GetBit(AutoRevive, Index))
			{
				DelBit(AutoRevive, Index);
				client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Ai oprit modul AutoRevive.");
			}
			else
			{
				SetBit(AutoRevive, Index);
				client_print_color(Index, print_team_red, "^4[^3REVIVE^4]^1 Ai pornit modul AutoRevive.");
				_revivePlayer(get_plugin(-1), Index);
			}
			
			new SafeName[MAX_NAME_LENGTH], Cache[120];
			get_user_name(Index, SafeName, charsmax(SafeName));
			replace_string(SafeName, charsmax(SafeName), "'", "");
				
			if (!GetBit(InTable, Index))
			{
				formatex(Cache, charsmax(Cache), "INSERT INTO Revive(NickName, Revive) VALUES('%s', '%d')", SafeName, GetBit(AutoRevive, Index) ? 1 : 0);
				SetBit(InTable, Index);
			}
			else
			{
				formatex(Cache, charsmax(Cache), "UPDATE Revive SET Revive = '%d' WHERE NickName = '%s'", GetBit(AutoRevive, Index) ? 1 : 0, SafeName);
			}
			SQL_ThreadQuery(SqlTuple, "addInSql", Cache);
			return PLUGIN_HANDLED;
		}
	}
	
	if(equal(Said, CompetitionIdent, charsmax(CompetitionIdent)) && get_user_flags(Index) & ADMIN_IMMUNITY)
	{
		if (Competition)
		{
			Competition = false;
		}
		else
		{
			Competition = true;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public showTrialReviveHud(TaskId)
{
	set_dhudmessage(0, 255, 255, 0.0, 0.20, 0, 0.0, 1.0, 0.0, 0.1);
	show_dhudmessage(0, "Trial-Revive : ^"%s^"", TrialReviveWord);
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