#include <amxmodx>

#define HartiMaxime	5

new NumeHarti[HartiMaxime][34]

public plugin_init() {
	register_plugin("Ultimele Harti", "1.0", "M@$t3r_@dy")
	register_clcmd("say !harti", "HartiJucateCuSay")
}

public plugin_cfg() {
	new FisierHartiJucate[64]
	
	get_localinfo("amxx_configsdir", FisierHartiJucate, 63)
	format(FisierHartiJucate, 63, "%s/hartianterioare.txt", FisierHartiJucate)

	new File = fopen(FisierHartiJucate, "rt")
	new i
	new Temp[34]
	if(File)
	{
		for(i=0; i<HartiMaxime; i++)
		{
			if(!feof(File))
			{
				fgets(File, Temporar, charsmax(Temp));
				replace(Temporar, charsmax(Temp), "^n", "")
				formatex(NumeHarti[i], charsmax(NumeHarti[]), Temporar)
			}
		}
		fclose(File)
	}

	delete_file(FisierHartiJucate)

	new CurrentMap[34]
	get_mapname(CurrentMap, charsmax(CurrentMap))

	File = fopen(FisierHartiJucate, "wt")
	if(File)
	{
		formatex(Temporar, charsmax(Temp), "%s^n", CurrentMap)
		fputs(File, Temporar)
		for(i=0; i<HartiMaxime-1; i++)
		{
			CurrentMap = NumeHarti[i]
			if(!CurrentMap[0])
				break
			formatex(Temporar, charsmax(Temp), "%s^n", CurrentMap)
			fputs(File, Temporar)
		}
		fclose(File)
	}
}

public HartiJucateCuSay(id) {
	new HartiAnterioare[192], n
	n += formatex(HartiAnterioare[n], 191-n, "Hartile jucate anterior sunt :")
	for(new i; i<HartiMaxime; i++)
	{
		if(!NumeHarti[i][0])
		{
			n += formatex(HartiAnterioare[n-1], 191-n+1, ".")
			break
		}
		n += formatex(HartiAnterioare[n], 191-n, " %s%s", NumeHarti[i], i+1 == HartiMaxime ? "." : ",")
	}
	client_print(id, print_chat, HartiAnterioare)
	return PLUGIN_CONTINUE
}
