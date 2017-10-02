#include <amxmisc> 
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <engine>
#include <fakemeta>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

enum _:ChatCommandData
{
	Command[25],
	Link[180]
}

new Array:ChatCommands;

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "Comanzi Chat + Block HP > 100",
		.version     = "1.1",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_clcmd("say", "hookChat");
	register_message(get_user_msgid("Health"), "checkHealth");
	
	ChatCommands = ArrayCreate(ChatCommandData);
	registerChatCommands();
}

public checkHealth(MessageIndex, MessageDest, Index)
{
	if(!is_user_alive(Index))
	{
        return;
	}
    
	if(get_msg_arg_int(1) > 100)
	{
		set_user_health(Index, 100);
		set_msg_arg_int(1, ARG_BYTE, 100);
	}
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
	

	/*static HudTextPro;
	if (!HudTextPro)
	{
		HudTextPro = get_user_msgid("HudTextPro")
	}
	message_begin(MSG_ONE, HudTextPro, _, Index);
	write_string("#Hint_press_buy_to_purchase");
	write_short((1<<1));
	message_end();*/
	
	new const ReloadIdent[] = "!reloadadmins", WhoIdent[] = "!who", MoveTeroIdent[] = "!movetero", SpecIdent[] = "!spec", GodModeIdent[] = "!godmode", NoClipIdent[] = "!noclip", TeroIdent[] = "!tero", ReloadCommandsIdent[] = "!reloadchatcommands";
	
	if (Said[0] == '/')
	{
		client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Comenzile în chat se apelează prin caracterul : '!' nu prin '/'. De exemplu : ^4!^3comanda^1 !");
		return PLUGIN_HANDLED;
	}
	
	if (Said[0] != '!')
	{
		return PLUGIN_CONTINUE;
	}
	
	if (get_user_flags(Index) & ADMIN_IMMUNITY)
	{
		if (equali(Said, MoveTeroIdent, charsmax(MoveTeroIdent)))
		{
			if (cs_get_user_team(Index) == CS_TEAM_T)
			{
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Eşti deja la Tero.");
				return PLUGIN_HANDLED;
			}
			cs_set_user_team(Index, CS_TEAM_T);
			user_kill(Index, 1);
			ExecuteHamB(Ham_CS_RoundRespawn, Index);
			client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Te-ai mutat la Tero.");
			return PLUGIN_HANDLED;
		}
		
		if (equali(Said, TeroIdent, charsmax(TeroIdent)))
		{
			if (cs_get_user_team(Index) == CS_TEAM_T)
			{
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Eşti deja la Tero.");
				return PLUGIN_HANDLED;
			}
			
			new Players[MAX_PLAYERS], PlayersMatched;
			get_players(Players, PlayersMatched, "ace", "TERRORIST");
			if (PlayersMatched == 1)
			{
				cs_set_user_team(Index, CS_TEAM_T);
				ExecuteHamB(Ham_CS_RoundRespawn, Index);
				new name[MAX_NAME_LENGTH];
				get_user_name(Players[0], name, charsmax(name));
				cs_set_user_team(Players[0], CS_TEAM_CT);
				ExecuteHamB(Ham_CS_RoundRespawn, Players[0]);
				//set_pev(Index, pev_deadflag, )
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Ai facut switch teroristul %s.", name);
				return PLUGIN_HANDLED;
			}
			else
			{
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Nu poți să faci swtich la Tero deoarece sunt mai mulți terorişti sau nu este nici unul.");
				return PLUGIN_HANDLED;
			}
		}
		
		if (equali(Said, SpecIdent, charsmax(SpecIdent)))
		{
			
			cs_set_user_team(Index, CS_TEAM_SPECTATOR);
			user_kill(Index, any:true);
			client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Te-ai mutat la Spec.");
			
			return PLUGIN_HANDLED;
		}
		
		if (equali(Said, GodModeIdent, charsmax(GodModeIdent)))
		{
			if (get_user_godmode(Index) == any:true)
			{
				set_user_godmode(Index, any:false);
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Ai dezactivat opţiunea godmode.");
			}
			else
			{
				set_user_godmode(Index, any:true);
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Ai activat opţiunea godmode.");
			}
			return PLUGIN_HANDLED;
		}
		
		if (equali(Said, NoClipIdent, charsmax(NoClipIdent)))
		{
			if (get_user_noclip(Index) == any:true)
			{
				set_user_noclip(Index, any:false);
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Ai dezactivat opţiunea noclip.");
			}
			else
			{
				set_user_noclip(Index, any:true);
				client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Ai activat opţiunea noclip.");
			}
			return PLUGIN_HANDLED;
		}
		
		if (equali(Said, ReloadCommandsIdent, charsmax(ReloadCommandsIdent)))
		{
			registerChatCommands();
			return PLUGIN_HANDLED;
		}
	}
	
	if (equali(Said, WhoIdent, charsmax(WhoIdent)))
	{
		client_print_color(Index, print_team_red, "^4[Dr.FioriGinal.Ro]^1 Pe acest server adminii nu trebuie să fie văzuţi de către jucatorii. Totuşi îi poţi vedea activându-ţi slot-ul prin comanda ^3!slot^1.");
		return PLUGIN_HANDLED;
	}
	
	if (equali(Said, ReloadIdent, charsmax(ReloadIdent)))
	{
		client_print_color(Index, print_team_blue, "^4[Dr.FioriGinal.Ro] ^3Ai reîncărcat adminele.");
		server_cmd("amx_reloadadmins");
		return PLUGIN_HANDLED;
	}

	new Size = ArraySize(ChatCommands), Data[ChatCommandData];
	for(new i = 0; i < Size; ++i)
	{
		ArrayGetArray(ChatCommands, i, Data);
		if (equali(Said, Data[Command], strlen(Data[Command])))
		{
			show_motd(Index, Data[Link], "Dr.FioriGinal.Ro");
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}


registerChatCommands()
{
	new Path[64];
	
	get_localinfo("amxx_configsdir", Path, charsmax(Path));
	add(Path, charsmax(Path), "/chatcommands.ini")
	
	if (!file_exists(Path))
	{
		new FilePointer = fopen(Path, "wt");
		
		if ( !FilePointer ) 
		{
			return;
		}
		
		fputs(FilePointer, "; Aici vor fi inregistrate comenzile din chat care deschid motd-uri.^n");
		fputs(FilePointer, "; Exemplu de adaugare comanda chat : ^"!comanda^" ^"link motd^"^n^n^n");
		fclose(FilePointer);
	}
	else
	{
		new Text[121], ChatCommand[25], Site[180];
		new FilePointer = fopen(Path, "rt");
		
		if ( !FilePointer ) 
		{
			return;
		}
		
		ArrayClear(ChatCommands);
		
		new Data[ChatCommandData];
		while (!feof(FilePointer))
		{
			fgets(FilePointer, Text, charsmax(Text));

			trim(Text);
		
			if ( (Text[0] == ';') || !strlen(Text) || ((Text[0] == '/') && (Text[1] == '/')) )
			{
				continue;
			}
		
			if (parse(Text, ChatCommand, charsmax(ChatCommand), Site, charsmax(Site)) != 2)
			{
				continue;
			}
			
			copy(Data[Command], charsmax(Data[Command]), ChatCommand);
			copy(Data[Link], charsmax(Data[Link]), Site);
			ArrayPushArray(ChatCommands, Data);
		}
		
		fclose(FilePointer);
	}
}
