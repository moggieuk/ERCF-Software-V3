
The ERCF system now offers the optional feature of coordinating its gear motor with the extruder stepper during printing. This added functionality enhances the filament pulling torque, potentially alleviating friction-related problems. It is crucial, however, to maintain precise rotational distances for both the primary extruder stepper and the gear stepper. A mismatch in filament transfer speeds between these components could lead to undue stress and filament grinding.

# Setting up Synchronization

- Modify the section title `[manual_stepper gear_stepper]` to `[manual_extruder_stepper gear_stepper]`.
- Within the `ercf_parameters.cfg` file, include `sync_to_extruder: <target_extruder>`. Here, `<target_extruder>` represents the extruder which is to be coordinated with the ERCF's gear stepper. In most cases, this will simply be `sync_to_extruder: extruder`.

# Synchronization Workflow

If the `sync_to_extruder` feature is activated, the gear stepper will automatically coordinate with the extruder stepper following a successful tool change. Any ERCF operation that necessitates the gear stepper's movement (like when unloading the filament or buzzing the gear stepper to verify filament engagement), will automatically disengage the sync. Generally, you don't need to manually manage the coordination/discoordination of the gear stepper — the ERCF software handles the majority of these actions. However, if the printer enters ERCF_PAUSE state (due to a filament jam or runout, for example), synchronization is automatically disengaged. Upon resuming a print, you should either manually invoke a tool change, which will implicity sync the steppers again, or use the `cmd_ERCF_SYNC_GEAR_MOTOR` command to reestablish coordination with the gear stepper.

The `cmd_ERCF_SYNC_GEAR_MOTOR sync={0|1} servo={0|1}` command functions as follows:
- Defaults to `sync=1` and `servo=1`
- If `sync=1` and `servo=1`, it triggers the servo and executes the synchronization
- If `sync=1` and `servo=0`, it performs only the synchronization
- If `sync=0`, it always disengages synchronization while maintaining the servo's status (ignores the servo parameter)

Much like a `manual_stepper`, you have the option to manually control a `manual_extruder_stepper` using the `MANUAL_STEPPER` command. This command, however, will only be effective if the stepper is not currently coordinated with the extruder.
