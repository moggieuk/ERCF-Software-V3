# Happy Hare ERCF Software
# Driver for encoder that supports movement measurement and runout/clog detection
#
# Copyright (C) 2022  moggieuk#6538 (discord)
#
# Based on:
# Original Enraged Rabbit Carrot Feeder Project  Copyright (C) 2021  Ette
# Generic Filament Sensor Module                 Copyright (C) 2019  Eric Callahan <arksine.code@gmail.com>
# Filament Motion Sensor Module                  Copyright (C) 2021 Joshua Wherrett <thejoshw.code@gmail.com>
#
# (\_/)
# ( *,*)
# (")_(") ERCF Ready
#
# This file may be distributed under the terms of the GNU GPLv3 license.
#
import logging, time
from . import pulse_counter

class ErcfEncoder:
    CHECK_MOVEMENT_TIMEOUT = .250

    RUNOUT_DISABLED = 0
    RUNOUT_STATIC = 1
    RUNOUT_AUTOMATIC = 2

    VARS_ERCF_CALIB_CLOG_LENGTH = "ercf_calib_clog_length" # in ercf_vars.cfg variables because it is autotuned

    def __init__(self, config):
        self.printer = config.get_printer()
        self.reactor = self.printer.get_reactor()
        self.gcode = self.printer.lookup_object('gcode')
        self.pin = config.get('encoder_pin')

        # For counter functionality
        self.sample_time = config.getfloat('sample_time', 0.1, above=0.)
        self.poll_time = config.getfloat('poll_time', 0.0001, above=0.)
        self.resolution = config.getfloat('encoder_resolution', above=0.) # Must be calibrated by user

        # For runout functionality
        self.extruder_name = config.get('extruder', None) # PAUL, I could discover this and allow a hidden override?
        self.headroom = config.getfloat('headroom', 5., above=0.)
        self.average_samples = config.getint('average_samples', 4, minval=1)
        self.calibration_length = config.getfloat('calibration_length', 200., above=50.)
        self.detection_length = config.getfloat('detection_length', 8., above=5.)
        self.event_delay = config.getfloat('event_delay', 3., above=0.)
        gcode_macro = self.printer.load_object(config, 'gcode_macro')
        self.runout_gcode = gcode_macro.load_template(config, 'runout_gcode', '_ERCF_ENCODER_RUNOUT')
        self.insert_gcode = gcode_macro.load_template(config, 'insert_gcode', '_ERCF_ENCODER_DETECTION')

        # Initialize measurement counter state
        self._last_time = self._last_count = None
        self._counts = 0
        self._encoder_steps = self.resolution
        self._counter = pulse_counter.MCU_counter(self.printer, self.pin, self.sample_time, self.poll_time)
        self._counter.setup_callback(self._counter_callback)

        # Initialize clog/runout state
        self.enabled = True # Additional method of enabling/disabling
        self.min_event_systime = self.reactor.NEVER
        self.extruder = self.estimated_print_time = self.filament_runout_pos = None
        self.filament_detected = False
        self.detection_mode = self.RUNOUT_STATIC
        self.next_calibration_point = 0.

        # Register event handlers
        self.printer.register_event_handler('klippy:ready', self._handle_ready)
        self.printer.register_event_handler('klippy:connect', self._handle_connect)
        self.printer.register_event_handler('idle_timeout:printing', self._handle_printing)
        self.printer.register_event_handler('idle_timeout:ready', self._handle_not_printing)
        self.printer.register_event_handler('idle_timeout:idle', self._handle_not_printing)

# PAUL vv temp
        self.gcode.register_command('PAUL', self.cmd_PAUL)
    def cmd_PAUL(self, gcmd):
        mode = gcmd.get_int('MODE', 2, minval=0, maxval=2)
        min_diff = gcmd.get_float('MIN_DIFF', 5, minval=0, maxval=7.2)
        self.detection_mode = mode
        self.min_diff_measured = min_diff
        self._update_detection_length()
# PAUL ^^ temp

    def _handle_connect(self):
        self.variables = self.printer.lookup_object('save_variables').allVariables
        self.detection_length = self.min_diff_measured = self.get_clog_detection_length()

    def _handle_ready(self):
        logging.info("PAUL: Ready from ErcfEncoder")
        self.min_event_systime = self.reactor.monotonic() + 2. # Don't process events too early
        self.extruder = self.printer.lookup_object(self.extruder_name)
        self.estimated_print_time = self.printer.lookup_object('mcu').estimated_print_time
        self._update_filament_runout_pos()
        self._extruder_pos_update_timer = self.reactor.register_timer(self._extruder_pos_update_event)

    def _handle_printing(self, print_time):
        self.reactor.update_timer(self._extruder_pos_update_timer, self.reactor.NOW) # Enabled

    def _handle_not_printing(self, print_time):
        self.reactor.update_timer(self._extruder_pos_update_timer, self.reactor.NEVER) # Disabled

    def _get_extruder_pos(self, eventtime=None):
        if eventtime is None:
            eventtime = self.reactor.monotonic()
        print_time = self.estimated_print_time(eventtime)
        return self.extruder.find_past_position(print_time)

    # Called periodically to check for runout
    def _extruder_pos_update_event(self, eventtime):
        extruder_pos = self._get_extruder_pos(eventtime)
        logging.info("PAUL: trace... Got periodic _extruder_pos_update_event(). Extruder pos=%.1f" % extruder_pos)
        if extruder_pos > self.next_calibration_point:
            if self.next_calibration_point > 0:
                logging.info("PAUL: past calibration point. Recalibrating...")
                self._update_detection_length()
            self.next_calibration_point = extruder_pos + self.calibration_length
        if self.filament_runout_pos - extruder_pos < self.min_diff_measured:
            self.min_diff_measured = self.filament_runout_pos - extruder_pos
            logging.info("PAUL: new min_diff_measured: %.1f" % self.min_diff_measured)
        self._handle_filament_event(extruder_pos < self.filament_runout_pos)
        return eventtime + self.CHECK_MOVEMENT_TIMEOUT

    # Called on all movement activity detected by encoder
    def _update_filament_runout_pos(self, eventtime=None):
        logging.info("PAUL: trace... Got periodic _update_filament_runout_pos()")
        if eventtime is None:
            eventtime = self.reactor.monotonic()
        extruder_pos = self._get_extruder_pos(eventtime)
        self.filament_runout_pos = extruder_pos + self.detection_length

    # Called periodically to tune the clog detection length
    def _update_detection_length(self):
        logging.info("PAUL: trace... _update_detection_length mode=%d, min_diff=%.1f" % (self.detection_mode, self.min_diff_measured))
        if self.detection_mode != self.RUNOUT_AUTOMATIC:
            return
        current_detection_length = self.detection_length
        logging.info("PAUL: current_detection_length=%.1f" % current_detection_length)
        if self.min_diff_measured < self.headroom:
            # Maintain headroom
            self.detection_length += (self.headroom - self.min_diff_measured)
            logging.info("PAUL: maintaining headroom by adding %.1f to detection_length" % (self.headroom - self.min_diff_measured))
        else:
            # Average down
            sample = self.detection_length - (self.min_diff_measured - self.headroom)
            logging.info("PAUL: averaging down with %.1f sample" % sample)
            self.detection_length = ((self.average_samples * self.detection_length) + self.headroom - self.min_diff_measured) / self.average_samples
            logging.info("PAUL: new_detection_length=%.1f" % self.detection_length)
        self.min_diff_measured = self.detection_length
        if round(self.detection_length) != round(current_detection_length): # Persist if significant
            logging.info("PAUL: new_detection_length=%.1f" % self.detection_length)
            self.set_clog_detection_length(self.detection_length)
# PAUL TODO
# IF real runout detected, then detection_length is (kept same | increased a little)?
# if kept same we might not get out of repetative trap of failing quickly.
# so better to increase by a little on each failure (IF automatic)

    # Called to see if state update requires callback notification
    def _handle_filament_event(self, filament_detected):
        if self.filament_detected == filament_detected:
            return
        self.filament_detected = filament_detected
        logging.info("PAUL: RUNOUT EVENT filament_detected: %s **************************************************************" % filament_detected)
        eventtime = self.reactor.monotonic()
        if eventtime < self.min_event_systime or self.detection_mode == self.RUNOUT_DISABLED or not self.enabled:
            # PAUL later add some debug logic here to see if we are called when disabled
            return
        is_printing = self.printer.lookup_object("idle_timeout").get_status(eventtime)["state"] == "Printing"
        if filament_detected:
            if not is_printing and self.insert_gcode is not None:
                # Insert detected
                self.min_event_systime = self.reactor.NEVER
                logging.info("Filament Sensor %s: insert event detected, Time %.2f" % (self.name, eventtime))
                self.reactor.register_callback(self._insert_event_handler)
        else:
            if is_printing and self.runout_gcode is not None:
                # Runout detected
                self.min_event_systime = self.reactor.NEVER
                logging.info("Filament Sensor %s: runout event detected, Time %.2f" % (self.name, eventtime))
                self.reactor.register_callback(self._runout_event_handler)

    def _runout_event_handler(self, eventtime):
        self._exec_gcode(self.runout_gcode)

    def _insert_event_handler(self, eventtime):
        self._exec_gcode(self.insert_gcode)

    def _exec_gcode(self, template):
        try:
            self.gcode.run_script(template.render())
        except Exception:
            logging.exception("Script running error")
        self.min_event_systime = self.reactor.monotonic() + self.event_delay

    def get_clog_detection_length(self):
        return max(self.variables.get(self.VARS_ERCF_CALIB_CLOG_LENGTH, self.detection_length), 5.) # Min 5mmm

    def set_clog_detection_length(self, clog_length):
        clog_length = max(clog_length, 5.)
        self.gcode.run_script_from_command("SAVE_VARIABLE VARIABLE=%s VALUE=%.1f" % (self.VARS_ERCF_CALIB_CLOG_LENGTH, clog_length))
        logging.info("PAUL: Clog detection length changed (and persisted) to %d mm" % round(clog_length))

    def set_mode(self, mode):
        self.detection_mode = mode

    # Callback for MCU_counter
    def _counter_callback(self, time, count, count_time):
        if self._last_time is None:  # First sample
            self._last_time = time
        elif count_time > self._last_time:
            self._last_time = count_time
            new_count = count - self._last_count
            self._counts += new_count
            if new_count > 0 and self.extruder is not None:
                # Tell runout logic about this movement
                self._update_filament_runout_pos(time)
                self._handle_filament_event(True)
        else:  # No counts since last sample
            self._last_time = time

        self._last_count = count

    def get_counts(self):
        return self._counts

    def get_distance(self):
        return (self._counts / 2.) * self._encoder_steps

    def set_distance(self, new_distance):
        self._counts = int((new_distance / self._encoder_steps) * 2.)

    def reset_counts(self):
        self._counts = 0.

    def get_status(self, eventtime):
        return {
                'min_diff_measured': self.min_diff_measured,
                'detetion_length': self.detection_length
                }

def load_config_prefix(config):
    return ErcfEncoder(config)

