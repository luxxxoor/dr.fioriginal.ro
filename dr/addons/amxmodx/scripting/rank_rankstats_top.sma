#include <amxmisc>
#include <csx>

#if AMXX_VERSION_NUM < 183 
	#define MAX_NAME_LENGTH 32
	#include <colorchat>
#endif

#pragma semicolon 1

new CvarRank, CvarRankStats, CvarTop, CvarTopNum, CvarTitle, CvarDisconnect;

public plugin_init() 
{
	register_plugin("RRT", "0.3.1-fixed", "Ex3cuTioN/Arion");
	
	register_clcmd("say", "hookSay");
	register_clcmd("say_team", "hookSay");
	
	#if AMXX_VERSION_NUM < 183 
		CvarTop = register_cvar("rrt_top", "1");
		CvarRank = register_cvar("rrt_rank", "1");
		CvarRankStats = register_cvar("rrt_rankstats", "1");
		CvarTopNum = register_cvar("rrt_topnum", "10");
		CvarTitle = register_cvar("rrt_title", "Top jucatori");
		CvarDisconnect = register_cvar("rrt_connect", "1");
	#else
		CvarTop = create_cvar("rrt_top", "1", _, "(1|0) Activează/Dezactivează topul.", true, 0.0, true, 1.0);
		CvarRank = create_cvar("rrt_rank", "1", _, "(0) Dezactivează rank-ul. (1|2) Detalii pornite/oprite.", true, 0.0, true, 2.0);
		CvarRankStats = create_cvar("rrt_rankstats", "1", _, "(1|0) Activează/Dezactivează RankStats-ul.", true, 0.0, true, 1.0);
		CvarTopNum = create_cvar("rrt_topnum", "10", _, "(10|15) Numărul de persoane afișate în top. Plugin-ul permite doar valorile 10-15.", true, 10.0, true, 15.0);
		CvarTitle = create_cvar("rrt_title", "Top jucători", _, "Titlul MOTD-ului.");
		CvarDisconnect = create_cvar("rrt_disconnect", "1", _, "(0) Dezactivează afișeaza rank-ului la ieșirea de pe server (1|2) Detalii pornite/oprite.", true, 0.0, true, 1.0);
	#endif
}

public hookSay(Index) 
{
	new Said[192], RankIdent[] = "/rank", RankStatsIdent[] = "/rankstats", TopIdent[] = "/top";
	
	read_args(Said, charsmax(Said));
	remove_quotes(Said);
	
	if (equal(Said, RankStatsIdent, charsmax(RankStatsIdent)))
	{
		new Target[MAX_NAME_LENGTH];
		split(Said, Said, charsmax(Said), Target, charsmax(Target), " ");
		if (equal(Target, ""))
		{
			showRankStats(Index, Index);
		}
		else
		{
			showRankStats(Index, cmd_target(Index, Target, CMDTARGET_NO_BOTS));
		}
		
		return PLUGIN_HANDLED;
	}
	
	if(equal(Said, RankIdent, charsmax(RankIdent)))
	{
		new Target[MAX_NAME_LENGTH];
		split(Said, Said, charsmax(Said), Target, charsmax(Target), " ");
		if (equal(Target, ""))
		{
			showRank(Index, Index);
		}
		else
		{
			showRank(Index, cmd_target(Index, Target, CMDTARGET_NO_BOTS));
		}
		
		return PLUGIN_HANDLED;
	}
	
	if(equal(Said, TopIdent, charsmax(TopIdent)))
	{
		if (get_pcvar_num(CvarTop) == 0) 
		{
			#if AMXX_VERSION_NUM < 183 
				ColorChat(Index, GREEN, "[Top]^1 Topul este dezactivat.");
			#else
				client_print_color(Index, print_team_default, "^4[Top]^1 Topul este dezactivat.");
			#endif
			return PLUGIN_HANDLED;
		}
		#if AMXX_VERSION_NUM < 183 
			replace(Said, charsmax(Said), "/top", "");
		#else
			replace_stringex(Said, charsmax(Said), "/top", "");
		#endif
		
		showTop(Index, str_to_num(Said));
	}
	
	return PLUGIN_CONTINUE;
}
#if AMXX_VERSION_NUM < 183 
	public client_disconnect(Index)
#else
	public client_disconnected(Index)
#endif
{
	new Disconnect = get_pcvar_num(CvarDisconnect);
	
	if (Disconnect == 0) 
	{
		return;
	}
	
	new Name[MAX_NAME_LENGTH], Stats[8], BodyHits[8], RankPos, RankMax;

	RankMax = get_statsnum();
	RankPos = get_user_stats(Index, Stats, BodyHits);
	
	if (RankPos <= 0) // @note The permanent storage is updated on every respawn or client disconnect.
	{
		return;
	}
	
	get_user_name(Index, Name, charsmax(Name));
	
	if(Disconnect == 2)
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(0, GREEN, "[Rank]^3 %s^1 a iesit, rank %d din %d cu %d fraguri si %d decese.", Name, RankPos, RankMax, Stats[0], Stats[1]);
		#else
			client_print_color(0, print_team_default, "^4[Rank]^3 %s^1 a ieșit, rank %d din %d cu %d fraguri și %d decese.", Name, RankPos, RankMax, Stats[0], Stats[1]);
		#endif
	}
	else if(Disconnect == 1)
	{
		#if AMXX_VERSION_NUM < 183
			ColorChat(0, GREEN, "[Rank]^3 %s^1 a iesit, rank %d din %d.", Name, RankPos, RankMax);
		#else
			client_print_color(0, print_team_default, "^4[Rank]^3 %s^1 a ieșit, rank %d din %d.", Name, RankPos, RankMax);
		#endif
	}
		
	return;
}

public showRank(Index, Target) {
	new Rank = get_pcvar_num(CvarRank);
	
	if (Rank == 0) 
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(Index, GREEN, "[Rank]^1 Rank-ul este dezactivat.");
		#else
			client_print_color(Index, print_team_default, "^4[Rank]^1 Rank-ul este dezactivat.");
		#endif
		
		return;
	}
	
	new Stats[8], BodyHits[8], RankPos, RankMax, Name[MAX_NAME_LENGTH];
	
	RankMax = get_statsnum();
	
	if (Index == Target) 
	{
		RankPos = get_user_stats(Index, Stats, BodyHits);
		get_user_name(Index, Name, charsmax(Name));
		
		if (RankPos <= 0) // @note The permanent storage is updated on every respawn or client disconnect.
		{
			#if AMXX_VERSION_NUM < 183 
				ColorChat(Index, GREEN, "[Rank]^3 %s^1, nu ai fost gasit in stats."); 
			#else
				client_print_color(Index, print_team_default, "^4[Rank]^3 %s^1, nu ai fost găsit în stats.");
			#endif
			
			return;
		}
		
		if(Rank == 2)
		{
			#if AMXX_VERSION_NUM < 183 
				ColorChat(Index, GREEN, "[Rank]^3 %s^1, te afli pe locul^3 %d^1 din^3 %d^1 cu^3 %d^1 fraguri si^3 %d^1 decese.", Name, RankPos, RankMax, Stats[0], Stats[1]);
			#else
				client_print_color(Index, print_team_default, "^4[Rank]^3 %s^1, te afli pe locul^3 %d^1 din^3 %d^1 cu^3 %d^1 fraguri și^3 %d^1 decese.", Name, RankPos, RankMax, Stats[0], Stats[1]);
			#endif
			
		}
		else if (Rank == 1)
		{
			#if AMXX_VERSION_NUM < 183 
				ColorChat(Index, GREEN, "[Rank]^3 %s^1, te afli pe locul %d din %d",Name, RankPos, RankMax);
			#else
				client_print_color(Index, print_team_default, "^4[Rank]^3 %s^1, te afli pe locul %d din %d",Name, RankPos, RankMax);
			#endif
		}
		
		return;
	}
	
	if (!is_user_connected(Target) || !Target) 
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(Index, GREEN, "[Rank]^1 Acest jucator nu este conectat.");
		#else
			client_print_color(Index, print_team_default, "^4[Rank]^1 Acest jucător nu este conectat.");
		#endif
		
		return;
	}

	RankPos = get_user_stats(Target, Stats, BodyHits);
	get_user_name(Target, Name, charsmax(Name));
	
	if (RankPos <= 0) // @note The permanent storage is updated on every respawn or client disconnect.
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(Index, GREEN, "[Rank]^1 Jucatorul nu a fost gasit in stats."); 
		#else
			client_print_color(Index, print_team_default, "^4[Rank]^1 Jucătorul nu a fost găsit în stats.");
		#endif
		
		return;
	}
	
	if (Rank == 2)
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(Index, GREEN, "[Rank]^3 %s^1 se afla pe locul^3 %d^1 din^3 %d^1 cu^3 %d^1 fraguri si^3 %d^1 decese.", Name, RankPos, RankMax, Stats[0], Stats[1]);
		#else
			client_print_color(Index, print_team_default, "^4[Rank]^3 %s^1 se află pe locul^3 %d^1 din^3 %d^1 cu^3 %d^1 fraguri și^3 %d^1 decese.", Name, RankPos, RankMax, Stats[0], Stats[1]);
		#endif
	}
	else if (Rank == 1)
	{
		#if AMXX_VERSION_NUM < 183
			ColorChat(Index, GREEN, "[Rank]^3 %s^1 se afla pe locul %d din %d.", Name, RankPos, RankMax);
		#else
			client_print_color(Index, print_team_default, "^4[Rank]^3 %s^1 se află pe locul %d din %d.", Name, RankPos, RankMax);
		#endif
	}
}

public showRankStats(Index, Target) 
{
	if (get_pcvar_num(CvarRankStats) == 0) 
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(Index, GREEN, "[RankStats]^1 RankStats este dezactivat.");
		#else
			client_print_color(Index, print_team_default, "^4[RankStats]^1 RankStats este dezactivat.");
		#endif
		
		return;
	}
	
	new Buffer[2368], Name[MAX_NAME_LENGTH], Len, RankPos, Stats[8], BodyHits[8];
	
	Len = copy(Buffer, charsmax(Buffer), "<meta charset=utf-8><style>body{background:#112233;font-family:Arial}th{background:#2E2E2E;color:#FFF;padding:5px 2px;text-align:center}td{padding:5px 2px}table{width:50%%;background:#EEEECC;font-size:12px;}h2{color:#FFF;font-family:Verdana;text-align:center}#c{background:#E2E2BC}</style>");
	
	new RankMax = get_statsnum();
	RankPos = get_user_stats(Index, Stats, BodyHits);
	
	if (RankPos <= 0) // @note The permanent storage is updated on every respawn or client disconnect.
	{
		#if AMXX_VERSION_NUM < 183 
			ColorChat(Index, GREEN, "[RankStats]^1 %s gasit in stats.", Index == Target ? "Nu ai fost" : "Jucatorul nu a fost"); 
		#else
			client_print_color(Index, print_team_default, "^4[RankStats]^1 %s găsit în stats.", Index == Target ? "Nu ai fost" : "Jucatorul nu a fost");
		#endif
		
		return;
	}
	
	get_user_name(Target, Name, charsmax(Name));
	
	if (Index == Target) 
	{
		Len += formatex(Buffer[Len], charsmax(Buffer)-Len, "<h2>Te afli pe locul %d din %d</h2>",RankPos, RankMax);
	}
	else 
	{	
		if (!is_user_connected(Target) || !Target) 
		{
			#if AMXX_VERSION_NUM < 183 
				ColorChat(Index, GREEN, "[RankStats]^1 Acest jucator nu este conectat.");
			#else
				client_print_color(Index, print_team_default, "^4[RankStats]^1 Acest jucător nu este conectat.");
			#endif
			
			return;
		}
		
		Len += formatex(Buffer[Len], charsmax(Buffer)-Len,"<h2>%s se afla pe locul %d din %d.</h2>", Name, RankPos, RankMax);
	}
	
	new ServerName[64];
	get_cvar_string("hostname", ServerName, charsmax(ServerName));
	
	Len = add(Buffer, charsmax(Buffer), "<table border=^"0^" align=^"center^" cellpadding=^"0^" cellspacing=^"1^"><tbody>");
	
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr><th colspan=^"2^">Statistici %s", Name);
	
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr id=^"c^"><td>Ucideri<td>%d (cu %d HS)", Stats[0], Stats[2]);
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr><td>Deaths<td>%d", Stats[1]);
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr id=^"c^"><td>Hits<td>%d", Stats[5]);
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr><td>Shots<td>%d", Stats[4]);
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr id=^"c^"><td>Damage(HP)<td>%d", Stats[6]);
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr><td>ACC. (%)<td>%.02f%", getAccuracy(Stats));
	Len += formatex(Buffer[Len], charsmax(Buffer), "<tr id=^"c^"><td>EFF.<td>%.02f%", getEfficiency(Stats));
	formatex(Buffer[Len], charsmax(Buffer), "<tr><th colspan=^"2^">%s", ServerName);
	
	add(Buffer, charsmax(Buffer), "</tbody></table></body>");
	show_motd(Index, Buffer, "Top jucatori");
}

Float:getAccuracy(Stats[8])
{
	if(!Stats[4])
	{
		return (0.0);
	}
	
	return (100.0 * float(Stats[5]) / float(Stats[4]));
}

Float:getEfficiency(Stats[8])
 {
	if(!Stats[0])
	{
		return (0.0);
	}
	
	return (100.0 * float(Stats[0]) / float(Stats[0] + Stats[1]));
}

public showTop(Index, TopCount) 
{
	new Max = get_statsnum();
	new Nr = get_pcvar_num(CvarTopNum);
	
	if (TopCount <= 0)
	{
		TopCount = 10;
	}
	
	if (Nr != 10 && Nr != 15)
	{
		return;
	}
	
	new Start;
		
	if (TopCount > 0 && TopCount < 16) 
	{
		TopCount = Nr;
	}
	else 
	{
		if(TopCount > Max)
		{
			TopCount = Max;
		}
		else	
		{
			Start = TopCount - Nr;
		}
	}
			
	new TitleData[128];
	new Title = get_pcvar_string(CvarTitle, TitleData, charsmax(TitleData));
		
	new Buffer[2368], Name[MAX_NAME_LENGTH*4], BodyHits[8], Len, Stats[8];
		
	formatex(Buffer, charsmax(Buffer), "<meta charset=utf-8><style>body{background:#112233;font-family:Arial}th{background:#2E2E2E;color:#FFF;padding:5px 2px;text-align:left}td{padding:5px 2px}table{width:100%%;background:#EEEECC;font-size:12px;}h2{color:#FFF;font-family:Verdana;text-align:center}#nr{text-align:center}#c{background:#E2E2BC}</style><h2>%s</h2><table border=^"0^" align=^"center^" cellpadding=^"0^" cellspacing=^"1^"><tbody>", Title);
	Len = add(Buffer, charsmax(Buffer), "<tr><th id=nr>#</th><th>Name<th>Kills<th>Deaths<th>HS<th>Skill");
		
	for (new i = Start; i < TopCount; i++) 
	{
		get_user_name(Index, Name, charsmax(Name)/4);
		get_stats(i, Stats, BodyHits, Name, charsmax(Name)/4);
			
		new Float:Skill[8];
		for (new j = 0; j < sizeof(Stats); j++)
		{
			Skill[j] = float(Stats[j]);
		}
		
		#if AMXX_VERSION_NUM < 183 
			replace_all(Name, charsmax(Name), "<", "&lt;");
			replace_all(Name, charsmax(Name), ">", "&gt;");
		#else
			replace_string(Name, charsmax(Name), "<", "&lt;");
			replace_string(Name, charsmax(Name), ">", "&gt;");
		#endif

		Len += formatex(Buffer[Len], charsmax(Buffer), "<tr %s><td id=nr>%d<td>%s<td>%d<td>%d<td>%d<td>%.02f",((i%2)==0) ? "" : " id=c", (i+1), Name, Stats[0], Stats[1], Stats[2], ((Skill[0]-Skill[1])+Skill[2])/2);
	}
		
	new ServerName[64];
	get_cvar_string("hostname", ServerName, charsmax(ServerName));
	
	formatex(Buffer[Len], charsmax(Buffer), "<tr><th colspan=^"7^" id=nr>%s", ServerName);	
	add(Buffer, charsmax(Buffer), "</tbody></table></body>");
	
	show_motd(Index, Buffer, "Top jucatori");
}