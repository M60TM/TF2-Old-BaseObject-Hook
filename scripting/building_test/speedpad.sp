#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#include <tf2attributes>
#include <tf2bh>
#include <tf2ca_custom_building>
#include <stocksoup/tf/entity_prop_stocks>

#define ATTR_SPEED_PAD "build speed pad"
#define ATTR_MULT_TELEPORTER_RECHARGE_RATE "mult_teleporter_recharge_rate"

enum //Teleporter states
{
	TELEPORTER_STATE_BUILDING = 0,				// Building, not active yet
	TELEPORTER_STATE_IDLE,						// Does not have a matching teleporter yet
	TELEPORTER_STATE_READY,						// Found match, charged and ready
	TELEPORTER_STATE_SENDING,					// Teleporting a player away
	TELEPORTER_STATE_RECEIVING,					
	TELEPORTER_STATE_RECEIVING_RELEASE,
	TELEPORTER_STATE_RECHARGING,				// Waiting for recharge
	TELEPORTER_STATE_UPGRADING					// Upgrading
}

static char g_szOffsetStartProp[64];
static int g_iOffsetMatchingTeleporter = -1;

// grab from 2018 leak lol
float g_flTeleporterRechargeTimes[4] =
{
	0.0,
	10.0,
	5.0,
	3.0
};

float g_flSpeedPadDurationTimes[4] =
{
	0.0,
	3.0,
	4.5,
	6.0
};

public Plugin myinfo = {
	name = "[TF2] Custom Attribute: Speed Pad",
	author = "Original plugin from Starblaster 64, Ported and Modified by Sandy",
	description = "",
	version = "1.0.1",
	url = ""
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("tf2.teleporters");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.teleporters).");
	}
	
	bool bFoundProp = GameConfGetKeyValue(hGameConf, "StartProp", g_szOffsetStartProp, sizeof(g_szOffsetStartProp));
	g_iOffsetMatchingTeleporter = GameConfGetOffset(hGameConf, "m_hMatchingTeleporter");
	
	if (!bFoundProp || g_iOffsetMatchingTeleporter < 0)
	{
		SetFailState("[EngiPads] Unable to get m_hMatchingTeleporter offset from 'tf2.teleporters.txt'. Check gamedata!");
	}
	
	delete hGameConf;

	AddCommandListener(EurekaTeleport, "eureka_teleport");

	AddNormalSoundHook(HookSound);
}

/**
 * Prevent Eureka Effect Teleport.
 */
public Action EurekaTeleport(int iClient, const char[] szCommand, int nArgs)
{
	if (IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		char arg[8]; GetCmdArg(1, arg, sizeof(arg));
		int iDest = StringToInt(arg);
		
		if (iDest != 1 || !GetCmdArgs())	//If teleport destination is not 1 or unspecified (Spawn)
			return Plugin_Continue;
		
		int teleexit = TF2BH_PlayerGetObjectOfType(iClient, 1, 1);
		if (IsValidEntity(teleexit) && TF2CA_BuilderHasCustomTeleporter(iClient, ATTR_SPEED_PAD))
		{
			EmitGameSoundToClient(iClient, "Player.UseDeny", iClient);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/**
 * I need to block the duplicate sapping sound otherwise it'll loop forever.
 */
public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
		int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
		char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (IsValidEntity(entity))
	{
		char className[64];
		GetEntityClassname(entity, className, sizeof(className));
	
		if (StrEqual(className, "obj_attachment_sapper") && TF2_GetObjectType(entity) == TFObject_Sapper && channel == SNDCHAN_STATIC)
		{
			if (GetEntPropEnt(entity, Prop_Send, "m_hBuiltOnEntity") == -1)
			{
				if (StrEqual(sample, "weapons/sapper_timer.wav") || StrContains(sample, "spy_tape") != -1)
				{
					return Plugin_Handled;
				}
			}
		}
	}
		
	return Plugin_Continue;
}

public void TF2BH_OnBuildObject(int builder, int building, TFObjectType type)
{
	if (builder == -1)
	{
		return;
	}
	
	if (type != TFObject_Teleporter)
	{
		return;
	}

	if (TF2CA_BuilderHasCustomTeleporter(builder, ATTR_SPEED_PAD))
	{
		ConvertTeleporterToSpeedPad(building, true);
	}
}

/* Pad Creation/Revertion */
void ConvertTeleporterToSpeedPad(int iEnt, bool bAddHealth)
{
	if (bAddHealth)
	{
		SetVariantInt(75);
		AcceptEntityInput(iEnt, "AddHealth", iEnt); //Spawns at 50% HP.
		SetEntProp(iEnt, Prop_Send, "m_iTimesUsed", 0);
	}
	
	TF2_SetMatchingTeleporter(iEnt, iEnt); //Set its matching Teleporter to itself.
	
	SDKHook(iEnt, SDKHook_Touch, OnPadTouch);
}

public Action OnPadTouch(int iPad, int iToucher)
{
	if (IsValidClient(iToucher))
	{		
		if (TF2_GetBuildingState(iPad) != TELEPORTER_STATE_READY)
			return Plugin_Continue;
		
		int iPadTeam = GetEntProp(iPad, Prop_Data, "m_iTeamNum");
		int iPadBuilder = GetEntPropEnt(iPad, Prop_Send, "m_hBuilder");
		
		if ((GetClientTeam(iToucher) == iPadTeam ||
			(TF2_GetPlayerClass(iToucher) == TFClass_Spy && TF2_IsPlayerInCondition(iToucher, TFCond_Disguised) && GetEntProp(iToucher, Prop_Send, "m_nDisguiseTeam") == iPadTeam)) &&
			GetEntPropEnt(iToucher, Prop_Send, "m_hGroundEntity") == iPad)
		{
			int level = GetEntProp(iPad, Prop_Send, "m_iUpgradeLevel");
			
			float flDur = g_flSpeedPadDurationTimes[level];
					
			TF2_AddCondition(iToucher, TFCond_SpeedBuffAlly, flDur, iPadBuilder);
			TF2_AddCondition(iToucher, TFCond_TeleportedGlow, flDur);
					
			TF2_SetBuildingState(iPad, TELEPORTER_STATE_RECEIVING_RELEASE);
			
			float RechargeTime = g_flTeleporterRechargeTimes[level];
			TF2Attrib_HookValueFloat(RechargeTime, ATTR_MULT_TELEPORTER_RECHARGE_RATE, iPadBuilder);
			SetEntPropFloat(iPad, Prop_Send, "m_flRechargeTime", GetGameTime() + RechargeTime);
					
			EmitGameSoundToAll("Powerup.PickUpHaste", iToucher);
			EmitGameSoundToAll("Building_Teleporter.Send", iPad);
				
			if (iToucher != iPadBuilder)
			{
				SetEntProp(iPad, Prop_Send, "m_iTimesUsed", GetEntProp(iPad, Prop_Send, "m_iTimesUsed") + 1);
				
				if (!(GetEntProp(iPad, Prop_Send, "m_iTimesUsed") % 3)) //Add +2 points every 3 uses
				{
					Event event = CreateEvent("player_escort_score", true);	//Using player_teleported unfortunately does not work.
					if (event != null)
					{
						event.SetInt("player", iPadBuilder);
						event.SetInt("points", 1);	//Not sure why this is adding double points
						event.Fire();
					}
				}
			}
		}
		return Plugin_Handled;	//Block client touch events to prevent enemy spies messing stuff up.
	}
	return Plugin_Continue;
}

stock void TF2_SetMatchingTeleporter(int iTele, int iMatch)	//Set the matching teleporter entity of a given Teleporter
{
	if (IsValidEntity(iTele) && HasEntProp(iTele, Prop_Send, g_szOffsetStartProp))
	{
		int iOffs = FindSendPropInfo("CObjectTeleporter", g_szOffsetStartProp) + g_iOffsetMatchingTeleporter;
		SetEntDataEnt2(iTele, iOffs, iMatch, true);
	}
}

stock int TF2_GetBuildingState(int iBuilding)
{
	int iState = -1;
	
	if (IsValidEntity(iBuilding))
	{
		iState = GetEntProp(iBuilding, Prop_Send, "m_iState");
	}
	
	return iState;
}

stock void TF2_SetBuildingState(int iBuilding, int iState = 0)
{	
	if (IsValidEntity(iBuilding))
	{
		SetEntProp(iBuilding, Prop_Send, "m_iState", iState);
	}
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}