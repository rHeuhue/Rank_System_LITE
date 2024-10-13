#include <amxmodx>
#include <rank_system_huehue>

/* Common include libraries */
#include <amxmisc>
#tryinclude <cromchat>

#define PLUGIN  "Addon: Admin Control Experience & Ranks"
#define VERSION "1.1"
#define AUTHOR  "Huehue @ AMXX-BG.INFO"
#define GAMETRACKER "rank_system_admin_commands"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(GAMETRACKER, AUTHOR, FCVAR_SERVER | FCVAR_SPONLY)
	set_cvar_string(GAMETRACKER, AUTHOR)

	register_clcmd("say /rankmenu", "Command_RankMenu", ADMIN_RCON, "- Toggles up the rank menu")
	register_concmd("amx_rankmenu", "Command_RankMenu", ADMIN_RCON, "- Toggles up the rank menu")
	register_clcmd("XP_Amount", "Command_XP_Amount", ADMIN_RCON)
	register_clcmd("Set_Level", "Command_Set_Level", ADMIN_RCON)

	#if defined _cromchat_included
	new szPrefix[32]
	get_plugin_prefix(szPrefix, charsmax(szPrefix))
	CC_SetPrefix(szPrefix)
	#endif
}

/* ================================================
	Rank Menus & Commands
================================================ */
new g_iPlayer[33], g_iMenuType[33]

public Command_RankMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	ToggleRankMenu(id)
	
	return PLUGIN_HANDLED
}
public ToggleRankMenu(id)
{
	static szTitle[64]
	formatex(szTitle, charsmax(szTitle), "\rHuehue's \d~ \wRank Menu")
	new iMenu = menu_create(szTitle, "rankmenu_handler")
	
	menu_additem(iMenu, "\yGive \dPlayer \rXP")
	menu_additem(iMenu, "\yTake \dPlayer \rXP^n")
	menu_additem(iMenu, "\ySet \dPlayer \rRank")
	menu_additem(iMenu, "\ySet \dPlayer \rLevel")
	
	menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\w")
	menu_setprop(iMenu, MPROP_EXITNAME, "\yExit \rRank Menu\d..")
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}
public rankmenu_handler(id, iMenu, Item)
{
	if (Item == MENU_EXIT)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	Item++
	PlayerSetMenu(id, Item)
	
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public PlayerSetMenu(id, iType)
{
	static szTitle[64]
	formatex(szTitle, charsmax(szTitle), "Choose Player to %s %s", iType == 1 ? "Give" : iType == 2 ? "Take" : "Set", iType == 4 ? "Level" : iType == 3 ? "Rank" : "XP")

	new iMenu = menu_create(szTitle, "player_set_menu_handler")

	g_iMenuType[id] = iType

	new iPlayers[32], iNum, iPlayer
	new szName[34], szTempID[10]
	get_players(iPlayers, iNum)
			
	for(new i; i < iNum; i++)
	{
		iPlayer = iPlayers[i]
		if(!is_user_connected(iPlayer))
			continue
				
		get_user_name(iPlayer, szName, sizeof szName - 1)
		num_to_str(iPlayer, szTempID, charsmax(szTempID))
		menu_additem(iMenu, szName, szTempID)
	}
	menu_setprop(iMenu, MPROP_EXITNAME, "Go back..")
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public player_set_menu_handler(id, iMenu, Item)
{
	if (Item == MENU_EXIT)
	{
		menu_destroy(iMenu)
		ToggleRankMenu(id)
		g_iMenuType[id] = 0
		return PLUGIN_HANDLED
	}

	new szData[6], iName[64], iAccess, iCallBack
	menu_item_getinfo(iMenu, Item, iAccess, szData, charsmax(szData), iName, charsmax(iName), iCallBack)
	
	g_iPlayer[id] = str_to_num(szData)


	if (!is_user_connected(g_iPlayer[id]))
	{
		g_iPlayer[id] = 0
		#if defined _cromchat_included
		CC_SendMatched(id, CC_COLOR_GREY, "&x03The player you chose is not in the server.")
		#else
		client_print_color(id, print_team_grey, "^4* ^3The player you chose is not in the server.")
		#endif
		return PLUGIN_HANDLED
	}

	new szRankName[64]
	get_user_rank_name(g_iPlayer[id], szRankName, charsmax(szRankName))

	#if defined _cromchat_included
	CC_SendMatched(id, CC_COLOR_GREY, "&x03Player &x04%s &x03is &x04Level %i %s &x03with &x04%i Experience&x03.", iName, get_user_level(g_iPlayer[id]), szRankName, get_user_exp(g_iPlayer[id]))
	#else
	client_print_color(id, print_team_grey, "^4* ^3Player ^4%s ^3is ^4Level %i %s ^3with ^4%i Experience^3.", iName, get_user_level(g_iPlayer[id]), szRankName, get_user_exp(g_iPlayer[id]))
	#endif

	switch(g_iMenuType[id])
	{
		case 1..2: client_cmd(id, "messagemode XP_Amount")
		case 3: SetRankMenu(id)
		case 4: client_cmd(id, "messagemode Set_Level")
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public Command_XP_Amount(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	if (!g_iPlayer[id])
		return PLUGIN_HANDLED
		
	if (!is_user_connected(g_iPlayer[id]))
	{
		#if defined _cromchat_included
		CC_SendMatched(id, CC_COLOR_GREY, "&x03The player you chose is not in the server.")
		#else
		client_print_color(id, print_team_grey, "^4* ^3The player you chose is not in the server.")
		#endif
		return PLUGIN_HANDLED
	}
	
	new szArgs[12]
	read_argv(1, szArgs, charsmax(szArgs))
	
	new iXP = str_to_num(szArgs)
	
	new szNames[2][32]
	get_user_name(id, szNames[0], charsmax(szNames[]))
	get_user_name(g_iPlayer[id], szNames[1], charsmax(szNames[]))
	
	switch (g_iMenuType[id])
	{
		case 1:
		{
			set_user_exp(g_iPlayer[id], get_user_exp(g_iPlayer[id]) + iXP)
			#if defined _cromchat_included
			CC_SendMatched(0, CC_COLOR_GREY, "&x03%s&x01 gave &x04%i XP &x01to &x03%s&x01.", szNames[0], iXP, szNames[1])
			#else
			client_print_color(0, print_team_grey, "^4* ^3%s ^1gave ^4%i XP ^1to ^3%s^1.", szNames[0], iXP, szNames[1])
			#endif
		}
		case 2:
		{
			set_user_exp(g_iPlayer[id], get_user_exp(g_iPlayer[id]) - iXP)
			#if defined _cromchat_included
			CC_SendMatched(0, CC_COLOR_GREY, "&x03%s&x01 took &x04%i XP &x01from &x03%s&x01.", szNames[0], iXP, szNames[1])
			#else
			client_print_color(0, print_team_grey, "^4* ^3%s ^1took ^4%i XP ^1from ^3%s^1.", szNames[0], iXP, szNames[1])
			#endif
		}
	}
	g_iPlayer[id] = 0
	g_iMenuType[id] = 0
	
	ToggleRankMenu(id)
	
	return PLUGIN_HANDLED
}

public SetRankMenu(id)
{
	static szTitle[64]
	formatex(szTitle, charsmax(szTitle), "Choose Rank to Set")
	new iMenu = menu_create(szTitle, "set_rank_handler")
	
	//new szItem[100]
	new iNum[6]
	new szRankName[64]
	
	for(new i = 0; i <= get_total_ranks(); i++)
	{
		get_rank_name_by_level(i, szRankName, charsmax(szRankName))

		// Debug test message
		//formatex(szItem, charsmax(szItem), "%s - Level %i", szRankName, PlayerData[i][LEVEL])
		formatex(iNum, charsmax(iNum), "%i", i)
		
		menu_additem(iMenu, szRankName, iNum)
	}
	menu_setprop(iMenu, MPROP_EXITNAME, "Go back..")
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}
public set_rank_handler(id, iMenu, Item)
{
	if (Item == MENU_EXIT)
	{
		ToggleRankMenu(id)
		return PLUGIN_HANDLED
	}
	
	new szData[6], iAccess, iCallBack
	menu_item_getinfo(iMenu, Item, iAccess, szData, charsmax(szData), _, _, iCallBack)
	
	new iLevel = str_to_num(szData)
	
	if (g_iPlayer[id] >= 0 || g_iPlayer[id] <= get_total_ranks())
	{
		set_user_rank(g_iPlayer[id], iLevel)
		
		new szNames[2][32]
		get_user_name(id, szNames[0], charsmax(szNames[]))
		get_user_name(g_iPlayer[id], szNames[1], charsmax(szNames[]))
		
		new szRankName[64]
		get_user_rank_name(g_iPlayer[id], szRankName, charsmax(szRankName))
		
		#if defined _cromchat_included
		CC_SendMatched(0, CC_COLOR_GREY, "&x03%s&x01 set &x04Level %i %s &x01to &x03%s&x01.", szNames[0], iLevel, szRankName, szNames[1])
		#else
		client_print_color(0, print_team_grey, "^4* ^3%s ^1set ^4Level %i %s ^1to %s^1.", szNames[0], iLevel, szRankName, szNames[1])
		#endif
	}
	
	g_iPlayer[id] = 0
	g_iMenuType[id] = 0
	
	ToggleRankMenu(id)
	
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}
public Command_Set_Level(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	if (!g_iPlayer[id])
		return PLUGIN_HANDLED
		
	if (!is_user_connected(g_iPlayer[id]))
	{
		#if defined _cromchat_included
		CC_SendMatched(id, CC_COLOR_GREY, "&x03The player you chose is not in the server.")
		#else
		client_print_color(id, print_team_grey, "^4* ^3The player you chose is not in the server.")
		#endif
		return PLUGIN_HANDLED
	}
	
	new szArgs[12]
	read_argv(1, szArgs, charsmax(szArgs))
	
	new iLevel = str_to_num(szArgs)
	
	if (iLevel > get_total_ranks() || iLevel < 0)
	{
		#if defined _cromchat_included
		CC_SendMatched(id, CC_COLOR_GREY, "&x03You can set level in between&x04 0 &x03and &x04%i &x03only!", get_total_ranks())
		#else
		client_print_color(id, print_team_grey, "^4* ^3You can set level in between^4 0 ^3and^4 %i ^3only!")
		#endif

		PlayerSetMenu(id, 4)
		return PLUGIN_HANDLED;
	}
	
	new szNames[2][32]
	get_user_name(id, szNames[0], charsmax(szNames[]))
	get_user_name(g_iPlayer[id], szNames[1], charsmax(szNames[]))

	set_user_rank(g_iPlayer[id], iLevel)
	
	new szRankName[64]
	get_user_rank_name(g_iPlayer[id], szRankName, charsmax(szRankName))
	
	#if defined _cromchat_included
	CC_SendMatched(0, CC_COLOR_GREY, "&x03%s &x01set &x04Level %i %s &x01to &x03%s", szNames[0], iLevel, szRankName, szNames[1])
	#else
	client_print_color(0, print_team_grey, "^4* ^3%s ^1set ^4Level %i %s ^1to ^3%s", szNames[0], iLevel, szRankName, szNames[1])
	#endif

	g_iPlayer[id] = 0
	g_iMenuType[id] = 0
	
	ToggleRankMenu(id)
	
	return PLUGIN_HANDLED
}