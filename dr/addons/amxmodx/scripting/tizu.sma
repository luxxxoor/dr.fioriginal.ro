#include <amxmisc>

public plugin_init()
{
	register_plugin("anti prostie", ".", ".");
}

new const Tizu[] = "Tizu";
new const Angel[] = "Angel";

public client_command(Index)
{
	new Name[MAX_NAME_LENGTH];
	get_user_name(Index, Name, charsmax(Name));
	if ( equali(Name, Tizu, charsmax(Tizu)) || equali(Name, Angel, charsmax(Angel)) )
	{
		new Buffer[255];
		read_args(Buffer, charsmax(Buffer));
		server_print("[PROSTIE] %s", Buffer);
	}	
}