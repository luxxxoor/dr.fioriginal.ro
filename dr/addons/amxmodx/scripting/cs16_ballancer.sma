#include < amxmodx >
#include < cstrike >

#define PLUGIN "CS16 Ballancer"
#define VERSION "0.1"
#define AUTHOR "aNNakin"

new gi_MaxPlayers;

new const gs_Teams[ ][ ] =
{
	"TERRORIST",
	"CT"
};

// - - - - - - - - -
#define	INTERVAL 30	/* din cate in cate secunde se vor verifica echipele */
const i_Immunity = 1;	/* 1 = adminii au imunitate, 0 adminii nu au imunitate */
// - - - - - - - - -

public plugin_init ( )
{
	register_plugin ( PLUGIN, VERSION, AUTHOR );
	gi_MaxPlayers = get_maxplayers ( );
	set_task ( float ( INTERVAL ), "CheckTeams", _, _, _, "b" );
}

public CheckTeams ( )
{
	new i_TsNum = get_team_num ( 1 );
	new i_CTsNum = get_team_num ( 2 );
	
	while ( ( i_TsNum - i_CTsNum ) > 1 )
	{
		i_TsNum--; ++i_CTsNum;
		transfer_user ( 1, 2 );
	}
	
	while ( ( i_TsNum - i_CTsNum ) < -1 )
	{
		i_TsNum++; --i_CTsNum;
		transfer_user ( 2, 1 );
	}
		
}

stock get_team_num ( i_Team )
{
	new i_Count, i_Index;
	
	for ( i_Index = 1; i_Index <= gi_MaxPlayers; i_Index++ )
		if ( get_user_team ( i_Index ) == i_Team )
			i_Count++;
			
	return i_Count;
}

stock transfer_user ( i_From, i_To )
{
	new i_Players[ 32 ], i_Num;
	get_players ( i_Players, i_Num, "ae", gs_Teams[ ( i_From - 1 ) ] )
	
	ChoosePlayer:
	new i_Player = i_Players[ random_num ( 0, i_Num-1 ) ];
	
	if ( ! is_user_alive ( i_Player ) || ( i_Immunity && get_user_flags ( i_Player ) & ADMIN_IMMUNITY ) )
		goto ChoosePlayer;
	
	switch ( i_To )
	{
		case 1: cs_set_user_team ( i_Player, CS_TEAM_T );
		case 2: cs_set_user_team ( i_Player, CS_TEAM_CT );
	}
	
	set_hudmessage ( 255, 85, 0, 0.01, 0.26, 0, 6.0, 7.0 );
	show_hudmessage ( i_Player, "Ai fost transferat la cealalalta echipa^npentru a echilibra jocul.")
	
	client_print ( i_Player, print_chat, "Ai fost transferat la cealalalta echipa pentru a echilibra jocul." );
}
