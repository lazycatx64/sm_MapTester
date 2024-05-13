Sourcemod Map Tester
=====

Just got hundreds of new maps for your source dedicated server, but some of them crashes your server and you don't have time to test them manually one by one?

This plugin shall help you go through all those maps

Note
-----

* It is recommended that at `least one player` stay in the server during the test. Some crashy maps require players to enter the game to trigger additional crash.

* You might need a good server restarter that can detect `server heartbeats`, in case server `frozen` or popped a `engine error window` on some map, that would cause a normal restarter (batch scripts) could not restart the server properly, it commonly happened in old maps.
![Engine Error](https://github.com/lazycatx64/sm_MapTester/blob/47b51fdfc4aedcaf7d2f61d3ec601d1b47e2e019/engineerror.png)
* Currently only tested in HL2DM server, but in theory it is applicable to all source servers that runs SourceMod.

Configs
-----

There's `/cfg/lm_maptester.cfg` included for default ConVars so you can config everything there.

* `lm_maptester_enabled`
  * To enable/disable the Tester.
  * Default: 0
* `lm_maptester_changetime`
  * After map loaded, X seconds later will go next map
  * Default: 3 (should keep it long enough to wait for player fully loaded into map)
* `lm_maptester_maplist`
  * Decides where we get map list from
  * Default: 0
  * 0 = Search in `maps` folder
  * 1 = Uses built-in ConVar `mapcyclefile` value which default is: `mapcycle.txt`
    * Will try to search this map list: `cfg/mapcycle.txt`
    * Will try default list instead of not found: `cfg/mapcycle_default.txt`
  * Any other path to a list file
    * example: `cfg/rtv.cfg`
      * Will try to search this map list: `cfg/rtv.cfg`
    * or: `cfg/my_new_map_list.txt`
      * Will try to search this map list: `cfg/my_new_map_list.txt`

Results
-----

* Good maps that loaded successfully will be logged to here
  * `addons/sourcemod/data/maptester/good.txt`
* Bad maps that crashed during loading will be logged to here next time server starts
  * `addons/sourcemod/data/maptester/bad.txt`

More features?
-----

More features may/might/possibly will (or not) be added in the future.
