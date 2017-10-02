#include <amxmodx>
#include <amxmisc>

#define ADVERTISING_TIME 149.0


stock const messages[][] = {

"* Daca vreti sa fiti unul din ADMINI uitati-va la preturile rangurilor tastand !preturi"

}



public plugin_init() {
	register_plugin("Preturi Ranguri (motd)","1.1","Adi kriSTian")
	register_clcmd ("say !preturi" , "preturi_ranguri_motd" , -1);
	register_clcmd ("say_team !preturi" , "preturi_ranguri_motd" , -1);
        set_task(ADVERTISING_TIME, "show_messages", _, _, _,"b");
}

public preturi_ranguri_motd(id) show_motd(id,"/addons/amxmodx/configs/motd/preturi_ranguri_motd.html")

public show_messages()
{
new Buffer[256];
formatex(Buffer, sizeof Buffer - 1, "^x02%s", messages[random(sizeof messages)]);

new players[32], num, id;
get_players(players, num);

for(new i = 0 ; i < num ; i++)
{
id = players[i]

message_begin(MSG_ONE, get_user_msgid("SayText"), _, id);
write_byte(id);
write_string(Buffer);
message_end();
}
}
