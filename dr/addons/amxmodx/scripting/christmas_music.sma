#include <amxmisc> //0757222715

new Array:Music;

enum _:Mp3Data
{
	Name[54],
	Path[128]
}

public plugin_precache()
{
	Music = ArrayCreate(Mp3Data);
	readFromDir();
}

public plugin_init( )
{
	register_plugin("Christmas Songs", "0.1", "Cs.FioriGinal.Ro");
	register_clcmd("say", "handleChat");
}

public plugin_end( )
{
    ArrayDestroy(Music);
}

readFromDir()
{
	new Dir[128];
	formatex(Dir, charsmax(Dir), "sound/Christmas_Songs");
	
	new const Mp3Ext[] = ".mp3"; 
	new Mp3File[64], Len;
	new DirPointer = open_dir(Dir, Mp3File, charsmax(Mp3File)); 
	
	if ( !DirPointer )
	{
		return; 
	}
	
	new Data[Mp3Data], Precache[128];
	
	formatex(Data[Path], charsmax(Data[Path]), "%s/%s", Dir, "/stop.mp3");
	if ( file_exists(Data[Path]) )
	{
		precache_sound("Christmas_Songs/stop.mp3");
		formatex(Data[Name], charsmax(Data[Name]), "Stop Music");
		ArrayPushArray(Music, Data, charsmax(Data));
	}
	
	do 
	{ 
		Len = strlen(Mp3File);
		if ( equali(Mp3File, "stop.mp3") )
		{
			continue;
		}
		
		if ( Len > 4 && equali(Mp3File[Len-4], Mp3Ext) ) 
		{ 
			//add prin array
			formatex(Data[Path], charsmax(Data[Path]), "%s/%s", Dir, Mp3File);
			copy(Data[Name], charsmax(Data[Name]), Mp3File);
			Data[Name][strlen(Data[Name])-4] = '^0';
			formatex(Precache, charsmax(Precache), "Christmas_Songs/%s", Mp3File);
			server_print(Precache);
			precache_sound(Precache);
			
			ArrayPushArray(Music, Data, charsmax(Data));
		} 
	} 
	while ( next_file(DirPointer, Mp3File, charsmax(Mp3File)) );
	
	close_dir(DirPointer);
}

public handleChat(Index)
{
	new Said[10];
	read_argv(1, Said, charsmax(Said));
	
	if ( Said[0] != '/' )
	{
		return PLUGIN_CONTINUE;
	}
	
	if ( equali(Said[1], "music") )
	{
		new Data[Mp3Data], Menu = menu_create( "\yAlege o melodie pentru a o asculta:", "musicHandler" );
		
		for(new i = 0; i < ArraySize(Music); ++i) 
		{
			ArrayGetArray(Music, i, Data, charsmax(Data));
			replace_string(Data[Name], charsmax(Data[Name]), "_", " ");
			menu_additem(Menu, Data[Name]);
		}
		
		menu_display(Index, Menu);
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public musicHandler( Index, Menu, Item )
{
	if( Item != MENU_EXIT )
	{
		new Data[Mp3Data];
		ArrayGetArray(Music, Item, Data, charsmax(Data));
		server_print(Data[Path]);
		client_cmd(Index, "mp3 play ^"%s^"", Data[Path]);
	}
	
	menu_destroy( Menu )
	return PLUGIN_HANDLED;
}