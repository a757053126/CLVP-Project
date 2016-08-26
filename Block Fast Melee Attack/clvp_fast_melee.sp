/*
** 插件功能: 修复近战武器速砍的BUG
** 插件作者: Janus (QQ:781662377)
** 开源协议: GNU General Public License (GPL) V3.0
** 已知问题: 没有考虑lateload的情况，如果插件在游戏中途加载可能没效果.
** 原插件地址: https://forums.alliedmods.net/showthread.php?p=2407280
**
** https://github.com/qq781662377/CLVP-Project
** 请自觉遵守开源协议并保留作者信息，谢谢 >w<
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

#define CLVP_AUTHOR		"Janus (QQ:781662377)"
#define	CLVP_URL		"http://steamcommunity.com/groups/CLVP"

new Float:fLastMeleeSwing[MAXPLAYERS+1];

public Plugin:myinfo = {name = "[CLVP GPL V3] Block Fast Melee Attack", version = "1.0", author = CLVP_AUTHOR, url = CLVP_URL};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:FolderName[32];
	GetGameFolderName(FolderName, sizeof(FolderName));
	if (!StrEqual(FolderName, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugins only support Left4Dead2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new oldteam = GetEventInt(event, "oldteam");
	new nowteam = GetEventInt(event, "team");
	
	if (IsClientInGameEx(client) && nowteam == 2)
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
		fLastMeleeSwing[client] = 0.0;
	}
	
	if (IsClientInGameEx(client) && (nowteam == 1 || nowteam == 3) && oldteam == 2)
	{
		SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
		fLastMeleeSwing[client] = 0.0;
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientValid(client) && GetClientTeam(client) == 2)
	{
		decl String:wpname[32];
		GetEventString(event, "weapon", wpname, sizeof(wpname));
		if (StrEqual(wpname, "melee", false)) {fLastMeleeSwing[client] = GetGameTime();}
	}
}

public OnWeaponSwitched(client, weapon)
{
	if (IsClientValid(client))
	{
		decl String:wpname[32];
		GetEdictClassname(weapon, wpname, sizeof(wpname));
		if (StrEqual(wpname, "weapon_melee", false))
		{
			new Float:fByServerNextAttack = GetGameTime() + 0.5;
			new Float:fShouldBeNextAttack = fLastMeleeSwing[client] + 0.92;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", (fShouldBeNextAttack > fByServerNextAttack) ? fShouldBeNextAttack : fByServerNextAttack);
		}
	}
}

stock bool:IsClientValid(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{return true;} else {return false;}
}

stock bool:IsClientInGameEx(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{return true;} else {return false;}
}