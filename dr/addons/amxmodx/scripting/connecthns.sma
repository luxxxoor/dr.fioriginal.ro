#include <amxmodx>
#include <amxmisc>

#define PLUGIN "FastConnect"
#define VERSION "1.0"
#define AUTHOR "R1kKk-"

#define DRTAG "!n[!tDr.!gFioriGinal.!tRo!n]"

public plugin_init( ) {
	
	register_clcmd("say !hns", "redirectcmd");
	register_clcmd("say_team !hns", "redirectcmd");
	
}

public redirectcmd(index) {
	chat_color(index, "%s Vei fi redirectionat pe !gHns.Joinet.Ro", DRTAG)
	set_task(3.0, "connect", index);
	set_task(5.0, "mesaj2", index);
	return PLUGIN_HANDLED;
}

public connect(index) {
	if(is_steam_user(index)) {
		client_cmd( index , "wait;wait;wait;wait;wait;^"connect^" 89.40.233.141:27015^"")
		} else {
		client_cmd( index , "csx_setcvar^"Enabled^"False")
		client_cmd( index , "rus_setcvar^"Enabled^"False")
		client_cmd( index , "prot_setcvar^"Enabled^"False")
		client_cmd( index , "bog_setcvar^"Enabled^"False")
		client_cmd( index , "exp_setcvar^"Enabled^"False")
		client_cmd( index , "fix_setcvar^"Enabled^"False")
		client_cmd( index , "Enabled^"Enabled^"False")
		client_cmd( index , "BlockCommands^"Enabled^"False")
		client_cmd( index , "Connect 89.40.233.141:27015")
		client_cmd( index , "ConnectHNS")
	}
}

public client_putinserver(index) {
	set_task(2.0, "printmessage", index)
}

public printmessage(index) {
	chat_color(index, "%s Daca vrei sa joci !thide`n`seek!n, tasteaza !g!hns !nca sa intrii pe serverul partener.", DRTAG)
}

public mesaj2(index) {
	chat_color(index, "%s Se pare ca nu ai putut fi redirectionat din cauza guard-ului. Serverul este !gHns.Joinet.Ro.", DRTAG )
}


stock bool:is_steam_user( id )
	{
	static szAuthid[ 35 ];
	get_user_authid( id, szAuthid, sizeof( szAuthid ) -1 );
	
	return szAuthid[ 7 ] == ':' ? true : false;
}

stock chat_color(const id, const input[], any:...)
	{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!n", "^1")
	replace_all(msg, 190, "!t", "^3")
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
			{
			if (is_user_connected(players[i]))
				{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang1033{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
