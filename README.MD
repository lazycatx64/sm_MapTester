# Sourcemod MapTester

Just got hundreds of new maps added to your source dedicated server, but some of them crashes your server and you don't have time to change map manually and write down the results one by one?

This plugin shall help you go through all those maps

_I currently only tested in HL2DM server, but in theory it should work on all source games that runs SourceMod since it does not touch game data or assets._

## Optional but recommended

* You may need a good server restarter like [Serverdoc](https://www.serverdoc.com) that can check ***server queries*** to see if the server is running as it should, why?
  * Sometimes the server will ***freeze*** during loading maps.
  * Sometimes the server will pop a ***Engine Error dialog*** during loading maps.\
    ![Engine Error](/engineerror.png)
  * Both of these won't really crash the server process but makes it stuck, and a normal batch server restarter wouldn't know that.
  * If you don't get a restarter that checks queries, you gonna have to stay in front of the computer to see if server stucked and restart server manually.\
    ![Serverdoc window](/serverdoc.png)
* It is recommended that should be ***one player*** stay in the server during the test, because some crashy maps require players stay inside the game to trigger additional crash.
  * If you do, set `lm_maptester_waitplayer` to `1` to wait for player completly loaded the map and spawned in the world, but you gonna join the server manually if server crashed/restarted.

## Configs

There's `/cfg/sourcemod/lm_maptester.cfg` included for default ConVars so you can config everything there, modify the settings and restart the server.

* `lm_maptester_enabled`
  * To enable/disable the Tester.
  * Default: 1
* `lm_maptester_waitplayer`
  * Set 1 to wait for first player complete loaded into map, then we change map.
  * Default: 0
* `lm_maptester_changetime`
  * After map loaded, X seconds later will go next map
  * Default: 3
* `lm_maptester_maplist`
  * Decides where we get map list from
  * Default: 0
  * 0 = Get every map.bsp in `/maps/` folder (Recommended and easiest)
  * 1 = Uses built-in ConVar `mapcyclefile` value which default is: `mapcycle.txt`
    * Will try to search this map list: `/cfg/mapcycle.txt`
    * If not found, will try default list: `/cfg/mapcycle_default.txt`
  * Path = Any other path to a list file
    * example 1: set it `cfg/rtv.cfg` will try to search : `/cfg/rtv.cfg`
    * example 2: set it `listmaps.txt` will try to search : `/listmaps.txt`

## How to use it?

1. (Optional) Get the [Serverdoc](https://www.serverdoc.com) or similar tool.
1. Download the plugin, put `lm_maptester.smx` to `/addons/sourcemod/plugins/` (or if you like to compile your own)
1. Start and join the server.
1. Set `lm_maptester_enabled` to `1` to start the test if haven't.
1. Get a cup of coffee ☕
1. Check `good.txt` `crash.txt` `missing.txt` for the result and move them somewhere else.

## What to expect?

### Good Maps
* Good maps that loaded successfully without crashing server.
* These maps will be logged to here:\
  `/addons/sourcemod/data/maptester/good.txt`
* Then MapTester will proceed to next map.

### Crashy Maps
* Crashy maps that crashed server process during map loading.
* Other maps that freezes server or causes engine errors.
* Server restarter should restart the server when that happened.
* These maps will be logged to here at next time server starts:\
  `/addons/sourcemod/data/maptester/crash.txt`
* MapTester should start from where it left.

### Missing Maps
* Maps that missing when player tries to join.
* These maps will be logged to here next time server starts:\
  `/addons/sourcemod/data/maptester/missing.txt`
* MapTester should proceed to next map automatically.

More features?
-----

More features may/perhaps/possibly will (or not) be added in the future.
