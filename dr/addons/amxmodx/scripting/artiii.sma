#include <amxmisc>

new CvarPointer, Float:CvarValue, cvarhook:HoockedCvar;

public plugin_init()
{
	CvarPointer = create_cvar("cvar_de_test", "5.0", FCVAR_NONE, "Acest cvar este creat pentru un test.", true, 0.0, true, 10.0);
//                      numele cvar-ului - valoarea - flagurile - descrierea cvar-ului -  admite minim - valoare - admite maxim - valoare

	bind_pcvar_float(CvarPointer, CvarValue); // variabila globala CvarValue va avea salvanta in ea mereu valoarea acestui cvar.
	HoockedCvar = hook_cvar_change(CvarPointer, "cvarValueChanged");
}


public clinet_putinserver(id)
{
	set_task(CvarValue, "testFunction", id);
	enable_cvar_hook(HoockedCvar); // repornim hook-ul cvar-ului
}

public testFunction(id)
{
	client_print_color(id, print_team_blue, "^3[^4Info^3] ^1 Bun venit pe server %n");
	server_print("acest mesaj a aparut in %f secunde de la conectarea pe server.", CvarValue);
}

public cvarValueChanged(pcvar, const old_value[], const new_value[])
{
	server_print("Valoarea cvar-ului ^"cvar_de_test^" si-a schimbat valoarea din %s in %s", old_value, new_value);
	disable_cvar_hook(HoockedCvar); // oprim hook-ul cvar-ului
}