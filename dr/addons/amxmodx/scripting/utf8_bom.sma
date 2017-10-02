#include < amxmodx > 

// #pragma semicolon 1 

#define PLUGIN "17b Res utf BOM remover" 
#define VERSION "0.0.1" 

new Trie:g_tDefaultRes 

public plugin_init() 
{ 
    register_plugin( PLUGIN, VERSION, "ConnorMcLeod" ); 
    g_tDefaultRes = TrieCreate() 
    TrieSetCell( g_tDefaultRes , "de_storm.res", 1); 
    TrieSetCell( g_tDefaultRes , "default.res", 1); 

    set_task(10.0, "Clean_Res_Files"); 
} 

public Clean_Res_Files() 
{ 
    new szMapsFolder[] = "maps"; 
    new const szResExt[] = ".res"; 
    new szResFile[64], iLen; 
    new dp = open_dir(szMapsFolder, szResFile, charsmax(szResFile)); 
     
    if( !dp ) 
    { 
        return; 
    } 

    // server_print("Opening %s folder (%s)", szMapsFolder, szResFile) 
    new szFullPathFileName[128]; 
    do 
    { 
        // server_print("Proceeding %s", szResFile) 
        iLen = strlen(szResFile) 
        if( iLen > 4 && equali(szResFile[iLen-4], szResExt) ) 
        { 
            if( TrieKeyExists(g_tDefaultRes, szResFile) ) 
            { 
                // server_print("Default %s file, continuing...", szResFile) 
                continue 
            } 
             
            formatex(szFullPathFileName, charsmax(szFullPathFileName), "%s/%s", szMapsFolder, szResFile) 
            write_file(szFullPathFileName, "/////////////////////////////////////////////////////////////^n", 0); 
            server_print("Proceeded %s", szResFile); 
        } 
    } 
    while( next_file(dp, szResFile, charsmax(szResFile)) ) 
     
    close_dir(dp) 
}  