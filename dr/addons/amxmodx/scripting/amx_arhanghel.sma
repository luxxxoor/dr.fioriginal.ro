#include <amxmodx>
#include <amxmisc>

#define NUME_PLUGIN      "amx_arhanghel"
#define VERSIUNE_PLUGIN  "0.3"
#define CREATOR_PLUGIN   "wEN/luxor" // update cu colorchat si cvar (de lux)

#define ACCES_COMANDA ADMIN_LEVEL_G

new Status;
new g_nuSperiaAdminul;

public plugin_init() {
    register_plugin(NUME_PLUGIN, VERSIUNE_PLUGIN, CREATOR_PLUGIN)
    register_concmd("amx_arhanghel", "AMXSCARY", ACCES_COMANDA, "- >nume sau userid< - sperii un jucator")

    Status = register_cvar("amx_live_scary_on", "1")  // Pluginul este activ (1 DA, 0 NU) - (default: 1)
    g_nuSperiaAdminul = register_cvar( "amx_sperie_adminul", "1" ); // poti da si la admini gag daca e egal cu 1, daca e 0 nu poti
}

public AMXSCARY(id, level, cid) {
    if(get_pcvar_num(Status) == 0)
    return PLUGIN_HANDLED
    
    new szArg[ 32 ];

    read_argv( 1, szArg, charsmax ( szArg ) );
    
    new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF );
    
    if ( get_pcvar_num( g_nuSperiaAdminul ) == 0 )
    {
      if ( is_user_admin( iPlayer ) )
      {
        client_print( id, print_console,"Nu poti folosi comanda pe Admini!" );
        return 1;
      }
    }

    if(!cmd_access(id, level, cid, 2)) {
        client_cmd(id,"spk ^"vox/access denied^"");
        return PLUGIN_HANDLED;
    }

    new arg[32];
    read_argv(1, arg, 31);
    new jucator = cmd_target(id, arg);

    if (!jucator)
        return PLUGIN_HANDLED;

    new Tinta[32], Admin[32];
    get_user_name(jucator, Tinta, 31);
    get_user_name(id, Admin, 31);

    client_cmd(jucator, "spk ^"vox/bizwarn detected user and destroy^"");
    show_motd(jucator, "http://inciswf.com/1332235315120.swf", "Tocmai ai fost speriat!");
    client_print_color(0, print_team_red, "^x04[Dr.Fioriginal.Ro] ^x03%s i-a pomenit toti arhanghelii lui ^x01%s", Admin, Tinta);
    client_print_color(0, print_team_red, "^x04[Dr.Fioriginal.Ro] ^x01%s ^x03 tocmai a ^x04 FACUT PE EL^x03!", Tinta);

    return PLUGIN_HANDLED;
}