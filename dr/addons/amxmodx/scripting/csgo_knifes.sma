#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
 
#if AMXX_VERSION_NUM < 181
    #assert AMX Mod X v1.8.1 or later library required!
#endif
 
#if AMXX_VERSION_NUM <183
    #define MAX_PLAYERS 32
#endif

#pragma semicolon 1
 
enum _:ModelType
{
        vModel[45],
        pModel[45]
}
 
new const Models[][ModelType] =
{
        {       ""                                            , ""                                                      },
        {       "models/csgo_knifes/bayonet/ct/v_knife.mdl"   , "models/csgo_knifes/bayonet/ct/p_knife.mdl"             },
        {       "models/csgo_knifes/bayonet/t/v_knife.mdl"    , "models/csgo_knifes/bayonet/t/p_knife.mdl"              },
        {       "models/csgo_knifes/butterfly/ct/v_knife.mdl" , "models/csgo_knifes/butterfly/ct/p_knife.mdl"           },
        {       "models/csgo_knifes/butterfly/t/v_knife.mdl"  , "models/csgo_knifes/butterfly/t/p_knife.mdl"            },
        {       "models/csgo_knifes/default/ct/v_knife.mdl"   , "models/csgo_knifes/default/ct/p_knife.mdl"             },
        {       "models/csgo_knifes/default/t/v_knife.mdl"    , "models/csgo_knifes/default/t/p_knife.mdl"              },
        {       "models/csgo_knifes/flip/ct/v_knife.mdl"      , "models/csgo_knifes/flip/ct/p_knife.mdl"                },
        {       "models/csgo_knifes/flip/t/v_knife.mdl"       , "models/csgo_knifes/flip/t/p_knife.mdl"                 },
        {       "models/csgo_knifes/gut/ct/v_knife.mdl"       , "models/csgo_knifes/gut/ct/p_knife.mdl"                 },
        {       "models/csgo_knifes/gut/t/v_knife.mdl"        , "models/csgo_knifes/gut/t/p_knife.mdl"                  },
        {       "models/csgo_knifes/huntsman/ct/v_knife.mdl"  , "models/csgo_knifes/huntsman/ct/p_knife.mdl"            },
        {       "models/csgo_knifes/huntsman/t/v_knife.mdl"   , "models/csgo_knifes/huntsman/t/p_knife.mdl"             },
        {       "models/csgo_knifes/karambit/ct/v_knife.mdl"  , "models/csgo_knifes/karambit/ct/p_knife.mdl"            },
        {       "models/csgo_knifes/karambit/t/v_knife.mdl"   , "models/csgo_knifes/karambit/t/p_knife.mdl"             },
        {       "models/csgo_knifes/m9_bayonet/ct/v_knife.mdl", "models/csgo_knifes/m9_bayonet/ct/p_knife.mdl"          },
        {       "models/csgo_knifes/m9_bayonet/t/v_knife.mdl" , "models/csgo_knifes/m9_bayonet/t/p_knife.mdl"           }
};
 
new const m_pPlayer = 41, XO_WEAPON = 4, Version[] = "1.2";
new Array:HandleModelsArray;
new KnifeId[MAX_PLAYERS], Size;
 
public plugin_precache()
{
        new Data[ModelType], bool:ResourcePrecached;
        HandleModelsArray = ArrayCreate(ModelType);
       
	Size = sizeof Models;
        for(new i = 0; i < Size; ++i)
        {
               ArrayPushArray(HandleModelsArray, Models[i]);
        }
       
        Size = ArraySize(HandleModelsArray);
        for(new i = 1; i < Size; ++i)
        {
                ArrayGetArray(HandleModelsArray, i, Data);
                if(!file_exists(Data[vModel]) || !file_exists(Data[pModel]))
                {
			log_amx("Fisierul %s si/sau fisierul %s lipsesc. Verifica daca ai introdus calea corect.", Data[vModel], Data[pModel]);
			ArrayDeleteItem(HandleModelsArray, i--);
			--Size;
                        continue;
                }
               	
		ResourcePrecached = true;
                precache_model(Data[vModel]);
                precache_model(Data[pModel]);
        }
	if ( !ResourcePrecached )
	{
		set_fail_state("Nu a fost detectat nici un model pentru cutite, pluginul se va auto-inchide.");
	}
}
 
public plugin_init()
{
        register_plugin("CSGO Knifes", Version, "lüxor");
       
        RegisterHam(Ham_Item_Deploy, "weapon_knife", "CBasePlayerItem_Deploy", 1);
        RegisterHam(Ham_Spawn, "player", "CBasePlayer_Spawn", 1);
       
        register_cvar("csgo_knifes", Version, FCVAR_SERVER|FCVAR_SPONLY);
}
 
public CBasePlayer_Spawn(id)
{
        if ( !is_user_alive(id) )
        {
                return;
        }
 
        new RandomNum = random_num(1, Size -1);
        KnifeId[id] = cs_get_user_team(id) == CS_TEAM_CT ? RandomNum * 2 - 1 : RandomNum * 2;
}
 
public CBasePlayerItem_Deploy(ent)
{
        if(pev_valid(ent))
        {
                new id = get_pdata_cbase(ent, m_pPlayer, XO_WEAPON), Data[ModelType];
       
                ArrayGetArray(HandleModelsArray, KnifeId[id], Data);
       
                set_pev(id, pev_viewmodel2, Data[vModel]);
                set_pev(id, pev_weaponmodel2, Data[pModel]);
        }
}
 
public plugin_end()
{
        ArrayDestroy(HandleModelsArray);
}