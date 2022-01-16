/**
 * -
 * My contacts: 
 * 	https://vk.com/felhalas
 * 	https://t.me/nikolaygaus
 * 
 * My group: https://vk.com/ragashop
 * Github: https://github.com/nikolaygaus
 * -
 * 
 * # Changelog:
 * 	Version 1.0.1
 * 		- public release.
 * 	Version 1.0.2
 * 		- added voice blocking for viewers or for everyone.
 * 		- added disable notifications in chat.
 * 		- added lang keys.
**/

new const PluginVersion[] = "1.0.2";
new const PluginPrefix[] = "^4[RAGASHOP]^1:";

// Comment if you don't want to hear anyone.
#define BLOCK_VOICE_ONLY_TEAM

// Comment if you don't want chat notifications.
#define NOTIFY_PLAYERS

#include <amxmodx>
#include <reapi>

new bool: g_bHookStatus[3];
new HookChain: g_pHook_RestartRound;
new HookChain: g_pHook_CanPlayerHearPlayer;

public plugin_init() {

	register_plugin("Block Voice 1x1", PluginVersion, "Ragamafona");
	register_cvar("block_voice_1x1", PluginVersion, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);

#if defined NOTIFY_PLAYERS
	{
		new TransKey: pKey;

		pKey = CreateLangKey("ML_BLOCK_VOICE_TYPE_0");
		AddTranslation("ru", pKey, "^3Террорист ^1остался один. Микрофон у его команды ^3отключен^1.");
		AddTranslation("en", pKey, "^3Terrorist ^1was left alone. His team's microphone is ^3off^1.");

		pKey = CreateLangKey("ML_BLOCK_VOICE_TYPE_1");
		AddTranslation("ru", pKey, "^3Спецназовец ^1остался один. Микрофон у его команды ^3отключен^1.");
		AddTranslation("en", pKey, "^3Counter-terrorist ^1was left alone. His team's microphone is ^3off^1.");
	}
#endif

	DisableHookChain(g_pHook_RestartRound =
		RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound", .post = false)
	);

	// I do not use the rg_set_can_hear_player method because it is used for various mute/gag systems.
	DisableHookChain(g_pHook_CanPlayerHearPlayer =
		RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "@CSGameRules_CanPlayerHearPlayer", .post = false)
	);

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", .post = true);
}

@CSGameRules_RestartRound() {

	arrayset(g_bHookStatus, false, sizeof(g_bHookStatus));

	DisableHookChain(g_pHook_RestartRound);
	DisableHookChain(g_pHook_CanPlayerHearPlayer);
}

@CSGameRules_CanPlayerHearPlayer(const pReceiver, const pSender) {

	if(pSender == pReceiver || !is_user_alive(pReceiver))
		return HC_CONTINUE;

	static iReceiverTeam;

	iReceiverTeam = get_member(pReceiver, m_iTeam);

#if defined BLOCK_VOICE_ONLY_TEAM
	if(~(BIT(iReceiverTeam)|BIT(_:TEAM_SPECTATOR)) & BIT(get_member(pSender, m_iTeam)))
		return HC_CONTINUE;
#endif

	if(!g_bHookStatus[iReceiverTeam])
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_BOOL, false);
	return HC_SUPERCEDE;
}

@CBasePlayer_Killed_Post() {

	Func_CheckPlayersCount();
}

public client_disconnected(pPlayer) {

	Func_CheckPlayersCount();
}

Func_CheckPlayersCount() {

	new iAlivePlayers[2];

	rg_initialize_player_counts(iAlivePlayers[0], iAlivePlayers[1]);

	if(!g_bHookStatus[0] && iAlivePlayers[0] == 1)
	{
		g_bHookStatus[0] = true;
#if defined NOTIFY_PLAYERS
		Func_NotifyPlayers(1);
#endif
	}

	if(!g_bHookStatus[1] && iAlivePlayers[1] == 1)
	{
		g_bHookStatus[1] = true;
#if defined NOTIFY_PLAYERS
		Func_NotifyPlayers(2);
#endif
	}

	if(!g_bHookStatus[2] && (g_bHookStatus[0] || g_bHookStatus[1]))
	{
		EnableHookChain(g_pHook_RestartRound);
		EnableHookChain(g_pHook_CanPlayerHearPlayer);
		g_bHookStatus[2] = true;
	}
}

#if defined NOTIFY_PLAYERS
Func_NotifyPlayers(const iTeam) {

	new szLangKey[MAX_NAME_LENGTH];
	formatex(szLangKey, charsmax(szLangKey), "ML_BLOCK_VOICE_TYPE_%i", iTeam - 1);

	for(new iPlayer = 1, iPrintColor = iTeam == 1 ? print_team_red : print_team_blue; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_connected(iPlayer) || is_user_alive(iPlayer))
			continue;

		if(get_member(iPlayer, m_iTeam) != iTeam)
			continue;

		client_print_color(iPlayer, iPrintColor, "%s %l", PluginPrefix, szLangKey);
	}
}
#endif