
#include <amxmodx>
#include <amxmisc>

#include <cstrike>

#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <xs>

new ModelWeapon[] = "models/p_glock18.mdl"
new ModelWeaponID

new Models[CsTeams][] =
{
	"",
	"models/player/leet/leet.mdl",
	"models/player/sas/sas.mdl",
	""
}

new ModelsIDs[CsTeams]

new const Plugin[] = "Lucia Hallucination"
new const Author[] = "joaquimandrade"
new const Version[]	= "1.0"

enum EntityData
{
	Origin[3],
	Angles[3],
	CsTeams:Team
}

const MaxSlots = 32

new bool:OnFirstPersonView[MaxSlots+1]
new SpectatingUser[MaxSlots+1]

new UserNeedsEntity[MaxSlots+1]
new UserEntityData[MaxSlots+1][EntityData]

new Float:LastTimeViewedAnEntity[MaxSlots+1]

const PermissionFlag = ADMIN_BAN

new CheckVisibilityForward

new CurrentHost 
new CurrentEnt

new Float:VectorNormalHideStartFactor = 46.0
new Float:VectorNormalHideEndFactor = 40.0

new Float:VectorNormalHideStep = 1.0

new const Float:PlayerRay = 22.0
new const Float:HullFactor = 0.5

const Float:PlayerHideMaxDistance = 1200.0

new CsTeams:Teams = CS_TEAM_T + CS_TEAM_CT

new OnFirstPersonViewN

new ForwardAddToFullPackPre
new ForwardAddToFullPackPost

new ForwardCmdStart

public plugin_precache()
{
	ModelWeaponID = precache_model(ModelWeapon)
	
	ModelsIDs[CS_TEAM_T] = precache_model(Models[CS_TEAM_T])
	ModelsIDs[CS_TEAM_CT] = precache_model(Models[CS_TEAM_CT])
}
public plugin_init()
{
	register_plugin(Plugin,Version,Author)

	register_event("TextMsg","specMode","b","2&#Spec_Mode")
	register_event("StatusValue","specTarget","bd","1=2")
	register_event("SpecHealth2","specTarget","bd")
	
	RegisterHam(Ham_Spawn,"player","playerSpawn",1)
	
	register_cvar("luciaHallucination",Version,FCVAR_SERVER|FCVAR_SPONLY);
	
	register_clcmd("luciaToggle","luciaToggle",PermissionFlag)
}

public luciaToggle(id,level,cid) 
{
	if(cmd_access(id,level,cid,0))
	{
		toggle(id)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public checkVisibility(id,pset)
{	
	if(CurrentEnt == id)
	{
		unregister_forward(FM_CheckVisibility,CheckVisibilityForward)
		CheckVisibilityForward = 0
		
		forward_return(FMV_CELL,1)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public addToFullPackPre(es, e, ent, host, hostflags, player, pSet)
{
	if(player && (host != ent) && is_user_alive(ent))
	{
		if((LastTimeViewedAnEntity[host] != get_gametime()) && (((UserNeedsEntity[host]) && (cs_get_user_team(host) != cs_get_user_team(ent))) || (OnFirstPersonView[host] && UserNeedsEntity[SpectatingUser[host]] && (cs_get_user_team(SpectatingUser[host]) != cs_get_user_team(ent)))))
		{
			if(!engfunc(EngFunc_CheckVisibility,ent,pSet))
			{
				CurrentEnt = ent
				CurrentHost = host
				
				if(!CheckVisibilityForward)
				{
					CheckVisibilityForward = register_forward(FM_CheckVisibility,"checkVisibility")
				}
			}
		}
	}
}

public addToFullPackPost(es, e, ent, host, hostflags, player, pSet)
{	
	if((host == CurrentHost) && (ent == CurrentEnt))
	{		
		LastTimeViewedAnEntity[CurrentHost] = get_gametime()
		
		new CsTeams:team
		
		if(OnFirstPersonView[host])
		{
			new spectated = SpectatingUser[host]
			
			team = UserEntityData[spectated][Team]
			
			static Float:origin[3]
			pev(spectated,pev_origin,origin)
			
			engfunc(EngFunc_TraceLine,origin,Float:UserEntityData[spectated][Origin],0,spectated,0)
			
			get_tr2(0,TR_EndPos,origin)
			
			set_es(es,ES_Origin,origin)
			set_es(es,ES_Angles,Float:UserEntityData[spectated][Angles])	
			
			set_es(es,ES_RenderMode,kRenderTransAlpha)
			set_es(es,ES_RenderAmt,170)
		
		}
		else
		{
			team = UserEntityData[host][Team]
			
			set_es(es,ES_Origin,Float:UserEntityData[host][Origin])
			set_es(es,ES_Angles,Float:UserEntityData[host][Angles])	
		}
		
		new CsTeams:enemyTeam = Teams - team
		
		
		set_es(es,ES_Team,_:enemyTeam)
		set_es(es,ES_ModelIndex,ModelsIDs[enemyTeam])
		set_es(es,ES_WeaponModel,ModelWeaponID)
		set_es(es,ES_Effects,EF_INVLIGHT)	
	}
	
	CurrentHost = CurrentEnt = 0
}

hullCheck(Float:origin[3])
{	
	static Float:margin[3]
	
	xs_vec_copy(origin,margin)
	
	for(new i=0;i<3;i++)
		margin[i] += HullFactor
	
	engfunc(EngFunc_TraceHull,origin,margin,1,HULL_POINT,0,0)
	return get_tr2(0,TR_AllSolid)
	
}

bool:isSafeHideOrigin(Float:origin[3])
{
	static Float:centerPointsZDistanceMultiply[] = {1.2,0.5,0.0,-0.5,-1.0,-1.5}
	static Float:centerPoints[sizeof centerPointsZDistanceMultiply][3]
	
	for(new i=0;i<sizeof centerPointsZDistanceMultiply;i++)
	{
		xs_vec_copy(origin,centerPoints[i])
		centerPoints[i][2] += centerPointsZDistanceMultiply[i] * (PlayerRay)
		
		if(!hullCheck(centerPoints[i]))
		{
			return false
		}
		
		static Float:borderPointsXYDistanceMultiply[4][2] = {{0.0,1.2},{1.2,0.0},{0.0,-1.2},{-1.2,0.0}}
		
		for(new j=0;j<4;j++)
		{
			static Float:borderPoint[3]
			xs_vec_copy(centerPoints[i],borderPoint)
			
			for(new k=0;k<2;k++)
			{
				borderPoint[k] += borderPointsXYDistanceMultiply[j][k] * (PlayerRay)
			}
			
			if(!hullCheck(borderPoint))
			{
				return false
			}
		}
	}
	
	return true
}

getEntityData(id)
{
	static Float:origin[3],Float:viewAngles[3],Float:viewOfs[3]
	
	pev(id,pev_origin,origin)
	pev(id,pev_view_ofs,viewOfs)
	
	xs_vec_add(origin,viewOfs,origin)
	
	pev(id,pev_v_angle,viewAngles)
	
	static Float:path[3]
	
	angle_vector(viewAngles,ANGLEVECTOR_FORWARD,path)
	xs_vec_normalize(path,path)
	
	xs_vec_mul_scalar(path,PlayerHideMaxDistance,path)
	
	static Float:end[3]
	
	xs_vec_add(origin,path,end)
	
	engfunc(EngFunc_TraceLine,origin,end,0,id,0);
	
	static Float:fraction
	get_tr2(0,TR_flFraction,fraction)
	
	if((fraction != 1.0) && (get_tr2(0,TR_Hit) == -1))
	{
		get_tr2(0,TR_EndPos,end)
		
		static Float:normal[3]
		get_tr2(0,TR_vecPlaneNormal,normal)
		
		static Float:normalPath[3]
		
		for(new Float:i=VectorNormalHideStartFactor;i>=VectorNormalHideEndFactor;i-=VectorNormalHideStep)
		{
			xs_vec_mul_scalar(normal,-i,normalPath)
			xs_vec_add(end,normalPath,normalPath)
			
			if(isSafeHideOrigin(normalPath))
			{
				static Float:angles[3]
				
				vector_to_angle(normal,angles)
			
				if(angles[0] > 0.0)
					angles[0] = 0.0
				
				xs_vec_copy(angles,Float:UserEntityData[id][Angles])
				xs_vec_copy(normalPath,Float:UserEntityData[id][Origin])
				
				UserEntityData[id][Team] = _:cs_get_user_team(id)
				
				return true
			}
		}
	}
	
	return false
}

toggle(id)
{
	if(OnFirstPersonView[id])
	{		
		if(UserNeedsEntity[SpectatingUser[id]])
		{
			client_print(id,print_chat,"[Lucia Hallucination] Stopped")
			
			UserNeedsEntity[SpectatingUser[id]] = false
		}
		else
		{
			if(getEntityData(SpectatingUser[id]))
			{
				client_print(id,print_chat,"[Lucia Hallucination] Started")
				
				UserNeedsEntity[SpectatingUser[id]] = true
			}
			else
			{
				client_print(id,print_chat,"[Lucia Hallucination] Failed to find an available spot")
			}
		}
	}
}

public cmdStart(id)
{
	if((get_user_button(id) & IN_RELOAD) && (~get_user_oldbutton(id) & IN_RELOAD))
		toggle(id)
}

handleJoiningFirstPersonView(id)
{	
	OnFirstPersonView[id] = true
	
	if(!OnFirstPersonViewN++)
	{
		ForwardAddToFullPackPre = register_forward(FM_AddToFullPack,"addToFullPackPre",0);
		ForwardAddToFullPackPost = register_forward(FM_AddToFullPack,"addToFullPackPost",1)
		ForwardCmdStart = register_forward(FM_CmdStart,"cmdStart")
	}
}

handleQuitingFirstPersonView(id)
{
	OnFirstPersonView[id] = false
	UserNeedsEntity[SpectatingUser[id]] = false
	SpectatingUser[id] = 0
	
	if(!--OnFirstPersonViewN)
	{
		unregister_forward(FM_AddToFullPack,ForwardAddToFullPackPre)
		unregister_forward(FM_AddToFullPack,ForwardAddToFullPackPost,1)
		unregister_forward(FM_CmdStart,ForwardCmdStart)
	}
}

public playerSpawn(id)
{
	if(OnFirstPersonView[id] && is_user_alive(id))
	{
		handleQuitingFirstPersonView(id)
	}
}

public client_disconnected(id)
{
	if(OnFirstPersonView[id])
	{
		handleQuitingFirstPersonView(id)
	}
}

public specMode(id)
{
	if(get_user_flags(id) & PermissionFlag)
	{
		new specMode[12]
		read_data(2,specMode,11)
			
		if(specMode[10] == '4')
		{
			handleJoiningFirstPersonView(id)
		}
		else if(OnFirstPersonView[id])
		{
			handleQuitingFirstPersonView(id)
		}
	}
}

public specTarget(id)
{
	new spectated = read_data(2);
		
	if(spectated)
	{
		if(OnFirstPersonView[id])
		{
			if(spectated != SpectatingUser[id])
			{
				handleQuitingFirstPersonView(id)
				SpectatingUser[id] = spectated;				
				handleJoiningFirstPersonView(id)
			}
		}
		else
		{
			SpectatingUser[id] = spectated;
		}
	}
}