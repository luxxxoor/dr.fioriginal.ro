/*
xJailbreak MOD:
Version 0.1.0 - Release
Added say system
Added cvar system
Added block buy zones
Added prefix
Added Contact command
Added HP display system
Added lang
Added Sql save system
Added Save Time
Added chooseteam menui
Added points system
Added ban system
Added drugs system
Added vip system
Added voice system
Added give/take time
Added simon system
Added gun menu
Update the sql save system
Update Vip system
Added real shop menu
Added points shop menu
Added drugs shop menu
Added heal system
Added simon ring
Updated Ban system
Added Mute system
Updated Sql save system
Updated Mute and Ban system
Updated Sql save system
Added Info command
Update class
Update mute/banct/gold
Added strip for spawn
Rewrited Sql
Added Register
Updated Sql
Added level mod
Update Level mod
Added Costumes
Added xp display
Updated xp display
Updated xp display with new things
Updated Gold & Nova
Added Sprint System
Updated Sprint system
*/
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <engine>
//#include <chr_engine>
#include <sqlx>
#include <xs>
 
#pragma semicolon 1;
#pragma dynamic 32768
new const g_Info[][] =
{
        "xJailbreak Mod",
        "0.1.0",
        "eNd.",
        "skitaila03"
};
 
#define get_bit(%1,%2)          (%1 & 1<<(%2&31))
#define set_bit(%1,%2)          %1 |= (1<<(%2&31))
#define clear_bit(%1,%2)        %1 &= ~(1<<(%2&31))
new g_iMaxPlayers;
#define FIRST_PLAYER_ID 1
#define IsPlayer(%1) (FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers)
#define OFFSET_CSMONEY 115
#define m_flWait   44
#define m_flNextPrimaryAttack   46
#define m_flNextSecondaryAttack 47
#define m_flNextAttack 83
#define m_pActiveItem    373
#define m_pClientActiveItem 374
#define m_iHideHUD      361
#define m_iClientHideHUD        362
#define m_iFOV  363
#define XO_PLAYER  5
#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )
/////////////////////////////////////////////////
#define ADMIN_GIVE ADMIN_RCON
#define ADMIN_TAKE ADMIN_RCON
/////////////////////////////////////////////////
new Host[]   = "89.40.104.2";
new User[]   = "vuser626";
new Pass[]   = "parola";
new Db[]     = "vuser626";
 
new Handle:g_SqlConnection;
new Handle:g_SqlTuple;
new g_Error[512];
 
new g_iSqlReady = false;
 
new g_iAuth[MAX_PLAYERS + 1];
new bool:g_bLoaded[MAX_PLAYERS + 1][9];
 
#define MaxLevels 3
new g_iLevel[MAX_PLAYERS +1];
new g_iExp[MAX_PLAYERS +1];
new const Levels[MaxLevels] =
{
        180, // Level #1
        600, // Level #2
        1500 // Level #3
 
};
new g_iCheck[MAX_PLAYERS + 1];
new g_iGang[MAX_PLAYERS + 1][32];
new g_iRank[MAX_PLAYERS + 1][32];
enum _:GangInfo
{
        Trie:GangMembers,
        GangName[64],
        GangKills,
        NumMembers
};
enum _:Status
{
        STATUS_NONE,
        STATUS_MEMBER,
        STATUS_ADMIN,
        STATUS_LEADER
}
new const status_name[Status][] =
{
        "none",
        "member",
        "admin",
        "leader"
};
enum
{
        VALUE_KILLS
}
new const g_szGangValues[ ][ ] =
{
        "Kills"
};
 
new Trie:g_tGangNames;
new Trie:g_tGangValues;
new Array:g_aGangs;
new g_iPassword[MAX_PLAYERS + 1][32];
new g_iEmail[MAX_PLAYERS + 1][32];
new g_iRegister[MAX_PLAYERS + 1];
new g_iTempLogin[MAX_PLAYERS + 1];
new g_iAttempt[MAX_PLAYERS + 1];
new g_iTempEmail[MAX_PLAYERS + 1][32];
new g_iTempPassword[MAX_PLAYERS + 1][32];
new g_iPlayerTime[MAX_PLAYERS + 1];
new g_iPoints[MAX_PLAYERS + 1];
new g_iDrugs[MAX_PLAYERS + 1];
new g_iMoneys[MAX_PLAYERS + 1];
new g_iBan[MAX_PLAYERS + 1];
new g_iBanTime[MAX_PLAYERS + 1];
new g_iBanReason[MAX_PLAYERS + 1][32];
new g_iBanName[MAX_PLAYERS + 1][32];
new g_iMute[MAX_PLAYERS + 1];
new g_iMuteTime[MAX_PLAYERS + 1];
new g_iMuteReason[MAX_PLAYERS + 1][32];
new g_iMuteName[MAX_PLAYERS + 1][32];
new g_iNova[MAX_PLAYERS + 1];
new g_iGold[MAX_PLAYERS + 1];
new g_iGoldTime[MAX_PLAYERS + 1];
new g_iJoinTime[MAX_PLAYERS + 1];
/////////////////////////////////////////////////
#define TEAMJOIN_TEAM                   "1"
#define TEAMJOIN_CLASS                  "2"
new const FIRST_JOIN_MSG[ ]             = "#Team_Select";
new const FIRST_JOIN_MSG_SPEC[ ]        = "#Team_Select_Spect";
new const INGAME_JOIN_MSG[ ]            = "#IG_Team_Select";
new const INGAME_JOIN_MSG_SPEC[ ]       = "#IG_Team_Select_Spect";
const g_iJoinMsgLen                     = sizeof( INGAME_JOIN_MSG_SPEC );
 
#define SPEAK_TEAM  4
new g_iSpeakFlags[33];
new const g_iSpeakNames[][] = {
        "",
        "Normal",
        "All",
        "Muted",
        "Team"
};
 
 
//new Float:g_fRoundStartTime;
//new Float:g_fRoundTime;
 
new g_iMsgStatus;
new g_iMsgShowMenu;
new g_iMsgVguiMenu;
new g_iHudText;
new g_iStatusText;
new g_iMoney;
new g_iScreenFade;
 
new g_bIsFirstConnected;
new g_bIsSimon;        
 
new g_Color[MAX_PLAYERS + 1][3];
new bool:g_bDisplayFix[MAX_PLAYERS + 1];
new bool:g_bHealth[MAX_PLAYERS + 1];
new bool:g_bPluginCommand;
new bool:g_bCanBuy;            
new g_bHasMenuOpen;            
new g_bHasHealth;
new g_bHasDrugs;
new g_bHasFlashBang;
new g_bHasCellKey;
new g_bHasGunGamble;
new g_bHasDisguise;
new g_bHasFreeday;
 
new g_bHasCrowbar;
new g_bHasBanana;
new g_bHasNail;
new g_bHasPipe;
new g_bHasUsp;
new g_bHasGlock;
new g_bHasInvest;
 
new g_sCrowbar;
new g_sBanana;
new g_sNail;
new g_sPipe;
new g_sUsp;
new g_sGlock;
new g_sInvest;
 
new g_sHealth;
new g_sDrugs;
new g_sFlashBang;
new g_sCellKey;
new g_sGunGamble;
new g_sDisguise;
new g_sFreeday;
 
new g_HudHP;
new g_HudSyncStatusText;
new g_iTimerEntity;
new g_iRingSprite;
/////////////////////////////////////////////////
new bool:g_bIsUserSprinting[MAX_PLAYERS+1];
new bool:g_bUserCanSprint[MAX_PLAYERS+1];
new Float:g_fLastSprintUsed[MAX_PLAYERS+1];
new Float:g_fLastKeyPressed[MAX_PLAYERS+1];
new Float:g_fLastSprintReleased[MAX_PLAYERS+1];
new Float:g_fSprintTime[MAX_PLAYERS+1];
/////////////////////////////////////////////////
enum _:( += 669 )
{
        TASK_HEALTH,
        TASK_TEAMJOIN,
        TASK_SIMONBEAM
};
/////////////////////////////////////////////////
 
enum _:DATA_ROUND_SOUND
{
        FILE_NAME[32],
        TRACK_NAME[64]
}
new Array:g_aDataRoundSound, g_iRoundSoundSize;
 
enum _:DATA_COSTUMES
{
        COSTUMES,
        ENTITY,
        bool:HIDE
}
new Array:g_aCostumesList, g_iCostumesListSize, g_eUserCostumes[MAX_PLAYERS + 1][DATA_COSTUMES];
 
/////////////////////////////////////////////////
new const g_szClassNameCrowbar[] = "class_crowbar";
new const CrowbarModels[][] =
{
        "models/xjailbreak/w_crowbar2.mdl"
};
 
new const ExhaustedSound[][] =
{      
        "xjailbreak/exhaust/exhausted_breathing.wav"
};
/////////////////////////////////////////////////
enum _:Cvars
{      
        cvar_prefix,
        cvar_team_ratio,
        cvar_time_ct,
        cvar_flashlight,
        cvar_flashlight_vip_level,
        cvar_blockvoice,
        cvar_blockvoice_level,
        cvar_moneypoint,
        cvar_sprayenable,
        cvar_shootbuttons,
        cvar_search,
        cvar_search_chance,
        cvar_max_simons,
        cvar_min_tero_simon,
        cvar_gold_time,
        cvar_nova_time,
        cvar_money,
        cvar_gold_cost,
        cvar_nova_cost,
        cvar_drugs_quant,
        cvar_drugs_cost,
        cvar_points_quant,
        cvar_points_cost,
        cvar_gang_cost,
        cvar_shop,
        cvar_health_price,
        cvar_health_limit,
        cvar_health_quant,
        cvar_flashbang_price,
        cvar_flashbang_limit,
        cvar_drugs_price,
        cvar_drugs_limit,
        cvar_drugs_quants,
        cvar_key_price,
        cvar_key_limit,
        cvar_gamble_price,
        cvar_gamble_chance,
        cvar_gamble_limit,
        cvar_disguise_price,
        cvar_disguise_limit,
        cvar_freeday_price,
        cvar_freeday_limit,
        cvar_drugs,
        cvar_min_ct_drugs,
        cvar_crowbar_price,
        cvar_crowbar_limit,
        cvar_crowbar_chance,
        cvar_pipe_price,
        cvar_pipe_limit,
        cvar_pipe_chance,
        cvar_nail_price,
        cvar_nail_limit,
        cvar_nail_chance,
        cvar_banana_price,
        cvar_banana_limit,
        cvar_banana_chance,
        cvar_usp_price,
        cvar_usp_limit,
        cvar_usp_chance,
        cvar_glock_price,
        cvar_glock_limit,
        cvar_glock_chance,
        cvar_invest_price,
        cvar_invest_limit,
        cvar_invest_chance,
        cvar_invest_bonus,
        cvar_login_register_account,
        cvar_attempt,
        cvar_register_time,
        cvar_sprint,
        cvar_sprint_speed,
        cvar_sprint_cooldown,
        cvar_sprint_key,
        cvar_sprint_time,
        cvar_gang
};
new const cvar_names[Cvars][] =
{
        "jb_prefix",            // Prefix
        "jb_team_ratio",        // Team ratio
        "jb_time_ct",           // Time spent to become ct
        "jb_flashlight",        // 0-Flashlight off 1- Flashlight on
        "jb_flashlight_vip_level",// 0- All can use flashlight, 1- Vip1+ can use flashlight, 2- Only vip2 can use
        "jb_blockvoice",        // 0- Alltalk 1- Guards can't hear prisoners 2- Prisoners can't talk
        "jb_blockvoice_level", // Level for speak from tero.
        "jb_moneypoints",       // 0- MoneyPoints off 1- MoneyPoints on
        "jb_sprayenable",       // 0- MoneyPoints off 1- Spray on
        "jb_shootbuttons",      // 0- ShootButton off 1- ShotButton on
        "jb_search",            // 0- Search off 1- Search on
        "jb_search_chance",     // set the search chance
        "jb_max_simons",        // set the max simon
        "jb_min_tero_simon",    // set he minimum prisonier to become simon
        "jb_gold_time",         // set the time for gold vip(days)
        "jb_nova_time",         // set the min time for nova vip(days)
        "jb_money",             // 0- Real Shop off 1- Real Shop on
        "jb_gold_price`",       // set the price for gold vip
        "jb_nova_price`",       // set the price for nova vip
        "jb_drugs_quant",       // set the quantity for drugs
        "jb_drugs_cost",        // set the price for drugs
        "jb_points_quants",     // set the quantity for points
        "jb_points_cost",       // set the price for points
        "jb_gang_cost",         // set the price for gang
        "jb_shop",              // 0- Shop off 1- Shop on
        "jb_health_price",      // set the health price
        "jb_health_limit",      // set the health limit
        "jb_health_quant",      // set the health quantity
        "jb_flashbang_price",   // set the flashbang price
        "jb_flashbang_limit",   // set the flashbang limit
        "jb_drugs_price",       // set the drugs price
        "jb_drugs_limit",       // set the drugs limit
        "jb_drugs_quant",       // set the drugs quantity
        "jb_key_price",         // set the key price
        "jb_key_limit",         // set the key limit
        "jb_gamble_price",      // set the gamble price
        "jb_gamble_chance",     // set the gamble chance
        "jb_gamble_limit",      // set the gamble limit
        "jb_disguise_price",    // set the disguise price
        "jb_disguise_limit",    // set the disguise limit
        "jb_freeday_price",     // set the freeday price
        "jb_freeday_limit",     // set the freeday limit
        "jb_drugs",             // 0- Drugs Shop off 1- Drugs Shop on
        "jb_min_ct_drugs",      // set he minimum ct to use drugs shop
        "jb_crowbar_price",     // set the crowbar price
        "jb_crowbar_limit",     // set the crowbar limit
        "jb_crowbar_chance",    // set the crowbar chance
        "jb_pipe_price",        // set the pipe price
        "jb_pipe_limit",        // set the pipe limit
        "jb_pipe_chance",       // set the pipe chance
        "jb_nail_price",        // set the nail price
        "jb_nail_limit",        // set the nail limit
        "jb_nail_chance",       // set the nail chance
        "jb_banana_price",      // set the banana price
        "jb_banana_limit",      // set the banana limit
        "jb_banana_chance",     // set the banana chance
        "jb_usp_price",         // set the usp price
        "jb_usp_limit",         // set the usp limit
        "jb_usp_chance",        // set the usp chance
        "jb_glock_price",       // set the glock price
        "jb_glock_limit",       // set the glock limit
        "jb_glock_chance",      // set the glock chance
        "jb_invest_price",      // set the invest price
        "jb_invest_limit",      // set the invest limit
        "jb_invest_chance",     // set the invest chance
        "jb_invest_bonus",      // set the invest bonus
        "jb_login_register_account",    // set the login/register/account system
        "jb_attempt",           // set the attempt for login
        "jb_register_time",     // set the min time for register
        "jb_sprint",            // set the sprint on/off
        "jb_sprint_speed",      // set the sprint speed
        "jb_sprint_cooldown",   // set the sprint cooldown
        "jb_sprint_key",        // set the key interval
        "jb_sprint_time",       // set the sprint time
        "jb_gang"               // set the gang on/off
};
new const cvar_defaults[Cvars][] = {
        "*",    // Prefix
        "3",    // Team ratio
        "15",   // Time spent to become ct
        "1",    // 0- Flashlight off 1- Flashlight on  
        "1",    // 0- All can use flashlight, 1- Vip1+ can use flashlight, 2- Only vip2 can use
        "2",    // 0- Alltalk 1- Guards can't hear prisoners 2- Prisoners can't talk
        "l",    // Level for speak from tero.
        "1",    // 0- MoneyPoints off 1- MoneyPoints on
        "1",    // 0- MoneyPoints off 1- Spray on
        "1",    // 0- ShootButton off 1- ShotButton on
        "1",    // 0- Search off 1- Search on
        "325",  // set the search chance
        "1",    // set the max simon
        "2",    // set he minimum prisonier to become simon
        "3",    // set the time for gold vip(days)
        "4",    // set the min time for nova vip(days)
        "1",    // 0- Real Shop off 1- Real Shop on
        "10",   // set the price for gold vip
        "5",    // set the price for nova vip
        "250",  // set the quantity for drugs
        "5",    // set the price for drugs
        "250",  // set the quantity for points
        "5",    // set the price for points
        "5",            // set the price for gang
        "1",    // 0- Shop off 1- Shop on
        "6",    // set the health price
        "2",    // set the health limit
        "30",   // set the health quant
        "3",    // set the flashbang price
        "2",    // set the flashbang limit
        "23",   // set the drugs price
        "2",    // set the drugs limit
        "4",    // set the drugs quant
        "13",   // set the key price
        "2",    // set the key limit
        "5",    // set the gamble price
        "12",   // set the gamble change. Min is 7
        "2",    // set the gamble limit
        "14",   // set the disguise price
        "2",    // set the disguise limit
        "18",   // set the freeday price
        "2",    // set the freeday limit
        "1",    // 0- Drugs Shop off 1- Drugs Shop on
        "1",    // set he minimum ct to use drugs shop
        "3",    // set the crowbar price
        "2",    // set the crowbar limit
        "2",    // set the crowbar chance
        "4",    // set the pipe price
        "2",    // set the pipe limit
        "2",    // set the pipe chance
        "3",    // set the nail price
        "2",    // set the nail limit
        "2",    // set the nail chance
        "2",    // set the banana price
        "2",    // set the banana limit
        "2",    // set the banana chance
        "5",    // set the usp price
        "2",    // set the usp limit
        "2",    // set the usp chance
        "5",    // set the glock price
        "2",    // set the glock limit
        "2",    // set the glock chance
        "3",    // set the invest price
        "2",    // set the invest limit
        "2",    // set the invest chance
        "3",    // set the invest bonus
        "1",    // set the login/register/account system
        "3",    // set the attempt for login
        "5",    // set the min time for register(hours)
        "1",    // set the sprint on/off
        "0.5",  // set the sprint speed
        "15.0", // set the sprint cooldown
        "0.2",  // set the key interval
        "2.5",  // set the sprint time
        "1"     // set the gang on/off
};
new cvar_pointer[Cvars];
 
new const SayClientCmds[][64] = {
        "contact", "ClCmd_Contact", "hp", "ClCmd_Health", "time", "ClCmd_Time", "points", "ClCmd_Points", "drugs", "ClCmd_Drugs", "search", "ClCmd_Search",
        "vip0", "ClCmd_Vip0", "nova", "ClCmd_Nova", "gold", "ClCmd_Gold", "costumes", "ClCmd_Costumes",
        "talkchannel", "ClCmd_Channel", "talk", "ClCmd_Channel", "channel", "ClCmd_Channel", "mic", "ClCmd_Channel",
        "simon", "ClCmd_Simon", "sef", "ClCmd_Simon", "lider", "ClCmd_Simon", "class", "ClCmd_ClassMenu", "guns", "ClCmd_ClassMenu",
        "rshop", "ClCmd_MoneyMenu", "shop", "ClCmd_ShopMenu", "bshop", "ClCmd_DrugsMenu", "heal", "ClCmd_Heal",
        "info", "ClCmd_Info", "register", "ClCmd_RegisterSay", "login", "ClCmd_LoginSay", "myaccount", "ClCmd_MyAccount",
        "level", "ClCmd_Level", "rank", "ClCmd_Rank", "top15", "ClCmd_Top15",
        "gang", "ClCmd_Gang", "clear", "ClCmd_Clear"
};
 
 
/////////////////////////////////////////////////
public plugin_init()
{
        register_plugin(g_Info[0], g_Info[1], g_Info[random_num(2,3)] );
 
        register_dictionary("xjailbreakmod.txt");
 
        g_iMaxPlayers   = get_maxplayers();
        g_iMsgStatus    = get_user_msgid( "StatusIcon" );
        g_iHudText      = get_user_msgid( "HudTextArgs" );
        g_iStatusText   = get_user_msgid( "StatusText" );
        g_iMsgShowMenu  = get_user_msgid( "ShowMenu" );
        g_iMsgVguiMenu  = get_user_msgid( "VGUIMenu" );
        g_iMoney        = get_user_msgid("Money");
        g_iScreenFade   = get_user_msgid("ScreenFade");
 
        g_aGangs        = ArrayCreate( GangInfo );
        g_tGangNames    = TrieCreate();
        g_tGangValues   = TrieCreate();
        register_event("Money", "Event_Money", "b");
        register_event("23", "Event_Spray", "a", "1=112");
        register_event("Health", "Event_Health", "be", "1>0" );
        register_event("StatusValue", "Event_StatusValueShow", "be", "1=2", "2!0");
        register_event("StatusValue", "Event_StatusValueHide", "be", "1=1", "2=0");
        register_event("TeamInfo", "eTeamInfo", "a");
        register_logevent("Event_RoundStart", 2, "1=Round_Start");
        register_logevent("Event_RoundEnd", 2, "1=Round_End");
        //register_logevent("Event_RoundEnd", 2, "1=Game_Commencing", "1&Restart_Round_");
 
        register_message( g_iMsgStatus, "MsgStatusIcon" );
        register_message( g_iMsgShowMenu, "MsgShowMenu" );
        register_message( g_iMsgVguiMenu, "MsgVGUIMenu" );
        register_message( g_iMoney, "MsgMoney");
        register_message( g_iStatusText, "MsgStatusText");
 
        g_bCanBuy        = true;
 
        RegisterHam(Ham_Spawn, "armoury_entity", "Fwd_ArmouryEntitySpawn", true );
        RegisterHam(Ham_Spawn, "player", "Fwd_PlayerSpawn_Post", 1);
        RegisterHam(Ham_Killed, "player", "Fwd_PlayerKilled_Pre", 0);
        RegisterHam(Ham_TraceAttack, "func_door", "Fwd_DoorAttack");
 
        register_forward(FM_PlayerPreThink, "Fwd_PlayerPreThink_Sprint");
        register_forward(FM_Voice_SetClientListening, "Fwd_SetVoice");
 
        register_touch(g_szClassNameCrowbar, "worldspawn", "CrowbarTouch");
        register_touch(g_szClassNameCrowbar, "player", "Fwd_PlayerCrowbarTouch");
 
        register_clcmd( "jointeam", "ClCmd_ChooseTeam" );
        register_clcmd( "chooseteam", "ClCmd_ChooseTeam" );
        register_clcmd("drop", "ClCmd_Drop", _, "Weapons Drop");
 
        register_clcmd( "pass", "ClCmd_Password" );
        register_clcmd( "email", "ClCmd_Email" );
        register_clcmd( "login", "ClCmd_Login" );
        register_clcmd( "changepass", "ClCmd_ChangePass" );
        register_clcmd( "changeemail", "ClCmd_ChangeEmail" );
        register_clcmd( "gang_name", "ClCmd_CreateGang" );
 
        register_concmd( "amx_banct", "cmd_banct", ADMIN_BAN, " <#nume><#motiv><#minute><#ore><#zile>- Restrictioneaza accesul unui jucator pentru echipa Gardienilor." );
        register_concmd( "amx_unbanct", "cmd_unbanct", ADMIN_RCON, " <#nume> - Inlatura restrictia unui jucator pentru echipa Gardienilor." );
        register_concmd( "amx_mute", "cmd_mute", ADMIN_BAN, " <#nume><#motiv><#minute><#ore><#zile>- Restrictioneaza accesul unui jucator pentru chat." );
        register_concmd( "amx_unmute", "cmd_unmute", ADMIN_RCON, " <#nume> - Inlatura restrictia unui jucator pentru chat." );
        register_concmd( "amx_give_time", "cmd_give_time", ADMIN_GIVE, " <#nume><#minute><#ore><#zile>- - Adauga un numar de minute unui jucator." );
        register_concmd( "amx_take_time", "cmd_take_time", ADMIN_TAKE, " <#nume><#minute><#ore><#zile> - Scoate un numar de minute unui jucator." );
        register_concmd( "amx_give_points", "cmd_give_points", ADMIN_GIVE, " <#nume> <#puncte> - Adauga un numar de puncte unui jucator." );
        register_concmd( "amx_take_points", "cmd_take_points", ADMIN_TAKE, " <#nume> <#puncte> - Scoate un numar de puncte unui jucator." );
        register_concmd( "amx_give_drugs", "cmd_give_drugs", ADMIN_GIVE, " <#nume> <#droguri> - Adauga un numar de droguri unui jucator." );
        register_concmd( "amx_take_drugs", "cmd_take_drugs", ADMIN_TAKE, " <#nume> <#droguri> - Scoate un numar de droguri unui jucator." );
        register_concmd( "amx_give_money", "cmd_give_moneys", ADMIN_GIVE, " <#nume> <#euro> - Adauga un numar de bani unui jucator." );
        register_concmd( "amx_take_money", "cmd_take_moneys", ADMIN_TAKE, " <#nume> <#euro> - Scoate un numar de bani unui jucator." );
        register_concmd( "amx_give_level", "cmd_give_level", ADMIN_GIVE, " <#nume> <#level[0-3]> - Adauga un numar de levele unui jucator." );
        register_concmd( "amx_take_level", "cmd_take_level", ADMIN_TAKE, " <#nume> <#level[0-3]> - Scoate un numar de levele unui jucator." );
 
        g_iTimerEntity = create_entity("info_target");
        entity_set_string(g_iTimerEntity, EV_SZ_classname, "check_entity");
 
        register_think("check_entity", "Fwd_Check");
        entity_set_float(g_iTimerEntity, EV_FL_nextthink, get_gametime() + 1.0);
       
        g_HudHP = CreateHudSyncObj();
        g_HudSyncStatusText = CreateHudSyncObj();
        set_msg_block( g_iHudText, BLOCK_SET );
 
        set_task(1.0, "MySql_Init");
        LoadGangs();
}
public plugin_cfg()
{
        for(new i = 0; i < sizeof(SayClientCmds); i = i+2)
                rd_register_saycmd(SayClientCmds[i], SayClientCmds[i+1], 0);
 
        for(new i = 0; i < Cvars; i++)
                cvar_pointer[i] = register_cvar(cvar_names[i] , cvar_defaults[i]);
 
        for( new i = 0; i < sizeof g_szGangValues; i++ )
                TrieSetCell( g_tGangValues, g_szGangValues[ i ], i );
 
        register_clcmd("say", "ClCmd_Say");
        register_clcmd("say_team", "ClCmd_Say");
}
public plugin_precache()
{
        new szCfgDir[64], szCfgFile[128];
        get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
        static i;
 
        for(i = 0; i < sizeof(CrowbarModels); i++)
                precache_model(CrowbarModels[i]);      
 
        for(i = 0; i < sizeof(ExhaustedSound); i++)
                precache_sound(ExhaustedSound[i]);
 
        formatex(szCfgFile, charsmax(szCfgFile), "%s/xjailbreak/round_sound.ini", szCfgDir);
        switch(file_exists(szCfgFile))
        {
                case 0: log_to_file("%s/xjailbreak/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
                case 1: round_sound_read_file(szCfgFile);
        }
 
        formatex(szCfgFile, charsmax(szCfgFile), "%s/xjailbreak/costume_models.ini", szCfgDir);
        switch(file_exists(szCfgFile))
        {
                case 0: log_to_file("%s/jb_engine/log_error.log", "File ^"%s^" not found!", szCfgDir, szCfgFile);
                case 1: jb_costume_models_read_file(szCfgFile);
        }
 
        g_iRingSprite = precache_model("sprites/shockwave.spr");
}
 
jb_costume_models_read_file(szCfgFile[])
{
        new szBuffer[64], iLine, iLen;
        g_aCostumesList = ArrayCreate(64);
        while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
                {
                if(!iLen || iLen > 32 || szBuffer[0] == ';') continue;
                format(szBuffer, charsmax(szBuffer), "models/xjailbreak/costumes/%s.mdl", szBuffer);
                ArrayPushString(g_aCostumesList, szBuffer);
                engfunc(EngFunc_PrecacheModel, szBuffer);
        }
        g_iCostumesListSize = ArraySize(g_aCostumesList);
}
 
round_sound_read_file(szCfgFile[])
{
        new aDataRoundSound[DATA_ROUND_SOUND], szBuffer[128], iLine, iLen;
        g_aDataRoundSound = ArrayCreate(DATA_ROUND_SOUND);
        while(read_file(szCfgFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
                {
                if(!iLen || szBuffer[0] == ';') continue;
                parse(szBuffer, aDataRoundSound[FILE_NAME], charsmax(aDataRoundSound[FILE_NAME]), aDataRoundSound[TRACK_NAME], charsmax(aDataRoundSound[TRACK_NAME]));
                formatex(szBuffer, charsmax(szBuffer), "sound/xjailbreak/round_sound/%s.mp3", aDataRoundSound[FILE_NAME]);
                engfunc(EngFunc_PrecacheGeneric, szBuffer);
                ArrayPushArray(g_aDataRoundSound, aDataRoundSound);
        }
        g_iRoundSoundSize = ArraySize(g_aDataRoundSound);
}
/////////////////////////////////////////////////
public MySql_Init()
{
        g_SqlTuple = SQL_MakeDbTuple(Host,User,Pass,Db);
 
        new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,charsmax(g_Error));
        if(SqlConnection == Empty_Handle)
                set_fail_state(g_Error);
       
        new Handle:Queries;
        Queries = SQL_PrepareQuery(SqlConnection,"CREATE TABLE IF NOT EXISTS xjailbreak_time (name varchar(64) NOT NULL, time INT(11) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_shop ( name varchar(64) NOT NULL, moneys INT(11) NOT NULL, points INT(11) NOT NULL,drugs INT(11) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_register ( name varchar(64) NOT NULL, register INT(11) NOT NULL, password varchar(64) NOT NULL, email varchar(64) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_ban ( name varchar(64) NOT NULL, ban INT(11) NOT NULL, bantime INT(11) NOT NULL, banreason varchar(64) NOT NULL, banname varchar(64) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_mute ( name varchar(64) NOT NULL, mute INT(11) NOT NULL, mutetime INT(11) NOT NULL, mutereason varchar(64) NOT NULL, mutename varchar(64) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_nova ( name varchar(64) NOT NULL, nova INT(11) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_gold ( name varchar(64) NOT NULL, gold INT(11) NOT NULL, goldtime INT(11) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_level ( name varchar(64) NOT NULL, level INT(11) NOT NULL, exp INT(11) NOT NULL ) ; CREATE TABLE IF NOT EXISTS xjailbreak_gang ( name varchar(64) NOT NULL, gang varchar(64) NOT NULL, rank varchar(64) NOT NULL )");
 
        if(!SQL_Execute(Queries))
        {
                SQL_QueryError(Queries,g_Error,charsmax(g_Error));
                set_fail_state(g_Error);
        }
   
        SQL_FreeHandle(Queries);
   
        g_iSqlReady = true;
        for(new i=1; i<=g_iMaxPlayers; i++)
                if(g_iAuth[i])
                        Load_MySql(i);
}
public Load_MySql(iPlayer)
{  
        if(g_iSqlReady)
        {
                if(g_SqlTuple == Empty_Handle)
                        set_fail_state(g_Error);
               
                new szTemp[512];
                new Data[1];
                Data[0] = iPlayer;
   
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_time` WHERE (`xjailbreak_time`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_time",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_shop` WHERE (`xjailbreak_shop`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_shop",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_register` WHERE (`xjailbreak_register`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_login",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_ban` WHERE (`xjailbreak_ban`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_ban",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_mute` WHERE (`xjailbreak_mute`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_mute",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_nova` WHERE (`xjailbreak_nova`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_nova",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_gold` WHERE (`xjailbreak_gold`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_gold",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_level` WHERE (`xjailbreak_level`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_level",szTemp,Data,1);
 
                format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_gang` WHERE (`xjailbreak_gang`.`name` = '%s')", szName(iPlayer));
                SQL_ThreadQuery(g_SqlTuple,"register_gang",szTemp,Data,1);
 
                //format(szTemp,charsmax(szTemp),"SELECT * FROM `xjailbreak_time` WHERE (`xjailbreak_time`.`name` = '%s') ; SELECT * FROM `xjailbreak_shop` WHERE (`xjailbreak_shop`.`name` = '%s') ; SELECT * FROM `xjailbreak_register` WHERE (`xjailbreak_register`.`name` = '%s') ; SELECT * FROM `xjailbreak_ban` WHERE (`xjailbreak_ban`.`name` = '%s') ; SELECT * FROM `xjailbreak_mute` WHERE (`xjailbreak_mute`.`name` = '%s') ; SELECT * FROM `xjailbreak_gold` WHERE (`xjailbreak_nova`.`name` = '%s') ; SELECT * FROM `xjailbreak_nova` WHERE (`xjailbreak_gold`.`name` = '%s')", szName(iPlayer), szName(iPlayer), szName(iPlayer), szName(iPlayer), szName(iPlayer), szName(iPlayer), szName(iPlayer));
                //SQL_ThreadQuery(g_SqlTuple,"register_client",szTemp,Data,1);
        }
}
 
public register_time(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_time` ( `name` , `time`)VALUES ('%s','0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                g_iPlayerTime[iPlayer]  = SQL_ReadResult(Query, 1);
 
        }
        g_bLoaded[iPlayer][0] = true;
        return PLUGIN_HANDLED;
}
public register_level(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_level` ( `name` , `level`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_level` ( `name` , `exp`)VALUES ('%s','0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
 
                g_iLevel[iPlayer]  = SQL_ReadResult(Query, 1);
                g_iExp[iPlayer] = SQL_ReadResult(Query, 2);
 
        }
        g_bLoaded[iPlayer][1] = true;
        return PLUGIN_HANDLED;
}
public register_nova(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
               
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_nova` ( `name` , `nova`)VALUES ('%s','0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
 
        }
        else
        {
               g_iNova[iPlayer]  = SQL_ReadResult(Query, 1);
 
        }
        g_bLoaded[iPlayer][2] = true;
        return PLUGIN_HANDLED;
}
public register_gold(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_gold` ( `name` , `gold`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_gold` ( `name` , `goldtime`)VALUES ('%s','0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
 
                g_iGold[iPlayer]  = SQL_ReadResult(Query, 1);
                g_iGoldTime[iPlayer] = SQL_ReadResult(Query, 2);
 
        }
        g_bLoaded[iPlayer][3] = true;
        return PLUGIN_HANDLED;
}
public register_shop(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_shop` ( `name` , `moneys`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_shop` ( `name` , `points`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_shop` ( `name` , `drugs`)VALUES ('%s','0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                g_iMoneys[iPlayer]  = SQL_ReadResult(Query, 1);
                g_iPoints[iPlayer]  = SQL_ReadResult(Query, 2);
                g_iDrugs[iPlayer]  = SQL_ReadResult(Query, 3);
 
        }
        g_bLoaded[iPlayer][4] = true;
        return PLUGIN_HANDLED;
}
public register_login(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_register` ( `name` , `register`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_register` ( `name` , `password`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_register` ( `name` , `email`)VALUES ('%s','\0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                g_iRegister[iPlayer]  = SQL_ReadResult(Query, 1);
                SQL_ReadResult(Query, 2, g_iPassword[iPlayer], charsmax(g_iPassword));
                SQL_ReadResult(Query, 3, g_iEmail[iPlayer], charsmax(g_iEmail));
 
        }
        g_bLoaded[iPlayer][5] = true;
        return PLUGIN_HANDLED;
}
public register_mute(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mute`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mutetime`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mutereason`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mutename`)VALUES ('%s','\0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                g_iMute[iPlayer]  = SQL_ReadResult(Query, 1);
                g_iMuteTime[iPlayer]  = SQL_ReadResult(Query, 2);
                SQL_ReadResult(Query, 3, g_iMuteReason[iPlayer], charsmax(g_iMuteReason));
                SQL_ReadResult(Query, 4, g_iMuteName[iPlayer], charsmax(g_iMuteName));
 
 
        }
        g_bLoaded[iPlayer][6] = true;
        return PLUGIN_HANDLED;
}
public register_ban(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `ban`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `bantime`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `banreason`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `banname`)VALUES ('%s','\0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                g_iBan[iPlayer]  = SQL_ReadResult(Query, 1);
                g_iBanTime[iPlayer]  = SQL_ReadResult(Query, 2);
                SQL_ReadResult(Query, 3, g_iBanReason[iPlayer], charsmax(g_iBanReason));
                SQL_ReadResult(Query, 4, g_iBanName[iPlayer], charsmax(g_iBanName));
 
        }
        g_bLoaded[iPlayer][7] = true;
        return PLUGIN_HANDLED;
}
 
public register_gang(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_gang` ( `name` , `gang`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_gang` ( `name` , `rank`)VALUES ('%s','\0');", szQuotedName);
 
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                SQL_ReadResult(Query, 1, g_iGang[iPlayer], charsmax(g_iGang));
                SQL_ReadResult(Query, 2, g_iRank[iPlayer], charsmax(g_iRank));
 
        }
        g_bLoaded[iPlayer][8] = true;
        return PLUGIN_HANDLED;
}
 
public Save_MySql(iPlayer)
{
        if(g_bLoaded[iPlayer][0] && g_bLoaded[iPlayer][1] && g_bLoaded[iPlayer][2] && g_bLoaded[iPlayer][3]
        && g_bLoaded[iPlayer][4] && g_bLoaded[iPlayer][5] && g_bLoaded[iPlayer][6] && g_bLoaded[iPlayer][7]
        && g_bLoaded[iPlayer][8])
        {
                new szTemp[512][9], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
 
                if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
                        return PLUGIN_HANDLED;
 
                if(g_iNova[iPlayer])
                {
                        format(szTemp[0], charsmax(szTemp),"UPDATE `xjailbreak_nova` SET `nova` = '%d' WHERE `xjailbreak_nova`.`name` = '%s';", g_iNova[iPlayer], szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[0]);
                }
                if(g_iGold[iPlayer])
                {
                        format(szTemp[1], charsmax(szTemp),"UPDATE `xjailbreak_gold` SET `gold` = '%d', `goldtime` = '%d' WHERE `xjailbreak_gold`.`name` = '%s';", g_iGold[iPlayer], g_iGoldTime[iPlayer], szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[1]);
                }
                if(!g_iGold[iPlayer])
                {
                        format(szTemp[1], charsmax(szTemp),"UPDATE `xjailbreak_gold` SET `gold` = '0', `goldtime` = '0' WHERE `xjailbreak_gold`.`name` = '%s';", szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[1]);
                }
                if(g_iBan[iPlayer])
                {
                        format(szTemp[2], charsmax(szTemp),"UPDATE `xjailbreak_ban` SET `ban` = '%d', `bantime` = '%d', `banreason` = '%s', `banname` = '%s' WHERE `xjailbreak_ban`.`name` = '%s';", g_iBan[iPlayer], g_iBanTime[iPlayer], g_iBanReason[iPlayer], g_iBanName[iPlayer], szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[2]);
                }
                if(!g_iBan[iPlayer])
                {
                        format(szTemp[2], charsmax(szTemp),"UPDATE `xjailbreak_ban` SET `ban` = '0', `bantime` = '0', `banreason` = '\0', `banname` = '\0' WHERE `xjailbreak_ban`.`name` = '%s';", szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[2]);
                }
                if(g_iMute[iPlayer])
                {
                        format(szTemp[3], charsmax(szTemp),"UPDATE `xjailbreak_mute` SET `mute` = '%d', `mutetime` = '%d', `mutereason` = '%s', `mutename` = '%s' WHERE `xjailbreak_mute`.`name` = '%s';", g_iMute[iPlayer], g_iMuteTime[iPlayer], g_iMuteReason[iPlayer], g_iMuteName[iPlayer], szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[3]);
                }
                if(!g_iMute[iPlayer])
                {
                        format(szTemp[3], charsmax(szTemp),"UPDATE `xjailbreak_mute` SET `mute` = '0', `mutetime` = '0', `mutereason` = '\0', `mutename` = '\0' WHERE `xjailbreak_mute`.`name` = '%s';", szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[3]);          
                }
                if(g_iRegister[iPlayer])
                {
                        format(szTemp[4], charsmax(szTemp),"UPDATE `xjailbreak_register` SET `register` = '%d', `password` = '%s', `email` = '%s' WHERE `xjailbreak_register`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], szQuotedName );
                        SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[4]);
                }
                format(szTemp[5], charsmax(szTemp),"UPDATE `xjailbreak_shop` SET `moneys` = '%d', `points` = '%d', `drugs` = '%d' WHERE `xjailbreak_shop`.`name` = '%s';", g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer], szQuotedName );
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[5]);
                format(szTemp[6], charsmax(szTemp),"UPDATE `xjailbreak_time` SET `time` = '%d' WHERE `xjailbreak_time`.`name` = '%s';", g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), szQuotedName );
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[6]);
                format(szTemp[7], charsmax(szTemp),"UPDATE `xjailbreak_level` SET `level` = '%d', `exp` = '%d' WHERE `xjailbreak_level`.`name` = '%s';", g_iLevel[iPlayer], g_iExp[iPlayer], szQuotedName );
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[7]);
                format(szTemp[8], charsmax(szTemp),"UPDATE `xjailbreak_gang` SET `gang` = '%s', `rank` = '%s' WHERE `xjailbreak_gang`.`name` = '%s';", g_iGang[iPlayer], g_iRank[iPlayer], szQuotedName );
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp[8]);          
        }
        return PLUGIN_CONTINUE;
}
/*
public register_client(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
   
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
   
        new iPlayer;
        iPlayer = Data[0];
 
        if(SQL_NumResults(Query) < 1)
        {
                if (equal(szName(iPlayer),"ID_PENDING"))
                        return PLUGIN_HANDLED;
       
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
       
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_register` ( `name` , `register`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_register` ( `name` , `password`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_register` ( `name` , `email`)VALUES ('%s','\0');", szQuotedName);
 
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_time` ( `name` , `time`)VALUES ('%s','0');", szQuotedName);
 
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_shop` ( `name` , `moneys`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_shop` ( `name` , `points`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_shop` ( `name` , `drugs`)VALUES ('%s','0');", szQuotedName);
 
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `ban`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `bantime`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `banreason`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_ban` ( `name` , `banname`)VALUES ('%s','\0');", szQuotedName);
 
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mute`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mutetime`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mutereason`)VALUES ('%s','\0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_mute` ( `name` , `mutename`)VALUES ('%s','\0');", szQuotedName);
 
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_nova` ( `name` , `nova`)VALUES ('%s','0');", szQuotedName);
 
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_gold` ( `name` , `gold`)VALUES ('%s','0');", szQuotedName);
                format(szTemp,charsmax(szTemp),"INSERT INTO `xjailbreak_gold` ( `name` , `goldtime`)VALUES ('%s','0');", szQuotedName);
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
        else
        {
                g_iRegister[iPlayer]  = SQL_ReadResult(Query, 1);
                SQL_ReadResult(Query, 2, g_iPassword[iPlayer], charsmax(g_iPassword));
                SQL_ReadResult(Query, 3, g_iEmail[iPlayer], charsmax(g_iEmail));
 
                g_iPlayerTime[iPlayer]  = SQL_ReadResult(Query, 4);
 
                g_iMoneys[iPlayer]  = SQL_ReadResult(Query, 5);
                g_iPoints[iPlayer]  = SQL_ReadResult(Query, 6);
                g_iDrugs[iPlayer]  = SQL_ReadResult(Query, 7);
 
                g_iBan[iPlayer]  = SQL_ReadResult(Query, 8);
                g_iBanTime[iPlayer]  = SQL_ReadResult(Query, 9);
                SQL_ReadResult(Query, 10, g_iBanReason[iPlayer], charsmax(g_iBanReason));
                SQL_ReadResult(Query, 11, g_iBanName[iPlayer], charsmax(g_iBanName));
 
                g_iMute[iPlayer]  = SQL_ReadResult(Query, 12);
                g_iMuteTime[iPlayer]  = SQL_ReadResult(Query, 13);
                SQL_ReadResult(Query, 14, g_iMuteReason[iPlayer], charsmax(g_iMuteReason));
                SQL_ReadResult(Query, 15, g_iMuteName[iPlayer], charsmax(g_iMuteName));
 
                g_iNova[iPlayer]  = SQL_ReadResult(Query, 16);
 
                g_iGold[iPlayer]  = SQL_ReadResult(Query, 17);
                g_iGoldTime[iPlayer] = SQL_ReadResult(Query, 18);
        }
        g_bLoaded[iPlayer] = true;
        return PLUGIN_HANDLED;
}
 
public Save_MySql(iPlayer)
{
        if(g_bLoaded[iPlayer])
        {
                new szTemp[512], szQuotedName[64];
                SQL_QuoteString(g_SqlConnection, szQuotedName, 63, szName(iPlayer));
 
 
                if(g_iGold[iPlayer] && g_iBan[iPlayer] && g_iMute[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '%d', `bantime` = '%d', `banreason` = '%s', `banname` = '%s', `mute` = '%d', `mutetime` = '%d', `mutereason` = '%s', `mutename` = '%s', `nova` = '%d', `gold` = '%d', `goldtime` = '%d' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iBan[iPlayer], g_iBanTime[iPlayer], g_iBanReason[iPlayer], g_iBanName[iPlayer],
                        g_iMute[iPlayer], g_iMuteTime[iPlayer], g_iMuteReason[iPlayer], g_iMuteName[iPlayer],
                        g_iNova[iPlayer], g_iGold[iPlayer], g_iGoldTime[iPlayer], szQuotedName );
 
                else
                if(g_iGold[iPlayer] && g_iBan[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '%d', `bantime` = '%d', `banreason` = '%s', `banname` = '%s', `mute` = '0', `mutetime` = '0', `mutereason` = '\0', `mutename` = '\0', `nova` = '%d', `gold` = '%d', `goldtime` = '%d' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iBan[iPlayer], g_iBanTime[iPlayer], g_iBanReason[iPlayer], g_iBanName[iPlayer],
                        g_iNova[iPlayer], g_iGold[iPlayer], g_iGoldTime[iPlayer], szQuotedName );
 
                else
                if(g_iGold[iPlayer] && g_iMute[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '0', `bantime` = '0', `banreason` = '\0', `banname` = '\0', `mute` = '%d', `mutetime` = '%d', `mutereason` = '%s', `mutename` = '%s', `nova` = '%d', `gold` = '%d', `goldtime` = '%d' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iMute[iPlayer], g_iMuteTime[iPlayer], g_iMuteReason[iPlayer], g_iMuteName[iPlayer],
                        g_iNova[iPlayer], g_iGold[iPlayer], g_iGoldTime[iPlayer], szQuotedName );
 
                else
                if(g_iGold[iPlayer] && !g_iBan[iPlayer] && !g_iMute[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '0', `bantime` = '0', `banreason` = '\0', `banname` = '\0', `mute` = '0', `mutetime` = '0', `mutereason` = '\0', `mutename` = '\0', `nova` = '%d', `gold` = '%d', `goldtime` = '%d' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iNova[iPlayer], g_iGold[iPlayer], g_iGoldTime[iPlayer], szQuotedName );
 
                else
                if(!g_iGold[iPlayer] && g_iBan[iPlayer] && g_iMute[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '%d', `bantime` = '%d', `banreason` = '%s', `banname` = '%s', `mute` = '%d', `mutetime` = '%d', `mutereason` = '%s', `mutename` = '%s', `nova` = '%d', `gold` = '0', `goldtime` = '0' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iBan[iPlayer], g_iBanTime[iPlayer], g_iBanReason[iPlayer], g_iBanName[iPlayer],
                        g_iMute[iPlayer], g_iMuteTime[iPlayer], g_iMuteReason[iPlayer], g_iMuteName[iPlayer],
                        g_iNova[iPlayer], szQuotedName );
 
                else
                if(!g_iGold[iPlayer] && g_iBan[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '%d', `bantime` = '%d', `banreason` = '%s', `banname` = '%s', `mute` = '0', `mutetime` = '0', `mutereason` = '\0', `mutename` = '\0', `nova` = '%d', `gold` = '0', `goldtime` = '0' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iBan[iPlayer], g_iBanTime[iPlayer], g_iBanReason[iPlayer], g_iBanName[iPlayer],
                        g_iNova[iPlayer], szQuotedName );
 
                else
                if(!g_iGold[iPlayer] && g_iMute[iPlayer])
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '0', `bantime` = '0', `banreason` = '\0', `banname` = '\0', `mute` = '%d', `mutetime` = '%d', `mutereason` = '%s', `mutename` = '%s', `nova` = '%d', `gold` = '0', `goldtime` = '0' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iMute[iPlayer], g_iMuteTime[iPlayer], g_iMuteReason[iPlayer], g_iMuteName[iPlayer],
                        g_iNova[iPlayer], szQuotedName );
 
 
                else
                        format(szTemp, charsmax(szTemp),"UPDATE `xjailbreak` SET `register` = '%d', `password` = '%s', `email` = '%s', `time` = '%d', `moneys` = '%d', `points` = '%d', `drugs` = '%d', `ban` = '0', `bantime` = '0', `banreason` = '\0', `banname` = '\0', `mute` = '0', `mutetime` = '0', `mutereason` = '\0', `mutename` = '\0', `nova` = '%d', `gold` = '0', `goldtime` = '0' WHERE `xjailbreak`.`name` = '%s';", g_iRegister[iPlayer], g_iPassword[iPlayer], g_iEmail[iPlayer], g_iPlayerTime[ iPlayer ] + ( get_user_time( iPlayer ) / 60 ), g_iMoneys[iPlayer], g_iPoints[iPlayer], g_iDrugs[iPlayer],
                        g_iNova[iPlayer], szQuotedName );
 
                SQL_ThreadQuery(g_SqlTuple,"IgnoreHandle",szTemp);
        }
}
*/
public IgnoreHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        SQL_FreeHandle(Query);
        return PLUGIN_HANDLED;
}
public plugin_end()
{
        if(g_SqlConnection != Empty_Handle)
                SQL_FreeHandle(g_SqlConnection);
   
        SaveGangs();
        return;
}
/////////////////////////////////////////////////
public Fwd_PlayerSpawn_Post(const iPlayer)
{
        if (!is_user_alive(iPlayer))
                return HAM_HANDLED;
       
        StripPlayerWeapons(iPlayer);
        displayInfo(iPlayer);
        g_fSprintTime[iPlayer] = 0.0;
        new team = get_user_team(iPlayer);
 
        switch(team)
        {
                case 1:
                {
                        switch (g_nCvar(cvar_blockvoice))
                        {
                                case 0: fm_set_speak(iPlayer, SPEAK_ALL);
                                case 1: if(get_user_flags(iPlayer) & read_flags(g_sCvar(cvar_blockvoice_level)))
                                                fm_set_speak(iPlayer, SPEAK_ALL);
                                        else fm_set_speak(iPlayer, SPEAK_TEAM);
                                case 2: if(get_user_flags(iPlayer) & read_flags(g_sCvar(cvar_blockvoice_level)))
                                                fm_set_speak(iPlayer, SPEAK_ALL);
                                        else fm_set_speak(iPlayer, SPEAK_MUTED);
                        }
                }
                case 2:
                {
                        fm_set_speak(iPlayer, SPEAK_TEAM);
                }
        }
 
        reset_all(iPlayer);
        return HAM_HANDLED;
}
public reset_all(iPlayer)
{
        if(get_bit(g_bHasHealth, iPlayer))
                clear_bit(g_bHasHealth, iPlayer);
       
        if(get_bit(g_bHasDrugs, iPlayer))
                clear_bit(g_bHasDrugs, iPlayer);
 
        if(get_bit(g_bHasFlashBang, iPlayer))
                clear_bit(g_bHasFlashBang, iPlayer);
 
        if(get_bit(g_bHasCellKey, iPlayer))
                clear_bit(g_bHasCellKey, iPlayer);
 
        if(get_bit(g_bHasGunGamble, iPlayer))
                clear_bit(g_bHasGunGamble, iPlayer);
 
        if(get_bit(g_bHasDisguise, iPlayer))
                clear_bit(g_bHasDisguise, iPlayer);
 
        if(get_bit(g_bHasFreeday, iPlayer))
                clear_bit(g_bHasFreeday, iPlayer);
 
        if(get_bit(g_bHasCrowbar, iPlayer))
                clear_bit(g_bHasCrowbar, iPlayer);
 
        if(get_bit(g_bHasBanana, iPlayer))
                clear_bit(g_bHasBanana, iPlayer);
 
        if(get_bit(g_bHasNail, iPlayer))
                clear_bit(g_bHasNail, iPlayer);
 
        if(get_bit(g_bHasPipe, iPlayer))
                clear_bit(g_bHasPipe, iPlayer);
 
        if(get_bit(g_bHasUsp, iPlayer))
                clear_bit(g_bHasUsp, iPlayer);
 
        if(get_bit(g_bHasGlock, iPlayer))
                clear_bit(g_bHasGlock, iPlayer);
 
        if(get_bit(g_bHasInvest, iPlayer))
                clear_bit(g_bHasInvest, iPlayer);
 
}
public Fwd_PlayerKilled_Pre(iVictim, iAttacker, iShouldgib)
{
        if (!IsPlayer(iVictim) || !is_user_alive(iAttacker))
                return HAM_IGNORED;
 
        if(get_bit(g_bIsSimon, iVictim))
                ResetSimon(iVictim);
 
        if(get_user_flags(iVictim) & read_flags(g_sCvar(cvar_blockvoice_level)))
                fm_set_speak(iVictim, SPEAK_ALL);
        else
                fm_set_speak(iVictim, SPEAK_MUTED);
 
        if(g_iCheck[iAttacker] > -1 )
        {
                new aData[GangInfo];
                ArrayGetArray(g_aGangs, g_iCheck[iAttacker], aData);
                aData[GangKills]++;
                ArraySetArray(g_aGangs, g_iCheck[iAttacker], aData);
        }
 
        return HAM_IGNORED;
}
public Fwd_DoorAttack(const door, const iPlayer, Float:damage, Float:direction[3], const tracehandle, const damagebits)
{      
        if(is_valid_ent(door))
        {
                if(get_bit(g_bHasCellKey, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CELLKEY", '^3', szName(iPlayer), '^1', '^4', '^1');
                        ExecuteHamB(Ham_Use, door, iPlayer, 0, 1, 1.0);
                        entity_set_float(door, EV_FL_frame, 0.0);
                        clear_bit(g_bHasCellKey, iPlayer);
                }
        }
        return HAM_IGNORED;
}
 
public Fwd_ArmouryEntitySpawn( const iEntity )
{
        engfunc( EngFunc_DropToFloor, iEntity );
       
        set_pev( iEntity, pev_movetype, MOVETYPE_NONE );
}
public Fwd_Check(const iEntity)
{      
        if (iEntity != g_iTimerEntity)
                return;
 
        static iPlayers[32], iNum, i, iPlayer;
        get_players( iPlayers, iNum, "c");
 
        for( i=0; i<iNum; i++ )
        {
                iPlayer = iPlayers[i];
                if(is_user_connected(iPlayer))
                {
                        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
                        {
                                new iTime = 60 - get_user_time( iPlayer, 1);
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LOGIN_INFO", '^3', szName(iPlayer), '^1', '^4', iTime, '^1', iTime == 1 ? "a":"e");
                        }
 
                        if(g_bDisplayFix[iPlayer])
                        {
                                displayInfo(iPlayer);
                                g_bDisplayFix[iPlayer] = false;
                        }
 
                        if(get_systime() - g_iJoinTime[iPlayer] >= 60)
                        {
                                g_iJoinTime[iPlayer] = get_systime();
                                client_print(iPlayer, print_chat, "test");
 
                                if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
                                {
                                        client_print_color(0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_KICK_ALL_M2", '^3', szName(iPlayer), '^1', '^4', '^1');
                                        console_print(iPlayer, "%L", LANG_SERVER, "JB_KICK_INFO_M2");
                                        server_cmd("kick #%i ^"%L^"", get_user_userid(iPlayer), LANG_PLAYER, "JB_KICK_LOGIN_M2");
                                }
                                if(g_iBan[iPlayer] && g_iBanTime[iPlayer] > 0)
                                {
                                        --g_iBanTime[iPlayer];
                                        reset_ban(iPlayer);
                                }
 
                                if(g_iMute[iPlayer] && g_iMuteTime[iPlayer] > 0)
                                {
                                        --g_iMuteTime[iPlayer];
                                        reset_mute(iPlayer);
                                }
 
                                if(g_iGold[iPlayer] && g_iGoldTime[iPlayer] > 0)                               
                                {
                                        --g_iGoldTime[iPlayer];
                                        reset_gold(iPlayer);
                                }
                                if(g_iLevel[iPlayer] <= MaxLevels-1)
                                {
                                        ++g_iExp[iPlayer];
                                        while(g_iExp[iPlayer] >= Levels[g_iLevel[iPlayer]])
                                        {
                                                ++g_iLevel[iPlayer];
                                                g_iExp[iPlayer] = 0;
                                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_UP", '^3', szName(iPlayer), '^1', '^4', '^1');
                                        }
                                }
                                Save_MySql(iPlayer);
                        }
                }
        }
        entity_set_float( g_iTimerEntity, EV_FL_nextthink, get_gametime() + 1.0 );
}
 
 
 
reset_gold(iPlayer)
{
        if(g_iGold[iPlayer] && g_iGoldTime[iPlayer] <= 0)
        {
                g_iGold[iPlayer]  = 0;
                g_iGoldTime[iPlayer] = 0;
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GOLD_EXPIRED", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
 
reset_ban(iPlayer)
{
        if(g_iBan[iPlayer] && g_iBanTime[iPlayer] <= 0)
        {
                g_iBan[iPlayer]  = 0;
                g_iBanTime[iPlayer] = 0;
                formatex(g_iBanReason[iPlayer], charsmax(g_iBanReason[]), "'\0'");
                formatex(g_iBanName[iPlayer], charsmax(g_iBanName[]), "'\0'");
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_EXPIRED", '^3', szName(iPlayer), '^1', '^4', '^1');
 
        }
 
}
 
reset_mute(iPlayer)
{
        if(g_iMute[iPlayer] && g_iMuteTime[iPlayer]  <= 0)
        {
 
                g_iMute[iPlayer]  = 0;
                g_iMuteTime[iPlayer] = 0;
                formatex(g_iMuteReason[iPlayer], charsmax(g_iMuteReason[]), "'\0'");
                formatex(g_iMuteName[iPlayer], charsmax(g_iMuteName[]), "'\0'");
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_EXPIRED", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
 
}
 
public eTeamInfo() {
        new id = read_data(1);
       
        new szTeam[12];
        read_data(2, szTeam, charsmax(szTeam));
       
        g_bUserCanSprint[id] = (szTeam[0] == 'S' || szTeam[0] == 'U') ? false : true;
}
public Fwd_PlayerPreThink_Sprint(iPlayer)
{
        if(!g_bUserCanSprint[iPlayer]) return;
 
        static button,oldbuttons,flags, Float:speed;
       
        button = pev(iPlayer, pev_button);
        oldbuttons = pev(iPlayer, pev_oldbuttons);
        pev(iPlayer, pev_maxspeed, speed);
        flags = pev(iPlayer, pev_flags);
       
       
        if(!(flags & FL_DUCKING) && speed != 1.0)
        {
               
                // Pressed
                if(button & IN_FORWARD && !(oldbuttons & IN_FORWARD))
                {
                        if( (get_gametime() - g_fLastKeyPressed[iPlayer]) < g_fCvar(cvar_sprint_key) )
                        {
                                if( (get_gametime() - g_fLastSprintReleased[iPlayer]) >= g_fCvar(cvar_sprint_cooldown))  
                                {
                                        g_fLastSprintUsed[iPlayer] = get_gametime();
                                        g_bIsUserSprinting[iPlayer] = true;
                                        g_fSprintTime[iPlayer] = 0.0;
                                        SetScreenFadeEffect(iPlayer, 1);
                                }
                                else if( g_fSprintTime[iPlayer] > 0.0 && g_fSprintTime[iPlayer] < g_fCvar(cvar_sprint_time) )
                                {
                                        g_fLastSprintUsed[iPlayer] = get_gametime();
                                        g_bIsUserSprinting[iPlayer] = true;
                                        SetScreenFadeEffect(iPlayer, 1);
                                }
                               
                        }
                        g_fLastKeyPressed[iPlayer] = get_gametime();
                }
                // Holding
                else if( oldbuttons & IN_FORWARD && button & IN_FORWARD )
                {
                        if(g_bIsUserSprinting[iPlayer])
                        {
                                if(speed != g_fCvar(cvar_sprint_speed))
                                {
                                        engfunc(EngFunc_SetClientMaxspeed, iPlayer, get_user_maxspeed(iPlayer) + get_user_maxspeed(iPlayer) * g_fCvar(cvar_sprint_speed));
                                        set_pev(iPlayer, pev_maxspeed, get_user_maxspeed(iPlayer) + get_user_maxspeed(iPlayer) * g_fCvar(cvar_sprint_speed));
                                }      
 
                                set_pev(iPlayer, pev_viewmodel, 0 );
                                set_pev(iPlayer, pev_weaponmodel, 0 );
                                set_pdata_int(iPlayer, m_iFOV, 95 );
                                set_pdata_float(iPlayer, m_flNextAttack, 9999.0);
                                set_pdata_float(iPlayer, m_flNextSecondaryAttack, 9999.0);
                                set_pdata_int(iPlayer, m_iClientHideHUD, 0);
                                set_pdata_int(iPlayer, m_iHideHUD, 4);
                                ///set_pdata_float(iPlayer, m_flNextPrimaryAttack, 9999.0);
                                //set_pdata_float(iPlayer, m_flNextSecondaryAttack, 9999.0);
 
                                if( ( g_fSprintTime[iPlayer] + get_gametime() - g_fLastSprintUsed[iPlayer] ) > g_fCvar(cvar_sprint_time))
                                {
                                        g_bIsUserSprinting[iPlayer] = false;
                                        ExecuteHamB(Ham_Item_PreFrame, iPlayer);
                                        g_fLastSprintReleased[iPlayer] = get_gametime();
                                        g_fSprintTime[iPlayer] = 0.0;
                                        SetScreenFadeEffect(iPlayer, 2);
                                        reset_sprint(iPlayer);
                                        emit_sound(iPlayer, CHAN_AUTO, ExhaustedSound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                                        set_hudmessage (221, 105, 0, 0.81, 0.90, 0, 2.0, 4.0, 0.1, 0.2, 4);
                                        show_hudmessage(iPlayer, "%L", LANG_SERVER, "JB_SPRINT", g_fCvar(cvar_sprint_cooldown));
               
                                }
                        }
                }
                // Released
                else if( oldbuttons & IN_FORWARD && !(button & IN_FORWARD))
                {
                        if(g_bIsUserSprinting[iPlayer])        
                        {
                                g_fLastSprintReleased[iPlayer] = get_gametime();
                                g_bIsUserSprinting[iPlayer] = false;
                                g_fSprintTime[iPlayer] += ( get_gametime() - g_fLastSprintUsed[iPlayer]);
                                ExecuteHamB(Ham_Item_PreFrame, iPlayer);
                                SetScreenFadeEffect(iPlayer, 0);
                                reset_sprint(iPlayer);
                        }
                }
                // Ducking
                if(g_bIsUserSprinting[iPlayer] && button & IN_DUCK)
                {
                        g_fLastSprintReleased[iPlayer] = get_gametime();
                        g_bIsUserSprinting[iPlayer] = false;
                        g_fSprintTime[iPlayer] += ( get_gametime() - g_fLastSprintUsed[iPlayer]);
                        ExecuteHamB(Ham_Item_PreFrame, iPlayer);
                        SetScreenFadeEffect(iPlayer, 0);
                        reset_sprint(iPlayer);
                }
                // Jumping
                if(g_bIsUserSprinting[iPlayer] && button & IN_JUMP)
                {
                        g_fLastSprintReleased[iPlayer] = get_gametime();
                        g_bIsUserSprinting[iPlayer] = false;
                        g_fSprintTime[iPlayer] += ( get_gametime() - g_fLastSprintUsed[iPlayer]);
                        ExecuteHamB(Ham_Item_PreFrame, iPlayer);
                        SetScreenFadeEffect(iPlayer, 0);
                        reset_sprint(iPlayer);
                }
 
        }
}
reset_sprint(iPlayer)
{
        cs_reset_user_weapon(iPlayer);
        set_pdata_int(iPlayer, m_iFOV, 90 );
        //set_pdata_float(iPlayer, m_flNextPrimaryAttack, 1.0);
        //set_pdata_float(iPlayer, m_flNextSecondaryAttack, 1.0);
        set_pdata_float(iPlayer, m_flNextAttack, 1.0);
        set_pdata_int(iPlayer, m_iClientHideHUD, 1);
        set_pdata_int(iPlayer, m_iHideHUD, 0);
        set_pdata_cbase(iPlayer, m_pClientActiveItem, FM_NULLENT);
}
public SetScreenFadeEffect(iPlayer, flag) {
       
        switch(flag) {
                case 0: {
                        message_begin(MSG_ONE_UNRELIABLE, g_iScreenFade, _, iPlayer);
                        write_short(0);
                        write_short(0);
                        write_short(0);
                        write_byte(0);
                        write_byte(0);
                        write_byte(0);
                        write_byte(0);
                        message_end();
                }
                case 1: {
                        message_begin(MSG_ONE_UNRELIABLE, g_iScreenFade, _, iPlayer);
                        write_short(0); // duration (will be ignored because of the flag)
                        write_short(0); // holdtime
                        write_short(0x0004); // FFADE_STAYOUT
                        write_byte(0); // r
                        write_byte(20); // g
                        write_byte(200); // b
                        write_byte(50); // alpha
                        message_end();
                }
                case 2: {
                        message_begin(MSG_ONE_UNRELIABLE, g_iScreenFade, _, iPlayer);
                        write_short(4096); // duration
                        write_short(2048); // holdtime
                        write_short(0x0000); // FFADE_IN
                        write_byte(255); // r
                        write_byte(1); // g
                        write_byte(1); // b
                        write_byte(50); // alpha
                        message_end();
                }
        }
}
/////////////////////////////////////////////////
public Fwd_SetVoice(const iReceiver, const iSender, bool:bListen)
{
        if(!is_user_connected(iReceiver)
        || !is_user_connected(iSender)
        || g_iSpeakFlags[iSender] == SPEAK_NORMAL
        && g_iSpeakFlags[iReceiver] != SPEAK_LISTENALL)
        {
                return FMRES_IGNORED;
        }
       
        static iSpeakType;
        iSpeakType = 0;
        if(g_iSpeakFlags[iSender] == SPEAK_ALL
        || g_iSpeakFlags[iReceiver] == SPEAK_LISTENALL
        || g_iSpeakFlags[iSender] == SPEAK_TEAM && get_pdata_int(iSender, 114) == get_pdata_int(iReceiver, 114))
        {
                iSpeakType = 1;
        }
       
        engfunc(EngFunc_SetClientListening, iReceiver, iSender, iSpeakType);
        return FMRES_SUPERCEDE;
}
public fm_get_speak(iPlayer)
{
        if(!is_user_connected(iPlayer))
        {
                log_error(AMX_ERR_NATIVE, "[FmSetSpeak] Jucator Invalid %d", iPlayer);
                return 0;
        }
       
        return g_iSpeakFlags[iPlayer];
}
public fm_set_speak(iPlayer, nums)
{
        if(!is_user_connected(iPlayer))
        {
                log_error(AMX_ERR_NATIVE, "[FmSetSpeak] Jucator Invalid %d", iPlayer);
                return;
        }
        g_iSpeakFlags[iPlayer] = nums;
}
/////////////////////////////////////////////////
public cmd_give_time( iPlayer, iLevel, iCid )
{
 
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strMinutes[ 16 ];
        read_argv( 2, strMinutes, charsmax( strMinutes ) );    
        new strHours[ 16 ];
        read_argv( 3, strHours, charsmax( strHours ) );
        new strDays[ 16 ];
        read_argv( 4, strDays, charsmax( strDays ) );  
 
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iMinutes = str_to_num( strMinutes ) ;
        new iHours = str_to_num( strHours )* 60;
        new iDays = str_to_num( strDays ) * 60 * 24;
        new iTime = iMinutes + iHours + iDays;
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iMinutes > 60)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_60", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
 
        if(iHours / 60 > 24)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_24", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
        if(iTime <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
       
        g_iPlayerTime[ iTarget ] += iTime;
 
        if(iDays / 60 / 24  > 0)
        {
 
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_CONSOLE_M1", szName(iPlayer), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_LOG_M1", szName(iPlayer), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_PLAYER_M1", '^3', szName(iPlayer), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e");
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_M1", '^3', szName(iPlayer), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^3', szName(iTarget), '^1');
 
        }
        else if(iHours / 60 > 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_CONSOLE_M2", szName(iPlayer), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_LOG_M2", szName(iPlayer), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_PLAYER_M2", '^3', szName(iPlayer), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e");
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_M2", '^3', szName(iPlayer), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^3', szName(iTarget), '^1');
 
        }
        else
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_CONSOLE_M3", szName(iPlayer), iTime, iTime == 1 ? "" : "e", szName(iTarget));
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_LOG_M3", szName(iPlayer), iTime, iTime == 1 ? "" : "e", szName(iTarget));
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_PLAYER_M3", '^3', szName(iPlayer), '^1', '^4', iTime, '^1', iTime == 1 ? "" : "e");
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_GIVE_M3", '^3', szName(iPlayer), '^1', '^4', iTime, '^1', iTime == 1 ? "" : "e", '^3', szName(iTarget), '^1');
 
        }
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
 
}
 
public cmd_take_time( iPlayer, iLevel, iCid )
{
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strMinutes[ 16 ];
        read_argv( 2, strMinutes, charsmax( strMinutes ) );    
        new strHours[ 16 ];
        read_argv( 3, strHours, charsmax( strHours ) );
        new strDays[ 16 ];
        read_argv( 4, strDays, charsmax( strDays ) );  
 
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iMinutes = str_to_num( strMinutes ) ;
        new iHours = str_to_num( strHours )* 60;
        new iDays = str_to_num( strDays ) * 60 * 24;
        new iTime = iMinutes + iHours + iDays;
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iMinutes > 60)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_60", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
 
        if(iHours / 60 > 24)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_24", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
        if(iTime <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
       
        if(g_iPlayerTime[iTarget] < iTime)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_FUNDS_TIME", szName(iTarget), g_iPlayerTime[iTarget] / 60 / 24, g_iPlayerTime[iTarget] / 60, g_iPlayerTime[iTarget]);
                return PLUGIN_HANDLED;
        }
        g_iPlayerTime[ iTarget ] -= iTime;
       
        if(iDays / 60 / 24  > 0)
        {
 
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_CONSOLE_M1", szName(iPlayer), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_LOG_M1", szName(iPlayer), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_PLAYER_M1", '^3', szName(iPlayer), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e");
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_M1", '^3', szName(iPlayer), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^3', szName(iTarget), '^1');
 
        }
        else if(iHours / 60 > 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_CONSOLE_M2", szName(iPlayer), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_LOG_M2", szName(iPlayer), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", szName(iTarget));
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_PLAYER_M2", '^3', szName(iPlayer), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e");
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_M2", '^3', szName(iPlayer), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^3', szName(iTarget), '^1');
 
        }
        else
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_CONSOLE_M3", szName(iPlayer), iTime, iTime == 1 ? "" : "e", szName(iTarget));
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_LOG_M3", szName(iPlayer), iTime, iTime == 1 ? "" : "e", szName(iTarget));
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_PLAYER_M3", '^3', szName(iPlayer), '^1', '^4', iTime, '^1', iTime == 1 ? "" : "e");
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TAKE_M3", '^3', szName(iPlayer), '^1', '^4', iTime, '^1', iTime == 1 ? "" : "e", '^3', szName(iTarget), '^1');
 
        }
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
 
public cmd_give_points( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strPoints[ 16 ];
        read_argv( 2, strPoints, charsmax( strPoints ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iPoints = str_to_num( strPoints );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iPoints <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
 
        g_iPoints[ iTarget ] += iPoints;
        displayInfo(iTarget);
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iTarget, g_iPoints[iTarget], 1);
 
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_GIVE_CONSOLE", szName(iPlayer), iPoints, iPoints == 1 ? "" : "e", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_GIVE_LOG", szName(iPlayer), iPoints, iPoints == 1 ? "" : "e", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_GIVE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iPoints, '^1', iPoints == 1 ? "" : "e");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_GIVE", '^3', szName(iPlayer), '^1', '^4', iPoints, '^1', iPoints == 1 ? "" : "e", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_take_points( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strPoints[ 16 ];
        read_argv( 2, strPoints, charsmax( strPoints ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iPoints = str_to_num( strPoints );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
 
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iPoints <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
 
        if(g_iPoints[iTarget] < iPoints)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_FUNDS", szName(iTarget), g_iPoints[iTarget]);
                return PLUGIN_HANDLED;
        }
 
        g_iPoints[ iTarget ] -= iPoints;
        displayInfo(iTarget);
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iTarget, g_iPoints[iTarget], 1);
 
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_TAKE_CONSOLE", szName(iPlayer), iPoints, iPoints == 1 ? "" : "uri", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_TAKE_LOG", szName(iPlayer), iPoints, iPoints == 1 ? "" : "uri", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_TAKE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iPoints, '^1', iPoints == 1 ? "" : "uri");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_TAKE", '^3', szName(iPlayer), '^1', '^4', iPoints, '^1', iPoints == 1 ? "" : "uri", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_give_drugs( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strDrugs[ 16 ];
        read_argv( 2, strDrugs, charsmax( strDrugs ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iDrugs = str_to_num( strDrugs );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iDrugs <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }      
 
        g_iDrugs[ iTarget ] += iDrugs;
        displayInfo(iTarget);
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_GIVE_CONSOLE", szName(iPlayer), iDrugs, iDrugs == 1 ? "" : "uri", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_GIVE_LOG", szName(iPlayer), iDrugs, iDrugs == 1 ? "" : "uri", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_GIVE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iDrugs, '^1', iDrugs == 1 ? "" : "uri");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_GIVE", '^3', szName(iPlayer), '^1', '^4', iDrugs, '^1', iDrugs == 1 ? "" : "uri", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_take_drugs( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strDrugs[ 16 ];
        read_argv( 2, strDrugs, charsmax( strDrugs ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ) );
        new iDrugs = str_to_num( strDrugs );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
 
        if(!iTarget)
                return PLUGIN_HANDLED;
 
        if(iDrugs <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
 
        if(g_iDrugs[iTarget] < iDrugs)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_FUNDS", szName(iTarget), g_iDrugs[iTarget]);
                return PLUGIN_HANDLED;
        }
       
        g_iDrugs[ iTarget ] -= iDrugs;
        displayInfo(iTarget);
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_TAKE_CONSOLE", szName(iPlayer), iDrugs, iDrugs == 1 ? "" : "e", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_TAKE_LOG", szName(iPlayer), iDrugs, iDrugs == 1 ? "" : "e", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_TAKE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iDrugs, '^1', iDrugs == 1 ? "" : "uri");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_TAKE", '^3', szName(iPlayer), '^1', '^4', iDrugs, '^1', iDrugs == 1 ? "" : "uri", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
 
public cmd_give_moneys( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strMoney[ 16 ];
        read_argv( 2, strMoney, charsmax( strMoney ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ) );
        new iMoneys = str_to_num( strMoney );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iMoneys <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }      
 
        g_iMoneys[ iTarget ] += iMoneys;
        displayInfo(iTarget);
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_GIVE_CONSOLE", szName(iPlayer), iMoneys, iMoneys == 1 ? "" : "i", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_GIVE_LOG", szName(iPlayer), iMoneys, iMoneys == 1 ? "" : "i", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_GIVE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iMoneys, '^1', iMoneys == 1 ? "" : "i");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MONEYS_GIVE", '^3', szName(iPlayer), '^1', '^4', iMoneys, '^1', iMoneys == 1 ? "" : "i", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_take_moneys( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strMoney[ 16 ];
        read_argv( 2, strMoney, charsmax( strMoney ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ) );
        new iMoneys = str_to_num( strMoney );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
 
        if(!iTarget)
                return PLUGIN_HANDLED;
 
        if(iMoneys <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
 
        if(g_iMoneys[iTarget] < iMoneys)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_FUNDS", szName(iTarget), g_iDrugs[iTarget]);
                return PLUGIN_HANDLED;
        }
       
        g_iMoneys[ iTarget ] -= iMoneys;
        displayInfo(iTarget);
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_TAKE_CONSOLE", szName(iPlayer), iMoneys, iMoneys == 1 ? "" : "i", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_TAKE_LOG", szName(iPlayer), iMoneys, iMoneys == 1 ? "" : "i", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_TAKE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iMoneys, '^1', iMoneys == 1 ? "" : "i");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGS_TAKE", '^3', szName(iPlayer), '^1', '^4', iMoneys, '^1', iMoneys == 1 ? "" : "i", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_give_level( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strLevel[ 16 ];
        read_argv( 2, strLevel, charsmax( strLevel ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ) );
        new iLevelx = str_to_num( strLevel );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iLevelx <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }      
        if(iLevelx > 3)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_3", szName(iTarget));
                return PLUGIN_HANDLED;
        }
               
        if(g_iLevel[iTarget] >= 3)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_MAX", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        if(g_iLevel[ iTarget ] + iLevelx >= 3)
                g_iLevel[ iTarget ] = 3;       
        else
                g_iLevel[ iTarget ] += iLevelx;
        g_iExp[ iTarget ] = 0;
        displayInfo(iTarget);
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_GIVE_CONSOLE", szName(iPlayer), iLevelx, iLevelx == 1 ? "" : "e", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_GIVE_LOG", szName(iPlayer), iLevelx, iLevelx == 1 ? "" : "e", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_GIVE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iLevelx, '^1', iLevelx == 1 ? "" : "e");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_GIVE", '^3', szName(iPlayer), '^1', '^4', iLevelx, '^1', iLevelx == 1 ? "" : "e", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_take_level( iPlayer, iLevel, iCid ) {
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strLevel[ 16 ];
        read_argv( 2, strLevel, charsmax( strLevel ) );
        new strTarget[ 32 ];
        read_argv( 1, strTarget, charsmax( strTarget ) );
        new iLevelx = str_to_num( strLevel );
 
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
 
        if(!iTarget)
                return PLUGIN_HANDLED;
 
        if(iLevelx <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        if(iLevelx > 3)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_3", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        if(g_iLevel[iTarget] < iLevelx)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_FUNDS", szName(iTarget), g_iLevel[iTarget]);
                return PLUGIN_HANDLED;
        }
       
        g_iLevel[ iTarget ] -= iLevelx;
        g_iExp[ iTarget ] = 0;
        displayInfo(iTarget);
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_TAKE_CONSOLE", szName(iPlayer), iLevelx, iLevelx == 1 ? "" : "e", szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_TAKE_LOG", szName(iPlayer), iLevelx, iLevelx == 1 ? "" : "e", szName(iTarget));
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_TAKE_PLAYER", '^3', szName(iPlayer), '^1', '^4', iLevelx, '^1', iLevelx == 1 ? "" : "e");
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LEVEL_TAKE", '^3', szName(iPlayer), '^1', '^4', iLevelx, '^1', iLevelx == 1 ? "" : "e", '^3', szName(iTarget), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
public cmd_banct( iPlayer, iLevel, iCid ) {
 
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strReason[ 64 ];
        read_argv( 2, strReason, charsmax( strReason) );
        new strMinutes[ 16 ];
        read_argv( 3, strMinutes, charsmax( strMinutes ) );    
        new strHours[ 16 ];
        read_argv( 4, strHours, charsmax( strHours ) );
        new strDays[ 16 ];
        read_argv( 5, strDays, charsmax( strDays ) );  
        new strTarget[ 36 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iMinutes = str_to_num( strMinutes ) ;
        new iHours = str_to_num( strHours )* 60;
        new iDays = str_to_num( strDays ) * 60 * 24;
        new iBan = iMinutes + iHours + iDays;
        copy(g_iBanReason[iPlayer], charsmax(g_iBanReason), strReason[0]);
        copy(g_iBanName[iPlayer], charsmax(g_iBanName), szName(iPlayer));
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
       
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iMinutes > 60)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_60", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
 
        if(iHours / 60 > 24)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_24", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
 
        if(iBan <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        if(g_iBan[iTarget] )
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_BANNED", szName(iTarget));
                return PLUGIN_HANDLED;
        }
       
        g_iBanTime[ iTarget ] += iBan;
        g_iBan[iTarget] = 1;   
        g_iJoinTime[iPlayer] = get_systime();
 
        if( cs_get_user_team( iTarget ) == CS_TEAM_CT )
        {
                if( is_user_alive( iTarget ) )
                        user_kill( iTarget );
                       
                cs_set_user_team( iTarget, CS_TEAM_T);
       
        }
        if(iDays / 60 / 24  > 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_CONSOLE_M1", szName(iPlayer), szName(iTarget), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iBanReason[iPlayer]);
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_LOG_M1", szName(iPlayer), szName(iTarget), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iBanReason[iPlayer]);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_LENGHT_M1", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iBanReason[iPlayer], '^1');       
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_PLAYER_M1", '^3', szName(iPlayer), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iBanReason[iPlayer], '^1');
        }
        else if(iHours / 60 > 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_CONSOLE_M2", szName(iPlayer), szName(iTarget), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iBanReason[iPlayer]);
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_LOG_M2", szName(iPlayer), szName(iTarget), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iBanReason[iPlayer]);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_LENGHT_M2", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iBanReason[iPlayer], '^1');      
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_PLAYER_M2", '^3', szName(iPlayer), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iBanReason[iPlayer], '^1');
 
        }
        else
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_CONSOLE_M3", szName(iPlayer), szName(iTarget), iMinutes, iMinutes == 1 ? "" : "e", g_iBanReason[iPlayer]);
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_LOG_M3", szName(iPlayer), szName(iTarget), iMinutes, iMinutes == 1 ? "" : "e", g_iBanReason[iPlayer]);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_LENGHT_M3", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1', '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iBanReason[iPlayer], '^1');     
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_PLAYER_M3", '^3', szName(iPlayer), '^1', '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iBanReason[iPlayer], '^1');
 
        }
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_unbanct( iPlayer, iLevel, iCid ) {
 
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
       
        new strTarget[ 36 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
       
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
       
        if( !iTarget )
        {
                return PLUGIN_HANDLED;
        }
        if(!g_iBan[iTarget])
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_UNBANNED", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        g_iBanTime[iTarget] = 0;
        Save_MySql(iTarget);
        g_iBan[iTarget] = 0;
        formatex(g_iBanReason[iPlayer], charsmax(g_iBanReason[]), "'\0'");
        formatex(g_iBanName[iPlayer], charsmax(g_iBanName[]), "'\0'");
        g_iJoinTime[iPlayer] = get_systime();
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNBAN_CONSOLE", szName(iPlayer), szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNBAN_LOG", szName(iPlayer), szName(iTarget));
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNBAN", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1');
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNBAN_PLAYER", '^3', szName(iPlayer), '^1');
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_mute( iPlayer, iLevel, iCid ) {
 
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
        new strReason[ 64 ];
        read_argv( 2, strReason, charsmax( strReason) );
        new strMinutes[ 16 ];
        read_argv( 3, strMinutes, charsmax( strMinutes ) );    
        new strHours[ 16 ];
        read_argv( 4, strHours, charsmax( strHours ) );
        new strDays[ 16 ];
        read_argv( 5, strDays, charsmax( strDays ) );  
        new strTarget[ 36 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
        new iMinutes = str_to_num( strMinutes ) ;
        new iHours = str_to_num( strHours )* 60;
        new iDays = str_to_num( strDays ) * 60 * 24;
        new iMute = iMinutes + iHours + iDays;
        copy(g_iMuteReason[iPlayer], charsmax(g_iMuteReason), strReason[0]);
        copy(g_iMuteName[iPlayer], charsmax(g_iMuteName), szName(iPlayer));
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
       
        if( !iTarget )
                return PLUGIN_HANDLED;
 
        if(iMinutes > 60)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_60", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
 
        if(iHours / 60 > 24)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_24", szName(iPlayer));
                return PLUGIN_HANDLED;
        }
 
        if(iMute <= 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_ZERO", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        if(g_iMute[iTarget] )
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_MUTED", szName(iTarget));
                return PLUGIN_HANDLED;
        }
       
        g_iMuteTime[ iTarget ] += iMute;
        g_iMute[iTarget] = 1;
        g_iJoinTime[iPlayer] = get_systime();
 
        if( cs_get_user_team( iTarget ) == CS_TEAM_CT )
        {
                if( is_user_alive( iTarget ) )
                        user_kill( iTarget );
                       
                cs_set_user_team( iTarget, CS_TEAM_T);
       
        }
        if(iDays / 60 / 24  > 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_CONSOLE_M1", szName(iPlayer), szName(iTarget), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iMuteReason[iPlayer]);
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_LOG_M1", szName(iPlayer), szName(iTarget), iDays / 24 / 60, iDays / 24 / 60 == 1 ? "" : "le", iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iMuteReason[iPlayer]);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_LENGHT_M1", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iMuteReason[iPlayer], '^1');     
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_PLAYER_M1", '^3', szName(iPlayer), '^1', '^4', iDays / 24 / 60, '^1', iDays / 24 / 60 == 1 ? "" : "le", '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iMuteReason[iPlayer], '^1');
        }
        else if(iHours / 60 > 0)
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_CONSOLE_M2", szName(iPlayer), szName(iTarget), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iMuteReason[iPlayer]);
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_LOG_M2", szName(iPlayer), szName(iTarget), iHours / 60, iHours / 60 == 1 ? "a" : "e", iMinutes, iMinutes == 1 ? "" : "e", g_iMuteReason[iPlayer]);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_LENGHT_M2", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iMuteReason[iPlayer], '^1');    
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_PLAYER_M2", '^3', szName(iPlayer), '^1', '^4', iHours / 60, '^1', iHours / 60 == 1 ? "a" : "e", '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iMuteReason[iPlayer], '^1');
 
        }
        else
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_CONSOLE_M3", szName(iPlayer), szName(iTarget), iMinutes, iMinutes == 1 ? "" : "e", g_iMuteReason[iPlayer]);
                log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_LOG_M3", szName(iPlayer), szName(iTarget), iMinutes, iMinutes == 1 ? "" : "e", g_iMuteReason[iPlayer]);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_LENGHT_M3", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1', '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iMuteReason[iPlayer], '^1');   
                client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_PLAYER_M3", '^3', szName(iPlayer), '^1', '^4', iMinutes, '^1', iMinutes == 1 ? "" : "e", '^4', g_iMuteReason[iPlayer], '^1');
 
        }
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
 
public cmd_unmute( iPlayer, iLevel, iCid ) {
 
        if( !cmd_access( iPlayer, iLevel, iCid, 2 ) )
                return PLUGIN_HANDLED;
       
       
        new strTarget[ 36 ];
        read_argv( 1, strTarget, charsmax( strTarget ));
       
        new iTarget = cmd_target( iPlayer, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF);
       
        if( !iTarget )
        {
                return PLUGIN_HANDLED;
        }
        if(!g_iMute[iTarget])
        {
                console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_UNMUTED", szName(iTarget));
                return PLUGIN_HANDLED;
        }
        g_iMuteTime[iTarget] = 0;
        Save_MySql(iTarget);
        g_iMute[iTarget] = 0;
        formatex(g_iMuteReason[iPlayer], charsmax(g_iMuteReason[]), "'\0'");
        formatex(g_iMuteName[iPlayer], charsmax(g_iMuteName[]), "'\0'");
        g_iJoinTime[iPlayer] = get_systime();
        console_print( iPlayer, "%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNMUTE_CONSOLE", szName(iPlayer), szName(iTarget));
        log_amx("%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNMUTE_LOG", szName(iPlayer), szName(iTarget));
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNMUTE", '^3', szName(iPlayer), '^1', '^3', szName(iTarget), '^1');
        client_print_color( iTarget, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNMUTE_PLAYER", '^3', szName(iPlayer), '^1');
       
        Save_MySql(iTarget);
        return PLUGIN_HANDLED;
}
/////////////////////////////////////////////////
new iPage;
public ClCmd_Channel(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
       
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MIC_M1", '^3', szName(iPlayer), '^1', '^4',  g_iSpeakNames[ fm_get_speak(iPlayer) ], '^1');
        if(!(get_user_flags(iPlayer) & read_flags(g_sCvar(cvar_blockvoice_level))))
        {
                //client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOACCESS", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        Show_MicMenu(iPlayer, iPage);
        return PLUGIN_HANDLED;
}
public Show_MicMenu(iPlayer, iPage) {
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
       
        new szText[256];
        formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MIC_TITLE");
        new menu = menu_create(szText, "sub_channelmenu");
       
        new players[32], pnum, tempid;
        new szTempid[10];
        new szOption[128];
        get_players(players, pnum);
       
        for( new i; i<pnum; i++ ) {
                tempid = players[i];
                fm_get_speak(tempid);
                num_to_str(tempid, szTempid, 9);
                formatex(szOption, 127, "%L", LANG_SERVER, "JB_MIC_MENU", szName(tempid), g_iSpeakNames[ fm_get_speak(tempid) ] );
                menu_additem(menu, szOption, szTempid);
        }
       
        menu_display(iPlayer, menu, iPage);
        return PLUGIN_HANDLED;
}
public sub_channelmenu(iPlayer, menu, item) {
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if( item == MENU_EXIT ) {
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
        if(!(get_user_flags(iPlayer) & read_flags(g_sCvar(cvar_blockvoice_level))))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOACCESS", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
       
        new data[6], name[64];
        new access, callback;
        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new tempid = str_to_num(data);
       
       
        switch( fm_get_speak(tempid) )
        {
                case 1: fm_set_speak(tempid, 2);
                case 2: fm_set_speak(tempid, 3);
                case 3: fm_set_speak(tempid, 4);
                case 4: fm_set_speak(tempid, 1);
        }
        if( iPlayer != tempid )
                client_print_color( tempid, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MIC_M2", '^3', szName(iPlayer), '^1', '^4', g_iSpeakNames[ fm_get_speak(tempid) ], '^1');
        player_menu_info(iPlayer, menu, menu, iPage);
        Show_MicMenu(iPlayer, iPage);
        return PLUGIN_HANDLED;
}  
public ClCmd_Rank(id)
{
        for(new i; i < g_iMaxPlayers; i++)
                if(is_user_connected(i))
                        Save_MySql(i);
       
        new Data[1];
        Data[0] = id;
   
        new szTemp[512];
        format(szTemp,charsmax(szTemp),"SELECT COUNT(*) FROM `xjailbreak_level` WHERE `level` >= %d", g_iLevel);
        SQL_ThreadQuery(g_SqlTuple,"Sql_Rank",szTemp,Data,1);
       
        return PLUGIN_CONTINUE;
}
 
public Sql_Rank(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
        if(FailState == TQUERY_CONNECT_FAILED)
                log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error);
        else if(FailState == TQUERY_QUERY_FAILED)
                log_amx("Load Query failed. [%d] %s", Errcode, Error);
 
        new count = 0;
        count = SQL_ReadResult(Query,0);
        if(count == 0)
                count = 1;
   
        new id;
        id = Data[0];
 
        client_print(id, print_chat, "You're rank is %i with %i level", count, g_iLevel[id]);
   
        return PLUGIN_HANDLED;
}  
public ClCmd_Top15(iPlayer)
{
        client_print(iPlayer,print_chat,"level %i", g_iLevel[iPlayer]);
        client_print(iPlayer,print_chat,"Exp %i", g_iExp[iPlayer]);
}
public ClCmd_Password(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_REGISTERED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
 
        new szArgs[ 60 ];
        read_args( szArgs, charsmax( szArgs ) );
               
        remove_quotes( szArgs );
        copy(g_iTempPassword[iPlayer], charsmax(g_iTempPassword), szArgs);
        client_print(iPlayer, print_chat, "%s", g_iTempPassword[iPlayer]);
        ClCmd_RegisterSay(iPlayer);
        return PLUGIN_HANDLED;
}
public ClCmd_Email(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_REGISTERED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        new szArgs[ 60 ];
        read_args( szArgs, charsmax( szArgs ) );
               
        remove_quotes( szArgs );
        copy(g_iTempEmail[iPlayer], charsmax(g_iTempEmail), szArgs);
        if(!(containi(szArgs, "@") != -1) || !(containi(szArgs, ".") != -1) )
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_INVALID_EMAIL", '^3', szName(iPlayer), '^1', '^4', szArgs, '^1', '^4', '^1');
                formatex(g_iTempEmail[iPlayer], charsmax(g_iTempEmail[]), "'\0'");
                ClCmd_RegisterSay(iPlayer);
                return PLUGIN_HANDLED;
        }
        ClCmd_RegisterSay(iPlayer);
        return PLUGIN_HANDLED;
}
public ClCmd_RegisterSay(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(is_user_connected(iPlayer))
        {
                if(g_iRegister[iPlayer])
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_REGISTERED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                if(g_iPlayerTime[ iPlayer ] < 60 * g_nCvar(cvar_register_time) && !g_iGold[iPlayer])   
                {      
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_TIME_LOGIN", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_register_time), '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                //g_bHasMenuOpen[id] = true
                if(get_bit(g_bHasMenuOpen, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                set_bit(g_bHasMenuOpen, iPlayer);
 
                new szText[256];               
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_REGISTER_TITLE", szName(iPlayer));
                new menu = menu_create(szText, "sub_registermenu");
               
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_REGISTER_M1", g_iTempPassword[iPlayer]);
                menu_additem(menu, szText, "1", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_REGISTER_M2", g_iTempEmail[iPlayer]);
                menu_additem(menu, szText, "2", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_REGISTER_M3");
                menu_additem(menu, szText, "3", 0);
               
                menu_setprop(menu, MPROP_EXIT , MEXIT_ALL);
                menu_display(iPlayer, menu, 0);
        }
        return PLUGIN_HANDLED;
}
public sub_registermenu(iPlayer, menu, item)  
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
                       
        if (item == MENU_EXIT || g_iRegister[iPlayer])
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
 
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[7], name[64];
        new access, callback;
        //clear_bit(g_bHasMenuOpen, id);
        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new Key = str_to_num(data);
       
        switch (Key)
        {
                case 1:
                {
                        client_cmd( iPlayer, "messagemode pass" );
                }
                case 2:
                {
                        client_cmd( iPlayer, "messagemode email" );
                }
                case 3:
                {
                        if(g_iTempPassword[iPlayer][0]  == EOS && g_iTempEmail[iPlayer][0]  == EOS)
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PASSWORD", '^3', szName(iPlayer), '^1', '^4', '^1');
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_EMAIL", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //ClCmd_RegisterSay(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iTempPassword[iPlayer][0]  == EOS)
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PASSWORD", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //ClCmd_RegisterSay(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iTempEmail[iPlayer][0]  == EOS)
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_EMAIL", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //ClCmd_RegisterSay(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        g_iRegister[iPlayer] = 1;
                        g_iTempLogin[iPlayer] = 1;
                        ClCmd_Confirm(iPlayer);
                }
       
        }
        menu_destroy(menu);
        return PLUGIN_HANDLED;
}
public ClCmd_Confirm(iPlayer)
{
        copy(g_iPassword[iPlayer], charsmax(g_iPassword), g_iTempPassword[iPlayer]);
        copy(g_iEmail[iPlayer], charsmax(g_iEmail), g_iTempEmail[iPlayer]);
        formatex(g_iTempPassword[iPlayer], charsmax(g_iTempPassword[]), "'\0'");
        formatex(g_iTempEmail[iPlayer], charsmax(g_iTempEmail[]), "'\0'");
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_SAVE_M1", '^3', '^1', '^3', szName(iPlayer), '^1', '^3', g_iPassword[iPlayer], '^1', '^3', g_iEmail[iPlayer], '^1');
        Save_MySql(iPlayer);
}
public ClCmd_ChangePass(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_REGISTER", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        new szArgs[ 60 ];
        read_args( szArgs, charsmax( szArgs ) );
               
        remove_quotes( szArgs );
        copy(g_iTempPassword[iPlayer], charsmax(g_iTempPassword), szArgs);
        ClCmd_MyAccount(iPlayer);
        return PLUGIN_HANDLED;
}
public ClCmd_ChangeEmail(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_REGISTER", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
 
        new szArgs[ 60 ];
        read_args( szArgs, charsmax( szArgs ) );
               
        remove_quotes( szArgs );
 
        copy(g_iTempEmail[iPlayer], charsmax(g_iTempEmail), szArgs);
        if(!(containi(szArgs, "@") != -1) || !(containi(szArgs, ".") != -1) )
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_INVALID_EMAIL", '^3', szName(iPlayer), '^1', '^4', szArgs, '^1', '^4', '^1');
                formatex(g_iTempEmail[iPlayer], charsmax(g_iTempEmail[]), "'\0'");
                ClCmd_MyAccount(iPlayer);
                return PLUGIN_HANDLED;
        }
        ClCmd_MyAccount(iPlayer);
        return PLUGIN_HANDLED;
}
 
public ClCmd_MyAccount(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(is_user_connected(iPlayer))
        {
                if(!g_iRegister[iPlayer])
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_REGISTER", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                //g_bHasMenuOpen[id] = true
                if(get_bit(g_bHasMenuOpen, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                set_bit(g_bHasMenuOpen, iPlayer);
 
                new szText[256];               
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MYACCOUNT_TITLE", szName(iPlayer));
                new menu = menu_create(szText, "sub_myaccountmenu");
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MYACCOUNT_M1", g_iPassword[iPlayer], g_iTempPassword[iPlayer]);
                menu_additem(menu, szText, "1", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MYACCOUNT_M2", g_iEmail[iPlayer], g_iTempEmail[iPlayer]);
                menu_additem(menu, szText, "2", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MYACCOUNT_M3");
                menu_additem(menu, szText, "3", 0);
 
                menu_setprop(menu, MPROP_EXIT , MEXIT_ALL);
                menu_display(iPlayer, menu, 0);
        }
        return PLUGIN_HANDLED;
}
public sub_myaccountmenu(iPlayer, menu, item)  
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
                       
        if (item == MENU_EXIT || !g_iRegister[iPlayer] || !g_iTempLogin[iPlayer])
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
 
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[7], name[64];
        new access, callback;
        //clear_bit(g_bHasMenuOpen, id);
        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new Key = str_to_num(data);
       
        switch (Key)
        {
                case 1:
                {
                        client_cmd( iPlayer, "messagemode changepass" );
                       
                }
                case 2:
                {
                        client_cmd( iPlayer, "messagemode changeemail" );
                }
 
                case 3:
                {
                        if(g_iTempPassword[iPlayer][0]  == EOS && g_iTempEmail[iPlayer][0]  == EOS)
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PASSWORD", '^3', szName(iPlayer), '^1', '^4', '^1');
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_EMAIL", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //ClCmd_RegisterSay(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iTempPassword[iPlayer][0]  == EOS)
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PASSWORD", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //ClCmd_RegisterSay(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iTempEmail[iPlayer][0]  == EOS)
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_EMAIL", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //ClCmd_RegisterSay(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        ClCmd_Confirm(iPlayer);
                }
       
        }
        menu_destroy(menu);
        return PLUGIN_HANDLED;
}
 
 
public ClCmd_Login(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_REGISTER", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iTempLogin[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        new szArgs[ 60 ];
        read_args( szArgs, charsmax( szArgs ) );
               
        remove_quotes( szArgs );
 
        if(!equali(szArgs, g_iPassword[iPlayer]) )
        {
                ClCmd_LoginSay(iPlayer);
                ++g_iAttempt[iPlayer];
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_INVALID_PASSWORD", '^3', szName(iPlayer), '^1', '^4', szArgs, '^1', '^4', '^1');
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ATTEMPT", '^3', szName(iPlayer), '^1', '^4', g_iAttempt[iPlayer], '^1', '^4', g_nCvar(cvar_attempt), '^1', '^4', '^1');
 
                if(g_iAttempt[iPlayer] >= g_nCvar(cvar_attempt))
                {
                        client_print_color(0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_KICK_ALL_M1", '^3', szName(iPlayer), '^1', '^4', '^1');
                        console_print(iPlayer, "%L", LANG_SERVER, "JB_KICK_INFO_M1");
                        server_cmd("kick #%i ^"%L^"", get_user_userid(iPlayer), LANG_PLAYER, "JB_KICK_LOGIN_M1");
                }
                return PLUGIN_HANDLED;
        }
 
        g_iTempLogin[iPlayer] = 1;
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
        return PLUGIN_HANDLED;
       
}
public ClCmd_LoginSay(iPlayer)
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(is_user_connected(iPlayer))
        {
                if(!g_iRegister[iPlayer])
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_REGISTER", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                if(g_iTempLogin[iPlayer])
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                //g_bHasMenuOpen[id] = true
                if(get_bit(g_bHasMenuOpen, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                set_bit(g_bHasMenuOpen, iPlayer);
 
                new szText[256];               
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_LOGIN_TITLE", szName(iPlayer));
                new menu = menu_create(szText, "sub_loginmenu");
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_LOGIN_M1");
                menu_additem(menu, szText, "1", 0);
               
               
                menu_setprop(menu, MPROP_EXIT , MEXIT_ALL);
                menu_display(iPlayer, menu, 0);
        }
        return PLUGIN_HANDLED;
}
public sub_loginmenu(iPlayer, menu, item)  
{
        if(!g_nCvar(cvar_login_register_account))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
                       
        if (item == MENU_EXIT || !g_iRegister[iPlayer] || g_iTempLogin[iPlayer])
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
 
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[7], name[64];
        new access, callback;
        //clear_bit(g_bHasMenuOpen, id);
        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new Key = str_to_num(data);
       
        switch (Key)
        {
                case 1:
                {
                        client_cmd( iPlayer, "messagemode login" );
                }      
        }
        menu_destroy(menu);
        return PLUGIN_HANDLED;
}
public ClCmd_Level(iPlayer)
{
        client_print(iPlayer,print_chat,"level %i", g_iLevel[iPlayer]);
        client_print(iPlayer,print_chat,"Exp %i", g_iExp[iPlayer]);
}
public ClCmd_Info(iPlayer)
{
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iBan[iPlayer])
        {
                new iMinutes;
                new iHours;
                new iDays;
                iMinutes = g_iBanTime[ iPlayer ];
 
                while ( iMinutes >= 60 )
                {
                        ++iHours;
                        iMinutes -= 60;
                }
                while (iHours >= 24)
                {
                        ++iDays;
                        iHours -= 24;
                }
                if(iDays >= 1)
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_INFO_M1", '^3', '^1', '^4', g_iBanName[iPlayer], '^1', '^4', g_iBanReason[iPlayer], '^1', '^4', iDays, '^1', iDays == 1 ? "" : "le", '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
       
                else if(iHours >= 1)
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_INFO_M2", '^3', '^1', '^4', g_iBanName[iPlayer], '^1', '^4', g_iBanReason[iPlayer], '^1', '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
 
                else
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BAN_INFO_M3", '^3', '^1', '^4', g_iBanName[iPlayer], '^1', '^4', g_iBanReason[iPlayer], '^1', '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
 
        }
        if(g_iMute[iPlayer])
        {
                new iMinutes;
                new iHours;
                new iDays;
                iMinutes = g_iMuteTime[ iPlayer ];
 
                while ( iMinutes >= 60 )
                {
                        ++iHours;
                        iMinutes -= 60;
                }
                while (iHours >= 24)
                {
                        ++iDays;
                        iHours -= 24;
                }
                if(iDays >= 1)
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_INFO_M1", '^3', '^1', '^4', g_iMuteName[iPlayer], '^1', '^4', g_iMuteReason[iPlayer], '^1', '^4', iDays, '^1', iDays == 1 ? "" : "le", '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
       
                else if(iHours >= 1)
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_INFO_M2", '^3', '^1', '^4', g_iMuteName[iPlayer], '^1', '^4', g_iMuteReason[iPlayer], '^1', '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
 
                else
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MUTE_INFO_M3", '^3', '^1', '^4', g_iMuteName[iPlayer], '^1', '^4', g_iMuteReason[iPlayer], '^1', '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
 
        }
        //client_print(iPlayer, print_chat, "%d",g_iJoinTime[iPlayer]);
        return PLUGIN_HANDLED;
}
public ClCmd_Health( iPlayer)
{
        if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
       
        switch(g_bHealth[iPlayer])
        {
                case true:
                {
                        g_bHealth[iPlayer] = false;
 
                        if (task_exists(iPlayer+TASK_HEALTH))
                                remove_task(iPlayer+TASK_HEALTH);
 
                        ClearSyncHud(iPlayer, g_HudHP);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_HP_M1", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                case false:
                {
                        g_bHealth[iPlayer] = true;
                        ShowHealth( iPlayer );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_HP_M2", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
        }
       
        return PLUGIN_HANDLED;
}
 
public ShowHealth( iPlayer ) {
       
        new iHealth = get_user_health( iPlayer );
       
        if( iHealth >= 70 )
                set_hudmessage( 0, 255, 0, 0.01, 0.95, 0, 12.0, 12.0, 0.1, 0.2, 4 );
        else if( iHealth >= 30 )
                set_hudmessage( 255, 140, 0, 0.01, 0.95, 0, 12.0, 12.0, 0.1, 0.2, 4 );
        else
                set_hudmessage( 255, 0, 0, 0.01, 0.95, 0, 12.0, 12.0, 0.1, 0.2, 4);
       
        ShowSyncHudMsg( iPlayer, g_HudHP, "Health: %d", iHealth );
       
        set_task( 12.0 - 0.1, "ShowHealth", iPlayer+TASK_HEALTH );
}
 
public ClCmd_Points( iPlayer )
{
        ++g_iPoints[iPlayer];
        client_print_color( iPlayer, print_team_default, "Points: %d", g_iPoints[iPlayer]);
}
public ClCmd_Drugs( iPlayer )
{
        ++g_iDrugs[iPlayer];
        client_print_color( iPlayer, print_team_default, "Drugs: %d", g_iDrugs[iPlayer]);
}
public ClCmd_Heal(iPlayer)
{
        g_Color[iPlayer] = {255,0,255};
        ScreenPulse(iPlayer);
       
        for(new Float:Count = 2.0;Count <= 10.0;Count += 2.0)
                set_task(Count,"ScreenPulse",iPlayer);
               
        for(new Float:Count = 0.5;Count <= 25.0;Count += 0.5)
                set_task(Count,"Hallucinate",iPlayer);
 
        set_task(26.0,"ClearEffects",iPlayer);
}
public ClearEffects(id)
{
 
        if(task_exists(id))
                remove_task(id);
        if(task_exists(id + 32))
                remove_task(id + 32);
}
public Hallucinate(id)
{
        new Mode;
        if(id > 32)
        {
                id -= 32;
                Mode = 1;
                //set_rendering(id,kRenderFxGlowShell,random_num(0,255),random_num(0,255),random_num(0,255),kRenderNormal,16)
        }
        new Origin[3],Num;
        FindEmptyLoc(id,Origin,Num);
        switch(random_num(0,Mode ? 9 : 4))
        {
                case 0 :
                {      
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_GUNSHOT);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        message_end();
                }
                case 1 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_EXPLOSION2);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        write_byte(0);
                        write_byte(255);
                        message_end();
                }
                case 2 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_IMPLOSION);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        write_byte(255);
                        write_byte(255);
                        write_byte(20);
                        message_end();
                }
                case 3 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_LAVASPLASH);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        message_end();
                }
                case 4 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_TELEPORT);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        message_end();
                }
                case 5 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_SPARKS);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        message_end();
                }
                case 6 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_TAREXPLOSION);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        message_end();
                }
                case 7 :
                {
                        new Float:Punchangle[3];
                        for(new Count;Count < 3;Count++)
                                Punchangle[Count] = random_float(-100.0,100.0);
                        entity_set_vector(id,EV_VEC_punchangle,Punchangle);
                }
                case 8 :
                {
                        for(new Count;Count < 3;Count++)
                                g_Color[id][Count] = random_num(0,255);
 
                        ScreenPulse(id);
                }
                case 9 :
                {
                        message_begin(MSG_ONE_UNRELIABLE,SVC_TEMPENTITY,Origin,id);
                        write_byte(TE_ARMOR_RICOCHET);
                        write_coord(Origin[0]);
                        write_coord(Origin[1]);
                        write_coord(Origin[2]);
                        write_byte(2);
                        message_end();
                }      
        }      
}
public ScreenPulse(id)
{
        message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"),{0,0,0},id);
        write_short(1<<300);
        write_short(1<<300);
        write_short(1<<12);
        write_byte(g_Color[id][0]);
        write_byte(g_Color[id][1]);
        write_byte(g_Color[id][2]);
        write_byte(150);
        message_end();
}
FindEmptyLoc(id,Origin[3],&Num)
{
        if(Num++ > 100)
                return client_print(id,print_chat,"You are in an invalid position to use this drug.");
        new Float:pOrigin[3];
        pev(id,pev_origin,pOrigin);
        for(new Count;Count < 2;Count++)
                pOrigin[Count] += random_float(-100.0,100.0);
        if(PointContents(pOrigin) != CONTENTS_EMPTY && PointContents(pOrigin) != CONTENTS_SKY)
                return FindEmptyLoc(id,Origin,Num);
        Origin[0] = floatround(pOrigin[0]);
        Origin[1] = floatround(pOrigin[1]);
        Origin[2] = floatround(pOrigin[2]);
        return PLUGIN_HANDLED;
}
public ClCmd_Search( iPlayer )
{
        if(!g_nCvar(cvar_search))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iNova[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_NOVA", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        /*new iRandom = random_num(0, g_nCvar(cvar_search_chance))
        switch(iRandom)
        {
                default: client_print(iPlayer, print_chat, "test");
        }*/
        client_print(iPlayer, print_chat, "test");
        return PLUGIN_HANDLED;
}
 
public ClCmd_DrugsMenu(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if(!g_nCvar(cvar_drugs))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
 
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
 
        if(get_user_team(iPlayer) != 1)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PRISONIER", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iLevel[iPlayer] < 1)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LEVEL", '^3', szName(iPlayer), '^1', '^4', g_iLevel[iPlayer] + 1, '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_bCanBuy)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_EXPIRED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        show_drugsmenu(iPlayer);
        return PLUGIN_HANDLED;
}
public show_drugsmenu(iPlayer)
{
        if(is_user_alive(iPlayer) && get_user_team(iPlayer) == 1)
        {
                new szText[256];
                new drugs = g_iDrugs[iPlayer];
                //g_bHasMenuOpen[id] = true
                if(get_bit(g_bHasMenuOpen, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                set_bit(g_bHasMenuOpen, iPlayer);
               
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_TITLE", drugs);
                new drugsmenu = menu_create(szText, "sub_drugsmenu");
               
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M1", g_sCrowbar, g_nCvar(cvar_crowbar_limit), g_nCvar(cvar_crowbar_price) );
                menu_additem(drugsmenu, szText, "1", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M2", g_sPipe, g_nCvar(cvar_pipe_limit), g_nCvar(cvar_pipe_price) );
                menu_additem(drugsmenu, szText, "2", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M3", g_sNail, g_nCvar(cvar_nail_limit), g_nCvar(cvar_nail_price) );
                menu_additem(drugsmenu, szText, "3", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M4", g_sBanana, g_nCvar(cvar_banana_limit), g_nCvar(cvar_banana_price) );
                menu_additem(drugsmenu, szText, "4", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M5", g_sUsp, g_nCvar(cvar_usp_limit), g_nCvar(cvar_usp_price) );
                menu_additem(drugsmenu, szText, "5", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M6", g_sGlock, g_nCvar(cvar_glock_limit), g_nCvar(cvar_glock_price) );
                menu_additem(drugsmenu, szText, "6", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_BSHOP_M7", g_sInvest, g_nCvar(cvar_invest_limit), g_nCvar(cvar_invest_price) );
                menu_additem(drugsmenu, szText, "7", 0);
               
                menu_setprop(drugsmenu, MPROP_EXIT , MEXIT_ALL);
                menu_display(iPlayer, drugsmenu, 0);
        }
        return PLUGIN_HANDLED;
}
public sub_drugsmenu(iPlayer, drugsmenu, item)  
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
                       
        if (item == MENU_EXIT || get_user_team(iPlayer) == 2 || !is_user_alive(iPlayer) || !g_bCanBuy)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
                menu_destroy(drugsmenu);
                return PLUGIN_HANDLED;
        }
       
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[7], name[64];
        new access, callback;
        menu_item_getinfo(drugsmenu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new Key = str_to_num(data);
       
        switch (Key)
        {
                case 1:
                {
                        if(get_bit(g_bHasCrowbar, iPlayer) || get_bit(g_bHasBanana, iPlayer) || get_bit(g_bHasNail, iPlayer) || get_bit(g_bHasPipe, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iDrugs[iPlayer] < g_nCvar(cvar_crowbar_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_crowbar_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sCrowbar >= g_nCvar(cvar_crowbar_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_crowbar_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_crowbar(iPlayer);
                }
                case 2:
                {
                        if(get_bit(g_bHasCrowbar, iPlayer) || get_bit(g_bHasBanana, iPlayer) || get_bit(g_bHasNail, iPlayer) || get_bit(g_bHasPipe, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iDrugs[iPlayer] < g_nCvar(cvar_pipe_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_pipe_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sPipe >= g_nCvar(cvar_pipe_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_pipe_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_pipe(iPlayer);
                }
                case 3:
                {
                        if(get_bit(g_bHasCrowbar, iPlayer) || get_bit(g_bHasBanana, iPlayer) || get_bit(g_bHasNail, iPlayer) || get_bit(g_bHasPipe, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iDrugs[iPlayer] < g_nCvar(cvar_nail_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nail_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sNail >= g_nCvar(cvar_nail_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nail_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_nail(iPlayer);
                }
                case 4:
                {
                        if(get_bit(g_bHasCrowbar, iPlayer) || get_bit(g_bHasBanana, iPlayer) || get_bit(g_bHasNail, iPlayer) || get_bit(g_bHasPipe, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iDrugs[iPlayer] < g_nCvar(cvar_banana_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_banana_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sBanana >= g_nCvar(cvar_banana_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_banana_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_banana(iPlayer);
                }
                case 5:
                {
                        if(get_bit(g_bHasUsp, iPlayer) || get_bit(g_bHasGlock, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_usp_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_usp_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sUsp >= g_nCvar(cvar_usp_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_usp_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_usp(iPlayer);
                }
                case 6:
                {
                        if(get_bit(g_bHasUsp, iPlayer) || get_bit(g_bHasGlock, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iDrugs[iPlayer] < g_nCvar(cvar_glock_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_glock_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sGlock >= g_nCvar(cvar_glock_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_glock_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_glock(iPlayer);
                }
                case 7:
                {
                        if(get_bit(g_bHasInvest, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY_DRUGS", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iDrugs[iPlayer] < g_nCvar(cvar_invest_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_invest_price), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sInvest >= g_nCvar(cvar_invest_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_invest_limit), '^4', '^1');
                                //show_drugsmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_invest(iPlayer);
                }
       
        }
        menu_destroy(drugsmenu);
        return PLUGIN_HANDLED;
}
public give_crowbar(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_crowbar_price), '^4', '^1');
        ++g_sCrowbar;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_crowbar_price);
 
        new iRandom = random_num(1, g_nCvar(cvar_crowbar_chance));
 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasCrowbar, iPlayer);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CROWBAR", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
public give_pipe(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_pipe_price), '^4', '^1');
        ++g_sPipe;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_pipe_price);
 
        new iRandom = random_num(1, g_nCvar(cvar_pipe_chance));
 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasPipe, iPlayer);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PIPE", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
public give_nail(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nail_price), '^4', '^1');
        ++g_sNail;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_nail_price);
 
        new iRandom = random_num(1, g_nCvar(cvar_nail_chance));
 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasNail, iPlayer);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NAIL", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
public give_banana(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_banana_price), '^4', '^1');
        ++g_sBanana;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_banana_price);
 
        new iRandom = random_num(1, g_nCvar(cvar_banana_chance));
 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasBanana, iPlayer);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_BANANA", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
public give_usp(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_usp_price), '^4', '^1');
        ++g_sUsp;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_usp_price);
       
        new iRandom = random_num(1, g_nCvar(cvar_usp_chance)); 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasUsp, iPlayer);
                        cs_set_weapon_ammo( give_item( iPlayer, "weapon_usp" ), 3 );
                        cs_set_user_bpammo( iPlayer, CSW_USP, 0 );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_USP", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
 
}
public give_glock(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_glock_price), '^4', '^1');
        ++g_sGlock;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_glock_price);
 
        new iRandom = random_num(1, g_nCvar(cvar_glock_chance));
 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasGlock, iPlayer);
                        cs_set_weapon_ammo( give_item( iPlayer, "weapon_glock18" ), 3 );
                        cs_set_user_bpammo( iPlayer, CSW_GLOCK18, 0 );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GLOCK", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
public give_invest(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY_DRUGS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_invest_price), '^4', '^1');
        ++g_sInvest;
        g_iDrugs[iPlayer] -= g_nCvar(cvar_invest_price);
        new iRandom = random_num(1, g_nCvar(cvar_invest_chance));
 
        switch(iRandom)
        {
                case 1:
                {
                        set_bit(g_bHasInvest, iPlayer);
                        g_iDrugs[iPlayer] += g_nCvar(cvar_invest_price) + g_nCvar(cvar_invest_bonus);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_INVEST", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_UNLUCKY", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
}
 
public ClCmd_ShopMenu(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if(!g_nCvar(cvar_shop))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(get_user_team(iPlayer) != 1)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PRISONIER", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iLevel[iPlayer] < 1)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LEVEL", '^3', szName(iPlayer), '^1', '^4', g_iLevel[iPlayer] + 1, '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_bCanBuy)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_EXPIRED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        show_shopmenu(iPlayer);
        return PLUGIN_HANDLED;
}
public show_shopmenu(iPlayer)
{
        if(is_user_alive(iPlayer) && get_user_team(iPlayer) == 1)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                set_bit(g_bHasMenuOpen, iPlayer);
 
                new szText[256];
                new points = g_iPoints[iPlayer];
                //g_bHasMenuOpen[id] = true
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_TITLE", points);
                new shopmenu = menu_create(szText, "sub_shopmenu");
               
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M1", g_nCvar(cvar_health_quant), g_sHealth, g_nCvar(cvar_health_limit), g_nCvar(cvar_health_price) );
                menu_additem(shopmenu, szText, "1", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M2", g_nCvar(cvar_drugs_quants), g_nCvar(cvar_drugs_quants) == 1 ? "" : "uri", g_sDrugs, g_nCvar(cvar_drugs_limit), g_nCvar(cvar_drugs_price) );
                menu_additem(shopmenu, szText, "2", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M3", g_sFlashBang, g_nCvar(cvar_flashbang_limit), g_nCvar(cvar_flashbang_price) );
                menu_additem(shopmenu, szText, "3", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M4", g_sCellKey, g_nCvar(cvar_key_limit), g_nCvar(cvar_key_price) );
                menu_additem(shopmenu, szText, "4", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M5", g_sGunGamble, g_nCvar(cvar_gamble_limit), g_nCvar(cvar_gamble_price) );
                menu_additem(shopmenu, szText, "5", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M6", g_sDisguise, g_nCvar(cvar_disguise_limit), g_nCvar(cvar_disguise_price) );
                menu_additem(shopmenu, szText, "6", 0);
 
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_SHOP_M7", g_sFreeday, g_nCvar(cvar_freeday_limit), g_nCvar(cvar_freeday_price) );
                menu_additem(shopmenu, szText, "7", 0);
               
                menu_setprop(shopmenu, MPROP_EXIT , MEXIT_ALL);
                menu_display(iPlayer, shopmenu, 0);
        }
        return PLUGIN_HANDLED;
}
public sub_shopmenu(iPlayer, shopmenu, item)  
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
                       
        if (item == MENU_EXIT || get_user_team(iPlayer) == 2 || !is_user_alive(iPlayer) || !g_bCanBuy)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
                menu_destroy(shopmenu);
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[7], name[64];
        new access, callback;
        menu_item_getinfo(shopmenu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new Key = str_to_num(data);
       
        switch (Key)
        {
                case 1:
                {
                        if(get_bit(g_bHasHealth, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_health_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_health_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sHealth >= g_nCvar(cvar_health_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_health_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_health(iPlayer);
                }
                case 2:
                {
                        if(get_bit(g_bHasDrugs, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_drugs_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_drugs_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sDrugs >= g_nCvar(cvar_drugs_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_drugs_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_drugs(iPlayer);
                }
                case 3:
                {
                        if(get_bit(g_bHasFlashBang, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_flashbang_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_flashbang_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sFlashBang >= g_nCvar(cvar_flashbang_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_flashbang_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_flashbang(iPlayer);
                }
                case 4:
                {
                        if(get_bit(g_bHasCellKey, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_key_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_key_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sCellKey >= g_nCvar(cvar_key_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_key_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_cellkey(iPlayer);
                }
                case 5:
                {
                        if(get_bit(g_bHasGunGamble, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_gamble_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gamble_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sGunGamble >= g_nCvar(cvar_gamble_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gamble_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_gamble(iPlayer);
                }
                case 6:
                {
                        if(get_bit(g_bHasDisguise, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_disguise_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_disguise_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sFreeday >= g_nCvar(cvar_disguise_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_disguise_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_disguise(iPlayer);
                }
                case 7:
                {
                        if(get_bit(g_bHasFreeday, iPlayer))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ALREADY", '^3', szName(iPlayer), '^1', '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_iPoints[iPlayer] < g_nCvar(cvar_freeday_price) )
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_freeday_price), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        if(g_sFreeday >= g_nCvar(cvar_freeday_limit))
                        {
                       
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TO_MUCH", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_freeday_limit), '^4', '^1');
                                //show_shopmenu(iPlayer);
                                return PLUGIN_HANDLED;
                        }
                        give_freeday(iPlayer);
                }
       
        }
        menu_destroy(shopmenu);
        return PLUGIN_HANDLED;
}
public give_health(iPlayer)
{
 
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_health_price), '^4', '^1');
        ++g_sHealth;
        set_bit(g_bHasHealth, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_health_price);
        set_user_health(iPlayer, get_user_health(iPlayer) + g_nCvar(cvar_health_quant));
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
 
}
public give_drugs(iPlayer)
{
 
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_drugs_price), '^4', '^1');
        ++g_sDrugs;
        set_bit(g_bHasDrugs, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_drugs_price);
        g_iDrugs[iPlayer] += g_nCvar(cvar_drugs_quants);
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
}
public give_flashbang(iPlayer)
{
 
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_flashbang_price), '^4', '^1');
        ++g_sFlashBang;
        set_bit(g_bHasFlashBang, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_flashbang_price);
        give_item(iPlayer, "weapon_flashbang");
 
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
       
}
public give_cellkey(iPlayer)
{
 
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_key_price), '^4', '^1');
        ++g_sCellKey;
        set_bit(g_bHasCellKey, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_key_price);
 
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
 
}
public give_gamble(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gamble_price), '^4', '^1');
        ++g_sGunGamble;
        set_bit(g_bHasGunGamble, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_gamble_price);
       
        new iRandom = random_num(1, g_nCvar(cvar_gamble_chance));      
 
        switch(iRandom)
        {
                case 1:
                {
                        give_item( iPlayer, "weapon_flashbang" );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M1", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                case 2:
                {
                        give_item( iPlayer, "weapon_smokegrenade" );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M2", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                case 3:
                {
                        set_user_health(iPlayer, get_user_health(iPlayer) + g_nCvar(cvar_health_quant));
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M3", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                case 4:
                {
                        set_user_health(iPlayer, get_user_health(iPlayer) + g_nCvar(cvar_health_quant) * 2);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M4", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                case 5:
                {
                        cs_set_weapon_ammo( give_item( iPlayer, "weapon_scout" ), 1 );
                        cs_set_user_bpammo( iPlayer, CSW_SCOUT, 0 );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M5", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                case 6:
                {
                        cs_set_weapon_ammo( give_item( iPlayer, "weapon_awp" ), 1 );
                        cs_set_user_bpammo( iPlayer, CSW_AWP, 0 );
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M6", '^3', szName(iPlayer), '^1', '^4', '^1');
                }
                default: client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GAMBLE_M7", '^3', szName(iPlayer), '^1', '^4', '^1');
        }
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
 
}
public give_disguise(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_disguise_price), '^4', '^1');
        ++g_sDisguise;
        set_bit(g_bHasDisguise, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_disguise_price);
 
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
 
}
public give_freeday(iPlayer)
{
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_PAY", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_freeday_price), '^4', '^1');
        ++g_sFreeday;
        set_bit(g_bHasFreeday, iPlayer);
        g_iPoints[iPlayer] -= g_nCvar(cvar_freeday_price);
 
        if(g_nCvar(cvar_moneypoint) == 1)
                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
}
public ClCmd_MoneyMenu(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if(!g_nCvar(cvar_money))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iLevel[iPlayer] < 1)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LEVEL", '^3', szName(iPlayer), '^1', '^4', g_iLevel[iPlayer] + 1, '^1');
                return PLUGIN_HANDLED;
        }
        show_moneymenu(iPlayer);       
        return PLUGIN_HANDLED;
}
public show_moneymenu(iPlayer)
{
        if(get_bit(g_bHasMenuOpen, iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        set_bit(g_bHasMenuOpen, iPlayer);
        new szText[256];
        formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_MONEY_TITLE", g_iMoneys[iPlayer]);
        new moneymenu = menu_create(szText, "sub_moneymenu");
       
        formatex(szText, 39, "%L", LANG_SERVER, "JB_MONEY_M1", g_nCvar(cvar_nova_cost));
        menu_additem(moneymenu, szText, "1", 0);
        if(g_iNova[iPlayer])
        {
                formatex(szText, 39, "%L", LANG_SERVER, "JB_MONEY_M2", g_nCvar(cvar_gold_cost) / 2);
                menu_additem(moneymenu, szText, "2", 0);
        }
        else
        {
                formatex(szText, 39, "%L", LANG_SERVER, "JB_MONEY_M2", g_nCvar(cvar_gold_cost));
                menu_additem(moneymenu, szText, "2", 0);
        }
        formatex(szText, 39, "%L", LANG_SERVER, "JB_MONEY_M3", g_nCvar(cvar_drugs_quant), g_nCvar(cvar_drugs_quant) == 1 ? "" : "e" , g_nCvar(cvar_drugs_cost));
        menu_additem(moneymenu, szText, "3", 0);
        formatex(szText, 39, "%L", LANG_SERVER, "JB_MONEY_M4", g_nCvar(cvar_points_quant), g_nCvar(cvar_points_quant) == 1 ? "" : "e" , g_nCvar(cvar_points_cost));
        menu_additem(moneymenu, szText, "4", 0);
       
        menu_display(iPlayer, moneymenu);
        return PLUGIN_HANDLED;
}
public sub_moneymenu(iPlayer, moneymenu, item)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if( item == MENU_EXIT)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
 
                menu_destroy(moneymenu);
                return PLUGIN_HANDLED;
        }
       
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);    
 
        new data[6], name[64];
        new access, callback;
        menu_item_getinfo(moneymenu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        switch(str_to_num(data))
        {
                case 1:
                {
                        if(g_iNova[iPlayer])
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA", '^3', szName(iPlayer), '^1', '^4', '^1');
                                return PLUGIN_HANDLED;
                        }
                        if(g_iMoneys[iPlayer] < g_nCvar(cvar_nova_cost))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nova_cost), '^4', '^1');
                                return PLUGIN_HANDLED;
                        }
                        g_iNova[ iPlayer ] = 1;
                        g_iMoneys[iPlayer] -= g_nCvar(cvar_nova_cost);
                        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M1", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nova_cost), '^1', '^4', '^1');
                        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M3", '^1', '^3', szName(iPlayer), '^1', '^4', '^1');
                        Save_MySql(iPlayer);
                }
 
                case 2:
                {
                        if(g_iGold[iPlayer])
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GOLD", '^3', szName(iPlayer), '^1', '^4', '^1');
                                return PLUGIN_HANDLED;
                        }
                        ClCmd_Gold( iPlayer );
                }
                case 3:
                {
                        if(g_iMoneys[iPlayer] < g_nCvar(cvar_drugs_cost))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_drugs_cost), '^4', '^1');
                                return PLUGIN_HANDLED;
                        }
                        g_iDrugs[ iPlayer ] += g_nCvar(cvar_points_quant);
                        g_iMoneys[iPlayer] -= g_nCvar(cvar_drugs_cost);
                        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DRUGSS_BOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_drugs_cost), '^1', '^3', g_nCvar(cvar_drugs_quant), '^4', '^1');
                        Save_MySql(iPlayer);
                }
 
                case 4:
                {
                        if(g_iMoneys[iPlayer] < g_nCvar(cvar_points_cost))
                        {
                                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_points_cost), '^4', '^1');
                                return PLUGIN_HANDLED;
                        }
                        g_iPoints[ iPlayer ] += g_nCvar(cvar_points_quant);
                       
                        if(g_nCvar(cvar_moneypoint) == 1)
                                cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
 
                        g_iMoneys[iPlayer] -= g_nCvar(cvar_points_cost);
                        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_POINTS_BOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_points_cost), '^1', '^3', g_nCvar(cvar_points_quant), '^4', '^1');
                        Save_MySql(iPlayer);
                }
        }
 
        menu_destroy(moneymenu);
        return PLUGIN_HANDLED;
}
 
#define COSTUMESS 2
new const g_iCostumesNames[COSTUMESS][] =
{
        "JB_COSTUMES_M1",
        "JB_COSTUMES_M2"
};
public ClCmd_Costumes(iPlayer)
{
        if(!g_iNova[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_NOVA", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(get_bit(g_bHasMenuOpen, iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        set_bit(g_bHasMenuOpen, iPlayer);
        new szText[256];
        formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_COSTUMES_TITLE");
        new menu = menu_create(szText, "Costumes_submenu");
                                       
        new iNumber[5], szOption[40];
        for( new i = 0; i < COSTUMESS; i++ ) {
                num_to_str(i+1, iNumber, 4);
                formatex(szOption, 39, "%L", LANG_SERVER, g_iCostumesNames[i]);
                menu_additem(menu, szOption, iNumber);
        }
       
        //menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
        menu_setprop(menu, MPROP_EXIT , MEXIT_ALL);
        menu_display(iPlayer, menu, 0);
        return PLUGIN_CONTINUE;
}
public Costumes_submenu(iPlayer, menu, item)
{
        if(item == MENU_EXIT || !g_iNova[iPlayer] || !is_user_alive(iPlayer))
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
 
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);    
 
        new data[7], name[64];
        new access, callback;
        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new key = str_to_num(data);
 
        switch(key)
        {
                case 1:
                {
                        random_costumes(iPlayer, random_num(1,3));
                }
                case 2:
                {
                        jb_hide_user_costumes(iPlayer);
                }
 
        }
       
        menu_destroy(menu);
        ClCmd_Costumes(iPlayer);
        return PLUGIN_CONTINUE;
}
random_costumes(iPlayer, iNumber)
{
        switch(iNumber)
        {
                case 1:
                {
                        jb_set_user_costumes(iPlayer, 1);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_body, random_num(1,40));
                }
                case 2:
                {
                        jb_set_user_costumes(iPlayer, 2);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_body, random_num(1,50));
                }
                case 3:
                {
                        jb_set_user_costumes(iPlayer, 3);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_body, random_num(1,44));
                }
        }
}
 
public jb_set_user_costumes(iPlayer, iCostumes)
{
        if(!g_iCostumesListSize || iCostumes > g_iCostumesListSize) return 0;
        if(iCostumes)
        {
                new szBuffer[64];
                if(!g_eUserCostumes[iPlayer][ENTITY])
                {
                        static iszFuncWall = 0;
                        if(iszFuncWall || (iszFuncWall = engfunc(EngFunc_AllocString, "func_wall"))) g_eUserCostumes[iPlayer][ENTITY] = engfunc(EngFunc_CreateNamedEntity, iszFuncWall);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_movetype, MOVETYPE_FOLLOW);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_aiment, iPlayer);
                        ArrayGetString(g_aCostumesList, iCostumes - 1, szBuffer, charsmax(szBuffer));
                        engfunc(EngFunc_SetModel, g_eUserCostumes[iPlayer][ENTITY], szBuffer);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_sequence, 0);
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_animtime, get_gametime());
                        set_pev(g_eUserCostumes[iPlayer][ENTITY], pev_framerate, 1.0);
                        //entity_set_int(g_eUserCostumes[iPlayer][ENTITY], EV_INT_body, iNumber);
                        //engfunc(EngFunc_SetModel, g_eUserCostumes[iPlayer][ENTITY], iNumber);
                }
                else
                {
                        ArrayGetString(g_aCostumesList, iCostumes - 1, szBuffer, charsmax(szBuffer));
                        engfunc(EngFunc_SetModel, g_eUserCostumes[iPlayer][ENTITY], szBuffer);
                }
                g_eUserCostumes[iPlayer][HIDE] = false;
                g_eUserCostumes[iPlayer][COSTUMES] = iCostumes;
                return PLUGIN_HANDLED;
        }
        else if(g_eUserCostumes[iPlayer][COSTUMES])
                {
                if(g_eUserCostumes[iPlayer][ENTITY]) engfunc(EngFunc_RemoveEntity, g_eUserCostumes[iPlayer][ENTITY]);
                g_eUserCostumes[iPlayer][ENTITY] = 0;
                g_eUserCostumes[iPlayer][HIDE] = false;
                g_eUserCostumes[iPlayer][COSTUMES] = 0;
                return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
}
public jb_hide_user_costumes(iPlayer)
{
        if(g_eUserCostumes[iPlayer][ENTITY])
        {
                engfunc(EngFunc_RemoveEntity, g_eUserCostumes[iPlayer][ENTITY]);
                g_eUserCostumes[iPlayer][ENTITY] = 0;
                g_eUserCostumes[iPlayer][HIDE] = true;
                return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
}
 
public ClCmd_Nova( iPlayer )
{
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iNova[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iPlayerTime[ iPlayer ] < 60 * 24 * g_nCvar(cvar_nova_time))       
        {      
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT_TIME", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nova_time), '^4', '^1');
                return PLUGIN_HANDLED;
        }
        g_iNova[ iPlayer ] = 1;
        //client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M1", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nova_cost), '^1', '^4', '^1');
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M2", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nova_time), '^1', '^4', '^1');
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M3", '^1', '^3', szName(iPlayer), '^1', '^4', '^1');
        Save_MySql(iPlayer);
        return PLUGIN_HANDLED;
}
public ClCmd_Gold( iPlayer )
{
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iGold[iPlayer])
        {
                new iMinutes;
                new iHours;
                new iDays;
                iMinutes = g_iGoldTime[ iPlayer ];
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NAME", '^1', '^3', szName(iPlayer));
               
                if ( iMinutes <= 0)
                        iMinutes = 0;
 
                while ( iMinutes >= 60 )
                {
                        ++iHours;
                        iMinutes -= 60;
                }
                while (iHours >= 24)
                {
                        ++iDays;
                        iHours -= 24;
                }
 
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_VIP", '^1', '^4', iDays, '^1', iDays == 1 ? "" : "le", '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
                return PLUGIN_HANDLED;
        }
        if(g_iNova[iPlayer] && g_iMoneys[iPlayer] < g_nCvar(cvar_gold_cost) / 2)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gold_cost) / 2, '^4', '^1');
                return PLUGIN_HANDLED;
        }
        else if(g_iMoneys[iPlayer] < g_nCvar(cvar_gold_cost))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOT_ENOUGHT", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gold_cost), '^4', '^1');
                return PLUGIN_HANDLED;
        }
        g_iGold[ iPlayer ] = 1;
        g_iJoinTime[iPlayer] = get_systime();
        g_iGoldTime[iPlayer] = 60 * 24 * g_nCvar(cvar_gold_time);
        if(g_iNova[iPlayer])
        {
                g_iMoneys[iPlayer] -= g_nCvar(cvar_gold_cost) / 2;
        }
        else
        {
                g_iMoneys[iPlayer] -= g_nCvar(cvar_gold_cost);
                g_iNova[ iPlayer ] = 1;
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M1", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_nova_cost), '^1', '^4', '^1');
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NOVA_BOUGHT_M3", '^1', '^3', szName(iPlayer), '^1', '^4', '^1');
        }
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GOLD_BOUGHT_M1", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gold_cost) / 2, '^1', '^4', '^1');
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_GOLD_BOUGHT_M2", '^1', '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_gold_time), '^1', '^4', '^1');
        ClCmd_RegisterSay(iPlayer);
        Save_MySql(iPlayer);
        return PLUGIN_HANDLED;
}
 
public ClCmd_Vip0( iPlayer )
{
        //g_iNova[ iPlayer ] = 0;
        //g_iGold[ iPlayer ] = 0;
}
 
public ClCmd_Time( iPlayer )
{      
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        new iTime = get_user_time( iPlayer, 1);
        new iMinutes;
        new iHours;
        new iDays;
        iMinutes = iTime / 60  + g_iPlayerTime[ iPlayer ];
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NAME", '^1', '^3', szName(iPlayer));
       
        while ( iMinutes >= 60 )
        {
                ++iHours;
                iMinutes -= 60;
        }
        while (iHours >= 24)
        {
                ++iDays;
                iHours -= 24;
        }
 
        if(iDays >= 1)
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TOTAL_M1", '^1', '^4', iDays, '^1', iDays == 1 ? "" : "le", '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
       
        else if(iHours >= 1)
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TOTAL_M2", '^1', '^4', iHours, '^1', iHours == 1 ? "a" : "e", '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
 
        else
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_TOTAL_M3", '^1', '^4', iMinutes,'^1', iMinutes == 1 ? "" : "e");
 
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_TIME_SESSION", '^1', '^4', ( iTime / 60 ), '^1', ( iTime / 60 ) == 1 ? "" : "e", '^4', szMap(), '^1' );
        return PLUGIN_HANDLED;
}
 
public ClCmd_Contact( iPlayer )
{      
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CONTACT_TITLE", '^1');
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CONTACT_M1", '^1', '^4', '^1', '^4', '^1', '^4', '^1');
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CONTACT_M2", '^1', '^4', '^1', '^4', '^1', '^4', '^1');
        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CONTACT_M3", '^1', '^4', '^1', '^4', '^1', '^4', '^1');
}
 
public ClCmd_Simon(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
               
        if(get_user_team(iPlayer) != 2)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_GUARD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
       
        if (fnGetTerrorists() < g_nCvar(cvar_min_tero_simon))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_SIMON_PRISONIERS", '^3', szName(iPlayer), '^1', '^3', g_nCvar(cvar_min_tero_simon), '^4', g_nCvar(cvar_min_tero_simon) == 1 ? "" : "i", '^1');
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bIsSimon, iPlayer))
        {
                ResetSimon(iPlayer);
                fm_set_speak(iPlayer, SPEAK_TEAM);
                client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_SIMON_DISMISS", '^3', szName(iPlayer), '^1', '^4', '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
       
        if (fnGetSimons() >= g_nCvar(cvar_max_simons))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_SIMON", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        client_print_color( 0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_SIMON_HIRED", '^3', szName(iPlayer), '^1', '^4', '^1', '^4', '^1');               
        set_bit(g_bIsSimon, iPlayer);
        fm_set_speak(iPlayer, SPEAK_ALL);
        if (!task_exists(iPlayer+TASK_SIMONBEAM))
                set_task(3.0, "Task_SimonStartRing", iPlayer+TASK_SIMONBEAM, _, _, "b");
        return PLUGIN_HANDLED;
}
new const g_iClassNames[][] = {
        "JB_CLASS_M1",
        "JB_CLASS_M2",
        "JB_CLASS_M3",
        "JB_CLASS_M4",
        "JB_CLASS_M5",
        "JB_CLASS_M6",
        "JB_CLASS_M7",
        "JB_CLASS_M8",
        "JB_CLASS_M9",
        "JB_CLASS_M10"
};
#define CLASS sizeof(g_iClassNames)
new const g_iAccessClass[CLASS] = {
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        ADMIN_KICK
};
public ClCmd_ClassMenu(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
       
        if(get_user_team(iPlayer) != 2)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_GUARD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
       
        if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
       
        if(!g_bCanBuy)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_EXPIRED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        set_bit(g_bHasMenuOpen, iPlayer);
        new szText[256];
        formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_CLASS_TITLE");
        new menu = menu_create(szText, "Class_submenu");
       
        // Give random weapon for Shot4Shot
        new iNumber[5], szOption[40];
        for( new i = 0; i < CLASS; i++ ) {
                num_to_str(i+1, iNumber, 4);
                formatex(szOption, 39, "%L", LANG_SERVER, g_iClassNames[i]);
                menu_additem(menu, szOption, iNumber, g_iAccessClass[i]);
        }
       
        menu_display(iPlayer, menu);
        return PLUGIN_HANDLED;
}
public Class_submenu(iPlayer, menu, item)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if( item == MENU_EXIT || get_user_team( iPlayer ) != 2)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
       
        if( get_user_team(iPlayer) != 2)
                return PLUGIN_HANDLED;
       
        if(!is_user_alive(iPlayer))
                return PLUGIN_HANDLED;
       
        if(!g_bCanBuy)
                return PLUGIN_HANDLED;
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[6], name[64];
        new access, callback;
        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        switch(str_to_num(data))
        {
                case 1:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_m4a1");
                        cs_set_user_bpammo(iPlayer, CSW_M4A1, 90);
                        give_item(iPlayer, "weapon_usp");
                        cs_set_user_bpammo(iPlayer, CSW_USP, 100);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M1", '^1');
 
                }
                case 2:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_ak47");
                        cs_set_user_bpammo(iPlayer, CSW_AK47, 90);
                        give_item(iPlayer, "weapon_glock18");
                        cs_set_user_bpammo(iPlayer, CSW_GLOCK18, 120);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M2", '^1');
 
                }
                case 3:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_awp");
                        cs_set_user_bpammo(iPlayer, CSW_AWP, 30);
                        give_item(iPlayer, "weapon_deagle");
                        cs_set_user_bpammo(iPlayer, CSW_DEAGLE, 35);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M3", '^1');
 
                }
                case 4:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_galil");
                        cs_set_user_bpammo(iPlayer, CSW_GALIL, 90);
                        give_item(iPlayer, "weapon_elite");
                        cs_set_user_bpammo(iPlayer, CSW_ELITE, 100);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M4", '^1');
 
                }
                case 5:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_m3");
                        cs_set_user_bpammo(iPlayer, CSW_M3, 32);
                        give_item(iPlayer, "weapon_p228");
                        cs_set_user_bpammo(iPlayer, CSW_P228, 52);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M5", '^1');
 
                }
                case 6:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_aug");
                        cs_set_user_bpammo(iPlayer, CSW_AUG, 90);
                        give_item(iPlayer, "weapon_fiveseven");
                        cs_set_user_bpammo(iPlayer, CSW_FIVESEVEN, 72);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M6", '^1');
 
                }
                case 7:
                {
                        StripPlayerWeapons(iPlayer);                   
                        give_item(iPlayer, "weapon_g3sg1");
                        cs_set_user_bpammo(iPlayer, CSW_G3SG1, 90);
                        give_item(iPlayer, "weapon_deagle");
                        cs_set_user_bpammo(iPlayer, CSW_DEAGLE, 35);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M7", '^1');
 
                }
                case 8:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_tmp");
                        cs_set_user_bpammo(iPlayer, CSW_TMP, 120);
                        give_item(iPlayer, "weapon_usp");
                        cs_set_user_bpammo(iPlayer, CSW_USP, 100);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M8", '^1');
 
                }
                case 9:
                {
                        StripPlayerWeapons(iPlayer);
                        give_item(iPlayer, "weapon_mp5navy");
                        cs_set_user_bpammo(iPlayer, CSW_MP5NAVY, 120);
                        give_item(iPlayer, "weapon_glock18");
                        cs_set_user_bpammo(iPlayer, CSW_GLOCK18, 120);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M9", '^1');
 
                }
                case 10:
                {
                        give_item(iPlayer, "weapon_m249");
                        cs_set_user_bpammo(iPlayer, CSW_M249, 400);
                        give_item(iPlayer, "weapon_elite");
                        cs_set_user_bpammo(iPlayer, CSW_ELITE, 100);
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_CLASS", '^3', szName(iPlayer), '^1', '^4', LANG_SERVER, "JB_CLASS_MESSAGE_M10", '^1');
 
                }
        }
        menu_destroy(menu);
        return PLUGIN_HANDLED;
}
public ClCmd_Clear(iPlayer)
{
        set_user_gang(  iPlayer, -1 );
        client_print(iPlayer, print_chat, "test");
}
 
public ClCmd_Gang(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if(!g_nCvar(cvar_gang))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEACTIVATE", '^3', szName(iPlayer), '^1');
                return PLUGIN_HANDLED;
        }
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(get_user_team(iPlayer) != 1)
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_PRISONIER", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        /*if(!is_user_alive(iPlayer))
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_DEAD", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }*/
        show_gangmenu(iPlayer);
        return PLUGIN_HANDLED;
}
public show_gangmenu(iPlayer)
{
        if(get_user_team(iPlayer) == 1)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                {
                        client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_MENU_OPENED", '^3', szName(iPlayer), '^1', '^4', '^1');
                        return PLUGIN_HANDLED;
                }
                set_bit(g_bHasMenuOpen, iPlayer);
 
                new szText[256];
                //new points = g_iPoints[iPlayer];
                static aData[GangInfo], iStatus;
                //iStatus = getStatus(iPlayer, g_iCheck[iPlayer]);
                //g_bHasMenuOpen[id] = true
                       
                formatex(szText, charsmax(szText), "%L", LANG_SERVER, "JB_GANG_TITLE", g_iCheck[iPlayer] > -1 ? aData[ GangName ] : "None" );
                new gangmenu = menu_create(szText, "sub_gangmenu");
               
                formatex(szText, 39, "%s %L", g_iCheck[iPlayer] > -1 ? "\d" : "\w", LANG_SERVER, "JB_GANG_M1",  g_nCvar(cvar_gang_cost));
                menu_additem(gangmenu, szText, "1", 0);                
               
                menu_setprop(gangmenu, MPROP_EXIT , MEXIT_ALL);
                menu_display(iPlayer, gangmenu, 0);
        }
        return PLUGIN_HANDLED;
}
public sub_gangmenu(iPlayer, gangmenu, item)  
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
                       
        if (item == MENU_EXIT || get_user_team(iPlayer) == 2)
        {
                if(get_bit(g_bHasMenuOpen, iPlayer))
                        clear_bit(g_bHasMenuOpen, iPlayer);
 
                menu_destroy(gangmenu);
                return PLUGIN_HANDLED;
        }
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        new data[7], name[64];
        new access, callback;
        menu_item_getinfo(gangmenu, item, access, data, charsmax(data), name, charsmax(name), callback);
       
        new Key = str_to_num(data);
       
        switch (Key)
        {
                case 1:
                {
                        client_cmd(iPlayer, "messagemode gang_name");
                }
       
        }
        menu_destroy(gangmenu);
        return PLUGIN_HANDLED;
}
/*
public ClCmd_Gang(iPlayer)
{
        client_cmd(iPlayer, "messagemode gang_name");
}*/
public ClCmd_CreateGang(iPlayer)
{
        new szArgs[ 60 ];
        read_args( szArgs, charsmax( szArgs ) );
               
        remove_quotes( szArgs );
               
        if( TrieKeyExists( g_tGangNames, szArgs ) )
        {
                client_print(iPlayer, print_chat, "acest %s exista deja", szArgs);
                return PLUGIN_HANDLED;
        }
        if( g_iCheck[ iPlayer ] > -1 )
        {
                client_print(iPlayer, print_chat, "nu poti crea, esti deja in 1");
                return PLUGIN_HANDLED;
        }
        new aData[ GangInfo ];
        aData[ GangName ] = szArgs;
        aData[ NumMembers ]     = 0;
        aData[ GangMembers ]    = _:TrieCreate();
        ArrayPushArray( g_aGangs, aData );
 
        set_user_gang( iPlayer, ArraySize( g_aGangs ) - 1, STATUS_LEADER);
        client_print(iPlayer, print_chat, "ai creat %s", aData[ GangName ]);
        return PLUGIN_HANDLED;
}
 
set_user_gang( iPlayer, iGang, iStatus=STATUS_MEMBER)
{
        new aData[ GangInfo ];
        if(g_iCheck[iPlayer] > -1 )
        {
                ArrayGetArray( g_aGangs, g_iCheck[iPlayer], aData );
                TrieDeleteKey( aData[ GangMembers ], szName(iPlayer) );
                aData[ NumMembers ]--;
                ArraySetArray( g_aGangs, g_iCheck[iPlayer], aData );
                formatex(g_iGang[iPlayer], charsmax(g_iGang[]), "\0");         
                formatex(g_iRank[iPlayer], charsmax(g_iRank[]), "\0");
                client_print(iPlayer, print_chat, "%s %s", g_iGang[iPlayer], g_iRank[iPlayer]);
                       
        }
 
        if( iGang > -1 )
        {
                ArrayGetArray( g_aGangs, iGang, aData );
                TrieSetCell( aData[ GangMembers ], szName(iPlayer), iStatus );
                aData[ NumMembers ]++;
                ArraySetArray( g_aGangs, iGang, aData );
                formatex(g_iGang[iPlayer], charsmax(g_iGang[]), aData[ GangName ]);            
                formatex(g_iRank[iPlayer], charsmax(g_iRank[]), status_name[iStatus]); 
                client_print(iPlayer, print_chat, "%s %s", g_iGang[iPlayer], g_iRank[iPlayer]);
        }
       
        g_iCheck[iPlayer] = iGang;
        Save_MySql(iPlayer);
        return PLUGIN_HANDLED;
}
get_user_gang( iPlayer )
{
        new aData[ GangInfo ];
               
        for( new i = 0; i < ArraySize( g_aGangs ); i++ )
        {
                ArrayGetArray( g_aGangs, i, aData );
                       
                if( TrieKeyExists( aData[ GangMembers ], szName(iPlayer) ) )
                        return i;
        }
               
        return -1;
}
                               
getStatus( iPlayer, iGang )
{
        if( !is_user_connected( iPlayer ))
                return STATUS_NONE;
                       
        new aData[ GangInfo ];
        ArrayGetArray( g_aGangs, iGang, aData );
               
        new iStatus;
        TrieGetCell( aData[ GangMembers ], szName(iPlayer), iStatus );
               
        return iStatus;
}
public LoadGangs()
{
        new szConfigsDir[ 60 ];
        get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
        add( szConfigsDir, charsmax( szConfigsDir ), "/xjailbreak/gangs.ini" );
               
        new iFile = fopen( szConfigsDir, "rt" );
               
        new aData[ GangInfo ];
               
        new szBuffer[ 512 ], szData[ 6 ], szValue[ 6 ], i, iCurGang;
               
        while( !feof( iFile ) )
        {
                fgets( iFile, szBuffer, charsmax( szBuffer ) );
                       
                trim( szBuffer );
                remove_quotes( szBuffer );
                       
                if( !szBuffer[ 0 ] || szBuffer[ 0 ] == ';' )
                {
                        continue;
                }
                       
                if( szBuffer[ 0 ] == '[' && szBuffer[ strlen( szBuffer ) - 1 ] == ']' )
                {
                        copy( aData[ GangName ], strlen( szBuffer ) - 2, szBuffer[ 1 ] );
                        aData[ NumMembers ] = 0;
                        aData[ GangMembers ] = _:TrieCreate();
                               
                        if( TrieKeyExists( g_tGangNames, aData[ GangName ] ) )
                        {
                                new szError[ 256 ];
                                formatex( szError, charsmax( szError ), "[JB Gangs] Gang already exists: %s", aData[ GangName ] );
                                set_fail_state( szError );
                        }
                               
                        ArrayPushArray( g_aGangs, aData );
                               
                        TrieSetCell( g_tGangNames, aData[ GangName ], iCurGang );
 
                        log_amx( "Gang Created: %s", aData[ GangName ] );
                               
                        iCurGang++;
                               
                        continue;
                }
                       
                strtok( szBuffer, szData, 31, szValue, 511, '=' );
                trim( szData );
                trim( szValue );
                if( TrieGetCell( g_tGangValues, szData, i ) )
                {
                        ArrayGetArray( g_aGangs, iCurGang - 1, aData );
                               
                        switch( i )
                        {                                      
 
                                case VALUE_KILLS:
                                        aData[ GangKills ] = str_to_num( szValue );
                        }
                               
                }      
       
        }
               
        fclose( iFile );
}
 
public SaveGangs()
{
        new szConfigsDir[ 64 ];
        get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
               
        add( szConfigsDir, charsmax( szConfigsDir ), "/xjailbreak/gangs.ini" );
               
        if( file_exists( szConfigsDir ) )
                delete_file( szConfigsDir );
                       
        new iFile = fopen( szConfigsDir, "wt" );
                       
        new aData[ GangInfo ];
               
        new szBuffer[ 256 ];
 
        for( new i = 0; i < ArraySize( g_aGangs ); i++ )
        {
                ArrayGetArray( g_aGangs, i, aData );
                       
                formatex( szBuffer, charsmax( szBuffer ), "[%s]^n", aData[ GangName ] );
                fputs( iFile, szBuffer );
 
                formatex( szBuffer, charsmax( szBuffer ), "Kills=%i^n^n", aData[ GangKills ] );
                fputs( iFile, szBuffer );
                       
        }
               
        fclose( iFile );
}
/////////////////////////////////////////////////
public client_impulse( iPlayer, iImpulse ) {
        if( iImpulse != 100 )
                return PLUGIN_CONTINUE;
       
        if(!g_nCvar(cvar_flashlight))
                return PLUGIN_HANDLED;
 
        switch(g_nCvar(cvar_flashlight_vip_level))
        {
                case 1:
                {
                        if(!g_iNova[iPlayer]) return PLUGIN_HANDLED;
                }
                case 2:
                {
                        if(!g_iGold[iPlayer]) return PLUGIN_HANDLED;
                }
        }
        return PLUGIN_CONTINUE;
}
/////////////////////////////////////////////////
public Event_StatusValueShow(id)
{
        //if(g_iDay[ TOTAL_DAYS ] != DAY_NONE)
        //      return PLUGIN_HANDLED_MAIN;
 
        new iTarget = read_data(2);
        new szTeam[][] = {"", "JB_PRISONER", "JB_GUARD", ""};
        new team = get_user_team(iTarget);
        set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 10.0, 0.0, 0.0, -1);
        /*
        switch(g_iVip[iTarget])
        {
                case 0: ShowSyncHudMsg(id, g_HudSyncStatusText, "%L", id, "JB_STATUS_PLAYER", id, szTeam[team], szName(iTarget));
                case 1: ShowSyncHudMsg(id, g_HudSyncStatusText, "%L", id, "JB_STATUS_VIP_1", id, szTeam[team], szName(iTarget));
                case 2: ShowSyncHudMsg(id, g_HudSyncStatusText, "%L", id, "JB_STATUS_VIP_2", id, szTeam[team], szName(iTarget));
 
        }*/
        ShowSyncHudMsg(id, g_HudSyncStatusText, "%L", id, "JB_STATUS_PLAYER", id, szTeam[team], szName(iTarget));
        return PLUGIN_HANDLED;
}
 
public Event_StatusValueHide(iPlayer)
{
        ClearSyncHud(iPlayer, g_HudSyncStatusText);
}
public Event_Health( iPlayer )
{
        if(g_bHealth[iPlayer])
                ShowHealth( iPlayer );
}
public Event_Money(iPlayer)
        if(is_user_connected(iPlayer) && IsPlayer(iPlayer))
                if(g_nCvar(cvar_moneypoint) == 1)
                        cs_set_user_money(iPlayer, g_iPoints[iPlayer], 1);
 
public Event_Spray()
{
        if(g_nCvar(cvar_sprayenable) != 1)
                return;
 
        static iPlayer;
        iPlayer = read_data(2);
 
        if(!is_user_connected(iPlayer) && !is_user_alive(iPlayer))
                return;
               
        static iOrigin[3];
        iOrigin[0] = read_data(3);
        iOrigin[1] = read_data(4);
        iOrigin[2] = read_data(5);
       
        static Float:vecOrigin[3];
        IVecFVec(iOrigin, vecOrigin);
       
        static Float:vecDirection[3];
        velocity_by_aim(iPlayer, 5, vecDirection);
       
        static Float:vecStop[3];
        xs_vec_add(vecOrigin, vecDirection, vecStop);
        xs_vec_mul_scalar(vecDirection, -1.0, vecDirection);
       
        static Float:vecStart[3];
        xs_vec_add(vecOrigin, vecDirection, vecStart);
        engfunc(EngFunc_TraceLine, vecStart, vecStop, IGNORE_MONSTERS, -1, 0);
        get_tr2(0, TR_vecPlaneNormal, vecDirection);
        vecDirection[2] = 0.0;
        xs_vec_normalize(vecDirection, vecDirection);
        xs_vec_mul_scalar(vecDirection, 5.0, vecDirection);
        xs_vec_add(vecOrigin, vecDirection, vecStart);
        xs_vec_copy(vecStart, vecStop);
        vecStop[2] -= 9999.0;
        engfunc(EngFunc_TraceLine, vecStart, vecStop, IGNORE_MONSTERS, -1, 0);
        get_tr2(0, TR_vecEndPos, vecStop);
       
        if(iPlayer > 0)
                client_print_color(0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_SPRAY", '^3', szName(iPlayer), '^1', '^4', (vecStart[2] - vecStop[2]), '^1', '^4', '^1');
 
}
public Event_RoundStart()
{
        g_bCanBuy = true;
        reset_players();
        reset_sall();
}
public reset_players()
{
        static iPlayers[32], iNum, i, iPlayer;
        get_players( iPlayers, iNum, "ac");
 
        for( i=0; i<iNum; i++ )
        {
                iPlayer = iPlayers[i];
                displayInfo(iPlayer);
        }
}
public reset_sall()
{
        if(g_sHealth > 0)
                g_sHealth = 0;
 
        if(g_sDrugs > 0)
                g_sDrugs = 0;
 
        if(g_sFlashBang > 0)
                g_sFlashBang = 0;
 
        if(g_sCellKey > 0)
                g_sCellKey = 0;
 
        if(g_sGunGamble > 0)
                g_sGunGamble = 0;
 
        if(g_sDisguise > 0)
                g_sDisguise = 0;
 
        if(g_sFreeday > 0)
                g_sFreeday = 0;
 
        if(g_sCrowbar > 0)
                g_sCrowbar = 0;
 
        if(g_sBanana > 0)
                g_sBanana = 0;
 
        if(g_sNail > 0)
                g_sNail = 0;
 
        if(g_sPipe  > 0)
                g_sPipe = 0;
 
        if(g_sUsp  > 0)
                g_sUsp = 0;
 
        if(g_sGlock  > 0)
                g_sGlock = 0;
 
        if(g_sInvest  > 0)
                g_sInvest = 0;
}
public Event_RoundEnd()
{
        if(g_iRoundSoundSize)
        {
                new aDataRoundSound[DATA_ROUND_SOUND], iTrack = random_num(0, g_iRoundSoundSize - 1);
                ArrayGetArray(g_aDataRoundSound, iTrack, aDataRoundSound);
                client_cmd(0, "mp3 play sound/xjailbreak/round_sound/%s.mp3", aDataRoundSound[FILE_NAME]);
                client_print_color(0, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_ROUND_SOUND", '^3', '^1', '^4', aDataRoundSound[TRACK_NAME], '^1');
 
        }
}
//////////////////////////////////////////////////
public ClCmd_Say(iPlayer)
{
        static Said[192];
 
        read_argv(1, Said, sizeof(Said) - 1);
 
        if(equal(Said, "!", 1))
                return PLUGIN_HANDLED;
       
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        if(g_iMute[iPlayer] && Said[0] != '!')
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_CHAT", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
}
 
public ClCmd_Drop(iPlayer)
{
        if(g_bIsUserSprinting[iPlayer])
                return PLUGIN_HANDLED;
 
        if (get_bit(g_bHasCrowbar,iPlayer) && (get_user_weapon(iPlayer) == CSW_KNIFE))
        {
                clear_bit(g_bHasCrowbar, iPlayer);
                cs_reset_user_weapon(iPlayer);
                spawn_crowbar(iPlayer);
                return PLUGIN_HANDLED;
        }
        return PLUGIN_CONTINUE;
}
public spawn_crowbar(const id)
{
        new iEntity;
        new Float:where[3];
       
        iEntity = create_entity("info_target");
        set_pev(iEntity, pev_classname, g_szClassNameCrowbar);
        set_pev(iEntity, pev_solid, SOLID_TRIGGER);
        set_pev(iEntity, pev_movetype, MOVETYPE_BOUNCE);
        entity_set_model(iEntity, CrowbarModels[0]);
        pev(id, pev_origin, where);
        where[2] += 50.0;
        where[0] += random_float(-20.0, 20.0);
        where[1] += random_float(-20.0, 20.0);
        entity_set_origin(iEntity, where);
        where[0] = 0.0;
        where[2] = 0.0;
        where[1] = random_float(0.0, 180.0);
        entity_set_vector(iEntity, EV_VEC_angles, where);
        velocity_by_aim(id, 200, where);
        entity_set_vector(iEntity, EV_VEC_velocity, where);
       
       
        return PLUGIN_HANDLED;
}
public CrowbarTouch(const id, const world)     
{
        new Float:velocity[3];
        new Float:volume;
        entity_get_vector(id, EV_VEC_velocity, velocity);
       
        velocity[0] = (velocity[0] * 0.45);
        velocity[1] = (velocity[1] * 0.45);
        velocity[2] = (velocity[2] * 0.45);
        entity_set_vector(id, EV_VEC_velocity, velocity);
        volume = get_speed(id) * 0.005;
        if (volume > 1.0) volume = 1.0;
        if (volume > 0.1) emit_sound(id, CHAN_AUTO, "debris/metal2.wav", volume, ATTN_NORM, 0, PITCH_NORM);
        return PLUGIN_CONTINUE;
}
public Fwd_PlayerCrowbarTouch(const iEntity, const id)
{
        if(!IsPlayer(id))
                return HAM_IGNORED;
 
        if( is_user_alive(id) && get_user_team(id) == 1 && !get_bit(g_bHasCrowbar, id))
        {
                set_bit(g_bHasCrowbar, id);
                remove_entity(iEntity);
                if (get_user_weapon(id) == CSW_KNIFE)
                {
                        cs_reset_user_weapon(id);
                }
                emit_sound(id, CHAN_AUTO, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
        }
        return HAM_IGNORED;
}
/////////////////////////////////////////////////
public ClCmd_ChooseTeam( iPlayer ) {
        ShowMainMenu( iPlayer );
       
        if( g_bPluginCommand )
                return PLUGIN_CONTINUE;
       
       
        return PLUGIN_HANDLED;
}
 
public ShowMainMenu( iPlayer ) {
        if(!g_iTempLogin[iPlayer] && g_iRegister[iPlayer])
        {
                client_print_color( iPlayer, print_team_default, "^4%s %L", g_sCvar(cvar_prefix), LANG_SERVER, "JB_NO_LOGIN", '^3', szName(iPlayer), '^1', '^4', '^1');
                return PLUGIN_HANDLED;
        }
        static menuMainMenu;
       
        if( !menuMainMenu )
        {
                new strMenuTitle[ 64 ];
                formatex( strMenuTitle, 63, "JailBreak Main Menu:");
               
                menuMainMenu = menu_create( strMenuTitle, "Handle_MainMenu" );
               
                new strOptionsMainMenu[ ][ ] = {
                        "\rChange Team^n",
                        "%L", LANG_SERVER, "JB_OPENCELLS",
                        "\wTest 2",
                        "\wTest 3^n",
                };
               
                new strNum[ 8 ];
               
                for( new i = 0; i < sizeof( strOptionsMainMenu ); i++ )
                {
                        num_to_str( i, strNum, 7 );
                       
                        menu_additem( menuMainMenu, strOptionsMainMenu[ i ], strNum );
                }
               
                menu_setprop( menuMainMenu, MPROP_NUMBER_COLOR, "\y" );
        }
       
        menu_display( iPlayer, menuMainMenu, 0 );
        return PLUGIN_CONTINUE;
}
 
public Handle_MainMenu( iPlayer, iMenu, iKey ) {
        if( iKey == MENU_EXIT )
                return;
       
       
        new strOption[ 8 ], iAccess, iCallBack;
        menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
       
        new iOption = str_to_num( strOption );
       
        switch( iOption )
        {
                case 0:
                {
                        if( g_iBan[iPlayer] ) {
                                client_print_color( iPlayer, print_team_blue, "You have been banned from joining the ^3Counter-Terrorist^1 team. Appeal your ban on our forums." );
                        }
                        else
                        {
                                new iPlayers[ 32 ], iNumCT, iNumT;
                                get_players( iPlayers, iNumCT, "e", "CT" );
                                get_players( iPlayers, iNumT, "e", "TERRORIST" );
                               
                                if( cs_get_user_team( iPlayer ) == CS_TEAM_T && ( ( ++iNumT / ++iNumCT ) < g_nCvar(cvar_team_ratio) ) && iNumCT > 1 )
                                {
                                        client_print_color( iPlayer, print_team_blue, "You cannot change teams since the ratio does not support that ^4(T:%i | CT:%i)^1.", iNumT, iNumCT );
                                }
                                else
                                {
                                        new iMinimumTime = g_nCvar(cvar_time_ct) * 60;
                                       
                                        switch( cs_get_user_team( iPlayer ) )
                                        {
                                                case CS_TEAM_T:
                                                {
                                                        if( g_iPlayerTime[ iPlayer ] < iMinimumTime && !is_user_admin( iPlayer ) )
                                                        {
                                                                client_print_color( iPlayer, print_team_red, "You need at least ^3%d minutes^1 of played time to go to the CT team.",  iMinimumTime ); 
                                                                return;
                                                        }
                                                        else
                                                        {
                                                                client_print_color( iPlayer, print_team_blue, "By playing as a ^3Guard^1 you automatically agree to the rules of this server. You have been warned!");
                                                                cs_set_user_team( iPlayer, CS_TEAM_CT, CS_CT_GSG9 );
                                                        }
                                                       
                                                }
                                                       
                                                default:
                                                {
                                                        cs_set_user_team( iPlayer, CS_TEAM_T, CS_T_LEET );
                                                }
                                        }
                                       
                                        if( is_user_alive(iPlayer) )
                                                user_kill( iPlayer );
                                       
                                }
                        }
                }
                default: return;
        }
}
public MsgStatusText()
        return PLUGIN_HANDLED;
 
writeStatusMessage(iPlayer, const message[64])
{
        if ( !is_user_connected(iPlayer) || is_user_bot(iPlayer) ) return;
 
        message_begin(MSG_ONE_UNRELIABLE, g_iStatusText, _, iPlayer);
        write_byte(0);
        write_string(message);
        message_end();
}
displayInfo(iPlayer)
{
        if(!is_user_connected(iPlayer) || !is_user_alive(iPlayer)) return;
 
        new message[64];
        if(g_bDisplayFix[iPlayer])     
                formatex(message, charsmax(message), "%L", LANG_SERVER, "JB_STATS_DISPLAY_M1");
        else if(g_iLevel[iPlayer] < MaxLevels)
                formatex(message, charsmax(message), "%L", LANG_SERVER, "JB_STATS_DISPLAY_M2", g_iLevel[iPlayer], MaxLevels, g_iExp[iPlayer], Levels[g_iLevel[iPlayer]], g_iPoints[iPlayer], g_iDrugs[iPlayer], g_iMoneys[iPlayer]);
        else
                formatex(message, charsmax(message), "%L", LANG_SERVER, "JB_STATS_DISPLAY_M3", g_iLevel[iPlayer], MaxLevels, g_iPoints[iPlayer], g_iDrugs[iPlayer], g_iMoneys[iPlayer]);       
        writeStatusMessage(iPlayer, message);
 
}
 
public MsgMoney(msgid, dest, id)
{
        if(g_nCvar(cvar_moneypoint) == 1)
        {
                set_pdata_int(id, OFFSET_CSMONEY, 0);
                set_msg_arg_int(1, ARG_LONG, 0);
        }
}
public MsgStatusIcon(const iMsgId, const iMsgDest, const iPlayer)
{
        new strIcon[ 5 ];
        get_msg_arg_string( 2, strIcon, 4 );
       
        if( strIcon[ 0 ] == 'b' && strIcon[ 2 ] == 'y' && strIcon[ 3 ] == 'z' )
        {
                if( get_msg_arg_int( 1 ) )
                {
                        set_pdata_int( iPlayer, 235, get_pdata_int( iPlayer, 235, 5 ) & ~( 1<<0 ), 5 );
                        return PLUGIN_HANDLED;
                }
        }
       
        return PLUGIN_CONTINUE;
}
public MsgShowMenu( iMessageID, iDestination, iPlayer )
{
        static strMenuCode[ g_iJoinMsgLen ];
        get_msg_arg_string( 4, strMenuCode, g_iJoinMsgLen - 1 );
       
        set_pdata_int( iPlayer, 125, get_pdata_int( iPlayer, 125, 5 ) & ~ ( 1<<8 ), 5 );
       
        if( equal( strMenuCode, FIRST_JOIN_MSG ) || equal( strMenuCode, FIRST_JOIN_MSG_SPEC ) )
        {
                if( is_user_connected(iPlayer) && !task_exists( TASK_TEAMJOIN + iPlayer ) )
                {
                        static iParameters[ 2 ];
                        iParameters[ 0 ] = iMessageID;
                        clear_bit(g_bIsFirstConnected, iPlayer);
                        set_task(0.1, "Task_TeamJoin", TASK_TEAMJOIN + iPlayer, iParameters, 1);
                        iParameters[0] = iPlayer;
                        set_task(2.5, "Task_NotifyMenu", _, iParameters, 1 );
                        return PLUGIN_HANDLED;
                }
        }
        else if( equal( strMenuCode, INGAME_JOIN_MSG ) || equal( strMenuCode, INGAME_JOIN_MSG_SPEC ) )
        {
                set_task( 0.1, "ShowMainMenu", iPlayer );
                return PLUGIN_HANDLED;
        }
       
        return PLUGIN_CONTINUE;
}
 
public MsgVGUIMenu( iMessageID, iDestination, iPlayer ) {
       
        set_pdata_int( iPlayer, 125, get_pdata_int( iPlayer, 125, 5 ) & ~ ( 1<<8 ), 5 );
       
        if( get_msg_arg_int( 1 ) != 2 )
                return PLUGIN_CONTINUE;
       
        if( is_user_connected(iPlayer) && !task_exists( TASK_TEAMJOIN + iPlayer ) )
        {
                if( get_bit( g_bIsFirstConnected, iPlayer ))
                {
                        clear_bit(g_bIsFirstConnected, iPlayer);
                        static iParameters[2];
                        iParameters[ 0 ] = iMessageID;
                        set_task( 0.1, "Task_TeamJoin", TASK_TEAMJOIN + iPlayer, iParameters, 1 );
                       
                        iParameters[ 0 ] = iPlayer;
                        set_task( 2.5, "Task_NotifyMenu", _, iParameters, 1 );
                        return PLUGIN_HANDLED; 
                }
                else
                {
                        set_task( 0.1, "ShowMainMenu", iPlayer );
                        return PLUGIN_HANDLED;
                }
        }
       
        return PLUGIN_CONTINUE;
}
 
public Task_TeamJoin( iParameters[ ], iTask ) {
        new iPlayer = iTask - TASK_TEAMJOIN;
        new iMessage = iParameters[ 0 ];
        new iMessageBlock = get_msg_block( iMessage );
        set_msg_block( iMessage, BLOCK_SET );
       
        static strTeam[2];
       
        switch( cs_get_user_team( iPlayer ) ) {
                case CS_TEAM_T:         strTeam = "2";
                case CS_TEAM_CT:        strTeam = "1";
                default:                strTeam = TEAMJOIN_TEAM;
        }
       
        g_bPluginCommand = true;
       
        engclient_cmd( iPlayer, "jointeam", strTeam );
        engclient_cmd( iPlayer, "joinclass", TEAMJOIN_CLASS );
       
        g_bPluginCommand = false;
       
        set_msg_block( iMessage, iMessageBlock );
}
 
 
public Task_NotifyMenu( iParameters[ ] ) {
        client_print_color( iParameters[ 0 ], print_team_default, "Press the ^3team menu^1 button ^4(default M)^1 to open the ^4Main Menu^1.");
}
 
 
public client_putinserver(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if(get_user_flags(iPlayer) & read_flags(g_sCvar(cvar_blockvoice_level)))
                fm_set_speak(iPlayer, SPEAK_ALL);
        else
                fm_set_speak(iPlayer, SPEAK_MUTED);
 
        set_bit(g_bIsFirstConnected, iPlayer); 
        g_iJoinTime[iPlayer] = get_systime();
        g_iAuth[iPlayer] = true;
        Load_MySql(iPlayer);
        g_iCheck[iPlayer] = get_user_gang(iPlayer);
        g_bDisplayFix[iPlayer] = true;
        return PLUGIN_CONTINUE;
}
/*public client_connect(iPlayer)
{
        g_iAuth[iPlayer] = true;
        Load_MySql(iPlayer);
}*/
public client_disconnect(iPlayer)
{
        if(!is_user_connected(iPlayer))
                return PLUGIN_HANDLED;
 
        if(get_bit(g_bIsSimon, iPlayer))
                ResetSimon(iPlayer);
       
        Save_MySql(iPlayer);
        reset_disconnect(iPlayer);
 
        return PLUGIN_CONTINUE;
}
 
reset_disconnect(iPlayer)
{
        if(g_iPlayerTime[iPlayer])
                g_iPlayerTime[iPlayer]  = 0;
       
        if(g_iPoints[iPlayer])
                g_iPoints[iPlayer]  = 0;
 
        if(g_iDrugs[iPlayer])
                g_iDrugs[iPlayer]  = 0;
 
        if(g_iMoneys[iPlayer])
                g_iMoneys[iPlayer]  = 0;
 
        if(g_iBan[iPlayer])
                g_iBan[iPlayer]  = 0;
 
        if(g_iBanTime[iPlayer])
                g_iBanTime[iPlayer]  = 0;
 
        if(g_iMute[iPlayer])
                g_iMute[iPlayer]  = 0;
 
        if(g_iMuteTime[iPlayer])
                g_iMuteTime[iPlayer]  = 0;
 
        if(g_iNova[iPlayer])
                g_iNova[iPlayer]  = 0;
 
        if(g_iGold[iPlayer])
                g_iGold[iPlayer]  = 0;
 
        if(g_iGoldTime[iPlayer])
                g_iGoldTime[iPlayer]  = 0;
       
        if(g_iJoinTime[iPlayer])
                g_iJoinTime[iPlayer] = 0;
 
        if(g_iRegister[iPlayer])
                g_iRegister[iPlayer] = 0;
 
        if(g_iAttempt[iPlayer])
                g_iAttempt[iPlayer] = 0;
 
        if(g_iLevel[iPlayer])
                g_iLevel[iPlayer] = 0;
 
        if(g_iExp[iPlayer])
                g_iExp[iPlayer] = 0;
 
        if(g_iTempLogin[iPlayer])
                g_iTempLogin[iPlayer] = 0;
 
        if(g_bDisplayFix[iPlayer])
                g_bDisplayFix[iPlayer] = false;
 
        if(g_iAuth[iPlayer])
                g_iAuth[iPlayer] = false;
 
        if(get_bit(g_bHasMenuOpen, iPlayer))
                clear_bit(g_bHasMenuOpen, iPlayer);
 
        if(g_eUserCostumes[iPlayer][COSTUMES])
                jb_set_user_costumes(iPlayer, 0);
 
        g_iCheck[iPlayer] = -1;
        formatex(g_iPassword[iPlayer], charsmax(g_iPassword[]), "'\0'");
        formatex(g_iTempPassword[iPlayer], charsmax(g_iTempPassword[]), "'\0'");
        formatex(g_iBanReason[iPlayer], charsmax(g_iBanReason[]), "'\0'");
        formatex(g_iBanName[iPlayer], charsmax(g_iBanName[]), "'\0'");
        formatex(g_iMuteReason[iPlayer], charsmax(g_iMuteReason[]), "'\0'");
        formatex(g_iMuteName[iPlayer], charsmax(g_iMuteName[]), "'\0'");
        formatex(g_iGang[iPlayer], charsmax(g_iGang[]), "'\0'");
        formatex(g_iRank[iPlayer], charsmax(g_iRank[]), "'\0'");
       
        g_bLoaded[iPlayer][0] = g_bLoaded[iPlayer][1] = g_bLoaded[iPlayer][2] = g_bLoaded[iPlayer][3] = g_bLoaded[iPlayer][4]
        = g_bLoaded[iPlayer][5] = g_bLoaded[iPlayer][6] = g_bLoaded[iPlayer][7] = g_bLoaded[iPlayer][8] = false;
}
public ResetSimon(iPlayer) {
        if (!task_exists(iPlayer+TASK_SIMONBEAM))
                remove_task(iPlayer+TASK_SIMONBEAM);
 
        clear_bit(g_bIsSimon, iPlayer);
 
}
public Task_SimonStartRing(iPlayer)
{
        iPlayer -= TASK_SIMONBEAM;
       
        if (!is_user_connected(iPlayer) || !is_user_alive(iPlayer) || !get_bit(g_bIsSimon, iPlayer))
        {
                remove_task(iPlayer+TASK_SIMONBEAM);
                return;
        }
        fnSetSimonRing(iPlayer);
}
fnSetSimonRing(id) {
        /* Teh beam cylinder !!! */
        new Float:flOrigin[3], iOrigin[3];
        pev(id, pev_origin, flOrigin);
        FVecIVec(flOrigin, iOrigin);
        // Beam Color
        new Beam = GetPlayerHullSize(id);
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iOrigin);
        write_byte(TE_BEAMCYLINDER);
        write_coord(iOrigin[0]);
        write_coord(iOrigin[1]);
        if(Beam == HULL_HEAD)
                write_coord(iOrigin[2]-16);
        else write_coord(iOrigin[2]-33);
        write_coord(iOrigin[0]);
        write_coord(iOrigin[1]);
        write_coord(iOrigin[2] + 200);
        write_short(g_iRingSprite);             // Sprite Index
        write_byte(0);                          // Start Frame
        write_byte(0);                          // Frame Rate
        write_byte(5);                          // Life
        write_byte(25);                         // Width
        write_byte(0);                          // Noise
        write_byte(255);//r
        write_byte(random_num(0,255));//g
        write_byte(255);//b
        write_byte(200);                        // Brightness
        write_byte(0);                          // Speed
        message_end();
 
}
/////////////////////////////////////////////////
enum Commands
{
        say,
        sayteam
};
       
new const say_commands[Commands][] = {
        "say !%s",
        "say_team !%s"
};
stock rd_register_saycmd(const saycommand[], const function[], flags) {
        static temp[64];
        for (new Commands:i = say; i < Commands; i++)
        {
                format(temp, 63, say_commands[i], saycommand);
                register_clcmd(temp, function, flags);
        }
}
cs_reset_user_weapon(iPlayer)
{
        new iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, XO_PLAYER);
        if(pev_valid(iWeapon))
                ExecuteHamB(Ham_Item_Deploy, iWeapon);
}
       
StripPlayerWeapons(iPlayer)
{
        if(!is_user_alive(iPlayer))
                return;
 
        strip_user_weapons(iPlayer);
        set_pdata_int(iPlayer, 116, 0);
        give_item(iPlayer, "weapon_knife");
}
fnGetTerrorists() {
        /* Get's the number of terrorists */
        static iPlayers[32], iNum;
        get_players(iPlayers, iNum, "ae", "TERRORIST");
        return iNum;
}
 
fnGetCounterTerrorists() {
        /* Get's the number of counter-terrorists */
        static iPlayers[32], iNum;
        get_players(iPlayers, iNum, "ae", "CT");
        return iNum;
}
 
fnGetSimons() {
        static iPlayers[32], iNum, i, iPlayer, Simons;
        Simons = 0;
        get_players(iPlayers, iNum, "ae", "CT");
        for( i=0; i<iNum; i++ ) {
                iPlayer = iPlayers[i];
                if(get_bit(g_bIsSimon, iPlayer))
                        Simons++;
        }
        return Simons;
}
szName(iPlayer)
{
        new sz_Name[MAX_PLAYERS + 1];
        get_user_name(iPlayer, sz_Name, charsmax(sz_Name));
        return sz_Name;
}
/*szAuth(iPlayer)
{
        new sz_Auth[MAX_PLAYERS + 1];
        get_user_authid(iPlayer, sz_Auth, charsmax(sz_Auth));
        return sz_Auth;
}
*/
szMap()
{
        new sz_Map[MAX_PLAYERS + 1];
        get_mapname(sz_Map, charsmax(sz_Map));
        return sz_Map;
}
g_sCvar( cvar )
{
        new sCvar[ 15 ];
        get_pcvar_string(cvar_pointer[ cvar ], sCvar, charsmax( sCvar ));
        return sCvar;
}
g_nCvar( cvar )
{
        static nCvar;
        nCvar = get_pcvar_num(cvar_pointer[ cvar ]);
        return nCvar;
}
 
Float:g_fCvar( cvar )
{
        static Float:fCvar;
        fCvar = get_pcvar_float(cvar_pointer[cvar]);
        return fCvar;
}