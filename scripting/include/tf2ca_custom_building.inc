/** Double-include prevention */
#if defined _tf2ca_custom_building_included_
  #endinput
#endif
#define _tf2ca_custom_building_included_

/////////////////////////////
// Native                  //
/////////////////////////////

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

public SharedPlugin __pl_tf2ca_custom_building = {
	name = "tf2ca_custom_building",
	file = "tf2ca_custom_building.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};