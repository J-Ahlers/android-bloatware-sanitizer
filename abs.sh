#!/bin/bash
#########################################################
#                                                       #
# Script that can be used to remove all sorts of system #
# bloatware from Android devices. This will also remove #
# apps that can not be uninstalled from the device      #
# itself.                                               #
#                                                       #
#    Version         1.0                                #
#    Author          Jonas Ahlers                       #
#    License         GNU General Public License v3      #
#                                                       #
#########################################################

THIS_DIR="$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
CONFIG_DIR="${THIS_DIR}/config"
OEM_DIR="${CONFIG_DIR}/oem"

function usage() {
    cat << USAGE
Android Bloatware Sanitizer

Usage: abs.sh [OPTIONS]

Options are:
  --help:
    Prints this help menu

  --device <ID>:
    Device ID to be used - required if multple devices are connted.
    To retreive the device ID use 'adb devices'

  --categories <LIST>:
    Categories to be included. Must be separated by commas. Optional.
    By default apps from all categories will be included.

  --skip-oem:
    If passed no OEM bloatware will be removed.

USAGE
}

function delete_list() {
    local file_path=$1
    local device=$2
    local package_list=$3

    if [[ -d "${file_path}" ]]; then
        return
    elif [[ -f "${file_path}" ]]; then
        category=$(basename "${file_path%.cfg}")
        echo "Removing $category bloatware..."
        while IFS='' read -r app || [[ -n "$app" ]]; do
            installed_app=$(echo "${package_list}" | grep -w "^package:${app}")
            if [[ $installed_app =~ .*"package:${app}" ]]; then
                echo "     > Deleting: ${app}"
                #adb "${device}" shell pm uninstall -k --user 0 "${app}"
            fi
        done < "${file_path}"
    else
        echo "[ERROR] Config file not found."
        echo "${file_path}"
        echo ""
        echo "You may be trying to remove bloatware from an unsupported manufacturer."
        echo "Try passing --skip-oem or creating the manufactorer config yourself."
        echo "Further instructions on how to contribute are in the README."
        exit 1
    fi
}


function main() {
    local device=""
    local categories=()
    local excludes=()
    local load_oem_config=true

    while [[ $# -gt 0 ]]; do
        arg="$1"
        shift

        case "${arg}" in
            --help)
                usage
                exit 0
                ;;
            --device)
                device="-s $1"
                shift || (echo "No device-ID given" && exit 1)
                ;;
            --categories)
                IFS=',' read -ra array <<< $1
                for i in "${array[@]}"; do
                    categories+=("${CONFIG_DIR}/${i}.cfg")
                done
                shift || (echo "No category list given" && exit 1)
                ;;
            --exclude-categories)
                IFS=',' read -ra array <<< $1
                for i in "${array[@]}"; do
                    excludes+=("${CONFIG_DIR}/${i}.cfg")
                done
                shift || (echo "No category list given" && exit 1)
                ;;
            --skip-oem)
                load_oem_config=
                ;;
            *)
                usage >&2
                echo "Unknown argument: '${arg}'" && exit 1
                ;;
        esac
    done

    if [ -z "${categories}" ]; then
        echo "Loading available configs..."
        while IFS= read -d $'\0' -r file ; do
            categories=("${categories[@]}" "${file}")
        done < <(find "${CONFIG_DIR}" -maxdepth 1 -print0 -type f)
    fi
    
    if [ "${load_oem_config}" ]; then
        local oem=$(adb ${device} shell getprop ro.product.manufacturer | tr -d '\r')
        if [ $? == 1 ]; then
            echo "Error connecting to device. Passing --device <ID> may help."
            exit 1
        else
            echo "Device manufacturer: ${oem}"
            categories+=("${OEM_DIR}/${oem}.cfg")
        fi
    fi

    package_list=$(adb ${device} shell pm list packages)
    for config in "${categories[@]}"; do
        delete_list "${config}" "${device}" "${package_list}"
    done    
}

main "$@"