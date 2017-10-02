/*
* DeathRunTimer
*
* Site : http://amxx.pl/deathrun-timer-save-records-t31649.html
* Author : Knopers
*/
#include <amxmodx>
#include <engine>
#include <hamsandwich>
 
#define _CustomButtons
 
#include "timer/buttons.inl"
 
#define RecordsSaveTo 1 // 1 - Nvault, 2 - MySQL (Standardowo linijka 10)
 
#define TaskID 3456
#define DeadID 3356
new sMap[35];
new HudObj, StatusText, TimerType = 2;
new TimerS[33] = 0;
new iBest, sBest[64] = "";
new g_iMaxPlayers;
 
#if RecordsSaveTo == 1
#include "timer/nvault.inl" // -= Nvault =-
#else
#if RecordsSaveTo == 2
#include "timer/mysql.inl" // -= MySQL =-
#endif
#endif
 
public plugin_init()
{
register_plugin("DeathRun Timer + Save Record", "2.1", "Knopers");//Edited by Owner (Owner123);
get_mapname(sMap, 34);
 
RegisterHam(Ham_Spawn, "player", "EvSpawn", 1);
RegisterHam(Ham_Killed, "player", "EvPlayerKilled", 1);
register_logevent("eventResetTime", 2, "1=Round_Start");
 
register_concmd("say /record", "ShowBest");
 
register_cvar("amx_timer_type", "2"); // 1 - Hud, 2 - Status
 
HudObj = CreateHudSyncObj();
StatusText = get_user_msgid("StatusText");
 
//
// Buttons
//
register_concmd("say /drtimermenu", "ShowMenu");
RegisterHam(Ham_Use, "func_button", "EvUse", 0);
entButton = engfunc(EngFunc_AllocString, "func_button");
readButtons();
 
#if defined _Timer_Save2Nvault
h_vault = nvault_open("dr_records");
LoadRecord();
#else
#if defined _Timer_Save2SQL
register_cvar("timer_sql_host","127.0.0.1",FCVAR_PROTECTED)
register_cvar("timer_sql_user","root",FCVAR_PROTECTED)
register_cvar("timer_sql_pass","password",FCVAR_PROTECTED)
register_cvar("timer_sql_database","baza123",FCVAR_PROTECTED)
 
ConnectSql();
//server_print("Loading Record ... [Step 1/4]"); //ForDebug
set_task(10.0, "CheckRecord");
#endif
#endif
 
g_iMaxPlayers = get_maxplayers();
}
public plugin_precache()
{
#if defined _CustomButtons
precache_model(gszButtonModels[0]);
precache_model(gszButtonModels[1]);
#else
engfunc(EngFunc_PrecacheModel, "models/w_c4.mdl");
#endif
}
public plugin_end()
{
#if defined _Timer_Save2Nvault
nvault_close(h_vault);
#else
#if defined _Timer_Save2SQL
SQL_FreeHandle(SQL_TUPLE);
#endif
#endif
}
public client_disconnect(id)
{
if(task_exists(id + TaskID))
remove_task(id + TaskID);
if(task_exists(id + DeadID))
remove_task(id + DeadID);
}
public EvSpawn(id)
{
TimerS[id] = 0;
if(task_exists(TaskID + id))
remove_task(TaskID + id);
if(task_exists(id + DeadID))
remove_task(id + DeadID);
if(get_user_team(id) == 2 && iOption[0])
Start(id);
}
public EvPlayerKilled(iVictim, iAttacker)
{
if(task_exists(TaskID + iVictim))
remove_task(TaskID + iVictim);
set_task(1.0, "DeadTask", iVictim + DeadID, _, _, "b");
if(get_user_team(iVictim) == 1 && get_user_team(iAttacker) == 2 && !iOption[1])
Finish(iAttacker, iVictim);
}
public Start(id)
{
TimerS[id] = 0;
if(get_user_team(id) == 2)
{
if(task_exists(id + TaskID))
remove_task(id + TaskID);
fnShowTimer(id + TaskID);
set_task(1.0, "fnShowTimer", id + TaskID, _, _, "b");
}
}
public Finish(id, idTT)
{
if(TimerS[id] <= 10 || !task_exists(TaskID + id))
return PLUGIN_CONTINUE;
 
if(idTT > 0 && idTT < 33 && !iOption[1])
{
remove_task(TaskID + id);
new svName[32], skName[32];
get_user_name(idTT, svName, 31);
get_user_name(id, skName, 31);
new sMsg[128];
format(sMsg, 127, "^x04Jucatorul ^x03%s ^x04a terminat mapa ^x03%02d:%02d ", skName, TimerS[id] / 60, TimerS[id] % 60, svName);
ColorChat(0, sMsg);
if(TimerS[id] < iBest || iBest < 1)
{
iBest = TimerS[id];
sBest = skName;
 
format(sMsg, 127, "^x04Jucatorul ^x03%s ^x04 a stabilit un nou record pe mapa ^x03%02d:%02d", skName, TimerS[id] / 60, TimerS[id] % 60);
ColorChat(0, sMsg);
 
#if defined _Timer_Save2Nvault
replace_all(sBest, 63, "^"", "''");
SaveRecord();
#else
#if defined _Timer_Save2SQL
//ColorChat(0, "^x04 Asteptati ... Se salveaza ... [Step 1/4]"); //ForDebug
replace_all(sBest, 63, "'", "\'");
replace_all(sBest, 63, "`", "\`");
//ColorChat(0, "^x04 Asteptati ... Se salveaza ... [Step 2/4]"); //ForDebug
Save2SQL();
#endif
#endif
}
else
{
format(sMsg, 127, "^x04Jucatorul ^x03%s ^x04nu a batut recordul. Recordul curent este: ^x03%02d:%02d", skName, iBest / 60, iBest % 60);
ColorChat(0, sMsg);
}
}
else
{
remove_task(TaskID + id);
new sName[32];
get_user_name(id, sName, 31);
new sMsg[128];
format(sMsg, 127, "^x04Jucatorul ^x03%s ^x04A terminat mapa in: ^x03%02d:%02d", sName, TimerS[id] / 60, TimerS[id] % 60);
ColorChat(0, sMsg);
if(TimerS[id] < iBest || iBest < 1)
{
iBest = TimerS[id];
sBest = sName;
 
format(sMsg, 127, "^x04Jucatorul ^x03%s ^x04 a stabilit un nou record: ^x03%02d:%02d ", sName, TimerS[id] / 60, TimerS[id] % 60);
ColorChat(0, sMsg);
 
#if defined _Timer_Save2Nvault
replace_all(sBest, 63, "^"", "''");
SaveRecord();
#else
#if defined _Timer_Save2SQL
//ColorChat(0, "^x04 Asteptati ... Se salveaza ... [Step 1/4]"); //ForDebug
replace_all(sBest, 63, "'", "\'");
replace_all(sBest, 63, "`", "\`");
//ColorChat(0, "^x04 Asteptati ... Se salveaza ... [Step 2/4]"); //ForDebug
Save2SQL();
#endif
#endif
}
else
{
format(sMsg, 127, "^x04Jucatorul ^x03%s ^x04nu a batut recordul. Recordul curent este: ^x03%02d:%02d", sName, iBest / 60, iBest % 60);
ColorChat(0, sMsg);
}
}
TimerType = get_cvar_num("amx_timer_type");
return PLUGIN_CONTINUE;
}
public fnShowTimer(idTask)
{
new id = idTask - TaskID;
TimerS[id] ++;
if(TimerType == 1)
{
set_hudmessage(255, 255, 255, 0.1, 0.9, 2, 0.05, 1000.0, 0.1, 3.0, -1);
ShowSyncHudMsg(id, HudObj, "Timer: %02d:%02d", TimerS[id] / 60, TimerS[id] % 60);
}
else
{
new sSMsg[32];
format(sSMsg, 31, "Timer: %02d:%02d", TimerS[id] / 60, TimerS[id] % 60);
message_begin(MSG_ONE, StatusText, {0,0,0}, id);
write_byte(0);
write_string(sSMsg);
message_end();
}
}
 
public eventResetTime()
{
for(new id = 1; id < g_iMaxPlayers; id++)
{
if(!is_user_connected(id) || !is_user_alive(id))
continue;
 
if(!task_exists(id + TaskID))
continue;
 
remove_task(id + TaskID);
TimerS[id] = 0;
set_task(1.0, "fnShowTimer", id + TaskID, _, _, "b");
}
}
 
public ShowBest(id)
{
new sMsg[128];
 
if(!sBest[0])
format(sMsg, 127, "^4Nimeni nu a terminat inca aceasta harta.");
else
format(sMsg, 127, "^x04Recordul mapei : ^x03%s ^x01-- ^x04%02d:%02d", sBest, iBest / 60, iBest % 60);
 
#if defined _Timer_Save2SQL
if(!g_bRecordLoaded)
format(sMsg, 127, "^4Loading, please wait...");
#endif
 
ColorChat(0, sMsg);
}
stock ColorChat(id, sMessage[])
{
new SayText = get_user_msgid("SayText");
if(id == 0)
{
for(new i = 1; i < 33; i++)
{
if(is_user_connected(i))
{
message_begin(MSG_ONE, SayText, { 0, 0, 0 }, i);
write_byte(i);
write_string(sMessage);
message_end();
}
}
}
else
{
message_begin(MSG_ONE, SayText, { 0, 0, 0 }, id);
write_byte(id);
write_string(sMessage);
message_end();
}
}
public DeadTask(Spect)
{
Spect -= DeadID;
if(!is_user_connected(Spect) || is_user_alive(Spect))
{
remove_task(Spect + DeadID);
return PLUGIN_CONTINUE;
}
new id = entity_get_int(Spect, EV_INT_iuser2);
if(id <= 0 || id >= 33 || !is_user_alive(id))
return PLUGIN_CONTINUE;
new Name[32];
get_user_name(id, Name, 31);
 
set_hudmessage(255, 255, 255, -1.0, 0.2, 2, 0.05, 1.0, 0.1, 3.0, -1);
ShowSyncHudMsg(Spect, HudObj, "Jucatorul: %s ^nTimpul jucatorului: %02d:%02d", Name, TimerS[id] / 60, TimerS[id] % 60);
 
return PLUGIN_CONTINUE;
}
