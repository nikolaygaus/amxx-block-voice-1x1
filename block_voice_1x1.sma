/**
 * -
 * My contacts: 
 * 	https://vk.com/felhalas
 * 	https://t.me/nikolaygaus
 * 
 * My group: https://vk.com/ragashop
 * Github: https://github.com/nikolaygaus
 * -
**/

new const PluginVersion[] = "1.0.0";
new const PluginPrefix[] = "^4[RAGASHOP]^1:";

#include <amxmodx>
#include <reapi>

new bool: g_bHookStatus[3];
new HookChain: g_pHook_RestartRound;
new HookChain: g_pHook_CanPlayerHearPlayer;

public plugin_init() {

	register_plugin("Block Voice 1x1", PluginVersion, "Ragamafona");

	DisableHookChain(g_pHook_RestartRound =
		RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound", .post = false)
	);
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

	static iPlayerTeam;

	iPlayerTeam = get_member(pReceiver, m_iTeam);

	if(_:TEAM_TERRORIST > iPlayerTeam > _:TEAM_CT || get_member(pSender, m_iTeam) != iPlayerTeam)
		return HC_CONTINUE;

	if(!g_bHookStatus[iPlayerTeam])
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

		client_print_color(0, print_team_red, "%s ^3Террорист ^1остался один. Микрофон у его команды ^3отключен^1.", PluginPrefix);
	}

	if(!g_bHookStatus[1] && iAlivePlayers[1] == 1)
	{
		g_bHookStatus[1] = true;

		client_print_color(0, print_team_blue, "%s ^3Спецназовец ^1остался один. Микрофон у его команды ^3отключен^1.", PluginPrefix);
	}

	if(!g_bHookStatus[2] && (g_bHookStatus[0] || g_bHookStatus[1]))
	{
		EnableHookChain(g_pHook_RestartRound);
		EnableHookChain(g_pHook_CanPlayerHearPlayer);
		g_bHookStatus[2] = true;
	}
}