#include <amxmodx>
#include <cstrike>

public client_connect(id)
{
	if(!is_user_bot(id))
	{
		set_task(0.5, "Fix", id);
	}
} 

public Fix(id)
{
	if (!is_user_connected(id))
	{
		return;
	}
	if( cs_get_user_team(id) == CS_TEAM_UNASSIGNED )
	{
		cs_set_user_team(id, CS_TEAM_CT);
	}
}