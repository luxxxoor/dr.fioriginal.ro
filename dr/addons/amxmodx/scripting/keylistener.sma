#include <amxmodx>
#include <fakemeta>
#include <colorchat>
#include <cstrike>

#define PLUGIN 	"Showkeys"
#define VERSION "1.1"
#define AUTHOR 	"cheap_suit / R1kKk-"


new cvar_x
new cvar_y

new g_spectarget[33]
new g_specmode[33]
new bool:ShowkeysON[33];

public plugin_init()  {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_PlayerPostThink, "fwd_playerpostthink")
	
	register_event("TextMsg", 	"event_textmsg", 	"b",	"2&#Spec_Mode")
	register_event("StatusValue", 	"event_statusvalue", 	"bd", 	"1=2")
	register_event("SpecHealth2", 	"event_spechealth2", 	"bd")
	register_event("ResetHUD", 	"event_resethud", 	"be")
	
	cvar_x = register_cvar("keylistenhud_x", "-1.0")
	cvar_y = register_cvar("keylistenhud_y", "0.6")
	
	register_clcmd("say !showkeys","cmdShowkeys");
	register_clcmd("say_team !showkeys","cmdShowkeys");
	register_clcmd("say !keys","cmdShowkeys");
	register_clcmd("say_team !keys","cmdShowkeys");

}

public client_connect(id) {	
	reset(id) 
	ShowkeysON[id] = false;
}
public client_disconnected(id) {	
	reset(id) 
	ShowkeysON[id] = false;
}
public event_resethud(id) {	
	reset(id) 
}

public reset(id) {
	g_spectarget[id] = 0, g_specmode[id] = false	
}

public cmdShowkeys(id) {
	if(!ShowkeysON[id]) {
		ColorChat(id, RED, "[Showkeys] ^4Ai activat showkeys !");
		ShowkeysON[id] = true;
		return PLUGIN_HANDLED
		}else{
		ColorChat(id, RED, "[Showkeys] ^4Ai dezactivat showkeys !");
		ShowkeysON[id] = false;
		return PLUGIN_HANDLED
	}	
}



public event_textmsg(id) {
	static specmode[12]
	read_data(2, specmode, 11)
	
	if(equal(specmode, "#Spec_Mode2") || equal(specmode, "#Spec_Mode4"))
		g_specmode[id] = true
	else
		g_specmode[id] = false
	
	return PLUGIN_CONTINUE
}

public event_statusvalue(id) {
	if(is_user_connected(id) && !is_user_alive(id))
		set_spec_target(id, read_data(2))
}

public event_spechealth2(id) {
	if(is_user_connected(id) && !is_user_alive(id))
		set_spec_target(id, read_data(2))
}

public set_spec_target(index, target) {
	if(target > 0)
		g_spectarget[index] = target
}

public fwd_playerpostthink(id) { 
	if(!is_user_alive(id) && !g_specmode[id]){
		return FMRES_IGNORED
		}
	if(!is_user_alive(id)) {
		new target = g_spectarget[id]
		if((target < 1) || !is_user_alive(target)) 
			return FMRES_IGNORED
		
		new button = pev(target, pev_button)
		
		static key[6][6]
		formatex(key[0], 5, "%s", (button & IN_FORWARD) && !(button & IN_BACK) ? " W " : "   ")
		formatex(key[1], 5, "%s", (button & IN_BACK) && !(button & IN_FORWARD) ? " S " : "   ")
		formatex(key[2], 5, "%s", (button & IN_MOVELEFT) && !(button & IN_MOVERIGHT) ? "A" : "   ")
		formatex(key[3], 5, "%s", (button & IN_MOVERIGHT) && !(button & IN_MOVELEFT) ? "D" : "   ")
		formatex(key[4], 5, "%s", (button & IN_DUCK) ? " DUCK " : "      ")
		formatex(key[5], 5, "%s", (button & IN_JUMP) ? " JUMP " : "      ")
		
		set_hudmessage(255, 10, 150, get_pcvar_float(cvar_x), get_pcvar_float(cvar_y), 0, _, 0.1, _, _, 1)
		show_hudmessage(id, "%s^n%s %s %s^n^n%s %s", key[0], key[2], key[1], key[3], key[4], key[5])
	}
	else if(is_user_alive(id) && ShowkeysON[id]) {
		if((id < 1) || !is_user_alive(id))
			return FMRES_IGNORED
		
		new buttonkey = pev(id, pev_button)
		
		static keybutton[6][6]
		formatex(keybutton[0], 5, "%s", (buttonkey & IN_FORWARD) && !(buttonkey & IN_BACK) ? " W " : "   ")
		formatex(keybutton[1], 5, "%s", (buttonkey & IN_BACK) && !(buttonkey & IN_FORWARD) ? " S " : "   ")
		formatex(keybutton[2], 5, "%s", (buttonkey & IN_MOVELEFT) && !(buttonkey & IN_MOVERIGHT) ? "A" : "   ")
		formatex(keybutton[3], 5, "%s", (buttonkey & IN_MOVERIGHT) && !(buttonkey & IN_MOVELEFT) ? "D" : "   ")
		formatex(keybutton[4], 5, "%s", (buttonkey & IN_DUCK) ? " DUCK " : "      ")
		formatex(keybutton[5], 5, "%s", (buttonkey & IN_JUMP) ? " JUMP " : "      ")
		
		set_hudmessage(255, 150, 10, get_pcvar_float(cvar_x), get_pcvar_float(cvar_y), 0, _, 0.1, _, _, 1)
		show_hudmessage(id, "%s^n%s %s %s^n^n%s %s", keybutton[0], keybutton[2], keybutton[1], keybutton[3], keybutton[4], keybutton[5])
	}
	return FMRES_IGNORED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3081\\ f0\\ fs16 \n\\ par }
*/

