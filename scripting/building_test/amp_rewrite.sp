#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <tf2utils>
#include <tf2bh>
#include <tf2ca_custom_building>

#define ATTR_AMP "build amplifier"

public Plugin myinfo = {
	name = "[TF2] Custom Attribute: Amplifier",
	author = "Sandy",
	description = "Mini Crits!",
	version = "1.0.1",
	url = ""
};

public void TF2BH_DispenserStartHealing(int builder, int building, int patient) {
	if (!IsValidClient(builder)) {
		return;
	}

	if (TF2CA_BuilderHasCustomDispenser(builder, ATTR_AMP)) {
		if (IsValidClient(patient)) {
			TF2_AddCondition(patient, TFCond_Buffed, TFCondDuration_Infinite, builder);
		}
	}
}

public void TF2BH_DispenserStopHealing(int builder, int building, int patient) {
	if (IsValidClient(patient) && IsValidClient(builder)) {
		if (TF2_IsPlayerInCondition(patient, TFCond_Buffed) && TF2Util_GetPlayerConditionProvider(patient, TFCond_Buffed) == builder) {
			TF2_RemoveCondition(patient, TFCond_Buffed);
		}
	}
}

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