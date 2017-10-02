#include < amxmodx >
#include < amxmisc >
#include < hamsandwich >
#include < fakemeta >
 
new const PLUGIN[ ] = "Christmas Candy Cane Knife";
new const VERSION[ ] = "1.0";
 
new const g_szCandyCaneModel[ ][ ] =
{
        "models/candy_cane/v_candy_cane_01.mdl",
        "models/candy_cane/v_candy_cane_02.mdl",
        "models/candy_cane/v_candy_cane_03.mdl",
        "models/candy_cane/v_candy_cane_04.mdl",
        "models/candy_cane/v_candy_cane_05.mdl",
        "models/candy_cane/v_candy_cane_06.mdl",
        "models/candy_cane/v_candy_cane_07.mdl",
        "models/candy_cane/p_candy_cane_01.mdl",
        "models/candy_cane/p_candy_cane_02.mdl",
        "models/candy_cane/p_candy_cane_03.mdl",
        "models/candy_cane/p_candy_cane_04.mdl",
        "models/candy_cane/p_candy_cane_05.mdl",
        "models/candy_cane/p_candy_cane_06.mdl",
        "models/candy_cane/p_candy_cane_07.mdl"
}
 
public plugin_precache( )
{
        for( new i = 0; i < sizeof g_szCandyCaneModel; i++ )
                engfunc( EngFunc_PrecacheModel, g_szCandyCaneModel[ i ] );
}
 
public plugin_init( )
{
        register_plugin( PLUGIN, VERSION, "Adventx" )
       
        // Ham Forwards
        RegisterHam( Ham_Item_Deploy, "weapon_knife", "fw_Item_Deploy", 1 )
       
        // other
        register_cvar( "candycane_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY )
}
 
public fw_Item_Deploy( ent )
{
        static id
        id = get_pdata_cbase( ent, 41, 4 )
       
        switch( random_num( 1, 7 ) )
        {
                case 1:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 0 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 7 ] );      
                }
               
                case 2:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 1 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 8 ] );
                }
               
                case 3:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 2 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 9 ] );
                }
               
                case 4:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 3 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 10 ] );
                }
               
                case 5:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 4 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 11 ] );
                }
               
                case 6:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 5 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 12 ] );
                }
               
                case 7:
                {
                        set_pev( id, pev_viewmodel2, g_szCandyCaneModel[ 6 ] );
                        set_pev( id, pev_weaponmodel2, g_szCandyCaneModel[ 13 ] );
                }
        }
}