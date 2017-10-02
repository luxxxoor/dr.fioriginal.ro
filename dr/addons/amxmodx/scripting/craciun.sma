#include <amxmodx>  
#include <hamsandwich>  
#include <nvault> 
#include <fakemeta>

new g_stats[33]; 
new g_szFile[ 128 ];

enum
{
	INFO_NAME,
	INFO_IP,
	INFO_AUTHID    
};

public plugin_precache( )
{
	get_localinfo( "amxx_configsdir", g_szFile, charsmax ( g_szFile ) );
	format( g_szFile, charsmax ( g_szFile ), "%s/lista_lui_mos_craciun.txt", g_szFile );	
	
	if( !file_exists( g_szFile ) )
	{
		write_file( g_szFile, "* Aici se afla lista lui Mos Craciun ! *", -1 );
		write_file( g_szFile, " ", -1 );
		write_file( g_szFile, " ", -1 );
	}
}

public plugin_init() {  
	register_plugin("VIP - Craciun.","0.1","[LF] | Dr.Freeman");  
	register_clcmd( "say", "HookChat");
	RegisterHam(Ham_Killed,"player","ololo");  
} 

public ololo(victim,attacker,shouldgib){  
	new wid,bh;
	new killer = get_user_attacker(victim,wid,bh); 
	if(!is_user_connected(killer)) 
		return PLUGIN_CONTINUE;
	if(g_stats[killer] > 50)
		return PLUGIN_CONTINUE;
	
	if(get_user_team(killer) == 2)
	{
		g_stats[killer]++;
		client_print_color( killer, print_team_blue, "^4[Dr.FioriGinal.Ro] : ^3Craciun fericit %s, ai facut %d/50 fraguri :D. Mult noroc in continuare.", GetInfo( killer, INFO_NAME ), g_stats[killer]);
	}
	
	if(g_stats[killer] == 50)
	{
		client_print_color( 0, print_team_blue, "^4[Dr.FioriGinal.Ro] : ^3Craciun fericit %s, tocmai ai fost trecut pe lista de cadouri a mosului :D.", GetInfo( killer, INFO_NAME ));
		LogCommand("NICK : %s | IP : %s ", GetInfo(killer, INFO_NAME), GetInfo(killer, INFO_IP));
	}
	
	
	return PLUGIN_CONTINUE;
}  



public client_putinserver(id){  
	new name[32];  
	get_user_name(id,name,charsmax(name));  
	
	g_stats[id] = LoadTime(id, name);
	
	return PLUGIN_CONTINUE; 
}  

public client_disconnect(id){  
	new name[32];  
	get_user_name(id,name,charsmax(name));  
	SaveTime(id, g_stats[id], name);
}

public HookChat(id)
{
	static said[ 192 ];
	read_args( said, charsmax( said ) );
	
	if( containi( said, "!fraguri" ) != -1)
	{
		client_print_color( id, print_team_blue, "^4[Dr.FioriGinal.Ro] : ^3Ai facut %d/50 fraguri, mult succes in continuare.", g_stats[id] );
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public ClientUserInfoChanged(id) 
{ 
	static const name[] = "name" 
	static szOldName[32], szNewName[32]
	pev(id, pev_netname, szOldName, charsmax(szOldName)) 
	if( szOldName[0] ) 
	{ 
		get_user_info(id, name, szNewName, charsmax(szNewName)) 
		if( !equal(szOldName, szNewName) ) 
			SaveTime(id, g_stats[id], szOldName);
	} 
	 
	g_stats[id] = LoadTime(id, szNewName);
	
	return FMRES_IGNORED 
}

LogCommand( const szMsg[ ], any:... )
{
	new szMessage[ 256 ], szLogMessage[ 256 ];
	vformat( szMessage, charsmax( szMessage ), szMsg , 2 );
	
	formatex( szLogMessage, charsmax( szLogMessage ), "%s%s", GetTime( ), szMessage );
	
	write_file( g_szFile, szLogMessage, -1 );
}

GetInfo( id, const iInfo )
{
	new szInfoToReturn[ 64 ];
	
	switch( iInfo )
	{
		case INFO_NAME:
		{
			static szName[ 32 ];
			get_user_name( id, szName, charsmax( szName ) );
			
			copy( szInfoToReturn, charsmax( szInfoToReturn ), szName );
		}
		case INFO_IP:
		{
			static szIp[ 32 ];
			get_user_ip( id, szIp, charsmax( szIp ), 1 );
			
			copy( szInfoToReturn, charsmax( szInfoToReturn ), szIp );
		}
		case INFO_AUTHID:
		{
			static szAuthId[ 35 ];
			get_user_authid( id, szAuthId, charsmax( szAuthId ) );
			
			copy( szInfoToReturn, charsmax( szInfoToReturn ), szAuthId );
		}
	}
	return szInfoToReturn;
}


GetTime( )
{
	static szTime[ 32 ];
	get_time( " %H:%M:%S ", szTime ,charsmax( szTime ) );
	
	return szTime;
}

public LoadTime( id, const name[] ) 
	{
	new valut = nvault_open("easy_stats");
	
	new vaultkey[64], vaultdata[64];
	
	format(vaultkey, 63, "FRAGS%s", name);
	
	nvault_get(valut, vaultkey, vaultdata, 63);
	nvault_close(valut);
	
	return  str_to_num(vaultdata);
}

public SaveTime( id, Frags, const name[] )
	{
	new valut = nvault_open("easy_stats");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle")
	
	new vaultkey[64], vaultdata[64];
	
	format(vaultkey, 63, "FRAGS%s", name); 
	format(vaultdata, 63, "%d", Frags); 
	
	nvault_set(valut, vaultkey, vaultdata);
	nvault_close(valut);
} 