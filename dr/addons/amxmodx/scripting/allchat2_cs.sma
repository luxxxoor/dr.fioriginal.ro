#include <amxmisc>
#include <cstrike>

#define BitSet(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define BitClear(%1,%2) (%1 &= ~(1 << (%2 & 31))) 
#define BitGet(%1,%2)   (%1 & (1 << (%2 & 31)))

enum _:BlockChatData
{
	TargetsBlock,
	AdminTargetsBlock
}

new Trie:ReplaceTrie, Trie:BlockedData, Blocked[MAX_PLAYERS+1], ForcedBlocked[MAX_PLAYERS+1];
public AllChatOnConsoleLog = 1;

public plugin_init() 
{

	register_plugin
	(
		.plugin_name = "The new allchat",
		.version     = "2.6",
		.author      = "Cs.FioriGinal.Ro"
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
	
	new TargetName1[MAX_NAME_LENGTH], TargetName2[MAX_NAME_LENGTH], AdminName[MAX_NAME_LENGTH];
	read_argv(1, TargetName1, charsmax(TargetName1));
	new TargetIndex1 = cmd_target(Index, TargetName1, CMDTARGET_NO_BOTS);
	if (!TargetIndex1)
	{
		return PLUGIN_HANDLED;
	}
	read_argv(2, TargetName2, charsmax(TargetName2));
	new TargetIndex2 = cmd_target(Index, TargetName2, CMDTARGET_NO_BOTS);
	if (!TargetIndex2 || TargetIndex1 == TargetIndex2)
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
		console_print(Index, "[The new allchat] Nu poți folosi comanda pe tine insuți. Folosește /block în chat.");
		return PLUGIN_HANDLED;
	}
	
	if (BitGet(ForcedBlocked[TargetIndex1], TargetIndex2) || BitGet(ForcedBlocked[TargetIndex2], TargetIndex1))
	{
		console_print(Index, "[The new allchat] Celor 2 le-a fost blocată deja intercomunicarea.");
		return PLUGIN_HANDLED;
	}
	
	BitSet(ForcedBlocked[TargetIndex1], TargetIndex2);
	BitSet(ForcedBlocked[TargetIndex2], TargetIndex1);
	
	get_user_name(TargetIndex1, TargetName1, charsmax(TargetName1));
	get_user_name(TargetIndex2, TargetName2, charsmax(TargetName2));
	get_user_name(Index, AdminName, charsmax(AdminName));

	client_print_color(0, print_team_red, "^4[Cs.FioriGinnal.Ro]^1ADMIN ^3%s^1 : Interacțiunea chat-ului blocată între ^3%s^1 și ^3%s^1 pentru 3 minute.", AdminName, TargetName1, TargetName2);			
	
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
	
	if (TrieKeyExists(BlockedData, Ip1))
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
	
	if (TrieKeyExists(BlockedData, Ip2))
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
	
	client_print_color(TargetIndex1, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 Poți vedea din nou mesajele scrise de ^3%s^1.", TargetName2);
	client_print_color(TargetIndex2, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 Poți vedea din nou mesajele scrise de ^3%s^1.", TargetName1);
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
	
	new const reloadAllchatIdent[] = "/reloadallchat", blockIdent[] = "/block", unblockIdent[] = "/unblock";
	
	get_user_name(Index, Name, charsmax(Name));
	
	if (equal(Message, blockIdent, charsmax(blockIdent)))
	{
		new Target[MAX_NAME_LENGTH], UseLess[2];
		read_argv(1, Target, charsmax(Target));
		split(Target, UseLess, charsmax(UseLess), Target, charsmax(Target), " ");
		new TargetIndex = cmd_target(Index, Target, 8);
		
		if (!TargetIndex || TargetIndex == Index) 
		{
			return PLUGIN_HANDLED;
		}
		
		new TargetName[MAX_NAME_LENGTH];
		if (BitGet(Blocked[Index], TargetIndex))
		{ 
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 Mesajele lui %s sunt deja blocate.", TargetName);
		}
		else
		{
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 I-ai blocat mesajele lui %s din allchat.", TargetName);
			BitSet(Blocked[Index], TargetIndex);
			client_print_color(TargetIndex, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 %s ți-a blocat mesajele, acesta nu va mai vedea de acum ce vei scrie în chat.", Name);
		}
		
		return PLUGIN_HANDLED;
	}
	
	if (equal(Message, unblockIdent, charsmax(unblockIdent)))
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
		if (BitGet(Blocked[Index], TargetIndex))
		{ 
			get_user_name(TargetIndex, TargetName, charsmax(TargetName));
			client_print_color(Index, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 Ai deblocat mesajele lui %s din allchat.", TargetName);
			BitClear(Blocked[Index], TargetIndex);
			client_print_color(TargetIndex, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 %s te-a deblocat, îi poți scrie din nou în chat.", Name);
			
			new Ip[20];
			get_user_ip(TargetIndex, Ip, charsmax(Ip), any:true);
			
			if (TrieKeyExists(BlockedData, Ip))
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
			client_print_color(Index, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 Meajele lui %s nu sunt blocate.", TargetName);
		}
		
		return PLUGIN_HANDLED;
	}
	
	if (equal(Message, reloadAllchatIdent, charsmax(reloadAllchatIdent)) && get_user_flags(Index) & ADMIN_IMMUNITY)
	{
		loadAllWords();
		client_print_color(Index, print_team_red, "^4[Cs.FioriGinnal.Ro]^1 Ai reincarcat cuvintele din allchat.");
		
		return PLUGIN_HANDLED;
	}
	
	replaceWords(Message, charsmax(Message));
	
	new CsTeams:IndexTeam = cs_get_user_team(Index);
	new bool:SayTeam, SayMethod[10];
	read_argv(0, SayMethod, charsmax(SayMethod));
	
	if (equal(SayMethod, "say_team"))
	{
		SayTeam = true;
	}
	
	new Team[30], bool:IsDead = !is_user_alive(Index);
	if (SayTeam)
	{
		switch(IndexTeam)
		{
			case CS_TEAM_T :
			{
				if (IsDead)
				{
					copy(Team, charsmax(Team), "*DEAD*(Terrorist)");
				}
				else
				{
					copy(Team, charsmax(Team), "(Terrorist)");
				}
			}
			case CS_TEAM_CT : 
			{
				if (IsDead)
				{
					copy(Team, charsmax(Team), "*DEAD*(Counter-Terrorist)");
				}
				else
				{
					copy(Team, charsmax(Team), "(Counter-Terrorist)");
				}
			}
			default :
			{
				copy(Team, charsmax(Team), "(Spectator)");
			}
		}
	}
   
	if (IndexTeam == CS_TEAM_SPECTATOR || IndexTeam == CS_TEAM_UNASSIGNED)
	{
		if (SayTeam)
		{
			printMessage(SayTeam, Index, IndexTeam, "^1%s ^3%s ^1: %s", Team, Name, Message);
		}
		else
		{
			printMessage(SayTeam, Index, IndexTeam, "^1*SPEC* ^3%s ^1: %s", Name, Message);
		}
	
		return PLUGIN_HANDLED;
	}
	else
	{
		if (SayTeam)
		{
			printMessage(SayTeam, Index, IndexTeam, "^1%s ^3%s ^1: %s", Team, Name, Message);
		}
		else
		{
			if (IsDead)
			{
				printMessage(SayTeam, Index, IndexTeam, "^1*DEAD* ^3%s ^1: %s", Name, Message);
			}
			else
			{
				printMessage(SayTeam, Index, IndexTeam, "^3%s ^1: %s", Name, Message);
			}
		}
		
		return PLUGIN_HANDLED;
	}
}

public loadAllWords()
{
	TrieClear(ReplaceTrie);
	new Path[64];
	get_localinfo("amxx_configsdir", Path, charsmax(Path));
	format(Path, charsmax(Path), "%s/%s", Path, "allchat-replacement.ini");
	
	new FilePointer = fopen(Path, "r+");
	
	if (!FilePointer)
	{
		return;
	}

	new Text[121], ForReplaceWord[64], ReplacedWord[64];

	for (new i; !feof(FilePointer); ++i)
	{
		fgets(FilePointer, Text, charsmax(Text));
		
		trim(Text);
		
		if ( !(Text[0] == '"') || !strlen(Text) )
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

printMessage(bool:SayTeam, Index, CsTeams:IndexTeam, const StandardMessage[], any:...)
{
	new Players[MAX_PLAYERS], PlayersNum, Message[192];
	vformat(Message, charsmax(Message), StandardMessage, 5);
	if(SayTeam)
	{
		switch(IndexTeam)
		{
			case CS_TEAM_T :
			{
				get_players(Players, PlayersNum, "ce", "TERRORIST");
			}
			case CS_TEAM_CT : 
			{
				get_players(Players, PlayersNum, "ce", "CT");
			}
			default :
			{
				get_players(Players, PlayersNum, "ce", "SPECTATOR");
			}
		}
	}
	else
	{
		get_players(Players, PlayersNum, "c");
	}

	for(new i = 0; i < PlayersNum; ++i)
	{
		if ( !BitGet(Blocked[Players[i]], Index) && !BitGet(ForcedBlocked[Players[i]], Index) )
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

replaceWords(Message[], Len)
{
	new String[192], ForReplaceWord[64], ReplacedWord[64];
	
	replace_string(Message, Len, "%", "");
	replace_string(Message, Len, "", "");
	replace_string(Message, Len, "", "");
	replace_string(Message, Len, "", "");
	
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
				if (isalnum(Message[j]))
				{
					ucfirst(Message[j])
					format(Message[i+1], Len, " %s", Message[j]);
					break;
				}
			}
		}
	}
}