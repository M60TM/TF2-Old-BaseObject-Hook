#pragma semicolon 1
#pragma newdecls required

/////////////////////////////
// SDKCall                 //
/////////////////////////////

static Handle g_SDKCallDetonateObjectOfType;
static Handle g_SDKCallObjectDestroyScreens;
static Handle g_SDKCallPlayerGetObjectOfType;
static Handle g_SDKCallPlayerRemoveAllObjects;

void Setup_SDKCalls(GameData data) {
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CTFPlayer::DetonateObjectOfType()");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // int - type
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // int - mode
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // bool - force
	g_SDKCallDetonateObjectOfType = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CTFPlayer::GetObjectOfType()");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallPlayerGetObjectOfType = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CBaseObject::DestroyScreens()");
	g_SDKCallObjectDestroyScreens = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CTFPlayer::RemoveAllObjects()");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	  // bool - explodeBulidings
	g_SDKCallPlayerRemoveAllObjects = EndPrepSDKCall();
}

/////////////////////////////
// Stock                   //
/////////////////////////////

stock bool IsValidClient(int client, bool replaycheck = true) {
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

any DetonateObjectOfType(int client, int type, int mode = 0, bool force = false) {
	return SDKCall(g_SDKCallDetonateObjectOfType, client, type, mode, force);
}

any PlayerGetObjectOfType(int owner, int objectType, int objectMode) {
	return SDKCall(g_SDKCallPlayerGetObjectOfType, owner, objectType, objectMode);
}

any DestroyScreens(int building) {
	return SDKCall(g_SDKCallObjectDestroyScreens, building);
}

any RemoveAllObjects(int client, bool explode) {
	return SDKCall(g_SDKCallPlayerRemoveAllObjects, client, explode);
}