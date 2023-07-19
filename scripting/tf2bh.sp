#pragma semicolon 1
#include <sourcemod>
#include <dhooks_gameconf_shim>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/functions>
#include <stocksoup/tf/entity_prop_stocks>

#include "tf2bh/utils.sp"
#include "tf2bh/dhooks.sp"
#include "tf2bh/natives.sp"
#include "tf2bh/forwards.sp"

/////////////////////////////
// PLUGIN INFO             //
/////////////////////////////

public Plugin myinfo =
{
	name		= "[TF2] BaseObject Hook",
	author		= "Sandy and Monera",
	description = "Natives and Forwards for Handling Building.",
	version		= "1.0.0",
	url			= "https://github.com/M60TM/TF2CA-Custom-Building"
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen)
{
	RegPluginLibrary("tf2bh");

	Setup_Natives();

	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData data = new GameData("tf2.baseobject");
	if (!data)
	{
		SetFailState("Failed to load gamedata (tf2.baseobject).");
	} 
	else if (!ReadDHooksDefinitions("tf2.baseobject"))
	{
		SetFailState("Failed to read dhooks definitions of gamedata (tf2.baseobject).");
	}

	Setup_SDKCalls(data);
	Setup_DHook(data);

	delete data;

	Setup_Forwards();

	AddNormalSoundHook(HookSound);

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