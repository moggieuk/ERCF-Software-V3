*This readme is work in progress...*
# ERCF-Software-V3 "Angry Hare"
I love my ERCF and building it was the most fun I've had in many years of the 3D-printing hobby. Whilst the design is brilliant I found a few problems with the software and wanted to add some features and improve user friendliness.  This became especially true after the separation of functionality with the introduction of the "sensorless" branch. I liked the new python implementation as a Klipper plug-in but wanted to leverage my (very reliable) toolhead sensor.  So I rewrote the software behind ERCF - it still has the structure and much of the code of the original but significantly it has many new features, integrates the toolhead sensor and sensorless options.  I'm calling it the **"Angry Hare"** release or v3.

## Major new features:
<ul>
<li>Support all options for both toolhead sensor based loading/unloading and sensorless filament homing (with no toolhead sensor)
<li>Supports sync load and unloading steps, including a config with toolhead sensor that can work with FLEX materials!
  <li>Fully implements *“EndlessSpool”* with new concept of Tool --> Gate mapping.  This allows empty gates to be identified and tool changes subsequent to runout to use the correct filament spool.  It has the added advantage for being able to map gates to tools in case of slicing to spool loading mismatch.
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
<li>Vastly increased error detection/checking.
<l1>Consistent handling of errors. E.g. use exceptions to avoid multiple calls to _pause()
<li>Wrapping of all stepper movements to facilitate “DEVELOPER” logging level and easier debugging
<li>Renewed load and unload sequences (to support all build configurations) and effectively combine the sensor and sensorless logic
</ul>
 
## Summary of new commands:
  | Commmand | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_STATUS | Report on ERCF state, cababilities and Tool-to-Gate map | DETAIL=\[0\|\1] Forces TTG map display even if EndlessSpool is not configured |
  | ERCF_TEST_CONFIG | Dump / Change essential load/unload config options at runtime | Many. Best to run ERCF_TEST_CONFIG without options to report all parameters than can be specified |
  | ERCF_DISPLAY_TTG_MAP | Displays the current Tool -> Gate mapping (can be used all the time but generally designed for EndlessSpool  | DETAIL=\[0 \| 1\] Whether to also show the tool --> gate mapping |
  | ERCF_REMAP_TTG | Reconfiguration of the Tool - to - Gate (TTG) map.  Can also set gates as empty! | TOOL=\[0..n\] <br>GATE=\[0..n\] Maps specified tool to this gate (multiple tools can point to same gate) <br>AVAILABLE=\[0\|1\]  Marks gate as available or empty |
  | ERCF_SELECT_BYPASS | Unload and select the bypass selector position if configured | None |
  | ERCF_LOAD_BYPASS | Does the extruder loading part of the load sequence - designed for bypass filament loading | None |
  | ERCF_TEST_HOME_TO_EXTRUDER | For calibrating extruder homing - TMC current setting, etc. | Return=\[0\|1\] Whether to return the filament to the approximate starting position after homing - good for repeated testing |
  
  Note that some existing comments have been enhanced.  See the [complete set of commands](#command_summary) here.
  
## New features in detail:
### Config Loading and Unload sequences explained
Note that if a toolhead sensor is configured it will become the default filament homing method and home to extruder an optional but unecessary step. Also note the home to extruder step will always be performed during calibration of tool 0 (to accurately set `ercf_calib_ref`) regardless of the `home_to_extruder` setting. For accurate homing and to avoid grinding, tune the gear stepper current reduction `extruder_homing_current` as a % of the default run current.

#### Possible loading options with toolhead sensor:
<i>Obviously the actual distances shown below may be customized</i>

    Extruder homing config          Toolhead homing config     Notes
    ----------------------          ----------------------     -----
    
    1. home_to_extruder=0           toolhead_homing_max=20     This is probably the BEST option and can work with FLEX
                                    toolhead_homing_step=1     Filament can load close to extruder gear, then is pulled
                                    sync_load_length=1         through to home on toolhead sensor by synchronized gear
                                                               and extruder motors
    
    2. home_to_extruder=0           toolhead_homing_max=20     Not recommended but can avoid problems with sync move.  The
                                    toolhead_homing_step=1     initial load to end of bowden must press the filament to
                                    sync_load_length=0         create spring so that extruder will pick up the filament
    
    3. home_to_extruder=1           toolhead_homing_max=20     Not recommended. The filament will be rammed against extruder
       extruder_homing_max=50       toolhead_homing_step=1     to home and then synchronously pulled through to home again on
       extruder_homing_step=2       sync_load_length=1         toolhead sensor (no more than 20mm away in this example)
       extruder_homing_current=50
    
    4. home_to_extruder=1           toolhead_homing_max=20     A bit redundant to home twice but allows for reliable filament
       extruder_homing_max=50       toolhead_homing_step=1     pickup by extruder, accurate toolhead homing and avoids 
       extruder_homing_step=2       sync_load_length=0         problem problems with sync move (Timer too close)
       extruder_homing_current=50

#### Possible loading options without toolhead sensor:
    5. home_to_extruder=1          sync_load_length=10         BEST option without a toolhead sensor.  Filament is homed to
       extruder_homing_max=50                                  extruder gear and then the initial move into the extruder is
       extruder_homing_step=2                                  synchronised for accurate pickup
       extruder_homing_current=50
  
    6. home_to_extruder=1          sync_load_length=0          Same as above but avoids the synchronous move.  Can be
       extruder_homing_max=50                                  reliable with accurate calibration reference length and
       extruder_homing_step=2                                  accurate encoder
       extruder_homing_current=50

*Obviously the actual distances shown above may be customized*
  
  **Advanced options**
When not using synchronous load move the spring tension in the filament held by servo will be leverage to help feed the filament into the extruder. This is controlled with the `delay_servo_release` setting. It defaults to 2mm and is unlikely that it will need to be altered. An option to home to the extruder using stallguard `homing_method=1` is avaiable but not recommended: (i) it is not necessary with current reduction, (ii) it is not readily compatible with EASY-BRD and (iii) is currently incompatible with sensorless selector homing which hijacks the gear endstop configuration.
  
  **Note about post homing distance**
Regardless of loading settings above it is important to accurately set `home_to_nozzle` distance.  If you are not homing to the toolhead sensor this will be from the extruder entrance to nozzle.  If you are hoing to toolhead sensor, this will be the (smaller) distance from sensor to nozzle.  For example in my setup of Revo & Clockwork 2, the distance is 72mm or 62mm respectively.
  
#### Possible unloading options:
This is much simplier than loading. The toolhead sensor, if installed, will automatically be leveraged as a checkpoint when extracting from the extruder.
`sync_unload_length` controls the mm of synchronized movement at start of bowden unloading.  This can make unloading more reliable and will act as what Ette refers to as a "hair pulling" step on unload.  This is an optional step, set to 0 to disable.
  
### Tool-to-Gate (TTG) mapping and EndlessSpool application
When changing a tool with the `Tx` command ERCF would by default select the filament at the gate (spool) of the same number.  The mapping built into this *Angry Hare* driver allows you to modify that.  There are 3 primarly use cases for this feature:
<ol>
  <li>You have loaded your filaments differently than you sliced gcode file. No problem, just issue the appropriate remapping commands prior to printing
  <li>Some of "tools" don't have filament and you want to mark them as empty
  <li>Most importantly, for EndlessSpool - when a filament runs out on one gate (spool) then next in the sequence is automatically mapped to the original tool.  It will therefore continue to print on subsequent tool changes.  You can also replace the spool and update the map to indicate avaiablity mid print
</ol>

*Note that the initial availability of filament at each gate can also be specfied in the `ercf_parameters.cfg` file by updating the `gate_status` list. E.g.
>gate_status = 1, 1, 0, 0, 1, 0, 0, 0, 1

  on a 9-gate ERCF would mark gates 2, 3, 5, 6 & 7 as empty
 
To view the current mapping you can use either `ERCF_STATUS DETAIL=1` or `ERCF_DISPLAY_TTG_MAP`
  
![ERCF_STATUS](ercf_status.png "ERCF_STATUS")
  
### Visualization of filament position
  The `log_visual` setting turns on an off the addition of a filament tracking visualization. Can be nice with log_level of 0 on when functioning setup.
  
![Bling is always better](visual_filament.png "Visual Filament Location")
  
### Filament bypass
TODO

### Adjusting configuration at runtime
  All the essential configuration and tuning parameters can be modified at runtime without restarting Klipper. Use the `ERCF_TEST_CONFIG` command to do this
  
  <img src="doc/ercf_test_config.png" width="500" alt="ERCF_TEST_CONFIG">
  
  Any of the displayed config settings can be modifed.  E.g.
  > ERCF_TEST_CONFIG home_position_to_nozzle=45
  
## Full set of ERCF Commands:
  | Commmand | Description | Parameters |
  | -------- | ----------- | ---------- |
  | TODO | TODO | TODO |
  
