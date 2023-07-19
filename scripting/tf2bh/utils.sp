/////////////////////////////
// SDKCall                 //
/////////////////////////////

static Handle g_SDKCallDetonateObjectOfType;
static Handle g_SDKCallBuildingDestroyScreens;
static Handle g_SDKCallPlayerGetObjectOfType;

void Setup_SDKCalls(GameData data)
{
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
}

/////////////////////////////
// Stock                   //
/////////////////////////////

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