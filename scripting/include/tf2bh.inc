/** Double-include prevention */
#if defined _tf2bh_included_
  #endinput
#endif
#define _tf2bh_included_

#include <tf2_stocks>

/////////////////////////////
// Define                  //
/////////////////////////////

#define SENTRY_BLUEPRINT_MODEL "models/buildables/sentry1_blueprint.mdl"
#define SENTRY_LV1_MODEL	   "models/buildables/sentry1.mdl"
#define SENTRY_LV1_HEAVY_MODEL "models/buildables/sentry1_heavy.mdl"
#define SENTRY_LV2_MODEL	   "models/buildables/sentry2.mdl"
#define SENTRY_LV2_HEAVY_MODEL "models/buildables/sentry2_heavy.mdl"
#define SENTRY_LV3_MODEL	   "models/buildables/sentry3.mdl"
#define SENTRY_LV3_HEAVY_MODEL "models/buildables/sentry3_heavy.mdl"

#define DISPENSER_BLUEPRINT_MODEL "models/buildables/dispenser_blueprint.mdl"
#define DISPENSER_LV1_LIGHT_MODEL "models/buildables/dispenser_light.mdl"
#define DISPENSER_LV1_MODEL		  "models/buildables/dispenser.mdl"
#define DISPENSER_LV2_LIGHT_MODEL "models/buildables/dispenser_lvl2_light.mdl"
#define DISPENSER_LV2_MODEL		  "models/buildables/dispenser_lvl2.mdl"
#define DISPENSER_LV3_LIGHT_MODEL "models/buildables/dispenser_lvl3_light.mdl"
#define DISPENSER_LV3_MODEL		  "models/buildables/dispenser_lvl3.mdl"

#define TELEPORTER_BLUEPRINT_ENTER_MODEL "models/buildables/teleporter_blueprint_enter.mdl"
#define TELEPORTER_BLUEPRINT_EXIT_MODEL	 "models/buildables/teleporter_blueprint_exit.mdl"
#define TELEPORTER_LIGHT_MODEL			 "models/buildables/teleporter_light.mdl"
#define TELEPORTER_MODEL				 "models/buildables/teleporter.mdl"

/////////////////////////////
// Native                  //
/////////////////////////////

/**
 * Detonate spectific buildings belonging to a player.
 * 
 * @param client     Player to check against.
 * @param type       Type of building to destroy.
 * @param mode       Mode of building to destroy.
 * @param force      Force to destroy buildings. If true, this skips the sapper / plasma disabled checks.
 * @noreturn         
 * 
 * @error            Invalid client index.
 */
native void TF2BH_PlayerDetonateObjectOfType(int client, int type, int mode = 0, bool force = false);

/**
 * Get player's spectific object.
 * 
 * @param client         Client index to check.
 * @param objectType     Type of object to find.
 * @param objectMode     Mode of object to find.
 * @return               Return client's object.
 * 
 * @error                Invalid client index.
 */
native int TF2BH_PlayerGetObjectOfType(int client, int objectType, int objectMode);

/**
 * Destroy object's screen.
 * 
 * @param building     Object index to destroy screen.
 * @noreturn           
 */
native void TF2BH_ObjectDestroyScreens(int building);

/**
 * Remove All Objects of spectific client.
 * 
 * @param client      Client index to remove it's own objects.
 * @param explode     Explode object instead remove.
 * @noreturn          
 * 
 * @error             Invalid client index.
 */
native void TF2BH_PlayerRemoveAllObjects(int client, bool explode);

/////////////////////////////
// Forward                 //
/////////////////////////////

/**
 * Called when object go active.
 * 
 * @param builder				object builder.
 * @param building				object's index.
 * @param type					object's type.
 */
forward void TF2BH_ObjectOnGoActive(int builder, int building, TFObjectType type);

/**
 * Called when object start upgrade.
 * 
 * @param builder				object builder.
 * @param building				object's index.
 * @param type					object's type.
 */
forward void TF2BH_ObjectStartUpgrading(int builder, int building, TFObjectType type);

/**
 * Called when object finish upgrade.
 * 
 * @param builder				object builder.
 * @param building				object's index.
 * @param type					object's type.
 */
forward void TF2BH_ObjectFinishUpgrading(int builder, int building, TFObjectType type);

/**
 * Called when object get max health for current level.
 * 
 * @param builder       Object builder index.
 * @param building      Object entity index.
 * @param type          Object type.
 * @param maxHealth     Object max health.
 * @return              Plugin_Changed to use your maxHealth value.
 */
forward Action TF2BH_ObjectGetMaxHealth(int builder, int building, TFObjectType type, int &maxHealth);

/**
 * Called when sentrygun find model for current state.
 * 
 * @param builder       Sentrygun builder index.
 * @param sentry        Sentrygun entity index.
 * @param modelName     Model path.
 * @return              Plugin_Changed to change model path.
 */
forward Action TF2BH_SentrygunSetModel(int builder, int sentry, char modelName[128]);

/**
 * Called when dispenser find model for current state.
 * 
 * @param builder       Dispenser builder index.
 * @param dispenser     Dispenser entity index.
 * @param modelName     Model path.
 * @return              Plugin_Changed to change model path.
 */
forward Action TF2BH_DispenserSetModel(int builder, int dispenser, char modelName[128]);

/**
 * Called when teleporter find model for current state.
 * 
 * @param builder        Teleporter builder index.
 * @param teleporter     Teleporter entity index.
 * @param modelName      Model path.
 * @return               Plugin_Changed to change model path.
 */
forward Action TF2BH_TeleporterSetModel(int builder, int teleporter, char modelName[128]);

/**
 * Called when dispenser start healing to patient.
 * 
 * @param builder      Dispenser builder index.
 * @param building     Dispenser entity index.
 * @param patient      Patient index.
 * @noreturn           
 */
forward void TF2BH_DispenserStartHealing(int builder, int building, int patient);

/**
 * Called when dispenser get healrate.
 * 
 * @param builder       Dispenser builder index.
 * @param dispenser     Dispenser entity index.
 * @param healrate      Healrate.
 * @return              Plugin_Changed to use your healrate value.
 */
forward Action TF2BH_DispenserGetHealRate(int builder, int dispenser, float &healrate);

/**
 * Called when dispenser stop healing to patient.
 * 
 * @param builder      Dispenser builder index.
 * @param building     Dispenser entity index.
 * @param patient      Patient index.
 * @noreturn           
 */
forward void TF2BH_DispenserStopHealingPost(int builder, int building, int patient);

/**
 * Called when player calculate object cost.
 * 
 * @note It doesn't affect to PDA. PDA's HUD is client side.
 * 
 * @param client      Client index.
 * @param type        Object type.
 * @param cost        Object cost.
 * @return            Plugin_Changed to use your cost value.
 */
forward Action TF2BH_PlayerCalculateObjectCost(int client, TFObjectType type, int &cost);

/**
 * Called when object get construction multiplier.
 * 
 * @param builder        Object builder index.
 * @param building       Object entity index.
 * @param type           Object type.
 * @param multiplier     Construction multiplier.
 * @return               Plugin_Changed to use your multiplier value.
 */
forward Action TF2BH_ObjectGetConstructionMultiplier(int builder, int building, TFObjectType type, float &multiplier);

/**
 * Called when dispenser consider patient is heal target.
 * Return Plugin_Continue to let the original calculation or return a higher
 * action to override the decision with the value of 'result'
 * 
 * @param builder       Builder index.
 * @param dispenser     Dispenser entity index.
 * @param patient       Patient index.
 * @param result        True to pass, false to block.
 * @return              Plugin_Continue for original calculation, higher value to use 'result'.
 */
forward Action TF2BH_DispenserCouldHealTarget(int builder, int dispenser, int patient, bool &result);

public SharedPlugin __pl_tf2bh = {
	name = "tf2bh",
	file = "tf2bh.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
