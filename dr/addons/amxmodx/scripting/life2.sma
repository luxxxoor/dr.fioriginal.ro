#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new bool:Concurs, Race_xVar;

public GivedLife, InUseLife, ReviveForce;

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "Transfer Life",
		.version     = "2.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_clcmd("say", "hookChat");
	
	register_logevent("newRound", 2, "1=Round_Start");
	RegisterHam(Ham_Spawn, "player", "letPlayerUseTranfer");
	RegisterHam(Ham_Killed, "player", "letPlayerUseTranfer");  
	
	Race_xVar = get_xvar_id("raceIds");
}

public client_disconnected(Index)
{
	DelBit(GivedLife, Index);
	DelBit(InUseLife, Index);
	DelBit(ReviveForce, Index);
}

public letPlayerUseTranfer(Index)
{
	DelBit(InUseLife, Index);
}

public newRound()
{
	GivedLife = InUseLife = ReviveForce = 0;
}

public hookChat(Index)
{
	new Said[64];
	read_args(Said, charsmax(Said));
       
	if ( !Said[0] )
		return PLUGIN_CONTINUE;
       
	remove_quotes(Said[0]);
       
	new const GiveLifeIdent[] = "!givelife", LifeIdent[] = "!life", ConcursIdent[] = "!concurs";

	if( equal(Said, ConcursIdent, charsmax(ConcursIdent)) && get_user_flags(Index) & ADMIN_IMMUNITY  )
	{
		if ( Concurs )
		{
			Concurs = false;
		}
		else
		{
			Concurs = true;
		}
	}
       
	if( equal(Said, GiveLifeIdent, charsmax(GiveLifeIdent)) && !Concurs )
	{
		transferLifeMenu(Index, 0);
		return PLUGIN_HANDLED;
	}
	if( equal(Said, LifeIdent, charsmax(LifeIdent)) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 !life ^1 a fost înlocuit cu ^3 !givelife^1!");
		return PLUGIN_HANDLED;
	}
       
	return PLUGIN_CONTINUE;
}

public transferLife(Index, TargetIndex, LifeTransferType)
{
	if ( !is_user_alive(Index) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Trebuie să fii in viaţă!");
		return;
	}	
	if ( cs_get_user_team(Index) != CS_TEAM_CT )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Trebuie să fii in counter!" );
		return;
	}
	if ( GetBit(InUseLife, Index) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu poți da life când ai primit deja life!" );
		return;
	}
	if ( GetBit(GivedLife, Index) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu poți da life decât o singură dată pe rundă!" );
		return;
	}
	
	if( !is_user_connected(TargetIndex) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Jucătorul nu se mai află pe server!");
		return;
	}
       
	if ( is_user_alive(TargetIndex) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Jucătorul este deja in viaţă!");
		return;
	}
       
	if ( get_user_team(Index) != get_user_team(TargetIndex) )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Jucătorul trebuie să fie in aceeași echipă cu tine!");
		return;
	}
    
	new TargetName[MAX_NAME_LENGTH];
	get_user_name(TargetIndex, TargetName, charsmax(TargetName));
	
	if ( Race_xVar != -1 )
	{
		new bits = get_xvar_num(Race_xVar);
		if ( GetBit(bits, Index) )
		{
			client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu poți da life cand ești in race." );
			return;
		}
		if ( GetBit(bits, TargetIndex) )
		{
			client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu îi poti da life lui %s pentru că se află în race.", TargetName);
			return;
		}
	}
	
	new Origin[3], Name[32];
	get_user_name(Index, Name, charsmax(Name));
	
	ExecuteHamB(Ham_CS_RoundRespawn, TargetIndex);
	set_user_health(TargetIndex, get_user_health(Index));
       
	user_silentkill(Index);
       
	get_user_origin(Index, Origin, 0);
	Origin[2] += 20;
       
	set_user_origin(TargetIndex, Origin);
	strip_user_weapons(TargetIndex);
	give_item(TargetIndex, "weapon_knife");
	SetBit(GivedLife, Index);
	SetBit(InUseLife, TargetIndex);
	static UsedRevive;
	if (UsedRevive == 0)
	{
		UsedRevive = get_xvar_id("UsedRevive");
	}
	new Auxiliar = get_xvar_num(UsedRevive);
	if (GetBit(Auxiliar, Index))
	{
		SetBit(Auxiliar, TargetIndex);
		set_xvar_num(UsedRevive, Auxiliar);
	}
    
	new Float:Time;
	switch (LifeTransferType)
	{
		case 0 :
		{
			Time = 15.0;
		}
		case 1 :
		{
			Time = 25.0;
		}
		case 2 :
		{
			Time = 30.0;
		}
		case 3 :
		{
			client_print_color(0, print_team_red, "^4[^3Transfer Life^4]^1 %s i-a dat viața permanent lui %s.", Name, TargetName);
			return;
		}
	}
	client_print_color(0, print_team_red, "^4[^3Transfer Life^4]^1 %s i-a dat viața lui %s pentru %d secunde.", Name, TargetName, floatround(Time));
	new Info[2];
	formatex(Info, charsmax(Info), "%d", LifeTransferType);
	set_task(Time, "transferLifeBack", Index*100+TargetIndex, Info, charsmax(Info));
}

public transferLifeBack(Info[], Indexes)
{
	new Index = Indexes % 100, TargetIndex = Indexes / 100;
	static TrialReviveIndex;
	if (TrialReviveIndex == 0)
	{
		TrialReviveIndex = get_xvar_id("TrialReviveIndex");
	}
	
	if (!is_user_alive(Index))
	{
		if (TargetIndex == get_xvar_num(TrialReviveIndex) || get_user_flags(TargetIndex) & ADMIN_LEVEL_H)
		{
			client_print_color(TargetIndex, print_team_red, "^4[^3Transfer Life^4]^1 Poți folosi folosi din nou ^4!revive^1.");
			SetBit(ReviveForce, TargetIndex);
		}
		return;
	}
	if (!GetBit(InUseLife, Index))
	{
		return;
	}
	if (!is_user_connected(TargetIndex) || !GetBit(GivedLife, TargetIndex))
	{
		return;
	}
	
	if (cs_get_user_team(TargetIndex) == CS_TEAM_T)
	{
		return;
	}
	
	if (TargetIndex == TrialReviveIndex || get_user_flags(TargetIndex) & ADMIN_LEVEL_H)
	{
		SetBit(ReviveForce, TargetIndex);
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, TargetIndex);
	set_user_health(TargetIndex, get_user_health(Index));
	
	user_silentkill(Index);
	new Origin[3], Name[MAX_NAME_LENGTH], TargetName[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name));
	get_user_name(TargetIndex, TargetName, charsmax(TargetName));
	get_user_origin(Index, Origin, 0);
	Origin[2] += 20;
       
	set_user_origin(TargetIndex, Origin);
	strip_user_weapons(TargetIndex);
	give_item(TargetIndex, "weapon_knife");
	DelBit(InUseLife, Index);
	/*
	static UsedRevive;
	if (UsedRevive == 0)
	{
		UsedRevive = get_xvar_id("UsedRevive");
	}
	new Auxiliar = get_xvar_num(UsedRevive);
	if (GetBit(Auxiliar, Index))
	{
		DelBit(Auxiliar, Index);
		set_xvar_num(UsedRevive, Auxiliar);
	}
	*/
	
	new Time;
	new LifeTransferType = str_to_num(Info);
	switch (LifeTransferType)
	{
		case 0 :
		{
			Time = 15;
		}
		case 1 :
		{
			Time = 25;
		}
		case 2 :
		{
			Time = 30;
		}
	}
	
	client_print_color(0, print_team_red, "^4[^3Transfer Life^4]^1 Au trecut %d secunde, %s i-a dat viața inapoi lui %s .", Time, Name, TargetName);
}

transferLifeMenu(Index, LifeTransferType)
{
	if (!is_user_alive(Index))
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Trebuie să fii in viaţă!" );
		return PLUGIN_HANDLED;
	}
	if (GetBit(InUseLife, Index))
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu poți da life când ai primit deja life!" );
		return PLUGIN_HANDLED;
	}
	if (GetBit(GivedLife, Index))
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu poți da life decât o singură dată pe rundă!" );
		return PLUGIN_HANDLED;
	}
	if (cs_get_user_team(Index) != CS_TEAM_CT)
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Trebuie să fii in counter!" );
		return PLUGIN_HANDLED;
	}
       
	new Players[MAX_PLAYERS], DeadPlayers, NamePlayer[MAX_NAME_LENGTH], PlayerId[6];
       
	get_players(Players, DeadPlayers, "bche", "CT");
	
	if ( DeadPlayers == 0 )
	{
		client_print_color(Index, print_team_red, "^4[^3Transfer Life^4]^1 Nu este nici un jucător mort!" );
		return PLUGIN_HANDLED;
	}
	
	new Menu = menu_create("\rThe new life transfer:", "menuHandler");
	
	new Contor = 1, bool:LastItem;
	for (new i = 0; i < DeadPlayers; ++i)
	{
		if ( GetBit(GivedLife, Players[i]) || GetBit(InUseLife, Players[i]) )
		{
			continue;
		}

		get_user_name(Players[i], NamePlayer, charsmax(NamePlayer));
		num_to_str(Players[i], PlayerId, charsmax(PlayerId));
           
		if ( Contor == 6 )
		{
			add(NamePlayer, charsmax(NamePlayer), "^n");
			menu_additem(Menu, NamePlayer, PlayerId);
			new Info[3], LifeTransferTime[40];
			formatex(Info, charsmax(Info), "%d", LifeTransferType);
			switch (LifeTransferType)
			{
				case 0 :
				{
					formatex(LifeTransferTime, charsmax(LifeTransferTime), "Lifeback in : \r15s");
				}
				case 1 :
				{
					formatex(LifeTransferTime, charsmax(LifeTransferTime), "Lifeback in : \r25s");
				}
				case 2 :
				{
					formatex(LifeTransferTime, charsmax(LifeTransferTime), "Lifeback in : \r30s");
				}
				case 3 :
				{
					formatex(LifeTransferTime, charsmax(LifeTransferTime), "Without lifeback.");
				}
			}
			menu_additem(Menu, LifeTransferTime, Info);
			Contor = 1;
			LastItem = true;
		}
		else
		{
			menu_additem(Menu, NamePlayer, PlayerId);
			Contor++;
			LastItem = false;
		}
	}
	
	if ( LastItem )
	{
		--Contor;
	}
	
	if ( Contor & 7 != 0 )
	{
		new Lines = 7;
		while ( Lines-- - Contor & 7 )
		{
			menu_addblank2(Menu);
		}
		new Info[3], LifeTransferTime[40];
		formatex(Info, charsmax(Info), "%d", LifeTransferType);
		switch (LifeTransferType)
		{
			case 0 :
			{
				formatex(LifeTransferTime, charsmax(LifeTransferTime), "Lifeback in : \r15s");
			}
			case 1 :
			{
				formatex(LifeTransferTime, charsmax(LifeTransferTime), "Lifeback in : \r25s");
			}
			case 2 :
			{
				formatex(LifeTransferTime, charsmax(LifeTransferTime), "Lifeback in : \r30s");
			}
			case 3 :
			{
				formatex(LifeTransferTime, charsmax(LifeTransferTime), "Without lifeback. \r(Only to slots)");
			}
		}
		menu_additem(Menu, LifeTransferTime, Info);
	}
    
	menu_display(Index, Menu, 0);
	
	return PLUGIN_CONTINUE;
}
 
public menuHandler(Index, Menu, Item)
{
	if( Item == MENU_EXIT )
	{
		menu_destroy(Menu);
		return PLUGIN_HANDLED;
	}
	
	new Info[6], ItemName[32], Access, CallBack, TargetName[MAX_NAME_LENGTH];
	menu_item_getinfo(Menu, 6, Access, Info, charsmax(Info), ItemName, charsmax(ItemName), CallBack);
	new LifeTransferType = str_to_num(Info);
	
	if ((Item+1) % 7 == 0)
	{
		if (++LifeTransferType == 4)
		{
			LifeTransferType = 0;
		}
		
		menu_item_getinfo(Menu, Item, Access, Info, charsmax(Info), ItemName, charsmax(ItemName), CallBack);
		transferLifeMenu(Index, LifeTransferType);
		return PLUGIN_HANDLED;
	}
       
	menu_item_getinfo(Menu, Item, Access, Info, charsmax(Info), ItemName, charsmax(ItemName), CallBack);
	new TargetIndex = str_to_num(Info);
	get_user_name(TargetIndex, TargetName, charsmax(TargetName));
	transferLife(Index, TargetIndex, LifeTransferType);
       
	menu_destroy(Menu);
	return PLUGIN_HANDLED;
}
 