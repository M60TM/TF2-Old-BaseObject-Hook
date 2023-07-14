#pragma semicolon 1
#include <sourcemod>
#include <dhooks_gameconf_shim>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

#include <tf2utils>
#include <tf_custom_attributes>
#include <tf2ca_stocks>
#include <stocksoup/functions>
#include <stocksoup/tf/entity_prop_stocks>
#include <stocksoup/var_strings>

#include "tf2ca_custom_building/methodmaps.sp"
#include "tf2ca_custom_building/dhooks.sp"
#include "tf2ca_custom_building/natives.sp"
#include "tf2ca_custom_building/forwards.sp"

/////////////////////////////
// PLUGIN INFO             //
/////////////////////////////

public Plugin myinfo =
{
	name		= "[TF2] Custom Attribute: Custom Building",
	author		= "Sandy and Monera",
	description = "A few native and custom attributes, forwards for handling custom building.",
	version		= "1.5.0",
	url			= "https://github.com/M60TM/TF2CA-Custom-Building"
}

/////////////////////////////
// SDKCall                 //
/////////////////////////////

static Handle g_SDKCallDetonateObjectOfType;
static Handle g_SDKCallBuildingDestroyScreens;
static Handle g_SDKCallPlayerGetObjectOfType;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen)
{
	RegPluginLibrary("tf2ca_custom_building");

	Setup_Natives();

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData data = new GameData("tf2.cattr_object");
	if (!data)
	{
		SetFailState("Failed to load gamedata (tf2.cattr_object).");
	} 
	else if (!ReadDHooksDefinitions("tf2.cattr_object"))
	{
		SetFailState("Failed to read dhooks definitions of gamedata (tf2.cattr_object).");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CTFPlayer::DetonateObjectOfType()");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // int - type
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // int - mode
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // bool - silent
	g_SDKCallDetonateObjectOfType = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CTFPlayer::GetObjectOfType()");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerGetObjectOfType = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CBaseObject::DestroyScreens()");
	g_SDKCallBuildingDestroyScreens = EndPrepSDKCall();

	Setup_DHook(data);

	delete data;

	Setup_Forwards();

	AddNormalSoundHook(HookSound);
}

public void OnMapStart()
{
	HookEvent("post_inventory_application", OnInventoryAppliedPost);
	HookEvent("player_builtobject", OnBuildObject);
	HookEvent("player_upgradedobject", OnUpgradeObject);
	HookEvent("player_carryobject", OnCarryObject);
	HookEvent("player_dropobject", OnDropObject);
	HookEvent("object_removed", OnObjectRemoved);
	HookEvent("object_destroyed", OnObjectDestroyed);
	HookEvent("object_detonated", OnObjectDetonated);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "obj_sentrygun") || StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_teleporter"))
	{
		OnObjectCreated(entity, classname);
	}
	else if (StrEqual(classname, "tf_projectile_sentryrocket"))
	{
		SDKHook(entity, SDKHook_SpawnPost, SentryRocketSpawnPost);
	}
}

void SentryRocketSpawnPost(int rocket)
{
	int owner = GetEntPropEnt(rocket, Prop_Data, "m_hOwnerEntity");

	if (!HasEntProp(owner, Prop_Send, "m_hBuilder"))
	{
		return;
	}

	int builder = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");

	if (IsValidClient(builder))
	{
		char sAttributes[256];
		if (TF2CustAttr_ClientHasString(builder, "custom sentry rocket model", sAttributes, sizeof(sAttributes)))
		{
			SetSentryRocketModel(rocket, sAttributes);
		}
	}

	return;
}

Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
	int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
	char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (!IsValidEntity(entity))
		return Plugin_Continue;

	static char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "obj_sentrygun", true) != -1)
	{
		int builder = TF2_GetObjectBuilder(entity);
		if (!IsValidClient(builder))
		{
			return Plugin_Continue;
		}

		return CallSentryEmitSoundForward(entity, builder, sample, channel, volume, level, pitch);
	}
	
	return Plugin_Continue;
}

/////////////////////////////
// Events                  //
/////////////////////////////

void OnInventoryAppliedPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(client))
	{
		return;
	}
	if (TF2_GetPlayerClass(client) != TFClass_Engineer)
	{
		return;
	}

	char attr[3][64];
	for (int i = 0; i < 3; i++)
	{
		attr[i][0] = '\0';
	}

	for (int i = 0; i < 5; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);

		if (!IsValidEntity(weapon))
		{
			continue;
		}

		TF2CustAttr_GetString(weapon, "custom dispenser type", attr[0], sizeof(attr[]), attr[0]);
		TF2CustAttr_GetString(weapon, "custom sentry type", attr[1], sizeof(attr[]), attr[1]);
		TF2CustAttr_GetString(weapon, "custom teleporter type", attr[2], sizeof(attr[]), attr[2]);
	}

	bool destroy[3] = { false, ... };
	int buildings = TF2Util_GetPlayerObjectCount(client);
	for (int i = 0; i < buildings; i++)
	{
		int building = TF2Util_GetPlayerObject(client, i);
		if (!IsValidEntity(building))
		{
			continue;
		}

		char customBuildingType[3][CUSTOM_BUILDING_TYPE_NAME_LENGTH];
		TFObjectType type = TF2_GetObjectType(building);
		switch (type)
		{
			case TFObject_Dispenser:
			{
				Builder(client).GetCustomDispenserType(customBuildingType[0], sizeof(customBuildingType[]));
				if (strcmp(attr[0], customBuildingType[0]) != 0)
				{
					destroy[0] = true; 
				}
			}
			case TFObject_Sentry:
			{
				Builder(client).GetCustomSentryType(customBuildingType[1], sizeof(customBuildingType[]));
				if (strcmp(attr[1], customBuildingType[1]) != 0)
				{
					destroy[2] = true;
				}
			}
			case TFObject_Teleporter:
			{
				Builder(client).GetCustomTeleporterType(customBuildingType[2], sizeof(customBuildingType[]));
				if (strcmp(attr[2], customBuildingType[2]) != 0)
				{
					destroy[1] = true;
				}
			}
		}
	}

	for (int i = 0; i < 3; i++)
	{
		if (destroy[i])
		{
			DetonateObjectOfType(client, i, 0, true);
			if (i == 1) DetonateObjectOfType(client, i, 1, true);	// teleporter
		}
	}

	Builder(client).SetCustomDispenserType(attr[0]);
	Builder(client).SetCustomSentryType(attr[1]);
	Builder(client).SetCustomTeleporterType(attr[2]);
}

/**
 * forward void TF2CA_OnBuildObject(int builder, int building, TFObjectType buildingtype)
 */
void OnBuildObject(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallBuildObjectForward(builder, building, buildingtype);
	
	if (builder != -1)
	{
		int wrench = GetPlayerWeaponSlot(builder, 2);
		char attr[256];
		if (TF2CustAttr_GetString(wrench, "building upgrade cost", attr, sizeof(attr)))
		{
			UpdateBuildingInfo(building, buildingtype, attr);
		}
	}
}

/**
 * forward void TF2CA_OnBuildObject(int builder, int building, TFObjectType buildingtype)
 */
void OnUpgradeObject(Event event, const char[] name, bool dontBroadcast)
{
	int upgrader = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(upgrader))
	{
		upgrader = -1;
	}

	int building = event.GetInt("index");

	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallUpgradeObjectForward(upgrader, builder, building, buildingtype);

	if (builder != -1)
	{
		int wrench = GetPlayerWeaponSlot(builder, 2);
		char attr[256];
		if (TF2CustAttr_GetString(wrench, "building upgrade cost", attr, sizeof(attr)))
		{
			UpdateBuildingInfo(building, buildingtype, attr);
		}
	}
}

/**
 * forward void TF2CA_OnCarryObject(int builder, int building, TFObjectType buildingtype);
 */
void OnCarryObject(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallCarryObjectForward(builder, building, buildingtype);
}

/**
 * forward void TF2CA_OnDropObject(int builder, int building, TFObjectType buildingtype);
 */
void OnDropObject(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallDropObjectForward(builder, building, buildingtype);
}

/**
 * forward void TF2CA_OnObjectRemoved(int builder, int building, TFObjectType buildingtype)
 */
void OnObjectRemoved(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallObjectRemovedForward(builder, building, buildingtype);
}

/**
 * forward void TF2CA_OnObjectRemoved(int builder, int building, TFObjectType buildingtype)
 */
void OnObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsValidClient(attacker))
	{
		attacker = -1;
	}

	int assister = GetClientOfUserId(event.GetInt("assister"));

	if (!IsValidClient(assister))
	{
		assister = -1;
	}

	int weapon = event.GetInt("weaponid");

	int building = event.GetInt("index");

	bool wasbuilding = event.GetBool("was_building");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallObjectDestroyedForward(builder, attacker, assister, weapon, building, buildingtype, wasbuilding);
}

/**
 * forward void TF2CA_OnObjectDetonated(int builder, int building, TFObjectType buildingtype);
 */
void OnObjectDetonated(Event event, const char[] name, bool dontBroadcast)
{
	int builder = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	CallObjectDetonatedForward(builder, building, buildingtype);
}

/////////////////////////////
// Stock                   //
/////////////////////////////

stock void SetSentryRocketModel(int entity, char[] attr)
{
	if (FileExists(attr, true))
	{
		PrecacheModel(attr);
		SetEntityModel(entity, attr);
	}
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if (replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

/////////////////////////////
// Utility                 //
/////////////////////////////

void UpdateBuildingInfo(int building, TFObjectType type, const char[] attr)
{
	int level = GetEntProp(building, Prop_Send, "m_iUpgradeLevel");

	switch (type)
	{
		case TFObject_Sentry:
		{
			if (ReadIntVar(attr, "sentry"))
			{
				int sentryMetalRequired[4];
				sentryMetalRequired[0] = 0;
				sentryMetalRequired[1] = ReadIntVar(attr, "sentry1", 200);
				sentryMetalRequired[2] = ReadIntVar(attr, "sentry2", 400);
				sentryMetalRequired[3] = ReadIntVar(attr, "sentry3", 600);

				SetEntProp(building, Prop_Send, "m_iUpgradeMetalRequired", sentryMetalRequired[level]);
			}
		}
		case TFObject_Dispenser:
		{
			if (ReadIntVar(attr, "dispenser"))
			{
				int dispenserMetalRequired[4];
				dispenserMetalRequired[0] = 0;
				dispenserMetalRequired[1] = ReadIntVar(attr, "dispenser1", 200);
				dispenserMetalRequired[2] = ReadIntVar(attr, "dispenser2", 400);
				dispenserMetalRequired[3] = ReadIntVar(attr, "dispenser3", 600);

				SetEntProp(building, Prop_Send, "m_iUpgradeMetalRequired", dispenserMetalRequired[level]);
			}
		}
	}
}

any DetonateObjectOfType(int client, int type, int mode = 0, bool silent = false)
{
	return SDKCall(g_SDKCallDetonateObjectOfType, client, type, mode, silent);
}

any PlayerGetObjectOfType(int owner, int objectType, int objectMode)
{
	return SDKCall(g_SDKCallPlayerGetObjectOfType, owner, objectType, objectMode);
}

any DestroyScreens(int building)
{
	return SDKCall(g_SDKCallBuildingDestroyScreens, building);
}