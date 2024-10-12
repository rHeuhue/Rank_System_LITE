#include <amxmodx>

/* Common include libraries */
#include <engine>
#include <rank_system_huehue>

#define PLUGIN  "Addon: Rank Information"
#define VERSION "1.1"
#define AUTHOR  "Huehue @ AMXX-BG.INFO"
#define GAMETRACKER "rank_system_info"

new g_SyncHudMessage

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(GAMETRACKER, AUTHOR, FCVAR_SERVER | FCVAR_SPONLY)
	set_cvar_string(GAMETRACKER, AUTHOR)

	g_SyncHudMessage = CreateHudSyncObj()

	new iEnt = create_entity("info_target")
	entity_set_string(iEnt, EV_SZ_classname, "task_entity")
										
	register_think("task_entity", "HudEntity")
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 1.0)

	register_event("StatusValue", "EventStatusValue", "b", "1>0", "2>0")
}

public HudEntity(iEnt)
{
	static iPlayers[32], iNum, id, iLen
	get_players(iPlayers, iNum, "ach")
			
	for (new i = 0; i < iNum; i++)
	{
		id = iPlayers[i]

		new szRankName[2][64], szHudMessage[128]
		get_user_rank_name(id, szRankName[0], charsmax(szRankName[]))
		get_user_next_rank_name(id, szRankName[1], charsmax(szRankName[]))
				
		iLen = formatex(szHudMessage, charsmax(szHudMessage), "Rank: %s^n", szRankName[0])
				

		if (get_user_level(id) > get_total_ranks()-1)
		{
			iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Experience: %i", get_user_exp(id))
		}
		else
		{
			iLen += formatex(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "Experience: %i/%i^nNext Rank: %s",
				get_user_exp(id), get_user_next_exp(id), szRankName[1])
		}

		static szColors[12], szRed[6], szGreen[6], szBlue[6], iRed, iGreen, iBlue
		get_hud_colors(szColors, charsmax(szColors))

		parse(szColors, szRed, charsmax(szRed), szGreen, charsmax(szGreen), szBlue, charsmax(szBlue))

		iRed = str_to_num(szRed)
		iGreen = str_to_num(szGreen)
		iBlue = str_to_num(szBlue)

		set_hudmessage(iRed, iGreen, iBlue, get_hud_position_x(), get_hud_position_y(), get_hud_effect(), 0.8, 0.8)
		ShowSyncHudMsg(id, g_SyncHudMessage, "%s", szHudMessage)
				
	}
	entity_set_float(iEnt, EV_FL_nextthink, get_gametime() + 0.6)
}

public EventStatusValue(const id)
{
	static szMessage[34], iPlayer, iAux
	get_user_aiming(id, iPlayer, iAux)
	
	if (is_user_alive(iPlayer))
	{
		static szRankName[64]
		get_user_rank_name(iPlayer, szRankName, charsmax(szRankName))

		static szFlag[6]
		get_vip_flag(szFlag, charsmax(szFlag))

		if (get_user_flags(iPlayer) & read_flags(szFlag))
			formatex(szMessage, charsmax(szMessage), "1 VIP: %%p2 | Rank: %s | Experience: %s", szRankName, get_user_exp(iPlayer))
		else
			formatex(szMessage, charsmax(szMessage), "1 PLAYER: %%p2 | Rank: %s | Experience: %s", szRankName, get_user_exp(iPlayer))

		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText") , _, id)
		write_byte(0)
		write_string(szMessage)
		message_end()
	}
}