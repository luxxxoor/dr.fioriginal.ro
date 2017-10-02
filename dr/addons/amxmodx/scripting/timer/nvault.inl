/*
* Nvault Include for DeathRunTimer
* nvault.inl (C) by Knopers
*
* Site : http://amxx.pl/deathrun-timer-save-records-t31649.html
* Author : Knopers
* Fixed : raggy, www.rayish.com
*/
 
#include <nvault>
#define _Timer_Save2Nvault 1
 
new h_vault;
 
public SaveRecord()
{
        new sData[128];
       
        //format(sData, 127,"^"%s^" ^"%02d^"", sBest, iBest); formatex can be used here and should be as it is faster, also change %02d to %d because the fist only formats the first 2 digits from iBest
        formatex(sData, 127,"^"%s^" ^"%d^"", sBest, iBest);
       
        nvault_set(h_vault, sMap, sData);
       
        //return PLUGIN_CONTINUE unnecessary, nothing uses this return
}
 
public LoadRecord()
{
        new sData[128];
       
        //format(sData, 127,"^"%s^" ^"%02d^"", sBest, iBest); <- wtf, unnecessary
        nvault_get(h_vault, sMap, sData, 127);
       
        //new RecordName[64], RecordS[3]; RecordS size is too small for bigger values, a size of 3 only fits 2 digits ie: 99
        new RecordName[64], RecordS[5];
       
        //parse(sData, RecordName, 63, RecordS, 2); Increase the writeable size here too
        parse(sData, RecordName, 63, RecordS, 4);
       
        sBest = RecordName;
        iBest = str_to_num(RecordS);
       
        //return PLUGIN_CONTINUE; unnecessary, nothing uses this return
}