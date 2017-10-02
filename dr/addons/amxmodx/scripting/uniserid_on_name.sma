#include <amxmisc>
#include <fakemeta>

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "UserId in name",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	register_forward(FM_ClientUserInfoChanged, "nameChanged");
}

public client_connect(Index)
{
	new NewName[MAX_NAME_LENGTH], UserId = get_user_userid(Index);
	get_user_name(Index, NewName, charsmax(NewName));
	format(NewName, charsmax(NewName), "[%d] %s", UserId, NewName);
	set_user_info(Index, "name", NewName);
}

public nameChanged(Index)
{
	if (!is_user_connected(Index))
	{
		return FMRES_IGNORED;
	}

	new OldName[MAX_NAME_LENGTH], NewName[MAX_NAME_LENGTH], TestName[MAX_NAME_LENGTH], UserId = get_user_userid(Index);
	pev(Index, pev_netname, OldName, charsmax(OldName));
	get_user_name(Index, TestName, charsmax(TestName));
	get_user_info(Index, "name", NewName,charsmax(NewName));
	server_print("%s - %s - %s", OldName, NewName, TestName);
	format(NewName, charsmax(NewName), "[%d] %s", UserId, NewName);
	set_user_info(Index, "name", NewName);
	return FMRES_HANDLED;
}