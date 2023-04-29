#pragma semicolon 1
#pragma newdecls required

#define CUSTOM_BUILDING_TYPE_NAME_LENGTH 64

static char g_customDispenserType[MAXPLAYERS + 1][CUSTOM_BUILDING_TYPE_NAME_LENGTH];
static char g_customSentryType[MAXPLAYERS + 1][CUSTOM_BUILDING_TYPE_NAME_LENGTH];
static char g_customTeleporterType[MAXPLAYERS + 1][CUSTOM_BUILDING_TYPE_NAME_LENGTH];

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

	public int GetCustomDispenserType(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, g_customDispenserType[this.Client]);
	}

	public int SetCustomDispenserType(const char[] buffer)
	{
		return strcopy(g_customDispenserType[this.Client], sizeof(g_customDispenserType[]), buffer);
	}

	public int GetCustomSentryType(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, g_customSentryType[this.Client]);
	}

	public int SetCustomSentryType(const char[] buffer)
	{
		return strcopy(g_customSentryType[this.Client], sizeof(g_customSentryType[]), buffer);
	}

	public int GetCustomTeleporterType(char[] buffer, int maxlen)
	{
		return strcopy(buffer, maxlen, g_customTeleporterType[this.Client]);
	}

	public int SetCustomTeleporterType(const char[] buffer)
	{
		return strcopy(g_customTeleporterType[this.Client], sizeof(g_customTeleporterType[]), buffer);
	}
}