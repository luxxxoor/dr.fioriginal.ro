#if defined _stripweapons_included
  #endinput
#endif
#define _stripweapons_included

#include <fakemeta>
#include <hamsandwich>    

enum 
{
    Primary = 1
    , Secondary
    , Knife
    , Grenades
    , C4
};


stock StripWeapons(id, Type, bool: bSwitchIfActive = true)
{
    if(is_user_alive(id))
    {
        new iEntity, iWeapon;
        while((iWeapon = GetWeaponFromSlot(id, Type, iEntity)) > 0)
            ham_strip_user_weapon(id, iWeapon, Type, bSwitchIfActive);
        
        return 1;
    }
    
    return 0;
}
    
        
/*
 | bugsy
 | http://forums.alliedmods.net/showpost.php?p=1575989&postcount=2
*/
stock GetWeaponFromSlot( id , iSlot , &iEntity )
{
    if ( !( 1 <= iSlot <= 5 ) )
        return 0;
    
    iEntity = 0;
    const m_rgpPlayerItems_Slot0 = 367;
    const m_iId = 43;
    const EXTRAOFFSET_WEAPONS = 4;
    
    iEntity = get_pdata_cbase( id , m_rgpPlayerItems_Slot0 + iSlot , EXTRAOFFSET_WEAPONS );
    
    return ( iEntity > 0 ) ? get_pdata_int( iEntity , m_iId , EXTRAOFFSET_WEAPONS ) : 0;
}  


/*
 | ConnorMcLeod
 | http://forums.alliedmods.net/showpost.php?p=1109747&postcount=42
*/
stock ham_strip_user_weapon(id, iCswId, iSlot = 0, bool:bSwitchIfActive = true)
{
    new iWeapon
    if( !iSlot )
    {
        static const iWeaponsSlots[] = {
            -1,
            2, //CSW_P228
            -1,
            1, //CSW_SCOUT
            4, //CSW_HEGRENADE
            1, //CSW_XM1014
            5, //CSW_C4
            1, //CSW_MAC10
            1, //CSW_AUG
            4, //CSW_SMOKEGRENADE
            2, //CSW_ELITE
            2, //CSW_FIVESEVEN
            1, //CSW_UMP45
            1, //CSW_SG550
            1, //CSW_GALIL
            1, //CSW_FAMAS
            2, //CSW_USP
            2, //CSW_GLOCK18
            1, //CSW_AWP
            1, //CSW_MP5NAVY
            1, //CSW_M249
            1, //CSW_M3
            1, //CSW_M4A1
            1, //CSW_TMP
            1, //CSW_G3SG1
            4, //CSW_FLASHBANG
            2, //CSW_DEAGLE
            1, //CSW_SG552
            1, //CSW_AK47
            3, //CSW_KNIFE
            1 //CSW_P90
        }
        iSlot = iWeaponsSlots[iCswId]
    }

    const XTRA_OFS_PLAYER = 5
    const m_rgpPlayerItems_Slot0 = 367

    iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_Slot0 + iSlot, XTRA_OFS_PLAYER)

    const XTRA_OFS_WEAPON = 4
    const m_pNext = 42
    const m_iId = 43

    while( iWeapon > 0 )
    {
        if( get_pdata_int(iWeapon, m_iId, XTRA_OFS_WEAPON) == iCswId )
        {
            break
        }
        iWeapon = get_pdata_cbase(iWeapon, m_pNext, XTRA_OFS_WEAPON)
    }

    if( iWeapon > 0 )
    {
        const m_pActiveItem = 373
        if( bSwitchIfActive && get_pdata_cbase(id, m_pActiveItem, XTRA_OFS_PLAYER) == iWeapon )
        {
            ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon)
        }

        if( ExecuteHamB(Ham_RemovePlayerItem, id, iWeapon) )
        {
            user_has_weapon(id, iCswId, 0)
            ExecuteHamB(Ham_Item_Kill, iWeapon)
            return 1
        }
    }

    return 0
}  
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1063\\ f0\\ fs16 \n\\ par }
*/
