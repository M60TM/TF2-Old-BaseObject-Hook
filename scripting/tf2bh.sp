#pragma semicolon 1
#include <sourcemod>
#include <dhooks_gameconf_shim>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/functions>
#include <stocksoup/tf/entity_prop_stocks>

#include "tf2bh/utils.sp"
#include "tf2bh/dhooks.sp"
#include "tf2bh/natives.sp"

/////////////////////////////
// PLUGIN INFO             //
/////////////////////////////

public Plugin myinfo = {
	name        = "[TF2] BaseObject Hook",
	author      = "Sandy and Monera",
	description = "Natives and Forwards for Handling Building.",
	version     = "1.1.0",
	url         = "https://github.com/M60TM/TF2CA-Custom-Building"
};

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen) {
	RegPluginLibrary("tf2bh");

	Setup_Natives();

	return APLRes_Success;
}

public void OnPluginStart() {
	GameData data = new GameData("tf2.baseobject");
	if (!data) {
		SetFailState("Failed to load gamedata (tf2.baseobject).");
	} else if (!ReadDHooksDefinitions("tf2.baseobject")) {
		SetFailState("Failed to read dhooks definitions of gamedata (tf2.baseobject).");
	}

	Setup_SDKCalls(data);
	Setup_DHook(data);

	delete data;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "obj_sentrygun") || StrEqual(classname, "obj_dispenser") || StrEqual(classname, "obj_teleporter")) {
		OnObjectCreated(entity, classname);
	}
}