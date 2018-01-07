//Code written by Janus(QQ:781662377)
//Open source license with MIT.
//github.com/qq781662377/CLVP-Project
#include <sourcemod>
#include <sdktools>

new bool:TakenBlock[MAXPLAYERS+1];

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGameEx(client) || GetClientTeam(client) != 2) return Plugin_Continue;
	if (!IsPlayerAlive(client) || IsPlayerIncap(client) || IsPlayerLedge(client)) return Plugin_Continue;
	
	if (buttons & IN_USE) //IN_USE = 游戏中的默认E键
	{
		if (!TakenBlock[client]) {DisposeItemTake(client);}
	}
	else {TakenBlock[client] = false;}
	return Plugin_Continue;
}

stock DisposeItemTake(client)
{
	new target = GetClientAimTarget(client, true);
	if (!IsClientInGameEx(target) || GetClientTeam(target) != 2) return;
	
	if (!IsFakeClient(target))
	{
		PrintCenterText(client, "只能拿走电脑玩家的物品哦~");
		return;
	}
	if (!InTransDistance(client, target))
	{
		PrintCenterText(client, "离近一点才能拿走物品哦~");
		return;
	}
	//0=主武器 1=副武器 2=投掷武器 3=医疗品 4=药品
	//不知道这个楼主想只拿走投掷还是全部都能拿走呢..
	//这个循环从2开始拿走东西，也就是只能拿2/3/4
	//如果想什么都能拿走，就把下面的new i = 2改为new i = 0
	for (new i = 2; i <= 4; i++)
	{
		new weapon = GetPlayerWeaponSlot(target, i);
		if (IsValidEntity(weapon) && IsValidEdict(weapon))
		{
			RemovePlayerItem(target, weapon); //删除电脑的物品
			EquipPlayerWeapon(client, weapon); //装备物品到玩家身上
			ClientCommand(client, "slot%i", i + 1); //切换到拿过来的物品
			
			decl String:wpname[48];
			GetWeaponName(weapon, wpname, sizeof(wpname));
			PrintCenterText(client, "你拿走了 %N 的 %s", target, wpname);
			TakenBlock[client] = true;
			return;
		}
	}
	PrintCenterText(client, "这个电脑贼穷，没有东西可以拿哦~");
}

stock bool:InTransDistance(client, target)
{
	new Float:Origin1[3], Float:Origin2[3];
	GetClientAbsOrigin(client, Origin1);
	GetClientAbsOrigin(target, Origin2);
	
	if (GetVectorDistance(Origin1, Origin2, true) < 48400)
	{return true;} else {return false;}
}

stock GetWeaponName(weapon, String:buffer[], maxlen)
{
	decl String:wpname[48];
	GetEntityClassname(weapon, wpname, sizeof(wpname));
	
	if (StrEqual(wpname, "weapon_molotov", false))
	{strcopy(buffer, maxlen, "燃烧瓶");}
	else if (StrEqual(wpname, "weapon_pipe_bomb", false))
	{strcopy(buffer, maxlen, "土质手雷");}
	else if (StrEqual(wpname, "weapon_vomitjar", false))
	{strcopy(buffer, maxlen, "胆汁罐");}
	else if (StrEqual(wpname, "weapon_defibrillator", false))
	{strcopy(buffer, maxlen, "电击器");}
	else if (StrEqual(wpname, "weapon_first_aid_kit", false))
	{strcopy(buffer, maxlen, "医疗包");}
	else if (StrEqual(wpname, "weapon_adrenaline", false))
	{strcopy(buffer, maxlen, "肾上腺素");}
	else if (StrEqual(wpname, "weapon_pain_pills", false))
	{strcopy(buffer, maxlen, "止疼药");}
	else if (StrEqual(wpname, "weapon_upgradepack_explosive", false))
	{strcopy(buffer, maxlen, "高爆弹部署盒");}
	else if (StrEqual(wpname, "weapon_upgradepack_incendiary", false))
	{strcopy(buffer, maxlen, "燃烧弹部署盒");}
}

stock bool:IsClientInGameEx(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{return true;} else {return false;}
}

stock bool:IsPlayerLedge(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"))
	{return true;} else {return false;}
}

stock bool:IsPlayerIncap(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}