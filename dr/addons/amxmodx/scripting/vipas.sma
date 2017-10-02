#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <fun>

const m_bHasPrimary = 464; 

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Scout for Revive",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_clcmd("say", "HookClCmdSay");
	register_clcmd("drop","antidrop");
}

public antidrop(Index)
{
	if (get_user_weapon(Index) == CSW_SCOUT)
	{
		ham_strip_weapon(Index, "weapon_scout");
		set_pdata_bool(Index, m_bHasPrimary, false); 
		give_item(Index, "weapon_knife");
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public HookClCmdSay(Index)
{
	new Said[192];
	read_args(Said, charsmax(Said));
	
	if (!Said[0])
	{
		return PLUGIN_CONTINUE;
	}
	
	remove_quotes(Said);
	new const ScoutIdent[] = "!scout";
	
	if (equal(Said, ScoutIdent, charsmax(ScoutIdent)))
	{
		giveStaff(Index);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

giveStaff(Index)
{
	if (cs_get_user_hasprim(Index))
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Ești deja înarmat cu o armă primară.");
		return;
	}
	
	if(get_user_flags(Index) & ADMIN_LEVEL_H)
	{
		if (get_user_weapon(Index) != CSW_SCOUT)
		{
			new Scout = give_item(Index, "weapon_scout");
			if( Scout > 0)
			{
				cs_set_weapon_ammo(Scout, 0);
				cs_set_user_bpammo(Index, CSW_SCOUT, 0);
			}
		}
	}
	else 
	{
		client_print_color(Index, print_team_red, "^4[^3AMX_REVIVE^4]^1 Comanda poate fi folosită doar de jucătorii care au ^4revive^1! Pentru detalii, scrie ^4!revive^1.");
	}
}

ham_strip_weapon(Index,weapon[])
	{
	if(!equal(weapon,"weapon_",7)) return 0;
	
	new wId = get_weaponid(weapon);
	if(!wId) return 0;
	
	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != Index) {}
	if(!wEnt) return 0;
	
	if(get_user_weapon(Index) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem,Index,wEnt)) return 0;
	ExecuteHamB(Ham_Item_Kill,wEnt);
	
	set_pev(Index,pev_weapons,pev(Index,pev_weapons) & ~(1<<wId));
	
	// this block should be used for Counter-Strike:
	/*if(wId == CSW_C4)
	{
		cs_set_user_plant(Index,0,0);
		cs_set_user_bpammo(Index,CSW_C4,0);
	}
	else if(wId == CSW_SMOKEGRENADE || wId == CSW_FLASHBANG || wId == CSW_HEGRENADE)
		cs_set_user_bpammo(Index,wId,0);*/
	
	return 1;
}
