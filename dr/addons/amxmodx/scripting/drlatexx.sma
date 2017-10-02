#include <amxmodx>
#include <fakemeta>
#include <hamsandwich> 
 
/* Modificat de Florin * */
 
#define PLUGIN "deathrun banner remover"
#define VERSION "1"
#define AUTHOR "Jon"
 
new Trie:gTrieWallModels, gRegisterIndex;
 
public plugin_precache()
{
		new Map[ 32 ];
		get_mapname( Map, charsmax(Map) );
 
		if( equali( Map, "deathrun_mnx_beta" ) )
		{
			new const WallModels[ ][ ] =
			{
				"*14",
                "*15",
                "*114",
                "*135",
                "*136",
                "*137",
                "*138",
                "*139",
                "*140",
                "*141",
                "*142",
                "*143",
                "*144",
                "*146",
                "*147",
                "*148",
                "*149"
			}
			gTrieWallModels = TrieCreate( );
       
			for( new i; i < sizeof WallModels; i++ )
				TrieSetCell( gTrieWallModels, WallModels[ i ], i );    
       
			gRegisterIndex = register_forward( FM_Spawn, "Spawn" );
		}
		if( equali( Map, "deathrun_latexx" ) )
		{
 
			new const WallModels[ ][ ] =
			{
					"*167"
			}
 
			gTrieWallModels = TrieCreate( );
       
			for( new i; i < sizeof WallModels; i++ )
				TrieSetCell( gTrieWallModels, WallModels[ i ], i );   
       
			gRegisterIndex = register_forward( FM_Spawn, "Spawn" );
       }
}
 
public plugin_init()
{
        register_plugin( PLUGIN, VERSION, AUTHOR );
        register_cvar( PLUGIN, VERSION, FCVAR_SPONLY | FCVAR_SERVER );
        register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	   
        unregister_forward( FM_Spawn, gRegisterIndex );
       
        TrieDestroy( gTrieWallModels );
}

public message_TextMsg(msg_id, msg_dest, msg_entity)
{
    static buffer[32];
    
    get_msg_arg_string(2, buffer, charsmax(buffer));
    
    if(equal(buffer, "#Game_Commencing") || equal(buffer, "#Game_will_restart_in"))
        return PLUGIN_HANDLED
    
    return PLUGIN_CONTINUE
}

public Spawn( Ent )
{
        if( !pev_valid( Ent ) )
                return FMRES_IGNORED;
       
        new Model[ 5 ];
        pev( Ent, pev_model, Model, charsmax(Model) );
               
        if( TrieKeyExists( gTrieWallModels, Model ) )
        {
                engfunc( EngFunc_RemoveEntity, Ent );
                       
                return FMRES_SUPERCEDE;
        }
       
        return FMRES_IGNORED;
}
 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1044\\ f0\\ fs16 \n\\ par }
*/