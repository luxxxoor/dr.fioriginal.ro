#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#pragma semicolon 1

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

const TrialReviveTask = 9234;

new TrialReviveName[MAX_NAME_LENGTH];
new TrialReviveTime, InTrialReviveCourse, TimeLeft;
new bool:Competition;
public TrialReviveIndex = -1, UsedRevive;

public plugin_init()
{	
	register_plugin
	(
		.plugin_name = "The new revive",
		.version     = "2.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_concmd("amx_revive", "commandRevive");
	register_clcmd("say", "hookChat");
	register_event("HLTV", "newRound", "a", "1=0", "2=0") ;
	register_event("DeathMsg", "clientDeath", "a");
	RegisterHam(Ham_Spawn, "player", "spawnCheck", 1);
	
	set_task(35.0, "afisareChat", _, _, _, "b", 0);
	TrialReviveTime = random_num(3, 7);
}

public spawnCheck(Index)
{
	if(!is_user_alive(Index))
	{
		return;
	}
	
	if (Index == TrialReviveIndex || get_user_flags(Index) & ADMIN_LEVEL_H)
	{
		return;
	}
	
	if (TimeLeft - get_timeleft() <= 20)
	{
		return;
	}
}
/*
public silentSlayClient(Index)
{
	user_silentkill(Index);
}
*/

public newRound() 
{
	UsedRevive = 0;
	TimeLeft = get_timeleft();
}

public clientDeath()
{
	if (UsedRevive == 0)
	{
		return;
	}
	
	new Players[MAX_PLAYERS], MatchedPlayers, bool:DidNotUsedRevive;
	get_players(Players, MatchedPlayers, "ache", "CT");
	for (new i = 0; i < MatchedPlayers; ++i)
	{
		if (!GetBit(UsedRevive, Players[i]))
		{
			DidNotUsedRevive = true;
			break;
		}
	}
	if (!DidNotUsedRevive)
	{
		for (new i = 0; i < MatchedPlayers; ++i)
		{
			UsedRevive = 0;
			user_silentkill(Players[i]);
		}
		client_print_color(0, print_team_red, "^4[^3AMX_REVIVE^4]^1 Ne pare rău dar toti jucatorii au murit, cei care au dat ^4revive^1 au primit slay.");
	}
}

public commandRevive(Index)
{
	if (!(get_user_flags(Index) & ADMIN_IMMUNITY))
	{
		return PLUGIN_HANDLED;
	}
	
	new Argument[32];
	new const AllIndent[] = "#ALL", TeroIdent[] = "#T", CouterIdent[] = "#CT";
	read_argv(1, Argument, charsmax(Argument));
	
	if (Argument[0] == '#' && (get_user_flags(Index) & ADMIN_RCON))
	{ 
		new Players[MAX_PLAYERS], MatchedPlayers;
		if (equal(Argument, AllIndent, charsmax(AllIndent)))
		{    
			get_players(Players, MatchedPlayers);
			for (new i = 0; i <= MatchedPlayers; ++i)
			{
				if (!is_user_bot(Index))
				{
					ExecuteHamB(Ham_CS_RoundRespawn, Players[i]);
				}
			}
						
			return PLUGIN_HANDLED; 
		}
		if (equal(Argument, TeroIdent, charsmax(TeroIdent)))
		{
			get_players(Players, MatchedPlayers, "e", "TERRORIST");   
			for (new i = 0; i <= MatchedPlayers; ++i)
			{
				if (!is_user_bot(Index))
				{
					ExecuteHamB(Ham_CS_RoundRespawn, Players[i]);
				}
			}

			return PLUGIN_HANDLED; 
		}
		if (equal(Argument, CouterIdent, charsmax(CouterIdent)))
		{
			get_players(Players, MatchedPlayers, "e", "CT");        
			for (new i = 0; i <= MatchedPlayers; ++i)
			{
				if (!is_user_bot(Index))
				{
					ExecuteHamB(Ham_CS_RoundRespawn, Players[i]);
				}
			}
			
			return PLUGIN_HANDLED; 
		}
	}
	
	new TargetIndex = cmd_target(Index, Argument, CMDTARGET_NO_BOTS);
	if (!TargetIndex)
	{
		return PLUGIN_HANDLED;
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, TargetIndex);
	
	return PLUGIN_HANDLED;
}

revivePlayer(Index)
{
	if (is_user_alive(Index))
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Ne pare rău dar această comandă o poţi folosi doar cand eşti mort.");
		return; 
	}
	
	if (cs_get_user_team(Index) != CS_TEAM_CT)
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Ne pare rău dar această comandă o poţi folosi doar cand eşti Counter-Terrorist.");
		return; 
	}
	
	static GivedLife, ReviveForce;
	if (GivedLife == 0)
	{
		GivedLife = get_xvar_id("GivedLife");
	}
	if (ReviveForce == 0)
	{
		ReviveForce = get_xvar_id("ReviveForce");
	}
	if (GivedLife != -1 && ReviveForce != -1)
	{
		if (GetBit(get_xvar_num(GivedLife), Index))
		{
			if (GetBit(get_xvar_num(ReviveForce), Index))
			{
				client_print(0, print_console, "miau");
				ExecuteHamB(Ham_CS_RoundRespawn, Index);
				SetBit(UsedRevive, Index);
				client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Deoarece ai dat life în această rundă, vei primi slay când toți jucătorii vor muri.");
			}
			else
			{
				client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Nu poți folosi comanda până când nu trece perioada life-ului.");
			}
			return; 
		}
	}
	
	new Players[MAX_PLAYERS], MatchedPlayers, AllPlayers, Counter;
	get_players(Players, AllPlayers, "ace", "TERRORIST");
	if (AllPlayers == 0)
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Nu poţi să dai revive dacă nu este nici un tero viu.");
		return;
	}
	
	get_players(Players, AllPlayers, "bce", "CT");
	for(new i = 0; i < AllPlayers; ++i)
	{
		if (get_user_flags(Players[i]) & ADMIN_LEVEL_H || Players[i] == TrialReviveIndex)
		{
			++Counter;
		}
	}
	AllPlayers -= Counter; // jucatorii morti fara revive
	get_players(Players, MatchedPlayers, "ace", "CT");

	
	ExecuteHamB(Ham_CS_RoundRespawn, Index);
	
	if ( TrialReviveIndex == Index )
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Ai primit respawn.");
	}
	else
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Ai primit respawn.");
	}
	
	Counter = 0;
	for(new i = 0; i < MatchedPlayers; ++i)
	{
		if (get_user_flags(Players[i]) & ADMIN_LEVEL_H || Players[i] == TrialReviveIndex)
		{
			++Counter;
		}
	}
	MatchedPlayers -= Counter;

	if (MatchedPlayers <= (AllPlayers+MatchedPlayers)/4)
	{
		SetBit(UsedRevive, Index);
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Sunt mai puțin de un sfert din jucători in viață, vei primi slay când toți jucătorii vor muri.");
	}
}

public client_infochanged(Index)
{
	if (!is_user_connected(Index))
	{
		return PLUGIN_CONTINUE;
	}
	
	if (TrialReviveIndex == Index)
	{
		get_user_info(Index, "name", TrialReviveName, charsmax(TrialReviveName));
	}
	
	return PLUGIN_CONTINUE;
}

public client_disconnected(Index)
{	
	if (TrialReviveIndex == Index)
	{
		TrialReviveIndex = -1;
		InTrialReviveCourse = 0;
		client_print_color(0, print_team_red, "^4[^3AMX_REVIVE^4]^1 %s s-a deconectat. Curând se va alege un nou Trial-Revive.", TrialReviveName);
	}
	DelBit(InTrialReviveCourse, Index);
}

public hookChat(Index)
{
	new Said[192];
	read_args(Said, charsmax(Said));
	
	if (!Said[0])
	{
		return PLUGIN_CONTINUE;
	}
	
	new const TrialReviveIdent[] = "!trialrevive", ReviveIdent[] = "!revive", CompetitionIdent[] = "!concurs";
		
	remove_quotes(Said);
	
	if (equal(Said, TrialReviveIdent, charsmax(TrialReviveIdent)) && (get_user_flags(Index) & ADMIN_LEVEL_H))
	{
		if (Competition)
		{
			client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Acest beneficiu este suspendat pe durata concursului.");
			return PLUGIN_HANDLED;
		}
		if (TrialReviveIndex != -1)
		{
			client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Trial-Revive-ul a fost acordat deja lui %s.", TrialReviveName);
		}
		else
		{
			client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Încă nu a fost acordat Trial-Revive-ul.");
		}
		return PLUGIN_HANDLED;
	}
	
	if (equal(Said, ReviveIdent, charsmax(ReviveIdent)))
	{
		if (Competition)
		{
			client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Acest beneficiu este suspendat pe durata concursului.");
			return PLUGIN_HANDLED;
		}
		if (get_user_flags(Index) & ADMIN_LEVEL_H || Index == TrialReviveIndex)
		{
			revivePlayer(Index);
			return PLUGIN_HANDLED;
		}
	}
	
	if(equal(Said, CompetitionIdent, charsmax(CompetitionIdent)) && get_user_flags(Index) & ADMIN_IMMUNITY)
	{
		if (Competition)
		{
			Competition = false;
		}
		else
		{
			Competition = true;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public afisareChat()
{
	if (TrialReviveIndex == -1 && !Competition)
	{
		new timelimit = get_cvar_pointer("mp_timelimit");
		if ( get_timeleft() / 60 + TrialReviveTime <= get_pcvar_num(timelimit) )
		{
			showMenu();
		}
		else
		{
			client_print_color(0, print_team_red, "^4[^3AMX_REVIVE^4]^1 Pregăteşte-te Trial-Revive va fi activat în curând !");
		}
	}
	else
	{
		if (TrialReviveIndex != -1 && get_user_flags(TrialReviveIndex) & ADMIN_LEVEL_H)
		{
			client_print_color(TrialReviveIndex, print_team_red, "^4[^3AMX_REVIVE^4]^1 Deoarece s-a depistat ca ai Revive, ti s-a anulat Trial-Revive.");
			TrialReviveIndex = -1;
		}
	}
}

showMenu()
{
	new Menu = menu_create("Vrei să intri în cursa pentru Trial-Revive ?", "ChoosedAnswer");
	menu_additem(Menu, "Nu");
	menu_additem(Menu, "Da");
	new Players[MAX_PLAYERS], MatchedPlayers;
	get_players(Players, MatchedPlayers, "ch");
	for (new i = 0; i < MatchedPlayers; ++i)
	{
		if (!(get_user_flags(Players[i]) & ADMIN_LEVEL_H))
		{
			menu_display(Players[i], Menu, 0, 10);
		}
	}
	
	set_task(15.0, "ChooseWinner", TrialReviveTask);
}

public ChoosedAnswer(Index, Menu, Item)
{
	if (Item == MENU_TIMEOUT)
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Se pare că nu ai raspuns la timp, mai multă atenție data viitoare.");
	}
	if (Item == 1)
	{
		SetBit(InTrialReviveCourse, Index);
	}
}

public ChooseWinner()
{
	if (!InTrialReviveCourse)
	{
		return;
	}
	
	new Competitors[MAX_PLAYERS], Counter = 0;
	for(new i = 1; i <= 32; ++i)
	{
		if (GetBit(InTrialReviveCourse, i))
		{
			Competitors[Counter++] = i;
		}
	}
	
	TrialReviveIndex = Competitors[random_num(0, Counter - 1)];
	
	if (get_user_flags(TrialReviveIndex) & ADMIN_LEVEL_H)
	{
		DelBit(InTrialReviveCourse, TrialReviveIndex);
		ChooseWinner();
		return;
	}
	
	get_user_name(TrialReviveIndex, TrialReviveName, charsmax(TrialReviveName));
	client_print_color(0, print_team_red, "^4[^3AMX_REVIVE^4]^1 %s a câştigat un Trial-Revive. Acesta poate folosi comanda !revive pe parcursul acestei hărţi.", TrialReviveName);
	client_print_color(TrialReviveIndex, print_team_red, "^4[^3AMX_REVIVE^4]^1 Scrie în chat !revive pentru a folosi comanda de revive.");
}