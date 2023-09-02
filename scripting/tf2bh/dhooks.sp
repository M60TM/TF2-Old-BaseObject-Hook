#pragma semicolon 1
#pragma newdecls required

/////////////////////////////
// Forward Define          //
/////////////////////////////

static GlobalForward g_ObjectOnGoActiveForward;
static GlobalForward g_ObjectStartUpgradingForward;
static GlobalForward g_ObjectFinishUpgradingForward;
static GlobalForward g_ObjectGetMaxHealthForCurrentLevel;
static GlobalForward g_SentrygunSetModel;
static GlobalForward g_DispenserSetModel;
static GlobalForward g_TeleporterSetModel;
static GlobalForward g_DispenserStartHealingForward;
static GlobalForward g_DispenserGetHealRate;
static GlobalForward g_DispenserStopHealingForward;
static GlobalForward g_PlayerCalculateObjectCost;
static GlobalForward g_ObjectGetConstructionMultiplier;
static GlobalForward g_DispenserCouldHealTargetForward;

/////////////////////////////
// DHooks Define           //
/////////////////////////////

static DynamicHook g_DHookObjectOnGoActive;
static DynamicHook g_DHookObjectStartUpgrading;
static DynamicHook g_DHookObjectFinishUpgrading;
static DynamicHook g_DHookObjectGetMaxHealth;
static DynamicHook g_DHookDispenserStartHealing;
static DynamicHook g_DHookObjectSetModel;
static DynamicHook g_DHookGetHealRate;

/////////////////////////////
// Setup Stuffs            //
/////////////////////////////

public void Setup_DHook(GameData data) {
	Setup_DHook_Forwards();
	
	g_DHookObjectOnGoActive = GetDHooksHookDefinition(data, "CBaseObject::OnGoActive()");
	g_DHookObjectStartUpgrading = GetDHooksHookDefinition(data, "CBaseObject::StartUpgrading()");
	g_DHookObjectFinishUpgrading = GetDHooksHookDefinition(data, "CBaseObject::FinishUpgrading()");
	g_DHookObjectGetMaxHealth = GetDHooksHookDefinition(data, "CBaseObject::GetMaxHealthForCurrentLevel()");

	g_DHookObjectSetModel = GetDHooksHookDefinition(data, "CBaseObject::SetModel()");

	g_DHookDispenserStartHealing = GetDHooksHookDefinition(data, "CObjectDispenser::StartHealing()");
	g_DHookGetHealRate = GetDHooksHookDefinition(data, "CObjectDispenser::GetHealRate()");

	DynamicDetour dynDetourCalculateObjectCost = GetDHooksDetourDefinition(data, "CTFPlayerShared::CalculateObjectCost()");
	dynDetourCalculateObjectCost.Enable(Hook_Post, DynDetour_CalculateObjectCostPost);
	DynamicDetour dynDetourStopHealing = GetDHooksDetourDefinition(data, "CObjectDispenser::StopHealing()");
	dynDetourStopHealing.Enable(Hook_Post, DynDetour_DispenserStopHealingPost);
	DynamicDetour dynDetourGetConstructionMultiplier = GetDHooksDetourDefinition(data, "CBaseObject::GetConstructionMultiplier()");
	dynDetourGetConstructionMultiplier.Enable(Hook_Post, DynDetour_GetConstructionMultiplierPost);
	DynamicDetour dynDetourCouldHealTarget = GetDHooksDetourDefinition(data, "CObjectDispenser::CouldHealTarget");
	dynDetourCouldHealTarget.Enable(Hook_Pre, DynDetour_CouldHealTargetPre);
}

void Setup_DHook_Forwards() {
	g_ObjectOnGoActiveForward = new GlobalForward("TF2BH_ObjectOnGoActive", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectStartUpgradingForward = new GlobalForward("TF2BH_ObjectStartUpgrading", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectFinishUpgradingForward = new GlobalForward("TF2BH_ObjectFinishUpgrading", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_ObjectGetMaxHealthForCurrentLevel = new GlobalForward("TF2BH_ObjectGetMaxHealth", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);

	g_SentrygunSetModel = new GlobalForward("TF2BH_SentrygunSetModel", ET_Hook, Param_Cell, Param_Cell, Param_String);

	g_DispenserSetModel = new GlobalForward("TF2BH_DispenserSetModel", ET_Hook, Param_Cell, Param_Cell, Param_String);

	g_TeleporterSetModel = new GlobalForward("TF2BH_TeleporterSetModel", ET_Hook, Param_Cell, Param_Cell,Param_String);

	g_DispenserStartHealingForward = new GlobalForward("TF2BH_DispenserStartHealing", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_DispenserGetHealRate = new GlobalForward("TF2BH_DispenserGetHealRate", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);

	g_DispenserStopHealingForward = new GlobalForward("TF2BH_DispenserStopHealing", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_PlayerCalculateObjectCost = new GlobalForward("TF2BH_PlayerCalculateObjectCost", ET_Hook, Param_Cell, Param_Cell,  Param_CellByRef);

	g_ObjectGetConstructionMultiplier = new GlobalForward("TF2BH_ObjectGetConstructionMultiplier", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);

	g_DispenserCouldHealTargetForward = new GlobalForward("TF2BH_DispenserCouldHealTarget", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
}

void OnObjectCreated(int entity, const char[] classname) {
	g_DHookObjectOnGoActive.HookEntity(Hook_Post, entity, DHook_ObjectOnGoActivePost);
	g_DHookObjectStartUpgrading.HookEntity(Hook_Post, entity, DHook_ObjectStartUpgradingPost);
	g_DHookObjectFinishUpgrading.HookEntity(Hook_Post, entity, DHook_ObjectFinishUpgradingPost);
	g_DHookObjectGetMaxHealth.HookEntity(Hook_Post, entity, DHook_ObjectGetMaxHealthPost);

	if (StrEqual(classname, "obj_sentrygun")) {
		g_DHookObjectSetModel.HookEntity(Hook_Pre, entity, DHook_SentrySetModelPre);
	} else if (StrEqual(classname, "obj_dispenser")) {
		g_DHookObjectSetModel.HookEntity(Hook_Pre, entity, DHook_DispenserSetModelPre);
		g_DHookDispenserStartHealing.HookEntity(Hook_Post, entity, DHook_DispenserStartHealingPost);
		g_DHookGetHealRate.HookEntity(Hook_Post, entity, DispenserGetHealRatePost);
	} else if (StrEqual(classname, "obj_teleporter")) {
		g_DHookObjectSetModel.HookEntity(Hook_Pre, entity, DHook_TeleporterSetModelPre);
	}
}

/**
 * forward void TF2CA_ObjectOnGoActive(int builder, int building, TFObjectType buildingtype);
 */
MRESReturn DHook_ObjectOnGoActivePost(int building) {
	int builder = TF2_GetObjectBuilder(building);

	TFObjectType type = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectOnGoActiveForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(type);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DHook_ObjectStartUpgradingPost(int building) {
	int	builder	= TF2_GetObjectBuilder(building);

	TFObjectType type = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectStartUpgradingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(type);
	Call_Finish();

	return MRES_Handled;
}

MRESReturn DHook_ObjectFinishUpgradingPost(int building) {
	int	builder	= TF2_GetObjectBuilder(building);

	TFObjectType type = TF2_GetObjectType(building);

	Call_StartForward(g_ObjectFinishUpgradingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(type);
	Call_Finish();

	return MRES_Handled;
}

MRESReturn DHook_ObjectGetMaxHealthPost(int building, DHookReturn hReturn) {
	int builder = TF2_GetObjectBuilder(building);

	TFObjectType type = TF2_GetObjectType(building);

	int health = hReturn.Value;

	Call_StartForward(g_ObjectGetMaxHealthForCurrentLevel);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(type);
	Call_PushCellRef(health);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hReturn.Value = health;
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn DHook_SentrySetModelPre(int building, DHookParam hParams) {
	int builder = TF2_GetObjectBuilder(building);
	
	char modelName[128];
	hParams.GetString(1, modelName, sizeof(modelName));

	Call_StartForward(g_SentrygunSetModel);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushStringEx(modelName, 128, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hParams.SetString(1, modelName);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DHook_DispenserSetModelPre(int building, DHookParam hParams) {
	int builder = TF2_GetObjectBuilder(building);

	char modelName[128];
	hParams.GetString(1, modelName, sizeof(modelName));

	Call_StartForward(g_DispenserSetModel);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushStringEx(modelName, 128, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hParams.SetString(1, modelName);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DHook_TeleporterSetModelPre(int building, DHookParam hParams) {
	int builder = TF2_GetObjectBuilder(building);

	char modelName[128];
	hParams.GetString(1, modelName, sizeof(modelName));

	Call_StartForward(g_TeleporterSetModel);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushStringEx(modelName, 128, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hParams.SetString(1, modelName);
		return MRES_ChangedHandled;
	}
	
	return MRES_Ignored;
}

/**
 * forward void TF2CA_DispenserStartHealing(int builder, int building, int patient);
 */
MRESReturn DHook_DispenserStartHealingPost(int building, DHookParam hParams) {
	int builder = TF2_GetObjectBuilder(building);

	int patient = hParams.Get(1);
	if (!IsValidClient(patient)) {
		patient = -1;
	}

	Call_StartForward(g_DispenserStartHealingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(patient);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DispenserGetHealRatePost(int building, DHookReturn hReturn) {
	int builder = TF2_GetObjectBuilder(building);

	float healrate = hReturn.Value;
	Call_StartForward(g_DispenserGetHealRate);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushFloatRef(healrate);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hReturn.Value = healrate;
		return MRES_Override;
	}
	
	return MRES_Ignored;
}

MRESReturn DynDetour_CalculateObjectCostPost(Address pThis, DHookReturn hReturn, DHookParam hParams) {
	int cost = hReturn.Value;

	int builder = hParams.Get(1);

	TFObjectType type = hParams.Get(2);

	Call_StartForward(g_PlayerCalculateObjectCost);
	Call_PushCell(builder);
	Call_PushCell(type);
	Call_PushCellRef(cost);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hReturn.Value = cost;
		return MRES_Override;
	}

	return MRES_Ignored;
}

/**
 * forward void TF2CA_DispenserStopHealing(int builder, int building, int patient);
 */
MRESReturn DynDetour_DispenserStopHealingPost(int building, DHookParam hParams) {
	int builder = TF2_GetObjectBuilder(building);

	int patient = DHookGetParam(hParams, 1);
	if (!IsValidClient(patient)) {
		patient = -1;
	}

	Call_StartForward(g_DispenserStopHealingForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(patient);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DynDetour_GetConstructionMultiplierPost(int building, DHookReturn hReturn) {
	int builder = TF2_GetObjectBuilder(building);

	TFObjectType type = TF2_GetObjectType(building);

	float multiplier = hReturn.Value;

	Call_StartForward(g_ObjectGetConstructionMultiplier);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(type);
	Call_PushFloatRef(multiplier);
	Action result;
	Call_Finish(result);

	if (result > Plugin_Continue) {
		hReturn.Value = multiplier;
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn DynDetour_CouldHealTargetPre(int building, DHookReturn hReturn, DHookParam hParams) {
	int builder = TF2_GetObjectBuilder(building);
	int patient = hParams.Get(1);

	if (IsValidClient(patient)) {
		Call_StartForward(g_DispenserCouldHealTargetForward);
		Call_PushCell(builder);
		Call_PushCell(building);
		Call_PushCell(patient);
		bool result = hReturn.Value;
		Call_PushCellRef(result);
		Action ret;
		Call_Finish(ret);

		if (ret > Plugin_Continue) {
			hReturn.Value = result;
			return MRES_Supercede;
		}
	}

	return MRES_Ignored;
}