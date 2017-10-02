#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <sqlx>
#include <sqlsmart>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new Handle:SqlTuple;
new InTable, HasSlot, NameChanged;
new Trie:PistolInfo;

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Pistols SQL",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	register_clcmd("say", "handleChat");
	
	PistolInfo = TrieCreate();
	RegisterHam(Ham_Spawn, "player", "givePistol", 1);
}

public onSqlConnection(Handle:Tuple)
{ 
	SqlTuple = Tuple;
	new SqlError[512];
	new ErrorCode, Handle:SqlConnection = SQL_Connect(SqlTuple, ErrorCode, SqlError, charsmax(SqlError));
	if (SqlConnection == Empty_Handle)
	{
		log_amx("SqlConnection == Empty_Handle, SqlError: %s", SqlError);
		reconnectToSqlDataBase();
		
		return;
	}
   
	new Handle:Query  = SQL_PrepareQuery(SqlConnection,\
			  "CREATE TABLE IF NOT EXISTS Pistols (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, NickName varchar(32) UNIQUE, PistolId int(8) DEFAULT -1)");
 
	if (!SQL_Execute(Query))
	{
		SQL_QueryError(Query, SqlError, charsmax(SqlError));
		log_amx("!SQL_Execute(Query), SqlError: %s", SqlError);
	}
   
	SQL_FreeHandle(Query);
}

public client_authorized(Index)
{
	new Cache[120], NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(NickName, charsmax(NickName), "'", " ");

	formatex(Cache, charsmax(Cache), "SELECT * FROM Pistols WHERE NickName = '%s'", NickName);
	SQL_ThreadQuery(SqlTuple, "CheckIfNameExists", Cache, NickName, charsmax(NickName));
}

public client_infochanged(Index)
{
	new NewNickName[MAX_NAME_LENGTH], OldNickName[MAX_NAME_LENGTH];
	get_user_name(Index, OldNickName, charsmax(OldNickName));
	get_user_info(Index, "name", NewNickName, charsmax(NewNickName));
	if ( !equali(OldNickName, NewNickName) )
	{
		SetBit(NameChanged, Index);
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(Index)
{
	DelBit(InTable, Index);
	DelBit(HasSlot, Index);
	DelBit(NameChanged, Index);
}

public handleChat(Index)
{
	new Said[15];
	read_argv(1, Said, charsmax(Said));
	
	if ( Said[0] != '!' )
	{
		return PLUGIN_CONTINUE;
	}
	
	if (equali(Said[1], "choosepistol"))
	{
		new Menu = menu_create("Alege-ti un pistol :", "choosedAnswer");
		menu_additem(Menu, "Random Pistol (Deagle chance)");
		menu_additem(Menu, "USP");
		menu_additem(Menu, "Glock 18");
		menu_additem(Menu, "p228");
		menu_additem(Menu, "Dual Beretas");
		menu_additem(Menu, "FiveSeven");
		//menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(Index, Menu);
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public choosedAnswer(Index, Menu, Item)
{
	if ( GetBit(HasSlot, Index) && Item >= 0 )
	{
		PutInTable(Index, Item);
	}
	
	client_print_color(Index, print_team_blue, "^4[^3Pistols^4]^1 Vei primi pistolul ales la următorul spawn.");
}

public PutInTable(Index, Item)
{
	new Cache[120], NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(NickName, charsmax(NickName), "'", " ");
	
	if ( !GetBit(InTable, Index) )
	{
		formatex(Cache, charsmax(Cache), "INSERT INTO Pistols(NickName, PistolId) VALUES('%s', '%d')", NickName, Item);
	}
	else
	{
		formatex(Cache, charsmax(Cache), "UPDATE Pistols SET PistolId = '%d' WHERE NickName = '%s'", Item, NickName);
	}
	TrieSetCell(PistolInfo, NickName, Item);
	SQL_ThreadQuery(SqlTuple, "CheckForErrors", Cache);
}

public CheckForErrors(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if ( FailState == TQUERY_CONNECT_FAILED )
	{
		log_amx("FailState == TQUERY_CONNECT_FAILED, Could not connect to SQL database.");
		reconnectToSqlDataBase();
		return;
	}
	else if ( FailState == TQUERY_QUERY_FAILED )
	{
		log_amx("FailState == TQUERY_QUERY_FAILED, Query failed.");
		reconnectToSqlDataBase();
		return;
	}
	
	if ( Errcode )
	{
		log_amx("Error on query: %s", Error);
		return;
	}
}

public CheckIfNameExists(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if ( FailState == TQUERY_CONNECT_FAILED )
	{
		log_amx("FailState == TQUERY_CONNECT_FAILED, Could not connect to SQL database.");
		reconnectToSqlDataBase();
		return;
	}
	else if ( FailState == TQUERY_QUERY_FAILED )
	{
		log_amx("FailState == TQUERY_QUERY_FAILED, Query failed.");
		reconnectToSqlDataBase();
		return;
	}
	if ( Errcode )
	{
		log_amx("Error on query: %s", Error);
		return;
	}
	
	new Index = get_user_index(Data);
	SetBit(HasSlot, Index);
	
	if( SQL_NumResults(Query) != 1)
	{
		return;
	}
	
	SetBit(InTable, Index);
	TrieSetCell(PistolInfo, Data, SQL_ReadResult(Query, 2));
	
	return;
}

public givePistol(Index)
{
	if (!is_user_alive(Index))
	{
		return
	}
	strip_user_weapons(Index);
	give_item(Index, "weapon_knife");
	if (!cs_get_user_nvg(Index))
	{
		cs_set_user_nvg(Index);
	}
	
	if (cs_get_user_team(Index) != CS_TEAM_CT)
	{
		return
	}
	
	if (GetBit(NameChanged, Index))
	{
		new Cache[120], NickName[MAX_NAME_LENGTH];
		get_user_name(Index, NickName, charsmax(NickName));
		replace_string(NickName, charsmax(NickName), "'", " ");

		formatex(Cache, charsmax(Cache), "SELECT * FROM Pistols WHERE NickName = '%s'", NickName);
		SQL_ThreadQuery(SqlTuple, "CheckIfNameExists", Cache, NickName, charsmax(NickName));
		DelBit(NameChanged, Index);
	}
		
	new PistolIndex, NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(NickName, charsmax(NickName), "'", " ");
	TrieGetCell(PistolInfo, NickName, PistolIndex);
		
	if (PistolIndex == 0)
	{
		PistolIndex = random_num(1, 6);
	}
		
	switch (PistolIndex)
	{
		case 1:
		{
			give_item(Index, "weapon_usp");
			cs_set_user_bpammo(Index, CSW_USP, 100);
		}
		case 2:
		{
			give_item(Index, "weapon_glock18");
			cs_set_user_bpammo(Index, CSW_GLOCK18, 120);
		}
		case 3:
		{
			give_item(Index, "weapon_p228");
			cs_set_user_bpammo(Index, CSW_P228, 52);
		}
		case 4:
		{
			give_item(Index, "weapon_elite");
			cs_set_user_bpammo(Index, CSW_ELITE, 120);
		}
		case 5:
		{
			give_item(Index, "weapon_fiveseven");
			cs_set_user_bpammo(Index, CSW_FIVESEVEN, 100);
		}
		case 6:
		{
			give_item(Index, "weapon_deagle");
			cs_set_user_bpammo(Index, CSW_DEAGLE, 35);
		}
	}
}