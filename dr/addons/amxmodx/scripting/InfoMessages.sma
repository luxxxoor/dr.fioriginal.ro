#include <amxmisc>

new Array:Messages, Array:QuerryMessages;

public plugin_init()
{
	register_plugin
	(
		.plugin_name = "Info Messages",
		.version     = "1.0",
		.author      = "Dr.FioriGinal.Ro"
	);
	
	Messages = ArrayCreate(192);
	QuerryMessages = ArrayCreate(192);
	
	loadMessages();
	set_task(120.0, "showMessage");
}

public showMessage()
{
	new Message[192];
	if (ArraySize(QuerryMessages) == 0)
	{
		QuerryMessages = ArrayClone(Messages);
	}
	
	ArrayGetString(QuerryMessages, 0, Message, charsmax(Message));
	ArrayDeleteItem(QuerryMessages, 0);
	
	client_print_color(0, print_team_grey, Message);
	set_task(60.0, "showMessage");
}

loadMessages()
{
	new Path[64];
	get_localinfo("amxx_configsdir", Path, charsmax(Path));
	add(Path, charsmax(Path), "/info_messages.ini");
	
	new FilePointer = fopen(Path, "r+");
	
	if (!FilePointer)
	{
		set_fail_state("Nu s-a gasit fisierul cu mesaje.");
		return;
	}

	new Text[192];

	for (new i; !feof(FilePointer); ++i)
	{
		fgets(FilePointer, Text, charsmax(Text));
		
		trim(Text);
		
		if ( (Text[0] == ';') || !strlen(Text) )
		{
			continue;
		}
		
		replace_string(Text, charsmax(Text), "^^4", "^4");
		replace_string(Text, charsmax(Text), "^^3", "^3");
		replace_string(Text, charsmax(Text), "^^1", "^1");
		
		ArrayPushString(Messages, Text);
		ArrayPushString(QuerryMessages, Text);
	}
	
	fclose(FilePointer);
	
	if(ArraySize(Messages) == 0)
	{
		set_fail_state("Nu s-au gasit mesaje.");
	}
}