/*
* Buttons Include for DeathRunTimer
* buttons.inl (C) by Knopers
*
* Site : http://amxx.pl/deathrun-timer-save-records-t31649.html
* Author : Knopers
*/
 
#include <amxmisc>
#include <fakemeta>
#include <xs>
 
new iOption[2] = {0, 0}; //0 - Wylaczony, 1 - wlaczony
new Float:ButtonsOrigin[2][3] = {{0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}};
new Button[2] = {0, 0};
new entButton;
 
#if defined _CustomButtons
new gszButtonModels[2][] = {
        "models/drtimer/button_start.mdl",
        "models/drtimer/button_end.mdl"
};
#endif
 
public EvUse(ent, id)
{
        if(!ent || id > 32)
                return HAM_IGNORED;
        if(!is_user_alive(id))
                return HAM_IGNORED;
       
        new target[33];
        pev(ent, pev_target, target, sizeof target - 1)
 
        if(equali(target, "timer_start") && iOption[0] && get_user_team(id) == 2)
                Start(id);
        else if(equali(target, "timer_end") && iOption[1] && get_user_team(id) == 2)
                Finish(id, 0);
        return HAM_IGNORED;
}
public ShowMenu(id)
{
        if(!(get_user_flags(id) & ADMIN_CFG))
        {
                ColorChat(id, "^x04Nemate pravo da koristite komandu");
                return PLUGIN_HANDLED;
        }
        new menu = menu_create("Deathrun Timer Menu", "menu_handler");
        new OnOff[32];
        menu_additem(menu, "Postavi start dugme", "");
        format(OnOff, 31, "Dugme Ukljuceno [%d]", iOption[0]);
        menu_additem(menu, OnOff, "");
        menu_additem(menu, "", "");
        menu_additem(menu, "Postavi zavrsno dugme", "");
        format(OnOff, 31, "Dugme Ukljuceno [%d]", iOption[1]);
        menu_additem(menu, OnOff, "");
        menu_additem(menu, "", "");
        menu_additem(menu, "Sacuvaj", "");
        menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
        menu_display(id, menu, 0);
        return PLUGIN_HANDLED;
}
 
public menu_handler(id, menu, item)
{
        if (item == MENU_EXIT)
        {
                menu_destroy(menu);
                return PLUGIN_HANDLED;
        }
        switch(item)
        {
                case 0:
                {
                        makeButton(id, "drtimer_button", 0);
                        iOption[0] = 1;
                        ShowMenu(id);
                }
                case 1:
                {
                        iOption[0] = iOption[0] ? 0 : 1;
                        ShowMenu(id);
                        return PLUGIN_HANDLED;
                }
                case 3:
                {
                        makeButton(id, "drtimer_button", 1);
                        iOption[1] = 1;
                        ShowMenu(id);
                }
                case 4:
                {
                        iOption[1] = iOption[1] ? 0 : 1;
                       
                        ShowMenu(id);
                        return PLUGIN_HANDLED;
                }
                case 6:
                {
                        writeButtons(id);
                        return PLUGIN_HANDLED;
                }
        }
        menu_destroy(menu);
        return PLUGIN_HANDLED;
}
bool:readButtons()
{
        new Map[32], config[32],  MapFile[128];
       
        get_mapname(Map, 31);
        get_configsdir(config, 31);
        format(MapFile, 127, "%s\drtimer\%s.buttons.cfg", config, Map);
        new Read = 0;
       
        if (file_exists(MapFile))
        {
                new Data[124], len;
                new line = 0;
                new pos[5][8];
               
                while(Read < 2 && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 )
                {
                        if (strlen(Data) < 2 || Data[0] == ';')
                                continue;
 
                        parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7);
                       
                        // Origin
                        ButtonsOrigin[Read][0] = str_to_float(pos[1]);
                        ButtonsOrigin[Read][1] = str_to_float(pos[2]);
                        ButtonsOrigin[Read][2] = str_to_float(pos[3]);
                       
                        iOption[Read] = str_to_num(pos[4]);
                        if(iOption[Read])
                                makeButton(0, "drtimer_button", Read, ButtonsOrigin[Read]);
                        Read++;
                }
        }
        else
        {
                log_amx("[DrTimer] Fajl sa dugmicima za mapu nije pronadjen.", Map);
                return false;
        }
        if(Read != 2)
        {
                log_amx("[DrTimer] Nema dugmica za mapu: %s.", Map);
                return false;
        }
        log_amx("[DrTimer] Ucitani dugmici za %s.", Map);
        return true;
}
writeButtons(id)
{
        new Map[32], config[32],  MapFile[128];
       
        get_mapname(Map, 31);
        get_configsdir(config, 31);
        format(MapFile, 127, "%s\drtimer\%s.buttons.cfg", config, Map);
       
        if (file_exists(MapFile))
                delete_file(MapFile);
 
        new Data[124];
               
        for(new i = 0; i < 2; i++)
        {
                if(ButtonsOrigin[i][0] == 0.0 && ButtonsOrigin[i][1] == 0.0 && ButtonsOrigin[i][2] == 0.0)
                        iOption[i] = 0;
                format(Data, 123, "%f %f %f %d", ButtonsOrigin[i][0], ButtonsOrigin[i][1], ButtonsOrigin[i][2], iOption[i]);
                write_file(MapFile, Data, -1);
        }
        ColorChat(id, "^x04[DrTimer]^x03Sacuvane kordinate dugmica.")
}
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
        new Float:RenderColor[3];
        RenderColor[0] = float(r);
        RenderColor[1] = float(g);
        RenderColor[2] = float(b);
 
        set_pev(entity, pev_renderfx, fx);
        set_pev(entity, pev_rendercolor, RenderColor);
        set_pev(entity, pev_rendermode, render);
        set_pev(entity, pev_renderamt, float(amount));
 
        return 1;
}
stock fm_get_aim_origin(index, Float:origin[3])
{
        new Float:start[3], Float:view_ofs[3];
        pev(index, pev_origin, start);
        pev(index, pev_view_ofs, view_ofs);
        xs_vec_add(start, view_ofs, start);
 
        new Float:dest[3];
        pev(index, pev_v_angle, dest);
        engfunc(EngFunc_MakeVectors, dest);
        global_get(glb_v_forward, dest);
        xs_vec_mul_scalar(dest, 9999.0, dest);
        xs_vec_add(start, dest, dest);
 
        engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
        get_tr2(0, TR_vecEndPos, origin);
 
        return 1;
}
 
stock makeButton(id, const szClassname[], itype, Float:pOrigin[3]={0.0, 0.0, 0.0})
{
        if(!Button[itype])
        {
                new ent = engfunc(EngFunc_CreateNamedEntity, entButton);
                if(!pev_valid(ent))
                        return PLUGIN_HANDLED;
                set_pev(ent, pev_classname, szClassname);
                set_pev(ent, pev_solid, SOLID_BBOX);
                set_pev(ent, pev_movetype, MOVETYPE_NONE);
                set_pev(ent, pev_target, itype ? "timer_end" : "timer_start");
                #if defined _CustomButtons
                engfunc(EngFunc_SetModel, ent, gszButtonModels[itype]);
                #else
                engfunc(EngFunc_SetModel, ent, "models/w_c4.mdl");
                #endif
                engfunc(EngFunc_SetSize, ent, {-15.0, -15.0, 0.0}, {15.0, 15.0, 60.0});
                Button[itype] = ent;
        }
        if(id)
        {
                new Float:vOrigin[3];
                fm_get_aim_origin(id, vOrigin);
                vOrigin[2] += 22.0;
                engfunc(EngFunc_SetOrigin, Button[itype], vOrigin);
                ButtonsOrigin[itype][0] = vOrigin[0];
                ButtonsOrigin[itype][1] = vOrigin[1];
                ButtonsOrigin[itype][2] = vOrigin[2];
        }
        else
                engfunc(EngFunc_SetOrigin, Button[itype], pOrigin);
       
        engfunc(EngFunc_DropToFloor, Button[itype]);
        switch(itype)
        {
                case 0: fm_set_rendering(Button[itype], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 100);
                case 1: fm_set_rendering(Button[itype], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 100);
        }
        return PLUGIN_HANDLED;
}