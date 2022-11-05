# ERCF-Software-V3
I love my ERCF and building it was the most fun I've had in many years of the 3D-printing hobby. Whilst the design is brilliant I found a few problems with the software and wanted to add some features and improve user friendliness.  This became especially true after the separation of functionality with the introduction of the "sensorless" branch. I liked the new python implementation as a Klipper plug-in but wanted to leverage my (very reliable) toolhead sensor.  So I rewrote the software behind ERCF - it still has the structure and much of the code of the original but significantly it has many new features, integrates the toolhead sensor and sensorless options.  I'm calling it the **"Angry Rabbit"** release or v3.

## Major new features:
<ul>
<li>Support all options for both toolhead sensor based loading/unloading and sensorless filament homing (with no toolhead sensor)
<li>Supports sync load and unloading steps, including a config with toolhead sensor that can work with FLEX materials!
<li>Fully implements _“EndlessSpool”_ with new concept of Tool -> Gate mapping.  This allows empty gates to be identified and tool changes subsequent to runout to use the correct filament spool.  It has the added advantage for being able to map gates to tools in case of slicing to spool loading mismatch.
<li>Measures “spring” after extruder homing for more accurate calibration reference
<li>Adds servo_up delay making the gear to extruder transition of filament more reliable (maintains pressure)
<li>Ability to secify empty or disabled tools (gates).
<li>Formal support for the filament bypass block with associated new commands and state if using it.
<li>Ability to reduce gear current (currently TMC2209 only) during “collision” homing procedure to prevent grinding, etc.
</ul>

## Other features:
<ul>
<li>Optional fun visual representation of loading and unloading sequence
<li>Reworks calibration routines that can average measurements, add compensation based on spring in filament (related to ID and length of bowden), and considers configuration options.
<li>Runtime configuration via new command (ERCF_TEST_CONFIG) for most options which avoids constantly restarting klipper or recalibrating during setup
<li>Workarond to some of the ways to provoke Klipper “Timer too close” errors (although there are definitely bugs in the Klipper firmware)
<li>More reliable “in-print” detection so tool change command “Tx” g-code can be used anytime and the user does not need to resort to “ERCF_CHANGE_TOOL_STANDALONE”
<li>Runtime configuration of most options which avoids constantly restarting klipper or recalibrating during setup
<li>New LOG_LEVEL=4 for developer use.  BTW This is useful in seeing the exact stepper movements
<li>Experimental logic to use stallguard filament homing (Caveat: not easy to setup using EASY-BRD and not compatible with sensorless selector homing option)
</ul>
  
## Other benefites of the code cleanup / rewrite:
<ul>
<li>Vastly increased error detection/checking
<l1>Consistent error handling. E.g. use exceptions to avoid multiple calls to _pause()
<li>Wrapping of all stepper movements to facilitate “DEVELOPER” logging level and easier debugging
<li>Renewed load and unload sequences (to support all build configurations) and effectively combine the sensor and sensorless logic
<li>Vastly increased error detection/checking
</ul>
 
## Summary of new commands:
  | Commmand | Description |
  | --- | ----------- |
  | ERCF_STATUS | Report on state and essential configuration options (see some examples below) |
  | ERCF_TEST_CONFIG | Dump / Change essential load/unload config options at runtime |
  | ERCF_DISPLAY_TTG_MAP | Displays the current Tool -> Gate mapping (can be used all the time but generally designed for EndlessSpool  |
  | ERCF_REMAP_TTG | Reconfiguration of the Tool - to - Gate (TTG) map.  Can also set gates as empty! |
  | ERCF_SELECT_BYPASS | Unload and select the bypass selector position if configured |
  | ERCF_LOAD_BYPASS | Does the extruder loading part of the load sequence - designed for bypass filament loading |
  | ERCF_TEST_HOME_TO_EXTRUDER | For calibrating extruder homing - TMC current setting, etc. |
  
![The San Juan Mountains are beautiful!](/assets/images/san-juan-mountains.jpg "San Juan Mountains")
