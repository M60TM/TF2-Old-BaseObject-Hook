#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

#include <tf2utils>
#include <tf2bh>
#include <tf2ca_stocks>

#include <stocksoup/functions>
#include <stocksoup/var_strings>

#include "tf2ca_custom_building/methodmaps.sp"

/////////////////////////////
// PLUGIN INFO             //
/////////////////////////////

public Plugin myinfo =
{
	name		= "[TF2CA] Custom Building",
	author		= "Sandy and Monera",
	description = "Custom Attributes For Building.",
	version		= "1.6.0",
	url			= "https://github.com/M60TM/TF2CA-Custom-Building"
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen)
{
	RegPluginLibrary("tf2ca_custom_building");
	
	CreateNative("TF2CA_BuilderHasCustomDispenser", Native_BuilderHasCustomDispenser);
	CreateNative("TF2CA_BuilderHasCustomSentry", Native_BuilderHasCustomSentry);
	CreateNative("TF2CA_BuilderHasCustomTeleporter", Native_BuilderHasCustomTeleporter);

	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("post_inventory_application", OnInventoryAppliedPost);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_sentryrocket"))
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
}

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
			TF2BH_PlayerDetonateObjectOfType(client, i, 0, true);
			if (i == 1) TF2BH_PlayerDetonateObjectOfType(client, i, 1, true);	// teleporter
		}
	}

	Builder(client).SetCustomDispenserType(attr[0]);
	Builder(client).SetCustomSentryType(attr[1]);
	Builder(client).SetCustomTeleporterType(attr[2]);
}

public void TF2BH_OnBuildObject(int builder, int building, TFObjectType type)
{
	if (builder != -1)
	{
		int wrench = GetPlayerWeaponSlot(builder, 2);
		char attr[256];
		if (IsValidEntity(wrench) && TF2CustAttr_GetString(wrench, "building upgrade cost", attr, sizeof(attr)))
		{
			UpdateBuildingInfo(building, type, attr);
		}
	}
}

public void TF2BH_OnUpgradeObject(int upgrader, int builder, int building, TFObjectType type)
{
	if (builder != -1)
	{
		int wrench = GetPlayerWeaponSlot(builder, 2);
		char attr[256];
		if (IsValidEntity(wrench) && TF2CustAttr_GetString(wrench, "building upgrade cost", attr, sizeof(attr)))
		{
			UpdateBuildingInfo(building, type, attr);
		}
	}
}

public Action TF2BH_SentrygunSetModel(int builder, int sentry, char modelName[128])
{
	char newSentryModel[128];
	if (!TF2CustAttr_ClientHasString(builder, "custom sentry model", newSentryModel, sizeof(newSentryModel)))
	{
		return Plugin_Continue;
	}

	if (StrContains(newSentryModel, ".mdl"))
	{
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}

	if (StrEqual(modelName, SENTRY_BLUEPRINT_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "1_blueprint.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, SENTRY_LV1_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "1.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, SENTRY_LV1_HEAVY_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "1_heavy.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, SENTRY_LV2_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "2.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, SENTRY_LV2_HEAVY_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "2_heavy.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, SENTRY_LV3_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "3.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, SENTRY_LV3_HEAVY_MODEL))
	{
		StrCat(newSentryModel, sizeof(newSentryModel), "3_heavy.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			modelName = newSentryModel;

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action TF2BH_DispenserSetModel(int builder, int dispenser, char modelName[128])
{
	char newDispenserModel[128];
	if (!TF2CustAttr_ClientHasString(builder, "custom dispenser model", newDispenserModel, sizeof(newDispenserModel)))
	{
		return Plugin_Continue;
	}

	if (StrContains(newDispenserModel, ".mdl"))
	{
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
	}

	char dispenserModel[128];
	strcopy(dispenserModel, sizeof(dispenserModel), newDispenserModel);

	if (StrEqual(modelName, DISPENSER_BLUEPRINT_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), "_blueprint.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, DISPENSER_LV1_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), "_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, DISPENSER_LV1_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), ".mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, DISPENSER_LV2_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), "_lvl2_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, sizeof(newDispenserModel), "_light.mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				modelName = newDispenserModel;

				return Plugin_Changed;
			}
		}
	}
	else if (StrEqual(modelName, DISPENSER_LV2_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), "_lvl2.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, sizeof(newDispenserModel), ".mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				modelName = newDispenserModel;

				return Plugin_Changed;
			}
		}
	}
	else if (StrEqual(modelName, DISPENSER_LV3_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), "_lvl3_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, sizeof(newDispenserModel), "_light.mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				modelName = newDispenserModel;

				return Plugin_Changed;
			}
		}
	}
	else if (StrEqual(modelName, DISPENSER_LV3_MODEL))
	{
		StrCat(newDispenserModel, sizeof(newDispenserModel), "_lvl3.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			modelName = newDispenserModel;

			return Plugin_Changed;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, sizeof(newDispenserModel), ".mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				modelName = newDispenserModel;

				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

public Action TF2BH_TeleporterSetModel(int builder, int teleporter, char modelName[128])
{
	char newteleportermodel[128];
	if (!TF2CustAttr_ClientHasString(builder, "custom teleporter model", newteleportermodel, sizeof(newteleportermodel)))
	{
		return Plugin_Continue;
	}

	// If model path contains .mdl, just check file and apply.
	if (StrContains(newteleportermodel, ".mdl"))
	{
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			modelName = newteleportermodel;

			return Plugin_Changed;
		}
	}

	// Save for more case..
	char teleporterModel[128];
	strcopy(teleporterModel, sizeof(teleporterModel), newteleportermodel);

	if (StrEqual(modelName, TELEPORTER_BLUEPRINT_ENTER_MODEL))
	{
		StrCat(newteleportermodel, sizeof(newteleportermodel), "_blueprint_enter.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			modelName = newteleportermodel;

			return Plugin_Changed;
		}
		else
		{
			strcopy(newteleportermodel, sizeof(newteleportermodel), teleporterModel);
			StrCat(newteleportermodel, sizeof(newteleportermodel), "_blueprint.mdl");
			if (FileExists(newteleportermodel, true))
			{
				PrecacheModel(newteleportermodel);
				modelName = newteleportermodel;

				return Plugin_Changed;
			}
		}
	}
	else if (StrEqual(modelName, TELEPORTER_BLUEPRINT_EXIT_MODEL))
	{
		StrCat(newteleportermodel, sizeof(newteleportermodel), "_blueprint_exit.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			modelName = newteleportermodel;

			return Plugin_Changed;
		}
		else
		{
			strcopy(newteleportermodel, sizeof(newteleportermodel), teleporterModel);
			StrCat(newteleportermodel, sizeof(newteleportermodel), "_blueprint.mdl");
			if (FileExists(newteleportermodel, true))
			{
				PrecacheModel(newteleportermodel);
				modelName = newteleportermodel;

				return Plugin_Changed;
			}
		}
	}
	else if (StrEqual(modelName, TELEPORTER_LIGHT_MODEL))
	{
		StrCat(newteleportermodel, sizeof(newteleportermodel), "_light.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			modelName = newteleportermodel;

			return Plugin_Changed;
		}
	}
	else if (StrEqual(modelName, TELEPORTER_MODEL))
	{
		StrCat(newteleportermodel, sizeof(newteleportermodel), ".mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			modelName = newteleportermodel;

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action TF2BH_ObjectGetMaxHealth(int builder, int building, TFObjectType type, int &maxHealth)
{
	int wrench = GetPlayerWeaponSlot(builder, 2);
	int level = GetEntProp(building, Prop_Send, "m_iUpgradeLevel");

	if (IsValidEntity(wrench))
	{
		char attr[512];
		if (TF2CustAttr_GetString(wrench, "override building health", attr, sizeof(attr)))
		{
			switch (type)
			{
				case TFObject_Sentry:
				{
					if (ReadIntVar(attr, "sentry"))
					{
						switch (level)
						{
							case 1:
							{
								maxHealth = ReadIntVar(attr, "sentry1", 150);
								return Plugin_Changed;
							}
							case 2:
							{
								maxHealth = ReadIntVar(attr, "sentry2", 180);
								return Plugin_Changed;
							}
							case 3:
							{
								maxHealth = ReadIntVar(attr, "sentry3", 216);
								return Plugin_Changed;
							}
						}
					}
				}
				case TFObject_Dispenser:
				{
					if (ReadIntVar(attr, "dispenser"))
					{
						switch (level)
						{
							case 1:
							{
								maxHealth = ReadIntVar(attr, "dispenser1", 150);
								return Plugin_Changed;
							}
							case 2:
							{
								maxHealth = ReadIntVar(attr, "dispenser2", 180);
								return Plugin_Changed;
							}
							case 3:
							{
								maxHealth = ReadIntVar(attr, "dispenser3", 216);
								return Plugin_Changed;
							}
						}
					}
				}
				case TFObject_Teleporter:
				{
					if (ReadIntVar(attr, "teleporter"))
					{
						switch (level)
						{
							case 1:
							{
								maxHealth = ReadIntVar(attr, "teleporter1", 150);
								return Plugin_Changed;
							}
							case 2:
							{
								maxHealth = ReadIntVar(attr, "teleporter2", 180);
								return Plugin_Changed;
							}
							case 3:
							{
								maxHealth = ReadIntVar(attr, "teleporter3", 216);
								return Plugin_Changed;
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action TF2BH_DispenserGetHealRate(int builder, int dispenser, float &healrate)
{
	healrate = TF2CustAttr_HookValueFloatOnClient(healrate, "dispenser healrate multiplier", builder);
	return Plugin_Changed;
}

public Action TF2BH_PlayerCalculateObjectCost(int builder, TFObjectType type, int &cost)
{
	float returncost = float(cost);
	if (type == TFObject_Dispenser)
	{
		returncost = TF2CustAttr_HookValueFloatOnClient(returncost, "mod dispenser cost", builder);
	}
	else if (type == TFObject_Sentry)
	{
		returncost = TF2CustAttr_HookValueFloatOnClient(returncost, "mod sentry cost", builder);
	}

	cost = RoundFloat(returncost);
	return Plugin_Changed;
}

public Action TF2BH_ObjectGetConstructionMultiplier(int builder, int building, TFObjectType type, float &multiplier)
{
	if (type == TFObject_Dispenser)
	{
		multiplier = TF2CustAttr_HookValueFloatOnClient(multiplier, "engineer dispenser build rate multiplier", builder);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

static any Native_BuilderHasCustomDispenser(Handle plugin, int nParams)
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

static any Native_BuilderHasCustomSentry(Handle plugin, int nParams)
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

static any Native_BuilderHasCustomTeleporter(Handle plugin, int nParams)
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