#include <amxmisc>
#include <nvault>

#define BitSet(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define BitClear(%1,%2) (%1 &= ~(1 << (%2 & 31))) 
#define BitGet(%1,%2)   (%1 & (1 << (%2 & 31)))

new const PluginName[]    = "The new gag",
		  PluginVersion[] = "1.0 - beta 6",
		  PluginAuthor[]  = "Dr.FioriGinal.Ro";

new Gaged, nVaultPointer;
new Trie:GagInfo;

enum _:GagData
{
	EndTime,
	GagTimes,
	bool:AdminChat
};

public plugin_init()
{
	register_plugin
	(
		.plugin_name = PluginName,
		.version     = PluginVersion,
		.author      = PluginAuthor
	);
	
	GagInfo = TrieCreate();
	nVaultPointer = nvault_open("testvault");

	if ( nVaultPointer == INVALID_HANDLE )
	{
		set_fail_state("Error opening nVault");  
	}
	
	register_concmd("amx_gag", "gagCommand", _, "amx_gag [u@] <name>");
	register_clcmd("say", "hookChat");
	register_clcmd("say_team", "hookChat");
}

public plugin_end()
{
	TrieDestroy(GagInfo);
	nvault_close(nVaultPointer);
}

public client_putinserver(id)
{
	new SteamID[20];
	get_user_authid(id, SteamID, charsmax(SteamID));
	
	ReCheck:
	//server_print("intra pe sv");
	if ( TrieKeyExists(GagInfo, SteamID) )
	{
		//server_print("este in trie");
		new Data[GagData];
		TrieGetArray(GagInfo, SteamID, Data, GagData);
		new TimeLeft = get_timeleft() - Data[EndTime];
		if ( TimeLeft != 0)
		{
			if ( TimeLeft > 0 )
			{
				//server_print("primeste gag");
				BitSet(Gaged, id);

				set_task(float(TimeLeft), "unGagTarget", id);
			}
			else
			{
				BitSet(Gaged, id);
			}
		}
	}
	else
	{
		if ( loadData(SteamID) )
		{
			//server_print("true");
			goto ReCheck;
		}
		
	}
}

public client_disconnected(id)
{
	if (BitGet(Gaged, id))
	{
		BitClear(Gaged, id);
		remove_task(id);
		
		new SteamID[35], Data[GagData];
		get_user_authid(id, SteamID, charsmax(SteamID));
		TrieGetArray(GagInfo, SteamID, Data, GagData)
		saveData(Data, SteamID, true);
	}
}

public hookChat(id)
{
	if ( BitGet(Gaged, id) )
	{
		new Data[GagData], Name[MAX_NAME_LENGTH], SteamID[20];
		get_user_authid(id, SteamID, charsmax(SteamID));
		TrieGetArray(GagInfo, SteamID, Data, GagData);
		get_user_name(id, Name, charsmax(Name));
		new TimeLeft = get_timeleft() - Data[EndTime];
		if ( TimeLeft <= 0 )
		{
			BitClear(Gaged, id);
			saveData(Data, SteamID, false);
			return PLUGIN_CONTINUE;
		}
		if ( !Data[AdminChat] )
		{
			//server_print("nu are gag pe U@");
			new Chat[10];
			read_argv(0, Chat, charsmax(Chat));
			if ( equal(Chat, "say_team") )
			{
				//server_print("scrie cu pe say_team");
				read_argv(1, Chat, charsmax(Chat));
				if ( Chat[0] == '@' )	
				{
					//server_print("scrie in u@");
					return PLUGIN_CONTINUE;
				}
			}
		}
		new GagTime[12];
		if ( TimeLeft/60 + 1 == 1 )
		{
			formatex(GagTime, charsmax(GagTime), "%d secunde", TimeLeft);
		}
		else
		{
			formatex(GagTime, charsmax(GagTime), "%d minute", TimeLeft/60 + 1);
		}
		client_print_color(id, print_team_grey,  "^1[^3%s^1] SERVER :^4 %s^3, gag-ul tău va expira în %s.", PluginAuthor, Name, GagTime); 
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public gagCommand(id)
{
	new idFlags = get_user_flags(id);
	if ( !(idFlags & (ADMIN_KICK | ADMIN_LEVEL_H)) )
	{
		console_print(id, "[%s] Nu ai acces pentru a folosi această comandă.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	
	new Argument[MAX_NAME_LENGTH], bool:GagOnAdminChat;
	read_argv(1, Argument, charsmax(Argument));
	
	if ( Argument[0] == 'u' && Argument[1] == '@' )
	{
		GagOnAdminChat = true;
		read_argv(2, Argument, charsmax(Argument));
	}
	
	new Target = cmd_target(id, Argument,  id != 0 ? (CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS) : CMDTARGET_NO_BOTS);
	
	if ( !Target )
	{
		console_print(id, "[%s] Jucătorul nu a fost găsit. Verifică dacă ai scris numele corect sau dacă acesta se află pe server.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	
	new TargetFlags = get_user_flags(Target);
	
	if ( TargetFlags & ADMIN_KICK )
	{
		console_print(id, "[%s] Nu poţi să dai gag unui admin.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	if ( TargetFlags & ADMIN_LEVEL_H && idFlags & ADMIN_LEVEL_H && !(idFlags & ADMIN_KICK) )
	{
		console_print(id, "[%s] Nu poţi să dai gag altui revive.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	if ( BitGet(Gaged, Target) )
	{		
		if ( !GagOnAdminChat)
		{
			console_print(id, "[%s] Nu poţi să dai gag unui jucător care are gag.", PluginAuthor);
			return PLUGIN_HANDLED;
		}
	}
	else
	{
		if ( GagOnAdminChat )
		{
			console_print(id, "[%s] Nu poţi să dai gag la admin chat, daca jucatorul nu are gag la chat.", PluginAuthor);
			return PLUGIN_HANDLED;
		}
	}
	
	new TargetName[MAX_NAME_LENGTH], idName[MAX_NAME_LENGTH], TimeLeft = get_timeleft() ;
	get_user_name(Target, TargetName, charsmax(TargetName));
	get_user_name(id, idName, charsmax(idName));
	
	new SteamID[20], Data[GagData];
	//server_print("debug 1 : %d %d %d", Data[EndTime], Data[GagTimes], _:Data[AdminChat]);
	get_user_authid(Target, SteamID, charsmax(SteamID));
	if( TrieKeyExists(GagInfo, SteamID) )
	{
		TrieGetArray(GagInfo, SteamID, Data, GagData);
	}
	
	if ( GagOnAdminChat )
	{
		if ( Data[AdminChat] )
		{
			console_print(id, "[%s] Nu poţi să dai gag la admin chat unui jucător care are deja gag la admin chat.", PluginAuthor);
			return PLUGIN_HANDLED;
		}
		
		if ( TimeLeft - Data[EndTime] > 0 )
		{ 
			Data[AdminChat] = true;
			TrieSetArray(GagInfo, SteamID, Data, GagData);
			
			console_print(id, "[%s] %s a primit gag la admin chat.", PluginAuthor, TargetName);
			
			if ( is_user_admin(Target) )
			{
				client_print_color(Target, print_team_grey,  "^1[^3%s^1] (%s) %s :^4 %s^3 gag-ul ți-a fost extins și pentru admin chat.", PluginAuthor, Admin_Rank(id), idName, TargetName); 
			}
			else
			{
				client_print_color(Target, print_team_grey,  "^1[^3%s^1] ADMIN :^4 %s^3 gag-ul ți-a fost extins și pentru admin chat.", PluginAuthor, TargetName); 
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	new Players[MAX_PLAYERS], Clients, Seconds;
	get_players(Players, Clients, "ch");
	
	//server_print("debug 2 : %d %d %d", Data[EndTime], Data[GagTimes], _:Data[AdminChat]);
	
	switch(Data[GagTimes])
	{
		case 0:
		{
			Seconds = 3*60;
		}
		case 1..2:
		{
			Seconds = 5*60;
		}
		case 3..5:
		{
			Seconds = 10*60;
		}
	}
	
	console_print(id, "[%s] %s a primit gag %d minute.", PluginAuthor, TargetName, Seconds/60);
	
	for (new i = 0; i < Clients; ++i)
	{	
		if ( is_user_admin(Players[i]) )
		{
			client_print_color(Players[i], print_team_grey,  "^1[^3%s^1] (%s) %s :^4 %s^3 a primit gag la chat pentru %d minute.", PluginAuthor, Admin_Rank(id), idName, TargetName, Seconds/60); 
		}
		else
		{
			client_print_color(Players[i], print_team_grey,  "^1[^3%s^1] ADMIN :^4 %s^3 a primit gag la chat pentru %d minute.", PluginAuthor, TargetName, Seconds/60); 
		}
	}
	
	BitSet(Gaged, Target);

	Data[EndTime] = TimeLeft - Seconds;
	if ( Data[GagTimes] < 4 )
	{
		Data[GagTimes] += 2;
	}
	get_user_authid(Target, SteamID, charsmax(SteamID));
	TrieSetArray(GagInfo, SteamID, Data, GagData);
	
	set_task(float(Seconds), "unGagTarget", Target);
	
	return PLUGIN_HANDLED;
}

public unGagTarget(Target)
{
	if( !is_user_connected(Target) )
	{
		return;
	}
	
	BitClear(Gaged, Target);
	
	new SteamID[20], TargetName[MAX_NAME_LENGTH], Data[GagData];
	get_user_name(Target, TargetName, charsmax(TargetName));
	get_user_authid(Target, SteamID, charsmax(SteamID));
	TrieGetArray(GagInfo, SteamID, Data, GagData);
	Data[AdminChat] = false;
	TrieSetArray(GagInfo, SteamID, Data, GagData);
	saveData(Data, SteamID, false);
	
	client_print_color(Target, print_team_grey,  "^1[^3%s^1] SERVER :^4 %s^3, gag-ul tău a expirat. Grijă data viitoare, deoarece timpul gag-ului va crește.", PluginAuthor, TargetName); 
}

loadData(SteamID[])
{
	new Data[12], nVaultData[3][5], Info[GagData], TimeLeft = get_timeleft();
	nvault_get(nVaultPointer, SteamID, Data, charsmax(Data));

	parse(Data, nVaultData[0], charsmax(nVaultData[]), nVaultData[1], charsmax(nVaultData[]), nVaultData[2], charsmax(nVaultData[]));
	Info[EndTime] = TimeLeft - str_to_num(nVaultData[0]);
	Info[GagTimes] = str_to_num(nVaultData[1]);
	Info[AdminChat] = bool:str_to_num(nVaultData[2]);
	
	//server_print("debug intrare : %d %d %d", Info[EndTime], Info[GagTimes], _:Info[AdminChat]);
	
	if ( !TrieKeyExists(GagInfo, SteamID) && Info[GagTimes] > 0 )
	{
		--Info[GagTimes];
	}
	TrieSetArray(GagInfo, SteamID, Info, GagData);
	
	if ( Info[EndTime] > 0 )
	{
		return true;
	}
	
	return false;
}

saveData(any:Data[], SteamID[], bool:IsGaged)
{
	new nVaultData[12], GagTime, TimeLeft = get_timeleft();
	if ( IsGaged )
	{
		if ( Data[EndTime] < 0 )
		{
			GagTime = -Data[EndTime];
		}
		if ( TimeLeft - Data[EndTime] > 0 )	
		{
			GagTime = TimeLeft - Data[EndTime];
			//server_print("debug 1.2 : are timp destul %d", GagTime);
		}
		else
		{
			GagTime = Data[EndTime] - TimeLeft;
			//server_print("debug 1.1 : nu are timp destul %d - %d = %d", Data[EndTime], TimeLeft, GagTime);
		}
	}
	//server_print("%d", IsGaged ? GagTime : 0);
	formatex(nVaultData, charsmax(nVaultData), "%d %d %d", IsGaged ? GagTime : 0, Data[GagTimes], _:Data[AdminChat]);
	
	nvault_set(nVaultPointer, SteamID, nVaultData);
}