#include <amxmisc> 
#include <fun>
#include <cstrike>
#include <hamsandwich>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

new Heal, PauseVoice;

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "H.E.V.",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage_Pre");
	RegisterHam(Ham_Spawn, "player", "playerSpawn", 1);
}

public playerSpawn(Index) 
{
	DelBit(Heal, Index);
}

public TakeDamage_Pre(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	new Health = get_user_health(Victim);
	if (Damage <= 0.0 || cs_get_user_team(Victim) != CS_TEAM_CT || Health - floatround(Damage) < 0)
	{
		return HAM_IGNORED;
	}
	
	if (Health - floatround(Damage) <= 5)
	{
		if (!GetBit(PauseVoice, Victim))
		{
			client_cmd(Victim, "spk ^"fvox/(p120) beep, beep, beep, (p100) near_death^"");
			client_print(Victim, print_center, "Emergency! User death imminent !");
			suit_next(Victim, 5.0);
		}
	}
	
	if (Health - floatround(Damage) <= 25)
	{
		if (!GetBit(PauseVoice, Victim))
		{
			client_cmd(Victim, "spk ^"fvox/(p120) beep, beep, beep, (p100) health_critical^"");
			client_print(Victim, print_center, "Warning: Vital sings critical !");
			suit_next(Victim, 5.0);
		}
	}
	
	if (DamageBits & DMG_FALL)
	{
		if (Health-Damage >= 65)
		{
			if (!GetBit(PauseVoice, Victim))
			{
				client_cmd(Victim, "spk ^"fvox/(p160) boop, boop, boop, (p100) minor_fracture^"");
				client_print(Victim, print_center, "Minor fracture detected !");
				suit_next(Victim, 5.0);
			}
		}
		else
		{
			if (!GetBit(PauseVoice, Victim))
			{
				client_cmd(Victim, "spk ^"fvox/(p160) boop, boop, boop, (p100) major_fracture^"");
				client_print(Victim, print_center, "Major fracture detected !");
				suit_next(Victim, 5.0);
			}
		}
		set_task(10.0, "hevFracture", Victim);
	}
	return HAM_IGNORED;
}

public hevFracture(Index)
{
	if (GetBit(Heal, Index) || !is_user_alive(Index))
	{
		return;
	}
	
	new Health = get_user_health(Index);
	
	set_user_health(Index, Health+35 > 100 ? 100 : Health+35);
	if (!GetBit(PauseVoice, Index))
	{
		client_cmd(Index, "spk ^"fvox/(p140) boop, boop, boop (p100) automedic_on _period _period administering_medical^"");
		client_print(Index, print_center, "Automatic medical systems engaged. Administering medical attention !");
		suit_next(Index, 7.0);
	}
	SetBit(Heal, Index);
}

suit_next(Index, Float:seconds) /* HEV Suit wont spam anymore */
{
	SetBit(PauseVoice, Index);
	set_task(seconds, "pauseVoiceOff", Index);
}

public pauseVoiceOff(Index)
{
	DelBit(PauseVoice, Index);
}