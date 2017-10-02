

#define USE_MENU_COMMAND

#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < fakemeta >


//new g_anti_abuse[ 33 ]



new cvar_health //,cvar_bonus

public plugin_init() 
{
	register_plugin( "Transfer Life", "1.0", "P.Of.Pw" )
	
	cvar_health = register_cvar( "tf_health_system", "1" )
	//cvar_bonus = register_cvar( "tf_bonus", "0")
	

	//RegisterHam( Ham_Spawn, "player", "fwd_HamPlayerSpawnPost" )
	//register_forward( FM_ClientKill, "fw_ClientKill" )
	
	register_clcmd( "say", "clcmdsay_transfer_life" )
	register_clcmd( "say_team", "clcmdsay_transfer_life" )
	
	register_clcmd( "life", "transfer_life" )

#if defined USE_MENU_COMMAND
	register_clcmd( "lifemenu", "transfer_life_menu" )
	register_clcmd( "say !lifemenu", "transfer_life_menu" )
	register_clcmd( "say_team !lifemenu", "transfer_life_menu" )
#endif	
}

//public client_disconnect( id )
//	g_anti_abuse[ id ] = false

//public fwd_HamPlayerSpawnPost()
//	arrayset( g_anti_abuse, false, 32 )

//public fw_ClientKill( id ) //suicide
//	g_anti_abuse[ id ] = false

public clcmdsay_transfer_life( id )
{
	static args[ 192 ], command[ 192 ]
	read_args( args, charsmax( args ) )
	
	if( !args[ 0 ] )
		return PLUGIN_CONTINUE
		
	remove_quotes( args[ 0 ] )
	
	if( equal( args, "!life", strlen( "!life" ) ) )
	{
		replace( args, charsmax( args ), "!", "" )
		formatex( command, charsmax( command ), "%s", args )
		client_cmd( id, command )
	}
	
	return PLUGIN_CONTINUE
}
	
public transfer_life( id )
{
	if( !is_user_alive( id ) )
	{
		console_print( id, "[Transfer Life] Trebuie sa fi in viata!" )
		return PLUGIN_HANDLED
	}
	
	//if( g_anti_abuse[ id ] )
	//{
	//	console_print( id, "[Transfer Life] NU mai poti folosi comanda!" )
	//	return PLUGIN_HANDLED
  //}
	
	new arg[ 32 ], tf_health_system = get_pcvar_num( cvar_health )
	//tf_bonus = get_pcvar_num( cvar_bonus ),
	new origin[ 3 ], name[ 32 ], target_name[ 32 ]
	
	read_argv( 1, arg, 31 )
	new target = cmd_target( id, arg, 0 )
	if( !target )
	{
		console_print( id, "[Transfer Life] Jucatorul NU se afla pe server!" )
		return PLUGIN_HANDLED
	}
	
	if( is_user_alive( target ) )
	{
		console_print( id, "[Transfer Life] Jucatorul este deja in viata!" )
		return PLUGIN_HANDLED
	}
	
	//if( g_anti_abuse[ target ] )
	//{
	//	console_print( id, "[Transfer Life] NU poti folosi comanda pe acest jucator!" )
	//	return PLUGIN_HANDLED
	//}
	
	if( get_user_team( id ) != get_user_team( target ) )
	{
		console_print( id, "[Transfer Life] Jucatorul trebuie sa fie in aceeasi echipa cu tine!" )
		return PLUGIN_HANDLED
	}
	//new health = get_user_health( id );
	if( tf_health_system == 1 )
	{
		new health
		health = get_user_health( id )
			
		/*if( health < 20 )
		{
			console_print( id, "[Transfer Life] Ai mai putin de 20HP! Nu poti sa oferi viata altui player" )
			return PLUGIN_HANDLED
		}*/
		
		ExecuteHamB( Ham_CS_RoundRespawn, target )
		fm_set_user_health( target, health )
	}
	
	user_silentkill( id )
	//g_anti_abuse[ id ] = true
	
	if( tf_health_system != 1 )
	{
		ExecuteHamB( Ham_CS_RoundRespawn, target )
		//fm_set_user_health( target, health );
	}
      
	get_user_origin( id, origin, 0 )
	origin[ 2 ] += 20
	
	fm_set_user_origin( target, origin )
	fm_strip_user_weapons( target )
	fm_give_item( target, "weapon_knife" )
	//fm_set_user_health( target, health );
	
	get_user_name( id, name, 31 )
	get_user_name( target, target_name, 31 )
	//fm_set_user_frags( id, get_user_frags( id ) + tf_bonus )
	
	//client_print( id, print_chat, "[Transfer Life] Ti-ai dat viata si ai primit %d Fraguri bonus!", tf_bonus )
	client_print( 0, print_chat, "[Transfer Life] %s i-a dat viata lui %s .", name, target_name )
	//client_print( 0, print_chat, "[Transfer Life] %s i-a dat viata lui %s si a primit %d Fraguri bonus!", name, target_name, tf_bonus )
	return PLUGIN_HANDLED
}

#if defined USE_MENU_COMMAND
public transfer_life_menu( id )
{
	if( !is_user_alive( id ) )
	{
		console_print( id, "[Transfer Life] Meniul nu poate fi deschis!" )
		return;
	}
	
	new menu = menu_create( "\rTransfer Life Menu:", "menu_handler" )

	new players[ 32 ], pnum, tempid,
	name_players[ 32 ], tempid2[ 10 ]

	get_players(players, pnum)
	for( new i; i < pnum; i++ )
	{
		tempid = players[ i ]
		
		if( get_user_team( id ) != get_user_team( tempid ) )
			continue
		if( is_user_alive( tempid ) )
			continue
			
		get_user_name( tempid, name_players, 31 )
		num_to_str( tempid, tempid2, 9 )

		menu_additem( menu, name_players, tempid2, 0 )
	}

	menu_display( id, menu, 0 )
}

public menu_handler( id, menu, item )
{
	if( item == MENU_EXIT )
	{
		menu_destroy( menu )
		return PLUGIN_HANDLED
	}

	new data[ 6 ], name_menu[ 64 ], access, callback, name_target[ 32 ]
	menu_item_getinfo( menu, item, access, data, 5, name_menu, 63, callback )

	new tempid = str_to_num( data )

	get_user_name( tempid, name_target, 31 )
	client_cmd( id, "life %s", name_target )

	menu_destroy( menu )
	return PLUGIN_HANDLED
}
#endif

//fakemeta_util by VEN
stock fm_entity_set_origin( index, const Float:origin[ 3 ] ) 
{
	new Float:mins[ 3 ], Float:maxs[ 3 ]
	pev( index, pev_mins, mins )
	pev( index, pev_maxs, maxs )
	engfunc( EngFunc_SetSize, index, mins, maxs )

	return engfunc( EngFunc_SetOrigin, index, origin )
}

stock fm_set_user_origin( index, origin[ 3 ] ) 
{
	new Float:orig[ 3 ]
	IVecFVec( origin, orig )

	return fm_entity_set_origin( index, orig )
}

stock fm_set_user_health( index, health ) 
{
	health > 0 
	? set_pev( index, pev_health, float( health ) ) 
	: dllfunc( DLLFunc_ClientKill, index )

	return 1
}

stock fm_set_user_frags( index, frags ) 
{
	set_pev( index, pev_frags, float( frags ) )

	return 1
}

stock fm_strip_user_weapons( id )
{
	static ent
	ent = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "player_weaponstrip" ) )
	if( !pev_valid( ent ) ) 
		return;
	
	dllfunc( DLLFunc_Spawn, ent )
	dllfunc( DLLFunc_Use, ent, id )
	engfunc( EngFunc_RemoveEntity, ent )
} 

stock fm_give_item( id, const item[] )
{
	static ent
	ent = engfunc( EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item ) )
	if( !pev_valid( ent ) ) 
		return;
	
	static Float:originF[ 3 ]
	pev( id, pev_origin, originF )
	set_pev( ent, pev_origin, originF )
	set_pev( ent, pev_spawnflags, pev( ent, pev_spawnflags ) | SF_NORESPAWN )
	dllfunc( DLLFunc_Spawn, ent )
	
	static save
	save = pev( ent, pev_solid )
	dllfunc( DLLFunc_Touch, ent, id )
	if( pev( ent, pev_solid ) != save )
		return;
	
	engfunc( EngFunc_RemoveEntity, ent )
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3081\\ f0\\ fs16 \n\\ par }
*/
