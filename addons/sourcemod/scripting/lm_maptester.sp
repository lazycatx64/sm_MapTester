
#include <sourcemod>

#define MSGTAG "[MapTester]"


ConVar g_hCvarMapTesterEnabled
bool g_bCvarMapTesterEnabled = false

ConVar g_hCvarChangeTime
float g_fCvarChangeTime = 10.0

ConVar g_hCvarMapList
char g_szCvarMapList[PLATFORM_MAX_PATH] = ""

char g_szNowTxt[PLATFORM_MAX_PATH]       = "now.txt"
char g_szBadTxt[PLATFORM_MAX_PATH]       = "bad.txt"
char g_szGoodTxt[PLATFORM_MAX_PATH]      = "good.txt"
char g_szMaplistTxt[PLATFORM_MAX_PATH]   = "maplist.txt"

char g_szDataFolder[PLATFORM_MAX_PATH]    = "data/maptester/"
char g_szMapsFolder[PLATFORM_MAX_PATH]    = "maps/"
char g_szMapcyclefile[PLATFORM_MAX_PATH]  = ""


public Plugin myinfo = {
	name = "Map Tester",
	author = "LaZycAt",
	description = "Map Tester that auto run through maps one by one.",
	version = "1.0.0",
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {

	LM_PrintToServerInfo("Map Tester loading...")

	g_hCvarMapTesterEnabled	= CreateConVar("lm_maptester_enabled", "1", "Set 1 to start the tester.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarMapTesterEnabled.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMapTesterEnabled)

	g_hCvarChangeTime	= CreateConVar("lm_maptester_changetime", "10", "After map loaded, X seconds later will go next map (default: 10)", FCVAR_NOTIFY, true, 5.0)
	g_hCvarChangeTime.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarChangeTime)
	
	g_hCvarMapList	= CreateConVar("lm_maptester_maplist", "0", "0=Maps Folder, 1='mapcyclefile', or path to a list file, changing value will generate", FCVAR_NOTIFY)
	g_hCvarMapList.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMapList)

	BuildPath(Path_SM, g_szDataFolder, sizeof(g_szDataFolder), g_szDataFolder)
	Format(g_szNowTxt,     sizeof(g_szNowTxt),     "%s%s", g_szDataFolder, g_szNowTxt)
	Format(g_szBadTxt,     sizeof(g_szBadTxt),     "%s%s", g_szDataFolder, g_szBadTxt)
	Format(g_szGoodTxt,    sizeof(g_szGoodTxt),    "%s%s", g_szDataFolder, g_szGoodTxt)
	Format(g_szMaplistTxt, sizeof(g_szMaplistTxt), "%s%s", g_szDataFolder, g_szMaplistTxt)
	
	if (!DirExists(g_szDataFolder))
		CreateDirectory(g_szDataFolder, 755)
	
	
	return APLRes_Success
}

public OnPluginStart() {
	if (!g_bCvarMapTesterEnabled)
		return

	if (!FileExists(g_szMaplistTxt)) {
		LM_PrintToServerInfo("'data/maptester/maplist.txt' is not generated yet, will generate now...")
	} else {
		LM_PrintToServerInfo("'data/maptester/maplist.txt' was found, will start map test loop after map fully loaded...")
	}

	if (StrEqual(g_szCvarMapList, "") || IsNullString(g_szCvarMapList))
		g_szCvarMapList = "0"


	if (StrEqual(g_szCvarMapList, "0")) {
		Check_MapsFolder()

	} else if (StrEqual(g_szCvarMapList, "1")) {
		Check_MapsCycleFile()

	} else {
		Check_DirectFile()

	}
	LM_PrintToServerInfo("Map Tester loaded")
}

public void OnMapInit() {
	char szCurrentMap[64]
	GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
	LM_PrintToServerInfo("Map '%s' now loading...", szCurrentMap, g_fCvarChangeTime)
	
	WriteMapToFile(g_szNowTxt, szCurrentMap)
}

public void OnMapStart() {
	if (!g_bCvarMapTesterEnabled)
		return

	char szCurrentMap[64]
	GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
	LM_PrintToServerInfo("Map '%s' successfully loaded, going next map in %f seconds...", szCurrentMap, g_fCvarChangeTime)

	WriteMapToFile(g_szGoodTxt, szCurrentMap)
	RemoveMapFromFile(g_szNowTxt, szCurrentMap)

	// CreateTimer(g_fCvarChangeTime, Timer_Countdown)
	CreateTimer(3.0, Timer_Countdown)
}

Action Timer_Countdown(Handle hTimer, any data) {

	char szMapName[32]
	GetNextTestMap(szMapName, sizeof(szMapName))
	if (StrEqual(szMapName, "")) {
		LM_PrintToServerInfo("==============================================")
		LM_PrintToServerInfo("Could not get next map! perhaps we tested all maps already?")
		LM_PrintToServerInfo("Go '%s'", g_szDataFolder)
		LM_PrintToServerInfo("and see the results in good.txt and bad.txt")
		LM_PrintToServerInfo("==============================================")
	}


	ForceChangeLevel(szMapName, "Map Test")

	return Plugin_Handled
}




Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarMapTesterEnabled)
		g_bCvarMapTesterEnabled = g_hCvarMapTesterEnabled.BoolValue
	else if (convar == g_hCvarChangeTime)
		g_fCvarChangeTime = g_hCvarChangeTime.FloatValue
	else if (convar == g_hCvarMapList)
		g_hCvarMapList.GetString(g_szCvarMapList, sizeof(g_szCvarMapList))
}




void Check_MapsFolder() {

	LM_PrintToServerInfo("Searching from 'maps/' folder...")

	DirectoryListing arDirList = OpenDirectory(g_szMapsFolder)
	Handle hMapList = OpenFile(g_szMaplistTxt, "w")

	char szMapName[PLATFORM_MAX_PATH]
	while (arDirList.GetNext(szMapName, sizeof(szMapName))) {
		
		// filters . and ..
		if (StrContains(szMapName, ".") == 0)
			continue

		// filters not .bsp
		if (StrContains(szMapName, ".bsp") != strlen(szMapName)-4)
			continue

		ReplaceString(szMapName, sizeof(szMapName), ".bsp", "")
		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")
		WriteFileLine(hMapList, szMapName)
	}
	
	LM_PrintToServerInfo("'data/maptester/maplist.txt' generated.")
	CloseHandle(hMapList)

}

void Check_MapsCycleFile() {

	LM_PrintToServerInfo("Searching from 'mapcyclefile' file...")

	GetConVarString(FindConVar("mapcyclefile"), g_szMapcyclefile, sizeof(g_szMapcyclefile))
	Format(g_szMapcyclefile, sizeof(g_szMapcyclefile), "cfg/%s", g_szMapcyclefile)
	
	if (!FileExists(g_szMapcyclefile)) {
		LM_PrintToServerWarning("'cfg/mapcycle.txt' was not found, trying default mapcycle file... 'cfg/mapcycle_default.txt")
	}
	g_szMapcyclefile = "cfg/mapcycle_default.txt"
	if (!FileExists(g_szMapcyclefile)) {
		LM_PrintToServerError("both mapcycle files in cfg/ was not found, set 'lm_maptester_maplist' to 0 or assign another map list file!")
		LM_PrintToServerError("Map Tester will now stop.")
		return
	}

	Handle hMapCycle = OpenFile(g_szMapcyclefile, "r")

	Handle hMapList = OpenFile(g_szMaplistTxt, "w")
	char szMapName[PLATFORM_MAX_PATH]
	while (!IsEndOfFile(hMapCycle)) {
		if (!ReadFileLine(hMapCycle, szMapName, sizeof(szMapName)))
			break
		
		// filters //
		if (StrContains(szMapName, "//") == 0)
			continue

		if (StrContains(szMapName, ".bsp") == strlen(szMapName)-4)
			ReplaceString(szMapName, sizeof(szMapName), ".bsp", "")

		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")
		WriteFileLine(hMapList, szMapName)
	}
	LM_PrintToServerInfo("'data/maptester/maplist.txt' generated.")
	CloseHandle(hMapList)
	CloseHandle(hMapCycle)

}

void Check_DirectFile() {
	
	LM_PrintToServerInfo("Direct file assigned, searching from '%s' file...", g_szCvarMapList)

	if (!FileExists(g_szCvarMapList)) {
		LM_PrintToServerError("'%s' was not found, please reconfig ConVar 'lm_maptester_maplist', assign another file or set to 0 to just search map folder.", g_szCvarMapList)
		LM_PrintToServerError("Map Tester will now stop.")
		return
	}

	Handle hMapCycle = OpenFile(g_szCvarMapList, "r")

	Handle hMapList = OpenFile(g_szMaplistTxt, "w")
	char szMapName[PLATFORM_MAX_PATH]
	while (!IsEndOfFile(hMapCycle)) {
		if (!ReadFileLine(hMapCycle, szMapName, sizeof(szMapName)))
			break
		
		// filters //
		if (StrContains(szMapName, "//") == 0)
			continue

		if (StrContains(szMapName, ".bsp") == strlen(szMapName)-4)
			ReplaceString(szMapName, sizeof(szMapName), ".bsp", "")

		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")
		WriteFileLine(hMapList, szMapName)
	}
	LM_PrintToServerInfo("'data/maptester/maplist.txt' generated.")
	CloseHandle(hMapList)
	CloseHandle(hMapCycle)
}




void WriteMapToFile(const char[] szFilePath, const char[] szNewMap) {
	bool bFound = false
	char szMapName[256]
	Handle hFile = OpenFile(szFilePath, "a+")
	while(!IsEndOfFile(hFile)) {
		if (!ReadFileLine(hFile, szMapName, sizeof(szMapName)))
			break
		
		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")
		if (StrEqual(szMapName, szNewMap)) {
			bFound = true
			break
		}
	}
	if (!bFound) {
		WriteFileLine(hFile, szNewMap)
	}
	CloseHandle(hFile)
}

void ReadMapFromFile(const char[] szFilePath, char[] szMapName, int iMaxLen) {
	
	Handle hFile = OpenFile(szFilePath, "r")
	while(!IsEndOfFile(hFile)) {
		if (!ReadFileLine(hFile, szMapName, iMaxLen))
			break
		if (StrEqual(szMapName, "") || strlen(szMapName) <= 1)
			continue

		ReplaceString(szMapName, iMaxLen, "\r", "")
		ReplaceString(szMapName, iMaxLen, "\n", "")
		break
	}
	// LM_PrintToServerError(szMapName)
	CloseHandle(hFile)
}

void RemoveMapFromFile(const char[] szFilePath, const char[] szFindMap) {
	
	char szMapName[32], szFileTmp[PLATFORM_MAX_PATH]
	Format(szFileTmp, sizeof(szFileTmp), "%s.tmp", szFilePath)
	
	Handle hFile = OpenFile(szFilePath, "r")
	Handle hTmp = OpenFile(szFileTmp, "w")
	
	while (!IsEndOfFile(hFile)) {
		if (!ReadFileLine(hFile, szMapName, sizeof(szMapName)))
			break

		if (StrEqual(szMapName, ""))
			continue

		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")

		if (StrEqual(szMapName, szFindMap)) {
			LM_PrintToServerError(szFindMap)
			continue
		}
		
		if (strlen(szMapName) < 2)
			continue
		
		WriteFileLine(hTmp, szMapName)

	}
	CloseHandle(hTmp)
	CloseHandle(hFile)

	DeleteFile(szFilePath)
	RenameFile(szFilePath, szFileTmp)
}

void GetNextTestMap(char[] szMapName, int iMaxLen) {
	ReadMapFromFile(g_szMaplistTxt, szMapName, iMaxLen)
	// LM_PrintToServerError(szMapName)
	RemoveMapFromFile(g_szMaplistTxt, szMapName)
}




void LM_PrintToServerInfo(const char[] format, any ...) {
	char buffer[256]
	VFormat(buffer, sizeof(buffer), format, 2)
	PrintToServer("%s[Info] %s", MSGTAG, buffer)
}

void LM_PrintToServerWarning(const char[] format, any ...) {
	char buffer[256]
	VFormat(buffer, sizeof(buffer), format, 2)
	PrintToServer("%s[Warn] %s", MSGTAG, buffer)
}

void LM_PrintToServerError(const char[] format, any ...) {
	char buffer[256]
	VFormat(buffer, sizeof(buffer), format, 2)
	PrintToServer("%s[Erro] %s", MSGTAG, buffer)
}



