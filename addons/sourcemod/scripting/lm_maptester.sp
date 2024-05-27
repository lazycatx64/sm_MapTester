
#include <sourcemod>

#define MSGTAG "[MapTester]"

bool g_bIsFirstStart = false

ConVar g_hCvarMapTesterEnabled
bool g_bCvarMapTesterEnabled = false

ConVar g_hCvarMapTesterWait
bool g_bCvarMapTesterWait = false

ConVar g_hCvarChangeTime
float g_fCvarChangeTime = 10.0

ConVar g_hCvarMapList
char g_szCvarMapList[PLATFORM_MAX_PATH] = ""

char g_szNowTxt[PLATFORM_MAX_PATH]        = "--now.txt"
char g_szMissingTxt[PLATFORM_MAX_PATH]    = "missing.txt"
char g_szCrashTxt[PLATFORM_MAX_PATH]      = "crash.txt"
char g_szGoodTxt[PLATFORM_MAX_PATH]       = "good.txt"
char g_szMaplistTxt[PLATFORM_MAX_PATH]    = "--maplist.txt"

char g_szDataFolder[PLATFORM_MAX_PATH]    = "data/maptester/"
char g_szMapsFolder[PLATFORM_MAX_PATH]    = "maps/"
char g_szMapcyclefile[PLATFORM_MAX_PATH]  = ""


public Plugin myinfo = {
	name = "Map Tester",
	author = "LaZycAt",
	description = "Map Tester that auto run through maps one by one.",
	version = "1.0.0",
	url = "https://github.com/lazycatx64/sm_MapTester"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max) {

	LM_PrintToServerInfo("Map Tester loading...")

	g_hCvarMapTesterEnabled = CreateConVar("lm_maptester_enabled", "1", "Set 1 to start the tester.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarMapTesterEnabled.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMapTesterEnabled)

	g_hCvarMapTesterWait = CreateConVar("lm_maptester_waitplayer", "0", "Set 1 to wait for first player complete loaded into map, then we change map.", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	g_hCvarMapTesterWait.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMapTesterWait)

	g_hCvarChangeTime = CreateConVar("lm_maptester_changetime", "3", "After map loaded, X seconds later will go next map", FCVAR_NOTIFY, true, 0.1)
	g_hCvarChangeTime.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarChangeTime)
	
	g_hCvarMapList = CreateConVar("lm_maptester_maplist", "0", "0=Maps Folder, 1='mapcyclefile', or path to a list file, changing value will regenerate maplist", FCVAR_NOTIFY)
	g_hCvarMapList.AddChangeHook(Hook_CvarChanged)
	CvarChanged(g_hCvarMapList)

	HookEvent("player_disconnect", LM_OnClientDisconnect)

	RegAdminCmd("lm_map_good", Command_MapGood, 0, "Skip current map and add it to good.txt")
	RegAdminCmd("lm_map_missing", Command_MapMissing, 0, "Skip current map and add it to missing.txt")
	RegAdminCmd("lm_map_crash", Command_MapCrash, 0, "Skip current map and add it to crash.txt")

	AutoExecConfig(true, "lm_maptester")

	BuildPath(Path_SM, g_szDataFolder, sizeof(g_szDataFolder), g_szDataFolder)
	Format(g_szNowTxt,     sizeof(g_szNowTxt),     "%s%s", g_szDataFolder, g_szNowTxt)
	Format(g_szMissingTxt, sizeof(g_szMissingTxt), "%s%s", g_szDataFolder, g_szMissingTxt)
	Format(g_szCrashTxt,   sizeof(g_szCrashTxt),   "%s%s", g_szDataFolder, g_szCrashTxt)
	Format(g_szGoodTxt,    sizeof(g_szGoodTxt),    "%s%s", g_szDataFolder, g_szGoodTxt)
	Format(g_szMaplistTxt, sizeof(g_szMaplistTxt), "%s%s", g_szDataFolder, g_szMaplistTxt)
	
	if (!DirExists(g_szDataFolder))
		CreateDirectory(g_szDataFolder, 755)
	
	
	return APLRes_Success
}

public OnPluginStart() {
	if (!g_bCvarMapTesterEnabled)
		return

	Gen_GenerateMapList()
	Check_NowFile()
	Check_TestedMaps()

	LM_PrintToServerInfo("Map Tester loaded")
}

void LM_Skip_Map(const char[] szWriteMap) {
	char szCurrentMap[64]
	GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
	LM_PrintToServerInfo("Map missing for players, going next map in %f seconds...", g_fCvarChangeTime)

	WriteMapToFile(szWriteMap, szCurrentMap)
	DeleteFile(g_szNowTxt)

	CreateTimer(g_fCvarChangeTime, Timer_Countdown)

}

public Action Command_MapGood(plyClient, args) {
	LM_Skip_Map(g_szGoodTxt)
	return Plugin_Handled
}

public Action Command_MapMissing(plyClient, args) {
	LM_Skip_Map(g_szMissingTxt)
	return Plugin_Handled
}

public Action Command_MapCrash(plyClient, args) {
	LM_Skip_Map(g_szCrashTxt)
	return Plugin_Handled
}



public void OnMapStart() {
	if (!g_bCvarMapTesterEnabled)
		return

	if (!g_bIsFirstStart) {

		LM_PrintToServerInfo("Tests will start in 5 seconds.")
		CreateTimer(5.0, Timer_DelayedOnMapStart)
		g_bIsFirstStart = true
		return
	}
	LM_MapStart()
	
}

Action Timer_DelayedOnMapStart(Handle hTimer, any data) {
	if (!g_bCvarMapTesterEnabled)
		return Plugin_Handled

	LM_MapStart()
	return Plugin_Handled
}

void LM_MapStart() {

	if (g_bCvarMapTesterWait) {
		char szCurrentMap[64]
		GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
		LM_PrintToServerInfo("Map '%s' successfully loaded, wait for player to join...", szCurrentMap, g_fCvarChangeTime)

	} else {

		char szCurrentMap[64]
		GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
		LM_PrintToServerInfo("Map '%s' successfully loaded, going next map in %f seconds...", szCurrentMap, g_fCvarChangeTime)

		WriteMapToFile(g_szGoodTxt, szCurrentMap)
		DeleteFile(g_szNowTxt)

		CreateTimer(g_fCvarChangeTime, Timer_Countdown)
	}
	
}

public void OnClientPostAdminCheck(int plyClient) {
	if (!g_bCvarMapTesterEnabled)
		return
	
	if (!g_bCvarMapTesterWait)
		return

	char szCurrentMap[64]
	GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
	LM_PrintToServerInfo("First player loaded, going next map in %f seconds...", g_fCvarChangeTime)

	WriteMapToFile(g_szGoodTxt, szCurrentMap)
	DeleteFile(g_szNowTxt)

	CreateTimer(g_fCvarChangeTime, Timer_Countdown)
	
}

void LM_OnClientDisconnect(Event hEvent, const char[] name, bool dontBroadcast) {
	
	if (!g_bCvarMapTesterEnabled)
		return
	
	char szReason[64]
	hEvent.GetString("reason", szReason, sizeof(szReason))
	
	if (StrContains(szReason, "Map is missing", false) != 0)
		return

	
	char szCurrentMap[64]
	GetCurrentMap(szCurrentMap, sizeof(szCurrentMap))
	LM_PrintToServerInfo("Map missing for players, going next map in %f seconds...", g_fCvarChangeTime)

	WriteMapToFile(g_szMissingTxt, szCurrentMap)
	DeleteFile(g_szNowTxt)

	CreateTimer(g_fCvarChangeTime, Timer_Countdown)

}


Action Timer_Countdown(Handle hTimer, any data) {

	char szNextMap[32]
	
	if (!GetNextTestMap(szNextMap, sizeof(szNextMap)) || StrEqual(szNextMap, "")) {
		LM_PrintToServerInfo("==============================================")
		LM_PrintToServerInfo("Could not get next map! perhaps we tested all maps already?")
		LM_PrintToServerInfo("Go '%s'", g_szDataFolder)
		LM_PrintToServerInfo("and see the results in good.txt and crash.txt")
		LM_PrintToServerInfo("==============================================")
		DeleteFile(g_szMaplistTxt)
		return Plugin_Handled
	}


	LM_PrintToServerInfo("Map '%s' now loading...", szNextMap)
	
	WriteMapToFile(g_szNowTxt, szNextMap)

	ForceChangeLevel(szNextMap, "Map Test")

	return Plugin_Handled
}




Hook_CvarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	CvarChanged(convar)
}
void CvarChanged(Handle convar) {
	if (convar == g_hCvarMapTesterEnabled)
		g_bCvarMapTesterEnabled = g_hCvarMapTesterEnabled.BoolValue
	else if (convar == g_hCvarMapTesterWait)
		g_bCvarMapTesterWait = g_hCvarMapTesterWait.BoolValue
	else if (convar == g_hCvarChangeTime)
		g_fCvarChangeTime = g_hCvarChangeTime.FloatValue
	else if (convar == g_hCvarMapList) {
		g_hCvarMapList.GetString(g_szCvarMapList, sizeof(g_szCvarMapList))
		Gen_GenerateMapList()
		Check_TestedMaps()
	}
}



/**
 * Check if Now.txt exists and has map name it in,
 * means that map crashed during loading,
 * then write that to crash.txt.
 */
void Check_NowFile() {

	if (!FileExists(g_szNowTxt))
		return

	Handle hNowFile = OpenFile(g_szNowTxt, "r")
	if (hNowFile == INVALID_HANDLE) {
		DeleteFile(g_szNowTxt)
		return
	}

	char szMapName[32]
	while (!IsEndOfFile(hNowFile)) {
		if (!ReadFileLine(hNowFile, szMapName, sizeof(szMapName)))
			break
		
		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")

		if (!StrEqual(szMapName, "") && strlen(szMapName) > 1) {
			LM_PrintToServerInfo("Writing '%s' map to crash.txt.", szMapName)
			WriteMapToFile(g_szCrashTxt, szMapName)
			break
		}
	}

	CloseHandle(hNowFile)
	DeleteFile(g_szNowTxt)
}

/**
 * Check tested maps from good.txt and crash.txt
 */
void Check_TestedMaps() {

	if (FileExists(g_szGoodTxt))
		RemoveDuplicatedFromFile(g_szMaplistTxt, g_szGoodTxt)

	if (FileExists(g_szMissingTxt))
		RemoveDuplicatedFromFile(g_szMaplistTxt, g_szMissingTxt)
	
	if (FileExists(g_szCrashTxt))
		RemoveDuplicatedFromFile(g_szMaplistTxt, g_szCrashTxt)
	
}



/**
 * Check the ConVar g_szCvarMapList and decide where we get list from.
 */
void Gen_GenerateMapList() {
	
	if (!FileExists(g_szMaplistTxt)) {
		LM_PrintToServerInfo("'data/maptester/maplist.txt' is not generated yet, will generate now...")
	} else {
		LM_PrintToServerInfo("'data/maptester/maplist.txt' was found, will start map test loop after map fully loaded...")
	}

	if (StrEqual(g_szCvarMapList, "") || IsNullString(g_szCvarMapList))
		g_szCvarMapList = "0"

	if (StrEqual(g_szCvarMapList, "0"))
		Gen_FromMapsFolder()
	else if (StrEqual(g_szCvarMapList, "1"))
		Gen_FromMapsCycleFile()
	else
		Gen_FromDirectFile()

}

/**
 * Generate map list from scanning maps folder
 */
void Gen_FromMapsFolder() {

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

/**
 * Generate map list from mapscycle.txt
 */
void Gen_FromMapsCycleFile() {

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

/**
 * Generate map list from specific file
 */
void Gen_FromDirectFile() {
	
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



/**
 * Write a map name to specific file.
 *
 * @param szFilePath    File path
 * @param szNewMap      Map name
 */
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

/**
 * Read the first map name from the file.
 *
 * @param szFilePath    File path
 * @param szMapName     Returned map name
 * @param iMaxLen       Max length of szMapName
 * @return True if success; false otherwise
 */
bool ReadMapFromFile(const char[] szFilePath, char[] szMapName, int iMaxLen) {
	
	bool bFound = false
	char szBuffer[32]
	Handle hFile = OpenFile(szFilePath, "r")
	while(!IsEndOfFile(hFile)) {
		if (!ReadFileLine(hFile, szBuffer, iMaxLen))
			break

		ReplaceString(szBuffer, iMaxLen, "\r", "")
		ReplaceString(szBuffer, iMaxLen, "\n", "")

		if (!StrEqual(szBuffer, "") && strlen(szBuffer) > 1) {
			strcopy(szMapName, iMaxLen, szBuffer)
			bFound = true
			break
		}
	
	}
	// LM_PrintToServerError(szMapName)
	CloseHandle(hFile)
	return bFound
}

/**
 * Remove a specific map name from file
 *
 * @param szFilePath    File path
 * @param szFindMap     Map name to remove
 */
void RemoveMapFromFile(const char[] szFilePath, const char[] szFindMap) {
	
	char szMapName[32], szFileTmp[PLATFORM_MAX_PATH]
	Format(szFileTmp, sizeof(szFileTmp), "%s.tmp", szFilePath)
	
	Handle hFile = OpenFile(szFilePath, "r")
	Handle hTmp = OpenFile(szFileTmp, "w")
	
	while (!IsEndOfFile(hFile)) {
		if (!ReadFileLine(hFile, szMapName, sizeof(szMapName)))
			break

		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")

		if (StrEqual(szMapName, "") || strlen(szMapName) < 2)
			continue

		if (StrEqual(szMapName, szFindMap))
			continue
		
		WriteFileLine(hTmp, szMapName)

	}
	CloseHandle(hTmp)
	CloseHandle(hFile)

	DeleteFile(szFilePath)
	RenameFile(szFilePath, szFileTmp)
}

/**
 * Compare two text file and remove duplicated from szFileToEdit
 *
 * @param szFileToEdit       File to edit
 * @param szFileToCompare    File to compare from
 */
void RemoveDuplicatedFromFile(const char[] szFileToEdit, const char[] szFileToCompare) {
	
	char szMapName[32], szComapreName[32], szFileTmp[PLATFORM_MAX_PATH]
	Format(szFileTmp, sizeof(szFileTmp), "%s.tmp", szFileToEdit)
	
	File hFileEdit = OpenFile(szFileToEdit, "r")
	File hFileTmp = OpenFile(szFileTmp, "w")
	File hFileCompare = OpenFile(szFileToCompare, "r")
	
	while (!hFileEdit.EndOfFile()) {

		if (!hFileEdit.ReadLine(szMapName, sizeof(szMapName)))
			break

		ReplaceString(szMapName, sizeof(szMapName), "\r", "")
		ReplaceString(szMapName, sizeof(szMapName), "\n", "")

		if (StrEqual(szMapName, "") || strlen(szMapName) < 2)
			continue

		bool bFound = false
		hFileCompare.Seek(0, SEEK_SET)
		while (!hFileCompare.EndOfFile()) {
			if (!hFileCompare.ReadLine(szComapreName, sizeof(szComapreName)))
				break

			ReplaceString(szComapreName, sizeof(szComapreName), "\r", "")
			ReplaceString(szComapreName, sizeof(szComapreName), "\n", "")

			if (StrEqual(szComapreName, "") || strlen(szComapreName) < 2)
				continue

			if (StrEqual(szMapName, szComapreName)) {
				bFound = true
				break
			}
			

		}
		if (!bFound)
			hFileTmp.WriteLine(szMapName)

	}
	hFileTmp.Flush()
	hFileTmp.Close()

	hFileEdit.Close()
	hFileCompare.Close()
	
	DeleteFile(szFileToEdit)
	RenameFile(szFileToEdit, szFileTmp)
}

/**
 * Get next test map from maplist
 *
 * @param szMapName    Returned map name
 * @param iMaxLen      Max length of szMapName
 * @return True if found a map; false otherwise
 */
bool GetNextTestMap(char[] szMapName, int iMaxLen) {
	if (!ReadMapFromFile(g_szMaplistTxt, szMapName, iMaxLen))
		return false
	
	RemoveMapFromFile(g_szMaplistTxt, szMapName)
	return true
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



