tag v2.0.0
Backported to 3.3.5a
2025-12-09

Release v2.0.0 - 3.3.5a Backport

--------------------

Changes:
	- Complete backport from retail to 3.3.5a (WotLK) client
	- Updated .toc file to interface version 30300
	- Replaced modern C_Map API calls with 3.3.5a compatible equivalents
	- Created polyfills for C_Map, C_Minimap, C_Timer, C_AddOns APIs
	- Replaced XML mixin attributes with standard Lua script handlers
	- Removed retail-specific version checks (WOW_PROJECT_ID, EditModeManagerFrame)
	- Fixed cardinal points positioning on HUD
	- TrailPath module: Fixed pins to remain static at world positions
	- TrailPath module: Corrected minimap and HUD trail positioning and scaling
	- TrailPath module: Proper clipping for pins outside visible range
	- Compatible with Project Ascension 3.3.5a private server

Technical Details:
	- Created Compat.lua with API polyfills for modern functions
	- Modified FarmHud.xml to use standard script blocks instead of mixin
	- Updated event handling for 3.3.5a event system
	- Fixed tracking mechanism for 3.3.5a API compatibility
