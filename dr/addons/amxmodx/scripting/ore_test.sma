#include <amxmodx>
#include <http>
#include <regex>

new Results[6][32];

enum patternsEnum {
    Prefix[32],
    Pattern[128]
}

new Info[][patternsEnum] = {
    { "First Seen:",        "\w{3} [0-3][0-9], [12][019][0-9][0-9]" },
    { "Last Seen:",   "Online Now|(((Yester|To)day)|(\w{3} [0-3][0-9], [12][019][0-9][0-9])) (1[0-2]|[0-9]):[0-5]\d [A|P]M" },
    { "Score:",    "(?<=\s)\d+" },
    { "Minutes Played:",    "(?<=\s)\d+" },
    { "Score per Minute:",  "(?<=\s)\d+\.?\d?" },
    { "Rank on Server:",    "#\d+ out of \d+" }
}
public plugin_init() {
    register_plugin("Test Plugin 9", "", "");
    
    HTTP_DownloadFile("http://www.gametracker.com/player/anca/89.40.233.75:27015/", "result.txt");
}

public HTTP_Download(const szFile[] , iDownloadID , iBytesRecv , iFileSize , bool:TransferComplete) {
    
    if ( ! TransferComplete )
        return;
    
    new hFile = fopen(szFile, "r");
    new num, i, bool: searching;
    new buffer[1024], error[128];

    if ( ! hFile )
        return;
    
    while ( ! feof(hFile) && i < sizeof Info ) {
        fgets(hFile, buffer, charsmax(buffer));
        
        if ( ! searching && contain(buffer, Info[i][Prefix]) != -1 )
        searching = true;
        
        if ( searching ) {
            
            new Regex:hRegex = regex_match(buffer, Info[i][Pattern], num, error, 127);
            
            if ( hRegex >= REGEX_OK ) {
                regex_substr(hRegex, 0, Results[i], 31);
                server_print("%s %s", Info[i][Prefix], Results[i]);
                regex_free(hRegex);
                i++;
                searching = false;
            }
        }
    }
    fclose(hFile)
    
    delete_file(szFile);
}