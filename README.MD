Sourcemod Map Tester
=====

Just got hundreds of new maps for your source dedicated server, but some of them crashes your server and you don't have time to test them manually one by one?

This plugin shall help you go through all those maps

Note
-----

* It is recommended that ***at least one player*** stay in the server during the test. Some crashy maps require players stay inside the game to trigger additional crash.

* You may need a good server restarter that can detect ***server heartbeat*** in case the server ***freezes*** or ***Engine Error dialog boxes pop up*** in some maps, this will cause the normal restarter (batch script) to not restart the server properly, this is very common in old maps, otherwise you have to stay in front of the computer to monitor whether your server need a restart.
  * ![Engine Error](/engineerror.png)
* Currently only tested in HL2DM server, but in theory it should work all source servers that runs SourceMod since it does not touch game data or assets.

Configs
-----

There's `/cfg/sourcemod/lm_maptester.cfg` included for default ConVars so you can config everything there.

* `lm_maptester_enabled`
  * To enable/disable the Tester.
  * Default: 0
* `lm_maptester_changetime`
  * After map loaded, X seconds later will go next map
  * Default: 3 (should keep it long enough to wait for player fully loaded into map)
* `lm_maptester_maplist`
  * Decides where we get map list from
  * Default: 0
  * 0 = Get every maps in `maps` folder (Recommended and easiest)
  * 1 = Uses built-in ConVar `mapcyclefile` value which default is: `mapcycle.txt`
    * Will try to search this map list: `/cfg/mapcycle.txt`
    * If not found, will try default list: `/cfg/mapcycle_default.txt`
  * Path = Any other path to a list file
    * example: `cfg/rtv.cfg` will try to search : `/cfg/rtv.cfg`
    * or: `listmaps.txt` will try to search : `/listmaps.txt`

How to use it?
-----

1. Download the plugin, put `lm_maptester.smx` to `/addons/sourcemod/plugins/` (or if you like to compile your own)
1. (Optional) Put `lm_maptester.cfg` to `/cfg/sourcemod/` and config it first if needed.
1. Start and join the server.
1. Set `lm_maptester_enabled` to `1` to start the test.
1. Get a cup of coffee ☕
1. Check the `good.txt` and `bad.txt` for the result.

Results
-----

* Good maps that loaded successfully will be logged to here
  * `/addons/sourcemod/data/maptester/good.txt`
* Bad maps that crashed during loading will be logged to here next time server starts
  * `/addons/sourcemod/data/maptester/bad.txt`

More features?
-----

More features may/perhaps/possibly will (or not) be added in the future.
