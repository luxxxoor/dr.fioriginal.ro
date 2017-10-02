#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fakemeta_util>

new g_Enable;
new g_bwEnt[33];


new const model_nade_world[] = "models/canister/w_canister.mdl" 
new const model_nade_view[] = "models/canister/v_canister.mdl" 
new const model_trail[] = "sprites/laserbeam.spr"
new on
new rendering
new trail

//For snowball trail
new g_trail
public plugin_init() {
	register_plugin( "Halloween", "1.0", "anakin_cstrike" );
	register_cvar("santa_hat", "1.1", FCVAR_SERVER);
	g_Enable = register_cvar("amx_halloweenhat", "1");
	
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1);
	
	on = register_cvar("snowballs_on","1")
	if(get_pcvar_num(on))
	{
		rendering = register_cvar("snowballs_rendering","1")
		trail = register_cvar("snowballs_trail","1")
		
		register_forward(FM_SetModel,"forward_model")
		
		register_event("CurWeapon","func_modelchange_hook","be","1=1","2=4","2=9","2=25")
	}
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel,model_nade_world)
	engfunc(EngFunc_PrecacheModel,model_nade_view)
	engfunc(EngFunc_PrecacheModel,model_nade_view)
	
	
	g_trail = engfunc(EngFunc_PrecacheModel,model_trail)
	
	precache_model("models/halloween_hat.mdl");
}

public fwHamPlayerSpawnPost( const player ) { // Cleanup by arkshine
	if ( get_pcvar_num( g_Enable ) && is_user_alive( player ) && !pev_valid ( g_bwEnt[ player ] ) ) {
		g_bwEnt[ player ] = engfunc ( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) );
		set_pev( g_bwEnt[ player ], pev_movetype, MOVETYPE_FOLLOW );
		set_pev( g_bwEnt[ player ], pev_aiment, player );
		engfunc( EngFunc_SetModel, g_bwEnt[ player ], "models/halloween_hat.mdl" );
	}
}

public func_modelchange_hook(id)
	set_pev(id, pev_viewmodel2,model_nade_view)
	
public forward_model(entity,const model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	if ( model[ 0 ] == 'm' && model[ 7 ] == 'w' && model[ 8 ] == '_' )
	{
		switch ( model[ 9 ] )
		{
			case 'f' :
			{
				engfunc ( EngFunc_SetModel, entity, model_nade_world )
				if(get_pcvar_num(trail))
				{
					fm_set_trail(entity,255,255,255,255)
				}
				if(get_pcvar_num(rendering))
				{
					fm_set_rendering ( entity, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 255 )
				}
		
			}
			case 'h' :
			{
				engfunc ( EngFunc_SetModel, entity, model_nade_world )
				if(get_pcvar_num(trail))
				{
					fm_set_trail(entity,255,0,0,255)
				}
				if(get_pcvar_num(rendering))
				{
					fm_set_rendering ( entity, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 255 )
				}
			}
			case 's' :
			{
				engfunc ( EngFunc_SetModel, entity, model_nade_world )
				if(get_pcvar_num(trail))
				{
					fm_set_trail(entity,0,255,0,255)
				}
				if(get_pcvar_num(rendering))
				{
					fm_set_rendering ( entity, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 255 )
				}
			}
		}
		return FMRES_SUPERCEDE
	}
    
	return FMRES_IGNORED
}
stock fm_set_trail(id,r,g,b,bright)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)              
	write_short(id)         
	write_short(g_trail)        
	write_byte(25)              
	write_byte(5)               
	write_byte(r)             
	write_byte(g)               
	write_byte(b)                
	write_byte(bright)                
	message_end()
}
