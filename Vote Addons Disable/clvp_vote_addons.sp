/*
** 插件功能: 投票开关禁用MOD的功能
** 插件作者: Janus (QQ:781662377)
** 开源协议: GNU General Public License (GPL) V3.0
** 依赖扩展: BuiltinVotes 0.5.8 / Left4Downtown2 0.5.7+
** BuiltinVotes: https://forums.alliedmods.net/showthread.php?t=162164
** Left4Downtown2: https://github.com/Attano/Left4Downtown2
**
** https://github.com/qq781662377/CLVP-Project
** 请自觉遵守开源协议并保留作者信息，谢谢 >w<
*/

#pragma semicolon 1
#include <sourcemod>
#include <builtinvotes>
#include <left4downtown>
#include <sdktools>

#define CLVP_AUTHOR		"Janus (QQ:781662377)"
#define	CLVP_URL		"http://steamcommunity.com/groups/CLVP"

#define BUILTINVOTE_ACTIONS_CLVP BuiltinVoteAction_Select|BuiltinVoteAction_Cancel|BuiltinVoteAction_End

new bool:IsRoundStarted = false;
new bool:EnableAddonsBlock = false;
new Handle:h_VoteMenu = INVALID_HANDLE;

public Plugin:myinfo = {name = "[CLVP GPL V3] Vote Addons Disable", version = "1.2", author = CLVP_AUTHOR, url = CLVP_URL};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:FolderName[32];
	GetGameFolderName(FolderName, sizeof(FolderName));
	if (!StrEqual(FolderName, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugins only support Left4Dead2");
		return APLRes_Failure;
	}
	if (FindConVar("l4d2_addons_eclipse") == INVALID_HANDLE)
	{
		strcopy(error, err_max, "This plugins require Left4Downtown2(0.5.7+)");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("versus_round_start", Event_VsRoundStart, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_vmod", Command_LaunchVote);
	RegConsoleCmd("sm_votemod", Command_LaunchVote);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {IsRoundStarted = false;}

public Event_VsRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {IsRoundStarted = true;}

public Action:Command_LaunchVote(client, args)
{
	if (IsClientValid(client)) {BuildAddonsStatePanel(client);}
	return Plugin_Handled;
}

BuildAddonsStatePanel(client)
{
	new Handle:convar = FindConVar("l4d2_addons_eclipse");
	if (convar != INVALID_HANDLE && GetConVarInt(convar) == 1)
	{
		new Handle:panel = CreatePanel();
		SetPanelTitle(panel, "CLVP GPL V3 - 投票开关禁MOD");
		DrawPanelText(panel, " \n");
		
		DrawPanelText(panel, "禁MOD功能会在玩家进入服务器时自动生效");
		DrawPanelText(panel, "部分MOD会导致游戏崩溃，建议提前手动关闭");
		DrawPanelText(panel, "回合正式开始后（离开安全区）不能发起此投票");
		DrawPanelText(panel, " \n");
		
		if (EnableAddonsBlock)
		{
			DrawPanelText(panel, "当前禁MOD状态: 已开启");
			DrawPanelText(panel, " \n");
			DrawPanelItem(panel, "投票关闭禁MOD");
		}
		else
		{
			DrawPanelText(panel, "当前禁MOD状态: 已关闭");
			DrawPanelText(panel, " \n");
			DrawPanelItem(panel, "投票开启禁MOD");
		}
		
		DrawPanelText(panel, " \n");
		DrawPanelText(panel, "0. 取消");
		SendPanelToClient(panel, client, Panel_VoteAddons, MENU_TIME_FOREVER);
		CloseHandle(panel);
	}
	else {PrintToChat(client, "\x04[CLVP] \x05无法使用，服务器没有打开禁MOD功能！");}
}

public Panel_VoteAddons(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select && select == 1)
	{PerformLaunchAddonsVote(client);}
}

PerformLaunchAddonsVote(client)
{
	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "\x04[CLVP] \x05无法发起投票，旁观者不能使用投票功能！");
		return;
	}
	if (IsBuiltinVoteInProgress())
	{
		PrintToChat(client, "\x04[CLVP] \x05无法发起投票，当前已有投票在进行中！");
		return;
	}
	if (CheckBuiltinVoteDelay() > 0)
	{
		PrintToChat(client, "\x04[CLVP] \x05无法发起投票，请等待 \x04%i \x05秒后再试！", CheckBuiltinVoteDelay());
		return;
	}
	if (IsRoundStarted)
	{
		PrintToChat(client, "\x04[CLVP] \x05无法发起投票，只能在回合未开始前进行投票！");
		return;
	}
	h_VoteMenu = CreateBuiltinVote(CallBack_VoteProgress, BuiltinVoteType_Custom_YesNo, BUILTINVOTE_ACTIONS_CLVP);
	
	if (EnableAddonsBlock)
	{
		SetBuiltinVoteArgument(h_VoteMenu, "（需至少75%%同意） 是否关闭自动禁用MOD功能?\n  >> 请注意，部分MOD可能导致游戏客户端崩溃！");
		PrintToChatAll("\x04[CLVP] \x05玩家 \x04%N \x05发起投票关闭禁MOD功能！", client);
	}
	else
	{
		SetBuiltinVoteArgument(h_VoteMenu, "（需至少75%%同意） 是否开启自动禁用MOD功能?\n  >> 请注意，部分MOD可能导致游戏客户端崩溃！");
		PrintToChatAll("\x04[CLVP] \x05玩家 \x04%N \x05发起投票开启禁MOD功能！", client);
	}
	SetBuiltinVoteInitiator(h_VoteMenu, client);
	SetBuiltinVoteResultCallback(h_VoteMenu, CallBack_VoteResult);
	DisplayBuiltinVoteToAllNonSpectators(h_VoteMenu, 20);
	FakeClientCommand(client, "Vote Yes");
}

public CallBack_VoteProgress(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	if (action == BuiltinVoteAction_Select)
	{
		switch (param2)
		{
			case 0: {PrintToConsoleAll("[CLVP Vote Detail]  Player %N in oppose of current vote.", param1);}
			case 1: {PrintToConsoleAll("[CLVP Vote Detail]  Player %N in favor of current vote.", param1);}
		}
	}
	else if (action == BuiltinVoteAction_Cancel)
	{
		DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
	}
	else if (action == BuiltinVoteAction_End)
	{
		CloseHandle(h_VoteMenu);
		h_VoteMenu = INVALID_HANDLE;
	}
}

public CallBack_VoteResult(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	if (num_votes <= (num_clients / 2))
	{
		DisplayBuiltinVoteFail(vote, BuiltinVoteFail_NotEnoughVotes);
		return;
	}
	new votey = 0;
	for (new i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{votey = item_info[i][BUILTINVOTEINFO_ITEM_VOTES];}
	}
	if (FloatDiv(float(votey), float(num_votes)) >= 0.75)
	{
		if (EnableAddonsBlock)
		{
			EnableAddonsBlock = false;
			DisplayBuiltinVotePass(vote, "禁MOD功能已关闭，服务器内的玩家即将重连...");
		}
		else
		{
			EnableAddonsBlock = true;
			DisplayBuiltinVotePass(vote, "禁MOD功能已开启，服务器内的玩家即将重连...");
		}
		CreateTimer(1.5, Timer_NoticeReadyReconnect);
		CreateTimer(5.0, Timer_ReconnectAllPlayers);
	}
	else {DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);}
}

public Action:Timer_NoticeReadyReconnect(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			PrintToChat(i, "\x04[CLVP] \x05你将自动重连服务器，出现短暂黑屏属正常现象！");
			PrintHintText(i, "你将自动重连服务器，出现短暂黑屏属正常现象！");
		}
	}
}

public Action:Timer_ReconnectAllPlayers(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i)) {ReconnectClient(i);}
	}
}

public Action:L4D2_OnClientDisableAddons(const String:SteamID[])
{
	return EnableAddonsBlock ? Plugin_Continue : Plugin_Handled;
}

stock bool:IsClientValid(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{return true;} else {return false;}
}

stock PrintToConsoleAll(const String:format[], any:...)
{
	decl String:buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i)) {PrintToConsole(i, buffer);}
	}
}