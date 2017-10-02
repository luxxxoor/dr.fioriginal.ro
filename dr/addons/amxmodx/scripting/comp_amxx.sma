#include <amxmodx>
#include <amxmisc>

#define bug

public plugin_init()
{
	register_plugin("bug test", "1.0", "nobody");
}

public client_connect( id )
	{
	new name[ MAX_NAME_LENGTH ];
	get_user_name( id, name, charsmax( name ) );
	new s_name[ MAX_NAME_LENGTH ];
	copy( s_name, charsmax( name ), name );
	for( new i; i < sizeof( s_name ); i++ )  
		{
		#if defined bug
		server_print("debug : i = %d; i+1 = %d", i, i+1);
			for( new i; i < sizeof( s_name ); i++ )  
			{
			if( i < 31)
				if( s_name[ i ] == '#')
				if(!isspace(s_name[ i+1 ]))
				{
				s_name[ i ] = ' ';
			}
		}
		}
		#else
		new j = i+1;
		
		server_print("debug : i = %d; j = %d", i, j);
		if( i < charsmax(s_name) -1 )
		{
			if( s_name[ i ] == 'a')
				if(!isspace(s_name[ j ]))
          client_print(id, print_console, "hello");
			server_print("debug : s_name[i] = %c; s_name[j] = %c", s_name[ i ], s_name[ j ]);
		}
		#endif
		
	}
