#include <amxmisc>
#include <sqlx>

new Handle:SqlTuple , SqlError[512];

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Evidenta",
		.version     = "1.0",
		.author      = "lüxor"
	);

	new const Host[] = "195.178.102.2",
			  User[] = "fullboos_test",
			  Pass[] = "andreyA1@",
			  Db[]   = "fullboos_test";

	SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db);
   
	new ErrorCode, Handle:SqlConnection = SQL_Connect(SqlTuple, ErrorCode, SqlError, charsmax(SqlError));
	if (SqlConnection == Empty_Handle)
	{
		set_fail_state(SqlError);
	}
   
	new Handle:Query  = SQL_PrepareQuery(SqlConnection,\
			  "CREATE TABLE IF NOT EXISTS Evidenta (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, NickName varchar(32), Ip varchar(35), ServerIp varchar(35))");
 
	if (!SQL_Execute(Query))
	{
		SQL_QueryError(Query, SqlError, charsmax(SqlError));
		set_fail_state(SqlError);
	}
   
	SQL_FreeHandle(Query);
}

public plugin_end()
{
	SQL_FreeHandle(SqlTuple);
}

public client_authorized(Index)
{
	new Cache[120], NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(NickName, charsmax(NickName), "'", " ");
	
	formatex(Cache, charsmax(Cache), "SELECT * FROM Evidenta WHERE NickName = '%s'", NickName);
	SQL_ThreadQuery(SqlTuple, "CheckIfNameExists", Cache, NickName, charsmax(NickName));
}

public CheckIfNameExists(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if ( FailState == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to SQL database.");
		return;
	}
	else if ( FailState == TQUERY_QUERY_FAILED )
	{
		set_fail_state("Query failed.");
		return;
	}
	
	if ( Errcode )
	{
		log_amx("Error on query: %s", Error);
		return;
	}
	
	if( SQL_NumResults(Query) != 0)
	{
		return;
	}
	
	new Index = get_user_index(Data);
	new Ip[35], ServerIp[35], Cache[120];
	get_user_ip(Index, Ip, charsmax(Ip), any:true);
	get_user_ip(0, ServerIp, charsmax(ServerIp), any:true);
	
	formatex(Cache, charsmax(Cache), "INSERT INTO Evidenta(NickName, Ip, ServerIp) VALUES('%s', '%s', '%s')", Data, Ip, ServerIp);
	SQL_ThreadQuery(SqlTuple, "CheckForErrors", Cache);
	
	return;
}

public CheckForErrors(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if ( FailState == TQUERY_CONNECT_FAILED )
	{
		set_fail_state("Could not connect to SQL database.");
		return;
	}
	else if ( FailState == TQUERY_QUERY_FAILED )
	{
		//set_fail_state("Query failed.");
		return;
	}
	
	if ( Errcode )
	{
		log_amx("Error on query: %s", Error);
		return;
	}
	
	return;
}