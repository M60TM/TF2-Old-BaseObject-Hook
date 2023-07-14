#pragma semicolon 1
#pragma newdecls required

#define CUSTOM_BUILDING_TYPE_NAME_LENGTH 64

static char customDispenserType[MAXPLAYERS + 1][CUSTOM_BUILDING_TYPE_NAME_LENGTH];
static char customSentryType[MAXPLAYERS + 1][CUSTOM_BUILDING_TYPE_NAME_LENGTH];
static char customTeleporterType[MAXPLAYERS + 1][CUSTOM_BUILDING_TYPE_NAME_LENGTH];

methodmap Builder
{
	public Builder(int client)
	{
		return view_as<Builder>(client);
	}

	property int Client
	{
		public get()
		{
			return view_as<int>(this);
		}
	}

	property bool IsValid
	{
		public get()
		{
			return IsValidClient(this.Client);
		}
	}

	public int GetCustomDispenserType(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, customDispenserType[this.Client]);
	}

	public int SetCustomDispenserType(const char[] buffer)
	{
		return strcopy(customDispenserType[this.Client], sizeof(customDispenserType[]), buffer);
	}

	public int GetCustomSentryType(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, customSentryType[this.Client]);
	}

	public int SetCustomSentryType(const char[] buffer)
	{
		return strcopy(customSentryType[this.Client], sizeof(customSentryType[]), buffer);
	}

	public int GetCustomTeleporterType(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, customTeleporterType[this.Client]);
	}

	public int SetCustomTeleporterType(const char[] buffer)
	{
		return strcopy(customTeleporterType[this.Client], sizeof(customTeleporterType[]), buffer);
	}
}