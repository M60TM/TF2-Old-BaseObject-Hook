#pragma semicolon 1
#pragma newdecls required

/////////////////////////////
// Forward                 //
/////////////////////////////

GlobalForward g_ObjectOnGoActiveForward;
GlobalForward g_ObjectStartUpgradingForward;
GlobalForward g_ObjectFinishUpgradingForward;
GlobalForward g_DispenserStartHealingForward;
GlobalForward g_DispenserStopHealingPreForward;
GlobalForward g_DispenserStopHealingPostForward;

/////////////////////////////
// DHooks                  //
/////////////////////////////

static DynamicHook g_DHookObjectOnGoActive;
static DynamicHook g_DHookObjectStartUpgrading;
static DynamicHook g_DHookObjectFinishUpgrading;
static DynamicHook g_DHookDispenserStartHealing;
static DynamicHook g_DHookObjectGetMaxHealth;
static DynamicHook g_DHookSentrySetModel;
static DynamicHook g_DHookDispenserSetModel;
static DynamicHook g_DHookTeleporterSetModel;
static DynamicHook g_DHookGetHealRate;

public void Setup_DHook(GameData hGameConf)
{
	g_DHookObjectOnGoActive		 = DHookCreateDynamicHook(hGameConf, "CBaseObject::OnGoActive()");
	g_DHookObjectStartUpgrading	 = DHookCreateDynamicHook(hGameConf, "CBaseObject::StartUpgrading()");
	g_DHookObjectFinishUpgrading = DHookCreateDynamicHook(hGameConf, "CBaseObject::FinishUpgrading()");

	g_DHookDispenserStartHealing = DHookCreateDynamicHook(hGameConf, "CObjectDispenser::StartHealing()");

	g_DHookObjectGetMaxHealth	 = DHookCreateDynamicHook(hGameConf, "CBaseObject::GetMaxHealthForCurrentLevel()");

	g_DHookSentrySetModel		 = DHookCreateDynamicHook(hGameConf, "CObjectSentrygun::SetModel()");
	g_DHookDispenserSetModel	 = DHookCreateDynamicHook(hGameConf, "CObjectDispenser::SetModel()");
	g_DHookTeleporterSetModel	 = DHookCreateDynamicHook(hGameConf, "CObjectTeleporter::SetModel()");

	g_DHookGetHealRate			 = DHookCreateDynamicHook(hGameConf, "CObjectDispenser::GetHealRate()");

	DHookSetupDynamicDetour(hGameConf, "CTFPlayerShared::CalculateObjectCost()", .postCallback = OnCalculateObjectCostPost);
	DHookSetupDynamicDetour(hGameConf, "CObjectDispenser::StopHealing()", OnDispenserStopHealingPre, OnDispenserStopHealingPost);
	DHookSetupDynamicDetour(hGameConf, "CBaseObject::GetConstructionMultiplier()", .postCallback = GetConstructionMultiplierPost);
}

void DHookSetupDynamicDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);

	if (detour)
	{
		if (preCallback != INVALID_FUNCTION && !DHookEnableDetour(detour, false, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);

		if (postCallback != INVALID_FUNCTION && !DHookEnableDetour(detour, true, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);

		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

static DynamicHook DHookCreateDynamicHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if (!hook)
	{
		LogError("Failed to create %s DynamicHook", name);
	}

	return hook;
}

public void OnObjectCreated(int entity, const char[] classname)
{
	DHookEntity(g_DHookObjectOnGoActive, true, entity, .callback = ObjectOnGoActivePost);
	DHookEntity(g_DHookObjectStartUpgrading, true, entity, .callback = ObjectStartUpgradingPost);
	DHookEntity(g_DHookObjectFinishUpgrading, true, entity, .callback = ObjectFinishUpgradingPost);
	DHookEntity(g_DHookObjectGetMaxHealth, true, entity, .callback = ObjectGetMaxHealthPost);

	if (StrEqual(classname, "obj_sentrygun"))
	{
		DHookEntity(g_DHookSentrySetModel, false, entity, .callback = SentrySetModelPre);
	}
	else if (StrEqual(classname, "obj_dispenser"))
	{
		DHookEntity(g_DHookDispenserStartHealing, true, entity, .callback = DispenserStartHealingPost);
		DHookEntity(g_DHookDispenserSetModel, false, entity, .callback = DispenserSetModelPre);
		DHookEntity(g_DHookGetHealRate, true, entity, .callback = DispenserGetHealRatePost);
	}
	else if (StrEqual(classname, "obj_teleporter"))
	{
		DHookEntity(g_DHookTeleporterSetModel, false, entity, .callback = TeleporterSetModelPre);
		DHookEntity(g_DHookObjectGetMaxHealth, true, entity, .callback = ObjectGetMaxHealthPost);
	}
}

/**
 * forward void TF2CA_ObjectOnGoActive(int builder, int building, TFObjectType buildingtype);
 */
MRESReturn ObjectOnGoActivePost(int building)
{
	int			 builder	  = TF2_GetObjectBuilder(building);

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectOnGoActiveForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn ObjectStartUpgradingPost(int building)
{
	int	builder	= TF2_GetObjectBuilder(building);

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectStartUpgradingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();

	return MRES_Handled;
}

MRESReturn ObjectFinishUpgradingPost(int building)
{
	int	builder	= TF2_GetObjectBuilder(building);

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectFinishUpgradingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();

	return MRES_Handled;
}

/**
 * forward void TF2CA_DispenserStartHealing(int builder, int building, int patient);
 */
MRESReturn DispenserStartHealingPost(int building, Handle hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int patient = DHookGetParam(hParams, 1);

	if (!IsValidClient(patient))
	{
		patient = -1;
	}

	Call_StartForward(g_DispenserStartHealingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(patient);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn OnDispenserStopHealingPre(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int patient = DHookGetParam(hParams, 1);

	if (!IsValidClient(patient))
	{
		patient = -1;
	}

	Call_StartForward(g_DispenserStopHealingPreForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(patient);

	MRESReturn result;
	Call_Finish(result);

	return result;
}

/**
 * forward void TF2CA_DispenserStopHealing(int builder, int building, int patient);
 */
MRESReturn OnDispenserStopHealingPost(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		builder = -1;
	}

	int patient = DHookGetParam(hParams, 1);

	if (!IsValidClient(patient))
	{
		patient = -1;
	}

	Call_StartForward(g_DispenserStopHealingPostForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(patient);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn GetConstructionMultiplierPost(int building, DHookReturn hReturn)
{
	int builder = TF2_GetObjectBuilder(building);
	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	if (TF2_GetObjectType(building) == TFObject_Dispenser)
	{
		float returnvalue = DHookGetReturn(hReturn);
		returnvalue		  = TF2CustAttr_HookValueFloatOnClient(returnvalue, "engineer dispenser build rate multiplier", builder);
		DHookSetReturn(hReturn, returnvalue);

		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn ObjectGetMaxHealthPost(int building, DHookReturn hReturn)
{
	int builder = TF2_GetObjectBuilder(building);
	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	int wrench = GetPlayerWeaponSlot(builder, 2);
	int level  = GetEntProp(building, Prop_Send, "m_iUpgradeLevel");

	if (IsValidEntity(wrench))
	{
		char attr[512];
		if (TF2CustAttr_GetString(wrench, "override building health", attr, sizeof(attr)))
		{
			TFObjectType BuildingType = TF2_GetObjectType(building);
			switch (BuildingType)
			{
				case TFObject_Sentry:
				{
					if (ReadIntVar(attr, "sentry"))
					{
						switch (level)
						{
							case 1:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "sentry1", 150));
								return MRES_ChangedOverride;
							}
							case 2:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "sentry2", 180));
								return MRES_ChangedOverride;
							}
							case 3:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "sentry3", 216));
								return MRES_ChangedOverride;
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
								DHookSetReturn(hReturn, ReadIntVar(attr, "dispenser1", 150));
								return MRES_ChangedOverride;
							}
							case 2:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "dispenser2", 180));
								return MRES_ChangedOverride;
							}
							case 3:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "dispenser3", 216));
								return MRES_ChangedOverride;
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
								DHookSetReturn(hReturn, ReadIntVar(attr, "teleporter1", 150));
								return MRES_ChangedOverride;
							}
							case 2:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "teleporter2", 180));
								return MRES_ChangedOverride;
							}
							case 3:
							{
								DHookSetReturn(hReturn, ReadIntVar(attr, "teleporter3", 216));
								return MRES_ChangedOverride;
							}
						}
					}
				}
			}
		}
	}

	return MRES_Ignored;
}

MRESReturn DispenserGetHealRatePost(int building, DHookReturn hReturn)
{
	int builder = TF2_GetObjectBuilder(building);
	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	float healrate = DHookGetReturn(hReturn);
	healrate	   = TF2CustAttr_HookValueFloatOnClient(healrate, "dispenser healrate multiplier", builder);
	DHookSetReturn(hReturn, healrate);
	return MRES_Override;
}

#define SENTRY_BLUEPRINT_MODEL "models/buildables/sentry1_blueprint.mdl"
#define SENTRY_LV1_MODEL	   "models/buildables/sentry1.mdl"
#define SENTRY_LV1_HEAVY_MODEL "models/buildables/sentry1_heavy.mdl"
#define SENTRY_LV2_MODEL	   "models/buildables/sentry2.mdl"
#define SENTRY_LV2_HEAVY_MODEL "models/buildables/sentry2_heavy.mdl"
#define SENTRY_LV3_MODEL	   "models/buildables/sentry3.mdl"
#define SENTRY_LV3_HEAVY_MODEL "models/buildables/sentry3_heavy.mdl"

MRESReturn SentrySetModelPre(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	char newSentryModel[128];
	if (!TF2CustAttr_ClientHasString(builder, "custom sentry model", newSentryModel, sizeof(newSentryModel)))
	{
		return MRES_Ignored;
	}

	if (StrContains(newSentryModel, ".mdl"))
	{
		if (FileExists(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}

	char oldsentrymodel[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, oldsentrymodel, sizeof(oldsentrymodel));
	if (StrEqual(oldsentrymodel, SENTRY_BLUEPRINT_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "1_blueprint.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV1_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "1.mdl");
		if (FileExistsAndLog(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV1_HEAVY_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "1_heavy.mdl");
		if (FileExistsAndLog(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV2_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "2.mdl");
		if (FileExistsAndLog(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV2_HEAVY_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "2_heavy.mdl");
		if (FileExistsAndLog(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV3_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "3.mdl");
		if (FileExistsAndLog(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV3_HEAVY_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "3_heavy.mdl");
		if (FileExistsAndLog(newSentryModel, true))
		{
			PrecacheModelAndLog(newSentryModel);
			DHookSetParamString(hParams, 1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}

	return MRES_Ignored;
}

#define DISPENSER_BLUEPRINT_MODEL "models/buildables/dispenser_blueprint.mdl"
#define DISPENSER_LV1_LIGHT_MODEL "models/buildables/dispenser_light.mdl"
#define DISPENSER_LV1_MODEL		  "models/buildables/dispenser.mdl"
#define DISPENSER_LV2_LIGHT_MODEL "models/buildables/dispenser_lvl2_light.mdl"
#define DISPENSER_LV2_MODEL		  "models/buildables/dispenser_lvl2.mdl"
#define DISPENSER_LV3_LIGHT_MODEL "models/buildables/dispenser_lvl3_light.mdl"
#define DISPENSER_LV3_MODEL		  "models/buildables/dispenser_lvl3.mdl"

MRESReturn DispenserSetModelPre(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	char newDispenserModel[128];
	if (!TF2CustAttr_ClientHasString(builder, "custom dispenser model", newDispenserModel, sizeof(newDispenserModel)))
	{
		return MRES_Ignored;
	}

	if (StrContains(newDispenserModel, ".mdl"))
	{
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}

	char oldDispenserModel[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, oldDispenserModel, sizeof(oldDispenserModel));

	char dispenserModel[128];
	strcopy(dispenserModel, sizeof(dispenserModel), newDispenserModel);

	if (StrEqual(oldDispenserModel, DISPENSER_BLUEPRINT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_blueprint.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV1_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_light.mdl");
		if (FileExistsAndLog(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV1_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, ".mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV2_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl2_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_light.mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModelAndLog(newDispenserModel);
				DHookSetParamString(hParams, 1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV2_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl2.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, ".mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModelAndLog(newDispenserModel);
				DHookSetParamString(hParams, 1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV3_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl3_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_light.mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModelAndLog(newDispenserModel);
				DHookSetParamString(hParams, 1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV3_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl3.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModelAndLog(newDispenserModel);
			DHookSetParamString(hParams, 1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, ".mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModelAndLog(newDispenserModel);
				DHookSetParamString(hParams, 1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}

	return MRES_Ignored;
}

#define TELEPORTER_BLUEPRINT_ENTER_MODEL "models/buildables/teleporter_blueprint_enter.mdl"
#define TELEPORTER_BLUEPRINT_EXIT_MODEL	 "models/buildables/teleporter_blueprint_exit.mdl"
#define TELEPORTER_LIGHT_MODEL			 "models/buildables/teleporter_light.mdl"
#define TELEPORTER_MODEL				 "models/buildables/teleporter.mdl"

MRESReturn TeleporterSetModelPre(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	char newteleportermodel[128];
	if (!TF2CustAttr_ClientHasString(builder, "custom teleporter model", newteleportermodel, sizeof(newteleportermodel)))
	{
		return MRES_Ignored;
	}

	// If model path contains .mdl, just check file and apply.
	if (StrContains(newteleportermodel, ".mdl"))
	{
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModelAndLog(newteleportermodel);
			DHookSetParamString(hParams, 1, newteleportermodel);

			return MRES_ChangedHandled;
		}
	}

	char oldteleportermodel[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, oldteleportermodel, sizeof(oldteleportermodel));

	// Save for more case..
	char teleporterModel[128];
	strcopy(teleporterModel, sizeof(teleporterModel), newteleportermodel);

	if (StrEqual(oldteleportermodel, TELEPORTER_BLUEPRINT_ENTER_MODEL))
	{
		StrCat(newteleportermodel, sizeof(newteleportermodel), "_blueprint_enter.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModelAndLog(newteleportermodel);
			DHookSetParamString(hParams, 1, newteleportermodel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newteleportermodel, sizeof(newteleportermodel), teleporterModel);
			StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_blueprint.mdl");
			if (FileExists(newteleportermodel, true))
			{
				PrecacheModelAndLog(newteleportermodel);
				DHookSetParamString(hParams, 1, newteleportermodel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldteleportermodel, TELEPORTER_BLUEPRINT_EXIT_MODEL))
	{
		StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_blueprint_exit.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModelAndLog(newteleportermodel);
			DHookSetParamString(hParams, 1, newteleportermodel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newteleportermodel, sizeof(newteleportermodel), teleporterModel);
			StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_blueprint.mdl");
			if (FileExists(newteleportermodel, true))
			{
				PrecacheModelAndLog(newteleportermodel);
				DHookSetParamString(hParams, 1, newteleportermodel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldteleportermodel, TELEPORTER_LIGHT_MODEL))
	{
		StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_light.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModelAndLog(newteleportermodel);
			DHookSetParamString(hParams, 1, newteleportermodel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldteleportermodel, TELEPORTER_MODEL))
	{
		StrCat(newteleportermodel, PLATFORM_MAX_PATH, ".mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModelAndLog(newteleportermodel);
			DHookSetParamString(hParams, 1, newteleportermodel);

			return MRES_ChangedHandled;
		}
	}

	return MRES_Ignored;
}

MRESReturn OnCalculateObjectCostPost(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	int	  iCost		 = DHookGetReturn(hReturn);

	int	  builder	 = DHookGetParam(hParams, 1);

	int	  type		 = DHookGetParam(hParams, 2);

	float returncost = float(iCost);
	if (type == 0)
	{
		returncost = TF2CustAttr_HookValueFloatOnClient(returncost, "mod dispenser cost", builder);
	}
	else if (type == 2)
	{
		returncost = TF2CustAttr_HookValueFloatOnClient(returncost, "mod sentry cost", builder);
	}

	DHookSetReturn(hReturn, RoundFloat(returncost));

	return MRES_ChangedOverride;
}