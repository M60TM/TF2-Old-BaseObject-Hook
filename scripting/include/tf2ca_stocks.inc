/** Double-include prevention */
#if defined _tf2ca_stocks_included_
  #endinput
#endif
#define _tf2ca_stocks_included_

#include <sdktools>
#include <tf_custom_attributes>

stock bool TF2CustAttr_ClientHasString(int client, const char[] check, char[] attr, int maxlength)
{
    for(int i = 0; i < 5; i++)
    {
        int weapon = GetPlayerWeaponSlot(client, i);
        if(IsValidEntity(weapon))
        {        
            if(TF2CustAttr_GetString(weapon, check, attr, maxlength))
            {
                return true;
            }
        }
    }

    return false;
}

stock float TF2CustAttr_HookValueFloatOnClient(float flInitial, const char[] customAttr, int entity, float defaultValue = 1.0)
{
    for(int i = 0; i < 5; i++)
    {
        int weapon = GetPlayerWeaponSlot(entity, i);
        if(IsValidEntity(weapon))
        {
            if(TF2CustAttr_GetFloat(weapon, customAttr, defaultValue) >= 0.0)
            {
                flInitial *= TF2CustAttr_GetFloat(weapon, customAttr, defaultValue);
            }
        }
    }
    
    return flInitial;
}

stock int TF2CustAttr_HookValueIntOR(int client, const char[] customAttr)
{
	int value = TF2CustAttr_GetInt(client, customAttr);
	for (int i = 0; i < 5; i++) {
		int weapon = GetPlayerWeaponSlot(client, i);
		if (IsValidEntity(weapon))
        {
            value |= TF2CustAttr_GetInt(weapon, customAttr);
        }
	}

	return value;
}