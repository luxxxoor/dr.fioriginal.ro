#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <revive>

#define SetBit(%1,%2)   (%1 |= (1 << (%2 & 31))) 
#define DelBit(%1,%2)   (%1 &= ~(1 << (%2 & 31))) 
#define GetBit(%1,%2)   (%1 & (1 << (%2 & 31)))

public RespawnTime;

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "The new respawn",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	register_logevent("roundStart", 2, "1=Round_Start");
	RegisterHam(Ham_Killed, "player", "playerPostKilled", 1);
	
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET); // Removes all dead bodies.
}

public roundStart()
{
	if (task_exists(RespawnTime))
	{
		remove_task(RespawnTime);
	}
	
	RespawnTime = 19;
	set_task(1.0, "countRespawnTime", RespawnTime)
}

public countRespawnTime()
{
	if (--RespawnTime == -1 )
	{
		//set_dhudmessage(255, 0, 0, 0.00, 0.0, 0, 0.0, 1.0, 0.0, 0.0);
		//show_dhudmessage(0, "Timpul respawn-ului s-a terminat !");
		return;
	}
	//set_dhudmessage(255, 0, 0, 0.00, 0.0, 0, 0.0, 1.0, 0.0, 0.0);
	//show_dhudmessage(0, "Respawn-ul este activ încă %d secunde !", RespawnTime+1);
	
	set_task(1.0, "countRespawnTime", RespawnTime);
}

public playerPostKilled(VictimIndex, AttackerIndex, ShouldGib)
{
	if (is_user_bot(VictimIndex) || !is_user_connected(VictimIndex))
	{
		return HAM_IGNORED;
	}
	
	if (cs_get_user_team(VictimIndex) != CS_TEAM_CT)
	{
		return HAM_IGNORED;
	}
	
	if (RespawnTime == -1)
	{
		static TrialReviveIndex, AutoRevive;
		if (TrialReviveIndex == 0)
		{
			TrialReviveIndex = get_xvar_id("TrialReviveIndex");
		}
		if (AutoRevive == 0)
		{
			AutoRevive = get_xvar_id("AutoRevive");
		}
		if ((get_user_flags(VictimIndex) & ADMIN_LEVEL_H || VictimIndex == get_xvar_num(TrialReviveIndex)) && GetBit(get_xvar_num(AutoRevive), VictimIndex))
		{
			set_task(1.0, "reviveClient", VictimIndex);
		}
		return HAM_IGNORED;
	}
	
	
	set_task(1.0, "spawnClient", VictimIndex);
	
	return HAM_IGNORED;
}

public reviveClient(Index)
{
	revivePlayer(Index);
}

public spawnClient(Index)
{
	if (!is_user_connected(Index))
	{
		return;
	}
	
	ExecuteHamB(Ham_CS_RoundRespawn, Index);
	
	new Deaths = get_user_deaths(Index) - 1;
	cs_set_user_deaths(Index, Deaths);
		
	static ScoreInfo;
	if (ScoreInfo == 0)
	{
		ScoreInfo = get_user_msgid("ScoreInfo")
	}
	message_begin(MSG_BROADCAST, ScoreInfo);
	write_byte(Index);
	write_short(get_user_frags(Index));
	write_short(Deaths);
	write_short(0);
	write_short(get_user_team(Index));
	message_end();
}