#pragma semicolon 1
#pragma newdecls required

/////////////////////////////
// Forward Define          //
/////////////////////////////

static GlobalForward g_ObjectOnGoActiveForward;
static GlobalForward g_ObjectStartUpgradingForward;
static GlobalForward g_ObjectFinishUpgradingForward;
static GlobalForward g_DispenserStartHealingForward;
static GlobalForward g_DispenserStopHealingForward;
static GlobalForward g_DispenserCouldHealTargetForward;

/////////////////////////////
// DHooks Define           //
/////////////////////////////

static DynamicHook g_DHookObjectOnGoActive;
static DynamicHook g_DHookObjectStartUpgrading;
static DynamicHook g_DHookObjectFinishUpgrading;
static DynamicHook g_DHookDispenserStartHealing;
static DynamicHook g_DHookObjectGetMaxHealth;
static DynamicHook g_DHookObjectSetModel;
static DynamicHook g_DHookGetHealRate;

/////////////////////////////
// Setup Stuffs            //
/////////////////////////////

public void Setup_DHook(GameData data)
{
	Setup_DHook_Forwards();
	
	g_DHookObjectOnGoActive = GetDHooksHookDefinition(data, "CBaseObject::OnGoActive()");
	g_DHookObjectStartUpgrading = GetDHooksHookDefinition(data, "CBaseObject::StartUpgrading()");
	g_DHookObjectFinishUpgrading = GetDHooksHookDefinition(data, "CBaseObject::FinishUpgrading()");
	g_DHookObjectGetMaxHealth = GetDHooksHookDefinition(data, "CBaseObject::GetMaxHealthForCurrentLevel()");

	g_DHookObjectSetModel = GetDHooksHookDefinition(data, "CBaseObject::SetModel()");

	g_DHookDispenserStartHealing = GetDHooksHookDefinition(data, "CObjectDispenser::StartHealing()");
	g_DHookGetHealRate = GetDHooksHookDefinition(data, "CObjectDispenser::GetHealRate()");

	DynamicDetour DynDetourCalculateObjectCost = GetDHooksDetourDefinition(data, "CTFPlayerShared::CalculateObjectCost()");
	DynDetourCalculateObjectCost.Enable(Hook_Post, DynDetour_CalculateObjectCostPost);
	DynamicDetour DynDetourStopHealing = GetDHooksDetourDefinition(data, "CObjectDispenser::StopHealing()");
	DynDetourStopHealing.Enable(Hook_Post, DynDetour_DispenserStopHealingPost);
	DynamicDetour DynDetourGetConstructionMultiplier = GetDHooksDetourDefinition(data, "CBaseObject::GetConstructionMultiplier()");
	DynDetourGetConstructionMultiplier.Enable(Hook_Post, DynDetour_GetConstructionMultiplierPost);
	DynamicDetour DynDetourCouldHealTarget = GetDHooksDetourDefinition(data, "CObjectDispenser::CouldHealTarget");
	DynDetourCouldHealTarget.Enable(Hook_Pre, DynDetour_CouldHealTargetPre);
}

void Setup_DHook_Forwards()
{
	g_ObjectOnGoActiveForward = new GlobalForward("TF2CA_ObjectOnGoActive", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectStartUpgradingForward = new GlobalForward("TF2CA_ObjectStartUpgrading", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectFinishUpgradingForward = new GlobalForward("TF2CA_ObjectFinishUpgrading", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserStartHealingForward = new GlobalForward("TF2CA_DispenserStartHealing", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserStopHealingForward = new GlobalForward("TF2CA_DispenserStopHealing", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserCouldHealTargetForward = new GlobalForward("TF2CA_DispenserCouldHealTarget", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
}

void OnObjectCreated(int entity, const char[] classname)
{
	g_DHookObjectOnGoActive.HookEntity(Hook_Post, entity, DHook_ObjectOnGoActivePost);
	g_DHookObjectStartUpgrading.HookEntity(Hook_Post, entity, DHook_ObjectStartUpgradingPost);
	g_DHookObjectFinishUpgrading.HookEntity(Hook_Post, entity, DHook_ObjectFinishUpgradingPost);
	g_DHookObjectGetMaxHealth.HookEntity(Hook_Post, entity, DHook_ObjectGetMaxHealthPost);

	if (StrEqual(classname, "obj_sentrygun"))
	{
		g_DHookObjectSetModel.HookEntity(Hook_Pre, entity, SentrySetModelPre);
	}
	else if (StrEqual(classname, "obj_dispenser"))
	{
		g_DHookObjectSetModel.HookEntity(Hook_Pre, entity, DispenserSetModelPre);
		g_DHookDispenserStartHealing.HookEntity(Hook_Post, entity, DHook_DispenserStartHealingPost);
		g_DHookGetHealRate.HookEntity(Hook_Post, entity, DispenserGetHealRatePost);
	}
	else if (StrEqual(classname, "obj_teleporter"))
	{
		g_DHookObjectSetModel.HookEntity(Hook_Pre, entity, TeleporterSetModelPre);
	}
}

/**
 * forward void TF2CA_ObjectOnGoActive(int builder, int building, TFObjectType buildingtype);
 */
MRESReturn DHook_ObjectOnGoActivePost(int building)
{
	int builder = TF2_GetObjectBuilder(building);

	TFObjectType buildingtype = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectOnGoActiveForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DHook_ObjectStartUpgradingPost(int building)
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

MRESReturn DHook_ObjectFinishUpgradingPost(int building)
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

MRESReturn DHook_ObjectGetMaxHealthPost(int building, DHookReturn hReturn)
{
	int builder = TF2_GetObjectBuilder(building);
	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	int wrench = GetPlayerWeaponSlot(builder, 2);
	int level = GetEntProp(building, Prop_Send, "m_iUpgradeLevel");

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
								hReturn.Value = ReadIntVar(attr, "sentry1", 150);
								return MRES_ChangedOverride;
							}
							case 2:
							{
								hReturn.Value = ReadIntVar(attr, "sentry2", 180);
								return MRES_ChangedOverride;
							}
							case 3:
							{
								hReturn.Value = ReadIntVar(attr, "sentry3", 216);
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
								hReturn.Value = ReadIntVar(attr, "dispenser1", 150);
								return MRES_ChangedOverride;
							}
							case 2:
							{
								hReturn.Value = ReadIntVar(attr, "dispenser2", 180);
								return MRES_ChangedOverride;
							}
							case 3:
							{
								hReturn.Value = ReadIntVar(attr, "dispenser3", 216);
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
								hReturn.Value = ReadIntVar(attr, "teleporter1", 150);
								return MRES_ChangedOverride;
							}
							case 2:
							{
								hReturn.Value = ReadIntVar(attr, "teleporter2", 180);
								return MRES_ChangedOverride;
							}
							case 3:
							{
								hReturn.Value = ReadIntVar(attr, "teleporter3", 216);
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
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}

	char oldsentrymodel[PLATFORM_MAX_PATH];
	hParams.GetString(1, oldsentrymodel, sizeof(oldsentrymodel));
	if (StrEqual(oldsentrymodel, SENTRY_BLUEPRINT_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "1_blueprint.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV1_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "1.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV1_HEAVY_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "1_heavy.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV2_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "2.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV2_HEAVY_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "2_heavy.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV3_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "3.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldsentrymodel, SENTRY_LV3_HEAVY_MODEL))
	{
		StrCat(newSentryModel, PLATFORM_MAX_PATH, "3_heavy.mdl");
		if (FileExists(newSentryModel, true))
		{
			PrecacheModel(newSentryModel);
			hParams.SetString(1, newSentryModel);

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
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}

	char oldDispenserModel[PLATFORM_MAX_PATH];
	hParams.GetString(1, oldDispenserModel, sizeof(oldDispenserModel));

	char dispenserModel[128];
	strcopy(dispenserModel, sizeof(dispenserModel), newDispenserModel);

	if (StrEqual(oldDispenserModel, DISPENSER_BLUEPRINT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_blueprint.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV1_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV1_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, ".mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV2_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl2_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_light.mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				hParams.SetString(1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV2_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl2.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, ".mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				hParams.SetString(1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV3_LIGHT_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl3_light.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_light.mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				hParams.SetString(1, newDispenserModel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldDispenserModel, DISPENSER_LV3_MODEL))
	{
		StrCat(newDispenserModel, PLATFORM_MAX_PATH, "_lvl3.mdl");
		if (FileExists(newDispenserModel, true))
		{
			PrecacheModel(newDispenserModel);
			hParams.SetString(1, newDispenserModel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newDispenserModel, sizeof(newDispenserModel), dispenserModel);
			StrCat(newDispenserModel, PLATFORM_MAX_PATH, ".mdl");
			if (FileExists(newDispenserModel, true))
			{
				PrecacheModel(newDispenserModel);
				hParams.SetString(1, newDispenserModel);

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
			PrecacheModel(newteleportermodel);
			hParams.SetString(1, newteleportermodel);

			return MRES_ChangedHandled;
		}
	}

	char oldteleportermodel[PLATFORM_MAX_PATH];
	hParams.GetString(1, oldteleportermodel, sizeof(oldteleportermodel));

	// Save for more case..
	char teleporterModel[128];
	strcopy(teleporterModel, sizeof(teleporterModel), newteleportermodel);

	if (StrEqual(oldteleportermodel, TELEPORTER_BLUEPRINT_ENTER_MODEL))
	{
		StrCat(newteleportermodel, sizeof(newteleportermodel), "_blueprint_enter.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			hParams.SetString(1, newteleportermodel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newteleportermodel, sizeof(newteleportermodel), teleporterModel);
			StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_blueprint.mdl");
			if (FileExists(newteleportermodel, true))
			{
				PrecacheModel(newteleportermodel);
				hParams.SetString(1, newteleportermodel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldteleportermodel, TELEPORTER_BLUEPRINT_EXIT_MODEL))
	{
		StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_blueprint_exit.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			hParams.SetString(1, newteleportermodel);

			return MRES_ChangedHandled;
		}
		else
		{
			strcopy(newteleportermodel, sizeof(newteleportermodel), teleporterModel);
			StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_blueprint.mdl");
			if (FileExists(newteleportermodel, true))
			{
				PrecacheModel(newteleportermodel);
				hParams.SetString(1, newteleportermodel);

				return MRES_ChangedHandled;
			}
		}
	}
	else if (StrEqual(oldteleportermodel, TELEPORTER_LIGHT_MODEL))
	{
		StrCat(newteleportermodel, PLATFORM_MAX_PATH, "_light.mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			hParams.SetString(1, newteleportermodel);

			return MRES_ChangedHandled;
		}
	}
	else if (StrEqual(oldteleportermodel, TELEPORTER_MODEL))
	{
		StrCat(newteleportermodel, PLATFORM_MAX_PATH, ".mdl");
		if (FileExists(newteleportermodel, true))
		{
			PrecacheModel(newteleportermodel);
			hParams.SetString(1, newteleportermodel);

			return MRES_ChangedHandled;
		}
	}

	return MRES_Ignored;
}

/**
 * forward void TF2CA_DispenserStartHealing(int builder, int building, int patient);
 */
MRESReturn DHook_DispenserStartHealingPost(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	int patient = hParams.Get(1);
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

MRESReturn DispenserGetHealRatePost(int building, DHookReturn hReturn)
{
	int builder = TF2_GetObjectBuilder(building);
	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	float healrate = hReturn.Value;
	healrate = TF2CustAttr_HookValueFloatOnClient(healrate, "dispenser healrate multiplier", builder);
	hReturn.Value = healrate;
	return MRES_Override;
}

MRESReturn DynDetour_CalculateObjectCostPost(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	int cost = hReturn.Value;

	int builder = hParams.Get(1);

	int	type = hParams.Get(2);

	float returncost = float(cost);
	if (type == 0)
	{
		returncost = TF2CustAttr_HookValueFloatOnClient(returncost, "mod dispenser cost", builder);
	}
	else if (type == 2)
	{
		returncost = TF2CustAttr_HookValueFloatOnClient(returncost, "mod sentry cost", builder);
	}

	hReturn.Value = RoundFloat(returncost);

	return MRES_ChangedOverride;
}

/**
 * forward void TF2CA_DispenserStopHealing(int builder, int building, int patient);
 */
MRESReturn DynDetour_DispenserStopHealingPost(int building, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);

	int patient = DHookGetParam(hParams, 1);
	if (!IsValidClient(patient))
	{
		patient = -1;
	}

	Call_StartForward(g_DispenserStopHealingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(patient);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DynDetour_GetConstructionMultiplierPost(int building, DHookReturn hReturn)
{
	int builder = TF2_GetObjectBuilder(building);
	if (!IsValidClient(builder))
	{
		return MRES_Ignored;
	}

	if (TF2_GetObjectType(building) == TFObject_Dispenser)
	{
		float returnvalue = DHookGetReturn(hReturn);
		returnvalue = TF2CustAttr_HookValueFloatOnClient(returnvalue, "engineer dispenser build rate multiplier", builder);
		hReturn.Value = returnvalue;

		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn DynDetour_CouldHealTargetPre(int building, DHookReturn hReturn, DHookParam hParams)
{
	int builder = TF2_GetObjectBuilder(building);
	int patient = hParams.Get(1);

	if (IsValidClient(patient))
	{
		Call_StartForward(g_DispenserCouldHealTargetForward);
		Call_PushCell(builder);
		Call_PushCell(building);
		Call_PushCell(patient);
		bool result;
		Call_PushCellRef(result);
		Action ret;
		Call_Finish(ret);

		if (ret > Plugin_Changed)
		{
			hReturn.Value = result;
			return MRES_Supercede;
		}
	}

	return MRES_Ignored;
}