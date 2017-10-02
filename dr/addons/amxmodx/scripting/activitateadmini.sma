#include <amxmodx>

#pragma semicolon 1


#define PLUGIN "Activitate Admini"
#define VERSION "2.0c"

enum
{
	
	INFO_NAME,
	INFO_IP,
	INFO_AUTHID
	
};

new const g_szFileName[ ] = "activitate_admini";

new g_CvarLogConnect;
new g_CvarLogDisconnect;
new g_CvarLogMap;
new g_CvarLogTimeLeft;
new g_CvarLogCommand;


new g_szFile[ 128 ];
new g_szMapName[ 32 ];

public plugin_precache( )
{
	get_localinfo( "amxx_configsdir", g_szFile, sizeof ( g_szFile ) -1 );
	format( g_szFile, sizeof ( g_szFile ) -1, "%s/%s", g_szFile, g_szFileName );
	
	if( !dir_exists( g_szFile ) )
		mkdir( g_szFile );
		
	new szCurentDate[ 15 ];
	get_time("%d-%m-%Y", szCurentDate , sizeof ( szCurentDate ) -1 );
	
	format( g_szFile, sizeof ( g_szFile ) -1, "%s/%s_%s.txt", g_szFile, g_szFileName, szCurentDate );
	
	if( !file_exists( g_szFile ) )
	{
		write_file( g_szFile, "-| Aici este salvata activitatea fiecarui admin. |-", -1 );
		write_file( g_szFile, " ", -1 );
		write_file( g_szFile, " ", -1 );
	}

	get_mapname( g_szMapName, sizeof ( g_szMapName ) -1 );
	format( g_szMapName, sizeof ( g_szMapName ) -1, "- Harta: %s|", g_szMapName );
	
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, "Askhanar" );
	
	g_CvarLogConnect = register_cvar( "aa_log_connect", "1" );
	g_CvarLogDisconnect = register_cvar( "aa_log_disconnect", "1" );
	g_CvarLogMap = register_cvar( "aa_log_map", "1" );
	g_CvarLogTimeLeft = register_cvar( "aa_log_timeleft", "1" );
	g_CvarLogCommand = register_cvar( "aa_log_commands", "3" );
	
}


public client_putinserver( id )
{
	if( !is_user_admin( id )
		|| !get_pcvar_num( g_CvarLogConnect ) )
		return 0;
		
	write_file( g_szFile, "-------------------------------------------------------------------------------------------------------------------------------", -1 );
	LogCommand( " %s [ %s | %s ] s-a conectat pe server.", 
			GetInfo( id, INFO_NAME ), GetInfo( id, INFO_AUTHID ), GetInfo( id, INFO_IP ) );
	write_file( g_szFile, "-------------------------------------------------------------------------------------------------------------------------------", -1 );
	return 0;
	
}

public client_disconnected( id )
{
	if( !is_user_admin( id ) 
		|| !get_pcvar_num( g_CvarLogDisconnect ) )
		return 0;
		
	write_file( g_szFile, "-------------------------------------------------------------------------------------------------------------------------------", -1 );
	LogCommand( " %s [ %s | %s ] s-a deconectat de pe server.",
			GetInfo( id, INFO_NAME ), GetInfo( id, INFO_AUTHID ), GetInfo( id, INFO_IP ) );
	write_file( g_szFile, "-------------------------------------------------------------------------------------------------------------------------------", -1 );
	
	return 0;
	
}

public client_command( id )
{
	static iLogCommand;
	iLogCommand = get_pcvar_num( g_CvarLogCommand );
	if( !is_user_admin( id ) || !iLogCommand )
		return 0;
		
	static szCommand[ 36 ];
	read_argv( 0, szCommand, sizeof ( szCommand ) -1 );
	
	if( get_command_value( szCommand ) == iLogCommand
		|| get_command_value( szCommand ) > 0 && iLogCommand == 3 )
	{
		static szArgs[ 101 ];
		read_args( szArgs, sizeof ( szArgs ) -1 );
		
		remove_quotes( szArgs );
		
		LogCommand( " %s [ %s | %s ] '%s %s' ", 
			GetInfo( id, INFO_NAME ), GetInfo( id, INFO_AUTHID ), GetInfo( id, INFO_IP ), szCommand, szArgs );
	}
	
	return 0;
}

LogCommand( const szMsg[ ], any:... )
{
	static szMessage[ 256 ], szLogMessage[ 256 ];
	vformat( szMessage, sizeof ( szMessage ) -1, szMsg , 2 );
	
	static iLogMap, iLogTimeLeft;
	iLogMap = get_pcvar_num( g_CvarLogMap );
	iLogTimeLeft = get_pcvar_num( g_CvarLogTimeLeft );
		
	formatex( szLogMessage, sizeof ( szLogMessage ) -1, "|%s|%s%s%s",
		_get_time( ), iLogMap ? g_szMapName : "", iLogTimeLeft ? _get_timeleft( ) : "", szMessage );
	
	write_file( g_szFile, szLogMessage, -1 );
}

stock get_command_value( const szCommand[ ] )
{
	static iCommandValue;
	
	if( equali( szCommand, "amx_", 4 ) )
		iCommandValue = 1;
	else if( equali( szCommand, "admin_" , 6 ) )
		iCommandValue = 2;
	else
		iCommandValue = -1;
		
	return iCommandValue;
	
}

stock bool:is_user_admin( id )
{
	if( get_user_flags( id ) & ADMIN_CHAT )
		return true;
		
	return false;
}
//--

stock _get_time( )
{
	new szTime[ 32 ];
	get_time( " %H:%M:%S ", szTime ,sizeof ( szTime ) -1 );
	
	return szTime;
}

stock _get_timeleft( )
{
	static szTimeLeft[ 25 ];
	format( szTimeLeft, sizeof ( szTimeLeft ) -1, "- TimeLeft: %d:%02d|", get_timeleft( ) / 60, ( get_timeleft( ) % 60 ) );
	
	return szTimeLeft;
	
}

stock GetInfo( id, const iInfo )
{
	
	new szInfoToReturn[ 64 ];
	
	switch( iInfo )
	{
		case INFO_NAME:
		{
			static szName[ 32 ];
			get_user_name( id, szName, sizeof ( szName ) -1 );
			
			copy( szInfoToReturn, sizeof ( szInfoToReturn ) -1, szName );
		}
		case INFO_IP:
		{
			static szIp[ 32 ];
			get_user_ip( id, szIp, sizeof ( szIp ) -1, 1 );
			
			copy( szInfoToReturn, sizeof ( szInfoToReturn ) -1, szIp );
		}
		case INFO_AUTHID:
		{
			static szAuthId[ 35 ];
			get_user_authid( id, szAuthId, sizeof ( szAuthId ) -1 );
			
			copy( szInfoToReturn, sizeof ( szInfoToReturn ) -1, szAuthId );
		}
	}

	return szInfoToReturn;
}
