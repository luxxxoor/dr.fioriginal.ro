#include <amxmisc>

#define PLUGIN			"ULTIMATE WHO"
#define VERSION			"1.2"
#define AUTHOR			"P.Of.Pw"

#define time_shower		1.0

#define GROUPS_NAME		4
#define GROUPS_ACCESS		4

#define time_hud		12.0

#define motd_msg		"Admin's Online"

#define who_meniu_ad_group_msg	"\y-=[Admin's]=- \r-=[Online]=-^n"
#define who_meniu_admin_msg	"\y-=[Admin's]=- \w-=[Online]=-^n^n"

#define who_meniu_ad_group_msg_bottom	"^n\wPt a esi apasati \y0 \w sau \y5"
#define who_meniu_admin_msg_bottom	"^n\wPt a esi apasati \r0 \w sau \r5"

#define	who_console_top		"=========== Admini Online ==========="
#define	who_console_bottom 	"================================"

new GroupNames[GROUPS_NAME][] = {
	"Owners",
	"Moderatori",
	"Administratori",
	"Sloturi"
}

new GroupFlags[GROUPS_ACCESS][] = {
	"abcdefghijklmnopqrstu",
	"abcdefghijklmnopqrst",
	"bcdefijmnopqrstu",
	"b"
}

new GroupFlagsValue[GROUPS_NAME]

new who_type, who_typemeniu, who_typtable

public plugin_init() 
{
   
	register_plugin(PLUGIN, VERSION, AUTHOR)
   
	for(new i; i < GROUPS_NAME ; ++i)
	{
		GroupFlagsValue[i] = read_flags(GroupFlags[i]);
	}
   
	register_clcmd("say", "cmdSay");
	register_clcmd("say_team", "cmdSay");
	
	who_type	    = register_cvar("cmd_who","1");
	who_typemeniu	= register_cvar("who_typemeniu","1");
	who_typtable	= register_cvar("who_typetable","2");
}

public cmdSay(id)
{
	new say[192];
	read_args(say, charsmax(say));
	if(( containi(say, "who") != -1 || containi(say, "admin") != -1 || containi(say, "admins") != -1  || contain(say, "/who") != -1 || contain(say, "/admin") != -1 || contain(say, "/admins") != -1))
		set_task(time_shower,"cmdULTMWho",id)
}

public cmdULTMWho(id)
{
	switch(get_pcvar_num(who_type))
	{
		case 1: who_meniu(id)
		
		case 2: who_motd(id)
		
		case 3: who_table(id)
		
		case 4: who_hud(id)
		
		case 5: who_console(id)
		
	}
}

who_meniu(id)
{
	switch(get_pcvar_num(who_typemeniu))
	{
		case 1: who_meniu_admin_groups(id)
		
		case 2: who_meniu_admin(id)
	}
}
who_meniu_admin_groups(id)
{
	new sPlayers[32], iNum
	new sName[32]
	new szMenu[256], nLen, keys
	
	nLen = format(szMenu[nLen], charsmax(szMenu), who_meniu_ad_group_msg)
	get_players(sPlayers, iNum, "ch")
   
	for(new i = 0; i < GROUPS_NAME; ++i)
	{   
		nLen += format(szMenu[nLen], charsmax(szMenu)-nLen,"\r%s^n", GroupNames[i])
     
		for(new j = 0; j < iNum; ++j)
		{
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i])
			{
				get_user_name(sPlayers[j], sName, charsmax(sName))
				nLen += format(szMenu[nLen], charsmax(szMenu)-nLen,"\w%s^n", sName)
			}   
		}
	}
	nLen += format(szMenu[nLen], charsmax(szMenu)-nLen, who_meniu_ad_group_msg_bottom)
	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9)
	show_menu(id,keys,szMenu,-1)
}

who_meniu_admin(id)
{
	new sPlayers[32], iNum
	new sName[32]
	new szMenu[256], nLen, keys
   
	nLen = format(szMenu[nLen], charsmax(szMenu), who_meniu_admin_msg)
  
	get_players(sPlayers, iNum, "ch")
	for(new i = 0; i < GROUPS_NAME; ++i)
	{
		for(new j = 0; j < iNum; ++j)
		{         
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i])
			{
				get_user_name(sPlayers[j], sName, charsmax(sName));
				nLen += format(szMenu[nLen], charsmax(szMenu)-nLen,"\r%s^n", sName)
			}   
		}
	}
	nLen += format(szMenu[nLen], charsmax(szMenu)-nLen, who_meniu_admin_msg_bottom)
	keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9)
	show_menu(id,keys,szMenu,-1)
}

who_motd(id)
{
	new sPlayers[32], iNum
	new sName[32], sBuffer[1024]
	new iLen
	
	iLen = formatex(sBuffer, charsmax(sBuffer), "<body bgcolor=#000000><font color=#7b68ee><pre>")
   
	get_players(sPlayers, iNum, "ch")
   
	for(new i = 0; i < GROUPS_NAME; ++i)
	{   
		iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<center><h5><font color=^"red^">%s^n</font></h5></center>", GroupNames[i])
     
		for(new j = 0; j < iNum; ++j)
		{         
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i])
			{
				get_user_name(sPlayers[j], sName, charsmax(sName))
				iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<center>%s^n</center>", sName)
			}
		}		
	}
	show_motd(id, sBuffer, motd_msg)
}

who_table(id)
{
	switch(get_pcvar_num(who_typtable))
	{
		case 1: table_style_one(id)
		
		case 2: table_style_two(id)
	}
}
table_style_one(id)
{
	new sPlayers[32], iNum
	new sName[32], sBuffer[1024]
	new iLen
	
	iLen = formatex(sBuffer, charsmax(sBuffer), "<body bgcolor=#000000><font color=#7b68ee><pre>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<center><h3><b><font color=^"red^">NUME			-	ACCES</font></h3></b></center>")
	
	get_players(sPlayers, iNum, "ch")
   
	for(new i = 0; i < GROUPS_NAME; ++i)
	{
		for(new j = 0; j < iNum; ++j)
		{	
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i])
			{
				get_user_name(sPlayers[j], sName, charsmax(sName))
				iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<center><h4><font color=^"white^">%s		%s^n</font></h4></center>", sName, GroupNames[i])
			}
		}		
	}
	show_motd(id, sBuffer, motd_msg)
}
table_style_two(id)
{
	new sPlayers[32], iNum
	new sName[32], sBuffer[1024]
	new iLen
	
	iLen = formatex(sBuffer, charsmax(sBuffer), "<body bgcolor=#000000><font color=#7b68ee><pre>")
	
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<html><head><title>a</title></head>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<br><br><center><body><table border>")
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<tr><td><h3><b><font color=^"red^">NUME</td><td></h3></b> <h3><b><font color=^"red^">ACCES</td></h3></font></b></center>")
	
	get_players(sPlayers, iNum, "ch")
   
	for(new i = 0; i < GROUPS_NAME; ++i)
	{
		for(new j = 0; j < iNum; ++j)
		{   
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i])
			{
				get_user_name(sPlayers[j], sName, charsmax(sName))
				iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "<center><tr><td><h4><b><font color=^"white^">%s<td></b></h4> <h4><b><font color=^"white^">%s </td></h4></font></b></center>", sName, GroupNames[i])
			}
		}		
	}
	iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "</table></body></html>")
	show_motd(id, sBuffer, motd_msg)
}

who_hud(id)
{
	new sPlayers[32], iNum
	new sName[32], sBuffer[1024]
	new iLen
	
	get_players(sPlayers, iNum, "ch")
   
	for(new i = 0; i < GROUPS_NAME; ++i)
	{   
		iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "=== %s ===^n", GroupNames[i])
		
		for(new j = 0; j < iNum; ++j)
		{
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i])
			{
				get_user_name(sPlayers[j], sName, charsmax(sName));
				iLen += formatex(sBuffer[iLen], charsmax(sBuffer) - iLen, "%s^n", sName)
			}
		}		
	}
	set_hudmessage(255, 255, 255, 0.02, 0.24, 0, 6.0, time_hud)
	show_hudmessage(id, sBuffer)
}

who_console(id)
{
	new sPlayers[32], iNum
	new sName[32]

	get_players(sPlayers, iNum)
	console_print(id, who_console_top)
	for(new i = 0; i < GROUPS_NAME; ++i) 
	{
		for(new j = 0; j < iNum; ++j)
		{
			get_user_name(sPlayers[j], sName, charsmax(sName));
			if(get_user_flags(sPlayers[j]) == GroupFlagsValue[i]) 
			{
				console_print(id, "= %d = %s : %s", i+1, GroupNames[i], sName)
			}			
		}
	}
	console_print(id, who_console_bottom)
}