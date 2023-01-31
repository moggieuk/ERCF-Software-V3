#!/bin/bash
KLIPPER_HOME="${HOME}/klipper"
KLIPPER_CONFIG_HOME="${HOME}/klipper_config"
PRINTER_DATA_CONFIG_HOME="${HOME}/printer_data/config"

declare -A PIN 2>/dev/null || {
    echo "Please run this script with ./bash $0"
    exit 1
}

# Pins for Fysetc Burrows ERB board and ERCF EASY-BRD
PIN[ERB,gear_uart_pin]="ercf:gpio20";         PIN[EASY-BRD,gear_uart_pin]="ercf:PA8"
PIN[ERB,gear_step_pin]="ercf:gpio10";         PIN[EASY-BRD,gear_step_pin]="ercf:PA4"
PIN[ERB,gear_dir_pin]="!ercf:gpio9";          PIN[EASY-BRD,gear_dir_pin]="!ercf:PA10"
PIN[ERB,gear_enable_pin]="!ercf:gpio8";       PIN[EASY-BRD,gear_enable_pin]="!ercf:PA2"
PIN[ERB,gear_diag_pin]="ercf:gpio13";         PIN[EASY-BRD,gear_diag_pin]=""
PIN[ERB,gear_endstop_pin]="ercf:gpio24";      PIN[EASY-BRD,gear_endstop_pin]="ercf:PB9"
PIN[ERB,selector_uart_pin]="ercf:gpio17";     PIN[EASY-BRD,selector_uart_pin]="ercf:PA8"
PIN[ERB,selector_step_pin]="ercf:gpio16";     PIN[EASY-BRD,selector_step_pin]="ercf:PA9"
PIN[ERB,selector_dir_pin]="!ercf:gpio15";     PIN[EASY-BRD,selector_dir_pin]="!ercf:PB8"
PIN[ERB,selector_enable_pin]="!ercf:gpio14";  PIN[EASY-BRD,selector_enable_pin]="!ercf:PA11"
PIN[ERB,selector_diag_pin]="ercf:gpio19";     PIN[EASY-BRD,selector_diag_pin]="ercf:PA7"
PIN[ERB,selector_endstop_pin]="ercf:gpio24";  PIN[EASY-BRD,selector_endstop_pin]="ercf:PB9"
PIN[ERB,servo_pin]="ercf:gpio23";             PIN[EASY-BRD,servo_pin]="ercf:PA5"
PIN[ERB,encoder_pin]="ercf:gpio22";           PIN[EASY-BRD,encoder_pin]="ercf:PA6"

# Screen Colors
OFF='\033[0m'             # Text Reset
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
PURPLE='\033[0;35m'       # Purple
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White

B_RED='\033[1;31m'        # Bold Red
B_GREEN='\033[1;32m'      # Bold Green
B_YELLOW='\033[1;33m'     # Bold Yellow
B_CYAN='\033[1;36m'       # Bold Cyan

INFO="${CYAN}"
EMPHASIZE="${B_CYAN}"
ERROR="${B_RED}"
WARNING="${B_YELLOW}"
PROMPT="${CYAN}"
INPUT="${OFF}"

function nextsuffix {
    local name="$1"
    local -i num=0
    while [ -e "$name.0$num" ]; do
        num+=1
    done
    printf "%s.0%d" "$name" "$num"
}

verify_not_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${ERROR}This script must not run as root"
        exit -1
    fi
}

check_klipper() {
    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "klipper.service")" ]; then
        echo -e "${INFO}Klipper service found"
    else
        echo -e "${ERROR}Klipper service not found! Please install Klipper first"
        exit -1
    fi

}

verify_home_dirs() {
    if [ ! -d "${KLIPPER_HOME}" ]; then
        echo -e "${ERROR}Klipper home directory (${KLIPPER_HOME}) not found. Use '-k <dir>' option to override"
        exit -1
    fi
    if [ ! -d "${KLIPPER_CONFIG_HOME}" ]; then
        if [ ! -d "${PRINTER_DATA_CONFIG_HOME}" ]; then
            echo -e "${ERROR}Klipper config directory (${KLIPPER_CONFIG_HOME} or ${PRINTER_DATA_CONFIG_HOME}) not found. Use '-c <dir>' option to override"
            exit -1
        fi
        KLIPPER_CONFIG_HOME="${PRINTER_DATA_CONFIG_HOME}"
    fi
}

link_ercf_plugin() {
    echo -e "${INFO}Linking ercf extension to Klipper..."
    if [ -d "${KLIPPER_HOME}/klippy/extras" ]; then
        ln -sf "${SRCDIR}/extras/ercf.py" "${KLIPPER_HOME}/klippy/extras/ercf.py"
        ln -sf "${SRCDIR}/extras/ercf_servo.py" "${KLIPPER_HOME}/klippy/extras/ercf_servo.py"
    else
        echo -e "${WARNING}ERCF modules not installed because Klipper 'extras' directory not found!"
    fi
}

copy_template_files() {
    if [ "${INSTALL_TEMPLATES}" -eq 0 ]; then
        return
    fi

    echo -e "${INFO}Copying configuration files to ${KLIPPER_CONFIG_HOME}"
    for file in `cd ${SRCDIR} ; ls *.cfg`; do
        dest=${KLIPPER_CONFIG_HOME}/${file}

        if test -f $dest; then
            next_dest="$(nextsuffix "$dest")"
            echo -e "${INFO}Config file ${file} already exists - moving old one to ${next_dest}"
            mv ${dest} ${next_dest}
        fi

        if [ "${file}" == "ercf_hardware.cfg" ]; then
            if [ "${toolhead_sensor}" -eq 1 ]; then
                magic_str1="## ERCF Toolhead sensor"
            else
                magic_str1="NO TOOLHEAD"
            fi
            if [ "${clog_detection}" -eq 1 ]; then
                magic_str2="## ERCF Clog detection"
            else
                magic_str2="NO CLOG"
            fi
	    uart_comment=""
            if [ "${brd_type}" == "ERB" ]; then
	        uart_comment="#"
            fi

            if [ "${sensorless_selector}" -eq 1 ]; then
                cat ${SRCDIR}/${file} | sed -e "\
                    s/^#endstop_pin: \^{gear_endstop_pin}/endstop_pin: \^{gear_endstop_pin}/; \
                    s/^#diag_pin: \^{selector_diag_pin}/diag_pin: \^{selector_diag_pin}/; \
                    s/^#driver_SGTHRS: 75/driver_SGTHRS: 75/; \
                    s/^endstop_pin: \^{selector_endstop_pin}/#endstop_pin: \^{selector_endstop_pin}/; \
                    s/^#endstop_pin: tmc2209_selector_stepper/endstop_pin: tmc2209_selector_stepper/; \
                    s/^uart_address:/${uart_comment}uart_address:/; \
                    s/{brd_type}/${brd_type}/; \
                        " > ${dest}.tmp
            else
                # This is the default template config without sensorless selector homing enabled
                cat ${SRCDIR}/${file} | sed -e "\
                    s/^uart_address:/${uart_comment}uart_address:/; \
                        " > ${dest}.tmp
	    fi

            # Now substitute pin tokens for correct brd_type
            if [ "${brd_type}" == "unknown" ]; then
                cat ${dest}.tmp | sed -e "\
                    s/{toolhead_sensor_pin}/${toolhead_sensor_pin}/; \
                    s%{serial}%${serial}%; \
                    /^${magic_str1} START/,/${magic_str1} END/ s/^#//; \
                    /^${magic_str2} START/,/${magic_str2} END/ s/^#//; \
                        " > ${dest} && rm ${dest}.tmp
            else
                cat ${dest}.tmp | sed -e "\
                    s/{gear_uart_pin}/${PIN[$brd_type,gear_uart_pin]}/; \
                    s/{gear_step_pin}/${PIN[$brd_type,gear_step_pin]}/; \
                    s/{gear_dir_pin}/${PIN[$brd_type,gear_dir_pin]}/; \
                    s/{gear_enable_pin}/${PIN[$brd_type,gear_enable_pin]}/; \
                    s/{gear_diag_pin}/${PIN[$brd_type,gear_diag_pin]}/; \
                    s/{gear_endstop_pin}/${PIN[$brd_type,gear_endstop_pin]}/; \
                    s/{selector_uart_pin}/${PIN[$brd_type,selector_uart_pin]}/; \
                    s/{selector_step_pin}/${PIN[$brd_type,selector_step_pin]}/; \
                    s/{selector_dir_pin}/${PIN[$brd_type,selector_dir_pin]}/; \
                    s/{selector_enable_pin}/${PIN[$brd_type,selector_enable_pin]}/; \
                    s/{selector_diag_pin}/${PIN[$brd_type,selector_diag_pin]}/; \
                    s/{selector_endstop_pin}/${PIN[$brd_type,selector_endstop_pin]}/; \
                    s/{servo_pin}/${PIN[$brd_type,servo_pin]}/; \
                    s/{encoder_pin}/${PIN[$brd_type,encoder_pin]}/; \
                    s/{toolhead_sensor_pin}/${toolhead_sensor_pin}/; \
                    s%{serial}%${serial}%; \
                    /^${magic_str1} START/,/${magic_str1} END/ s/^#//; \
                    /^${magic_str2} START/,/${magic_str2} END/ s/^#//; \
                        " > ${dest} && rm ${dest}.tmp
            fi
        elif [ "${file}" == "ercf_software.cfg" ]; then
            cat ${SRCDIR}/${file} | sed -e "\
                s%{klipper_config_home}%${KLIPPER_CONFIG_HOME}%g; \
                    " > ${dest}
        else
            # Other config files (not ercf_hardware.cfg, ercf_software.cfg, ercf_display_menu.cfg)
            if [ "${brd_type}" == "unknown" ]; then
                cp ${SRCDIR}/${file} ${dest}.tmp
            else
                cat ${SRCDIR}/${file} | sed -e "\
                    s/{encoder_pin}/${PIN[$brd_type,encoder_pin]}/g; \
                        " > ${dest}.tmp
            fi
            cat ${dest}.tmp | sed -e "\
                s/{sensorless_selector}/${sensorless_selector}/g; \
                s/{clog_detection}/${clog_detection}/g; \
                s/{endless_spool}/${endless_spool}/g; \
                s/{servo_up_angle}/${servo_up_angle}/g; \
                s/{servo_down_angle}/${servo_down_angle}/g; \
                s/{calibration_bowden_length}/${calibration_bowden_length}/g; \
                    " > ${dest} && rm ${dest}.tmp
        fi
    done

    if [ "${INSTALL_TEMPLATES}" -eq 1 ]; then
        if [ "${add_includes}" -eq 1 ]; then
            # Link in all includes if not already present
            dest=${KLIPPER_CONFIG_HOME}/printer.cfg
            if test -f $dest; then
                next_dest="$(nextsuffix "$dest")"
                echo -e "${INFO}Copying original printer.cfg file to ${next_dest}"
                cp ${dest} ${next_dest}
                if [ ${menu_12864} -eq 1 ]; then
                    i='\[include ercf_menu.cfg\]'
                    already_included=$(grep -c "${i}" ${dest} || true)
                    if [ "${already_included}" -eq 0 ]; then
                        sed -i "1i ${i}" ${dest}
                    fi
                fi
                for i in \
                        '\[include client_macros.cfg\]' \
                        '\[include ercf_software.cfg\]' \
                        '\[include ercf_parameters.cfg\]' \
                        '\[include ercf_hardware.cfg\]' ; do
                    already_included=$(grep -c "${i}" ${dest} || true)
                    if [ "${already_included}" -eq 0 ]; then
                        sed -i "1i ${i}" ${dest}
                    fi
                done
            else
                echo -e "${WARNING}File printer.cfg file not found! Cannot include ERCF configuration files"
            fi
        fi
    fi
}

install_update_manager() {
    echo -e "${INFO}Adding update manager to moonraker.conf"
    if [ -f "${KLIPPER_CONFIG_HOME}/moonraker.conf" ]; then
        update_section=$(grep -c '\[update_manager ercf-happy_hare\]' \
        ${KLIPPER_CONFIG_HOME}/moonraker.conf || true)
        if [ "${update_section}" -eq 0 ]; then
            echo "" >> ${KLIPPER_CONFIG_HOME}/moonraker.conf
            while read -r line; do
                echo -e "${line}" >> ${KLIPPER_CONFIG_HOME}/moonraker.conf
            done < "${SRCDIR}/moonraker_update.txt"
            echo "" >> ${KLIPPER_CONFIG_HOME}/moonraker.conf
            restart_moonraker
        else
            echo -e "${INFO}[update_manager ercf] already exist in moonraker.conf - skipping install"
        fi
    else
        echo -e "${WARNING}Moonraker.conf not found!"
    fi
}

restart_klipper() {
    echo -e "${INFO}Restarting Klipper..."
    sudo systemctl restart klipper
}

restart_moonraker() {
    echo -e "${INFO}Restarting Moonraker..."
    sudo systemctl restart moonraker
}

prompt_yn() {
    while true; do
        read -p "$@ (y/n)?" yn
        case "${yn}" in
            Y|y|Yes|yes)
		echo "y" 
                break;;
            N|n|No|no)
		echo "n" 
    	        break;;
    	    *)
		;;
        esac
    done
}

# Force script to exit if an error occurs
set -e
clear

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/ && pwd )"

INSTALL_TEMPLATES=0
while getopts "k:c:i" arg; do
    case $arg in
        k) KLIPPER_HOME=$OPTARG;;
        c) KLIPPER_CONFIG_HOME=$OPTARG;;
        i) INSTALL_TEMPLATES=1;;
    esac
done

verify_not_root
verify_home_dirs
check_klipper
link_ercf_plugin

if [ "${INSTALL_TEMPLATES}" -eq 1 ]; then
    echo
    echo -e "${INFO}Let me see if I can help you with initial config (you will still have some manual config to perform)...${INPUT}"
    echo
    brd_type="unknown"
    yn=$(prompt_yn "Are you using the EASY-BRD or Fysetc Burrows ERB controller?")
    case $yn in
        y)
            echo -e "${INFO}Great, I can setup almost everything for you. Let's get started"
            serial=""
            echo
            for line in `ls /dev/serial/by-id | egrep "Klipper_samd21|Klipper_rp2040"`; do
                if echo ${line} | grep --quiet "Klipper_samd21"; then
                    brd_type="EASY-BRD"
                else
                    brd_type="ERB"
		fi
                echo -e "${PROMPT}This looks like your ${EMPHASIZE}${brd_type}${PROMPT} controller serial port. Is that correct?${INPUT}"
		yn=$(prompt_yn "/dev/serial/by-id/${line}")
                case $yn in
                    y)
                        serial="/dev/serial/by-id/${line}"
                        break
                        ;;
                    n)
                        brd_type="unknown"
                        ;;
                esac
            done
            if [ "${serial}" == "" ]; then
		echo
                echo -e "${PROMPT}Couldn't find your serial port, but no worries - I'll configure the default and you can manually change later${INPUT}"
		yn=$(prompt_yn "Setup for EASY-BRD? (Answer 'N' for Fysetc Burrows ERB)")
                case $yn in
                    y)
                        brd_type="EASY-BRD"
                        ;;
                    n)
                        brd_type="ERB"
                        ;;
                esac
                serial='/dev/ttyACM1 # Config guess. Run ls -l /dev/serial/by-id and set manually'
	    fi

            echo
            echo -e "${PROMPT}Sensorless selector operation? This allows for additional selector recovery steps but disables the 'extra' input on the EASY-BRD.${INPUT}"
            yn=$(prompt_yn "Enable sensorless selector operation")
            case $yn in
                y)
                    if [ "${brd_type}" == "EASY-BRD" ]; then
                        echo
	                echo -e "${WARNING}    IMPORTANT: Set the J6 jumper pins to 2-3 and 4-5, i.e. .[..][..]  MAKE A NOTE NOW!!"
		    fi
	            sensorless_selector=1
                    ;;
                n)
                    if [ "${brd_type}" == "EASY-BRD" ]; then
                        echo
	                echo -e "${WARNING}    IMPORTANT: Set the J6 jumper pins to 1-2 and 4-5, i.e. [..].[..]  MAKE A NOTE NOW!!"
		    fi
	            sensorless_selector=0
                    ;;
	    esac
            ;;

        n)
            easy_brd=0
            echo -e "${INFO}Ok, I can only partially setup non EASY-BRD/ERB installations, but lets see what I can help with"
            serial=""
            echo
            for line in `ls /dev/serial/by-id`; do
                echo -e "${PROMPT}Is this the serial port to your ERCF mcu?${INPUT}"
		yn=$(prompt_yn "/dev/serial/by-id/${line}")
                case $yn in
                    y)
                        serial="/dev/serial/by-id/${line}"
                        break
                        ;;
                    n)
                        ;;
                esac
            done
            if [ "${serial}" = "" ]; then
                echo -e "${INFO}Couldn't find your serial port, but no worries - I'll configure the default and you can manually change later as per the docs"
                serial='/dev/ttyACM1 # Config guess. Run ls -l /dev/serial/by-id and set manually'
	    fi

            echo
            echo -e "${PROMPT}Sensorless selector operation? This allows for additional selector recovery steps${INPUT}"
            yn=$(prompt_yn "Enable sensorless selector operation")
            case $yn in
                y)
	            sensorless_selector=1
                    ;;
                n)
	            sensorless_selector=0
                    ;;
	    esac
	    ;;
    esac

    echo
    echo -e "${PROMPT}Do you have a toolhead sensor you would like to use? If reliable this provides the smoothest and most reliable loading and unloading operation${INPUT}"
    yn=$(prompt_yn "Enable toolhead sensor")
    case $yn in
	y)
	    toolhead_sensor=1
	    echo -e "${PROMPT}    What is the mcu pin name that your toolhead sensor is connected too?"
	    echo -e "${PROMPT}    If you don't know just hit return, I can enter a default and you can change later${INPUT}"
            read -p "    Toolhead sensor pin name? " toolhead_sensor_pin
            if [ "${toolhead_sensor_pin}" = "" ]; then
                toolhead_sensor_pin="{dummy_pin_must_set_me}"
            fi
            ;;
        n)
	    toolhead_sensor=0
            toolhead_sensor_pin="{dummy_pin_must_set_me}"
            ;;
    esac

    echo
    echo -e "${PROMPT}Using default MG-90S servo? (Answer 'N' for Savox SH0255MG, you can always change it later)${INPUT}"
    yn=$(prompt_yn "MG-90S Servo?")
    case $yn in
        y)
	    servo_up_angle=30
	    servo_down_angle=140
            ;;
        n)
	    servo_up_angle=140
	    servo_down_angle=30
            ;;
    esac

    echo
    echo -e "${PROMPT}Clog detection? This uses the ERCF encoder movement to detect clogs and can call your filament runout logic${INPUT}"
    yn=$(prompt_yn "Enable clog detection")
    case $yn in
        y)
            clog_detection=1
            ;;
        n)
            clog_detection=0
            ;;
    esac

    echo
    echo -e "${PROMPT}EndlessSpool? This uses filament runout detection to automate switching to new spool without interruption${INPUT}"
    yn=$(prompt_yn "Enable EndlessSpool")
    case $yn in
        y)
            endless_spool=1
            if [ "${clog_detection}" -eq 0 ]; then
                echo
                echo -e "${WARNING}    NOTE: I've re-enabled clog detection which is necessary for EndlessSpool to function"
                clog_detection=1
            fi
            ;;
        n)
	    endless_spool=0
           ;;
    esac

    echo
    echo -e "${PROMPT}What is the length of your reverse bowden tube in mm?"
    echo -e "${PROMPT}(This is just to speed up calibration and needs to be approximately right but not longer than the real length)${INPUT}"
    while true; do
        read -p "Reverse bowden length in mm? " calibration_bowden_length
        if ! [ "${calibration_bowden_length}" -ge 1 ] 2> /dev/null ;then
            echo -e "${INFO}Positive integer value only"
       else
           break
       fi
    done

    echo
    menu_12864=0
    echo -e "${PROMPT}Finally, would you like me to include all the ERCF config files into your printer.cfg file${INPUT}"
    yn=$(prompt_yn "Add include?")
    case $yn in
        y)
            add_includes=1
            echo -e "${PROMPT}    Would you like to include Mini 12864 menu configuration extension for ERCF${INPUT}"
            yn=$(prompt_yn "    Include menu")
            case $yn in
                y)
                    menu_12864=1
                    ;;
                n)
        	    menu_12864=0
                   ;;
            esac
            ;;
        n)
	    add_includes=0
           ;;
    esac

    echo
    echo -e "${INFO}"
    echo "    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    echo
    echo "    NOTES:"
    echo "     What still needs to be done:"
    if [ "${brd_type}" == "unknown" ]; then
        echo "     * Edit *.cfg files and substitute all \{xxx\} tokens to match or setup"
        echo "     * Review all pin configuration and change to match your mcu"
    else
        echo "     * Tweak motor speeds and current, especially if using non BOM motors"
        echo "     * Adjust motor direction with '!' on pin if necessary. No way to know here"
    fi
    echo "     * Adjust your config for loading and unloading preferences"
    echo "     * Adjust toolhead distances 'home_to_extruder' for your particular setup"
    echo 
    echo "    Advanced:"
    echo "         * Tweak configurations like speed and distance in ercf_parameter.cfg"
    echo 
    echo "    Good luck! ERCF is complex to setup. Remember Discord is your friend.."
    echo
    echo "    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    echo

fi

copy_template_files
install_update_manager
restart_klipper

echo -e "${EMPHASIZE}"
echo "Done.  Enjoy ERCF (and thank you Ette for a wonderful design)..."
echo -e "${INFO}"
echo '(\_/)'
echo '( *,*)'
echo '(")_(") ERCF Ready'
echo
