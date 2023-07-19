# TF2-BaseObject-Hook
Forwards and Natives for handling object.

## Dependency
- sourcemod 1.11+
- [stocksoup (compile only)](https://github.com/nosoop/stocksoup)

# TF2CA-Custom-Building
Provide some custom attributes based on TF2-BaseObject-Hook.

## Dependency
- sourcemod 1.11+
- [TFCustAttr](https://github.com/nosoop/SM-TFCustAttr)
- [TF2Utils](https://github.com/nosoop/SM-TFUtils)
- [stocksoup (compile only)](https://github.com/nosoop/stocksoup)

## Usage
```
#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#include <tf_custom_attributes>
#include <tf2bh>
#include <tf2ca_custom_building>

#define ATTR_TEST "build test"

public void TF2BH_OnBuildObject(int builder, int building, TFObjectType type)
{
	if (builder == -1)
	{
		return;
	}
	
	if (type != TFObject_Teleporter)
	{
		return;
	}

	if (TF2CA_BuilderHasCustomTeleporter(builder, ATTR_TEST))
	{
		DoSomething(builder, building);
	}
}
```

----

## Building

This project is configured for building via [Ninja][]; see `BUILD.md` for detailed
instructions on how to build it.

If you'd like to use the build system for your own projects,
[the template is available here](https://github.com/nosoop/NinjaBuild-SMPlugin).

[Ninja]: https://ninja-build.org/
