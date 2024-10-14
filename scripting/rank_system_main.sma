#include <amxmodx>

/* Common include libraries */
#include <amxmisc>
#include <time>
#tryinclude <cromchat>

#define PLUGIN  "Rank System"
#define VERSION "1.3"
#define AUTHOR  "Huehue @ AMXX-BG.INFO"
#define GAMETRACKER "rank_system"

#if !defined MAX_PLAYERS || AMXX_VERSION_NUM < 183
#define MAX_PLAYERS 32
#define client_disconnected client_disconnect
#endif

enum _:ePlayerData
{
	Experience,
	Level,
	NextLevel,
	IncreaseExperience,
	ConnectStatus,
	UserName[MAX_PLAYERS],
	UserAuthID[MAX_AUTHID_LENGTH],
	UserIP[MAX_IP_LENGTH],
	Connections,
	Played_Time
}

new g_iPlayerData[MAX_PLAYERS + 1][ePlayerData]

enum
{
	NVAULT = 0,
	FVAULT,
	SQL
}

enum
{
	NAME = 0,
	STEAMID,
	IP
}

#include <fvault>

#include <nvault>
new g_iNVault

#include <sqlx>
new Handle:g_SqlTuple
new g_Error[512]

enum
{
	Negative = 0,
	Positive
}

new Array:g_aRankName, Array:g_aRankExp
new iTotalRanks

enum
{
	SECTION_SETTINGS = 1,
	SECTION_RANKS,
	SECTION_SAVE_SETTINGS
}

enum _:eSettings
{
	Prefix[32],
	VipFlag[6],
	HudColors[12],
	Float:HudX,
	Float:HudY,
	HudEffect,
	KillExp,
	HeadKillExp,
	GrenadeKillExp,
	KnifeKillExp,
	VipKillExp,
	VipHeadKillExp,
	VipGrenadeKillExp,
	VipKnifeKillExp,
	VipFlagBit,
	LevelUp_Sound[64],
	LevelDown_Sound[64]
}

new g_eSettings[eSettings]

enum _:eSave_Settings
{
	Host[MAX_NAME_LENGTH],
	User[MAX_NAME_LENGTH],
	Pass[MAX_NAME_LENGTH],
	Db[MAX_NAME_LENGTH],
	Table[MAX_NAME_LENGTH],
	NVault[MAX_NAME_LENGTH],
	FVault[MAX_NAME_LENGTH],
	szSaveType[MAX_NAME_LENGTH],
	SaveType,
	Float:LoadTime,
	SaveBy[MAX_NAME_LENGTH],
	SaveByWhat
}

new g_eSave_Settings[eSave_Settings]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(GAMETRACKER, AUTHOR, FCVAR_SERVER | FCVAR_SPONLY)
	set_cvar_string(GAMETRACKER, AUTHOR)

	register_dictionary("time.txt")

	register_event("DeathMsg", "eventDeathMsg", "a")

	register_clcmd("amx_reload_file", "Command_Reload_RanksFile", ADMIN_RCON, "- Reload settings and rank file..")

	register_clcmd("say /pinfo", "Show_PlayerInfo")
	register_clcmd("say_team /pinfo", "Show_PlayerInfo")
	register_clcmd("say /pt", "Show_PlayerInfo")
	register_clcmd("say /playtime", "Show_PlayerInfo")

	#if defined _cromchat_included
	CC_SetPrefix(g_eSettings[Prefix])
	#endif
}

public plugin_cfg()
{
	switch(g_eSave_Settings[SaveType])
	{
		case NVAULT:
		{
			g_iNVault = nvault_open(g_eSave_Settings[NVault])
		}
		case SQL:
		{
			set_task(2.0, "RSH_SQL_Initialize")
		}
	}
}

public plugin_precache()
{
	g_aRankName = ArrayCreate(128, 1)
	g_aRankExp = ArrayCreate(64, 1)
	
	Read_Ranks_File()
}

public plugin_end()
{
	switch(g_eSave_Settings[SaveType])
	{
		case NVAULT:
		{
			nvault_close(g_iNVault)
		}
		case SQL:
		{
			if(g_SqlTuple != Empty_Handle)
				SQL_FreeHandle(g_SqlTuple)
		}
	}
}

public Read_Ranks_File()
{
	static szConfigsDir[64], iFile, szRankFile[64]
	get_configsdir(szConfigsDir, charsmax(szConfigsDir))
	formatex(szRankFile, charsmax(szRankFile), "/Rank_System.ini")
	add(szConfigsDir, charsmax(szConfigsDir), szRankFile)
	iFile = fopen(szConfigsDir, "rt")
	
	if(!file_exists(szConfigsDir))
	{
		server_print("File not found, creating new one..")
		new iFile = fopen(szConfigsDir, "wt")
		
		if (iFile)
		{
			new szNewFile[MAX_MOTD_LENGTH]
			formatex(szNewFile, charsmax(szNewFile), "[SETTINGS]\
				^nPREFIX = &x04[&x03Rank System&x04]\
				^nVIP_FLAG = b\
				^nHUD_COLORS = 255 0 0\
				^nHUD_X_POSITION = 0.80\
				^nHUD_Y_POSITION = -1.0\
				^nHUD_EFFECT = 0\
				^nKILL_EXP = 2\
				^nHEADSHOT_KILL_EXP = 3\
				^nGRENADE_KILL_EXP = 4\
				^nKNIFE_KILL_EXP = 6\
				^nVIP_KILL_EXP = 3\
				^nVIP_HEADSHOT_KILL_EXP = 5\
				^nVIP_GRENADE_KILL_EXP = 6\
				^nVIP_KNIFE_KILL_EXP = 8\
				^n^nLEVEL_UP_SOUND = sound/ambience/lv_fruit2.wav\
				^nLEVEL_DOWN_SOUND = sound/ambience/thunder_clap.wav\
				^n^n[SAVE OPTIONS]\
				^nHOST = YourHost\
				^nUSER = YourUser\
				^nPASS = YourPassword\
				^nDB = YourDb\
				^nTABLE = RSH_SQLx_AMXXBG\
				^nNVault = RSH_nVault_AMXXBG\
				^nFVault = RSH_fVault_AMXXBG\
				^n^n// Save types are: nVault | fVault | SQL || Requires Map change to load new settings\
				^nSAVE_TYPE = 0\
				^nLOAD_TIME = 1.0\
				^n// Save types are: NAME | STEAMID | IP\
				^nSAVE_BY = NAME\
				^n^n[RANKS]\
				^n;Rank Name = XP\
				^nNewbie = 0\
				^nPro = 25\
				^nMaster = 50")
			fputs(iFile, szNewFile)
		}
		fclose(iFile)
		Read_Ranks_File()
		return
	}
	
	new iLine
	
	if (iFile)
	{
		static szLineData[160], iSection, szValue[160], szKey[64]
		
		while (!feof(iFile))
		{
			fgets(iFile, szLineData, charsmax(szLineData))
			trim(szLineData)
			
			if (szLineData[0] == EOS || szLineData[0] == ';' || (szLineData[0] == '/' && szLineData[1] == '/'))
				continue

			switch(szLineData[0])
			{
				case EOS, ';': continue
				case '[':
				{
					if (szLineData[strlen(szLineData) - 1] == ']')
					{
						if (containi(szLineData, "settings") != -1)
							iSection = SECTION_SETTINGS
						else if (containi(szLineData, "save") != -1)
							iSection = SECTION_SAVE_SETTINGS
						else if (containi(szLineData, "ranks") != -1)
							iSection = SECTION_RANKS
					}
					else
						continue
				}
				default:
				{
					switch(iSection)
					{
						case SECTION_SETTINGS:
						{
							strtok(szLineData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
							trim(szKey)
							trim(szValue)

							if (szValue[0] == EOS)
								continue

							if (equal(szKey, "PREFIX"))
								copy(g_eSettings[Prefix], charsmax(g_eSettings[Prefix]), szValue)
							else if (equal(szKey, "VIP_FLAG"))
							{
								copy(g_eSettings[VipFlag], charsmax(g_eSettings[VipFlag]), szValue)
								g_eSettings[VipFlagBit] = read_flags(g_eSettings[VipFlag])
							}
							else if (equal(szKey, "HUD_COLORS"))
								copy(g_eSettings[HudColors], charsmax(g_eSettings[HudColors]), szValue)
							else if (equal(szKey, "HUD_X_POSITION"))
								g_eSettings[HudX] = _:str_to_float(szValue)
							else if (equal(szKey, "HUD_Y_POSITION"))
								g_eSettings[HudY] = _:str_to_float(szValue)
							else if (equal(szKey, "HUD_EFFECT"))
								g_eSettings[HudEffect] = str_to_num(szValue)
							else if (equal(szKey, "KILL_EXP"))
								g_eSettings[KillExp] = str_to_num(szValue)
							else if (equal(szKey, "HEADSHOT_KILL_EXP"))
								g_eSettings[HeadKillExp] = str_to_num(szValue)
							else if (equal(szKey, "GRENADE_KILL_EXP"))
								g_eSettings[GrenadeKillExp] = str_to_num(szValue)
							else if (equal(szKey, "KNIFE_KILL_EXP"))
								g_eSettings[KnifeKillExp] = str_to_num(szValue)
							else if (equal(szKey, "VIP_KILL_EXP"))
								g_eSettings[VipKillExp] = str_to_num(szValue)
							else if (equal(szKey, "VIP_HEADSHOT_KILL_EXP"))
								g_eSettings[VipHeadKillExp] = str_to_num(szValue)
							else if (equal(szKey, "VIP_GRENADE_KILL_EXP"))
								g_eSettings[VipGrenadeKillExp] = str_to_num(szValue)
							else if (equal(szKey, "VIP_KNIFE_KILL_EXP"))
								g_eSettings[VipKnifeKillExp] = str_to_num(szValue)
							else if (equal(szKey, "LEVEL_UP_SOUND"))
							{
								copy(g_eSettings[LevelUp_Sound], charsmax(g_eSettings[LevelUp_Sound]), szValue)

								if (szValue[0])
								{
									try_precache_generic(szValue)
								}
							}
							else if (equal(szKey, "LEVEL_DOWN_SOUND"))
							{
								copy(g_eSettings[LevelDown_Sound], charsmax(g_eSettings[LevelDown_Sound]), szValue)

								if (szValue[0])
								{
									try_precache_generic(szValue)
								}
							}
						}
						case SECTION_SAVE_SETTINGS:
						{
							strtok(szLineData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
							trim(szKey)
							trim(szValue)

							if (szValue[0] == EOS)
								continue

							if (equal(szKey, "HOST"))
								copy(g_eSave_Settings[Host], charsmax(g_eSave_Settings[Host]), szValue)
							else if (equal(szKey, "USER"))
								copy(g_eSave_Settings[User], charsmax(g_eSave_Settings[User]), szValue)
							else if (equal(szKey, "PASS"))
								copy(g_eSave_Settings[Pass], charsmax(g_eSave_Settings[Pass]), szValue)
							else if (equal(szKey, "DB"))
								copy(g_eSave_Settings[Db], charsmax(g_eSave_Settings[Db]), szValue)
							else if (equal(szKey, "TABLE"))
								copy(g_eSave_Settings[Table], charsmax(g_eSave_Settings[Table]), szValue)
							else if (equal(szKey, "NVault"))
								copy(g_eSave_Settings[NVault], charsmax(g_eSave_Settings[NVault]), szValue)
							else if (equal(szKey, "FVault"))
								copy(g_eSave_Settings[FVault], charsmax(g_eSave_Settings[FVault]), szValue)
							else if (equal(szKey, "SAVE_TYPE"))
							{
								copy(g_eSave_Settings[szSaveType], charsmax(g_eSave_Settings[szSaveType]), szValue)

								if (equali(g_eSave_Settings[szSaveType], "nvault"))
									g_eSave_Settings[SaveType] = NVAULT
								else if (equali(g_eSave_Settings[szSaveType], "fvault"))
									g_eSave_Settings[SaveType] = FVAULT
								else if (equali(g_eSave_Settings[szSaveType], "sql"))
									g_eSave_Settings[SaveType] = SQL
							}
							else if (equal(szKey, "LOAD_TIME"))
								g_eSave_Settings[LoadTime] = _:str_to_float(szValue)
							else if (equal(szKey, "SAVE_BY"))
							{
								strtoupper(szValue)
								copy(g_eSave_Settings[SaveBy], charsmax(g_eSave_Settings[SaveBy]), szValue)

								if (equali(g_eSave_Settings[SaveBy], "NAME"))
									g_eSave_Settings[SaveByWhat] = NAME
								else if (equali(g_eSave_Settings[SaveBy], "STEAMID") || equali(g_eSave_Settings[SaveBy], "AUTHID") || equali(g_eSave_Settings[SaveBy], "STEAM"))
									g_eSave_Settings[SaveByWhat] = STEAMID
								else if (equali(g_eSave_Settings[SaveBy], "IP"))
									g_eSave_Settings[SaveByWhat] = IP
							}

						}
						case SECTION_RANKS:
						{
							strtok(szLineData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
							trim(szKey)
							trim(szValue)

							if (szValue[0] == EOS)
								continue

							ArrayPushString(g_aRankName, szKey)
							ArrayPushCell(g_aRankExp, str_to_num(szValue))

							iLine++
						}
					}
				}
			}
		}
		fclose(iFile)
	}
	iTotalRanks = iLine - 1
	server_print(">> Loaded %i Ranks from file", iTotalRanks)
}

public client_putinserver(id)
{
	arrayset(g_iPlayerData[id], 0, sizeof(g_iPlayerData[]))
	get_user_name(id, g_iPlayerData[id][UserName], charsmax(g_iPlayerData[][UserName]))

	switch (g_eSave_Settings[SaveByWhat])
	{
		case NAME:
		{
			set_task(g_eSave_Settings[LoadTime], "Load_Data", id, g_iPlayerData[id][UserName], sizeof(g_iPlayerData[][UserName]))
		}
		case STEAMID:
		{
			get_user_authid(id, g_iPlayerData[id][UserAuthID], charsmax(g_iPlayerData[][UserAuthID]))
			set_task(g_eSave_Settings[LoadTime], "Load_Data", id, g_iPlayerData[id][UserAuthID], sizeof(g_iPlayerData[][UserAuthID]))
		}
		case IP:
		{
			get_user_ip(id, g_iPlayerData[id][UserIP], charsmax(g_iPlayerData[][UserIP]), 1)
			set_task(g_eSave_Settings[LoadTime], "Load_Data", id, g_iPlayerData[id][UserIP], sizeof(g_iPlayerData[][UserIP]))
		}
	}
}

public client_disconnected(id)
{
	if (g_iPlayerData[id][ConnectStatus])
	{
		switch (g_eSave_Settings[SaveByWhat])
		{
			case NAME: Save_Data(id, g_iPlayerData[id][UserName])
			case STEAMID: Save_Data(id, g_iPlayerData[id][UserAuthID])
			case IP: Save_Data(id, g_iPlayerData[id][UserIP])
		}
		g_iPlayerData[id][ConnectStatus] = false
	}
}

public client_infochanged(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED
	
	enum _:eNameData
	{
		Old_Name,
		New_Name
	}

	static szNames[eNameData][MAX_NAME_LENGTH]
	get_user_name(id, szNames[Old_Name], charsmax(szNames[]))
	get_user_info(id, "name", szNames[New_Name], charsmax(szNames[]))

	if (!equali(szNames[New_Name], szNames[Old_Name]))
	{
		if (g_eSave_Settings[SaveByWhat] == NAME)
		{
			Save_Data(id, szNames[Old_Name])
			set_task(0.1, "Load_Data", id, szNames[New_Name], sizeof(szNames[]))
		}
		g_iPlayerData[id][UserName] = szNames[New_Name]
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public Show_PlayerInfo(id)
{
	if (is_user_connected(id))
	{
		new szTime[MAX_FMT_LENGTH], szRankName[64]
		ArrayGetString(g_aRankName, g_iPlayerData[id][Level], szRankName, charsmax(szRankName))
		get_time_length(id, get_user_total_playtime(id), timeunit_seconds, szTime, charsmax(szTime))
		#if defined _cromchat_included
		CC_SendMatched(id, CC_COLOR_GREY, "&x03Player: &x04%s &x03>> [&x01Level: &x04%i &x03| &x01Experience: &x04%i &x03| &x01Rank: &x04%s&x03]", g_iPlayerData[id][UserName], g_iPlayerData[id][Level], g_iPlayerData[id][Experience], szRankName)
		CC_SendMatched(id, CC_COLOR_GREY, "&x03Player: &x04%s &x03>> [&x01Play Time: &x04%s &x03| &x01Connects: &x04%i&x03]", g_iPlayerData[id][UserName], szTime, g_iPlayerData[id][Connections])
		#else
		client_print_color(id, print_team_grey, "^4* ^3Player: ^4%s ^3>> [^1Level: ^4%i ^3| ^1Experience: ^4%i ^3| ^1Rank: ^4%s^3]", g_iPlayerData[id][UserName], g_iPlayerData[id][Level], g_iPlayerData[id][Experience], szRankName)
		client_print_color(id, print_team_grey, "^4* ^3Player: ^4%s ^3>> [^1Play Time: ^4%s ^3| ^1Connects: ^4%i^3]", g_iPlayerData[id][UserName], szTime, g_iPlayerData[id][Connections])
		#endif
	}
	return PLUGIN_HANDLED
}

public Command_Reload_RanksFile(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	ArrayClear(g_aRankName)
	ArrayClear(g_aRankExp)
	
	Read_Ranks_File()
	
	return PLUGIN_HANDLED
}

public CheckRank(id, iType, bool:bSendMessage, bool:bSendLevel_Sound)
{
	if(g_iPlayerData[id][Level] <= 0)
	{
		g_iPlayerData[id][Level] = 0
		g_iPlayerData[id][NextLevel] = 1
	}
		
	if (g_iPlayerData[id][Experience] < 0)
		g_iPlayerData[id][Experience] = 0
		
	switch(iType)
	{
		case Negative:
		{
			while (g_iPlayerData[id][Level] <= iTotalRanks)
			{
				new iExp = ArrayGetCell(g_aRankExp, g_iPlayerData[id][Level])
				
				if(g_iPlayerData[id][Experience] >= iExp)
					break
				
				g_iPlayerData[id][Level]--
				g_iPlayerData[id][NextLevel]--
				
				new szRankName[64]
				ArrayGetString(g_aRankName, g_iPlayerData[id][NextLevel], szRankName, charsmax(szRankName))

				if (bSendMessage)
				{
					#if defined _cromchat_included
					CC_SendMatched(0, CC_COLOR_GREY, "&x03Player &x04%s&x03 has lost &x04Level %i &x03- &x04%s", g_iPlayerData[id][UserName], g_iPlayerData[id][NextLevel], szRankName)
					#else
					client_print_color(0, print_team_grey, "^4* ^3Player ^4%s ^3has lost ^4Level %i ^3- ^4%s", g_iPlayerData[id][UserName], g_iPlayerData[id][NextLevel], szRankName)
					#endif
				}

				if (bSendLevel_Sound)
				{
					client_cmd(id, "spk %s", g_eSettings[LevelDown_Sound])
				}
			}
		}
		case Positive:
		{
			while (g_iPlayerData[id][Level] < iTotalRanks)
			{
				new iNextLevelExp = ArrayGetCell(g_aRankExp, g_iPlayerData[id][NextLevel])
				
				if (g_iPlayerData[id][Experience] < iNextLevelExp)
					break
				
				g_iPlayerData[id][Level]++
				g_iPlayerData[id][NextLevel]++
				
				new szRankName[64]
				ArrayGetString(g_aRankName, g_iPlayerData[id][Level], szRankName, charsmax(szRankName))
				
				if (bSendMessage)
				{
					#if defined _cromchat_included
					CC_SendMatched(0, CC_COLOR_GREY, "&x03Player &x04%s &x03has achieved &x04Level %i &x03- &x04%s", g_iPlayerData[id][UserName], g_iPlayerData[id][Level], szRankName)
					#else
					client_print_color(0, print_team_grey, "^4* ^3Player ^4%s ^3has achieved ^4Level %i ^3- ^4%s", g_iPlayerData[id][UserName], g_iPlayerData[id][Level], szRankName)
					#endif
				}

				if (bSendLevel_Sound)
				{
					client_cmd(id, "spk %s", g_eSettings[LevelUp_Sound])
				}
			}
		}
	}
}

/* =============================================
	Events
============================================= */
public eventDeathMsg()
{
	new iKiller = read_data(1), iVictim = read_data(2)
	
	if (is_user_connected(iKiller) && iKiller != iVictim)
	{
		new szWeapon[32]
		read_data(4, szWeapon, charsmax(szWeapon))
		if (equal(szWeapon, "grenade"))
		{
			if (get_user_flags(iKiller) & g_eSettings[VipFlagBit])
				g_iPlayerData[iKiller][IncreaseExperience] = g_eSettings[VipGrenadeKillExp]
			else
				g_iPlayerData[iKiller][IncreaseExperience] = g_eSettings[GrenadeKillExp]
		}
		else if (equal(szWeapon, "knife"))
		{
			if (get_user_flags(iKiller) & g_eSettings[VipFlagBit])
				g_iPlayerData[iKiller][IncreaseExperience] = g_eSettings[VipKnifeKillExp]
			else
				g_iPlayerData[iKiller][IncreaseExperience] = g_eSettings[KnifeKillExp]
		}
		else
		{
			new iHeadShot = read_data(3)

			if (get_user_flags(iKiller) & g_eSettings[VipFlagBit])
				g_iPlayerData[iKiller][IncreaseExperience] = iHeadShot ? g_eSettings[VipHeadKillExp] : g_eSettings[VipKillExp]
			else
				g_iPlayerData[iKiller][IncreaseExperience] = iHeadShot ? g_eSettings[HeadKillExp] : g_eSettings[KillExp]
		}

		g_iPlayerData[iKiller][Experience] += g_iPlayerData[iKiller][IncreaseExperience]

		CheckRank(iKiller, Positive, true, true)
	}
}

/* =============================================
	Load & Save
============================================= */
public RSH_SQL_Initialize()
{
	new ErrorCode
	g_SqlTuple = Handle:SQL_MakeDbTuple(g_eSave_Settings[Host], g_eSave_Settings[User], g_eSave_Settings[Pass], g_eSave_Settings[Db])
	
	new Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error))
	
	if(SqlConnection == Empty_Handle)
	{
		log_amx(g_Error)
		g_eSave_Settings[SaveType] = FVAULT
	}

	new Handle:Queries = SQL_PrepareQuery(SqlConnection, "CREATE TABLE IF NOT EXISTS `%s`\
	(`%s` VARCHAR(32) NOT NULL,\
	`Experience` INT(10) NOT NULL,\
	`Level` INT(10) NOT NULL,\
	`Played_Time` INT(10) NOT NULL,\
	`Connections` INT(10) NOT NULL,\
	PRIMARY KEY (%s));", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_eSave_Settings[SaveBy])
	
	if(!SQL_Execute(Queries))
	{
		SQL_QueryError(Queries, g_Error, charsmax(g_Error))
		set_fail_state(g_Error)
	}
	
	SQL_FreeHandle(Queries)
	SQL_FreeHandle(SqlConnection)
}

public QueryHandler(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	switch(FailState)
	{
		case -2:
		{
			log_amx("[SQL Error] Failed to connect (%d): %s", Errcode, Error);
		}
		case -1:
		{
			log_amx("[SQL Error] (%d): %s", Errcode, Error);
		}
	}
	return PLUGIN_HANDLED
}

public Save_Data(id, szSaveBy[])
{
	static szData[MAX_FMT_LENGTH], szTemp[MAX_FMT_LENGTH * 2]
	switch(g_eSave_Settings[SaveType])
	{
		case NVAULT:
		{
			formatex(szData, charsmax(szData), "%i#%i#%i#%i", g_iPlayerData[id][Experience], g_iPlayerData[id][Level], get_user_total_playtime(id), g_iPlayerData[id][Connections])
			nvault_set(g_iNVault, szSaveBy, szData)
		}
		case FVAULT:
		{
			formatex(szData, charsmax(szData), "%i#%i#%i#%i", g_iPlayerData[id][Experience], g_iPlayerData[id][Level], get_user_total_playtime(id), g_iPlayerData[id][Connections])
			fvault_set_data(g_eSave_Settings[FVault], szSaveBy, szData)
		}
		case SQL:
		{
			format(szTemp, charsmax(szTemp), "UPDATE `%s` SET `Experience`='%i',`Level`='%i',`Played_Time`='%i',`Connections`='%i' WHERE `%s`='%s';", g_eSave_Settings[Table], g_iPlayerData[id][Experience], g_iPlayerData[id][Level], get_user_total_playtime(id), g_iPlayerData[id][Connections], g_eSave_Settings[SaveBy], szSaveBy)
			SQL_ThreadQuery(g_SqlTuple, "QueryHandler", szTemp)
		}
	}
}

public Load_Data(szSaveBy[], id)
{
	if (!is_user_connected(id))
		return
	
	static szData[MAX_FMT_LENGTH]
	
	switch(g_eSave_Settings[SaveType])
	{
		case NVAULT:
		{
			new iTimeStamp
			if (nvault_lookup(g_iNVault, szSaveBy, szData, charsmax(szData), iTimeStamp))
			{
				parse_loaded_data(id, szData, charsmax(szData))
			}
			else
			{
				register_new_player(id)
			}
		}
		case FVAULT:
		{
			if(fvault_get_data(g_eSave_Settings[FVault], szSaveBy, szData, charsmax(szData)))
			{
				parse_loaded_data(id, szData, charsmax(szData))
			} 
			else 
			{
				register_new_player(id)
			}
		}
		case SQL:
		{
			new ErrorCode
			new Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error))
			
			SQL_QuoteString(SqlConnection, szSaveBy, MAX_NAME_LENGTH, szSaveBy)
			
			if (SqlConnection == Empty_Handle)
			{
				log_amx(g_Error)
				return
			}

			new Handle:Query = SQL_PrepareQuery(SqlConnection, "SELECT * FROM %s WHERE %s = '%s';", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], szSaveBy)

			if (!SQL_Execute(Query))
			{
				SQL_QueryError(Query, g_Error, charsmax(g_Error))
				log_amx(g_Error)
				return
			}
			if (SQL_NumResults(Query) > 0)
			{
				parse_loaded_data(id, "", 0)
			}
			else
			{
				register_new_player(id)
			}
			SQL_FreeHandle(Query)
			SQL_FreeHandle(SqlConnection)
		}
	}
	g_iPlayerData[id][ConnectStatus] = true
}

public parse_loaded_data(id, szData[], iLen)
{
	switch(g_eSave_Settings[SaveType])
	{
		case NVAULT..FVAULT:
		{
			replace_all(szData, iLen, "#", " ")

			new szExp[10], szLevel[10], szTime[32], szConnections[10]
			parse(szData, szExp, charsmax(szExp), szLevel, charsmax(szLevel), szTime, charsmax(szTime), szConnections, charsmax(szConnections))

			g_iPlayerData[id][Experience] = str_to_num(szExp)
			g_iPlayerData[id][Level] = str_to_num(szLevel)
			g_iPlayerData[id][NextLevel] = g_iPlayerData[id][Level]
			g_iPlayerData[id][NextLevel]++

			g_iPlayerData[id][Played_Time] = str_to_num(szTime)
			g_iPlayerData[id][Connections] = str_to_num(szConnections)
			g_iPlayerData[id][Connections]++

			CheckRank(id, Positive, false, false)
		}
		case SQL:
		{
			new ErrorCode
			new Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error))
			
			switch (g_eSave_Settings[SaveByWhat])
			{
				case NAME: SQL_QuoteString(SqlConnection, g_iPlayerData[id][UserName], charsmax(g_iPlayerData[][UserName]), g_iPlayerData[id][UserName])
				case STEAMID: SQL_QuoteString(SqlConnection, g_iPlayerData[id][UserAuthID], charsmax(g_iPlayerData[][UserAuthID]), g_iPlayerData[id][UserAuthID])
				case IP: SQL_QuoteString(SqlConnection, g_iPlayerData[id][UserIP], charsmax(g_iPlayerData[][UserIP]), g_iPlayerData[id][UserIP])
			}
			
			if (SqlConnection == Empty_Handle)
			{
				log_amx(g_Error)
				return 
			}

			static szPreparedQueryFmt[MAX_FMT_LENGTH]
			
			switch (g_eSave_Settings[SaveByWhat])
			{
				case NAME: formatex(szPreparedQueryFmt, charsmax(szPreparedQueryFmt), "SELECT Experience,Level,Played_Time,Connections FROM %s WHERE %s = '%s';", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_iPlayerData[id][UserName])
				case STEAMID: formatex(szPreparedQueryFmt, charsmax(szPreparedQueryFmt), "SELECT Experience,Level,Played_Time,Connections FROM %s WHERE %s = '%s';", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_iPlayerData[id][UserAuthID])
				case IP: formatex(szPreparedQueryFmt, charsmax(szPreparedQueryFmt), "SELECT Experience,Level,Played_Time,Connections FROM %s WHERE %s = '%s';", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_iPlayerData[id][UserIP])
			}
			
			new Handle:Query = SQL_PrepareQuery(SqlConnection, szPreparedQueryFmt)
			
			if (!SQL_Execute(Query))
			{
				SQL_QueryError(Query, g_Error, charsmax(g_Error))
				log_amx(g_Error)
			}
			
			if (SQL_NumResults(Query) > 0)
			{
				g_iPlayerData[id][Experience] = SQL_ReadResult(Query, 0)
				g_iPlayerData[id][Level] = SQL_ReadResult(Query, 1)
				g_iPlayerData[id][NextLevel] = g_iPlayerData[id][Level]
				g_iPlayerData[id][NextLevel]++

				g_iPlayerData[id][Played_Time] = SQL_ReadResult(Query, 2)
				g_iPlayerData[id][Connections] = SQL_ReadResult(Query, 3)
				g_iPlayerData[id][Connections]++

				CheckRank(id, Positive, false, false)
			}
			SQL_FreeHandle(Query)
			SQL_FreeHandle(SqlConnection)
		}
	}
}

public register_new_player(id)
{
	switch(g_eSave_Settings[SaveType])
	{
		case NVAULT..FVAULT:
		{
			g_iPlayerData[id][Experience] = 0
			g_iPlayerData[id][Level] = 0
			g_iPlayerData[id][NextLevel] = 1

			g_iPlayerData[id][Played_Time] = 0
			g_iPlayerData[id][Connections] = 1
		}
		case SQL:
		{
			new ErrorCode
			new Handle:SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, charsmax(g_Error))
			
			switch (g_eSave_Settings[SaveByWhat])
			{
				case NAME: SQL_QuoteString(SqlConnection, g_iPlayerData[id][UserName], charsmax(g_iPlayerData[][UserName]), g_iPlayerData[id][UserName])
				case STEAMID: SQL_QuoteString(SqlConnection, g_iPlayerData[id][UserAuthID], charsmax(g_iPlayerData[][UserAuthID]), g_iPlayerData[id][UserAuthID])
				case IP: SQL_QuoteString(SqlConnection, g_iPlayerData[id][UserIP], charsmax(g_iPlayerData[][UserIP]), g_iPlayerData[id][UserIP])
			}
			
			if(SqlConnection == Empty_Handle)
			{
				log_amx(g_Error)
				return 
			}

			static szPreparedQueryFmt[MAX_FMT_LENGTH]
			
			switch (g_eSave_Settings[SaveByWhat])
			{
				case NAME: formatex(szPreparedQueryFmt, charsmax(szPreparedQueryFmt), "INSERT INTO %s (`%s`,`Experience`,`Level`,`Played_Time`,`Connections`) VALUES ('%s','0','0','0','1');", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_iPlayerData[id][UserName])
				case STEAMID: formatex(szPreparedQueryFmt, charsmax(szPreparedQueryFmt), "INSERT INTO %s (`%s`,`Experience`,`Level`,`Played_Time`,`Connections`) VALUES ('%s','0','0','0','1');", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_iPlayerData[id][UserAuthID])
				case IP: formatex(szPreparedQueryFmt, charsmax(szPreparedQueryFmt), "INSERT INTO %s (`%s`,`Experience`,`Level`,`Played_Time`,`Connections`) VALUES ('%s','0','0','0','1');", g_eSave_Settings[Table], g_eSave_Settings[SaveBy], g_iPlayerData[id][UserIP])
			}

			new Handle:Query = SQL_PrepareQuery(SqlConnection, szPreparedQueryFmt)

			if(!SQL_Execute(Query))
			{
				SQL_QueryError(Query, g_Error, charsmax(g_Error))
				log_amx(g_Error)
			}
			
			SQL_FreeHandle(Query)
			SQL_FreeHandle(SqlConnection)
			
			g_iPlayerData[id][Experience] = 0
			g_iPlayerData[id][Level] = 0
			g_iPlayerData[id][NextLevel] = 1
			
			g_iPlayerData[id][Played_Time] = 0
			g_iPlayerData[id][Connections] = 1
		}
	}
}


/* =============================================
	Natives
============================================= */
public plugin_natives()
{
	register_library("rank_system_huehue")
	
	register_native("get_user_level", "native_get_user_level")
	register_native("set_user_level", "native_set_user_level")
	register_native("get_user_exp", "native_get_user_exp")
	register_native("set_user_exp", "native_set_user_exp")
	register_native("get_user_rank_name", "native_get_user_rank_name")
	register_native("get_user_next_exp", "native_get_user_next_exp")
	register_native("get_user_next_level", "native_get_user_next_level")
	register_native("get_user_next_rank_name", "native_get_user_next_rank_name")
	register_native("get_rank_name_by_level", "native_get_rank_name_by_level")
	register_native("get_rank_exp", "native_get_rank_exp")
	register_native("get_total_ranks", "native_get_total_ranks")
	register_native("update_rank_info", "native_update_rank_info")
	register_native("set_user_rank", "native_set_user_rank")
	register_native("get_plugin_prefix", "native_get_plugin_prefix")
	register_native("get_vip_flag", "native_get_vip_flag")

	register_native("get_hud_colors", "native_get_hud_colors")
	register_native("get_hud_position_x", "native_get_hud_position_x")
	register_native("get_hud_position_y", "native_get_hud_position_y")
	register_native("get_hud_effect", "native_get_hud_effect")

	register_native("get_user_connects", "native_get_user_connects")
	register_native("get_user_playtime", "native_get_user_playtime")
	register_native("get_user_sz_playtime", "native_get_user_sz_playetime")
}

public native_get_user_level(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return -1
	
	return g_iPlayerData[id][Level]
}
public native_set_user_level(iPlugin, iParams)
{
	new id = get_param(1), iLevel = get_param(2)
	
	if (!is_user_connected(id))
		return false
		
	if (g_iPlayerData[id][Level] < iLevel)
	{
		g_iPlayerData[id][Level] = iLevel
		CheckRank(id, Positive, true, true)
	}
	else
	{
		g_iPlayerData[id][Level] = iLevel
		CheckRank(id, Negative, true, true)
	}
	return true
	
}
public native_get_user_exp(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return -1
	
	return g_iPlayerData[id][Experience]
}
public native_set_user_exp(iPlugin, iParams)
{
	new id = get_param(1), iExp = get_param(2)
	
	if (!is_user_connected(id))
		return false
		
	if (g_iPlayerData[id][Experience] < iExp)
	{
		g_iPlayerData[id][Experience] = iExp
		CheckRank(id, Positive, true, true)
	}
	else
	{
		g_iPlayerData[id][Experience] = iExp
		CheckRank(id, Negative, true, true)
	}
	return true
	
}
public native_get_user_rank_name(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return false
	
	new szRankName[64]
	ArrayGetString(g_aRankName, g_iPlayerData[id][Level], szRankName, charsmax(szRankName))
	
	set_string(2, szRankName, get_param(3))
	return true
}

public native_get_user_next_exp(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (g_iPlayerData[id][Level] > iTotalRanks-1)
	{
		return 0
	}
	else
	{
		new iNextLevelExp = ArrayGetCell(g_aRankExp, g_iPlayerData[id][NextLevel])
	
		return iNextLevelExp
	}
	#if AMXX_VERSION_NUM < 183
	return 0
	#endif
}
public native_get_user_next_level(iPlugin, iParams)
{
	new id = get_param(1)

	if (g_iPlayerData[id][Level] > iTotalRanks-1)
	{
		return 0
	}
	else
	{
		return g_iPlayerData[id][NextLevel]
	}
	#if AMXX_VERSION_NUM < 183
	return 0
	#endif
}
public native_get_user_next_rank_name(iPlugin, iParams)
{
	new id = get_param(1)

	if (g_iPlayerData[id][Level] > iTotalRanks-1)
	{
		return 0
	}
	else
	{
		new szRankName[64]
		ArrayGetString(g_aRankName, g_iPlayerData[id][NextLevel], szRankName, charsmax(szRankName))

		set_string(2, szRankName, get_param(3))
	}
	return true
}
public native_get_rank_name_by_level(iPlugin, iParams)
{
	new iLevel = get_param(1)
	
	if (iLevel > iTotalRanks + 1)
	{
		return 0
	}
	
	new szRankName[64]
	ArrayGetString(g_aRankName, iLevel, szRankName, charsmax(szRankName))
	
	set_string(2, szRankName, get_param(3))
	return true
}

public native_get_total_ranks(iPlugin, iParams)
{
	return iTotalRanks
}

public native_update_rank_info(iPlugin, iParams)
{
	new id = get_param(1), iType = get_param(2)

	if (!is_user_connected(id))
		return false

	CheckRank(id, iType, true, true)
	return true
}

public native_get_rank_exp(iPlugin, iParams)
{
	new iExp = ArrayGetCell(g_aRankExp, get_param(1))

	return iExp
}

public native_set_user_rank(iPlugin, iParams)
{
	new id = get_param(1), iRankNum = get_param(2)

	if (!is_user_connected(id))
		return false

	new iExpAmount = ArrayGetCell(g_aRankExp, iRankNum)

	g_iPlayerData[id][Level] = iRankNum
	g_iPlayerData[id][Experience] = iExpAmount
	g_iPlayerData[id][NextLevel] = g_iPlayerData[id][Level]
	g_iPlayerData[id][NextLevel]++

	return true
}

public native_get_plugin_prefix(iPlugin, iParams)
{
	return set_string(1, g_eSettings[Prefix], get_param(2))
}

public native_get_vip_flag(iPlugin, iParams)
{
	return set_string(1, g_eSettings[VipFlag], get_param(2))
}

public native_get_hud_colors(iPlugin, iParams)
{
	return set_string(1, g_eSettings[HudColors], get_param(2))
}

public Float:native_get_hud_position_x(iPlugin, iParams)
{
	return g_eSettings[HudX]
}

public Float:native_get_hud_position_y(iPlugin, iParams)
{
	return g_eSettings[HudY]
}
public native_get_hud_effect(iPlugin, iParams)
{
	return g_eSettings[HudEffect]
}

public native_get_user_connects(iPlugin, iParams)
{
	new id = get_param(1)

	if (!is_user_connected(id))
		return -1

	return g_iPlayerData[id][Connections]
}

public native_get_user_playtime(iPlugin, iParams)
{
	new id = get_param(1)

	if (!is_user_connected(id))
		return -1

	return get_user_total_playtime(id)
}

public native_get_user_sz_playetime(iPlugin, iParams)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
		return false

	new szTime[MAX_FMT_LENGTH]
	get_time_length_ex(get_user_total_playtime(id), timeunit_seconds, szTime, charsmax(szTime))

	set_string(2, szTime, get_param(3))
	return true
}

stock get_user_total_playtime(id)
{
	return g_iPlayerData[id][Played_Time] + get_user_time(id)
}

stock try_precache_generic(const szGeneric[])
{
	if (containi(szGeneric, "sound/") == -1)
	{
		new szGenericSoundFix[64]
		format(szGenericSoundFix, charsmax(szGenericSoundFix), "sound/%s", szGeneric)

		if (file_exists(szGenericSoundFix))
		{
			precache_generic(szGenericSoundFix)
			return true
		}
		else
		{
			log_amx("Failed to precache generic ^"%s^"", szGenericSoundFix)
			return false
		}
	}
	else
	{
		if (file_exists(szGeneric))
		{
			precache_generic(szGeneric)
			return true
		}
		else
		{
			log_amx("Failed to precache generic ^"%s^"", szGeneric)
			return false
		}
	}
}