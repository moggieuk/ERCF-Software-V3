# ERCF-Software-V3 "Happy Hare"
I love my ERCF and building it was the most fun I've had in many years of the 3D-printing hobby. Whilst the design is brilliant I found a few problems with the software and wanted to add some features and improve user friendliness.  This became especially true after the separation of functionality with the introduction of the "sensorless filament homing" branch. I liked the new python implementation as a Klipper plug-in but wanted to leverage my (very reliable) toolhead sensor.  So I rewrote the software behind ERCF - it still has the structure and much of the code of the original but, more significantly, it has many new features, integrates the toolhead sensor and sensorless options.  I'm calling it the **"Happy Hare"** release or v3.

## Major new features:
<ul>
<li>Support all options for both toolhead sensor based loading/unloading and the newer sensorless filament homing (no toolhead sensor)
<li>Supports sync load and unloading steps moving the extruder and gear motor together, including a config with toolhead sensor that can work with FLEX materials!
  <li>Fully implements “EndlessSpool” with new concept of Tool --> Gate mapping.  This allows empty gates to be identified and tool changes subsequent to runout to use the correct filament spool.  It has the added advantage for being able to map gates to tools in case of slicing to spool loading mismatch.
<li>Vastly improved logging including a new log to file functionality. You can keep the console log to a minimum and send debugging information to `ercf.log` located in the same directory as Klipper logs
<li>Optional fun visual representation of loading and unloading sequence
<li>Ability to specify empty or disabled tools (gates).
<li>Formal support for the filament bypass block with associated new commands and state if using it.
<li>Ability to reduce gear current (currently TMC2209 only) during “collision” homing procedure to prevent grinding, etc.
<li>Convenience filament "autoload" function and check gate feature to ensure filaments are all ready before print
<li>No need to do anything custom in your existing macros
<li>Moonraker update-manager support!
</ul>

## Other features:
<ul>
<li>Reworks calibration routine to average measurements, add compensation based on spring in filament (related to ID and length of bowden), and considers configuration options.
<li>Runtime configuration via new command (ERCF_TEST_CONFIG) for most options which avoids constantly restarting klipper or recalibrating during setup
<li>Workaround to some of the ways to provoke Klipper “Timer too close” errors (although there are definitely bugs in the Klipper firmware)
<li>Measures “spring” in filament after extruder homing for more accurate calibration reference
<li>Adds servo_up delay making the gear to extruder transition of filament more reliable (maintains pressure)
<li>New "TEST" commands to help diagnose issues with encoder
<li>Logic to use stallguard filament homing (Caveat: not easy to setup using EASY-BRD and not compatible with sensorless selector homing option)
<li>The clog detection runout distance is now set based on measurements of the filament "spring" i.e. the maximum the extruder can move before encoder sees it.
</ul>
  
## Other benefits of the code rewrite:
<ul>
<li>Vastly increased error detection/checking of supplied parameters and configurations
<li>Consistent handling of errors. E.g. use exceptions to avoid multiple calls to "pause"
<li>Wrapping of all stepper movements to facilitate “DEVELOPER” logging level and easier debugging
<li>Renewed load and unload sequences (to support all build configurations) and effectively combine the sensor and sensorless logic
</ul>
 
<br>
  
## Installation
The module can be installed into an existing Klipper installation with the install script. Once installed it will be added to Moonraker update-manager to easy updates like other Klipper plugins:

    cd ~
    git clone https://github.com/moggieuk/ERCF-Software-V3.git
    cd ERCF-Software-V3

    ./install.sh -i

The `-i` option will bring up some interactive prompts to aid setting some confusing parameters (like sensorless selector homing setup). For EASY-BRD installations it will also configure all the pins for you. If not run with the `-i` flag the new template `ercf*.cfg` files will not be installed.  Note that if existing `ercf*.cfg` files are found the old versions will be moved to `<file>.00` extension instead so as not to overwrite an existing configuration (don't run twice in a row!).  If you still choose not to install the new `ercf*.cfg` files automatically be sure to examine them closely and compare to the supplied templates - some options have changed!
<br>

Note that the installer will look for Klipper install and config in standard locations.  If you have customized locations or the installer fails to find Klipper you can use the `-k` and `-c` flags to override the klipper home directory and klipper config directory respectively. Also, the install assumes a single instance of Klipper running per device.  If you have many you may need to install and configure the `ercf*.cfg` files by hand.
<br>

REMEMBER that `ercf_hardware.cfg`, `ercf_software.cfg` & `ercf_parameters.cfg` must all be referenced by your `printer.cfg` master config file.  `client_macros.cfg` should also be referenced if you don't already have working PAUSE/RESUME/CANCEL_PRINT macros (but be sure to read the section before on macro expectations). These includes can be added automatically for you with the install script.
<br>

Pro tip: If you are concerned about running `install.sh -i` then run like this: `install.sh -i -c /tmp -k /tmp` This will build the `*.cfg` files for you but put then in /tmp.  You can then read them, pull out the bits your want to augment existing install or simple see what the answers to the various questions will do...
<br>

Also be sure to read my [notes on Encoder problems](doc/ENCODER.md) - the better the encoder the better this software will work.
<br>

The configuration and setup of your ERCF using Happy Hare is 95% the same as documented in the [newer V2 Manual](https://github.com/EtteGit/EnragedRabbitProject/raw/no_toolhead_sensor/Documentation/ERCF_Manual.pdf).  Be sure to read this README and the installed 'ercf_*.cfg' to understand any differences.
  
## Revision History
<ul>
<li> v1.0.0 - Initial Beta Release
<li> v1.0.3 - Bug fixes from community: Better logging on toolchange (for manual recovery); Advanced config parameters for adjust tolerance used in 'apply_bowden_correction' move; Fixed a couple of silly (non serious) bugs
<li> v1.1.0 - New commands: ERCF_PRELOAD & ERCF_CHECK_GATES ; Automatic setting of clog detection distance in calibration routine ; New interactive install script to help EASY-BRD setup; Bug fixes
<li> v1.1.1 - Fixes for over zealous tolerance checks on bowden loading; Fix for unloading to far if apply_bowden_correction is active; new test command: ERCF_TEST_TRACKING; Fixed slicer based tool load issue
<li> v1.1.2 - Improved install.sh -i to include servo and calib bowden length; Better detection of malfunctioning toolhead sensor
<li> v1.1.3 - Added ERCF_RECOVER command to re-establish filament position after manual intervention and filament movement. Not necessary if you use ERCF commands to correct problem but useful to call prior to RESUME; Much improved install.sh to cover toolhead sensor and auto restart moonraker on first time install
<li> v1.1.4 - Change to automatic clog detection length based on community feedback
<li> v1.1.5 - Further install.sh improvements - no longer need filament_sensor defined or duplicate pin override if not using clog detection; Cleaned up documentation in template config file; Stallguard filament homing should now be possible (have to configure by hand); Additional configuration checks on startup; minor useability improvements based on community feedback
<li> v1.1.6 - New feature to log to file independently to console (allows for clean console and debug to logfile);  New gate statistics (like slippage) are recorded and available with an augmented ERCF_DUMP_STATS command; Several minor improvements and fixes suggested by community
<li> v1.1.7 - No need to put anything ERCF related into existing macros (START/PAUSE/RESUME/STOP/CANCEL) anymore!;  Improvements to install script for non EASY-BRD config; Exposed all built-in gear/extruder feed speeds; Tweaks to tolerance checks to prevent false pauses; No annoying pause/unlock sequence while you are playing out of a print. UPDATE TO CONFIG FILES RECOMMENDED
</ul>

<br>

## Summary of new commands:
  | Commmand | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_STATUS | Report on ERCF state, capabilities and Tool-to-Gate map | SHOWCONFIG=\[0\|1\] Whether or not to describe the machine configuration in status message |
  | ERCF_TEST_CONFIG | Dump / Change essential load/unload config options at runtime | Many. Best to run ERCF_TEST_CONFIG without options to report all parameters that can be specified |
  | ERCF_DISPLAY_TTG_MAP | Displays the current Tool - to - Gate mapping (can be used all the time but generally designed for EndlessSpool  | None |
  | ERCF_REMAP_TTG | Reconfiguration of the Tool - to - Gate (TTG) map.  Can also set gates as empty! | TOOL=\[0..n\] <br>GATE=\[0..n\] Maps specified tool to this gate (multiple tools can point to same gate) <br>AVAILABLE=\[0\|1\]  Marks gate as available or empty |
  | ERCF_SELECT_BYPASS | Unload and select the bypass selector position if configured | None |
  | ERCF_LOAD_BYPASS | Does the extruder loading part of the load sequence - designed for bypass filament loading | None |
  | ERCF_TEST_HOME_TO_EXTRUDER | For calibrating extruder homing - TMC current setting, etc. | RETURN=\[0\|1\] Whether to return the filament to the approximate starting position after homing - good for repeated testing |
  | ERCF_TEST_TRACKING | Simple visual test to see how encoder tracks with gear motor | DIRECTION=\[-1\|1\] Direction to perform the test <br>STEP=\[0.5..20\] Size of individual steps<br>Defaults to load direction and 1mm step size |
  | ERCF_PRELOAD | Helper for filament loading. Feed filament into gate, ERCF will catch it and correctly position at the specified gate | GATE=\[0..n\] The specific gate to preload. If omitted the currently selected gate can be loaded |
  | ERCF_CHECK_GATES | Inspect the gate(s) and mark availability | GATE=\[0..n\] The specific gate to check. If omitted all gates will be checked (the default) |
  | ERCF_RECOVER | Recover filament position. Useful to call prior to RESUME if you intervene/manipulate filament by hand | None |
  
  Note that some existing commands have been enhanced a little.  See the [command reference](#ercf-command-reference) at the end of this page.
  
<br>

## New features in detail:
### Config Loading and Unload sequences explained
Note that if a toolhead sensor is configured it will become the default filament homing method and home to extruder an optional but unnecessary step. Also note the home to extruder step will always be performed during calibration of tool 0 (to accurately set `ercf_calib_ref`). For accurate homing and to avoid grinding, tune the gear stepper current reduction `extruder_homing_current` as a % of the default run current.

#### Understanding the load sequence:
    1. ERCF [T1] >.... [encoder] .............. [extruder] .... [sensor] .... [nozzle] UNLOADED (@0.0 mm)
    2. ERCF [T1] >>>>> [encoder] >>>........... [extruder] .... [sensor] .... [nozzle] (@48.2 mm)
    3. ERCF [T1] >>>>> [encoder] >>>>>>>>...... [extruder] .... [sensor] .... [nozzle] (@696.4 mm)
    4. ERCF [T1] >>>>> [encoder] >>>>>>>>>>>>>> [extruder] .... [sensor] .... [nozzle] (@696.4 mm)
    5. ERCF [T1] >>>>> [encoder] >>>>>>>>>>>>>> [extruder] >>>| [sensor] .... [nozzle] (@707.8 mm)
    6. ERCF [T1] >>>>> [encoder] >>>>>>>>>>>>>> [extruder] >>>> [sensor] >>>> [nozzle] LOADED (@758.7 mm)
  
The "visual log" above shows individual steps of the loading process:
  <ol>
    <li>Starting with filament unloaded and sitting in the gate for tool 1
    <li>Firstly ERCF clamps the servo down and pulls a short length of filament through the encoder. It it doesn't see filament it will try 'load_encoder_retries' times (default 2). If still no filament it will report the error. The speed of this initial movement is controlled by 'short_moves_speed', the acceleration is as defined on the gear stepper motor config in 'ercf_hardware.cfg'
    <li>ERCF will then load the filament through the bowden in a fast movement.  The speed is controlled by 'long_moves_speed'.  This movement can be broken up into multiple movements with 'num_moves' as one workaround to overcome "Timer too close" errors from Klipper. If you keep your step size to 8 for the gear motor you are likely to be able to operate with a single fast movement.  The length of this movement is set when you calibrate ERCF and stored in 'ercf_vars.cfg'.  There is an advanced option to allow for correction of this move if slippage is detected controlled by 'apply_bowden_correction' and 'load_bowden_tolerance' (see comments in 'ercf_parameters.cfg' for more details)
    <li>The example shown uses a toolhead sensor, but if you configure sensorless filament homing then ERCF will now creep towards your extruder gears to detect this point as its homing position.  This homing move is controlled by 'extruder_homing_max' (maximum distance to advance in order to attempt to home the extruder), 'extruder_homing_step' (step size to use when homing to the extruder with collision detection), 'extruder_homing_current' (tunable to control how much % to temporarily reduce the gear stepper current to prevent grinding of filament)
    <li>This is the move into the toolhead and is the most critical transition point.  ERCF will advance the extruder looking to see that the filament was successfully picked up. In the case of a toolhead sensor this is deterministic because it will advance to the sensor and use this as a new homing point.  For sensorless ERCF will look for encoder movement implying that filament has been picked up.  Optionally this move can be made to run gear and extruder motors synchronously for greater reliability. 'sync_load_length' (mm of synchronized extruder loading at entry to extruder).  If synchronous load is not employed ERCF will attempt to use the "spring" in the filament by delaying the servo release by 'delay_servo_release' mm.
<br>
With toolhead sensor enabled there is a little more to this step: ERCF will home the end of the filament to the toolhead sensor controlled by 'toolhead_homing_max' (maximum distance to advance in order to attempt to home to toolhead sensor) and 'toolhead_homing_step (step size to use when homing to the toolhead sensor. If 'sync_load_length' is greater than 0 this homing step will be synchronised.
<br>The speed of all movements in this step is controlled by 'sync_load_speed'
    <li>Now the filament is under exclusive control of the extruder.  Filament is moved the remaining distance to the meltzone. This distance is defined by 'home_position_to_nozzle' and is either the distance from the toolhead sensor to the nozzle or the distance from the extruder gears to the nozzle depending on your setup.  This move speed is controlled by 'nozzle_load_speed'.  We are now loaded and ready to print.
  </ol>

#### Understanding the unload sequence:
    1. ERCF [T1] <<<<< [encoder] <<<<<<<<<<<<<< [extruder] <<<< [sensor] <... [nozzle] (@34.8 mm)
    2. ERCF [T1] <<<<< [encoder] <<<<<<<<<<<<<< [extruder] <<<| [sensor] .... [nozzle] (@87.7 mm)
    3. ERCF [T1] <<<<< [encoder] <<<<<<<<<<<<<< [extruder] .... [sensor] .... [nozzle] (@91.7 mm)
    4. ERCF [T1] <<<<< [encoder] <<<<<<<<...... [extruder] .... [sensor] .... [nozzle] (@729.9 mm)
    5. ERCF [T1] <<<<< [encoder] <<<........... [extruder] .... [sensor] .... [nozzle] (@729.9 mm)
    6. ERCF [T1] <<<.. [encoder] .............. [extruder] .... [sensor] .... [nozzle] (@795.5 mm)
    7. ERCF [T1] <.... [encoder] .............. [extruder] .... [sensor] .... [nozzle] UNLOADED (@795.5 mm)
  
The "visual log" above shows individual steps of the loading process:
  <ol>
    <li>Starting with filament loaded in tool 1. This example is taken from an unload that is not under control of the slicer, so the first thing that happens is that a tip is formed on the end of the filament which ends with filament in the cooling zone of the extruder. This operation is controlled but the user edited '_ERCF_FORM_TIP_STANDALONE' macro in 'ercf_software.cfg'
    <li>This step only occurs with toolhead sensor. The filament is withdrawn until it no longer detected by toolhead sensor. This is done at the 'nozzle_unload_speed' and provides a more accurate determination of how much further to retract and a safety check that the filament is not stuck in the nozzle
    <li>ERCF then moves the filament out of the extruder at 'nozzle_unload_speed'. Once at where it believes is the gear entrance to the extruder an optional short synchronized (gear and extruder) move can be configured. This is controlled by 'sync_unload_speed' and 'sync_unload_length'.  This is a great safely step and "hair pull" operation but also serves to ensure that the ERCF gear has a grip on the filament.  If synchronized unload is not configured ERCF will still perform the bowden unload with an initial short move with gear motor only, again to ensure filament is gripped
    <li>The filament is now extracted quickly through the bowden. The speed is controlled by 'long_moves_speed' and the movement can be broken up with 'num_moves' similar to when loading.
    <li>Completion of the the fast bowden move
    <li>At this point ERCF performs a series of short moves looking for when the filament exits the encoder.  The speed is controlled by 'short_moves_speed'
    <li>When the filament is released from the encoder, the remainder of the distance to the park position is moved at 'short_moves_speed'.  The filament is now unloaded.
  </ol>

When the state of ERCF is unknown, ERCF will perform other movements and look at its sensors to try to ascertain filament location. This may modify the above sequence and result in the omission of the fast bowden move for unloads.

#### Possible loading options (explained in ercf_parameters.cfg template):
     If you have a toolhead sensor for filament homing:
        toolhead_homing_max: 35            # Maximum distance to advance in order to attempt to home to toolhead sensor (default 20)
        toolhead_homing_step: 1.0          # Step size to use when homing to the toolhead sensor (default 1)

    Options without toolhead sensor (but still needed for calibration with toolhead sensor)

        extruder_homing_max: 50            # Maximum distance to advance in order to attempt to home the extruder
        extruder_homing_step: 2.0          # Step size to use when homing to the extruder with collision detection (default 2)
    
    For accurate homing and to avoid grinding, tune the gear stepper current reduction

        extruder_homing_current: 40        # Percentage of gear stepper current to use when extruder homing (TMC2209 only, 100 to disable)
    
    How far (mm) to run gear_stepper and extruder together in sync on load and unload. This will make loading and unloading
    more reliable and will act as a "hair pulling" step on unload.  These settings are optional - use 0 to disable
    Non zero value for 'sync_load_length' will synchronize the whole homing distance if toolhead sensor is installed

        sync_load_length: 10               # mm of synchronized extruder loading at entry to extruder
        sync_unload_length: 10             # mm of synchronized movement at start of bowden unloading
    
    This is the distance of the final filament load from the homing point to the nozzle
    If homing to toolhead sensor this will be the distance from the toolhead sensor to the nozzle
    If extruder homing it will be the distance from the extruder gears (end of bowden) to the nozzle
    
    This value can be determined by manually inserting filament to your homing point (extruder gears or toolhead sensor)
    and advancing it 1-2mm at a time until it starts to extrude from the nozzle.  Subtract 1-2mm from that distance distance
    to get this value.  If you have large gaps in your purge tower, increase this value.  If you have blobs, reduce this value.
    This value will depend on your extruder, hotend and nozzle setup.

        home_position_to_nozzle: 72        # E.g. Revo Voron with CW2 extruder using extruder homing

*Obviously the actual distances shown above may be customized*
  
  **Advanced options**
When not using synchronous load move the spring tension in the filament held by servo will be leverage to help feed the filament into the extruder. This is controlled with the `delay_servo_release` setting. It defaults to 2mm and is unlikely that it will need to be altered.
<br>An option to home to the extruder using stallguard `homing_method=1` is available but not recommended: (i) it is not necessary with current reduction, (ii) it is not readily compatible with EASY-BRD and (iii) is currently incompatible with sensorless selector homing which hijacks the gear endstop configuration.
<br>The 'apply_bowden_correction' setting, if enabled, will make the driver "believe" the encoder reading and make correction moves to bring the filament to the desired end of bowden position. This is useful is you suspect slippage on high speed loading, perhaps when yanking on spool (requires accurate encoder). If disabled, the gear stepper will be solely responsible for filament positioning in bowden (requires minimal friction in feeder tubes). The associated (advanced) 'load_bowden_tolerance' defines the point at which to apply to correction moves. See 'ercf_parameters.cfg' for more details.
  
  **Note about post homing distance**
Regardless of loading settings above it is important to accurately set `home_to_nozzle` distance.  If you are not homing to the toolhead sensor this will be from the extruder entrance to nozzle.  If you are homing to toolhead sensor, this will be the (smaller) distance from sensor to nozzle.  For example in my setup of Revo & Clockwork 2, the distance is 72mm or 62mm respectively.
  
#### Possible unloading options:
This is much simplier than loading. The toolhead sensor, if installed, will automatically be leveraged as a checkpoint when extracting from the extruder.
`sync_unload_length` controls the mm of synchronized movement at start of bowden unloading.  This can make unloading more reliable if the tip is caught in the gears and will act as what Ette refers to as a "hair pulling" step on unload.  This is an optional step, set to 0 to disable.

### Tool-to-Gate (TTG) mapping and EndlessSpool application
When changing a tool with the `Tx` command the ERCF will by default select the filament at the gate (spool) of the same number.  The mapping built into this *Happy Hare* driver allows you to modify that.  There are 3 primary use cases for this feature:
<ol>
  <li>You have loaded your filaments differently than you sliced gcode file... No problem, just issue the appropriate remapping commands prior to printing
  <li>Some of "tools" don't have filament and you want to mark them as empty to avoid selection.
  <li>Most importantly, for EndlessSpool - when a filament runs out on one gate (spool) then next in the sequence is automatically mapped to the original tool.  It will therefore continue to print on subsequent tool changes.  You can also replace the spool and update the map to indicate availability mid print
</ol>

*Note that the initial availability of filament at each gate can also be specified in the `ercf_parameters.cfg` file by updating the `gate_status` list. E.g.
>gate_status = 1, 1, 0, 0, 1, 0, 0, 0, 1

  on a 9-gate ERCF would mark gates 2, 3, 5, 6 & 7 as empty
 
To view the current mapping you can use either `ERCF_STATUS` or `ERCF_DISPLAY_TTG_MAP`
  
![ERCF_STATUS](doc/ercf_status.png "ERCF_STATUS")

<br>

Since EndlessSpool is not something that triggers very often you can use the following to simulate the action:
  > ERCF_ENCODER_RUNOUT RUNOUT=1

This will emulate a filament runout and force ERCF to interpret it as a true runout and not a possible clog. ERCF will then run the following sequence:
<ul>
  <li>Move the toolhead up a little (defined by 'z_hop_distance & z_hop_speed') to avoid blobs
  <li>Call '_ERCF_ENDLESS_SPOOL_PRE_UNLOAD' macro.  Typically this where you would quickly move the toolhead to your parking area
  <li>Perform the toolchange and map the new gate in the sequence
  <li>Call '_ERCF_ENDLESS_SPOOL_POST_LOAD' macro.  Typically this is where you would clean the nozzle and quickly move your toolhead back to the position where you picked it up in the PRE_UNLOAD macro
  <li>Move the toolhead back down the final amount and resume the print
</ul>

The default supplied _PRE and _POST macros call PAUSE/RESUME which is typically a similar operation and may be already sufficient. Note: A common problem is that a custom _POST macro does not return the toolhead to previous position.  ERCF will still handle this case but it will move very slowly because it is not expecting large horizontal movement.

<br>
  
### Visualization of filament position
  The `log_visual` setting turns on an off the addition of a filament tracking visualization.  This is a nice with log_level of 0 or 1 on a tuned and functioning setup.
  
![Bling is always better](doc/visual_filament.png "Visual Filament Location")
  
<br>

### Filament bypass
If you have installed the optional filament bypass block your can configure its selector position by setting `bypass_selector` in `ercf_parameters.cfg`. Once this is done you can use the following command to unload any ERCF controlled filament and select the bypass:
  > ERCF_SELECT_BYPASS
  
  Once you have filament loaded up to the extruder you can load the filament to nozzle with
  > ERCF_LOAD_BYPASS

### Adjusting configuration at runtime
  All the essential configuration and tuning parameters can be modified at runtime without restarting Klipper. Use the `ERCF_TEST_CONFIG` command to do this:
  
  <img src="doc/ercf_test_config.png" width="500" alt="ERCF_TEST_CONFIG">
  
  Any of the displayed config settings can be modified.  E.g.
  > ERCF_TEST_CONFIG home_position_to_nozzle=45
  
  Will update the distance from homing position to nozzle.  The change is designed for testing was will not be persistent.  Once you find your tuned settings be sure to update `ercf_parameters.cfg`

### Updated Calibration Ref
  Setting the `ercf_calib_ref` is slightly different in that it will, by default, average 3 runs and compensate for spring tension in filament held by servo. It might be worth limiting to a single pass until you have tuned the gear motor current. Here is an example:
  
  <img src="doc/Calibration Ref.png" width="500" alt="ERCF_CALIBRATION_SINGLE TOOL=0">
  
### Useful pre-print functionality
  The `ERCF_PRELOAD` is an aid to loading filament into the ERCF.  The command works a bit like the Prusa MMU and spins gear with servo depressed until filament is fed in.  Then parks the filament nicely. This is the recommended way to load filament into ERCF and ensures that filament is not under/over inserted blocking the gate.

Similarly the `ERCF_CHECK_GATES` command will run through all the gates (or those specified), checks that filament is loaded, correctly parks and updates the "gate status" map of empty gates. Could be a really useful pre-print check...

### Gate statistics
  Per-gate statistics that aggregate servo/load/unload failures and slippage are recorded throughout a session and can be logged at each toolchange.  An augmented `ERCF_DUMP_STATS` command will display these stats and will give a rating on the "quality assessment" of functionality of the gate (more info is sent to debug level typically found in the `ercf.log`).  The per-gate statistics will record important data about possible problems with individual gates.  Since the software will try to recover for many of these conditions you might not know you have a problem.  One particularly useful feature is being able to spot gates that are prone to slippage.  If slippage occurs on all gates equally, it is likely an encoder problem.  If on one gate if might be incorrect calibration of that gate or friction in the filament path.  Note that `ERCF_DUMP_STATS` will display this data but the details are sent to the DEBUG log level so you will only see it in the ercf.log file if you setup as I suggest.

### Logging
There are four configuration options that control logging:

    log_level & logfile_level can be set to one of (0 = essential, 1 = info, 2 = debug, 3 = trace, 4 = developer)
    Generally you can keep console logging to a minimal whilst still sending debug output to the ercf.log file
    Increasing the console log level is only really useful during initial setup to save having to constantly open the log file
      log_level: 1
      logfile_level: 3            # Can also be set to -1 to disable log file completely
      log_statistics: 1           # 1 to log statistics on every toolchange, 0 to disable (still recorded)
      log_visual: 1               # 1 to log a fun visual representation of ERCF state showing filament position, 0 disable

The logfile will be placed in the same directory as other log files and is called `ercf.log`.  It will rotate and keep the last 5 versions (just like klipper).  The default log level for ercf.log is "3" but can be set by adding `logfile_level` in you `ercf_parameters.cfg`.  With this available my suggestion is to reset the console logging level `log_level: 1` for an uncluttered experience knowing that you can always access `ercf.log` for debugging at a later time.  Oh, and if you don't want the logfile, no problem, just set `logfile_level: -1`

### Pause / Resume / Cancel_Print macros:
It is no longer necessary to added anything to these macros -- ERCF will automatically wrap anything defined.   If you have used other versions of the software then you should remove these customizations. To understand the philosophy and expectations here is the sequence:
<br>
  
During a print, if ERCF detects a problem, it will record the print position, safely lift the nozzle up to `z_hop_height` at `z_hop_speed` (to prevent a blob).  It will then call the user's PAUSE macro (which can be the example one supplied in `ercf_software.cfg`).  It is expected that pause will save it's starting position (GCODE_SAVE_STATE) and move the toolhead to a park area, often above a purge bucket, at fast speed.
<br>

The user then calls 'ERCF_UNLOCK', addresses the issue and called 'RESUME'
<br>
  
The user's RESUME macro may do some purging or nozzle cleaning, but is expected to return the toolhead at higher speed to where it was left when the pause macro was called.  At this point the ERCF wrapper takes over and is responsible for dropping the toolhead back down to the print and resumes printing.
<br>
  
ERCF will always return the toolhead to the correct position, but if you leave it in your park area will will move it back very slowly.  You can to follow the above sequence to make this operation fast to prevent oozing from leaking on your print. 

## My Testing:
  This software is largely rewritten as well as being extended and so, despite best efforts, has probably introduced some bugs that may not exist in the official driver.  It also lacks extensive testing on different configurations that will stress the corner cases.  I have been using successfully on Voron 2.4 / ERCF with EASY-BRD.  I use a self-modified CW2 extruder with foolproof microswitch toolhead sensor. My day-to-day configuration is to load the filament to the extruder in a single movement (`num_moves=1`) at 200mm/s, then home to toolhead sensor with synchronous gear/extruder movement (option #1 explained above).  I use the sensorless selector and have runout and EndlessSpool enabled.

### My Setup:
<img src="doc/My Voron 2.4 and ERCF.jpg" width="400" alt="My Setup">

### Some setup notes based on my learnings:
Firstly the importance of a reliable and fairly accurate encoder should not be under estimated. If you cannot get very reliable results from `ERCF_CALIBRATE_ENCODER` then don't proceed with setup - address the encoder problem first. Because the encoder is the HEART of ERCF I [created a how-to](doc/ENCODER.md) on fixing many possible problems with encoder.
<ul>
  <li>If using a toolhead sensor, that must be reliable too.  The hall effect based switch is very awkward to get right because of so many variables: strength of magnet, amount of iron in washer, even temperature, therefore I strongly recommend a simple microswitch based detection.  They work first time, every time.
  <li>The longer the bowden length the more important it is to calibrate correctly (do a couple of times to check for consistency).  Small errors multiply with longer moves!
  <li>Eliminate all points of friction in the filament path.  There is lots written about this already but I found some unusual places where filament was rubbing on plastic and drilling out the path improved things a good deal.
  <li>This version of the driver software both, compensates for, and exploits the spring that is inherently built when homing to the extruder.  The `ERCF_CALIBRATE_SINGLE TOOL=0` (which calibrates the *ercf_calib_ref* length) averages the measurement of multiple passes, measures the spring rebound and considers the configuration options when recommending and setting the ercf_calib_ref length.  If you change basic configuration options it is advisable to rerun this calibration step again.
  <li>The dreaded "Timer too close" can occur but I believe I have worked around most of these cases.  The problem is not always an overloaded mcu as often cited -- there are a couple of bugs in Klipper that will delay messages between mcu and host and thus provoke this problem.  To minimize you hitting these, I recommend you use a step size of 8 for the gear motor. You don't need high fidelity and this greatly reduces the chance of this error. Also, increasing 'num_moves' also is a workaround.  I'm not experiencing this and have a high speed (200 mm/s) single move load with a step size of 8.
  <li>The servo problem where a servo with move to end position and then jump back can occur due to bug in Klipper just like the original software but also because of power supply problems. The workaround for the former is increase the same servo "dwell" config options in small increments until the servo works reliably. Note that this driver will retry the initial servo down movement if it detects slippage thus working around this issue to some extent.
  <li>I also added a 'apply_bowden_correction' config option that dictates whether the driver "believes" the encoder or not for long moves.  If enabled, the driver will make correction moves to get the encoder reading correct.  If disabled the gear stepper movement will be applied without slippage detection.  Details on when this is useful is documented in 'ercf_parameters'.  If enabled, the options 'load_bowden_tolerance' and 'unload_bowden_tolerance' will set the threshold at which correction is applied.
  <li>I can recommend the "sensorless selector" option -- it works well and provides for additional recovery abilities if filament gets stuck in encoder preventing selection of a different gate.
  <li>Speeds.... starting in v1.1.7 the speed setting for all the various moves made by ERCF can be tuned.  These are all configurable in the 'ercf_parameters.cfg' file or can be tested without restarting Klipper with the 'ERCF_TEST_CONFIG' command.  If you want to optimise performance you might want to tuning these faster.  If you do, watch for the gear stepper missing steps which will often be reported as slippage.
</ul>

Good luck and hopefully a little less *enraged* printing.  You can find me on discord as *moggieuk#6538*

  
  ---
  
# ERCF Command Reference
  
  *Note that some of these commands have been enhanced from the original*

  ## Logging and Stats
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_RESET_STATS | Reset the ERCF statistics | None |
  | ERCF_DUMP_STATS | Dump the ERCF statistics (and Gate statistics to debug level - usually the logfile) | None |
  | ERCF_SET_LOG_LEVEL | Sets the logging level and turning on/off of visual loading/unloading sequence and stats reporting | LEVEL=\[1..4\] The level of logging to the console (1 recommended)<br>LOGFILE=\[1..4\] The level of logging to the ercf.log file (3 recommended)<br>VISUAL=\[0\|1\] Whether to also show visual representation<br>STATS=\[0\|1\] Whether to log print stats and gate summary on every tool change |
  | ERCF_STATUS | Report on ERCF state, capabilities and Tool-to-Gate map | SHOWCONFIG=\[0\|1\] Whether or not to describe the machine configuration in status message |
  | ERCF_DISPLAY_ENCODER_POS | Displays the current value of the ERCF encoder | None |
  <br>

  ## Calibration
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_CALIBRATE | Complete calibration of all ERCF tools | None |
  | ERCF_CALIBRATE_SINGLE | Calibration of a single ERCF tool | TOOL=\[0..n\] <br>REPEATS=\[1..10\] How many times to repeat the calibration for reference tool T0 (ercf_calib_ref) <br>VALIDATE=\[0\|1\] If True then calibration of tool 0 will simply verify the ratio i.e. another check of encoder accuracy (should result in a ratio of 1.0) |
  | ERCF_CALIB_SELECTOR | Calibration of the selector for the defined tool | TOOL=\[0..n\] |
  | ERCF_CALIBRATE_ENCODER | Calibration routine for ERCF encoder | DIST=.. Distance (mm) to measure over. Longer is better, defaults to 500mm <br>REPEATS=.. Number of times to average over <br>SPEED=.. Speed of gear motor move. Defaults to long move speed <br>ACCEL=.. Accel of gear motor move. Defaults to motor setting in ercf_hardware.cfg |
  <br>

  ## Servo and motor control
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_SERVO_DOWN | Engage the ERCF gear | None |
  | ERCF_SERVO_UP | Disengage the ERCF gear | None |
  | ERCF_MOTORS_OFF | Turn off both ERCF motors | None |
  | ERCF_BUZZ_GEAR_MOTOR | Buzz the ERCF gear motor and report on whether filament was detected | None |
  <br>

  ## Core ERCF functionality
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_PRELOAD | Helper for filament loading. Feed filament into gate, ERCF will catch it and correctly position at the specified gate | GATE=\[0..n\] The specific gate to preload. If omitted the currently selected gate can be loaded |
  | ERCF_UNLOCK | Unlock ERCF operations after a pause caused by error condition | None |
  | ERCF_HOME | Home the ERCF selector and optionally selects gate associated with the specified tool | TOOL=\[0..n\] After homing, select this gate as if ERCF_SELECT_GATE was called<br>FORCE_UNLOAD=\[0\|1\] ERCF will try to unload filament if it thinks it has to but this option will force it to check and attempt unload |
  | ERCF_SELECT_TOOL | Selects the gate associated with the specified tool | TOOL=\[0..n\] The tool to be selected (technically the gate associated with this tool will be selected) |
  | ERCF_SELECT_BYPASS | Unload and select the bypass selector position if configured | None |
  | ERCF_LOAD_BYPASS | After inserting filament to the extruder gear this will perform the extruder loading part of the load sequence - designed for bypass filament loading | None |
  | ERCF_CHANGE_TOOL | Perform a tool swap (generally called from 'Tx' macros) | TOOL=\[0..n\] <br>STANDALONE=\[0\|1\] Optional to force standalone logic (tip forming) |
  | ERCF_CHANGE_TOOL_STANDALONE | Deprecated. Perform tool swap outside of a print. Use 'ERCF_TOOL_CHANGE STANDALONE=1' if really necessary | TOOL=\[0..n\] |
  | ERCF_EJECT | Eject filament and park it in the ERCF gate | None |
  | ERCF_PAUSE | Pause the current print and lock the ERCF operations | FORCE_IN_PRINT=\[0\|1\] This option forces the handling of pause as if it occurred in print and is useful for testing |
  | ERCF_RECOVER | Recover filament position (state). ERCF will generally do this for you can this may be use useful to call prior to RESUME if you intervene/manipulate filament by hand and want to confirm state | None |
  <br>

  ## User Testing
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_TEST_GRIP | Test the ERCF grip of the currently selected tool | None |
  | ERCF_TEST_SERVO | Test the servo angle | VALUE=.. Angle value sent to servo |
  | ERCF_TEST_MOVE_GEAR | Move the ERCF gear | LENGTH=..\[200\] Length of gear move in mm <br>SPEED=..\[50\] Stepper move speed50 <br>ACCEL=..\[200\] Gear stepper accel |
  | ERCF_TEST_LOAD_SEQUENCE | Soak testing of load sequence. Great for testing reliability and repeatability| LOOP=..\[10\] Number of times to loop while testing <br>RANDOM=\[0\|1\] Whether to randomize tool selection <br>FULL=\[0 \|1 \] Whether to perform full load to nozzle or short load just past encoder |
  | ERCF_TEST_LOAD | Test loading filament | LENGTH=..[100] Test load the specified length of filament into selected tool |
  | (ERCF_LOAD) | Identical to ERCF_TEST_LOAD | |
  | ERCF_TEST_UNLOAD | Move the ERCF gear | LENGTH=..[100] Length of filament to be unloaded <br>UNKNOWN=\[0\|1\] Whether the state of the extruder is known. Generally 0 for standalone use, 1 simulates call as if it was from slicer when tip has already been formed |
  | ERCF_TEST_HOME_TO_EXTRUDER | For calibrating extruder homing - TMC current setting, etc. | RETURN=\[0\|1\] Whether to return the filament to the approximate starting position after homing - good for repeated testing |
  | ERCF_TEST_TRACKING | Simple visual test to see how encoder tracks with gear motor | DIRECTION=\[-1\|1\] Direction to perform the test <br>STEP=\[0.5..20\] Size of individual steps<br>Defaults to load direction and 1mm step size |
  | ERCF_TEST_CONFIG | Dump / Change essential load/unload config options at runtime | Many. Best to run ERCF_TEST_CONFIG without options to report all parameters than can be specified |
  <br>

  ## Tool to Gate map and Endless spool
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | ERCF_ENCODER_RUNOUT | Filament runout handler that will also implement EndlessSpool if enabled | RUNOUT=1 is useful for testing to validate your _ERCF_ENDLESS_SPOOL\*\* macros |
  | ERCF_DISPLAY_TTG_MAP | Displays the current Tool -> Gate mapping (can be used all the time but generally designed for EndlessSpool  | None |
  | ERCF_REMAP_TTG | Reconfiguration of the Tool - to - Gate (TTG) map.  Can also set gates as empty! | TOOL=\[0..n\] <br>GATE=\[0..n\] Maps specified tool to this gate (multiple tools can point to same gate) <br>AVAILABLE=\[0\|1\]  Marks gate as available or empty |
  | ERCF_RESET_TTG_MAP | Reset the Tool-to-Gate map back to default | None |
  | ERCF_CHECK_GATES | Inspect the gate(s) and mark availability | GATE=\[0..n\] The specific gate to check. If omitted all gates will be checked (the default) |
  <br>

  ## User defined/configurable macros (in ercf_software.cfg)
  | Command | Description | Parameters |
  | -------- | ----------- | ---------- |
  | _ERCF_ENDLESS_SPOOL_PRE_UNLOAD | Called prior to unloading the remains of the current filament |
  | _ERCF_ENDLESS_SPOOL_POST_LOAD | Called subsequent to loading filament in the new gate in the sequence |
  | _ERCF_FORM_TIP_STANDALONE | Called to create tip on filament when not in print (and under the control of the slicer). You tune this macro by modifying the defaults to the parameters |
<br>

*Working reference PAUSE / RESUME / CANCEL_PRINT macros are defined in client_macros.cfg*

  
    (\_/)
    ( *,*)
    (")_(") ERCF Ready
  
