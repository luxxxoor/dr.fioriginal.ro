/* ==  ==  ==  ==  ==  ==  ==  ==     Change the font to "Times New Roman" with a size of 10 for a good readability     ==  ==  ==  ==  ==  ==  == */

#define PLUGIN	"Server Messages"
#define AUTHOR	"Leon McVeran"
#define VERSION	"v1.1"
#define PDATE	"27th April 2009"

/* ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==

Content of Server Messages

This plugin is not really a new idea. You can download similar plugins on https://forums.alliedmods.net or on www.amxmodx.com.
This plugin shows important messages, informations or rules on clients. You can add a messages in different languages into a
file (server_messages.txt). You can also send a custom messages to a specific client or group. 

Special thanks to the members of "Alliedmods - Forum" for some suggestions, solutions and translations.

==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==

Commands

Valid values for @group (with case ignoring)
- for all players: 		@A or @ALL
- for all CTs: 		@C, @CT or @COUNTER
- for all Ts: 		@T, @TE, @TERROR or @TERRORIST

amx_server_msg <authid, nick, @group or #userid> <msg number> <optional: mode> <optional: style (only if mode set to 4)>
- shows a specific messages from the server_messages.txt

amx_server_rule <authid, nick, @group or #userid> <rule number> <optional: mode> <optional: style (only if mode set to 4)>
- shows a specific rules from the server_messages.txt

amx_server_info <authid, nick, @group or #userid> <info number> <optional: mode> <optional: style (only if mode set to 4)>
- shows a specific informations from the server_messages.txt

amx_custom_msg <authid, nick, @group or #userid> <msg> <optional: mode> <optional: style (only if mode set to 4)>
- shows a custom messages to a client or group

amx_list_msg
- shows a list of all server messages that are saved in the server_messages.txt

amx_list_rule
- shows a list of all server rules that are saved in the server_messages.txt

amx_list_info
- shows a list of all server informations that are saved in the server_messages.txt

==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==

CVARs

server_msg_mode "3"
- print location for messages (0 - console, 1 - chat, 2 - center, 3 - hud, 4 - tutor)

server_rule_mode "4"
- print location for rules (0 - console, 1 - chat, 2 - center, 3 - hud, 4 - tutor)

server_info_mode "4"
- print location for informations (0 - console, 1 - chat, 2 - center, 3 - hud, 4 - tutor)

server_msg_style "0"
- style of the tutor by messages (0 - default information, 1 - friend died, 2 - enemy died, 3 - scenario, [4 - buy, 5 - career, 6 - hint, 7 - ingame hint, 8 - endgame])

server_rule_style "3"
- style of the tutor by messages 

server_info_style "0"
- style of the tutor by messages 

server_msg_ondeath "1"
- shows automatically a message on dead players

server_rule_ondeath "1"
- shows automatically a rule on dead players

server_info_ondeath "1"
- shows automatically a information on dead players

server_msg_time "8"
- how long should be displayed a message (seconds)

server_msg_delay "15"
- time between two called messages

server_rule_prefix "1"
- adds a prefix "Rule x:" to server rules

server_restart_msg "0"
- shows a restart messages on joining players (only on players who visit the server first time)

==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==

Changelog

v1.0alpha	9.Apr.2009	Start of this project
v1.0beta	22.Apr.2009	Added
- Messages in Tutor Style
v1.0	24.Apr.2009	Added
- Function to show automatically server messages on dead players
Improved
- Check if exists a messages (If we reach the second language in the server_messages.txt the check will be aborted.)
v1.1	27.Apr.2009	Changed
- Flag of the message_begin-function from MSG_ONE to MSG_ONE_UNRELIABLE (Thanks xPaw)
Bugfixed
- A small fault in the "cmd_server_list"-function
Added
- Translations for
- polish (Thanks merkava)
- dutch (Thanks crazyeffect)
- spanish (Thanks meTaLiCroSS)
- New CVAR "server_rule_prefix" to add a prefix on server rules.
- Now you can set a mode and style in the commands amx_server_rule, ..._msg and ..._info
to overwrite the cvar values.
- Using of the nvault database to determine player who visit the server first time.
For this players will be replaced the tutor messages (mode 4) with hud messages (mode 3).
Set the CVAR "server_restart_msg" to 1 to show a message on affected players after they 
joined a team.

==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==

ToDo

- Green colored Center messages

Troubleshooting
- Player who visit the server at first time didn't see any Tutor messages. (only a CS bug)
(The current solution is not 100% secured because player can remove this files or using more than one computer.)

==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  =*/


#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <vault>


#define ACCESS_MESSAGES 		ADMIN_RCON
#define ACCESS_LIST_MSG 		ADMIN_USER

#define TASK_HIDE_TUTOR 		8800
#define TASK_SHOW_MESSAGE 	8833
#define TYPE_MSG 			1
#define TYPE_RULE			2
#define TYPE_INFO 		4


new bool:g_bTutEnabled[33]
new g_iLastMsg[33]
new g_iLastRule[33]
new g_iLastInfo[33]
new g_szLastType[33][13]

new CVAR_msg_mode
new CVAR_rule_mode
new CVAR_info_mode
new CVAR_msg_style
new CVAR_rule_style
new CVAR_info_style
new CVAR_msg_ondeath
new CVAR_rule_ondeath
new CVAR_info_ondeath
new CVAR_msg_time
new CVAR_msg_delay
new CVAR_rule_prefix
new CVAR_restart_msg

new gMsgTutorClose
new gMsgTutorText
new gMsgSayText

new Float:BlockTutor;
new Float:round_start_gametime;

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("server_messages.txt")
	
	if (is_running("cstrike") || is_running("czero")){
		register_event("HLTV","event_newround","a","1=0","2=0") 
		register_event("DeathMsg", "event_player_death", "a")
		register_event("HLTV", "event_freezetime_start", "a", "1=0", "2=0")
		register_logevent("event_round_end", 2, "1=Round_End")
		
		register_concmd("amx_server_msg", "cmd_server_say", ACCESS_MESSAGES, "<authid, nick, @group or #userid> <msg number> <optional: mode> <optional: style (only if mode set to 4)>")
		register_concmd("amx_server_rule", "cmd_server_say", ACCESS_MESSAGES, "<authid, nick, @group or #userid> <rule number> <optional: mode> <optional: style (only if mode set to 4)>")
		register_concmd("amx_server_info", "cmd_server_say", ACCESS_MESSAGES, "<authid, nick, @group or #userid> <info number> <optional: mode> <optional: style (only if mode set to 4)>")
		register_concmd("amx_custom_msg", "cmd_custom_say", ACCESS_MESSAGES, "<authid, nick, @group or #userid> <msg> <optional: mode> <optional: style (only if mode set to 4)>")
		register_concmd("amx_list_msg", "cmd_server_list", ACCESS_LIST_MSG, "- shows a list of all server messages")
		register_concmd("amx_list_rule", "cmd_server_list", ACCESS_LIST_MSG, "- shows a list of all server rules")
		register_concmd("amx_list_info", "cmd_server_list", ACCESS_LIST_MSG, "- shows a list of all server informations")
		
		register_clcmd("joinclass", "cmd_joinclass")				// New VGUI Menu
		register_menucmd(register_menuid("Terrorist_Select", 1), 511, "cmd_joinclass")	// Old Style Menu
		register_menucmd(register_menuid("CT_Select", 1), 511, "cmd_joinclass")	// Old Style Menu
		
		CVAR_msg_mode = register_cvar("server_msg_mode", "4")
		CVAR_rule_mode = register_cvar("server_rule_mode", "4")
		CVAR_info_mode = register_cvar("server_info_mode", "4")
		CVAR_msg_style = register_cvar("server_msg_style", "5")
		CVAR_rule_style = register_cvar("server_rule_style", "3")
		CVAR_info_style = register_cvar("server_info_style", "7")
		CVAR_msg_ondeath = register_cvar("server_msg_ondeath", "1")
		CVAR_rule_ondeath = register_cvar("server_rule_ondeath", "1")
		CVAR_info_ondeath = register_cvar("server_info_ondeath", "1")
		CVAR_msg_time = register_cvar("server_msg_time", "8")
		CVAR_msg_delay = register_cvar("server_msg_delay", "15")
		CVAR_rule_prefix = register_cvar("server_rule_prefix", "1")
		CVAR_restart_msg = register_cvar("server_restart_msg", "0")
		
		gMsgTutorClose = get_user_msgid("TutorClose")
		gMsgTutorText = get_user_msgid("TutorText")
		gMsgSayText = get_user_msgid("SayText")
	}
	else{
		new ErrMsg[256]
		format(ErrMsg, 255, "[AMXX] Failed to load %s (only for Counter Strike or Condition Zero)", PLUGIN)
		set_fail_state(ErrMsg)
	}
	
	return PLUGIN_CONTINUE
}

public event_newround() 
	{ 
	round_start_gametime = get_gametime() 
	return PLUGIN_CONTINUE 
}  

public plugin_precache(){
	precache_generic("gfx/career/icon_!.tga")
	precache_generic("gfx/career/icon_!-bigger.tga")
	precache_generic("gfx/career/icon_i.tga")
	precache_generic("gfx/career/icon_i-bigger.tga")
	precache_generic("gfx/career/icon_skulls.tga")
	precache_generic("gfx/career/round_corner_ne.tga")
	precache_generic("gfx/career/round_corner_nw.tga")
	precache_generic("gfx/career/round_corner_se.tga")
	precache_generic("gfx/career/round_corner_sw.tga")
	
	precache_generic("resource/TutorScheme.res")
	precache_generic("resource/UI/TutorTextWindow.res")
	
	precache_sound("events/enemy_died.wav")
	precache_sound("events/friend_died.wav")
	precache_sound("events/task_complete.wav")
	precache_sound("events/tutor_msg.wav")
}

/* == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==
EVENTS
== == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==*/

public client_authorized(id){
	if (!is_user_bot(id)){
		LoadData(id)
	}
}

public client_disconnect(id){
	if (!is_user_bot(id)){
		SaveData(id)
	}
}

public event_player_death(){
	new iVictim = read_data(2)
	if (!is_user_bot(iVictim)){
		set_task(8.0, "func_show_message", TASK_SHOW_MESSAGE+iVictim)
	}
}

public event_freezetime_start(){
	for (new iPlayer=0; iPlayer<=get_maxplayers(); ++iPlayer){
		if (task_exists(TASK_SHOW_MESSAGE+iPlayer)){
			remove_task(TASK_SHOW_MESSAGE+iPlayer)
		}
	}
	BlockTutor = get_roundtime();
}

public event_round_end(){
	for (new iPlayer=0; iPlayer<=get_maxplayers(); ++iPlayer){
		if (task_exists(TASK_SHOW_MESSAGE+iPlayer)){
			remove_task(TASK_SHOW_MESSAGE+iPlayer)
		}
	}
}

/* == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==
COMMANDS
== == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==*/

public cmd_joinclass(id){
	if (!g_bTutEnabled[id]){
		if (get_pcvar_num(CVAR_restart_msg) && !is_user_bot(id)){
			new szMsg[256]
			format(szMsg, 255, "%L", id, "MSG_SHOULD_RESTART")
			replace_all(szMsg, 254, "\n", "^n")
			
			set_hudmessage(240, 0, 0, -1.0, 0.65, 2, 0.1, 12.0, 0.02, 0.02, 8)
			show_hudmessage(id, szMsg)
		}
	}
}

public cmd_server_say(id, level, cid){
	// Check if a player have access (only for offline mode)
	if (!(get_user_flags(id)&ACCESS_MESSAGES)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_NO_ACCESS")
		return PLUGIN_HANDLED
	}
	if (!cmd_access(id, level, cid, 3)){
		return PLUGIN_HANDLED
	}
	new szCommand[32], szArg[32], szArg2[4], szArg3[4], szArg4[4], szAdminName[32]
	read_argv(0, szCommand, 31)
	read_argv(1, szArg, 31)
	read_argv(2, szArg2, 3)
	read_argv(3, szArg3, 3)
	read_argv(4, szArg4, 3)
	get_user_name(id, szAdminName, 31)
	
	
	// Define which type of message are used
	new szSearchFor[20], iLen, iMode, iStyle, bool:bPrefix
	if (equal(szCommand, "amx_server_msg")){
		iLen += format(szSearchFor, 19, "SERVER_MSG_")
		iMode = strlen(szArg3) ? str_to_num(szArg3) : get_pcvar_num(CVAR_msg_mode)
		iStyle = strlen(szArg4) ? str_to_num(szArg4) : get_pcvar_num(CVAR_msg_style)
	}
	else if (equal(szCommand, "amx_server_rule")){
		iLen += format(szSearchFor, 19, "SERVER_RULE_")
		iMode = strlen(szArg3) ? str_to_num(szArg3) : get_pcvar_num(CVAR_rule_mode)
		iStyle = strlen(szArg4) ? str_to_num(szArg4) : get_pcvar_num(CVAR_rule_style)
		bPrefix = get_pcvar_num(CVAR_rule_prefix) ? true : false
	}
	else if (equal(szCommand, "amx_server_info")){
		iLen += format(szSearchFor, 19, "SERVER_INFO_")
		iMode = strlen(szArg3) ? str_to_num(szArg3) : get_pcvar_num(CVAR_info_mode)
		iStyle = strlen(szArg4) ? str_to_num(szArg4) : get_pcvar_num(CVAR_info_style)
	}
	
	
	// Technically we should never get here
	if (!strlen(szSearchFor)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_ERROR_SEARCH")
		return PLUGIN_HANDLED
	}
	
	
	// Check if the second parameter a number or not
	if (!is_str_num(szArg2)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_ERROR_NUMBER")
		return PLUGIN_HANDLED
	}
	
	
	// Merge the different parameters to define the used message
	format(szSearchFor[iLen], 19 - iLen, szArg2)
	
	
	// Check if the messages exists
	if (!is_msg_valid(szSearchFor)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_ERROR_TEXT")
		return PLUGIN_HANDLED
	}
	
	
	if (szArg[0]=='@'){
		new iPlayers[32], pNum
		if (equali(szArg[1], "A") || equali(szArg[1], "ALL")){
			get_players(iPlayers, pNum, "c")
		}
		if (equali(szArg[1], "C") || equali(szArg[1], "CT") || equali(szArg[1], "COUNTER")){
			get_players(iPlayers, pNum, "ce", "CT")
		}
		if (equali(szArg[1], "T") || equali(szArg[1], "TE") || equali(szArg[1], "TERROR") || equali(szArg[1], "TERRORIST")){
			get_players(iPlayers, pNum, "ce", "TERRORIST")
		}
		if (pNum==0){
			client_print(id, print_console, "%L", LANG_PLAYER, "MSG_NO_CLIENT")
			return PLUGIN_HANDLED
		}
		
		for(new p=0; p<pNum; ++p){
			new szMsg[256]
			if (bPrefix){
				format(szMsg, 255, "%L^n%L", iPlayers[p], "MSG_SERVER_PREFIX", str_to_num(szSearchFor[12]), iPlayers[p], szSearchFor)
			}
			else{
				format(szMsg, 255, "%L", iPlayers[p], szSearchFor)
			}
			func_print_message(iPlayers[p], szMsg, iMode, iStyle, true)
		}
		log_amx("%L", LANG_SERVER, "MSG_PRINT_LOG", szAdminName, szCommand, szArg, szArg2)
	}
	else {
		new szTargetName[32], iTarget = cmd_target(id, szArg, 10)
		if (!iTarget) return PLUGIN_HANDLED
		get_user_name(id, szTargetName, 31)
		
		new szMsg[256]
		if (bPrefix){
			format(szMsg, 255, "%L^n%L", iTarget, "MSG_SERVER_PREFIX", str_to_num(szSearchFor[12]), iTarget, szSearchFor)
		}
		else{
			format(szMsg, 255, "%L", iTarget, szSearchFor)
		}
		func_print_message(iTarget, szMsg, iMode, iStyle, true)
		log_amx("%L", LANG_SERVER, "MSG_PRINT_LOG", szAdminName, szCommand, szTargetName, szArg2)
	}
	
	return PLUGIN_HANDLED
}

public cmd_custom_say(id, level, cid){
	// Check if a player have access (only for offline mode)
	if (!(get_user_flags(id)&ACCESS_MESSAGES)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_NO_ACCESS")
		return PLUGIN_HANDLED
	}
	if (!cmd_access(id, level, cid, 3)){
		return PLUGIN_HANDLED
	}
	new szArg[32], szMsg[256], szArg3[4], szArg4[4], szAdminName[32]
	read_argv(1, szArg, 31)
	read_argv(2, szMsg, 255)
	read_argv(3, szArg3, 3)
	read_argv(4, szArg4, 3)
	get_user_name(id, szAdminName, 31)
	
	
	// Define mode and style of the message
	// Default mode is 4 (Tutor Message)
	// Default Style is 0 (Standard Information)
	new iMode = strlen(szArg3) ? str_to_num(szArg3) : 4
	new iStyle = strlen(szArg4) ? str_to_num(szArg4) : 0
	
	
	if (szArg[0]=='@'){
		new iPlayers[32], pNum
		if (equali(szArg[1], "A") || equali(szArg[1], "ALL")){
			get_players(iPlayers, pNum, "c")
		}
		if (equali(szArg[1], "C") || equali(szArg[1], "CT") || equali(szArg[1], "COUNTER")){
			get_players(iPlayers, pNum, "ce", "CT")
		}
		if (equali(szArg[1], "T") || equali(szArg[1], "TE") || equali(szArg[1], "TERROR") || equali(szArg[1], "TERRORIST")){
			get_players(iPlayers, pNum, "ce", "TERRORIST")
		}
		if (pNum==0){
			client_print(id, print_console, "%L", LANG_PLAYER, "MSG_NO_CLIENT")
			return PLUGIN_HANDLED
		}
		
		
		for(new p=0; p<pNum; ++p){
			func_print_message(iPlayers[p], szMsg, iMode, iStyle, true)
		}
		log_amx("%L", LANG_SERVER, "MSG_SEND_LOG", szAdminName, szArg, szMsg, iMode, iStyle)
	}
	else {
		new szTargetName[32], iTarget = cmd_target(id, szArg, 10)
		if (!iTarget) return PLUGIN_HANDLED
		get_user_name(id, szTargetName, 31)
		
		func_print_message(iTarget, szMsg, iMode, iStyle, true)
		log_amx("%L", LANG_SERVER, "MSG_SEND_LOG", szAdminName, szTargetName, szMsg, iMode, iStyle)
	}
	
	return PLUGIN_HANDLED
}

public cmd_server_list(id, level, cid){
	// Check if a player have access (only for offline mode)
	if (!(get_user_flags(id)&ACCESS_LIST_MSG)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_NO_ACCESS")
		return PLUGIN_HANDLED
	}
	if (!cmd_access(id, level, cid, 1)){
		return PLUGIN_HANDLED
	}
	new szCommand[32], szAdminName[32]
	read_argv(0, szCommand, 31)
	get_user_name(id, szAdminName, 31)
	
	
	// Define which type of message should be listed
	new szSearchFor[20], iLen
	if (equal(szCommand, "amx_list_msg")){
		iLen += format(szSearchFor, 19, "SERVER_MSG_")
		client_print(id, print_console, "^n%L", LANG_PLAYER, "MSG_START_MSG_LISTING")
	}
	else if (equal(szCommand, "amx_list_rule")){
		iLen += format(szSearchFor, 19, "SERVER_RULE_")
		client_print(id, print_console, "^n%L", LANG_PLAYER, "MSG_START_RULE_LISTING")
	}
	else if (equal(szCommand, "amx_list_info")){
		iLen += format(szSearchFor, 19, "SERVER_INFO_")
		client_print(id, print_console, "^n%L", LANG_PLAYER, "MSG_START_INFO_LISTING")
	}
	
	
	// Technically we should never get here
	if (!strlen(szSearchFor)){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_ERROR_SEARCH")
		return PLUGIN_HANDLED
	}
	
	
	// Search the messages and print in the console
	new szFileName[64], bool:bFound, iLanguages
	get_datadir(szFileName, 63)
	format(szFileName, 63, "%s/lang/server_messages.txt", szFileName)
	if (file_exists(szFileName)){
		new szText[32], szBuffer[128], szLastMsg[32], fp=fopen(szFileName, "r")
		while (!feof(fp) && iLanguages < 2){
			szBuffer[0]='^0'
			fgets(fp, szBuffer, charsmax(szBuffer))
			parse(szBuffer, szText, charsmax(szText))
			if (!equali(szText, szLastMsg)){
				
				// Saves the current message for blocking duplicative messages
				copy(szLastMsg, 31, szText)
				
				if (equali(szText, szSearchFor, strlen(szSearchFor))){
					bFound = true
					
					// That is all for the formatting of the messages
					new szMsg[256], iMsg = str_to_num(szText[strlen(szSearchFor)])
					format(szMsg, 255, "%L", id, szText)
					replace_all(szMsg, 254, "\n", "^n")
					replace_all(szMsg, 254, "^n", iMsg > 9 ? "^n      " : "^n    ")
					client_print(id, print_console, "%i: %s", iMsg, szMsg)
				}
				
				// Stop loop if we reached the second language
				else if (szText[0] == '[' && szText[3] == ']'){
					iLanguages += 1
				}
			}
		}
		fclose(fp)
	}
	else{
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_ERROR_FILE")
		return PLUGIN_HANDLED
	}
	if (!bFound){
		client_print(id, print_console, "%L", LANG_PLAYER, "MSG_ERROR_TEXT")
	}
	client_print(id, print_console, "   ")
	
	return PLUGIN_HANDLED
}

/* == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==
FUNCTIONS
== == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==*/

public func_print_message(id, szMsg[], iMode, iStyle, bool:bSound){
	
	// Check if we can use the tutor, otherwise we send a hudmessage
	if (iMode == 4 && !g_bTutEnabled[id]){
		iMode = 3
	}
	
	// Replace all \n with ^n because it is difficult to type "^" in the console. So you can use \n for a word wrap.
	replace_all(szMsg, 254, "\n", "^n")
	
	switch(iMode){
		case 1: {
			replace_all(szMsg, 254, "^n", " ")
			//client_print(id, print_center, szMsg)
			Create_ChatMsg(id, szMsg)
		}
		case 2: {
			replace_all(szMsg, 254, "^n", " ")
			client_print(id, print_center, szMsg)
		}
		case 3: {
			set_hudmessage(0, 200, 0, 0.05, 0.35, 2, 0.1, get_pcvar_num(CVAR_msg_time) < 5 ? 5.0 : get_pcvar_float(CVAR_msg_time), 0.02, 0.02, 8)
			show_hudmessage(id, szMsg)
		}
		case 4: {
			Create_TutorMsg(id, szMsg, iStyle, bSound)
		}
		default: client_print(id, print_console, szMsg)
	}
}

public func_show_message(taskid){
	new id = (taskid > TASK_SHOW_MESSAGE) ? (taskid - TASK_SHOW_MESSAGE) : taskid
	if (is_user_connected(id)){
		
		// Define the next message
		new iTypes
		iTypes += get_pcvar_num(CVAR_msg_ondeath) ? TYPE_MSG : 0
		iTypes += get_pcvar_num(CVAR_rule_ondeath) ? TYPE_RULE : 0
		iTypes += get_pcvar_num(CVAR_info_ondeath) ? TYPE_INFO : 0
		if (!iTypes){
			return PLUGIN_HANDLED
		}
		
		new bool:bFound, iTryFind
		while (!bFound && iTryFind < 2){
			iTryFind+=1
			
			new szNextMsg[20]
			if (equal(g_szLastType[id], "SERVER_MSG_", 11)){
				if (iTypes & TYPE_MSG) iTypes-=TYPE_MSG
				switch(iTypes){
					case TYPE_RULE + TYPE_INFO: {
						new iType = random_num(0, 1)
						if (iType){
							g_iLastRule[id]+=1
							format(szNextMsg, 19, "SERVER_RULE_%i", g_iLastRule[id])
						}
						else{
							g_iLastInfo[id]+=1
							format(szNextMsg, 19, "SERVER_INFO_%i", g_iLastInfo[id])
						}
					}
					case TYPE_RULE: {
						g_iLastRule[id]+=1
						format(szNextMsg, 19, "SERVER_RULE_%i", g_iLastRule[id])
					}
					case TYPE_INFO: {
						g_iLastInfo[id]+=1
						format(szNextMsg, 19, "SERVER_INFO_%i", g_iLastInfo[id])
					}
					default: {
						g_iLastMsg[id]+=1
						format(szNextMsg, 19, "SERVER_MSG_%i", g_iLastMsg[id])
					}
				}
			}
			else if (equal(g_szLastType[id], "SERVER_RULE_", 12)){
				if (iTypes & TYPE_RULE) iTypes-=TYPE_RULE
				switch(iTypes){
					case TYPE_MSG + TYPE_INFO: {
						new iType = random_num(0, 1)
						if (iType){
							g_iLastMsg[id]+=1
							format(szNextMsg, 19, "SERVER_MSG_%i", g_iLastMsg[id])
						}
						else{
							g_iLastInfo[id]+=1
							format(szNextMsg, 19, "SERVER_INFO_%i", g_iLastInfo[id])
						}
					}
					case TYPE_MSG: {
						g_iLastMsg[id]+=1
						format(szNextMsg, 19, "SERVER_MSG_%i", g_iLastMsg[id])
					}
					case TYPE_INFO: {
						g_iLastInfo[id]+=1
						format(szNextMsg, 19, "SERVER_INFO_%i", g_iLastInfo[id])
					}
					default: {
						g_iLastRule[id]+=1
						format(szNextMsg, 19, "SERVER_RULE_%i", g_iLastRule[id])
					}
				}
			}
			else{
				if (iTypes & TYPE_INFO) iTypes-=TYPE_INFO
				switch(iTypes){
					case TYPE_MSG + TYPE_RULE: {
						new iType = random_num(0, 1)
						if (iType){
							g_iLastMsg[id]+=1
							format(szNextMsg, 19, "SERVER_MSG_%i", g_iLastMsg[id])
						}
						else{
							g_iLastRule[id]+=1
							format(szNextMsg, 19, "SERVER_RULE_%i", g_iLastRule[id])
						}
					}
					case TYPE_MSG: {
						g_iLastMsg[id]+=1
						format(szNextMsg, 19, "SERVER_MSG_%i", g_iLastMsg[id])
					}
					case TYPE_RULE: {
						g_iLastRule[id]+=1
						format(szNextMsg, 19, "SERVER_RULE_%i", g_iLastRule[id])
					}
					default: {
						g_iLastInfo[id]+=1
						format(szNextMsg, 19, "SERVER_INFO_%i", g_iLastInfo[id])
					}
				}
			}
			
			if (is_msg_valid(szNextMsg)){
				bFound = true
				copy(g_szLastType[id], 12, szNextMsg)
				
				new iMode, iStyle, bool:bPrefix
				if (equal(szNextMsg, "SERVER_MSG_", 11)){
					iMode = get_pcvar_num(CVAR_msg_mode)
					iStyle = get_pcvar_num(CVAR_msg_style)
				}
				else if (equal(szNextMsg, "SERVER_RULE_", 12)){
					iMode = get_pcvar_num(CVAR_rule_mode)
					iStyle = get_pcvar_num(CVAR_rule_style)
					bPrefix = get_pcvar_num(CVAR_rule_prefix) ? true : false
				}
				else if (equal(szNextMsg, "SERVER_INFO_", 12)){
					iMode = get_pcvar_num(CVAR_info_mode)
					iStyle = get_pcvar_num(CVAR_info_style)
				}
				
				new szMsg[256]
				if (bPrefix){
					format(szMsg, 255, "%L^n%L", id, "MSG_SERVER_PREFIX", str_to_num(szNextMsg[12]), id, szNextMsg)
				}
				else{
					format(szMsg, 255, "%L", id, szNextMsg)
				}
				func_print_message(id, szMsg, iMode, iStyle, false)
			}
			else{
				if (equal(szNextMsg, "SERVER_MSG_", 11)){
					g_iLastMsg[id]=0
				}
				else if (equal(szNextMsg, "SERVER_RULE_", 12)){
					g_iLastRule[id]=0
				}
				else if (equal(szNextMsg, "SERVER_INFO_", 12)){
					g_iLastInfo[id]=0
				}
			}
		}
		
		set_task(get_pcvar_num(CVAR_msg_delay) < 10 ? 10.0 : get_pcvar_float(CVAR_msg_delay), "func_show_message", TASK_SHOW_MESSAGE+id)
	}
	
	return PLUGIN_CONTINUE
}


/* == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==
STOCKS
== == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==*/

stock Create_TutorMsg(id, szMsg[], iStyle, bool:bSound){
	if((get_gametime() - BlockTutor < 35.0) )
		return;
	// Emulate played sounds of the original tutor
	// Don't play this sounds for automatic messages on dead players
	if (bSound){
		switch(iStyle){
			case 1: emit_sound(id, CHAN_ITEM, "events/friend_died.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
			case 2: emit_sound(id, CHAN_ITEM, "events/enemy_died.wav", VOL_NORM, ATTN_NORM, 0, PITCH_LOW)
			case 5: emit_sound(id, CHAN_ITEM, "events/task_complete.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			default: emit_sound(id, CHAN_ITEM, "events/tutor_msg.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	
	// I think we can remove this but this is called by the original
	// Hide Tutor
	message_begin(MSG_ONE_UNRELIABLE , gMsgTutorClose, {0, 0, 0}, id)
	message_end()
	
	// Create a Tutor message
	message_begin(MSG_ONE_UNRELIABLE , gMsgTutorText, {0, 0, 0}, id)
	write_string(szMsg)		// displayed message
	write_byte(0)		// ???
	write_short(0)		// ???
	write_short(0)		// ???
	write_short(1<<iStyle)	// class of a message
	message_end()
	
	// Hide Tutor in ... seconds
	remove_task(TASK_HIDE_TUTOR+id)
	set_task(get_pcvar_num(CVAR_msg_time) < 5 ? 5.0 : get_pcvar_float(CVAR_msg_time), "Remove_TutorMsg", TASK_HIDE_TUTOR+id)
	
}

public Remove_TutorMsg(taskid){
	new id = (taskid > TASK_HIDE_TUTOR) ? (taskid - TASK_HIDE_TUTOR) : taskid
	message_begin(MSG_ONE_UNRELIABLE , gMsgTutorClose, {0, 0, 0}, id)
	message_end()
}

stock Create_ChatMsg(id, szMsg[]){
	format(szMsg, 255, "^x04%s", szMsg)
	
	message_begin(MSG_ONE_UNRELIABLE , gMsgSayText, {0, 0, 0}, id)
	write_byte(id)
	write_string(szMsg)
	message_end()
}

stock bool:is_msg_valid(szSearchFor[]){
	new szFileName[64], bool:bFound, iLanguages
	get_datadir(szFileName, 63)
	format(szFileName, 63, "%s/lang/server_messages.txt", szFileName)
	if (file_exists(szFileName)){
		new szText[32], szBuffer[128], szLastMsg[32], fp=fopen(szFileName, "r")
		while (!feof(fp) && !bFound && iLanguages < 2){
			szBuffer[0]='^0'
			fgets(fp, szBuffer, charsmax(szBuffer))
			parse(szBuffer, szText, charsmax(szText))
			if (!equali(szText, szLastMsg)){
				
				// Saves the current message for blocking duplicative messages
				copy(szLastMsg, 31, szText)
				
				if (equali(szText, szSearchFor, strlen(szSearchFor))){
					bFound = true
				}
				
				// Stop loop if we reached the second language
				else if (szText[0] == '[' && szText[3] == ']'){
					iLanguages += 1
				}
			}
		}
		fclose(fp)
	}
	// Message or File not exists.
	// I used this bool because I want close the file before I doing something others.
	if (!bFound){
		return false
	}
	return true
}

stock SaveData(id){
	if (!is_running("czero")){
		new szAuthid[32], szKey[64], szData[64]
		
		get_user_authid(id, szAuthid, 31)
		format(szKey, 63, "SERV_MSG_%s", szAuthid)
		format(szData, 63, "true")
		
		set_vaultdata(szKey, szData)
	}
}

stock LoadData(id){
	if (!is_running("czero")){
		new szAuthid[32], szKey[64], szData[64]
		
		get_user_authid(id, szAuthid, 31)
		format(szKey, 63, "SERV_MSG_%s", szAuthid)
		
		get_vaultdata(szKey, szData, 63)
		g_bTutEnabled[id] = equali(szData, "true") ? true : false
	}
	else{
		g_bTutEnabled[id] = true
	}
}

stock Float:get_roundtime() 
	{ 
	return get_gametime() - round_start_gametime 
}  
