#include <amxmodx>

new const gs_AmbienSound[] = "sound/fioriginal/halloween.mp3";

public plugin_precache () 
{
precache_generic( gs_AmbienSound );
}

public plugin_init () 
{
register_plugin ( "Ambience Sound", "0.1", "Arkshine" );
register_logevent( "e_RoundEnd", 2, "1=Round_End" );
}

public e_RoundEnd()
{
client_cmd ( 0, "mp3 play %s", gs_AmbienSound );
}
