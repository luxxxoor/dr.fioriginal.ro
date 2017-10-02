#include <amxmodx>

new last_command[128]

public plugin_init()
{
	register_clcmd("say", "say")
}

public client_command()
{
	new command[128]
	read_argv(0, command, charsmax(command))
	remove_quotes(command)
	read_args(last_command, charsmax(last_command))
	remove_quotes(last_command)
	server_print("%s %s", command, last_command)
}

public say(id)
{
	new said[128]
	read_args(said, charsmax(said))
	remove_quotes(said)
	
	if (equal(last_command, said))
	{
		return PLUGIN_CONTINUE
	}
	
	return PLUGIN_HANDLED
}