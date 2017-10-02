/*
Created By AlexALX (c) 2010-2011 http://alex-php.net/

DRM: Triggers & Entities Fix is free software;
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
------------------------
Created By AlexALX (c) 2010-2011 http://alex-php.net/
Based on DRM_trigger_hurt_fix
Original plugin authors:
coderiz / xPaw
Thanks:
ConnorMcLeod (CTriggerPush_Touch, func_rotating render fix plugin)
Monyak (idea how to fix the doors and some help)
xPaw (use him func_breakable render fix plugin)
Lt.RAT (small help with plugin optimization)
*/
#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>

// Change this values to higher, if you have errors
#define MAX_ENTS 1024
#define MAX_ITEMS 384
#define MAX_BUTTONS 256

new Float:g_flEntMins[ MAX_ENTS ][ 3 ];
new Float:g_flEntMaxs[ MAX_ENTS ][ 3 ];
new g_eEnt[ MAX_ENTS ];
new g_eCount, g_dCount;

new Float:g_flItemMins[ MAX_ITEMS ][ 3 ];
new Float:g_flItemMaxs[ MAX_ITEMS ][ 3 ];
new g_iEnt[ MAX_ITEMS ], n_iEnt[ MAX_ITEMS ];
new g_iCount;

new Float:g_flButMins[ MAX_BUTTONS ][ 3 ];
new Float:g_flButMaxs[ MAX_BUTTONS ][ 3 ];
new g_bEnt[ MAX_BUTTONS ], n_bEnt[ MAX_BUTTONS ];
new g_bCount;

new register_hurt, register_push, register_teleport, register_gravity, register_multiple, register_once, register_counter;
new register_breakable, register_breakable_render, register_button, register_button_delay, register_item, register_item_delay, register_door, register_door_open;
new register_door_rotating, register_door_rotating_open, register_momentary_door, register_train, register_train_render, register_vehicle, register_tracktrain;
new register_rotating, register_rotating_render, register_pendulum, register_block;
new cvar_breakable, cvar_button, cvar_item, cvar_door, cvar_door_open, cvar_door_rotating, cvar_door_rotating_open, cvar_momentary_door;
new cvar_train, cvar_vehicle, cvar_tracktrain, cvar_rotating, cvar_pendulum, cvar_block;

#define VERSION "1.4.1"

public plugin_init() {
	register_plugin( "DRM: Triggers & Entities Fix", VERSION, "AlexALX" );
	register_cvar( "semiclip_fix_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	register_hurt = register_cvar( "semiclip_fix_hurt", "1" );
	register_push = register_cvar( "semiclip_fix_push", "1" );
	register_teleport = register_cvar( "semiclip_fix_teleport", "1" );
	register_gravity = register_cvar( "semiclip_fix_gravity", "1" );
	register_multiple = register_cvar( "semiclip_fix_multiple", "1" );
	register_once = register_cvar( "semiclip_fix_once", "1" );
	register_counter = register_cvar( "semiclip_fix_counter", "1" );
	register_breakable = register_cvar( "semiclip_fix_breakable", "1" );
	register_breakable_render = register_cvar( "semiclip_fix_breakable_render", "1" );
	register_button = register_cvar( "semiclip_fix_button", "1" );
	register_button_delay = register_cvar( "semiclip_fix_button_delay", "2.0" );
	register_item = register_cvar( "semiclip_fix_item", "1" );
	register_item_delay = register_cvar( "semiclip_fix_item_delay", "2.0" );
	register_door = register_cvar( "semiclip_fix_door", "1" );
	register_door_open = register_cvar( "semiclip_fix_door_open", "1" );
	register_door_rotating = register_cvar( "semiclip_fix_door_rotating", "1" );
	register_door_rotating_open = register_cvar( "semiclip_fix_door_rotating_open", "1" );
	register_momentary_door = register_cvar( "semiclip_fix_momentary_door", "1" );
	register_train = register_cvar( "semiclip_fix_train", "1" );
	register_train_render = register_cvar( "semiclip_fix_train_render", "1" );
	register_vehicle = register_cvar( "semiclip_fix_vehicle", "1" );
	register_tracktrain = register_cvar( "semiclip_fix_tracktrain", "1" );
	register_rotating = register_cvar( "semiclip_fix_rotating", "1" );
	register_rotating_render = register_cvar( "semiclip_fix_rotating_render", "1" );
	register_pendulum = register_cvar( "semiclip_fix_pendulum", "1" );
	register_block = register_cvar( "semiclip_fix_block", "1" );
}

public plugin_cfg() {
	set_task(0.1,"check_plugins");
	set_task(7.0,"delay_load");
}

public check_plugins() {
	if(find_plugin_byfile("linux_func_rotating_fix_fakemeta.amxx") != INVALID_PLUGIN_ID) {
		log_amx("WARNING: linux_func_rotating_fix_fakemeta.amxx plugin running! stopped.");
		pause("acd","linux_func_rotating_fix_fakemeta.amxx");
	}
	if(find_plugin_byfile("linux_func_rotating_fix_engine.amxx") != INVALID_PLUGIN_ID) {
		log_amx("WARNING: linux_func_rotating_fix_engine.amxx plugin running! stopped.");
		pause("acd","linux_func_rotating_fix_engine.amxx");
	}
	if(find_plugin_byfile("func_rotating_bugfix.amxx") != INVALID_PLUGIN_ID) {
		log_amx("WARNING: func_rotating_bugfix.amxx plugin running! stopped.");
		pause("acd","func_rotating_bugfix.amxx");
	}
	if(find_plugin_byfile("DRM_trigger_hurt_fix.amxx") != INVALID_PLUGIN_ID) {
		log_amx("WARNING: DRM_trigger_hurt_fix.amxx plugin running! stopped.");
		pause("acd","DRM_trigger_hurt_fix.amxx");
	}
	if(find_plugin_byfile("linux_func_train_fm.amxx") != INVALID_PLUGIN_ID) {
		log_amx("WARNING: linux_func_train_fm.amxx plugin running! stopped.");
		pause("acd","linux_func_train_fm.amxx");
	}
	if(find_plugin_byfile("BreakableFix.amxx") != INVALID_PLUGIN_ID) {
		log_amx("WARNING: BreakableFix.amxx plugin running! stopped.");
		pause("acd","BreakableFix.amxx");
	}
}

public delay_load()
{
	new cvar_hurt = get_pcvar_num(register_hurt);
	new cvar_push = get_pcvar_num(register_push);
	new cvar_teleport = get_pcvar_num(register_teleport);
	new cvar_gravity = get_pcvar_num(register_gravity);
	new cvar_multiple = get_pcvar_num(register_multiple);
	new cvar_once = get_pcvar_num(register_once);
	new cvar_counter = get_pcvar_num(register_counter);
	cvar_breakable = get_pcvar_num(register_breakable);
	new cvar_breakable_render = get_pcvar_num(register_breakable_render);
	cvar_button = get_pcvar_num(register_button);
	new Float:cvar_button_delay = get_pcvar_float(register_button_delay);
	cvar_item = get_pcvar_num(register_item);
	new Float:cvar_item_delay = get_pcvar_float(register_item_delay);
	cvar_door = get_pcvar_num(register_door);
	cvar_door_open = get_pcvar_num(register_door_open);
	cvar_door_rotating = get_pcvar_num(register_door_rotating);
	cvar_door_rotating_open = get_pcvar_num(register_door_rotating_open);
	cvar_momentary_door = get_pcvar_num(register_momentary_door);
	cvar_train = get_pcvar_num(register_train);
	new cvar_train_render = get_pcvar_num(register_train_render);
	cvar_vehicle = get_pcvar_num(register_vehicle);
	cvar_tracktrain = get_pcvar_num(register_tracktrain);
	cvar_rotating = get_pcvar_num(register_rotating);
	new cvar_rotating_render = get_pcvar_num(register_rotating_render);
	cvar_pendulum = get_pcvar_num(register_pendulum);
	cvar_block = get_pcvar_num(register_block);

	// Searching entities
	new iEntity = -1;
	new g_iPushCount, g_iBreakCount, g_iTrainCount, g_iRotatingCount, classname[32];
	while( (iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, Float:{0.0,0.0,0.0}, 8192.0)) > 0 ) {
		if (pev_valid(iEntity)) {
			classname[0] = '^0';
			pev(iEntity,pev_classname,classname, 31);
			if (cvar_hurt&&equali(classname,"trigger_hurt")||cvar_push&&equali(classname,"trigger_push")
			||cvar_teleport&&equali(classname,"trigger_teleport")||cvar_gravity&&equali(classname,"trigger_gravity")
			||cvar_multiple&&equali(classname,"trigger_multiple")||cvar_once&&equali(classname,"trigger_once")
			||cvar_counter&&equali(classname,"trigger_counter")||cvar_breakable&&equali(classname,"func_breakable")) {
				pev( iEntity, pev_absmin, g_flEntMins[ g_eCount ] );
				pev( iEntity, pev_absmax, g_flEntMaxs[ g_eCount ] );
				g_eEnt[ g_eCount ] = iEntity;
				g_eCount++;
				if (equali(classname,"trigger_push")) g_iPushCount++;
			}
			if (cvar_breakable_render&&equali(classname,"func_breakable")) g_iBreakCount++;
			if (cvar_door&&equali(classname,"func_door")||cvar_door_rotating&&equali(classname,"func_door_rotating")
			||cvar_momentary_door&&equali(classname,"momentary_door")||cvar_rotating&&equali(classname,"func_rotating")
			||cvar_pendulum&&equali(classname,"func_pendulum")||cvar_train&&equali(classname,"func_train")
			||cvar_vehicle&&equali(classname,"func_vehicle")||cvar_tracktrain&&equali(classname,"func_tracktrain"))
				g_dCount++;
			if (is_linux_server()&&cvar_train_render&&equali(classname,"func_train")) g_iTrainCount++;
			if (is_linux_server()&&cvar_rotating_render&&equali(classname,"func_rotating")) g_iRotatingCount++;
			if (cvar_item&&(containi(classname,"item_")!=-1||equali(classname,"armoury_entity"))) g_iCount++;
			if (cvar_button&&equali(classname,"func_button")) g_bCount++;
		}
	}

	if(g_eCount>0||g_iCount>0||g_bCount>0) {
		register_forward(FM_PlayerPreThink, "FwdPlayerPreThink");
		if (g_iPushCount > 0) RegisterHam(Ham_Touch, "trigger_push", "CTriggerPush_Touch");
	}
	if (g_dCount>0)	set_task(0.1, "check_players", 0, "", 0, "b");
	if (cvar_breakable_render&&g_iBreakCount > 0) RegisterHam( Ham_Think , "func_breakable" , "FwdThinkBreak" );
	if (is_linux_server()&&cvar_train_render&&g_iTrainCount > 0) RegisterHam( Ham_Think , "func_train", "Think_FixAngles", 1 );
	if (is_linux_server()&&cvar_rotating_render&&g_iRotatingCount > 0) RegisterHam( Ham_Think , "func_rotating", "Think_FixAngles", 1 );
	if (cvar_item_delay>0.0) set_task(cvar_item_delay, (g_iCount > 0 ? "abs_update_items" : "abs_update_boxs"), 1, "", 0, "b");
	else if (cvar_item_delay<=0.0&&g_iCount > 0) set_task(0.1, "abs_update_items",0);
	if (cvar_button_delay>0.0&&g_bCount > 0) set_task(cvar_button_delay, "abs_update_buttons", 0, "", 0, "b");
	else if (cvar_button_delay<=0.0&&g_bCount > 0) set_task(0.1, "abs_update_buttons");
}

public abs_update_items(weaponbox) {
	g_iEnt = n_iEnt;
	g_iCount = 0;

	// Searching entities
	new iEntity = -1, classname[32];
	while( (iEntity = engfunc(EngFunc_FindEntityInSphere, iEntity, Float:{0.0,0.0,0.0}, 8192.0)) > 0 ) {
		if (pev_valid(iEntity)) {
			classname[0] = '^0';
			pev(iEntity,pev_classname,classname, 31)
			if (containi(classname,"item_")!=-1||equali(classname,"armoury_entity")||weaponbox&&equali(classname,"weaponbox")) {
				pev( iEntity, pev_absmin, g_flItemMins[ g_iCount ] );
				pev( iEntity, pev_absmax, g_flItemMaxs[ g_iCount ] );
				g_iEnt[ g_iCount ] = iEntity;
				g_iCount++;
			}
		}
	}
}

public abs_update_boxs() {
	g_iEnt = n_iEnt;
	g_iCount = 0;

	// Searching entities
	new iEntity = -1;
	while( (iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "weaponbox")) > 0 ) {
		if (pev_valid(iEntity)) {
			pev( iEntity, pev_absmin, g_flItemMins[ g_iCount ] );
			pev( iEntity, pev_absmax, g_flItemMaxs[ g_iCount ] );
			g_iEnt[ g_iCount ] = iEntity;
			g_iCount++;
		}
	}
}

public abs_update_buttons() {
	g_bEnt = n_bEnt;
	g_bCount = 0;

	// Searching entities
	new iEntity = -1;
	while( (iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "func_button")) > 0 ) {
		if (pev_valid(iEntity)) {
			pev( iEntity, pev_absmin, g_flButMins[ g_bCount ] );
			pev( iEntity, pev_absmax, g_flButMaxs[ g_bCount ] );
			g_bEnt[ g_bCount ] = iEntity;
			g_bCount++;
		}
	}
}

public FwdPlayerPreThink( id ) {
	if( !is_user_alive( id ) || pev( id, pev_solid ) != SOLID_NOT )
		return FMRES_IGNORED;

	if (g_eCount>0||g_iCount>0||g_bCount>0) {
		new Float:flMins[ 3 ], Float:flMaxs[ 3 ];
		pev( id, pev_absmin, flMins );
		pev( id, pev_absmax, flMaxs );
		if (g_eCount>0) {
			// Head and Legs fix oO
			new Float:flMinsF[ 3 ], Float:flMaxsF[ 3 ];
			flMinsF[0] = flMins[0]+1;
			flMinsF[1] = flMins[1]+1;
			flMinsF[2] = flMins[2]+3;
			flMaxsF[0] = flMaxs[0]-1;
			flMaxsF[1] = flMaxs[1]-1;
			flMaxsF[2] = flMaxs[2]-17;
			new classname[32];
			for( new i = 0; i < g_eCount; i++ ) {
				if (pev_valid(g_eEnt[i])) {
					if (pev( g_eEnt[i], pev_solid ) != SOLID_NOT) {
						classname[0] = '^0';
						pev(g_eEnt[i],pev_classname,classname, 31);
						if (cvar_breakable&&equali(classname,"func_breakable")) {
							if( !( g_flEntMins[i][0] > flMaxs[0] || g_flEntMaxs[i][0] < flMins[0] )
							&& !( g_flEntMins[i][1] > flMaxs[1] || g_flEntMaxs[i][1] < flMins[1] )
							&& !( g_flEntMins[i][2] > flMaxs[2] || g_flEntMaxs[i][2] < flMins[2] ) ) {
								ExecuteHamB( Ham_Touch, g_eEnt[i], id );
							}
						} else {
							if( !( g_flEntMins[i][0] > flMaxsF[0] || g_flEntMaxs[i][0] < flMinsF[0] )
							&& !( g_flEntMins[i][1] > flMaxsF[1] || g_flEntMaxs[i][1] < flMinsF[1] )
							&& !( g_flEntMins[i][2] > flMaxsF[2] || g_flEntMaxs[i][2] < flMinsF[2] ) ) {
								ExecuteHamB( Ham_Touch, g_eEnt[i], id );
							}
						}
					}
				}
			}
		}
		if (g_iCount>0) {
			for( new i = 0; i < g_iCount; i++ ) {
				if (pev_valid(g_iEnt[i])) {
					if (pev( g_iEnt[i], pev_solid ) != SOLID_NOT) {
						if( !( g_flItemMins[i][0] > flMaxs[0] || g_flItemMaxs[i][0] < flMins[0] )
						&& !( g_flItemMins[i][1] > flMaxs[1] || g_flItemMaxs[i][1] < flMins[1] )
						&& !( g_flItemMins[i][2] > flMaxs[2] || g_flItemMaxs[i][2] < flMins[2] ) ) {
							ExecuteHamB( Ham_Touch, g_iEnt[i], id );
						}
					}
				}
			}
		}
		if (g_bCount>0) {
			for( new i = 0; i < g_bCount; i++ ) {
				if (pev_valid(g_bEnt[i])) {
					if (pev( g_bEnt[i], pev_solid ) != SOLID_NOT) {
						if( !( g_flButMins[i][0] > flMaxs[0] || g_flButMaxs[i][0] < flMins[0] )
						&& !( g_flButMins[i][1] > flMaxs[1] || g_flButMaxs[i][1] < flMins[1] )
						&& !( g_flButMins[i][2] > flMaxs[2] || g_flButMaxs[i][2] < flMins[2] ) ) {
							ExecuteHamB( Ham_Touch, g_bEnt[i], id );
						}
					}
				}
			}
		}
	}
	return FMRES_IGNORED;
}

public check_players() {
	new players[32], num, id, iEntity;
	get_players(players, num,"a")
	new Float:origin[3], trace, ent, hull, classname[32], Float:dmg;
	for(new i=0; i<num; i++) {
		id = players[i];
		if (!is_user_alive(id) || pev( id, pev_solid ) != SOLID_NOT) continue;
		if (cvar_door||cvar_door_rotating||cvar_momentary_door||cvar_rotating||cvar_pendulum||cvar_train||cvar_vehicle||cvar_tracktrain) {
			if (!fm_get_user_godmode(id) && !fm_get_user_noclip(id)) {
				pev(id, pev_origin,origin)
				hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
				engfunc(EngFunc_TraceHull, origin, origin, IGNORE_MONSTERS, hull, id, trace)
				ent = get_tr2(trace, TR_pHit)
				free_tr2(trace)
				if (ent>0) {
					classname[0] = '^0';
					pev(ent,pev_classname,classname, 31)
					if (cvar_door&&equali(classname,"func_door")||cvar_door_rotating&&equali(classname,"func_door_rotating")
					||cvar_momentary_door&&equali(classname,"momentary_door")||cvar_rotating&&equali(classname,"func_rotating")
					||cvar_pendulum&&equali(classname,"func_pendulum")||cvar_train&&equali(classname,"func_train")
					||cvar_vehicle&&equali(classname,"func_vehicle")||cvar_tracktrain&&equali(classname,"func_tracktrain")) {
						if (cvar_block) {
							ExecuteHamB( Ham_Blocked, ent, id );
						} else {
							pev(ent,pev_dmg,dmg)
							if (dmg>=0.0) fm_fakedamage(id, classname, dmg, DMG_GENERIC)
						}
					}
				}
			}
			if (cvar_door_open||cvar_door_rotating_open) {
				pev(id, pev_origin,origin);
				engfunc(EngFunc_TraceHull, origin, origin, IGNORE_MONSTERS, HULL_LARGE, id, trace);
				iEntity = get_tr2(trace, TR_pHit);
				free_tr2(trace);
				if (iEntity>0) {
					classname[0] = '^0';
					pev(iEntity,pev_classname,classname, 31)
					if (cvar_door_open&&equali(classname,"func_door")||cvar_door_rotating_open&&equali(classname,"func_door_rotating"))
						ExecuteHamB( Ham_Touch, iEntity, id );
				}
			}
		}
	}
}

// Thanks ConnorMcLeod
public CTriggerPush_Touch( iEnt , pevToucher )
{
    static const fBadMoveTypeBit = (1<<MOVETYPE_NONE)|(1<<MOVETYPE_PUSH)|(1<<MOVETYPE_NOCLIP)|(1<<MOVETYPE_FOLLOW)
    static const fBadSolidBit = (1<<SOLID_BSP) //(1<<SOLID_NOT)|
    if(    ( fBadMoveTypeBit & (1<<pev(pevToucher, pev_movetype)) )
    ||    ( fBadSolidBit & (1<<pev(pevToucher, pev_solid)) )    )
    {
        return HAM_SUPERCEDE
    }

    if( pev(iEnt, pev_spawnflags) & SF_TRIG_PUSH_ONCE )
    {
        // Instant trigger, just transfer velocity and remove
        new Float:vecVelocity[3], Float:flSpeed, Float:vecMoveDir[3]
        pev(pevToucher, pev_velocity, vecVelocity)
        pev(iEnt, pev_speed, flSpeed)
        pev(iEnt, pev_movedir, vecMoveDir)
        xs_vec_mul_scalar(vecMoveDir, flSpeed, vecMoveDir)
        xs_vec_add(vecVelocity, vecMoveDir, vecVelocity)
        if( vecVelocity[2] > 0.0 )
        {
            set_pev(pevToucher, pev_flags, pev(pevToucher, pev_flags) & ~FL_ONGROUND)
        }
        set_pev(pevToucher, pev_velocity, vecVelocity)
        set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
    }
    else
    {    // Push field, transfer to base velocity
        new Float:flSpeed, Float:vecPush[3]
        pev(iEnt, pev_speed, flSpeed)
        pev(iEnt, pev_movedir, vecPush)
        xs_vec_mul_scalar(vecPush, flSpeed, vecPush)

        new iFlags = pev(pevToucher, pev_flags)
        if( iFlags & FL_BASEVELOCITY )
        {
            new Float:vecBaseVelocity[3]
            pev(pevToucher, pev_basevelocity, vecBaseVelocity)
            xs_vec_add(vecPush, vecBaseVelocity, vecPush)
        }
        else
        {
            set_pev(pevToucher, pev_flags, iFlags | FL_BASEVELOCITY)
        }

        set_pev(pevToucher, pev_basevelocity, vecPush)
    }
    return HAM_SUPERCEDE;
}

// func_rotating rendering fix (for linux) by ConnorMcLeod
public Think_FixAngles( iEnt )
{
    new Float:vecAngles[3], bSet, i, Float:fAngle;
    pev(iEnt, pev_angles, vecAngles);
    bSet = false;
    for(i=0; i<3; i++) {
        fAngle = vecAngles[i];
        if( fAngle < -360.0 || fAngle > 360.0 ) {
            vecAngles[i] -= floatround(fAngle) / 360 * 360;
            bSet = true;
        }
    }
    if( bSet ) set_pev(iEnt, pev_angles, vecAngles);
}

// func_breakable rendering fix by xPaw (convert to fakemeta by AlexALX)
public FwdThinkBreak( iEntity ) {
	if( pev( iEntity, pev_solid ) == SOLID_NOT ) {
		new iEffects = pev( iEntity, pev_effects );

		if( !( iEffects & EF_NODRAW ) )
			set_pev( iEntity, pev_effects, iEffects | EF_NODRAW );

		if( pev( iEntity, pev_deadflag ) != DEAD_DEAD )
			set_pev( iEntity, pev_deadflag, DEAD_DEAD );
	}
}