/////////////////////////////
// Forward Define          //
/////////////////////////////

static GlobalForward g_OnBuildObjectForward;
static GlobalForward g_OnUpgradeObjectForward;
static GlobalForward g_OnCarryObjectForward;
static GlobalForward g_OnDropObjectForward;
static GlobalForward g_OnObjectRemovedForward;
static GlobalForward g_OnObjectDestroyedForward;
static GlobalForward g_OnObjectDetonatedForward;
static GlobalForward g_OnSentrySoundForward;

/////////////////////////////
// Setup                   //
/////////////////////////////

void Setup_Forwards()
{
	g_OnBuildObjectForward = new GlobalForward("TF2CA_OnBuildObject", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnUpgradeObjectForward = new GlobalForward("TF2CA_OnUpgradeObject", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	g_OnCarryObjectForward = new GlobalForward("TF2CA_OnCarryObject", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnDropObjectForward = new GlobalForward("TF2CA_OnDropObject", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnObjectRemovedForward = new GlobalForward("TF2CA_OnObjectRemoved", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnObjectDestroyedForward = new GlobalForward("TF2CA_OnObjectDestroyed", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	g_OnObjectDetonatedForward = new GlobalForward("TF2CA_OnObjectDetonated", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	g_OnSentrySoundForward = new GlobalForward("TF2CA_SentryEmitSound", ET_Hook, Param_Cell, Param_Cell, Param_String, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef);
}

void CallBuildObjectForward(int builder, int building, TFObjectType buildingtype)
{
	Call_StartForward(g_OnBuildObjectForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

void CallUpgradeObjectForward(int upgrader, int builder, int building, TFObjectType buildingtype)
{
	Call_StartForward(g_OnUpgradeObjectForward);
	Call_PushCell(upgrader);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

void CallCarryObjectForward(int builder, int building, TFObjectType buildingtype)
{
	Call_StartForward(g_OnCarryObjectForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

void CallDropObjectForward(int builder, int building, TFObjectType buildingtype)
{
	Call_StartForward(g_OnDropObjectForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

void CallObjectRemovedForward(int builder, int building, TFObjectType buildingtype)
{
	Call_StartForward(g_OnObjectRemovedForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

void CallObjectDestroyedForward(int builder, int attacker, int assister, int weapon, int building, TFObjectType buildingtype, bool wasbuilding)
{
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

void CallObjectDetonatedForward(int builder, int building, TFObjectType buildingtype)
{
	Call_StartForward(g_OnObjectDetonatedForward);
	Call_PushCell(builder);
	Call_PushCell(building);
	Call_PushCell(buildingtype);
	Call_Finish();
}

Action CallSentryEmitSoundForward(int entity, int builder, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch)
{
	Call_StartForward(g_OnSentrySoundForward);
	Call_PushCell(entity);
	Call_PushCell(builder);
	Call_PushStringEx(sample, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(channel);
	Call_PushFloatRef(volume);
	Call_PushCellRef(level);
	Call_PushCellRef(pitch);
	Action result;
	Call_Finish(result);

	return result;
}