#include <amxmisc>    

#define PLUGIN "Slay/Slay Team"
#define VERSION "1.0"
#define AUTHOR "Dr.FioriGinal.Ro"   

#pragma semicolon 1
 
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_concmd("amx_slayteam","slayteam",ADMIN_KICK,"< #ALL, #CT sau #T >");    
	register_concmd("amx_slapteam","slapteam",ADMIN_KICK,"< #ALL, #CT sau #T >");  
}


public slayteam(id,level,cid){ 
	if (!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;  
	
	new arg[32], AdminName[32];
	read_argv(1,arg,charsmax(arg));
	get_user_name(id, AdminName, charsmax(AdminName));
	
	if(arg[0]=='#')
	{
		new players[MAX_PLAYERS], totalplayers;
		if ( equal(arg, "#ALL", strlen("#ALL")) )
		{   
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				user_silentkill(players[i]);
				
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				if(players[i])
					if (is_user_admin(players[i]))
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 (%s) %s :^3 a dat slay la toţi jucătorii !", Admin_Rank(id), AdminName);
					else 
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 ADMIN :^3 slay la toţi jucătorii !");
						
			return PLUGIN_HANDLED; 
		}
		if ( equal(arg, "#T", strlen("#T")) )
		{
			get_players(players, totalplayers, "e", "TERRORIST");  
			for(new i; i <= totalplayers; ++i)
				user_silentkill(players[i]);	
				
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				if(players[i])
					if (is_user_admin(players[i]))
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 (%s) %s :^3 a dat slay la toţi teroriştii !", Admin_Rank(id), AdminName);
					else
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 ADMIN :^3 slay la toţi teroriştii !");
			return PLUGIN_HANDLED; 
		}
		if ( equal(arg, "#CT", strlen("#CT")) )
		{
			get_players(players, totalplayers, "e", "CT");      
			for(new i; i <= totalplayers; ++i)
				user_silentkill(players[i]);
				
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				if(players[i])
					if (is_user_admin(players[i]))
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 (%s) %s :^3 a dat slay la toţi counterii !",Admin_Rank(id), AdminName);
					else
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 ADMIN :^3 slay la toţi counterii !");
		}
		return PLUGIN_HANDLED; 
	}
	return PLUGIN_CONTINUE;
}

public slapteam(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))
		return PLUGIN_HANDLED;
	
	new arg[32], AdminName[32];
	read_argv(1,arg,charsmax(arg));
	get_user_name(id, AdminName, charsmax(AdminName));
	
	if(arg[0]=='#')
	{ 
		new players[MAX_PLAYERS], totalplayers;
		if ( equal(arg, "#ALL", strlen("#ALL")) )
		{    
			get_players(players, totalplayers);
			for (new i; i <= totalplayers; ++i)
				user_slap(players[i],0 ,1);
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				if(players[i])
					if (is_user_admin(players[i]))
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 (%s) %s :^3 a dat slap la toţi jucătorii !",Admin_Rank(id), AdminName);
					else
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 ADMIN :^3 slap la toţi jucătorii !");
						
			return PLUGIN_HANDLED; 
		}
		if ( equal(arg, "#T", strlen("#T")) )
		{
			get_players(players, totalplayers, "e", "TERRORIST");   
			for(new i; i <= totalplayers; ++i)
				user_slap(players[i],0 ,1);
				
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				if(players[i])
					if (is_user_admin(players[i]))
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 (%s) %s :^3 a dat slap la toţi teroriştii !", Admin_Rank(id), AdminName);
					else
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 ADMIN :^3 slap la toţi teroriştii !");

			return PLUGIN_HANDLED; 
		}
		if ( equal(arg, "#CT", strlen("#CT")) )
		{
			get_players(players, totalplayers, "e", "CT");        
			for(new i; i <= totalplayers; ++i)
				user_slap(players[i],0 ,1);
				
			get_players(players, totalplayers);
			for(new i; i <= totalplayers; ++i)
				if(players[i])
					if (is_user_admin(players[i]))
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 (%s) %s :^3 a dat slap la toţi counterii !",Admin_Rank(id) , AdminName);
					else
						client_print_color( players[i], print_team_grey,"^4 [Dr.FioriGinal.Ro] ^3 ADMIN :^3 slap la toţi counterii !");
			
			return PLUGIN_HANDLED; 
		}
	}
	return PLUGIN_CONTINUE;
}
