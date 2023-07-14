/////////////////////////////
// Setup                   //
/////////////////////////////

void Setup_Natives()
{
	CreateNative("TF2CA_BuilderHasCustomDispenser", Native_BuilderHasCustomDispenser);
	CreateNative("TF2CA_BuilderHasCustomSentry", Native_BuilderHasCustomSentry);
	CreateNative("TF2CA_BuilderHasCustomTeleporter", Native_BuilderHasCustomTeleporter);
	CreateNative("TF2CA_DetonateObjectOfType", Native_DetonateObjectOfType);
	CreateNative("TF2CA_PlayerGetObjectOfType", Native_PlayerGetObjectOfType);
	CreateNative("TF2CA_DestroyScreens", Native_DestroyScreens);
}

/////////////////////////////
// Native                  //
/////////////////////////////

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

static any Native_DetonateObjectOfType(Handle plugin, int nParams)
{
	int	 client = GetNativeInGameClient(1);
	int	 type	= GetNativeCell(2);
	int	 mode	= GetNativeCell(3);
	bool silent = GetNativeCell(4);

	return DetonateObjectOfType(client, type, mode, silent);
}

static any Native_PlayerGetObjectOfType(Handle plugin, int nParams)
{
	int owner = GetNativeInGameClient(1);
	int objectType = GetNativeCell(2);
	int objectMode = GetNativeCell(3);

	return PlayerGetObjectOfType(owner, objectType, objectMode);
}

static any Native_DestroyScreens(Handle plugin, int nParams)
{
	int building = GetNativeCell(1);

	return DestroyScreens(building);
}