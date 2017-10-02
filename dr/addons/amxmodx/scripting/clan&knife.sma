#include <amxmisc>
#include <celltravtrie>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

enum _:ClanData
{
	ClanName[15],
	ClanNameType,
	ClanPass[32],
	ClanModel[192]
}

new TravTrie:Clan, TravTrie:Members, Trie:RealNames;
new Option;
new const ClanFile[] = "addons/amxmodx/configs/clans.ini";
new const TempClanFile[] = "addons/amxmodx/configs/tempclans.ini";
new const BasicKnifeModel[] = "models/fioriginal/v_knife.mdl";

public plugin_precache()
{
	loadClanInfos();
	
	new Data[ClanData];
	
	new travTrieIter:Iterator = GetTravTrieIterator(Clan);
	while(MoreTravTrie(Iterator))
	{
		ReadTravTrieArray(Iterator, Data, ClanData);
		
		if (!file_exists(Data[ClanModel]))
		{
			continue;
		}
		precache_model(Data[ClanModel]);
	}
	DestroyTravTrieIterator(Iterator);
	
	precache_model("models/fioriginal/florin.mdl"); // cutit Florin*
	precache_model(BasicKnifeModel);
}

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Clan Tag",
		.version     = "2.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_clcmd("amx_clan", "clanCommands");
	register_clcmd("say", "hookChat");
	register_clcmd("clanrename", "clanRename");
	register_event("CurWeapon", "currentWeapon", "be", "1=1");
}

public hookChat(Index)
{
	new Said[32];
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if ( !Said[0] )
	{
		return PLUGIN_CONTINUE;
	}
	
	new const KnifeIdent[] = "!tralala";
	if (equali(Said, KnifeIdent, charsmax(KnifeIdent)))
	{
		if (is_user_alive(Index))
		{
			if (get_user_weapon(Index) == CSW_KNIFE)
			{
				set_pev(Index, pev_viewmodel2, GetBit(Option, Index) ? BasicKnifeModel : "models/v_knife.mdl");
			}
		}
		GetBit(Option, Index) ? DelBit(Option, Index) : SetBit(Option, Index);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public client_disconnected(Index)
{
	DelBit(Option, Index);
}

public plugin_natives()
{
    register_library("clantag");
    
    register_native("getClanTag", "_getClanTag");
}

public _getClanTag(PluginId, Parameters)
{
	if(Parameters != 5 || Clan == Invalid_TravTrie || Members == Invalid_TravTrie)
	{
		return any:false;
	}
	
	new Len = get_param(2);
	new MemberName[MAX_NAME_LENGTH];
	get_string(1, MemberName, Len);
	strtolower(MemberName);
	
	if (!TravTrieKeyExists(Members, MemberName))
	{
		return any:false;
	}
	
	new TagName[15], Data[ClanData];
	TravTrieGetString(Members, MemberName, TagName, charsmax(TagName));
	Len = get_param(4);
	set_string(3, TagName, Len);
	TravTrieGetArray(Clan, TagName, Data, ClanData);
	set_param_byref(5, Data[ClanNameType]);
	
	return any:true;
}

public clanCommands(Index)
{
	new Name[32];
	get_user_name(Index, Name, charsmax(Name));
	strtolower(Name);
	
	if (!TravTrieKeyExists(Members, Name))
	{
		client_print(Index, print_console, "[Clan Management] Nu aparții nici unui clan");
		return PLUGIN_HANDLED;
	}
	
	new Data[ClanData], TagName[15], Pass[32];
	TravTrieGetString(Members, Name, TagName, charsmax(TagName));
	
	new travTrieIter:Iterator = GetTravTrieIterator(Clan);
	while(MoreTravTrie(Iterator))
	{
		ReadTravTrieArray(Iterator, Data, ClanData);
		
		if (equal(TagName, Data[ClanName]))
		{
			read_argv(1, Pass, charsmax(Pass));
			if (!equal(Pass, Data[ClanPass]))
			{
				client_print(Index, print_console, "[Clan Management] Nu deții parola acestui clan.");
				return PLUGIN_HANDLED;
			}
			set_user_info(Index, "_clan", Pass);
			break;
		}
	}
	DestroyTravTrieIterator(Iterator);
	
	new Menu = menu_create("Detalii despre clan :", "clanAction");
	menu_additem(Menu, "Elimină membru.");
	menu_additem(Menu, "Adaugă membru.");
	menu_additem(Menu, "Schimbă numele clanului.");
	menu_display(Index, Menu);
	

	return PLUGIN_HANDLED;
}

public clanRename(Index)
{
	new NewName[15], MemberName[MAX_NAME_LENGTH];
	get_user_name(Index, MemberName, charsmax(MemberName));
	strtolower(MemberName);
	
	if (!TravTrieKeyExists(Members, MemberName))
	{
		return PLUGIN_HANDLED;
	}
	new Pass[32], Data[ClanData], TagName[15];
	TravTrieGetString(Members, MemberName, TagName, charsmax(TagName));
	read_argv(1, Pass, charsmax(Pass));
	
	new travTrieIter:Iterator = GetTravTrieIterator(Clan);
	while(MoreTravTrie(Iterator))
	{
		ReadTravTrieArray(Iterator, Data, ClanData);
		
		if (equal(TagName, Data[ClanName]))
		{
			get_user_info(Index, "_clan", Pass, charsmax(Pass));
			if (!equal(Pass, Data[ClanPass]))
			{
				return PLUGIN_HANDLED;
			}
			break;
		}
	}
	DestroyTravTrieIterator(Iterator);
	
	read_argv(1, NewName, charsmax(NewName));
	changeClanName(Index, NewName, TagName);
	
	return PLUGIN_HANDLED;
}

public clanAction(Index, Menu, Item)
{
	switch (Item)
	{
		case 0 :
		{
			deleteClanMember(Index);
		}
		case 1 :
		{
			addClanMember(Index);
		}
		case 2 :
		{
			client_cmd(Index, "messagemode clanrename");
		}
	}
}

deleteClanMember(Index)
{
	new MemberName[MAX_NAME_LENGTH], TagName[15], Name[MAX_NAME_LENGTH], MemberTagName[15];
	get_user_name(Index, Name, charsmax(Name));
	strtolower(Name);
	TravTrieGetString(Members, Name, TagName, charsmax(TagName));
	
	new Menu = menu_create("Alege membrul care vrei să fie eliminat din clan", "askForDeleteMember");
	
	new travTrieIter:Iterator = GetTravTrieIterator(Members), RealPlayerName[MAX_NAME_LENGTH];
	while(MoreTravTrie(Iterator))
	{
		ReadTravTrieKey(Iterator, MemberName, charsmax(MemberName));
		
		if (equal(Name, MemberName))
		{
			ReadTravTrieString(Iterator, MemberTagName, charsmax(MemberTagName)); // ReadTravTrieKey nu incrementreaza iteratorul
			continue;
		}
		
		ReadTravTrieString(Iterator, MemberTagName, charsmax(MemberTagName));
		if (!equal(MemberTagName, TagName))
		{
			continue;
		}
		
		TrieGetString(RealNames, MemberName, RealPlayerName, charsmax(RealPlayerName));
		menu_additem(Menu, RealPlayerName);
	}
	DestroyTravTrieIterator(Iterator);
	if (menu_items(Menu) > 0)
	{
		menu_display(Index, Menu);
	}
	else
	{
		client_print_color(Index, print_team_red, "^3[^1Clan Management^3] ^4Ești singurul jucător al acestui clan. (Îl poți părăsi folosind !clan)");
		menu_destroy(Menu);
	}
}

addClanMember(Index)
{
	new Menu = menu_create("Adaugă un nou membru", "addNewMember");
	new Players[MAX_PLAYERS], PlayersMatched, Name[MAX_NAME_LENGTH];
	get_players(Players, PlayersMatched, "c");
	for (new i = 0; i < PlayersMatched; ++i)
	{
		get_user_name(Players[i], Name, charsmax(Name));
		strtolower(Name);
		if (TravTrieKeyExists(Members, Name))
		{
			continue;
		}
		get_user_name(Players[i], Name, charsmax(Name));
		menu_additem(Menu, Name);
	}
	
	if (menu_items(Menu) > 0)
	{
		menu_display(Index, Menu);
	}
	else
	{
		client_print_color(Index, print_team_red, "^3[^1Clan Management^3] ^4Nu se află nici un jucător pe server cu slot care să nu aparțină nici unui clan.");
		menu_destroy(Menu);
	}
}

changeClanName(Index, NewName[], TagName[])
{
	new Name[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name));
	strtolower(Name);
	new OldFilePointer = fopen(ClanFile, "r"), NewFilePointer = fopen(TempClanFile, "w");
	
	new Text[121], MemberName[MAX_NAME_LENGTH], bool:Separator, CurrentTagName[15];
	while (!feof(OldFilePointer))
	{
		fgets(OldFilePointer, Text, charsmax(Text));
		if (Text[0] == '-' && Text[1] == '-' && Text[2] == '-')
		{
			Separator = true;
			fputs(NewFilePointer, Text);
			continue;
		}
		
		if (Separator)
		{
			if (contain(Text, TagName) != -1)
			{
				parse(Text, MemberName, charsmax(MemberName), CurrentTagName, charsmax(CurrentTagName));
				replace_stringex(Text, charsmax(Text), CurrentTagName, NewName);
			}
		}
		else
		{
			if (contain(Text, TagName) != -1)
			{
				parse(Text, CurrentTagName, charsmax(CurrentTagName));
				replace_stringex(Text, charsmax(Text), CurrentTagName, NewName);
			}
		}
		fputs(NewFilePointer, Text);
	}		
	fclose(OldFilePointer);
	fclose(NewFilePointer);
	
	delete_file(ClanFile);
	rename_file(TempClanFile, ClanFile, 1);
	loadClanInfos();
}

public addNewMember(Index, Menu, Item)
{
	if (Item < 0)
	{
		return;
	}
	
	new Access, Info[1], Name[MAX_NAME_LENGTH], Callback, MenuBuffer[155];
	menu_item_getinfo(Menu, Item, Access, Info, charsmax(Info), Name, charsmax(Name), Callback);
	formatex(MenuBuffer, charsmax(MenuBuffer), "Ești sigur că vrei să-l adaugi pe \r%s\y în clan ?", Name);
	new NewMenu = menu_create(MenuBuffer, "answerForAddingMember");
	menu_additem(NewMenu, "Da", Name);
	menu_additem(NewMenu, "Nu", Name);
	menu_display(Index, NewMenu);
}

public answerForAddingMember(Index, Menu, Item)
{
	if (Item == 0)
	{
		if (!file_exists(ClanFile))
		{
			return;
		}

		new FilePointer = fopen(ClanFile, "a"), Access, Name[MAX_NAME_LENGTH], NewMemberName[MAX_NAME_LENGTH], Callback, TagName[15];
		menu_item_getinfo(Menu, Item, Access, NewMemberName, charsmax(NewMemberName), Name, charsmax(Name), Callback);
		get_user_name(Index, Name, charsmax(Name));
		strtolower(Name);
		TravTrieGetString(Members, Name, TagName, charsmax(TagName));
		fprintf(FilePointer, "^n^"%s^" ^"%s^"", NewMemberName, TagName)
		
		fclose(FilePointer);
		
		loadClanInfos();
	}
}

public askForDeleteMember(Index, Menu, Item)
{
	if (Item < 0)
	{
		return;
	}
	
	new Access, Info[1], Name[MAX_NAME_LENGTH], Callback, MenuBuffer[155];
	menu_item_getinfo(Menu, Item, Access, Info, charsmax(Info), Name, charsmax(Name), Callback);
	formatex(MenuBuffer, charsmax(MenuBuffer), "Ești sigur că vrei să-l scoți pe \r%s\y din clan ?", Name);
	new NewMenu = menu_create(MenuBuffer, "answerForDeletingMember");
	menu_additem(NewMenu, "Da", Name);
	menu_additem(NewMenu, "Nu", Name);
	menu_display(Index, NewMenu);
}

public answerForDeletingMember(Index, Menu, Item)
{
	if (Item == 0)
	{
		if (!file_exists(ClanFile))
		{
			return;
		}

		new Access, Name[1], DeletingMemberName[MAX_NAME_LENGTH], Callback;
		menu_item_getinfo(Menu, Item, Access, DeletingMemberName, charsmax(DeletingMemberName), Name, charsmax(Name), Callback);
		deleteMember(DeletingMemberName);
	}
}

public currentWeapon(Index)
{
	if (is_user_bot(Index) || Clan == Invalid_TravTrie || Members == Invalid_TravTrie)
	{
		return;
	}
	
	if (!GetBit(Option, Index))
	{
		if (get_user_weapon(Index) == CSW_KNIFE)
		{
			new Data[ClanData], Name[MAX_NAME_LENGTH];
			get_user_name(Index, Name, charsmax(Name));
			if (containi(Name, "Florin *") != -1)
			{
				set_pev(Index, pev_viewmodel2, "models/fioriginal/florin.mdl");
				return;
			}
			strtolower(Name);
			if (!TravTrieKeyExists(Members, Name))
			{
				set_pev(Index, pev_viewmodel2, BasicKnifeModel);
				return;
			}
			new TagName[15];
			TravTrieGetString(Members, Name, TagName, charsmax(TagName));
			
			new travTrieIter:Iterator = GetTravTrieIterator(Clan);
			while(MoreTravTrie(Iterator))
			{
				ReadTravTrieArray(Iterator, Data, ClanData);
				if (equal(TagName, Data[ClanName]) && file_exists(Data[ClanModel]))
				{
					set_pev(Index, pev_viewmodel2, Data[ClanModel]);
					return;
				}
			}
			DestroyTravTrieIterator(Iterator);
		}
	}
}

loadClanInfos()
{
	new Path[64];
	
	get_localinfo("amxx_configsdir", Path, charsmax(Path));
	add(Path, charsmax(Path), "/clans.ini")
	
	if ( !file_exists(Path) )
	{
		new FilePointer = fopen(Path, "wt");
		
		if ( !FilePointer ) 
		{
			return;
		}
		
		fputs(FilePointer, "; Aici vor fi inregistrate numele de clan protejate.^n");
		fputs(FilePointer, "; Exemplu de adaugare tag clan : ^"nume clan^" ^"parola clan^" ^"model clan^"^n^n^n");
		fputs(FilePointer, "---^n^n^n");
		fputs(FilePointer, "; Exemplu de adaugare membru clan : ^"nume membru^" ^"nume clan^"");
		fclose(FilePointer);
	}
	else
	{
		new FilePointer = fopen(Path, "rt");
		
		if (!FilePointer) 
		{
			return;
		}
		if (Clan == Invalid_TravTrie)
		{
			Clan = TravTrieCreate();
		}
		else
		{
			TravTrieClear(Clan);		
		}
		
		if (Members == Invalid_TravTrie)
		{
			Members = TravTrieCreate();
		}
		else
		{
			TravTrieClear(Members);
		} 
		
		if (RealNames == Invalid_Trie)
		{
			RealNames = TrieCreate();
		}
		else
		{
			TrieClear(RealNames);
		}
		
		new Text[121], TagName[16], Type[9], Password[32], ModelPath[192];
		new Data[ClanData];
		while (!feof(FilePointer))
		{
			fgets(FilePointer, Text, charsmax(Text));

			trim(Text);
		
			if ((Text[0] == ';') || !strlen(Text) || ((Text[0] == '/') && (Text[1] == '/')))
			{
				continue;
			}
			if (Text[0] == '-' && Text[1] == '-' && Text[2] == '-')
			{
				break;
			}
		
			if (parse(Text, TagName, charsmax(TagName), Type, charsmax(Type), Password, charsmax(Password), ModelPath, charsmax(ModelPath)) < 3)
			{
				continue;
			}
			
			copy(Data[ClanName], charsmax(Data[ClanName]), TagName);
			Data[ClanNameType] = equali(Type, "prenume") ? 1 : equali(Type, "postnume") ? 0 : -1
			if (Data[ClanNameType] == -1)
			{
				continue;
			}
			copy(Data[ClanPass], charsmax(Data[ClanPass]), Password);
			copy(Data[ClanModel], charsmax(Data[ClanModel]), ModelPath);
			TravTrieSetArray(Clan, TagName, Data, ClanData);
			ModelPath[0] = 0 // mereu reseteaza bufferul pt model
		}
		
		new MemberName[MAX_NAME_LENGTH], bool:ValidClan;
		while (!feof(FilePointer))
		{
			fgets(FilePointer, Text, charsmax(Text));

			trim(Text);
		
			if ((Text[0] == ';') || !strlen(Text) || ((Text[0] == '/') && (Text[1] == '/')))
			{
				continue;
			}
		
			if (parse(Text, MemberName, charsmax(MemberName), TagName, charsmax(TagName)) != 2)
			{
				continue;
			}
			
			new travTrieIter:Iterator = GetTravTrieIterator(Clan);
			while(MoreTravTrie(Iterator))
			{
				ReadTravTrieArray(Iterator, Data, ClanData);
				
				if (equal(Data[ClanName], TagName))
				{
					ValidClan = true;
					break;
				}
			}
			DestroyTravTrieIterator(Iterator);
			
			if (!ValidClan)
			{
				continue;
			}
			
			new RealPlayerName[MAX_NAME_LENGTH];
			copy(RealPlayerName, charsmax(RealPlayerName), MemberName);
			strtolower(MemberName);
			TrieSetString(RealNames, MemberName, RealPlayerName);
			TravTrieSetString(Members, MemberName, TagName);
		}
		
		fclose(FilePointer);
	}
}

deleteMember(DeletingMemberName[])
{
	new OldFilePointer = fopen(ClanFile, "r"), NewFilePointer = fopen(TempClanFile, "w");
	
	new Text[121], MemberName[MAX_NAME_LENGTH], bool:Separator, bool:Found;
	while (!feof(OldFilePointer))
	{
		fgets(OldFilePointer, Text, charsmax(Text));
		if (Text[0] == '-' && Text[1] == '-' && Text[2] == '-')
		{
			Separator = true;
			fputs(NewFilePointer, Text);
			continue;
		}
		
		if (Separator)
		{
			if (!Found)
			{
				parse(Text, MemberName, charsmax(MemberName));
				trim(MemberName);
				if (equal(DeletingMemberName, MemberName))
				{
					Found = true;
					continue;
				}
			}
		}
		fputs(NewFilePointer, Text);
	}		
	fclose(OldFilePointer);
	fclose(NewFilePointer);
	
	delete_file(ClanFile);
	rename_file(TempClanFile, ClanFile, 1);
	loadClanInfos();
}