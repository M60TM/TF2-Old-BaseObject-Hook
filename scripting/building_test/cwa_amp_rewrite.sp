#pragma semicolon 1
#include <sourcemod>

#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

#include <tf2utils>
#include <tf2ca_custom_building>

#define ATTR_AMP "build amplifier"

public Plugin myinfo = {
	name = "[TF2] Custom Attribute: Amplifier",
	author = "Sandy",
	description = "Mini Crits!",
	version = "1.0.0",
	url = ""
}

public void TF2CA_DispenserStartHealing(int builder, int building, int patient)
{
    if (builder == -1)
	{
		return;
	}

    if (TF2CA_BuilderHasCustomDispenser(builder, ATTR_AMP))
	{
        if (patient != -1)
        {
            TF2_AddCondition(patient, TFCond_Buffed, TFCondDuration_Infinite, builder);
        }
    }
}

public void TF2CA_DispenserStopHealing(int builder, int building, int patient)
{
    if (patient != -1 && builder != -1)
    {
        if (TF2_IsPlayerInCondition(patient, TFCond_Buffed) 
                && TF2Util_GetPlayerConditionProvider(patient, TFCond_Buffed) == builder)
        {
            TF2_RemoveCondition(patient, TFCond_Buffed);
        }
    }
}