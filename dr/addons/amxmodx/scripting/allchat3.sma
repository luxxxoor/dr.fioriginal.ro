#include <amxmisc>
#include <cstrike>
#include <clantag>
#include <accesses>
#include <sqlx>
#include <sqlsmart>

new Trie:ReplaceTrie, Trie:CustomeTag, Handle:SqlTuple;
public AllChatOnConsoleLog = 1;

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "The new allchat",
		.version     = "3.0",
		.author      = "Dr.FioriGinal.Ro"
	);
   
	register_clcmd("say", "cmdSay");
	register_clcmd("say_team", "cmdSay");
   
	register_srvcmd("allchat_reload", "loadAllWords");
   
	ReplaceTrie = TrieCreate();
	CustomeTag = TrieCreate();
   
	loadAllWords();
}

public plugin_end() 
{
	TrieDestroy(ReplaceTrie);
	TrieDestroy(CustomeTag);
}

public onSqlConnection(Handle:Tuple)
{
	SqlTuple = Tuple;
	SQL_ThreadQuery(SqlTuple, "checkForErrors", "CREATE TABLE IF NOT EXISTS AllChatTags (Id int(8) PRIMARY KEY NOT NULL AUTO_INCREMENT, NickName varchar(32) UNIQUE, CustomeTag varchar(16))");
}

public cmdSay(Index) 
{ 
	new Name[MAX_NAME_LENGTH], Message[192];

	read_args(Message, charsmax(Message));
	remove_quotes(Message);
	
	if (!Message[0])
	{
		return PLUGIN_HANDLED;
	}
	
	new const reloadAllChatIdent[] = "!reloadallchat", setTagIdent[] = "!settag";
	
	if (equal(Message, reloadAllChatIdent, charsmax(reloadAllChatIdent)))
	{
		loadAllWords();
		client_print_color(Index, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Ai reincarcat cuvintele din allchat.");
		
		return PLUGIN_HANDLED;
	}
	
	if (equal(Message, setTagIdent, charsmax(setTagIdent)))
	{
		new Tag[16];
		copy(Tag, charsmax(Tag), Message[charsmax(setTagIdent)+1])
		
		setCustumeFlag(Index, Tag, charsmax(Tag));
	}

	replaceWords(Message, charsmax(Message));
	
	get_user_name(Index, Name, charsmax(Name));
	setTagAndPrint(Index, Message, Name, charsmax(Name));
	
	return PLUGIN_HANDLED;
}

setCustumeFlag(Index, Tag[], Len)
{
	new Cache[120], NickName[MAX_NAME_LENGTH];
	get_user_name(Index, NickName, charsmax(NickName));
	replace_string(Tag, Len, "'", " ");
	new bool:KeyExists = TrieKeyExists(CustomeTag, NickName);
	TrieSetString(CustomeTag, NickName, Tag);
	replace_string(NickName, charsmax(NickName), "'", " ");
	
	if (!KeyExists)
	{
		formatex(Cache, charsmax(Cache), "INSERT INTO AllChatTags(NickName, CustomeTag) VALUES('%s', '%s')", NickName, Tag);
	}
	else
	{
		formatex(Cache, charsmax(Cache), "UPDATE AllChatTags SET CustomeTag = '%s' WHERE NickName = '%s'", Tag, NickName);
	}
	
	SQL_ThreadQuery(SqlTuple, "checkForErrors", Cache);
}

public checkForErrors(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (Errcode)
	{
		log_error(AMX_ERR_GENERAL, "Error on query: %s", Error);
	}
	if (FailState == TQUERY_CONNECT_FAILED)
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		reconnectToSqlDataBase();
		return;
	}
	else if (FailState == TQUERY_QUERY_FAILED)
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		return;
	}
}

public client_authorized(Index)
{
	new Name[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name))
	
	if (TrieKeyExists(CustomeTag, Name))
	{
		return
	}
	
	replace_string(Name, charsmax(Name), "'", " ");
	new Cache[120];
	formatex(Cache, charsmax(Cache), "SELECT * FROM AllChatTags WHERE NickName = '%s'", Name);
	SQL_ThreadQuery(SqlTuple, "getSqlValue", Cache, Name, charsmax(Name));
}

public getSqlValue(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	if (Errcode)
	{
		log_error(AMX_ERR_GENERAL, "Error on query: %s", Error);
	}
	if (FailState == TQUERY_CONNECT_FAILED)
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		reconnectToSqlDataBase();
		return;
	}
	else if (FailState == TQUERY_QUERY_FAILED)
	{
		log_error(AMX_ERR_GENERAL, "Query failed.");
		return;
	}
	
	if (SQL_NumResults(Query) != 1)
	{
		return;
	}
	
	new Tag[16];
	SQL_ReadResult(Query, 2, Tag, charsmax(Tag))
	TrieSetString(CustomeTag, Data, Tag);
}

public loadAllWords()
{
	TrieClear(ReplaceTrie);
	new Path[] = "addons/amxmodx/configs/allchat-replacement.ini";
	
	new FilePointer = fopen(Path, "r+");
	
	if (!FilePointer)
	{
		return;
	}

	new Text[121], ForReplaceWord[64], ReplacedWord[64];

	while (!feof(FilePointer))
	{
		fgets(FilePointer, Text, charsmax(Text));
		
		trim(Text);
		
		if (!(Text[0] == '"'))
		{
			continue;
		}
		if ( parse(Text, ForReplaceWord, charsmax(ForReplaceWord), ReplacedWord, charsmax(ReplacedWord)) != 2 )
		{
			continue;
		}
		
		TrieSetString(ReplaceTrie, ForReplaceWord, ReplacedWord);
	}
	fclose(FilePointer);
}

setTagAndPrint(Index, Message[], Name[], Len)
{
	new ClanTag[15], NewName[47], bool:Colored, Type;
	if (getClanTag(Name, Len, ClanTag, charsmax(ClanTag), Type))
	{
		if (Type)
		{
			formatex(NewName, charsmax(NewName), "^4%s^3%s", ClanTag, Name);
		}
		else
		{
			formatex(NewName, charsmax(NewName), "^3%s^4%s", Name, ClanTag);
		}
	}
	else
	{
		copy(NewName, charsmax(NewName), Name);
	}
   
	static TrialReviveIndex;
	if (TrialReviveIndex == 0)
	{
		TrialReviveIndex = get_xvar_id("TrialReviveIndex");
	}
	
	if (get_user_flags(Index) & ADMIN_LEVEL_H || get_xvar_num(TrialReviveIndex) == Index)
	{
		Colored = true;
	}
	
	if (TrieKeyExists(CustomeTag, Name))
	{
		new Tag[16]
		TrieGetString(CustomeTag, Name, Tag, charsmax(Tag))
		printMessage(Index, "^1%s ^3%s %c:%s", Tag, NewName, Colored ? '^4' : '^1', Message);
		return
	}
   
	printMessage(Index, " ^3%s %c:%s", NewName, Colored ? '^4' : '^1', Message);
}

printMessage(const Index, const StandardMessage[], any:...)
{
	new Players[MAX_PLAYERS], PlayersNum, Message[192];
	vformat(Message, charsmax(Message), StandardMessage, 3);
	get_players(Players, PlayersNum, "c");
	
	replaceTagNames(Message, charsmax(Message), contain(Message, ":") + 1, contain(Message[contain(Message, ":")-1], "^4") != -1);
	
	for(new i = 0; i < PlayersNum; ++i)
	{
		client_print_color(Players[i], Index, Message);
	}
	
	if ( AllChatOnConsoleLog )
	{
		replace_string(Message, charsmax(Message), "^1", "");
		replace_string(Message, charsmax(Message), "^3", "");
		replace_string(Message, charsmax(Message), "^4", "");
		format(Message, charsmax(Message), "[The new allchat] %s", Message);
		server_print(Message);
	}
}

replaceTagNames(Message[], Len, StartPos, bool:Colored)
{
	new Char = Message[strlen(Message)-1];
	Message[strlen(Message)-1] = ' ';
	new TagReplacement[MAX_NAME_LENGTH], Name[MAX_NAME_LENGTH], Index;
	for (new i = StartPos; i < Len; ++i)
	{
		if (Message[i] == '@')
		{
			split_string(Message[i], " ", TagReplacement, charsmax(TagReplacement));
			Index = find_player("bl", TagReplacement[1]);
			if (Index)
			{
				get_user_name(Index, Name, charsmax(Name));
				if (Colored)
				{
					format(Name, charsmax(Name), "^3@^1%s^4", Name);
				}
				else
				{
					format(Name, charsmax(Name), "^3@^4%s^1", Name);
				}
				i += replace_stringex(Message[i], Len, TagReplacement, Name)
			}
		}
	}
	Message[strlen(Message)-1] = Char;
	Message[strlen(Message)] = 0;
}

replaceWords(Message[], Len)
{
	new String[192], ForReplaceWord[64], ReplacedWord[64];
	
	replace_string(Message, Len, "%", " ");
	
	format(Message, Len, " %s ", Message);
	copy(String, charsmax(String), Message);

	new WordType = 0, CheckWord[64];
	
	while ( String[0] )
	{
		strtok2(String, ForReplaceWord, charsmax(ForReplaceWord), String, charsmax(String));
		copy(CheckWord, charsmax(CheckWord), ForReplaceWord);
		if(is_char_upper(CheckWord[0]))
		{
			if (is_char_upper(CheckWord[1]))
			{
				WordType = 1;
			}
			else
			{
				WordType = 2;
			}
		}
		strtolower(CheckWord);
		if (TrieKeyExists(ReplaceTrie, CheckWord))
		{
			TrieGetString(ReplaceTrie, CheckWord, ReplacedWord, charsmax(ReplacedWord));
			strtolower(ReplacedWord);
			switch(WordType)
			{
				case 1 :
				{
					strtoupper(ReplacedWord);
				}
				case 2 :
				{
					ucfirst(ReplacedWord);
				}
			}
			format(ForReplaceWord, charsmax(ForReplaceWord), " %s ", ForReplaceWord);
			format(ReplacedWord, charsmax(ReplacedWord), " %s ", ReplacedWord);
			replace_string(Message, Len, ForReplaceWord, ReplacedWord, true);
		}
	}
	
	ucfirst(Message[1]);
	checkForPunctation(Message[1], Len-1);
	if (isalnum(Message[strlen(Message)-2]))
	{
		Message[strlen(Message)-1] = '.';
	}
}

checkForPunctation(Message[], Len)
{
	new Length = strlen(Message);
	for(new i = Length; i > 0; --i)
	{
		if (is_char_mb(Message[i]))
		{
			//i += get_char_bytes(Message[i])-1;
			continue;
		}
		if (!isalnum(Message[i]) && !isspace(Message[i]) && Message[i] != '@' && Message[i] != '^'' && Message[i] != '-' && Message[i] != '_' || Message[i] == '!')
		{
			for(new j = i; j < Length; ++j)
			{
				if (isalnum(Message[j]) || Message[j] == '@')
				{
					if (Message[i] == '.' || Message[i] == '?')
					{
						ucfirst(Message[j])
					}
					format(Message[i+1], Len, " %s", Message[j]);
					break;
				}
			}
		}
	}
}