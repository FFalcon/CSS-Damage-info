#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "F4LC0n"
#define PLUGIN_VERSION "0.2"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:sm_damageinfo;
new String:clientname[MAXPLAYERS + 1][32];
new _:damageDoneLastFiveSec[MAXPLAYERS][MAXPLAYERS];
new bool:IsHuman[MAXPLAYERS + 1];
new clientteam[MAXPLAYERS + 1];
new Handle:hudSync;

public Plugin:myinfo = 
{
	name = "Bullet Damage",
	author = PLUGIN_AUTHOR,
	description = "shows accumulated dmg info at crosshair",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	sm_damageinfo = CreateConVar("sm_bulletdmg", "0.1", "Enable/Disable", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	CreateTimer(5.0, CleanDamageAccumulator, _, TIMER_REPEAT);
	hudSync = CreateHudSynchronizer();
	HookConVarChange(sm_damageinfo, HurtEventChange);
	
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_team", OnPlayerChangeTeam);
	HookEvent("player_changename", OnPlayerChangeName);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public Action CleanDamageAccumulator(Handle timer)
{
    for (int i = 0; i < MAXPLAYERS; i++){
    	for(int j = 0; j < MAXPLAYERS; j++){
    		damageDoneLastFiveSec[i][j] = 0;
    	}
    }
    return Plugin_Continue;
}

public HurtEventChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(convar))
	{
		HookEvent("player_hurt", OnPlayerHurt);
		HookEvent("player_spawn", OnPlayerSpawn);
		HookEvent("player_team", OnPlayerChangeTeam);
		HookEvent("player_changename", OnPlayerChangeName);
		
		HookEvent("round_start", OnRoundStart);
		HookEvent("round_end", OnRoundEnd);
		
		ResetPastMsgAll();
	}
	else
	{
		
		UnhookEvent("player_hurt", OnPlayerHurt);
		UnhookEvent("player_spawn", OnPlayerSpawn);
		UnhookEvent("player_team", OnPlayerChangeTeam);
		UnhookEvent("player_changename", OnPlayerChangeName);
		
		UnhookEvent("round_start", OnRoundStart);
		UnhookEvent("round_end", OnRoundEnd);
		
		ResetPastMsgAll();
	}
}

public OnClientPutInServer(client)
{
	GetClientName(client, clientname[client], 32);
	IsHuman[client] = !IsFakeClient(client);
	ResetPastMsg(client);
}

public OnClientDisconnect(client)
{
	clientname[client] = NULL_STRING;
	clientteam[client] = CS_TEAM_NONE;
	IsHuman[client] = false;
	ResetPastMsg(client);
}

public Action:OnRoundStart(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	ResetPastMsgAll();
}

public Action:OnRoundEnd(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	ResetPastMsgAll();
}

public Action:OnPlayerChangeName(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "newname", clientname[client], 32);
}

public Action:OnPlayerChangeTeam(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	clientteam[client] = GetEventInt(event, "team");
	
	ResetPastMsg(client);
}

public Action:OnPlayerSpawn(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	clientteam[client] = GetClientTeam(client);
	
	ResetPastMsg(client);
}

public Action:OnPlayerHurt(Handle:event, const String:eventname[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim == 0)
	return;
	
	if (!IsHuman[victim] && !IsHuman[attacker]) // if both victim and attacker are not human, no point to process further
		return;
		
	new damage = GetEventInt(event, "dmg_health");
	
	ShowDamageReceivedAndDealt(victim, attacker, damage);
}

ShowDamageReceivedAndDealt(int victim, int attacker, int damage)
{
	if (attacker != 0) // damage caused by players and not "world"
	{
		if (victim != attacker) // damage not self inflicted
		{
			ShowDamageReceived(victim, damage);
			ShowDamageDealt(attacker, damage);
			damageDoneLastFiveSec[attacker][victim] += damage;
		}
		else // self-inflicted damage, most likely grenade
		{
			ShowDamageReceived(victim, damage);
		}
	}
	else // damage inflicted by "world": fall damage, c4, ...
	{
		ShowDamageReceived(victim, damage);
	}
}

ShowDamageDealt(int client, int damage)
{
	if (IsClientInGame(client) && IsHuman[client])
	{
		if(hudSync != INVALID_HANDLE){
			//ClearSyncHud(client, hudSync);
			SetHudTextParams(0.48, 0.52, 5.0, 0, 0, 255, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, 2, "%d", damage);
		}
	}
}

ShowDamageReceived(int client, int damage)
{
	if (IsClientInGame(client) && IsHuman[client])
	{
		if(hudSync != INVALID_HANDLE){
			//ClearSyncHud(client, hudSync);
			SetHudTextParams(0.65, -1.0, 5.0, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
			ShowHudText(client, 3, "%d", damage);
		}
	}
}

stock ResetPastMsg(int client)
{
	ClearSyncHud(client, hudSync);
}

stock ResetPastMsgAll()
{
	for (new i = 1; i <= MaxClients; i++)
		ResetPastMsg(i);
}
