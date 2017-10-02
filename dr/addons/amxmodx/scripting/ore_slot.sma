#include <amxmodx>
#include <amxmisc>
#include <nvault> 
#include <fakemeta>

new TotalPlayedTime[MAX_PLAYERS + 1], contor[MAX_PLAYERS + 1], scadere[MAX_PLAYERS + 1], nana[MAX_PLAYERS + 1], timep;
new vault;

public plugin_init() 
{
	register_plugin("Played Time", "1.3", "Alka" );
	
	register_clcmd( "pass", "Cmd_Pass" );
	register_clcmd("say", "handle_say");
	register_forward(FM_ClientUserInfoChanged, "ClientUserInfoChanged");
	
	vault = nvault_open("Time_played");
}

public plugin_end()
{
	nvault_close(vault);
}

public Cmd_Pass(id)
{
	if ( nana[id] )
	{
		new configsDir[64]
		get_configsdir(configsDir, charsmax(configsDir))
		format(configsDir, charsmax(configsDir), "%s/lista_gag.ini", configsDir)

		if (!file_exists(configsDir))
			return PLUGIN_HANDLED;
		new pass[33], szLogData[200], name[32];
		get_user_name(id, name,charsmax(name));
		read_argv(1, pass, charsmax(pass));
		if ( strlen(pass) && containi(pass, "!slot") != -1 )
		{
			client_print_color(0, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 Nu ai setat o parolă corectă. Fii mai atent data viitoare.");
			return PLUGIN_HANDLED;
		}
		set_user_info(id, "_pw", pass); 
		formatex(szLogData, charsmax(szLogData), "^n^"%s^" ^"%s^" ^"b^" ^"a^" ;Slot de la !slot", name, pass);
		write_file(configsDir, szLogData);
		client_print(id, print_console, "------------------- |    ORE ~ SLOT    | -------------------")
		client_print(id, print_console, "[SLOT] Ai primit kick pentru ca pentru ca ai primit slot.")
		client_print(id, print_console, "[SLOT] Parola ta (setinfo _pw) este: %s", pass)
		client_print(id, print_console, "[SLOT] Ca sa poti intra pe server trebuie sa scri in consola: setinfo _pw %s", pass)
		client_print(id, print_console, "------------------- | DR.FIORIGINAL.RO | -------------------")
		server_cmd("kick #%d ^"Ai primit kick deoarece ti-ai activat slot pe nume, parola ta este %s, pentru mai multe informatii verifica consola^"", get_user_userid(id), pass)
		server_cmd("amx_reloadadmins");
		client_print_color(0, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s şi-a activat slot-ul ! Scrie şi tu^3 !slot^1 pentru a avea slot.", name);
	}
	return PLUGIN_CONTINUE;
}

public handle_say(id) 
	{
	static said[9]
	read_argv(1, said, 8);
	
	if(equali(said, "!ore"))
	{
		static ctime[64], name[32], prea_lung, prea_scurt;
		
		get_user_name( id, name,charsmax( name ) );
		timep = get_user_time(id, 1) / 60;
		get_time("%H:%M:%S", ctime, 63);
		prea_lung = (timep+TotalPlayedTime[id]-scadere[id]) / 60;
		prea_scurt = timep+TotalPlayedTime[id]-scadere[id];
		while( prea_scurt >= 60 )
			prea_scurt = prea_scurt - 60;
		client_print_color(id, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s ai jucat^3 %d^1 or%s ( şi ^3%d^1 minut%s)  pe acest nume.",
																name, prea_lung, prea_lung == 1 ? "ă" : "e", prea_scurt, prea_scurt == 1 ? "" :"e");
		return PLUGIN_HANDLED;
	}
	if( equali(said, "!slot") )
		{
		static name[32], prea_lung;
		
		get_user_name( id, name, charsmax ( name ) );
		timep = get_user_time(id, 1) / 60;
		prea_lung = (timep+TotalPlayedTime[id]-scadere[id]) / 60;
		
		if (is_user_admin(id))
		{
			client_print_color(id, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s ai deja numele rezervat.", name);
			return PLUGIN_HANDLED;
		}
		
		if(prea_lung < 10)
		{
			client_print_color(id, print_team_blue, "^4[Dr.FioriGinal.Ro]^1 %s ai jucat doar ^3 %d^1 or%s, pentru a primi^3 slot^1 ai nevoie de^3 10^1ore."
																														, name, prea_lung, prea_lung == 1 ? "ă" : "e");
			return PLUGIN_HANDLED;
		}
		else
		{
			nana[id] = true;
			client_cmd( id, "messagemode pass" );
			client_print( id, print_center, "Alege o parolă, ai grijă să n-o uiți." );
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	contor[id] = 0;
	new name[32];
	get_user_name(id, name, charsmax(name));
	TotalPlayedTime[id] = TotalPlayedTime[id] + (get_user_time(id)/60);
	SaveTime(id, TotalPlayedTime[id], name);
}

public client_putinserver(id)
{
	new name[32];
	get_user_name(id, name, charsmax(name));
	TotalPlayedTime[id] = LoadTime(id, name);
}

public LoadTime( id, const name[] ) 
{	
	new vaultkey[64], vaultdata[64];
	
	formatex(vaultkey, charsmax(vaultkey), "TIMEPLAYED%s", name);
	
	nvault_get(valut, vaultkey, vaultdata, charsmax(vaultkey));
	
	return  str_to_num(vaultdata);
}

public SaveTime(id, PlayedTime, const name[])
{
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle")
	
	new vaultkey[64], vaultdata[64];
	
	formatex(vaultkey, charsmax(vaultkey), "TIMEPLAYED%s", name); 
	formatex(vaultdata, charsmax(vaultdata), "%d", PlayedTime ); 
	
	nvault_set(valut, vaultkey, vaultdata);	
} 

public ClientUserInfoChanged(id) 
{ 
	static const name[] = "name";
	new szOldName[32], szNewName[32];
	pev(id, pev_netname, szOldName, charsmax(szOldName));
	if ( szOldName[0] ) 
	{ 
		get_user_info(id, name, szNewName, charsmax(szNewName));
		if ( !equal(szOldName, szNewName) ) 
		{ 
			if ( contor[id] < 5 )
			{
				++contor[id];
				TotalPlayedTime[id] = TotalPlayedTime[id] + get_user_time(id) / 60;
				SaveTime(id, TotalPlayedTime[id], szOldName);
				scadere[id] = get_user_time(id, 1) / 60;
			}
			else
			{ 
				client_print(id, print_chat ,"[AMXX] Îţi poţi schimba numele de maxim 5 ori.");
				set_user_info(id, name, szOldName);
				return FMRES_HANDLED;
			}
		} 
	}
	TotalPlayedTime[id] = LoadTime(id, szNewName);
	return FMRES_IGNORED;
} 
