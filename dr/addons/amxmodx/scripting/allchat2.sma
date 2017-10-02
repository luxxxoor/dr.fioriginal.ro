//sa verifice daca vine litera dupa pct ca sa o faca litera mare, sa verifice daca jucatorii nu striga un nume specific.
#include <amxmisc>
#include <cstrike>
#include <clantag>
#include <accesses>
#include <celltravtrie>

#define BitSet(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define BitClear(%1,%2) (%1 &= ~(1 << (%2 & 31))) 
#define BitGet(%1,%2)   (%1 & (1 << (%2 & 31)))

enum _:BlockChatData
{
	TargetsBlock,
	AdminTargetsBlock
}

new bool:Competition, Trie:ReplaceTrie, Trie:BlockedData, Blocked[MAX_PLAYERS+1], ForcedBlocked[MAX_PLAYERS+1];
public AllChatOnConsoleLog = 1;

public plugin_init() 
{

	register_plugin
	(
		.plugin_name = "The new allchat",
		.version     = "2.6",
		.author      = "Dr.FioriGinal.Ro"
	);
   
	register_clcmd("say", "cmdSay");
	register_clcmd("say_team", "cmdSay");
   
	register_concmd("amx_blockchat", "blockChatInteraction", ADMIN_KICK, "<name or #userid> <name or #userid>");
   
	register_srvcmd("allchat_reload", "loadAllWords");
   
	ReplaceTrie = TrieCreate();
	BlockedData = TrieCreate();
   
	loadAllWords();
}

public plugin_end() 
{
	TrieDestroy(ReplaceTrie);
	TrieDestroy(BlockedData);
}

public client_connect(Index)
{
	new Ip[35];
	get_user_ip(Index, Ip, charsmax(Ip), any:true);
	if (TrieKeyExists(BlockedData, Ip))
	{
		new Data[BlockChatData];
		TrieGetArray(BlockedData, Ip, Data, BlockChatData);
		
		if (Data[TargetsBlock] != 0)
		{
			for(new i = 1; i <= MAX_PLAYERS; ++i)
			{
				if (BitGet(Data[TargetsBlock], i))
				{
					BitSet(Blocked[i], Index);
					BitSet(Blocked[Index], i);
				}
			}
		}
		if (Data[AdminTargetsBlock] != 0)
		{
			for(new i = 1; i <= MAX_PLAYERS; ++i)
			{
				if (BitGet(Data[AdminTargetsBlock], i))
				{
					BitSet(ForcedBlocked[i], Index);
					BitSet(ForcedBlocked[Index], i);
				}
			}
		}
	}
}

public client_disconnected(Index)
{
	new Ip[20], Data[BlockChatData];
	get_user_ip(Index, Ip, charsmax(Ip), any:true);
	for(new i = 1; i <= MAX_PLAYERS; ++i)
	{
		if (BitGet(Blocked[i], Index))
		{
			BitSet(Data[TargetsBlock], i);
			BitClear(Blocked[i], Index);
		}
		if (BitGet(ForcedBlocked[i], Index))
		{
			BitSet(Data[AdminTargetsBlock], i);
			BitClear(ForcedBlocked[i], Index);
		}
	}
	Blocked[Index] = 0;
	ForcedBlocked[Index] = 0;
	
	if (Data[TargetsBlock] != 0 || Data[AdminTargetsBlock] != 0)
	{
		TrieSetArray(BlockedData, Ip, Data, BlockChatData);
	}
}

public blockChatInteraction(Index, Level, CommandIndex)
{
	if (!cmd_access(Index, Level, CommandIndex, 3))
	{
		return PLUGIN_HANDLED;
	}
	
	new TargetName1[MAX_NAME_LENGTH], TargetName2[MAX_NAME_LENGTH];
	read_argv(1, TargetName1, charsmax(TargetName1));
	new TargetIndex1 = cmd_target(Index, TargetName1, CMDTARGET_NO_BOTS);
	if ( !TargetIndex1 )
	{
		return PLUGIN_HANDLED;
	}
	read_argv(2, TargetName2, charsmax(TargetName2));
	new TargetIndex2 = cmd_target(Index, TargetName2, CMDTARGET_NO_BOTS);
	if ( !TargetIndex2 || TargetIndex1 == TargetIndex2 )
	{
		console_print(Index, "[The new allchat] Ai nevoie de 2 persoane distrincte pentru a folosi comanda.");
		return PLUGIN_HANDLED;
	}
	
	if (get_user_flags(TargetIndex1) & ADMIN_KICK || get_user_flags(TargetIndex2) & ADMIN_KICK)
	{
		console_print(Index, "[The new allchat] Nu poți folosi comanda pe alți admini.");
		return PLUGIN_HANDLED;
	}
	
	if (TargetIndex1 == Index || TargetIndex2 == Index )
	{
		console_print(Index, "[The new allchat] Nu poți folosi comanda pe tine insuți. Folosește !block în chat.");
		return PLUGIN_HANDLED;
	}
	
	if ( BitGet(ForcedBlocked[TargetIndex1], TargetIndex2) || BitGet(ForcedBlocked[TargetIndex2], TargetIndex1) )
	{
		console_print(Index, "[The new allchat] Celor 2 le-a fost blocată deja intercomunicarea.");
		return PLUGIN_HANDLED;
	}
	
	BitSet(ForcedBlocked[TargetIndex1], TargetIndex2);
	BitSet(ForcedBlocked[TargetIndex2], TargetIndex1);
	
	get_user_name(TargetIndex1, TargetName1, charsmax(TargetName1));
	get_user_name(TargetIndex2, TargetName2, charsmax(TargetName2));
	
	new Clients[32], OnlinePlayers, AdminName[MAX_NAME_LENGTH], Level[35];
	get_players(Clients, OnlinePlayers, "ch");
	get_user_name(Index, AdminName, charsmax(AdminName));
	getLevel(Index, Level, charsmax(Level));
	
	for(new i = 0; i < OnlinePlayers; i++) 	
	{ 	 	
		if(is_user_admin(Clients[i])) 	 	
		{ 	 	 	
			client_print_color(Clients[i], print_team_red, "^4[Dr.FioriGinnal.Ro]^1(%s) ^3%s^1 : Interacțiunea chat-ului blocată între ^3%s^1 și ^3%s^1 pentru 3 minute.", Level, AdminName, TargetName1, TargetName2);		
		} 	 	
		else 	 	
		{ 	 	
			client_print_color(Clients[i], print_team_red, "^4[Dr.FioriGinnal.Ro]^1ADMIN : Interacțiunea chat-ului blocată între ^3%s^1 și ^3%s^1 pentru 3 minute.", TargetName1, TargetName2);
		} 	 	
	}
	
	new Ips[40], Len;
	Len = get_user_ip(TargetIndex1, Ips, charsmax(Ips), any:true);
	Ips[Len++] = ' ';
	Len += get_user_ip(TargetIndex2, Ips[Len], charsmax(Ips) - Len, any:true);
	set_task(3.0*60, "unblockChatInterraction", TargetIndex1*100+TargetIndex2, Ips, charsmax(Ips));
	
	return PLUGIN_HANDLED;
}

public unblockChatInterraction(Ips[], Indexes)
{
	new TargetIndex1, TargetIndex2 = Indexes % 100;
	Indexes /= 100;
	TargetIndex1 = Indexes;
	
	BitClear(ForcedBlocked[TargetIndex1], TargetIndex2);
	BitClear(ForcedBlocked[TargetIndex2], TargetIndex1);
	
	new Ip1[20], Ip2[20], bool:Found;
	parse(Ips, Ip1, charsmax(Ip1), Ip2, charsmax(Ip2));
	
	if( TrieKeyExists(BlockedData, Ip1))
	{
		new Data[BlockChatData];
		TrieGetArray(BlockedData, Ip1, Data, BlockChatData);
		Data[AdminTargetsBlock] =- BitGet(Data[AdminTargetsBlock], TargetIndex1);
		if (Data[AdminTargetsBlock] || Data[TargetsBlock])
		{
			TrieSetArray(BlockedData, Ip1, Data, BlockChatData);
		}
		else
		{
			TrieDeleteKey(BlockedData, Ip1);
		}
		Found = true;
	}
	
	if( TrieKeyExists(BlockedData, Ip2))
	{
		new Data[BlockChatData];
		TrieGetArray(BlockedData, Ip2, Data, BlockChatData);
		Data[AdminTargetsBlock] =- BitGet(Data[AdminTargetsBlock], TargetIndex2);
		if (Data[AdminTargetsBlock] || Data[TargetsBlock])
		{
			TrieSetArray(BlockedData, Ip2, Data, BlockChatData);
		}
		else
		{
			TrieDeleteKey(BlockedData, Ip2);
		}
		Found = true;
	}
	
	if (Found || !is_user_connected(TargetIndex1) || !is_user_connected(TargetIndex2))
	{
		return;
	}
	
	new IpTest[20];
	get_user_ip(TargetIndex1, IpTest, charsmax(IpTest), any:true);
	if (!equal(Ip1, IpTest))
	{
		return;
	}
	
	get_user_ip(TargetIndex2, IpTest, charsmax(IpTest), any:true);
	if (!equal(Ip2, IpTest))
	{
		return;
	}	
	
	new TargetName1[MAX_NAME_LENGTH], TargetName2[MAX_NAME_LENGTH];
	get_user_name(TargetIndex1, TargetName1, charsmax(TargetName1));
	get_user_name(TargetIndex2, TargetName2, charsmax(TargetName2));
	
	client_print_color(TargetIndex1, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Poți vedea din nou mesajele scrise de ^3%s^1.", TargetName2);
	client_print_color(TargetIndex2, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Poți vedea din nou mesajele scrise de ^3%s^1.", TargetName1);
}

public cmdSay(Index) 
{ 
	new Name[MAX_NAME_LENGTH], Message[192];

	read_args(Message, charsmax(Message));
	remove_quotes(Message);
	
	if ( !Message[0] )
	{
		return PLUGIN_HANDLED;
	}
	
	new const concursIdent[] = "!concurs", reloadAllchatIdent[] = "!reloadallchat", blockIdent[] = "!block", unblockIdent[] = "!unblock";
	
	get_user_name(Index, Name, charsmax(Name));
	
	if ( equal(Message, blockIdent, charsmax(blockIdent)) )
	{
		new Target[MAX_NAME_LENGTH], UseLess[2];
		read_argv(1, Target, charsmax(Target));
		split(Target, UseLess, charsmax(UseLess), Target, charsmax(Target), " ");
		new TargetIndex = cmd_target(Index, Target, 8);
		
		if ( !TargetIndex || TargetIndex == Index ) 
		{
			return PLUGIN_HANDLED;
		}
		
		new TargetName[MAX_NAME_LENGTH];
		if ( BitGet(Blocked[Index], TargetIndex) )
		{ 
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Mesajele lui %s sunt deja blocate.", TargetName);
		}
		else
		{
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 I-ai blocat mesajele lui %s din allchat.", TargetName);
			BitSet(Blocked[Index], TargetIndex);
			client_print_color(TargetIndex, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 %s ți-a blocat mesajele, acesta nu va mai vedea de acum ce vei scrie în chat.", Name);
		}
		
		return PLUGIN_HANDLED;
	}
	
	if ( equal(Message, unblockIdent, charsmax(unblockIdent)) )
	{
		new Target[MAX_NAME_LENGTH], UseLess[2];
		read_argv(1, Target, charsmax(Target));
		split(Target, UseLess, charsmax(UseLess), Target, charsmax(Target), " ");
		new TargetIndex = cmd_target(Index, Target, 8);
		
		if ( !TargetIndex || TargetIndex == Index ) 
		{
			return PLUGIN_HANDLED;
		}
		
		new TargetName[MAX_NAME_LENGTH];
		if ( BitGet(Blocked[Index], TargetIndex) )
		{ 
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Ai deblocat mesajele lui %s din allchat.", TargetName);
			BitClear(Blocked[Index], TargetIndex);
			client_print_color(TargetIndex, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 %s te-a deblocat, îi poți scrie din nou în chat.", Name);
			
			new Ip[20];
			get_user_ip(TargetIndex, Ip, charsmax(Ip), any:true);
			
			if( TrieKeyExists(BlockedData, Ip))
			{
				new Data[BlockChatData];
				TrieGetArray(BlockedData, Ip, Data, BlockChatData);
				Data[TargetsBlock] =- BitGet(Data[TargetsBlock], TargetIndex);
				if (Data[AdminTargetsBlock] || Data[TargetsBlock])
				{
					TrieSetArray(BlockedData, Ip, Data, BlockChatData);
				}
				else
				{
					TrieDeleteKey(BlockedData, Ip);
				}
			}
		}
		else
		{
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Meajele lui %s nu sunt blocate.", TargetName);
		}
		
		return PLUGIN_HANDLED;
	}
	
	if ( equal(Message, concursIdent, charsmax(concursIdent)) && get_user_flags(Index) & ADMIN_IMMUNITY )
	{
		if ( Competition )
		{
			Competition = false;
		}
		else
		{
			Competition = true;
		}
		return PLUGIN_HANDLED;
	}
	
	if ( equal(Message, reloadAllchatIdent, charsmax(reloadAllchatIdent)) && get_user_flags(Index) & ADMIN_IMMUNITY )
	{
		loadAllWords();
		client_print_color(Index, print_team_red, "^4[Dr.FioriGinnal.Ro]^1 Ai reincarcat cuvintele din allchat.");
		
		return PLUGIN_HANDLED;
	}

	replaceWords(Message, charsmax(Message));
	
	setTagAndPrint(Index, Message, Name, charsmax(Name));
	
	return PLUGIN_HANDLED;
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
	new CsTeams:IndexTeam = cs_get_user_team(Index), IndexFlags = get_user_flags(Index), ClanTag[15], NewName[47], State[5], Title[15], bool:Colored;
	if (getClanTag(Name, Len, ClanTag, charsmax(ClanTag)))
	{
		formatex(NewName, charsmax(NewName), "^4%s^3%s", ClanTag, Name);
	}
	else
	{
		copy(NewName, charsmax(NewName), Name);
	}
	
	if (IndexTeam == CS_TEAM_SPECTATOR)
	{
		copy(State, charsmax(State), "Spec");
	}
	else
	{
		if (is_user_alive(Index))
		{
			copy(State, charsmax(State), "Viu");
		}
		else
		{
			copy(State, charsmax(State), "Mort");
		}
	}
	
	
	if (Competition)
	{
		if (IndexFlags & ADMIN_IMMUNITY)
		{
			copy(Title, charsmax(Title), "Organizator");
			Colored = true;
		}
		else if (IndexFlags & ADMIN_KICK)
		{
			copy(Title, charsmax(Title), "Figurant");
			Colored = true;
		}
		else
		{
			copy(Title, charsmax(Title), "Concurent");
		}
	}
	else
	{	
		static TrialReviveIndex;
		if (TrialReviveIndex == 0)
		{
			TrialReviveIndex = get_xvar_id("TrialReviveIndex");
		}
		
		if (IndexFlags & ADMIN_LEVEL_H)
		{
			if (equal(Name, "Joker$*") || equal(Name, "-rTg|maEsTrOo"))
			{
				copy(Title, charsmax(Title),  "^4Profesionist^1");
			}
			else
			{
				copy(Title, charsmax(Title),  "Revive");
			}
			Colored = true;
		}
		else if (get_xvar_num(TrialReviveIndex) == Index)
		{			
			copy(Title, charsmax(Title),  "Trial-Revive");
			Colored = true;
		}
		else if (IndexFlags & ADMIN_RESERVATION)
		{
			copy(Title, charsmax(Title),  "Utilizator");
		}
		else
		{
			copy(Title, charsmax(Title),  "Jucător");
		}
	}
   
	printMessage(Index, "^1[%s ~ %s] ^3%s %c:%s", Title, State, NewName, Colored ? '^4' : '^1', Message);
}

printMessage(const Index, const StandardMessage[], any:...)
{
	new Players[MAX_PLAYERS], PlayersNum, Message[192];
	vformat(Message, charsmax(Message), StandardMessage, 3);
	get_players(Players, PlayersNum, "c");
	
	replaceTagNames(Message, charsmax(Message), contain(Message, ":") + 1, contain(Message[contain(Message, ":")-1], "^4") != -1);
	
	for(new i = 0; i < PlayersNum; ++i)
	{
		if (!BitGet(Blocked[Players[i]], Index) && !BitGet(ForcedBlocked[Players[i]], Index))
		{
			client_print_color(Players[i], Index, Message);
		}
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

replaceTagNames(Message[], Len, Pos, bool:Colored)
{
	new Char = Message[strlen(Message)-1];
	Message[strlen(Message)-1] = ' ';
	new TagReplacement[MAX_NAME_LENGTH], Name[MAX_NAME_LENGTH], Index;
	for (new i = Pos; i < Len; ++i)
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
	checkForDot(Message, Len);
	if (isalnum(Message[strlen(Message)-2]))
	{
		Message[strlen(Message)-1] = '.';
	}
}

checkForDot(Message[], Len)
{
	new Length = strlen(Message);
	for(new i = Length; i > 0; --i)
	{
		if (Message[i] == '.')
		{
			for(new j = i; j < Length; ++j)
			{
				if (isalnum(Message[j]) || Message[j] == '@')
				{
					ucfirst(Message[j])
					format(Message[i+1], Len, " %s", Message[j]);
					break;
				}
			}
		}
	}
}