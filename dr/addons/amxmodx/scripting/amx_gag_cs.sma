#include <amxmisc>

#define BitSet(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define BitClear(%1,%2) (%1 &= ~(1 << (%2 & 31))) 
#define BitGet(%1,%2)   (%1 & (1 << (%2 & 31)))

new const PluginName[]    = "The new gag",
		  PluginVersion[] = "1.0 - non-save",
		  PluginAuthor[]  = "Cs.FioriGinal.Ro";

new Gaged;
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
	
	register_concmd("amx_gag", "gagCommand", _, "amx_gag [u@] <name>");
	register_clcmd("say", "hookChat");
	register_clcmd("say_team", "hookChat");
}

public plugin_end()
{
	TrieDestroy(GagInfo);
}

public client_putinserver(id)
{
	new SteamID[20];
	get_user_authid(id, SteamID, charsmax(SteamID));
	
	if ( TrieKeyExists(GagInfo, SteamID) )
	{
		new Data[GagData];
		TrieGetArray(GagInfo, SteamID, Data, GagData);
		new TimeLeft = get_timeleft() - Data[EndTime];
		if ( TimeLeft != 0)
		{
			if ( TimeLeft > 0 )
			{
				BitSet(Gaged, id);

				set_task(float(TimeLeft), "unGagTarget", id);
			}
		}
	}
}

public client_disconnected(id)
{
	if (BitGet(Gaged, id))
	{
		BitClear(Gaged, id);
		remove_task(id);
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
			return PLUGIN_CONTINUE;
		}
		if ( !Data[AdminChat] )
		{
			new Chat[10];
			read_argv(0, Chat, charsmax(Chat));
			if ( equal(Chat, "say_team") )
			{
				read_argv(1, Chat, charsmax(Chat));
				if ( Chat[0] == '@' )	
				{
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
		client_print_color(id, print_team_grey,  "^1[^3%s^1] Server :^4 %s^3, gag-ul tãu va expira în %s.", PluginAuthor, Name, GagTime); 
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public gagCommand(id)
{
	new idFlags = get_user_flags(id);
	if ( !(idFlags & (ADMIN_KICK | ADMIN_LEVEL_H)) )
	{
		console_print(id, "[%s] Nu ai acces pentru a folosi aceastã comandã.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	
	new name[MAX_NAME_LENGTH];
	get_user_name(id, name, charsmax(name));
	
	if ( equali(name, "KiddinG?") )
	{
		console_print(id, "[%s] Nu ai acces pentru a folosi aceastã comandã.", PluginAuthor);
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
		console_print(id, "[%s] Jucãtorul nu a fost gãsit. Verificã dacã ai scris numele corect sau dacã acesta se aflã pe server.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	
	new TargetFlags = get_user_flags(Target);
	
	if ( TargetFlags & ADMIN_KICK )
	{
		console_print(id, "[%s] Nu poþi sã dai gag unui admin.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	if ( TargetFlags & ADMIN_LEVEL_H && idFlags & ADMIN_LEVEL_H && !(idFlags & ADMIN_KICK) )
	{
		console_print(id, "[%s] Nu poþi sã dai gag altui revive.", PluginAuthor);
		return PLUGIN_HANDLED;
	}
	if ( BitGet(Gaged, Target) )
	{		
		if ( !GagOnAdminChat)
		{
			console_print(id, "[%s] Nu poþi sã dai gag unui jucãtor care are gag.", PluginAuthor);
			return PLUGIN_HANDLED;
		}
	}
	else
	{
		if ( GagOnAdminChat )
		{
			console_print(id, "[%s] Nu poþi sã dai gag la admin chat, daca jucatorul nu are gag la chat.", PluginAuthor);
			return PLUGIN_HANDLED;
		}
	}
	
	new TargetName[MAX_NAME_LENGTH], idName[MAX_NAME_LENGTH], TimeLeft = get_timeleft() ;
	get_user_name(Target, TargetName, charsmax(TargetName));
	get_user_name(id, idName, charsmax(idName));
	
	new SteamID[20], Data[GagData];
	get_user_authid(Target, SteamID, charsmax(SteamID));
	if( TrieKeyExists(GagInfo, SteamID) )
	{
		TrieGetArray(GagInfo, SteamID, Data, GagData);
	}
	
	if ( GagOnAdminChat )
	{
		if ( Data[AdminChat] )
		{
			console_print(id, "[%s] Nu poþi sã dai gag la admin chat unui jucãtor care are deja gag la admin chat.", PluginAuthor);
			return PLUGIN_HANDLED;
		}
		
		if ( TimeLeft - Data[EndTime] > 0 )
		{ 
			Data[AdminChat] = true;
			TrieSetArray(GagInfo, SteamID, Data, GagData);
			
			console_print(id, "[%s] %s a primit gag la admin chat.", PluginAuthor, TargetName);
			
			if ( is_user_admin(Target) )
			{
				client_print_color(Target, print_team_grey,  "^1[^3%s^1] (%s) %s :^4 %s^3 gag-ul ?i-a fost extins ?i pentru admin chat.", PluginAuthor, Admin_Rank(id), idName, TargetName); 
			}
			else
			{
				client_print_color(Target, print_team_grey,  "^1[^3%s^1] ADMIN :^4 %s^3 gag-ul ?i-a fost extins ?i pentru admin chat.", PluginAuthor, TargetName); 
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	new Seconds;
	
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
	
	client_print_color(0, print_team_grey,  "^1[^3%s^1] %s :^4 %s^3 a primit gag la chat pentru %d minute.", PluginAuthor, idName, TargetName, Seconds/60); 
	
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
	
	client_print_color(Target, print_team_grey,  "^1[^3%s^1] Server :^4 %s^3, gag-ul tãu a expirat. Grijã data viitoare, deoarece timpul gag-ului va cre?te.", PluginAuthor, TargetName); 
}