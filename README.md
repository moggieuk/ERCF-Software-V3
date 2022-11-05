# ERCF-Software-V3
I love my ERCF and building it was the most fun I've had in many years of the 3D-printing hobby. Whilst the design is brilliant I found a few problems with the software and wanted to add some features and improve user friendliness.  This became especially true after the separation of functionality with the introduction of the "sensorless" branch. I liked the new python implementation as a Klipper plug-in but wanted to leverage my (very reliable) toolhead sensor.  So I rewrote the software behind ERCF - it still has the structure and much of the code of the original but significantly it has many new features, integrates the toolhead sensor and sensorless options.  I'm calling it the **"Angry Rabbit"** release or v3.

## Major new features:
<ul>
<li>Support all options for both toolhead sensor base loading/unloading and sensorless
<li>Supports sync load and unloading steps in sequence, including a config with toolhead sensor that can work with FLEX materials!
<li>Fully implements “EndlessSpool” with concept of Tool -> Gate mapping.  This allows empty gates to be identified and tool changes subsequent to runout to use the correct filament spool.  It has the added (advanced) advantage for being able to map gates to tools in case of slicing to spool loading mismatch
<li>Measures “spring” after extruder homing and leverages to more accurate calibration reference and, with servo release delay, making the gear to extruder transition more reliable.
<li>Formal support for the filament bypass block… new commands and state if using it.
<li>Ability to reduce gear current (currently TMC2209 only) during “collision” homing procedure to prevent grinding, etc.
<li>and toolhead sensor options, including stallguard filament homing (if user is not using EASY-BRD/sensorless selector homing)
</ul>

## Other features:
<ul>
<li>Optional fun visual representation of loading and unloading sequence
<li>Averaging of the calibration reference length (on T0) and compensation based on spring in filament (related to ID and length of bowden) and chosen configuration options.
<li>Runtime “test” command (ERCF_TEST_CONFIG) to set key parameters used in loading and unload sequences whilst calibrating to avoid constant Klipper restarts
<li>Workarond to many of the ways to provoke Klipper “Timer too close” errors (although there is definitely a bug in the Klipper firmware) – at least I’m not having any problems with EASY-BRD, long single load moves, and extensive use of synchronized gear and extruder movement.
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
