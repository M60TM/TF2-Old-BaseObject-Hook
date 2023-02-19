# TF2CA-Custom-Building
A few forwards, natives, custom attributes for custom building.

## Features
- Automatically detonate a building when the current custom building type is different from the custom building type of the builder

## Dependency
- sourcemod 1.11+
- [TFCustAttr](https://github.com/nosoop/SM-TFCustAttr)
- [TF2Utils](https://github.com/nosoop/SM-TFUtils)
- [stocksoup (compile only)](https://github.com/nosoop/stocksoup)

## Also Support
- [Custom Weapon X](https://github.com/nosoop/SM-TFCustomWeaponsX)

## Usage
```
#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#include <tf_custom_attributes>
#include <tf2ca_custom_building>

#define ATTR_TEST "build test"

public void TF2CA_OnBuildObject(int builder, int building, TFObjectType buildingtype)
{
	if (builder == -1)
	{
		return;
	}
	
	if (buildingtype != TFObject_Teleporter)
	{
		return;
	}

	if (TF2CA_BuilderHasCustomTeleporter(builder, ATTR_TEST))
	{
		DoSomething(builder, building);
	}
}
```

## Natives
```
native bool TF2CA_BuilderHasCustomDispenser(int client, const char[] value);
```
```
native bool TF2CA_BuilderHasCustomSentry(int client, const char[] value);
```
```
native bool TF2CA_BuilderHasCustomTeleporter(int client, const char[] value);
```
```
native void TF2CA_DetonateObjectOfType(int client, int type, int mode = 0, bool silent = false);
```
```
native int TF2CA_PlayerGetObjectOfType(int owner, int objectType, int objectMode);
```
```
native void TF2CA_DestroyScreens(int building);
```

----

## Building

This project is configured for building via [Ninja][]; see `BUILD.md` for detailed
instructions on how to build it.

If you'd like to use the build system for your own projects,
[the template is available here](https://github.com/nosoop/NinjaBuild-SMPlugin).

[Ninja]: https://ninja-build.org/
