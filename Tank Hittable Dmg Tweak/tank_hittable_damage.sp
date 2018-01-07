//Code written by Janus(QQ:781662377)
//Open source license with MIT.
//github.com/qq781662377/CLVP-Project
#include <sourcemod>
#include <sdkhooks>

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldteam = GetEventInt(event, "oldteam");
	new nowteam = GetEventInt(event, "team");
	
	if (IsClientInGameEx(client) && nowteam == 2)
	{SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);}
	
	if (IsClientInGameEx(client) && (nowteam == 1 || nowteam == 3) && oldteam == 2)
	{SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (!IsClientInGameEx(victim) || GetClientTeam(victim) != 2) return Plugin_Continue;
	if (!IsClientInGameEx(attacker) || GetClientTeam(attacker) != 3) return Plugin_Continue;
	if (GetEntData(attacker, FindSendPropOffs("Tank", "m_zombieClass")) != 8) return Plugin_Continue;
	if (!IsValidEntity(inflictor) || !IsValidEdict(inflictor)) return Plugin_Continue;
	
	decl String:wpname[32];
	GetEntityClassname(inflictor, wpname, sizeof(wpname));
	
	if (!StrEqual(wpname, "weapon_tank_claw", false) && !StrEqual(wpname, "tank_rock", false))
	{
		//更改铁对生还者的伤害
		damage = 25.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool:IsClientInGameEx(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{return true;} else {return false;}
}