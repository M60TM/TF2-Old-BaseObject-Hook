/** Double-include prevention */
#if defined _tf2ca_custom_building_included_
  #endinput
#endif
#define _tf2ca_custom_building_included_

#include <tf2_stocks>

/**
 * Check if the player has the same value as the entered value.
 * 
 * @param value		The value you want to check.
 * @return          True if the player has the same value as the entered value, false otherwise.
 */
native bool TF2CA_BuilderHasCustomDispenser(int client, const char[] value);

/**
 * Check if the player has the same value as the entered value.
 * 
 * @param value		The value you want to check.
 * @return          True if the player has the same value as the entered value, false otherwise.
 */
native bool TF2CA_BuilderHasCustomSentry(int client, const char[] value);

/**
 * Check if the player has the same value as the entered value.
 * 
 * @param value		The value you want to check.
 * @return          True if the player has the same value as the entered value, false otherwise.
 */
native bool TF2CA_BuilderHasCustomTeleporter(int client, const char[] value);

/**
 * Detonate all buildings belonging to a player
 * 
 * @param client     Player to check against.
 * @param type       Type of building to destroy.
 * @param mode       Mode of building to destroy.
 * @param silent     Destroy buildings silently.
 */
native void TF2CA_DetonateObjectOfType(int client, int type, int mode = 0, bool silent = false);

/**
 * Get player's spectific object.
 * 
 * @param owner			Player to check against.
 * @param objectType	Type of building to find.
 * @param objectMode	Mode of building to find.
 */
native int TF2CA_PlayerGetObjectOfType(int owner, int objectType, int objectMode);

/**
 * Destroy building(dispenser..)'s screen.
 * 
 * @param building     Building index to destroy screen.
 */
native void TF2CA_DestroyScreens(int building);

/**
 * Called When player build an object.
 * 
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_OnBuildObject(int builder, int building, TFObjectType buildingtype);

/**
 * Called When player upgrade an object.
 * 
 * @param upgrader				object upgrader.
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_OnUpgradeObject(int upgrader, int builder, int building, TFObjectType buildingtype);

/**
 * Called When player carry an object.
 * 
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_OnCarryObject(int builder, int building, TFObjectType buildingtype);

/**
 * Called When player drop an object.
 * 
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_OnDropObject(int builder, int building, TFObjectType buildingtype);

/**
 * Called When object is removed.
 * 
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_OnObjectRemoved(int builder, int building, TFObjectType buildingtype);

/**
 * Called When object is destroyed.
 * 
 * @param builder		    	object builder.
 * @param attacker		  		object destoryer.
 * @param assister      		assister of destroying object.
 * @param weapon        		weapon was used to destroy object. 
 * @param building      		object's index.
 * @param buildingtype  		object's type.
 * @param wasbuilding   		check object was building when destroyed.
 */
forward void TF2CA_OnObjectDestroyed(int builder, int attacker, int assister, int weapon, 
			int building, TFObjectType buildingtype, bool wasbuilding);

/**
 * Called When object is removed.
 * 
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_OnObjectDetonated(int builder, int building, TFObjectType buildingtype);

/**
 * Called When object go active.
 * 
 * @param builder				object builder.
 * @param building  			object's index.
 * @param buildingtype  		object's type.
 */
forward void TF2CA_ObjectOnGoActive(int builder, int building, TFObjectType buildingtype);

/**
 * Called When dispenser start healing.
 * 
 * @param builder
 * @param building
 * @param patient
 */
forward void TF2CA_DispenserStartHealing(int builder, int building, int patient);

/**
 * Called When dispenser stop healing.
 * 
 * @param builder
 * @param building
 * @param patient
 */
forward void TF2CA_DispenserStopHealing(int builder, int building, int patient);

public SharedPlugin __pl_tf2ca_custom_building = {
	name = "tf2ca_custom_building",
	file = "tf2ca_custom_building.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
