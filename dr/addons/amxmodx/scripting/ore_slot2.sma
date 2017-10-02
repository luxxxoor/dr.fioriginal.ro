#include <amxmodx>
#include <amxmisc>
#include <nvault>

new Vault;
new TotalPlayedTime[MAX_PLAYERS+1], Requested[MAX_PLAYERS+1], PreviousTimePlayed[MAX_PLAYERS+1];

public plugin_init() 
{
	register_plugin("Ore Jucate", "1.0", "Dr.FioriGinal.Ro" );
	
	register_clcmd("pass", "Cmd_Pass");
	register_clcmd("say", "handle_say");
	
	Vault = nvault_open("OreJucate");
	
	if ( Vault == INVALID_HANDLE )
	{
		set_fail_state("nValut returned invalid handle");
	}
}

public plugin_end()
{
	nvault_close(Vault);
}

public Cmd_Pass( id )
{
	if ( Requested[id] )
	{
		new ConfigsDirectory[128]
		get_configsdir(ConfigsDirectory, charsmax(ConfigsDirectory))
		format(ConfigsDirectory, charsmax(ConfigsDirectory), "%s/lista_gag.ini", ConfigsDirectory)

		if ( !file_exists(ConfigsDirectory) )
		{
			return PLUGIN_HANDLED;
		}
		
		new Password[MAX_PLAYERS+1], LogData[200], Name[MAX_NAME_LENGTH];
		get_user_name(id, Name,charsmax(Name));
		read_argv(1, Password, charsmax(Password));
		
		if ( strlen(Password), containi(Password, "!slot") != -1 ) // strlen
		{
			client_print_color(0, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 Nu ai setat o parolă corectă. Fii mai atent data viitoare.");
			return PLUGIN_HANDLED;
		}
		
		set_user_info(id, "_pw", Password); 
		formatex(LogData, charsmax(LogData), "^n^"%s^" ^"%s^" ^"b^" ^"a^" ;Slot de la !slot", Name, Password);
		write_file(ConfigsDirectory, LogData);
		client_print(id, print_console, "------------------- |    ORE ~ SLOT    | -------------------")
		client_print(id, print_console, "[SLOT] Ai primit kick pentru ca pentru ca ai primit slot.")
		client_print(id, print_console, "[SLOT] Parola ta (setinfo _pw) este: %s", Password)
		client_print(id, print_console, "[SLOT] Ca sa poti intra pe server trebuie sa scri in consola: setinfo _pw %s", Password)
		client_print(id, print_console, "------------------- | DR.FIORIGINAL.RO | -------------------")
		server_cmd("kick #%d ^"Ai primit kick deoarece ti-ai activat slot pe nume, parola ta este %s, pentru mai multe informatii verifica consola^"", get_user_userid(id), Password)
		server_cmd("amx_reloadadmins");
		client_print_color(0, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s şi-a activat slot-ul ! Scrie şi tu^3 !slot^1 pentru a avea slot.", Name);
	}
	
	return PLUGIN_CONTINUE;
}

public handle_say(id) 
{
	new Said[6];
	read_argv(1, Said, charsmax(Said));
	
	if ( equali(Said, "!ore") )
	{
		new Name[MAX_NAME_LENGTH], Hours, Minutes;
		Hours = TotalPlayedTime[id] / 60 - PreviousTimePlayed[id] / 60 + get_user_time(id) / 3600;		
		Minutes = (TotalPlayedTime[id] % 60 - PreviousTimePlayed[id] % 60 + get_user_time(id) / 60) % 60;
		//server_print("%d - %d + %d = %d", TotalPlayedTime[id] % 60, PreviousTimePlayed[id] % 60, get_user_time(id) / 60, TotalPlayedTime[id] % 60 - PreviousTimePlayed[id] % 60 + get_user_time(id) / 60);
		
		get_user_name(id, Name,charsmax(Name));
		
		client_print_color(id, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s ai jucat^3 %d^1 or%s ( şi ^3%d^1 minut%s)  pe acest nume.",
																Name, Hours, Hours == 1 ? "ă" : "e", Minutes, Minutes == 1 ? "" :"e");
		return PLUGIN_HANDLED;
	}
	
	if ( equali(Said, "!slot") )
	{
		new Name[MAX_NAME_LENGTH], Hours;
		
		get_user_name(id, Name, charsmax(Name));
		Hours = TotalPlayedTime[id] / 60 - PreviousTimePlayed[id] / 60 + get_user_time(id) / 3600;
		
		if ( is_user_admin(id) )
		{
			client_print_color(id, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s ai deja numele rezervat.", Name);
			return PLUGIN_HANDLED;
		}
		
		if ( Hours < 10 )
		{
			client_print_color(id, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s ai jucat doar ^3 %d^1 or%s, pentru a primi^3 slot^1 ai nevoie de^3 10^1ore.",
																														Name, Hours, Hours == 1 ? "ă" : "e");
			return PLUGIN_HANDLED;
		}
		else
		{
			Requested[id] = true;
			client_cmd(id, "messagemode pass");
			client_print(id, print_center, "Alege o parolă, ai grijă să n-o uiți.");
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	new Name[MAX_NAME_LENGTH];
	get_user_name(id, Name, charsmax(Name));
	TotalPlayedTime[id] = TotalPlayedTime[id] + get_user_time(id) / 60  - PreviousTimePlayed[id];
	SaveTime(TotalPlayedTime[id], Name);
}

public client_putinserver(id)
{
	new Name[MAX_NAME_LENGTH];
	get_user_name(id, Name, charsmax(Name));
	TotalPlayedTime[id] = LoadTime(Name);
}

public client_infochanged(id)
{
	if ( !is_user_connected(id) )
	{
		return PLUGIN_CONTINUE;
	}
		
	new NewName[MAX_NAME_LENGTH], OldName[MAX_NAME_LENGTH];
	get_user_name(id, OldName, charsmax(OldName));
	get_user_info(id, "name", NewName, charsmax(NewName));
	
	if ( !equali(NewName, OldName) )
	{
		SaveTime(TotalPlayedTime[id] - PreviousTimePlayed[id] + get_user_time(id)/60, OldName);
		PreviousTimePlayed[id] = get_user_time(id)/60;
		//server_print("%d - %d = %d", get_user_time(id)/60, PreviousTimePlayed[id], get_user_time(id)/60 - PreviousTimePlayed[id]);
		TotalPlayedTime[id] = LoadTime(NewName);
	}
	
	return PLUGIN_CONTINUE;
}

public LoadTime(name[]) 
{
	new VaultKey[64], VaultData[32];
	
	formatex(VaultKey, charsmax(VaultKey), "TIMEPLAYED-%s", name);
	
	nvault_get(Vault, VaultKey, VaultData, charsmax(VaultData));
	
	//server_print("load - %s", VaultData);
	return  str_to_num(VaultData);
}

public SaveTime(PlayedTime, name[])
{	
	new VaultKey[64], VaultData[64];
	
	formatex(VaultKey, charsmax(VaultKey), "TIMEPLAYED-%s", name); 
	formatex(VaultData, charsmax(VaultData), "%d ", PlayedTime ); 
	
	//server_print("set - %s", VaultData);
	nvault_set(Vault, VaultKey, VaultData);	
} 