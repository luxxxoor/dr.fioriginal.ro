/*    
     
amx_autogag_time 3 // minutele pentru gag cand ia autogag  
amx_gag_minute_limit 300 // limita maxima pentru gag minute
amx_gag_minute_in_seconds 60 // minute in secunde
amx_gag_tagname 1 // pune taguri la gag
amx_admingag 0 // poti da si la admini gag daca e egal cu 1, daca e 0 nu poti
amx_maxwords 200 // lista maxima de cuvinte in gag_words.ini 
amx_gagtag * // tag-ul din chat 
 
amx_gag < nume > < timp in minute > - dai gag unui jucator pentru x minute 
amx_ungag < nume > ii scoti gag-ul unui jucator

/gag < nume > < timp in minute > - dai gag unui jucator pentru x minute 
/ungag < nume > ii scoti gag-ul unui jucator

Cand un jucator cu gag iese de pe server va fi salvat intr-un fisier
Atunci cand se va conecta pe server va avea gag exact cate minute mai avea cand a iesit de pe server 

Autor: Cristi. C  
*/	
 
#include < amxmodx >
#include < amxmisc >

#include < fakemeta >
#include < engine >
#include < nvault >

//#pragma semicolon 1

#define PLUGIN "Special Admin Gag"
#define VERSION "1.0"

#define COMMAND_ACCESS  	ADMIN_KICK // accesu adminilor pentru comanda
#define COMMAND_ACCESS2         ADMIN_LEVEL_G
//#define MAX_PLAYERS 		32 + 1

enum
{
	INFO_NAME,
	INFO_IP,
	INFO_AUTHID
};

new gBlockTexts [ ] [ ] = {
	
	"#",
	"%"
	
}

new const gGagFileName[ ] = "gag_words.ini";
new const gLogFileName[ ] = "GagLog.log"; 

new const gGagThinkerClassname[ ] = "GagThinker_";


new PlayerGagged[ MAX_PLAYERS + 1 ];
new PlayerGagTime[ MAX_PLAYERS + 1 ];
new string:PlayerGagReason[ MAX_PLAYERS + 1 ];
new JoinTime[ MAX_PLAYERS + 1 ];
new szName[ 32 ];

new g_Words[ 562 ] [ 32 ], g_Count;
new szOldName[ MAX_PLAYERS + 1 ] [ 40 ];

new gCvarSwearGagTime;
new gCvarGagMinuteLimit;
new gCvarGagMinuteInSeconds;
new gCvarAdminGag;
new gCvarWords;
new gCvarTag;

new gMaxPlayers;
new iVault;

public plugin_init( ) 
	{
	
	register_plugin( PLUGIN, PLUGIN, "Cristi .C" );
	
	register_concmd( "amx_gag", "CommandGag" ); 
	register_concmd( "amx_ungag", "CommandUngag" );
	
	register_clcmd( "say", "CheckGag" );
	register_clcmd( "say_team", "CheckGag" );
	
	//register_clcmd( "say", "command_chat" );
	
	GagThinker( );
	register_think( gGagThinkerClassname, "Forward_GagThinker" );
	register_forward(FM_ClientUserInfoChanged, "ClientUserInfoChanged");
	
	gCvarSwearGagTime = register_cvar( "amx_autogag_time", "3" ); // minutele pentru gag cand ia autogag
	gCvarGagMinuteLimit = register_cvar( "amx_gag_minute_limit", "10" ); // limita maxima pentru gag minute
	gCvarGagMinuteInSeconds = register_cvar( "amx_gag_minute_in_seconds", "60" ); // minute in secunde
	gCvarAdminGag = register_cvar( "amx_admingag", "0" ); // poti da si la admini gag daca e egal cu 1, daca e 0 nu poti
	gCvarWords = register_cvar( "amx_maxwords", "200" ); // lista maxima de cuvinte in gag_words.ini
	gCvarTag = register_cvar( "amx_gagtag", "[Gag System]" ); // tag-ul din chat
	
	iVault  =  nvault_open(  "GagSystem"  );
	
	if(  iVault  ==  INVALID_HANDLE  )
		{
		set_fail_state(  "nValut returned invalid handle!"  );
	}
	
	gMaxPlayers = get_maxplayers( );
	
}

public plugin_cfg( ) 
	{
	static szConfigDir[ 64 ], iFile[ 64 ];
	
	get_localinfo ( "amxx_configsdir", szConfigDir, 63 );
	formatex ( iFile , charsmax( iFile ) , "%s/%s" , szConfigDir, gGagFileName );
	
	if( !file_exists( iFile ) )
		{
		write_file( iFile, "# Pune aici cuvintele jignitoare sau reclamele", -1 );
		log_to_file( gLogFileName, "Fisierul <%s> nu exista! Creez unul nou acum...", iFile );
	}
	
	new szBuffer[ 128 ];
	new szFile = fopen( iFile, "rt" );
	
	while( !feof( szFile ) )
		{
		fgets( szFile, szBuffer, charsmax( szBuffer ) );
		
		if( szBuffer[ 0 ] == '#' )
			{
			continue;
		}
		
		parse( szBuffer, g_Words[ g_Count ], sizeof g_Words[ ] - 1 );
		g_Count++;
		
		if( g_Count >= get_pcvar_num ( gCvarWords ) )
			{
			break;
		}
	}
	
	fclose( szFile );
}


public client_putinserver( id ) 
	{ 
	if ( is_user_connected( id ) )
		{
		JoinTime[ id ] = get_systime( );
	}
}

public client_disconnect( id )
	{
	if ( PlayerGagged[ id ] == 1 )
		{	
		client_print_color( 0, print_team_red,  "^4[Gag System]^1 Jucătorul cu gag^3 %s^1(^3%s^1), s-a deconectat!", GetInfo( id, INFO_NAME ), GetInfo( id, INFO_IP ) );
		log_to_file( gLogFileName, "[EXIT]Jucatorul cu gag <%s><%s><%s>, s-a deconectat!", GetInfo( id, INFO_NAME ), GetInfo( id, INFO_IP ), GetInfo( id, INFO_AUTHID ) );
	}
	
	JoinTime[ id ] = 0 ;
	SaveGagedPlayers( id );
}

public client_connect( id )
	{
	LoadGagedPlayers( id );  
}

public CheckGag( id ) 
	{
	new szSaid[ 192 ];
	
	read_args( szSaid, charsmax( szSaid ) );
	remove_quotes( szSaid );
	
	if( !UTIL_IsValidMessage( szSaid ) )
		{
		return PLUGIN_HANDLED;
	}
	
	if ( PlayerGagged[ id ] == 1 ) 
		{
		PlayerGagged[ id ] = 1;
		
		client_print_color( id, print_team_red,  "^4[Gag System]^1 Ai primit Gag pentru^3 %s^1, asteaptă^3 %d^1 minute!", PlayerGagReason[ id ],PlayerGagTime[ id ] );
		
		
		return PLUGIN_HANDLED;
	}
	
	else
	{
		new i;
		for( i = 0; i < g_Count; i++ )
			{
			if( containi( szSaid, g_Words[ i ] ) != -1 )
				{
				if( get_pcvar_num( gCvarAdminGag ) == 0 )
					{
					if ( is_user_admin ( id ) )
						{	
						return 1;
					}
				}
				
				
				
				PlayerGagged[ id ] = 1;
				PlayerGagTime[ id ] = get_pcvar_num ( gCvarSwearGagTime );
				set_speak( id, SPEAK_MUTED );
				
				client_print_color( id, print_team_red,  "^4[Gag System]^1 Ai primit AutoGag pentru injuratură sau reclamă! Timpul expiră în:^3 %d^1 minute!", PlayerGagTime[ id ] );
				//client_print_color( id, print_team_red,  "^4[Gag System]^1 Nu mai poti folosi urmatoarele comenzi:^3 say^1,^3 say_team^1,^3 voice speak^1,^3 change name^1." );
				
				log_to_file( gLogFileName, "[AUTOGAG]<%s><%s><%s> a luat AutoGag pentru ca a injurat sau a facut reclama!", GetInfo( id, INFO_NAME ), GetInfo( id, INFO_IP ), GetInfo( id, INFO_AUTHID ) );
				
				
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public CommandGag( id )  
{
	new bool:acces;
	if( get_user_flags( id ) & COMMAND_ACCESS || get_user_flags(id) & ADMIN_LEVEL_H )
	{
		acces = true;
	}
	
	if ( !acces )
	{
		client_cmd( id, "echo %s Nu ai acces la aceasta comanda!", get_tag( ) );
		return 1;
	}
	
	new szArg[ 32 ], szMinutes[ 32 ], szReason[120];
	
	read_argv( 1, szArg, charsmax ( szArg ) );
	
	if( equal( szArg, "" ) )
		{
		client_cmd( id, "echo amx_gag < nume > < minute > < motiv >!" );
		return 1;
	}
	
	new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF );
	
	if( !iPlayer )
		{
		client_cmd( id, "echo %s Jucatorul specificat nu a fost gasit!", get_tag( ) );
		return 1;
	}
	
	if ( get_pcvar_num( gCvarAdminGag ) == 0 )
		{
		if ( get_user_flags( iPlayer ) & ADMIN_KICK )
			{
			if( !(get_user_flags( id ) & ADMIN_LEVEL_G) )
				{ 
				client_cmd( id, "echo %s Nu poti da gag la Admini!", get_tag( ) );
				return 1;
			}
		}
	}
	
	read_argv( 2, szMinutes, charsmax ( szMinutes ) );
	
	new iMinutes = str_to_num( szMinutes );
	
	if( iMinutes <= 0)
		{
		console_print(id, "Ai slectat o valoare invalida.");
		return 1;
	}
	
	
	if ( iMinutes > get_pcvar_num ( gCvarGagMinuteLimit ) )
		{
		if( !(get_user_flags( id ) & ADMIN_MENU) )
		{
      console_print( id, "%s Ai setat %d minute, iar limita maxima de minute este %d! Setare automata pe %d.", get_tag( ), iMinutes, get_pcvar_float ( gCvarGagMinuteLimit ), get_pcvar_float ( gCvarGagMinuteLimit ) );
      iMinutes = get_pcvar_num( gCvarGagMinuteLimit ) ;
		}
	}
	
	get_user_name( iPlayer, szName, sizeof ( szName ) -1 );
	
	szOldName[ iPlayer ] = szName;
	
	if( PlayerGagged[ iPlayer ] == 1 ) 
		{
		client_cmd( id, "echo %s Jucatorul %s are deja Gag!", get_tag( ), GetInfo( iPlayer, INFO_NAME ) );
		return 1;
	} 
	
	read_argv( 3, szReason, charsmax ( szReason ) );
	
	if(equal(szReason,"lbj")) 
		szReason = "Limbaj.";
	
	
	for ( new o = 0; o < sizeof ( gBlockTexts ); o++ ) {	
		if ( containi ( szReason, gBlockTexts [ o ] ) != -1 )
			{
			client_print(id, print_console, "Nu poti folosi CMD_BUG.");
			return 1;
		}	
	}
	
	PlayerGagged[ iPlayer ] = 1;
	PlayerGagTime[ iPlayer ] = iMinutes;
	//PlayerGagReason[ iPlayer ] = szReason;
	copy( PlayerGagReason[ iPlayer ], 31, szReason );
	remove_quotes( szReason );
	set_speak( iPlayer, SPEAK_MUTED );
	
	new players[32], plrsnum, pl
	get_players(players, plrsnum, "ch")
	for(new j; j<plrsnum; j++)
		{
		pl = players[j]
		
		if (is_user_admin(pl))
			{
			client_print_color( pl, print_team_red,  "^4[Gag System]^1 (%s) %s^1: Gag^3 %s^1 pentru^3 %d^1 minute, motiv :^3 %s.", Admin_Rank(id), GetInfo( id, INFO_NAME ), GetInfo( iPlayer, INFO_NAME ), iMinutes, szReason ); 
		}
		else
		{
			client_print_color( pl, print_team_red,  "^4[Gag System]^1 ADMIN^1: Gag^3 %s^1 pentru^3 %d^1 minute, motiv :^3 %s.", GetInfo( iPlayer, INFO_NAME ), iMinutes, szReason ); 
		}
	}
	client_print_color( iPlayer, print_team_red,  "^4[Gag System]^1 Ai primit Gag pentru că ai injurat sau ai facut reclamă!" ); 
	//client_print_color( iPlayer, print_team_red,  "^4[Gag System]^1 Nu mai poti folosi urmatoarele comenzi:^3 say^1,^3 say_team^1,^3 voice speak" );
	
	log_to_file( gLogFileName, "[GAG]%s i-a dat gag lui <%s><%s><%s> pentru. <%d> minute", GetInfo( id, INFO_NAME ), GetInfo( iPlayer, INFO_NAME ), GetInfo( iPlayer, INFO_IP ), GetInfo( iPlayer, INFO_AUTHID ), iMinutes );
	
	SaveGagedPlayers( id );
	return PLUGIN_HANDLED;
}

public ClientUserInfoChanged(id) 
	{ 
	static const name[] = "name" 
	static szOldName[32], szNewName[32] 
	pev(id, pev_netname, szOldName, charsmax(szOldName)) 
	if( szOldName[0] ) 
		{ 
		get_user_info(id, name, szNewName, charsmax(szNewName)) 
		if( !equal(szOldName, szNewName) ) 
			{ 
			if( PlayerGagged[ id ] == 1 )
				{ 
				client_print_color( id, print_team_red,  "^4[Gag System]^1 Nu iţi poţi schimba nickname-ul in timpul gag-ului !" ); 
				set_user_info(id, name, szOldName) 
				return FMRES_HANDLED
			}
		} 
	} 
	return FMRES_IGNORED 
}  

public CommandUngag( id )  
	{  
	if( !(get_user_flags( id ) & COMMAND_ACCESS2 ) )
		{
		client_cmd( id, "echo %s Nu ai acces la aceasta comanda!", get_tag( ) );
		return 1;
	}
	
	new szArg[ 32 ];
	
	read_argv( 1, szArg, charsmax( szArg ) );
	
	if( equal( szArg, "" ) )
		{
		client_cmd( id, "echo amx_ungag < nume > !" );
		return 1;
	}
	
	new iPlayer = cmd_target ( id, szArg, CMDTARGET_ALLOW_SELF );
	
	if( !iPlayer )
		{
		client_cmd(  id, "echo %s Jucatorul specificat nu a fost gasit!", get_tag( ) );
		return 1;
	}
	
	if( PlayerGagged[ iPlayer ] == 0 ) 
		{
		console_print( id, "%s Jucatorul %s nu are Gag!", get_tag( ), GetInfo( iPlayer, INFO_NAME ) );
		return 1;
	}
	
	
	PlayerGagged[ iPlayer ] = 0;
	PlayerGagTime[ iPlayer ] = 0;
	set_speak( iPlayer, SPEAK_NORMAL );
	
	new players[32], plrsnum, pl
	get_players(players, plrsnum, "ch")
	for(new j; j<plrsnum; j++)
		{
		pl = players[j]
		
		if (is_user_admin(pl))
			{
			client_print_color( pl, print_team_red,  "^4[Gag System]^1 (%s) %s^1: UnGag^3 %s^1 .", Admin_Rank(id), GetInfo( id, INFO_NAME ), GetInfo( iPlayer, INFO_NAME )); 
		}
		else
		{
			client_print_color( pl, print_team_red,  "^4[Gag System]^1 ADMIN^1: UnGag^3 %s^1 .", GetInfo( iPlayer, INFO_NAME )); 
		}
	}
	client_print_color( iPlayer, print_team_red,  "^4[Gag System]^1 Ai primit ungag ! Ai grijă la limbaj data viitoare!" );
	
	log_to_file( gLogFileName, "[UNGAG]<%s> i-a dat ungag lui <%s><%s><%s>", GetInfo( id, INFO_NAME ), GetInfo( iPlayer, INFO_NAME ), GetInfo( iPlayer, INFO_IP ), GetInfo( iPlayer, INFO_AUTHID ) );
	
	SaveGagedPlayers( id );
	return PLUGIN_HANDLED;
}

public Forward_GagThinker( iEntity )
	{
	if ( pev_valid( iEntity ) )
		{
		set_pev( iEntity, pev_nextthink, get_gametime( ) + 1.0 ) ;
		
		new id;
		for ( id = 1; id <= gMaxPlayers; id++ )
			{
			if ( is_user_connected ( id ) 	
			&& ! is_user_bot( id )
			&& PlayerGagged[ id ] == 1 
			&& PlayerGagTime[ id ] > 0
			&& ( ( get_systime( ) - JoinTime[ id ] ) >= get_pcvar_num ( gCvarGagMinuteInSeconds ) ) )
			{
				JoinTime[ id ] = get_systime( );
				PlayerGagTime[ id ] -= 1;
				
				if ( PlayerGagTime[ id ] <= 0 )
					{
					PlayerGagTime[ id ] = 0;
					PlayerGagged[ id ] = 0;
					set_speak( id, SPEAK_NORMAL );
					
					client_print_color( id, print_team_red,  "^4[Gag System]^1 Ai primit UnGag, ai grijă la limbaj data viitoare!" );
					log_to_file( gLogFileName, "[AUTOUNGAG]<%s> a primit AutoUnGag!", GetInfo( id, INFO_NAME ) );
					
					
					client_cmd( id, "name ^"%s^"", szOldName[ id ] );
				}
			}
		}
	}
}



stock GagThinker( )
	{
	new iEntity = create_entity ( "info_target" );
	
	if( ! pev_valid ( iEntity ) )
		{
		return PLUGIN_HANDLED;
	}
	
	set_pev ( iEntity, pev_classname, gGagThinkerClassname );
	set_pev ( iEntity, pev_nextthink, get_gametime( ) + 1.0 );
	
	return PLUGIN_HANDLED;
}

stock get_tag( )
	{
	new szTag [ 32 ];
	get_pcvar_string( gCvarTag, szTag, sizeof ( szTag ) -1 );
	
	return szTag;
}

stock GetInfo( id, const iInfo )
	{
	new szInfoToReturn[ 64 ];
	
	switch( iInfo )
	{
		case INFO_NAME:
		{
			new szName[ 32 ];
			get_user_name( id, szName, charsmax ( szName ) );
			
			copy( szInfoToReturn, charsmax ( szInfoToReturn ) , szName );
		}
		case INFO_IP:
		{
			new szIp[ 32 ];
			get_user_ip( id, szIp, charsmax ( szIp ) , 1 );
			
			copy( szInfoToReturn, charsmax ( szInfoToReturn ) , szIp );
		}
		case INFO_AUTHID:
		{
			new szAuthId[ 35 ];
			get_user_authid( id, szAuthId, charsmax ( szAuthId ) );
			
			copy( szInfoToReturn, charsmax ( szInfoToReturn ) ,  szAuthId );
		}
	}
	
	return szInfoToReturn;
}

stock bool:UTIL_IsValidMessage( const szSaid[ ] )
	{
	new iLen = strlen( szSaid );
	
	if( !iLen )
		{
		return false;
	}
	
	for( new i = 0; i < iLen; i++ )
		{
		if( szSaid[ i ] != ' ' )
			{
			return true;
		}
	}
	
	return false;
}

public LoadGagedPlayers( id )
	{
	new szIp[ 40 ], szVaultKey[ 64 ], szVaultData[ 64 ];
	get_user_ip( id, szIp, charsmax ( szIp ) );
	
	formatex( szVaultKey, charsmax( szVaultKey ), "%s-Gag", szIp );
	formatex( szVaultData, charsmax( szVaultData ), "%i#%i", PlayerGagged[ id ], PlayerGagTime[ id ] );
	nvault_get( iVault, szVaultKey, szVaultData, charsmax ( szVaultData ) );
	
	replace_all( szVaultData, charsmax( szVaultData ), "#", " " );
	
	new iGagOn[ 32 ], iGagTime [ 32 ];
	parse( szVaultData, iGagOn, charsmax ( iGagOn ), iGagTime, charsmax ( iGagTime ) );
	
	PlayerGagged[ id ] = str_to_num ( iGagOn );
	PlayerGagTime[ id ] = clamp ( str_to_num ( iGagTime ), 0, get_pcvar_num ( gCvarGagMinuteLimit ) );
	
}

public SaveGagedPlayers(  id  )
	{
	
	new szIp[ 40 ], szVaultKey[ 64 ], szVaultData[ 64 ];
	get_user_ip( id, szIp, charsmax( szIp ) );
	
	formatex( szVaultKey, charsmax( szVaultKey ), "%s-Gag", szIp );
	formatex( szVaultData, charsmax( szVaultData ), "%i#%i", PlayerGagged[ id ], PlayerGagTime[ id ] );
	
	nvault_set( iVault, szVaultKey, szVaultData );
}

public plugin_end( )
	{
	nvault_close( iVault );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
