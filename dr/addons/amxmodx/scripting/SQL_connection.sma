//nu inchide toate conexiunile sql deschise.
#include <amxmisc>
#include <sqlx>

enum _:Data
{
	Host[64], 
	User[32], 
	Pass[32], 
	Db[128]
}

new Handle:SqlTuple;
new SqlData[Data];
new reconnectionTentatives;
new const MaxReconnectionTentatives = 20;
new const RestartReconnectionId = 10000;

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "SQL Smart Connection API",
		.version     = "1.1",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	readData();
}

public plugin_natives()
{
	register_library("SqlSmart");
    
	register_native("reconnectToSqlDataBase", "_reconnectToSqlDataBase");
}

readData()
{
	new Path[] = "addons/amxmodx/configs/SQL-connection.ini";
	
	if (!file_exists(Path))
	{
		new FilePointer = fopen(Path, "wt");
		
		if ( !FilePointer ) 
		{
			return;
		}
		
		fputs(FilePointer, "; Aici va fi inregistrata conexiunea SQL. (Doar una)^n");
		fputs(FilePointer, "; Exemplu de adaugare conexiune : ^"Host^" ^"User^" ^"Pass^" ^"Db^"^n^n^n");
		fclose(FilePointer);
		
		return;
	}
	new FilePointer = fopen(Path, "r+");
	
	if (!FilePointer)
	{
		return;
	}

	new Text[121], bool:Found;

	while (!feof(FilePointer))
	{
		fgets(FilePointer, Text, charsmax(Text));
		
		trim(Text);
		
		if ((Text[0] == ';') || ((Text[0] == '/') && (Text[1] == '/')))
		{
			continue;
		}
		
		if (parse(Text, SqlData[Host], charsmax(SqlData[Host]), SqlData[User], charsmax(SqlData[User]),
						SqlData[Pass], charsmax(SqlData[Pass]), SqlData[Db], charsmax(SqlData[Db])) != 4)
		{
			continue;
		}
		
		Found = true;
		break;
	}
	
	fclose(FilePointer);
	
	if (!Found)
	{
		log_error(1, "Nu s-au gasit datele de conectare la serverul SQL");
	}
	
	_connectToSqlDataBase();
}

_connectToSqlDataBase()
{
	SqlTuple = SQL_MakeDbTuple(SqlData[Host], SqlData[User], SqlData[Pass], SqlData[Db]);
	
	if (SqlTuple == Empty_Handle)
	{
		return;
	}
	
	new Forward = CreateMultiForward("onSqlConnection", ET_IGNORE, FP_CELL), ReturnValue;
	
	if (Forward == -1)
	{
		log_error(1, "Forward-ul nu a putut fi creat.");
	}
	
	if (!ExecuteForward(Forward, ReturnValue, SqlTuple))
	{
		log_error(1, "Forward-ul nu s-a putut executa.");
	}
	
	DestroyForward(Forward);
}

public restartReconnection()
{
	reconnectionTentatives = 0;
}

public _reconnectToSqlDataBase(PluginId, Parameters)
{
	if (Parameters != 0)
	{
		log_error(4, "Functia ^"connectToSqlDataBase^" nu are parametrii");
	}
	
	if(++reconnectionTentatives > MaxReconnectionTentatives)
	{
		if(!task_exists(RestartReconnectionId))
		{
			set_task(300.0, "restartReconnection", RestartReconnectionId);
		}
        
		return;
	}

	SqlTuple = SQL_MakeDbTuple(SqlData[Host], SqlData[User], SqlData[Pass], SqlData[Db]);
	
	if (SqlTuple == Empty_Handle)
	{
		return;
	}
	
	new Forward = CreateOneForward(PluginId, "onSqlConnection", FP_CELL), ReturnValue;
	
	if (Forward == -1)
	{
		log_error(1, "Forward-ul nu a putut fi creat.");
	}
	
	if (ExecuteForward(Forward, ReturnValue, SqlTuple))
	{
		log_error(1, "Forward-ul nu s-a putut executa.");
	}
	
	DestroyForward(Forward);
}

public plugin_end()
{
	if (SqlTuple != Empty_Handle)
	{
		SQL_FreeHandle(SqlTuple);
	}
}