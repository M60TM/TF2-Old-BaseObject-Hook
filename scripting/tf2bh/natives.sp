#pragma semicolon 1
#pragma newdecls required

/////////////////////////////
// Setup                   //
/////////////////////////////

void Setup_Natives() {
	CreateNative("TF2BH_PlayerDetonateObjectOfType", Native_DetonateObjectOfType);
	CreateNative("TF2BH_PlayerGetObjectOfType", Native_PlayerGetObjectOfType);
	CreateNative("TF2BH_ObjectDestroyScreens", Native_DestroyScreens);
	CreateNative("TF2BH_PlayerRemoveAllObjects", Native_PlayerRemoveAllObjects);
}

/////////////////////////////
// Native                  //
/////////////////////////////

static any Native_DetonateObjectOfType(Handle plugin, int nParams) {
	int	client = GetNativeInGameClient(1);
	int	type = GetNativeCell(2);
	int	mode = GetNativeCell(3);
	bool silent = GetNativeCell(4);

	return DetonateObjectOfType(client, type, mode, silent);
}

static any Native_PlayerGetObjectOfType(Handle plugin, int nParams) {
	int owner = GetNativeInGameClient(1);
	int objectType = GetNativeCell(2);
	int objectMode = GetNativeCell(3);

	return PlayerGetObjectOfType(owner, objectType, objectMode);
}

static any Native_DestroyScreens(Handle plugin, int nParams) {
	int building = GetNativeCell(1);

	return DestroyScreens(building);
}

static any Native_PlayerRemoveAllObjects(Handle plugin, int nParams) {
	int	client = GetNativeInGameClient(1);
	bool explode = GetNativeCell(2);

	return RemoveAllObjects(client, explode);
}