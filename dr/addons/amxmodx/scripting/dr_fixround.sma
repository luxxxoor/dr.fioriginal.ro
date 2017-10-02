#include <amxmisc>
#include <cstrike>
#include <hamsandwich>

public plugin_init() 
{
	register_plugin
	(
		.plugin_name = "DeathRun fix round",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
}

public client_disconnected(Index)
{
	new Players[MAX_PLAYERS], MatchedPlayers;
	get_players(Players, MatchedPlayers, "ce", "TERRORIST");
	if (MatchedPlayers == 1) // in unele situatii detecteaza ca este pe server, in altele nu-l detecteaza, conteaza cum se deconecteaza.
	{
		if (Players[0] == Index)
		{
			MatchedPlayers = 0;
		}
	}
	if (MatchedPlayers == 0)
	{
		setNewTerrorist(Index);
		
		static Refuses, Responsed, InNewTeroCourse, Rejected;
		if (Refuses == 0)
		{
			Refuses = get_xvar_id("Refuses");
		}
		if (Responsed == 0)
		{
			Responsed = get_xvar_id("Responsed");
		}
		if (InNewTeroCourse == 0)
		{
			InNewTeroCourse = get_xvar_id("InNewTeroCourse");
		}
		if (Rejected == 0)
		{
			Rejected = get_xvar_id("Rejected");
		}
		
		if (Refuses != -1 && Responsed != -1 && InNewTeroCourse != -1 && Rejected != -1)
		{
			set_xvar_num(Refuses, 0);
			set_xvar_num(Responsed, 0);
			set_xvar_num(InNewTeroCourse, -1);
			set_xvar_num(Rejected, 0);
		}
	}
}

setNewTerrorist(OldTerrorIndex)
{
	if (get_playersnum() <= 1)
	{
		return;
	}
	
	new Players[MAX_PLAYERS], MatchedPlayers;
	get_players(Players, MatchedPlayers, "bce", "CT");
	if (MatchedPlayers == 0)
	{
		get_players(Players, MatchedPlayers, "ce", "CT");
		if (MatchedPlayers == 0)
		{
			return;
		}
	}
	new NewTerorIndex = Players[random(MatchedPlayers)];
	cs_set_user_team(NewTerorIndex, CS_TEAM_T);
	ExecuteHamB(Ham_CS_RoundRespawn, NewTerorIndex);
	new OldTerrorName[MAX_NAME_LENGTH], NewTerrorName[MAX_NAME_LENGTH];
	get_user_name(OldTerrorIndex, OldTerrorName, charsmax(OldTerrorName));
	get_user_name(NewTerorIndex, NewTerrorName, charsmax(NewTerrorName));
	client_print_color(0, print_team_red, "^4[Dr.FioriGinal.Ro]^1 ^3%s^1 este noul terorist deoarece ^3%s^1 s-a deconectat.", NewTerrorName, OldTerrorName);
}