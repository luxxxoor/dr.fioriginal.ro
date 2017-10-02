#include <amxmisc>
#include <cstrike>
#include <hamsandwich>

enum _:RaceType
{
	idAsker,
	idAccepter
}

const MaxRaces = 16;

#define BitSet(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define BitClear(%1,%2) (%1 &= ~(1 << (%2 & 31))) 
#define BitGet(%1,%2)   (%1 & (1 << (%2 & 31)))

new bool:InRace[MaxRaces], isnotAfk, score[MaxRaces][RaceType], Competitors[MaxRaces][RaceType], Rounds[MaxRaces], Races;
new bool:StartRace[MaxRaces];
public raceIds;

public plugin_init()
{
	register_plugin("Race Plugin", "1.0", "Dr.FioriGinal.Ro");
	register_clcmd("say", "hookChat");
	register_clcmd("say_team", "hookChat");
	
	RegisterHam(Ham_TakeDamage, "player", "takeDamage");
	register_logevent("roundStart", 2, "1=Round_Start");
}

public roundStart() 
{
	if ( !Races )
	{
		return;
	}
	new bool:Tero;
	for (new i = 0, j = 1; i < MaxRaces && j <= Races ; ++i)
	{
		if ( InRace[i] )
		{
			++j;
		}
		else
		{
			continue;
		}
		if ( !StartRace[i] )
		{
			StartRace[i] = true;
			client_print_color(Competitors[i][idAsker], print_team_blue, "^4[^3Race Plugin^4] Race-ul a inceput !");
			client_print_color(Competitors[i][idAccepter], print_team_blue, "^4[^3Race Plugin^4] Race-ul a inceput !");
			continue;
		}
		if ( !Tero )
		{
			if ( cs_get_user_team(Competitors[i][idAsker]) == CS_TEAM_T || cs_get_user_team(Competitors[i][idAccepter]) == CS_TEAM_T )
			{
				Tero = true;
				continue;
			}
		}
		if ( ++Rounds[i] == 5 )
		{
			new name[MAX_NAME_LENGTH], name2[MAX_NAME_LENGTH];
			get_user_name(Competitors[i][idAsker], name, charsmax(name));
			get_user_name(Competitors[i][idAccepter], name2, charsmax(name2));
			
			if ( score[i][idAsker] < score[i][idAccepter] )
			{
				client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s a castigat race-ul cu %d-%d contra lui %s.", name2, score[i][idAccepter], score[i][idAsker], name);
			}
			else
			{
				if ( score[i][idAsker] == score[i][idAccepter] )
				{
					client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s si %s au facut egal %d-%d.", name, name2, score[i][idAsker], score[i][idAccepter]);
				}
				else
				{
					client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s a castigat race-ul cu %d-%d contra lui %s.", name,score[i][idAsker], score[i][idAccepter], name2);
				}
			}
			--Races;
			//client_print(0, print_console, "--race in roundstart");
			InRace[i] = false;
			StartRace[i] = false;
		
			BitClear(raceIds, Competitors[i][idAsker]);
			BitClear(raceIds, Competitors[i][idAccepter]);
			return;
		}
	}
	
}

public client_disconnect(id)
{
	if ( BitGet(raceIds, id) )
	{
		//client_print(0, print_console, "debug detetez ca e in bitsum");
		for (new i = 0, j = 1; i < MaxRaces && j <= Races ; ++i)
		{
			if ( InRace[i] )
			{
				++j;
				//client_print(0, print_console, "debug detetez ca e in race");
			}
			else
			{
				continue;
			}
			if ( id == Competitors[i][idAsker] || id == Competitors[i][idAccepter] )
			{
				--Races;
				//client_print(0, print_console, "--race in client_disconnect");
				InRace[i] = false;
				StartRace[i] = false;
				//client_print(0, print_console, "debug curat celula");
				BitClear(raceIds, Competitors[i][idAsker]);
				BitClear(raceIds, Competitors[i][idAccepter]);
				break;
			}
		}
	}
}

public takeDamage( iVictim, inflictor, iAttacker, Float:iDamagee, damagetype )
{
	//client_print(0, print_console, "Races : %d, iVictim %d, iAttacker %d, BitGet ivictim %d, BitGet iAttacker %d",
	//			Races, iVictim, iAttacker, BitGet(raceIds, iVictim), BitGet(raceIds, iAttacker));
	if ( Races && !BitGet(raceIds, iVictim) && BitGet(raceIds, iAttacker) && cs_get_user_team(iVictim) == CS_TEAM_T &&
		cs_get_user_team(iAttacker) == CS_TEAM_CT )
	{
		for (new i = 0, j = 1; i < MaxRaces && j <= Races ; ++i)
		{
			if ( InRace[i] && StartRace[i] )
			{
				++j;
			}
			else
			{
				continue;
			}
			if ( iAttacker == Competitors[i][idAsker] || iAttacker == Competitors[i][idAccepter] )
			{
				user_kill(Competitors[i][idAsker], 1);
				user_kill(Competitors[i][idAccepter], 1);
				if ( iAttacker == Competitors[i][idAsker] )
				{
					new name[MAX_NAME_LENGTH], name2[MAX_NAME_LENGTH];
					get_user_name(Competitors[i][idAsker], name, charsmax(name));
					get_user_name(Competitors[i][idAccepter], name2, charsmax(name2));
					if ( ++score[i][idAsker] == 3 )
					{
						client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s castigat cu 3-%d race-ul contra lui %s !", name, score[i][idAccepter], name2);
						--Races;
						//client_print(0, print_console, "--race in win asker");
						InRace[i] = false;
						StartRace[i] = false;
				
						BitClear(raceIds, Competitors[i][idAsker]);
						BitClear(raceIds, Competitors[i][idAccepter]);
					}
					else
					{
						client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s a punctat !", name);
						client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] Scorul este %s %d-%d %s.", name, score[i][idAsker], score[i][idAccepter], name2);
					}
				}
				else
				{
					new name[MAX_NAME_LENGTH], name2[MAX_NAME_LENGTH];
					get_user_name(Competitors[i][idAsker], name, charsmax(name));
					get_user_name(Competitors[i][idAccepter], name2, charsmax(name2));
					if ( ++score[i][idAccepter] == 3 )
					{
						client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s castigat cu 3-%d race-ul contra lui %s !", name2, score[i][idAsker], name);
						--Races;
						//client_print(0, print_console, "--race in win accepter");
						InRace[i] = false;
						StartRace[i] = false;
				
						BitClear(raceIds, Competitors[i][idAsker]);
						BitClear(raceIds, Competitors[i][idAccepter]);
					}
					else
					{
						client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s a punctat !", name2);
						client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] Scorul este %s %d-%d %s.", name, score[i][idAsker], score[i][idAccepter], name2);
					}
				}
				SetHamParamFloat(4, 0.0);
		
				return HAM_HANDLED;
			}
		}
	}
	
	return HAM_IGNORED;
}  

public hookChat(id)
{
	new args[32];
	read_args(args, charsmax(args));
	
	if ( !args[0] )
	{
		return PLUGIN_CONTINUE;
	}
	
	remove_quotes(args);
	
	new const raceIdent[] = "!race";
	
	if ( equal(args, raceIdent, charsmax(raceIdent)) )
	{
		if ( !(get_user_flags(id) & ADMIN_RESERVATION) ) 
		{
			client_print_color(id, print_team_blue, "^4[^3Race Plugin^4] Ai nevoie de slot pentru a da race cu cineva.");
			return PLUGIN_HANDLED;
		}
		if ( get_timeleft() / 60 < 7 )
		{
			client_print_color(id, print_team_blue, "^4[^3Race Plugin^4] Nu poti incepe un race cand mai sunt 7 minute ramase.");
			return PLUGIN_HANDLED;
		}
		if ( BitGet(raceIds, id) )
		{
			client_print_color(id, print_team_blue, "^4[^3Race Plugin^4] Esti deja intr-o race.");
			return PLUGIN_HANDLED;
		}
		
		raceMenu(id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public raceMenu(id)
{
	new menu = menu_create("Alegeti adversarul :", "raceMenuHandler");
	new players[MAX_PLAYERS], pnum, OutOfRace;
	new name[MAX_NAME_LENGTH], data[10];
	
	get_players(players, pnum, "ch");
	
	for (new i = 0; i < pnum; ++i )
	{
		if ( players[i] == id || BitGet(raceIds, players[i]) || !is_user_admin(players[i]) )
		{
			OutOfRace++;
			//get_user_name(players[i], name, charsmax(name));
			//client_print(0, print_console, "[RP] nume: %s", name);
			continue;
		}
		get_user_name(players[i], name, charsmax(name));
		num_to_str(get_user_userid(players[i]), data, charsmax(data));
		
		menu_additem(menu, name, data);
	}
	
	if ( pnum - OutOfRace == 0 )
	{
		client_print_color(id, print_team_blue, "^4[^3Race Plugin^4] Nu exista competitori pentru race.");
		return;
	}
	
	menu_display(id, menu);
}

public raceMenuHandler(id, menu, item)
{
	if ( item == MENU_EXIT )
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6], name[MAX_NAME_LENGTH];
	new _acces, item_callback;
	menu_item_getinfo(menu, item, _acces, data, charsmax(data), name, charsmax(name), item_callback);
	
	new userid = str_to_num(data);
	new player = find_player("k", userid);
	
	if ( player )
	{
		new name2[MAX_NAME_LENGTH];
		get_user_name(player, name2, charsmax(name2));
		if( BitGet(raceIds, player) )
		{
			client_print_color(id, print_team_blue, "^4[^3Race Plugin^4] %s este deja intr-o race.", name2);
			return PLUGIN_HANDLED;
		}
		new name[MAX_NAME_LENGTH];
		get_user_name(id, name, charsmax(name));
		InRace[Races] = true;
		score[Races][idAccepter] = 0;
		score[Races][idAsker] = 0;
		Competitors[Races][idAsker] = id;
		Competitors[Races][idAccepter] = player;
		BitSet(raceIds, id);
		BitSet(raceIds, player);
		Races++;		
		
		client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s l-a provocat pe %s la un race.", name, name2);
		
		new Text[121];
		formatex(Text, charsmax(Text), "%s te-a provocat la un race :", name);
		new Menu = menu_create(Text, "answerMenu");
               
		formatex(Text, charsmax(Text), "Accept provocarea." );
		menu_additem(Menu, Text, "1", 0);
               
		formatex(Text, charsmax(Text), "Nu multumesc." );
		menu_additem(Menu, Text, "2", 0);
 
		menu_setprop(Menu, MPROP_EXIT , MEXIT_ALL);
		menu_display(player, Menu, 0);
		new index[10];
		BitClear(isnotAfk, player);
		num_to_str(player, index, charsmax(index));
		set_task(15.0, "autoRefuse", Menu, index, charsmax(index));
 
		return PLUGIN_HANDLED;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public autoRefuse(index[], Menu)
{
	new id = str_to_num(index);
	//client_print(0, print_console, "[RP]index : %s", index);
	if ( !BitGet(isnotAfk, id) )
	{
		menu_destroy(Menu);
	}
}

public answerMenu(id, Menu, item)
{
	new CurrentRace;
	for ( new i = 0; i < MaxRaces; ++i )
	{
		if( id == Competitors[i][idAccepter] )
		{
			CurrentRace = i;
			break;
		}
	}
	
	BitSet(isnotAfk, id);
	new name[MAX_NAME_LENGTH], name2[MAX_NAME_LENGTH];
	get_user_name(Competitors[CurrentRace][idAsker], name, charsmax(name));
	get_user_name(Competitors[CurrentRace][idAccepter], name2, charsmax(name2));
	
	if ( item == MENU_EXIT )
	{
		--Races;
		InRace[CurrentRace] = false;
		StartRace[CurrentRace] = false;
		BitClear(raceIds, Competitors[CurrentRace][idAsker]);
		BitClear(raceIds, Competitors[CurrentRace][idAccepter]);
		client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s nu a raspuns provocarii lui %s.", name2, name);
		
		menu_destroy(Menu);
		return PLUGIN_HANDLED;
	}
	
	new data[6];
	new _acces, item_callback;
	menu_item_getinfo(Menu, item, _acces, data, charsmax(data), _, _, item_callback);

	new Key = str_to_num(data);
	
	switch (Key)
	{
		case 1:
		{
			client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s a acceptat provocarea lui %s.", name2, name);
		}
		case 2:
		{
			client_print_color(0, print_team_blue, "^4[^3Race Plugin^4] %s a refuzat provocarea lui %s.", name2, name);
			--Races;
			BitClear(raceIds, Competitors[CurrentRace][idAsker]);
			BitClear(raceIds, Competitors[CurrentRace][idAccepter]);
			StartRace[CurrentRace] = false;
			InRace[CurrentRace] = false;
		}
	}
	
	menu_destroy(Menu);
	return PLUGIN_HANDLED;
}