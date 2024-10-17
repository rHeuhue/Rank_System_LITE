#include <amxmodx>
#include <amxmisc>

/* Common include libraries */
#include <rank_system_huehue>
#tryinclude <cromchat>

#define PLUGIN  "Addon: Rank Information"
#define VERSION "1.3"
#define AUTHOR  "Huehue @ AMXX-BG.INFO"
#define GAMETRACKER "rank_system_info"

#define RSH_TASKID	1030

// Uncomment to show in hud player total play time
//#define SHOW_PLAYTIME

new g_SyncHudMessage

enum _:eHudData
{
	Red,
	Green,
	Blue,
	Float:X_Coord,
	Float:Y_Coord,
	Effect
}

new g_iHudSettings[eHudData]

new bool:g_bRankHudMessage[MAX_PLAYERS + 1] = {true, ...}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(GAMETRACKER, AUTHOR, FCVAR_SERVER | FCVAR_SPONLY)
	set_cvar_string(GAMETRACKER, AUTHOR)

	register_clcmd("say /rankhud", "Command_ToggleRankHud")
	register_clcmd("say_team /rankhud", "Command_ToggleRankHud")

	g_SyncHudMessage = CreateHudSyncObj()

	register_event("StatusValue", "EventStatusValue", "b", "1>0", "2>0")

	#if defined _cromchat_included
	new szPrefix[32]
	get_plugin_prefix(szPrefix, charsmax(szPrefix))
	CC_SetPrefix(szPrefix)
	#endif
}

public plugin_cfg()
{
	static szColors[12], szRed[6], szGreen[6], szBlue[6]
	get_hud_colors(szColors, charsmax(szColors))

	parse(szColors, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))

	g_iHudSettings[Red] = str_to_num(szRed)
	g_iHudSettings[Green] = str_to_num(szGreen)
	g_iHudSettings[Blue] = str_to_num(szBlue)
	g_iHudSettings[X_Coord] = get_hud_position_x()
	g_iHudSettings[Y_Coord] = get_hud_position_y()
	g_iHudSettings[Effect] = get_hud_effect()
}

public client_putinserver(id)
{
	g_bRankHudMessage[id] = true

	set_task_ex(1.0, "Display_RankHud_Info", id + RSH_TASKID, .flags = SetTask_Repeat)
}

public Command_ToggleRankHud(id)
{
	g_bRankHudMessage[id] = !g_bRankHudMessage[id]

	#if defined _cromchat_included
	CC_SendMatched(id, CC_COLOR_GREY, "&x03You have successfully turned &x04%s &x03rank hud message!", g_bRankHudMessage[id] ? "on" : "off")
	#else
	client_print_color(id, print_team_grey, "^4* ^3You have successfully turned ^4%s ^3rank hud message!", g_bRankHudMessage[id] ? "on" : "off")
	#endif
	return PLUGIN_HANDLED
}

public Display_RankHud_Info(id)
{
	id -= RSH_TASKID

	if (!g_bRankHudMessage[id])
		return

	static iDeadId
	iDeadId = id

	if (is_user_alive(id))
	{
		UTIL_FormatHudMessage(id, id)
	}
	else
	{
		iDeadId = pev(id, pev_iuser2)

		if (iDeadId)
			UTIL_FormatHudMessage(id, iDeadId)
	}
}

UTIL_FormatHudMessage(id, iDeadId)
{
	static iLen
	new szRankName[2][64], szHudMessage[128]
	get_user_rank_name(iDeadId, szRankName[0], charsmax(szRankName[]))
	get_user_next_rank_name(iDeadId, szRankName[1], charsmax(szRankName[]))
					
	iLen = formatex(szHudMessage, charsmax(szHudMessage), "Rank: %s^n", szRankName[0])
					

	if (get_user_level(iDeadId) > get_total_ranks()-1)
	{
		iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Level: %i^n", get_user_level(iDeadId), get_total_ranks() - 1)
		iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Experience: %i", get_user_exp(iDeadId))
	}
	else
	{
		iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Level: %i/%i^n", get_user_level(iDeadId), get_total_ranks())
		iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Experience: %i/%i^nNext Rank: %s",
				get_user_exp(iDeadId), get_user_next_exp(iDeadId), szRankName[1])
	}

	#if defined SHOW_PLAYTIME
	new szTime[MAX_FMT_LENGTH]
	get_user_sz_playtime(iDeadId, szTime, charsmax(szTime))
	iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "^nPlay Time: %s", szTime)
	#endif

	set_hudmessage(g_iHudSettings[Red], g_iHudSettings[Green], g_iHudSettings[Blue], g_iHudSettings[X_Coord], g_iHudSettings[Y_Coord], g_iHudSettings[Effect], 0.9, 0.9)
	ShowSyncHudMsg(id, g_SyncHudMessage, "%s", szHudMessage)
}

public EventStatusValue(const id)
{
	static szMessage[MAX_FMT_LENGTH], iPlayer, iAux
	get_user_aiming(id, iPlayer, iAux)
	
	if (is_user_alive(iPlayer))
	{
		static szRankName[64]
		get_user_rank_name(iPlayer, szRankName, charsmax(szRankName))

		static szFlag[6]
		get_vip_flag(szFlag, charsmax(szFlag))

		if (get_user_flags(iPlayer) & read_flags(szFlag))
			formatex(szMessage, charsmax(szMessage), "1 VIP: %%p2 | Rank: %s | Experience: %i", szRankName, get_user_exp(iPlayer))
		else
			formatex(szMessage, charsmax(szMessage), "1 PLAYER: %%p2 | Rank: %s | Experience: %i", szRankName, get_user_exp(iPlayer))

		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText") , _, id)
		write_byte(0)
		write_string(szMessage)
		message_end()
	}
}