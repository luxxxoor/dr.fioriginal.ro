#include <amxmisc>

new bool:isnotAfk[MAX_PLAYERS+1];

public plugin_init()
{
	register_plugin("Menu Bug Test", "1.0", "luxor");
	register_clcmd("say", "hookChat");
	
	register_logevent("roundStart", 2, "1=Round_Start"); // we will suppose that part will be the mapchooser menu, but it will be called at every round start.
}
public roundStart() 
{
	show_menu( 0, 0, "^n", 1 ); // please notice that part is not for destroying the menu, imagine this like a mapchooser or any another base vote command.
}

public hookChat(id)
{
	new word[12];
	read_args(word, charsmax(word));
	
	if ( !word[0] )
	{
		return PLUGIN_CONTINUE;
	}
	
	remove_quotes(word);
	
	new const testIdent[] = "!test";
	
	if ( equal(word, testIdent, charsmax(testIdent)) )
	{
		testMenu(id);
		client_print(0, print_chat, "Now plese don't choose any item from the menu, just type kill in console as quick as you can.");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public testMenu(id)
{
	client_print(0, print_chat, "TestMenu called");
	new Menu = menu_create("Test title", "answerMenu");
	menu_additem(Menu, "Test item #1", "1", 0);
	menu_additem(Menu, "Test item #2", "2", 0);
	menu_additem(Menu, "Test item #3", "3", 0);
	menu_additem(Menu, "Test item #4", "4", 0);
	menu_setprop(Menu, MPROP_EXIT , MEXIT_ALL);
	menu_display(id, Menu, 0);
	
	new index[10];
	num_to_str(id, index, charsmax(index));
	isnotAfk[id] = false;
	set_task(15.0, "autoRefuse", Menu, index, charsmax(index));
}

public answerMenu(id, Menu, item)
{
	client_print(0, print_chat, "answerMenu called");
	new data[6];
	new _acces, item_callback;
	menu_item_getinfo(Menu, item, _acces, data, charsmax(data), _, _, item_callback);

	new Key = str_to_num(data);

	if ( item == MENU_EXIT )
	{
		client_print(0, print_chat, "NewMenu exit.");
		menu_destroy(Menu);
		return PLUGIN_HANDLED;
	}
	
	switch (Key)
	{
		case 1:
		{
			client_print(0, print_chat, "TestItem #1");
		}
		case 2:
		{
			client_print(0, print_chat, "TestItem #2");
		}
		case 3:
		{
			client_print(0, print_chat, "TestItem #3");
		}
		case 4:
		{
			client_print(0, print_chat, "TestItem #4");
		}
	}
	
	isnotAfk[id] = true;
	
	menu_destroy(Menu);
	return PLUGIN_HANDLED;
}

public autoRefuse(index[], Menu)
{
	client_print(0, print_chat, "autoRefuse called");
	new id = str_to_num(index);
	if ( !isnotAfk[id] )
	{
		client_print(0, print_chat, "Menu will destroy.");
		menu_destroy(Menu);
		client_print(0, print_chat, "Menu is destroyed.");
	}
}