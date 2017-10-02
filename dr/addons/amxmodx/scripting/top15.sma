#include < amxmodx >
#include < csx >
 
#pragma semicolon 1
 
#define INT_MAX_PLAYERS_MENU 360
 
enum {
   INT_STATS_KILLS = 0
};
 
new g_iMessageSayText;
 
public plugin_init( ) {
   register_plugin( "Top DR", "1.0", "Dr.FioriGinal.RO" );
 
   register_clcmd( "say", "CLIENT_COMMAND_HOOK" );
   register_clcmd( "say_team", "CLIENT_COMMAND_HOOK" );
  
   
   g_iMessageSayText = get_user_msgid( "SayText" );
}
 
public CLIENT_COMMAND_HOOK( INT_PLAYER ) {
   static STRING_ARGUMENT[ 11 ];
   read_argv( 1, STRING_ARGUMENT, charsmax( STRING_ARGUMENT ) );
   
   // TOP
   if( equali( STRING_ARGUMENT, "!top", 4 ) ) {
      new HANDLE_MENU = menu_create( "Top Dr.FioriGinal.Ro", "FUNC_MENU_HANDLER" );
      new STRING_STATS[ 8 ], STRING_BODY[ 8 ], STRING_NAME[ 32 ], STRING_TEMP[ 128 ], STRING_TEMP_NUM[ 4 ], INT_VARIABLE, STATSNUM = get_statsnum( );
     
      if( STATSNUM < INT_MAX_PLAYERS_MENU )
         INT_VARIABLE = STATSNUM;
     
      else
         INT_VARIABLE = INT_MAX_PLAYERS_MENU;
     
      for( new INT_VARIABLE2 = 0; INT_VARIABLE2 < INT_VARIABLE; INT_VARIABLE2++ ) {
         get_stats( INT_VARIABLE2, STRING_STATS, STRING_BODY, STRING_NAME, charsmax( STRING_NAME ) );
         
         num_to_str( INT_VARIABLE2 + 1, STRING_TEMP_NUM, charsmax( STRING_TEMP_NUM ) );
         
         format( STRING_TEMP, charsmax( STRING_TEMP ), "\y%s \wKills: \r%i", STRING_NAME,  \
            STRING_STATS[ INT_STATS_KILLS ] );
         
         menu_additem( HANDLE_MENU, STRING_TEMP, STRING_TEMP_NUM, 0 );
      }
     
      menu_setprop( HANDLE_MENU, MPROP_EXITNAME, "Exit" );
      menu_setprop( HANDLE_MENU, MPROP_NEXTNAME, "Next" );
      menu_setprop( HANDLE_MENU, MPROP_BACKNAME, "Back" );
     
      menu_display( INT_PLAYER, HANDLE_MENU, 0 );
     
      client_cmd( INT_PLAYER, "spk buttons/button9" );
   }
   
}
 
public FUNC_MENU_HANDLER( INT_PLAYER, INT_MENU, INT_ITEM )
   return PLUGIN_HANDLED;
 
public FUNC_MENU_STATS_HANDLER( INT_PLAYER, INT_MENU, INT_ITEM ) {
   new STRING_COMMAND[ 6 ], STRING_NAME[ 64 ], INT_ACCESS, INT_CALLBACK, INT_VICTIM;
   menu_item_getinfo( INT_MENU, INT_ITEM, INT_ACCESS, STRING_COMMAND, charsmax( STRING_COMMAND ), STRING_NAME, charsmax( STRING_NAME ), INT_CALLBACK );
   INT_VICTIM = get_user_index( STRING_NAME );
   
   if( is_user_connected( INT_VICTIM ) )
      FUNC_STATS_ME( INT_PLAYER, INT_VICTIM );
   
   else {
      ColorChat( INT_PLAYER, "^x01The player you choosed is disconnected!" );
      return PLUGIN_HANDLED;
   }
   
   return PLUGIN_HANDLED;
}
 
public FUNC_STATS_ME( INT_PLAYER, VICTIM ) {
   new INT_RANK_POS, STRING_STATS[ 8 ], STRING_BODY[ 8 ], STRING_TEMP[ 128 ], STRING_STATS2[ 4 ], STRING_NAME[ 32 ];
   INT_RANK_POS = get_user_stats( VICTIM, STRING_STATS, STRING_BODY );
   get_user_stats2( VICTIM, STRING_STATS2 );
   get_user_name( VICTIM, STRING_NAME, charsmax( STRING_NAME ) );
   
   new HANDLE_MENU = menu_create( "Rank", "FUNC_MENU_HANDLER" );
   
   format( STRING_TEMP, charsmax( STRING_TEMP ), "\wUser: \r%s", STRING_NAME );
   menu_additem( HANDLE_MENU, STRING_TEMP, "1", 0 );
   
   format( STRING_TEMP, charsmax( STRING_TEMP ), "\wRank: \r%i", INT_RANK_POS );
   menu_additem( HANDLE_MENU, STRING_TEMP, "2", 0 );
   
   format( STRING_TEMP, charsmax( STRING_TEMP ), "\wKills: \r%i", STRING_STATS[ INT_STATS_KILLS ] );
   menu_additem( HANDLE_MENU, STRING_TEMP, "3", 0 );
   
   menu_setprop( HANDLE_MENU, MPROP_EXITNAME, "Exit" );
   menu_setprop( HANDLE_MENU, MPROP_NEXTNAME, "Next" );
   menu_setprop( HANDLE_MENU, MPROP_BACKNAME, "Back" );
   
   menu_display( INT_PLAYER, HANDLE_MENU, 0 );
   
   client_cmd( INT_PLAYER, "spk buttons/button9" );
}
 
ColorChat( iTarget, szMessage[ ], any: ... ) {
   static szBuffer[ 189 ];
   vformat( szBuffer, 188, szMessage, 3 );
   
   if( iTarget ) {
      message_begin( MSG_ONE_UNRELIABLE, g_iMessageSayText, _, iTarget );
      write_byte( iTarget );
      write_string( szBuffer );
      message_end( );
   } else {
      static iPlayers[ 32 ], iNum, i, iPlayer;
      get_players( iPlayers, iNum, "c" );
     
      for( i = 0; i < iNum; i++ ) {
         iPlayer = iPlayers[ i ];
         
         message_begin( MSG_ONE_UNRELIABLE, g_iMessageSayText, _, iPlayer );
         write_byte( iPlayer );
         write_string( szBuffer );
         message_end( );
      }
   }
}
