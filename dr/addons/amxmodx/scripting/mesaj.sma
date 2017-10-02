#include <amxmisc>

public plugin_init()
{
	register_plugin("Mesaj Concurs", "1.0", "Gg.FioriGinal.Ro");
	set_task(60.0, "showMessage", _, _, _, "b");
}

public showMessage()
{
	client_print_color(0, print_team_grey,  "^4[CONCURS^1 2^4 Top15]^3Locul 1 licenta ^4CS 1.6^3 ,Locul 2 ^4Locotenent^3 ,Locul 3 ^4Sergent^3.Pentru detalii accesati forumul.");
}