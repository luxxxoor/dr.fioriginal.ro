#include <amxmisc>

new const SmokeFile[] = "sprites/gas_puff_01.spr"

public plugin_init()
{
	register_plugin("Anti-Smoke Detector","1.0", "Cs.FioriGinal.Ro");
}
public plugin_precache()
{
    force_unmodified(force_exactfile, {0,0,0},{0,0,0}, SmokeFile);
}

public inconsistent_file(Index, const FileName[], Reason[64]) 
{
    if( equal(FileName, SmokeFile) ) 
    {
		copy(Reason, charsmax(Reason), "^nSpite-ul tau de smoke nu este cel original");
    }
}  
