#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
 
#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new const Tag[] = "^1*^4Change Tero^1:";
const TrialReviveTask = 9234;
const TeroCourseTask  = 9235;

new Swaped, Asked,Refuses, Responsed, InNewTeroCourse;
new bool:EndRound, bool:Rejected;
 
public plugin_init() 
{ 
	register_plugin
	(
		.plugin_name = "Change Tero",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_clcmd("say", "hookChat");
	register_event("HLTV", "newRound", "a", "1=0", "2=0");
	
	register_logevent("endRound", 2, "1=Round_End");
}

public endRound()
{
	EndRound = true;
}

public client_disconnected(Index)
{
	DelBit(Swaped, Index);
	DelBit(Responsed, Index);
	DelBit(Asked, Index);
	DelBit(InNewTeroCourse, Index);
	
	new Players[MAX_PLAYERS], MatchedPlayers;
	get_players(Players, MatchedPlayers, "ce", "TERRORIST");
	if (MatchedPlayers == 1) // in unele situatii detecteaza ca este pe server, in altele nu-l detecteaza, conteaza cum se deconecteaza.
	{
		if (Players[0] == Index)
		{
			MatchedPlayers = 0;
		}
	}
	if (MatchedPlayers == 0)
	{
		setNewTerrorist(Index);
		
		Refuses = Responsed = InNewTeroCourse = 0;
		Rejected = false;
		
		if (task_exists(TeroCourseTask))
		{
			remove_task(TeroCourseTask);
		}
	}
}

public newRound()
{
	Swaped = Responsed = Asked = Refuses = InNewTeroCourse = 0;
	EndRound = Rejected = false;
	
	if (task_exists(TeroCourseTask))
	{
		remove_task(TeroCourseTask);
	}
}

public hookChat(Index)
{
	new Said[32];
	read_args(Said, charsmax(Said));
	
	if ( !Said[0] )
	{
		return PLUGIN_CONTINUE;
	}
	
	new const NewTero[] = "!newtero", SwapTero[] = "!swaptero";
	
	remove_quotes(Said);
	
	if (Said[0] != '!')
	{
		return PLUGIN_CONTINUE;
	}
	
	if (equali(Said, NewTero, charsmax(NewTero)))
	{
		client_print_color(Index, print_team_red, "%s ^3Această opțiune a fost oprită, temporar sau permanent.", Tag);
		return PLUGIN_HANDLED;
		/*
		if (cs_get_user_team(Index) != CS_TEAM_T)
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda decât când eşti Terorist.", Tag);
			return PLUGIN_HANDLED;
		}
		if (task_exists(TrialReviveTask, any:true))
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda acum deoarece se alege un Trial-Revive.", Tag);
			return PLUGIN_HANDLED;
		}
		if (task_exists(TeroCourseTask))
		{
			client_print_color(Index, print_team_red, "%s ^3Ai folosit deja comanda, aşteaptă rezultatul !", Tag);
			return PLUGIN_HANDLED;
		}
		if (Rejected)
		{
			client_print_color(Index, print_team_red, "%s ^3Ei bine nimeni nu vrea să-ți ia locul, din păcate vei rămâne Terorist!", Tag);
			return PLUGIN_HANDLED;
		}
		if (GetBit(Swaped, Index))
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda dacă ai facut swap !", Tag);
			return PLUGIN_HANDLED;
		}
		if (GetBit(Asked, Index))
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda până când nu răspunzi la solicitarea de swap.", Tag);
			return PLUGIN_HANDLED;
		}
		
		new Players[MAX_PLAYERS], PlayersMatched;
		get_players(Players, PlayersMatched, "ce", "CT");
		
		if (PlayersMatched == 0)
		{
			client_print_color(Index, print_team_default, "%s ^3Nu poți folosi comanda decât dacă este minim un Counter!", Tag);
			return PLUGIN_HANDLED;
		}
		
		if (EndRound)
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda acum !", Tag);
			return PLUGIN_HANDLED;
		}
		
		showMenu(Players, PlayersMatched);
		client_print_color(Index, print_team_default, "%s ^3Ai pornit cursa pentru alegerea unui nou Terorist !", Tag);
		*/
	}
	
	if (equali(Said, SwapTero, charsmax(SwapTero)))
	{
		if (cs_get_user_team(Index) != CS_TEAM_CT)
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda decât când eşti Counter.", Tag);
			return PLUGIN_HANDLED;
		}
		
		if (task_exists(TeroCourseTask))
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda deoarece Teroristul a solicitat deja schimbarea sa!", Tag);
			return PLUGIN_HANDLED;
		}

		if (GetBit(Responsed, Index))
		{
			client_print_color(Index, print_team_red, "%s ^3Teroristul te-a refuzat deja.", Tag);
			return PLUGIN_HANDLED;
		}
		
		if (GetBit(Swaped, Index))
		{
			client_print_color(Index, print_team_red, "%s ^3Dacă ai făcut switch nu mai poți să ajungi tero !", Tag);
			return PLUGIN_HANDLED;
		}
		
		if (Refuses == 3)
		{
			client_print_color(Index, print_team_red, "%s ^3Teroristul nu doreşte să facă switch !", Tag);
			return PLUGIN_HANDLED;
		}
		
		if (EndRound)
		{
			client_print_color(Index, print_team_red, "%s ^3Nu poți folosi comanda acum !", Tag);
			return PLUGIN_HANDLED;
		}
		
		new Players[MAX_PLAYERS], PlayersMatched;
		get_players(Players, PlayersMatched, "ace", "TERRORIST");
		new TeroIndex = Players[random_num(0, PlayersMatched - 1)];
		
		if (PlayersMatched == 0)
		{
			client_print_color(Index, print_team_default, "%s ^3Nu poți folosi comanda decât dacă este minim un Terorist în viață!", Tag);
			return PLUGIN_HANDLED;
		}
		
		if (GetBit(Asked, TeroIndex))
		{
			client_print_color(Index, print_team_red, "%s ^3Teroristul este întrebat de o altă persoană dacă vrea să cedeze locul.", Tag);
			return PLUGIN_HANDLED;
		}
		
		swapTeroMenu(Index, TeroIndex);
	}
	
	return PLUGIN_CONTINUE;
}
/*
showMenu(Players[32], PlayersMatched)
{
	new Menu = menu_create("Vrei să intri în cursa pentru înlocuirea Teroristului ?", "courseAnswer"), Counter;
	menu_additem(Menu, "Nu");
	menu_additem(Menu, "Da");
	for (new i = 0; i < PlayersMatched; ++i)
	{
		if (!GetBit(Swaped, Players[i]))
		{
			menu_display(Players[i], Menu, 0, 10);
			Counter++;
		}
	}
	
	if (Counter == 0)
	{
		for (new i = 0; i < PlayersMatched; ++i)
		{
			menu_display(Players[i], Menu, 0, 7);
		}
	}
	
	set_task(8.0, "ChooseWinner", TeroCourseTask);
}

public courseAnswer(Index, Menu, Item)
{
	if (InNewTeroCourse == 0)
	{
		if (task_exists(TeroCourseTask))
		{
			remove_task(TeroCourseTask);
		}
		return;
	}
	if (Item == MENU_TIMEOUT)
	{
		client_print_color(Index, print_team_red, "%s ^3Se pare că nu ai raspuns la timp, mai multă atenție data viitoare.", Tag);
	}
	if (Item == 1)
	{
		SetBit(InNewTeroCourse, Index);
		client_print(0, print_console, "%d -", Index);
	}
}

public ChooseWinner()
{	
	if (!InNewTeroCourse)
	{
		client_print_color(0, print_team_red, "%s ^3Nu a optat nimeni pentru înlocuirea Teroristului.", Tag);
		Rejected = true;
		return;
	}
	
	new Competitors[MAX_PLAYERS], Counter = 0;
	for(new i = 1; i <= MAX_PLAYERS; ++i)
	{
		if (GetBit(InNewTeroCourse, i))
		{
			client_print(0, print_console, "%d +", Competitors[Counter]);
			Competitors[Counter++] = i;
		}
	}
	
	new Index = Competitors[random_num(0, Counter - 1)];
	
	new Players[MAX_PLAYERS], PlayersMatched, Name[MAX_NAME_LENGTH], TeroName[MAX_NAME_LENGTH];
	get_players(Players, PlayersMatched, "ace", "TERRORIST");
	new TeroIndex = Players[random_num(0, PlayersMatched - 1)];
	
	get_user_name(Index, Name, charsmax(Name));
	get_user_name(TeroIndex, TeroName, charsmax(TeroName));
	
	swapTero(Index, TeroIndex);
	SetBit(Swaped, TeroIndex);
	
	client_print_color(0, print_team_red, "%s ^4%s^3 a fost ales aleator să-l înlocuiască pe ^4%s^3.", Tag, Name, TeroName);
	InNewTeroCourse = 0;
}*/

swapTero(Index, TeroIndex)
{
	cs_set_user_team(Index ,CS_TEAM_T);		
	cs_set_user_team(TeroIndex ,CS_TEAM_CT);
			
	if (is_user_alive(Index))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, TeroIndex);
		new Origin[3];
		get_user_origin(Index, Origin, 0);
		Origin[2] += 20;
       
		set_user_origin(TeroIndex, Origin);
		ExecuteHamB(Ham_CS_RoundRespawn, Index);
	}
	else
	{
		ExecuteHamB(Ham_CS_RoundRespawn, Index);
		user_silentkill(TeroIndex);
	}
}

swapTeroMenu(Index, TeroIndex)
{
	new MenuBuffer[64], Name[MAX_NAME_LENGTH], InfoString[3];
	num_to_str(Index, InfoString, charsmax(InfoString));
	get_user_name(Index, Name, charsmax(Name));
	formatex(MenuBuffer, charsmax(MenuBuffer), "\d%s doreşte sa te înlocuiască\y:", Name);
	
	new Menu = menu_create(MenuBuffer, "askTero");
	menu_additem(Menu, "Refuză", InfoString);
	menu_additem(Menu, "Acceptă", InfoString);
	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(TeroIndex, Menu, 0, 10);
	
	SetBit(Asked, TeroIndex);
	
	set_task(10.5, "timeOut", Index*100+TeroIndex);
}

public timeOut(Index)
{
	new TeroIndex = Index % 100, Name[MAX_NAME_LENGTH];
	Index /= 100;
	get_user_name(TeroIndex, Name, charsmax(Name));
	client_print_color(Index, print_team_red, "%s ^4%s^3 nu ai răspuns la timp ofertei tale.", Tag, Name);
	DelBit(Asked, TeroIndex);
}

public askTero(TeroIndex, Menu, Item)
{
	if (!is_user_connected(TeroIndex))
	{
		new InfoString[3], TeroName[MAX_NAME_LENGTH], Access, CallBack;
		menu_item_getinfo(Menu, Item, Access, InfoString, charsmax(InfoString), _, _, CallBack);
		new Index = str_to_num(InfoString);
			
		client_print_color(Index, print_team_red, "%s ^3 Terrorsistul s-a deconectat. #%d", Tag, TeroName, Index);
		return;
	}
	
	if (cs_get_user_team(TeroIndex) != CS_TEAM_T)
	{
		menu_destroy(Menu);
		return;
	}
	
	switch(Item)
	{
		case MENU_EXIT: 
		{
			menu_destroy(Menu);
		}
		case MENU_TIMEOUT:
		{
			client_print_color(TeroIndex, print_team_red, "%s ^3Se pare că nu ai răspuns la timp, oferta a expirat.", Tag);
		}
		case 0:
		{
			new InfoString[3], TeroName[MAX_NAME_LENGTH], Access, CallBack;
			menu_item_getinfo(Menu, Item, Access, InfoString, charsmax(InfoString), _, _, CallBack);
			new Index = str_to_num(InfoString);
			get_user_name(TeroIndex, TeroName, charsmax(TeroName));
			
			client_print_color(Index, print_team_red, "%s ^4%s^3 a refuzat să îți ia locul.", Tag, TeroName);
			Refuses++;
			SetBit(Responsed, Index);
			
			if (task_exists(Index*100+TeroIndex))
			{
				remove_task(Index*100+TeroIndex);
			}
		}
		case 1:
		{
			new InfoString[3], Name[MAX_NAME_LENGTH], TeroName[MAX_NAME_LENGTH], Access, CallBack;
			menu_item_getinfo(Menu, Item, Access, InfoString, charsmax(InfoString), _, _, CallBack);
			new Index = str_to_num(InfoString);
			if (cs_get_user_team(Index) != CS_TEAM_CT)
			{
				client_print_color(TeroIndex, print_team_red, "%s ^3Ne pare rău, însă cel care te-a ofertat nu mai este CT.", Tag);
				return;
			}
			get_user_name(Index, Name, charsmax(Name));
			get_user_name(TeroIndex, TeroName, charsmax(TeroName));
			
			swapTero(Index, TeroIndex);
			
			static ScoreAttrib;
			if (ScoreAttrib == 0)
			{
				ScoreAttrib = get_user_msgid("ScoreAttrib")
			}
			message_begin(MSG_BROADCAST, ScoreAttrib);
			write_byte(Index);
			write_byte(0);
			message_end();
			
			SetBit(Swaped, Index);
			SetBit(Swaped, TeroIndex);
			Refuses = Responsed = 0;
			
			client_print_color(0, print_team_red, "%s ^4%s^3 i-a cedat locul lui^4 %s^3.", Tag, TeroName, Name);
			
			if (task_exists(Index*100+TeroIndex))
			{
				remove_task(Index*100+TeroIndex);
			}
		}
	}
	DelBit(Asked, TeroIndex);
}

setNewTerrorist(OldTerrorIndex)
{
	if (get_playersnum() <= 1)
	{
		return;
	}
	
	new Players[MAX_PLAYERS], MatchedPlayers;
	get_players(Players, MatchedPlayers, "bce", "CT");
	if (MatchedPlayers == 0)
	{
		get_players(Players, MatchedPlayers, "ce", "CT");
		if (MatchedPlayers == 0)
		{
			return;
		}
	}
	new NewTerorIndex = Players[random(MatchedPlayers)];
	cs_set_user_team(NewTerorIndex, CS_TEAM_T);
	ExecuteHamB(Ham_CS_RoundRespawn, NewTerorIndex);
	new OldTerrorName[MAX_NAME_LENGTH], NewTerrorName[MAX_NAME_LENGTH];
	get_user_name(OldTerrorIndex, OldTerrorName, charsmax(OldTerrorName));
	get_user_name(NewTerorIndex, NewTerrorName, charsmax(NewTerrorName));
	client_print_color(0, print_team_red, "%s ^4%s^3 este noul terorist deoarece ^4%s^3 s-a deconectat.", Tag, NewTerrorName, OldTerrorName);
}