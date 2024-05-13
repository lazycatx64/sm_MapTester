Sourcemod Map Tester
=====

Just got hundred of new maps for your source dedicated server, but some of them are crashing your server, and you got no time to test them all one by one?

This plugin shall help you go through all those maps

What can it do?
-----

* ConVar to enable the Tester.
* Auto change map every few seconds after map loaded. (Configable ConVar)
* Can get map list from:
  * Search in `maps` folder (default)
  * Built-in ConVar `mapcyclefile` default: `mapcycle.txt`
    * located in: `cfg/mapcycle.txt`
  * Any other path to a list file
    * example: `cfg/rtv.cfg`
    * or: `cfg/my_new_map_list.txt`

Results
-----

* Good maps that loaded sucessfully will be logged to
  * `addons/sourcemod/data/maptester/good.txt`
* Bad maps that crashed during loading will be logged to
  * `addons/sourcemod/data/maptester/bad.txt`
* More feature may/might/possibly will be added in future

Note
-----

You might need a good server restarter that can detect `server heartbeats`, in case server `frozen` or popped a `engine error window` on some map, that would cause a normal restarter (batch scripts) could not restart the server properly, it commonly happened in old maps.
