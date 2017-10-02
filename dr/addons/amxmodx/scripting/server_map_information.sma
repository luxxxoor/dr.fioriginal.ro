#include <amxmodx>
#include <amxmisc>

#pragma semicolon 1


#define PLUGIN "Server's Map Information"
#define VERSION "1.1.1"

#define		iMapsToSave	10

new g_szFile[64];

new g_szMapsName[iMapsToSave][32], g_iMapPlayersRec[iMapsToSave], g_iMapPlayedTime[iMapsToSave], g_iMapSysTime[iMapsToSave];
new g_iMapsNum, g_iMaxPlayers, g_iPlayers, g_iPlayersRecord, g_iCvarUrl, g_szMapName[32];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, "Ulquiorra" );
	register_cvar( "smi_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY ); 
	
	register_clcmd( "say !harti", "cmd_MapsInfo" );
	
	g_iCvarUrl = register_cvar( "smi_script_url", "http://ulqtech.tk/smi/smi.php" );
	
	get_localinfo("amxx_configsdir", g_szFile, charsmax(g_szFile));
	add(g_szFile, charsmax( g_szFile ), "/LastPlayedMaps.txt");
	
	for(new i = 0; i < iMapsToSave; i++)
	{
		g_szMapsName[i] = "NoMap";
		g_iMapPlayedTime[i] = -999;
		g_iMapPlayersRec[i] = -999;
		g_iMapSysTime[i] = -999;
	}
	
	new iFile = fopen(g_szFile, "rt");
	
	if (iFile)
	{
		new szBuffer[ 128 ], szData[ 3 ][ 32 ];// 0 = Played Time, 1 = Player record, 2 = SysTime to get the mins ago.
		while (!feof( iFile ) && g_iMapsNum < iMapsToSave)
		{
			fgets(iFile, szBuffer, charsmax(szBuffer));
			trim(szBuffer);
			
			if (szBuffer[0])
			{
				parse(szBuffer,\
				g_szMapsName[g_iMapsNum], charsmax(g_szMapsName[]),\
				szData[0], charsmax(szData[]),\
				szData[1], charsmax(szData[]),\
				szData[2], charsmax(szData[]));
				
				g_iMapPlayedTime[g_iMapsNum] = str_to_num(szData[0]);
				g_iMapPlayersRec[g_iMapsNum] = str_to_num(szData[1]);
				g_iMapSysTime[g_iMapsNum] = str_to_num(szData[2]);
				g_iMapsNum++;
			}
		}
		
		fclose(iFile);
	}
	
	g_iMaxPlayers = get_maxplayers();
	get_mapname(g_szMapName, charsmax(g_szMapName));
}

public client_putinserver(id)
{
	if ( is_user_bot(id) || is_user_hltv(id) )
		return;
		
	if ( ++g_iPlayers > g_iPlayersRecord )
		g_iPlayersRecord = g_iPlayers;
		
}

public client_disconnect( id )
{
	if( is_user_bot( id ) || is_user_hltv( id ) )
		return;
		
	if( --g_iPlayers < 0 )
		g_iPlayers = 0;
		
}

public cmd_MapsInfo( id )
{	
	new iMinutes, iTimeLeft, szNextMap[32], szUrl[64];
	
	iMinutes = floatround(get_gametime() / 60.0, floatround_ceil);
	iTimeLeft = get_timeleft() / 60;
	
	get_cvar_string("amx_nextmap", szNextMap, charsmax(szNextMap));
	get_pcvar_string(g_iCvarUrl, szUrl, charsmax(szUrl));
	
	if ( !szNextMap[0] )
		szNextMap = "Not voted yet";
		
	new szBuffer[2500], szMapInfo[128], i, iSysTime;
	formatex(szBuffer, charsmax( szBuffer ), "%s?cr_mn=%s&cr_pt=%i&nm_mn=%s&nm_tl=%i", 
		szUrl, g_szMapName, iMinutes, szNextMap, iTimeLeft);
		
	iSysTime = get_systime();
	for( i = 0; i < g_iMapsNum; i++ )
	{		
		formatex( szMapInfo, charsmax(szMapInfo), "&m%i_pt=%i&m%i_pr=%i/%i&m%i_mn=%s&m%i_tago=%i",
			i, g_iMapPlayedTime[i], i, g_iMapPlayersRec[i],\
			g_iMaxPlayers, i, g_szMapsName[i],\
			i, (iSysTime - g_iMapSysTime[i]) / 60 );
				
		add(szBuffer, charsmax(szBuffer), szMapInfo);
	}
	
	//log_amx( szBuffer );
	show_motd(id, szBuffer, "Server's Map Info");
	
}

public plugin_end(  )
{
	new iMinutes, iFile;
	iMinutes = floatround( get_gametime(  ) / 60.0, floatround_ceil );
	
	iFile = fopen( g_szFile, "wt" );
	if( iFile )
	{
		fprintf(iFile, "^"%s^" ^"%i^" ^"%i^" ^"%i^"", g_szMapName, iMinutes, g_iPlayersRecord, get_systime());
	
		if ( g_iMapsNum == iMapsToSave )
			g_iMapsNum--;
	
		for (new i = 0; i < g_iMapsNum; i++) 
			fprintf(iFile, "^n^"%s^" ^"%i^" ^"%i^" ^"%i^"", g_szMapsName[i], g_iMapPlayedTime[i], g_iMapPlayersRec[i], g_iMapSysTime[i]);
	
		fclose(iFile);
	}
}