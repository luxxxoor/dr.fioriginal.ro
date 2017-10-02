#include <amxmisc>

new Trie:Accesses;
new const File[] = "addons/amxmodx/configs/admin_accesses.ini";

public plugin_init()
{
	loadAccesses();
	
	register_plugin
	(
		.plugin_name = "Accese admini",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
}

public plugin_natives()
{
    register_library("accesses");
    
    register_native("getLevel", "_getLevel");
}

public _getLevel(PluginId, Parameters) // Index, Level, Len
{
	if (Parameters != 3 || Accesses == Invalid_Trie)
	{
		return any:false;
	}
	
	new Index = get_param(1), Len = get_param(3), bool:HasRevive;
	if (Index == 0)
	{
		set_string(2, "Server", Len);
		return any:true;
	}
	if (!is_user_admin(Index))
	{
		set_string(2, "Player", Len);
		return any:true;
	}
	new Flags[32];
	get_flags(get_user_flags(Index), Flags, charsmax(Flags));
	
	if (contain(Flags, "t"))
	{
		if (!TrieKeyExists(Accesses, Flags))
		{
			replace_stringex(Flags, charsmax(Flags), "t", "");
			if (TrieKeyExists(Accesses, Flags))
			{
				HasRevive = true;
			}
		}
	}
	
	if (!TrieKeyExists(Accesses, Flags))
	{
		set_string(2, "Access neidentificat", Len);
		return any:false;
	}
	
	new GradeName[35];
	TrieGetString(Accesses, Flags, GradeName, charsmax(GradeName));
	if (HasRevive)
	{
		add(GradeName, charsmax(GradeName), " + Revive");
	}
	set_string(2, GradeName, Len);
	
	return any:true;
}

loadAccesses()
{
	if ( !file_exists(File) )
	{
		new FilePointer = fopen(File, "wt");
		
		if ( !FilePointer ) 
		{
			return;
		}
		
		fputs(FilePointer, "; Aici vor fi inregistrate accesele adminilor.^n");
		fputs(FilePointer, "; Exemplu de adaugare acces : ^"nume grad^" ^"acces^"^n^n^n");
		fclose(FilePointer);
	}
	else
	{
		new Text[121], GradeName[30], Access[32];
		new FilePointer = fopen(File, "rt");
		
		if ( !FilePointer ) 
		{
			return;
		}
		
		if (Accesses == Invalid_Trie)
		{
			Accesses = TrieCreate();
		}
		else
		{
			TrieClear(Accesses);
		}
		
		while (!feof(FilePointer))
		{
			fgets(FilePointer, Text, charsmax(Text));

			trim(Text);
		
			if ((Text[0] == ';') || ((Text[0] == '/') && (Text[1] == '/')))
			{
				continue;
			}
		
			if (parse(Text, GradeName, charsmax(GradeName), Access, charsmax(Access)) == 2)
			{
				TrieSetString(Accesses, Access, GradeName);
			}
		}		
		fclose(FilePointer);
	}
}