#pragma semicolon 1
#include <sourcemod>
#include <dhooks>
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

#include "tf2ca_custom_building/dhooks.sp"
#include "tf2ca_custom_building/methodmaps.sp"

/////////////////////////////
// PLUGIN INFO             //
/////////////////////////////

public Plugin myinfo =
{
	name		= "[TF2] Custom Attribute: Custom Building",
	author		= "Sandy and Monera",
	description = "A few native and custom attributes, forwards for handling custom building.",
	version		= "1.4.0",
	url			= "https://github.com/M60TM/TF2CA-Custom-Building"
}

/////////////////////////////
// Forward                 //
/////////////////////////////

GlobalForward g_OnBuildObjectForward;
GlobalForward g_OnUpgradeObjectForward;
GlobalForward g_OnCarryObjectForward;
GlobalForward g_OnDropObjectForward;
GlobalForward g_OnObjectRemovedForward;
GlobalForward g_OnObjectDestroyedForward;
GlobalForward g_OnObjectDetonatedForward;

/////////////////////////////
// SDKCall                 //
/////////////////////////////

Handle		g_SDKCallDetonateObjectOfType;
Handle		g_SDKCallBuildingDestroyScreens;
Handle		g_SDKCallPlayerGetObjectOfType;

StringMap	g_MissingModels;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen)
{
	RegPluginLibrary("tf2ca_custom_building");

	CreateNative("TF2CA_BuilderHasCustomDispenser", Native_BuilderHasCustomDispenser);
	CreateNative("TF2CA_BuilderHasCustomSentry", Native_BuilderHasCustomSentry);
	CreateNative("TF2CA_BuilderHasCustomTeleporter", Native_BuilderHasCustomTeleporter);
	CreateNative("TF2CA_DetonateObjectOfType", Native_DetonateObjectOfType);
	CreateNative("TF2CA_PlayerGetObjectOfType", Native_PlayerGetObjectOfType);
	CreateNative("TF2CA_DestroyScreens", Native_DestroyScreens);

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData hGameConf = new GameData("tf2.cattr_object");
	if (!hGameConf)
	{
		SetFailState("Failed to load gamedata (tf2.cattr_object).");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer::DetonateObjectOfType()");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // int - type
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // int - mode
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // bool - silent
	g_SDKCallDetonateObjectOfType = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer::GetObjectOfType()");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerGetObjectOfType = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CBaseObject::DestroyScreens()");
	g_SDKCallBuildingDestroyScreens = EndPrepSDKCall();

	Setup_DHook(hGameConf);

	delete hGameConf;

	g_OnBuildObjectForward = CreateGlobalForward("TF2CA_OnBuildObject", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnUpgradeObjectForward = CreateGlobalForward("TF2CA_OnUpgradeObject", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	g_OnCarryObjectForward = CreateGlobalForward("TF2CA_OnCarryObject", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnDropObjectForward = CreateGlobalForward("TF2CA_OnDropObject", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnObjectRemovedForward = CreateGlobalForward("TF2CA_OnObjectRemoved", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnObjectDestroyedForward = CreateGlobalForward("TF2CA_OnObjectDestroyed", ET_Event, Param_Cell, Param_Cell, Param_Cell,
																				Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	g_OnObjectDetonatedForward = CreateGlobalForward("TF2CA_OnObjectDetonated", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectOnGoActiveForward = CreateGlobalForward("TF2CA_ObjectOnGoActive", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectStartUpgradingForward = CreateGlobalForward("TF2CA_ObjectStartUpgrading", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectFinishUpgradingForward = CreateGlobalForward("TF2CA_ObjectFinishUpgrading", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserStartHealingForward = CreateGlobalForward("TF2CA_DispenserStartHealing", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserStopHealingPreForward = CreateGlobalForward("TF2CA_DispenserStopHealing", ET_Hook, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserStopHealingPostForward = CreateGlobalForward("TF2CA_DispenserStopHealingPost", ET_Event, Param_Cell, Param_Cell, Param_Cell);
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

	delete g_MissingModels;
	g_MissingModels = new StringMap();
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
					DetonateObjectOfType(client, 0, 0, true);
				}
			}
			case TFObject_Sentry:
			{
				Builder(client).GetCustomSentryType(customBuildingType[1], sizeof(customBuildingType[]));
				if (strcmp(attr[1], customBuildingType[1]) != 0)
				{
					DetonateObjectOfType(client, 2, 0, true);
				}
			}
			case TFObject_Teleporter:
			{
				Builder(client).GetCustomTeleporterType(customBuildingType[2], sizeof(customBuildingType[]));
				if (strcmp(attr[2], customBuildingType[2]) != 0)
				{
					DetonateObjectOfType(client, 1, 0, true);
					DetonateObjectOfType(client, 1, 1, true);
				}
			}
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

	int	building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnBuildObjectForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();

	if (builder != -1)
	{
		int	 wrench = GetPlayerWeaponSlot(builder, 2);
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

	int builder	 = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnUpgradeObjectForward);
	Call_PushCell(upgrader);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();

	if (builder != -1)
	{
		int	 wrench = GetPlayerWeaponSlot(builder, 2);
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

	int	building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnCarryObjectForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
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

	int	building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnDropObjectForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
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

	int	building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnObjectRemovedForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
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

	if (!IsValidEntity(weapon))
	{
		weapon = -1;
	}

	int	building = event.GetInt("index");

	bool wasbuilding = event.GetBool("was_building");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnObjectDestroyedForward);
	Call_PushCell(builder);
	Call_PushCell(attacker);
	Call_PushCell(assister);
	Call_PushCell(weapon);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_PushCell(wasbuilding);
	Call_Finish();
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

	int	building = event.GetInt("index");

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_OnObjectDetonatedForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

/////////////////////////////
// Native                  //
/////////////////////////////

int Native_BuilderHasCustomDispenser(Handle plugin, int nParams)
{
	int client = GetNativeInGameClient(1);

	int len;
	GetNativeStringLength(2, len);
	if (len <= 0)
	{
		return false;
	}
	char[] value = new char[len + 1];
	GetNativeString(2, value, len + 1);

	char dispenserType[CUSTOM_BUILDING_TYPE_NAME_LENGTH];
	Builder(client).GetCustomDispenserType(dispenserType, sizeof(dispenserType));
	return strcmp(dispenserType, value) == 0;
}

int Native_BuilderHasCustomSentry(Handle plugin, int nParams)
{
	int client = GetNativeInGameClient(1);

	int len;
	GetNativeStringLength(2, len);
	if (len <= 0)
	{
		return false;
	}
	char[] value = new char[len + 1];
	GetNativeString(2, value, len + 1);

	char sentryType[CUSTOM_BUILDING_TYPE_NAME_LENGTH];
	Builder(client).GetCustomSentryType(sentryType, sizeof(sentryType));
	return strcmp(sentryType, value) == 0;
}

int Native_BuilderHasCustomTeleporter(Handle plugin, int nParams)
{
	int client = GetNativeInGameClient(1);

	int len;
	GetNativeStringLength(2, len);
	if (len <= 0)
	{
		return false;
	}
	char[] value = new char[len + 1];
	GetNativeString(2, value, len + 1);

	char teleporterType[CUSTOM_BUILDING_TYPE_NAME_LENGTH];
	Builder(client).GetCustomTeleporterType(teleporterType, sizeof(teleporterType));
	return strcmp(teleporterType, value) == 0;
}

int Native_DetonateObjectOfType(Handle plugin, int nParams)
{
	int	 client = GetNativeInGameClient(1);
	int	 type	= GetNativeCell(2);
	int	 mode	= GetNativeCell(3);
	bool silent = GetNativeCell(4);

	return SDKCall(g_SDKCallDetonateObjectOfType, client, type, mode, silent);
}

int Native_PlayerGetObjectOfType(Handle plugin, int nParams)
{
	int owner	   = GetNativeInGameClient(1);
	int objectType = GetNativeCell(2);
	int objectMode = GetNativeCell(3);

	return SDKCall(g_SDKCallPlayerGetObjectOfType, owner, objectType, objectMode);
}

int Native_DestroyScreens(Handle plugin, int nParams)
{
	int building = GetNativeCell(1);

	return SDKCall(g_SDKCallBuildingDestroyScreens, building);
}

/////////////////////////////
// Stock                   //
/////////////////////////////

stock void SetSentryRocketModel(int entity, char[] attr)
{
	if (FileExistsAndLog(attr, true))
	{
		PrecacheModelAndLog(attr);
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
				int iSentryMetalRequired[4];
				iSentryMetalRequired[0] = 0;
				iSentryMetalRequired[1] = ReadIntVar(attr, "sentry1", 200);
				iSentryMetalRequired[2] = ReadIntVar(attr, "sentry2", 400);
				iSentryMetalRequired[3] = ReadIntVar(attr, "sentry3", 600);

				SetEntProp(building, Prop_Send, "m_iUpgradeMetalRequired", iSentryMetalRequired[level]);
			}
		}
		case TFObject_Dispenser:
		{
			if (ReadIntVar(attr, "dispenser"))
			{
				int iDispenserMetalRequired[4];
				iDispenserMetalRequired[0] = 0;
				iDispenserMetalRequired[1] = ReadIntVar(attr, "dispenser1", 200);
				iDispenserMetalRequired[2] = ReadIntVar(attr, "dispenser2", 400);
				iDispenserMetalRequired[3] = ReadIntVar(attr, "dispenser3", 600);

				SetEntProp(building, Prop_Send, "m_iUpgradeMetalRequired", iDispenserMetalRequired[level]);
			}
		}
	}
}

bool FileExistsAndLog(const char[] path, bool use_valve_fs = false, const char[] valve_path_id = "GAME")
{
	if (FileExists(path, use_valve_fs, valve_path_id))
	{
		return true;
	}

	any discarded;
	if (!g_MissingModels.GetValue(path, discarded))
	{
		LogError("Missing file '%s'", path);
		g_MissingModels.SetValue(path, true);
	}
	return false;
}

int PrecacheModelAndLog(const char[] model, bool preload = false)
{
	int modelIndex = PrecacheModel(model, preload);
	if (!modelIndex)
	{
		LogError("Failed to precache model '%s'", model);
	}
	return modelIndex;
}

void DetonateObjectOfType(int client, int type, int mode = 0, bool silent = false)
{
	SDKCall(g_SDKCallDetonateObjectOfType, client, type, mode, silent);
}