#include <amxmodx>

public plugin_init()
{
	register_plugin("Map Scheduler", "1.0", "Author");

	set_task(60.0, "task_check_time", 38427236, _, _, "b")
}

public task_check_time()
{
	new a[6];
	get_time("%H:%M", a, 5);

	if (equal(a, "23:59"))
	{
		client_print_color(0, print_team_red, "^3[Cs.FioriGinal.Ro] ^4Este ora 23:59! Serverul trece pe setarile de noapte.");
	}

	if (equal(a, "00:00"))
	{
		server_cmd("changelevel de_dust2x2");
	}

	if (equal(a, "00:05"))
	{
		server_cmd("mp_timelimit 0")
		server_cmd("amx_pausecfg stop adminvote");
		server_cmd("amx_pausecfg stop mapchooser");
		server_cmd("amx_pausecfg stop mapsmenu");
	}

	if (equal(a, "03:00"))
	{
		server_cmd("changelevel fy_snow");
	}

	if (equal(a, "03:05"))
	{
		server_cmd("mp_timelimit 0")
		server_cmd("amx_pausecfg stop adminvote");
		server_cmd("amx_pausecfg stop mapchooser");
		server_cmd("amx_pausecfg stop mapsmenu");
	}

	if (equal(a, "07:00"))
	{
		server_cmd("changelevel de_dust2x2");
	}

	if (equal(a, "07:05"))
	{
		server_cmd("mp_timelimit 0");
		server_cmd("amx_pausecfg stop adminvote");
		server_cmd("amx_pausecfg stop mapchooser");
		server_cmd("amx_pausecfg stop mapsmenu");
	}

	if (equal(a, "07:50"))
	{
		server_cmd("amx_map de_dust2");
	}

	if (equal(a, "07:55"))
	{
		server_cmd("exec server.cfg");
	}

	if (equal(a, "08:00"))
	{
		client_print_color(0, print_team_red, "^3[Cs.FioriGinal.Ro] ^4Este ora 08:00 ! Serverul trece pe setarile de zi.");
	}
}