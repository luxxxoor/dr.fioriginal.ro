#include <amxmisc>
#include <engine>
#include <fakemeta>

public plugin_init() 
{
	register_plugin("da", "1.0", "nu");
	register_forward(FM_Touch, "test1")
	//register_touch("trigger_hurt", "player", "test1");
	register_clcmd("bartime", "test");
}

public test1(Entity, Index)
{
	new Classname[33];
	pev(Entity, pev_classname, Classname, charsmax(Classname));
	if(equal(Classname, "trigger_hurt"))
	{
		if (task_exists(Index))
			return;
		MakeBarTime(Index, 10);
		set_task(9.9, "DestroyBarTime", Index);
	}
	/*else 
	{
		DestroyBarTime(Index);
	}*/
}

public test(Index)
{
	new data[12]
	read_argv(1, data, charsmax(data));
	MakeBarTime(Index, str_to_num(data));
	read_argv(2, data, charsmax(data));
	set_task(float(str_to_num(data)), "DestroyBarTime", Index);
}

public MakeBarTime(Index, iBarScale) // cu asta faci bartime
{
	static BarTimeMessage;
	if (!BarTimeMessage)
	{
		BarTimeMessage = get_user_msgid("BarTime");
	}
	
	message_begin(MSG_ONE, BarTimeMessage, _, Index);
	write_short(iBarScale);
	message_end();
}

public DestroyBarTime(Index) 
{
	static BarTimeMessage;
	if (!BarTimeMessage)
	{
		BarTimeMessage = get_user_msgid("BarTime");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, BarTimeMessage, _, Index);
	write_short(0);
	message_end();
} 

