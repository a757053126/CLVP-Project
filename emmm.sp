#include <sourcemod>
#include <left4downtown>

new bool:g_bIsLobbyReserved = false;
new Handle:g_hCriticalCvar = INVALID_HANDLE;

public void OnPluginStart()
{
	g_hCriticalCvar = FindConVar("sv_allow_lobby_connect_only");

	if (g_hCriticalCvar == INVALID_HANDLE)
	{
		//emmm, that should be never happen
		SetFailState("Failed find convar 'sv_allow_lobby_connect_only' handle");
	}
}

public void OnClientPutInServer(client)
{
	if (!IsClientValid(client)) return;

	if (!g_bIsLobbyReserved)
	{
		g_bIsLobbyReserved = true;
		L4D_LobbyUnreserve();
		SetConVarInt(g_hCriticalCvar, 0);
	}
}

public void OnClientDisconnect(client)
{
	if (!IsClientValid(client)) return;

	CreateTimer(1.0, Timer_DelayCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DelayCheck(Handle:timer)
{
	new players = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i)) players ++;
	}
	if (players == 0)
	{
		SetConVarInt(g_hCriticalCvar, 1);
		g_bIsLobbyReserved = false;
	}
}

stock bool IsClientValid(client)
{
	if (client > 0 && client <= MaxClients
		&& IsClientConnected(client)
		&& !IsFakeClient(client)
	) return true; else return false;
}

//...