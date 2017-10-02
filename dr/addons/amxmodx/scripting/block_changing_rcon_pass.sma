#include <amxmisc>

#if AMXX_VERSION_NUM < 183 
    #assert AMX Mod X v1.8.3 or later library required!
#endif

new RconPasswordValue[64];

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Block changing rcon_password",
		.version     = "1.0",
		.author      = "lüxor"
	);
	new RconPasswordCvarPointer = get_cvar_pointer("rcon_password");
	get_pcvar_string(RconPasswordCvarPointer, RconPasswordValue, charsmax(RconPasswordValue));
	hook_cvar_change(RconPasswordCvarPointer, "setDefaultValue");
}

public setDefaultValue(PointerCvar, const OldValue[], const NewValue[])
{
	if ( !equal(NewValue, RconPasswordValue, charsmax(RconPasswordValue)) )
	{
		set_pcvar_string(PointerCvar, OldValue);
	}
}