#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#pragma tabsize 0

#define MAX_ENTITYS 900+15*32 // (900+15*SERVER_SLOTS) is the calculation cs uses but it can be bypassed by the "-num_edicts <x>"-parameter

new bool:g_bPlayerInvisible[33];
new bool:g_bWaterInvisible[33];

new bool:g_bWaterEntity[MAX_ENTITYS];
new bool:g_bWaterFound;

new g_iSpectatedId[33];

public plugin_init( )
	{
	register_plugin( "Invis", "2.0", "SchlumPF" );
	
	register_clcmd( "say", "SayCMD" );
	register_menucmd( register_menuid( "\r[FPS] - \wInvizibilitate^n^n" ), 1023, "menuInvisAction" );
	
	register_forward( FM_AddToFullPack, "fwdAddToFullPack_Post", 1 );
	RegisterHam( Ham_Spawn, "player", "hamSpawnPlayer_Post", 1 );
	
	register_event( "SpecHealth2", "eventSpecHealth2", "bd" );
}

public client_putinserver(id) 
	{
	set_user_info(id, "_vgui_menus", "1");
}

public plugin_cfg( )
	{
	new ent = -1;
	while( ( ent = find_ent_by_class( ent, "func_water" ) ) != 0 )
		{
		
		if( !g_bWaterFound )
			{
			g_bWaterFound = true;
		}
		
		g_bWaterEntity[ent] = true;
	}
	
	ent = -1;
	while( ( ent = find_ent_by_class( ent, "func_illusionary" ) ) != 0 )
		{
		if( pev( ent, pev_skin ) ==  CONTENTS_WATER )
			{
			if( !g_bWaterFound )
				{
				g_bWaterFound = true;
			}
			
			g_bWaterEntity[ent] = true;
		}
	}
	
	ent = -1;
	while( ( ent = find_ent_by_class( ent, "func_conveyor" ) ) != 0 )
		{
		if( pev( ent, pev_spawnflags ) == 3 )
			{
			if( !g_bWaterFound )
				{
				g_bWaterFound = true;
			}
			
			g_bWaterEntity[ent] = true;
		}
	}
}

public SayCMD(  id  )
	{
	
	static szSaid[ 192 ];
	read_args( szSaid, sizeof ( szSaid ) -1 );
	
	remove_quotes( szSaid );
	
	if( equal( szSaid, "!invis", strlen ( "!invis" ) ) )
		{
		menuInvisDisplay(id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public fwdAddToFullPack_Post( es_handle, e, ent, host, hostflags, player, pset )
	{
	if( player && g_bPlayerInvisible[host] && host != ent && ent != g_iSpectatedId[host] && get_user_team(host) == get_user_team(ent) )
		{
		static const Float:corner[8][3] = 
		{
			{ -4096.0, -4096.0, -4096.0 },
			{ -4096.0, -4096.0, 4096.0 },
			{ -4096.0, 4096.0, -4096.0 },
			{ -4096.0, 4096.0, 4096.0 },
			{ 4096.0, -4096.0, -4096.0 },
			{ 4096.0, -4096.0, 4096.0 },
			{ 4096.0, 4096.0, -4096.0 },
			{ 4096.0, 4096.0, 4096.0 }
		};
		
		// rounded; distance from the map's center to the corners; sqrt( 4096^2 + 4096^2 + 4096^2 )
		static const Float:map_distance = 7094.480108;
		
		static Float:origin[3];
		get_es( es_handle, ES_Origin, origin );
		
		static i;
		while( get_distance_f( origin, corner[i] ) > map_distance )
			{ 
			if( ++i >= sizeof( corner ) )
				{
				// better to nullify the varibale now then doing it each time before the loop
				i = 0;
			}
		}
		
		set_es( es_handle, ES_Origin, corner[i] );
		set_es( es_handle, ES_Effects, get_es( es_handle, ES_Effects ) | EF_NODRAW );
	}
	else if( g_bWaterInvisible[host] && g_bWaterEntity[ent])
		{
		set_es( es_handle, ES_Effects, get_es( es_handle, ES_Effects ) | EF_NODRAW );
	}
}

public hamSpawnPlayer_Post( id )
	{
	g_iSpectatedId[id] = 0;
}

// thanks to xPaw who told me about this event
public eventSpecHealth2( id )
	{
	g_iSpectatedId[id] = read_data( 2 );
}

public menuInvisDisplay( id )
	{
	static menu[256];
	
	new szData[ 64 ];
	get_user_info( id, "_vgui_menus", szData, 63 );
	
	if(str_to_num(szData) == 0)
		{
		set_user_info(id, "_vgui_menus", "1");
	}
	
	new len = formatex( menu, 255, "\r[FPS] - \wInvizibilitate^n^n" );
	
	len += formatex( menu[len], 255 - len, "\r1. \wCoechipierii: \y%s^n", g_bPlayerInvisible[id] ? "Invizibili" : "Vizibili" );
	
	if( g_bWaterFound )
		{
		len += formatex( menu[len], 255 - len, "\r2. \wApa: \y%s^n", g_bWaterInvisible[id] ? "Invizibila" : "Vizibila" );
	}
	else
	{
		len += formatex( menu[len], 255 - len, "\r2. \wApa: \yNu exista apa pe harta!^n" );
	}
	
	len += formatex( menu[len], 255 - len, "^n\r0. \wIesire" );
	
	show_menu( id, ( 1<<0 | 1<<1 | 1<<9 ), menu, -1 );
	
	return PLUGIN_HANDLED;
}

public menuInvisAction( id, key )
	{
	switch( key )
	{
		case 0:
		{
			g_bPlayerInvisible[id] = !g_bPlayerInvisible[id];
			menuInvisDisplay( id );
		}
		case 1:
		{
			if( g_bWaterFound )
				{
				g_bWaterInvisible[id] = !g_bWaterInvisible[id];
			}
			
			menuInvisDisplay( id );
		}
		case 9: show_menu( id, 0, "" );
	}
}

public client_connect( id )
	{
	g_bPlayerInvisible[id] = false;
	g_bWaterInvisible[id] = false;
	g_iSpectatedId[id] = 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
