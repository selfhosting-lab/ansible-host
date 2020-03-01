#!/usr/bin/env bash
# Author: Ben Fairless <benfairless@gmail.com>
# Description: Useful functions used in SHL scripts

################################################################################
####################### SHARED FUNCTIONS FOR SHL SCRIPTS #######################
################################################################################

# Check if terminal provides colour ouput.
shl_colours() {
  if [[ $(tput colors 2>/dev/null) -lt 8 ]]; then return 1; fi
}

# Colour terminal support
if shl_colours; then
  shl_bold=$(tput bold)
  export shl_bold
  export shl_reset='\033[0m'
  export shl_red='\033[31m'
  export shl_green='\033[32m'
  export shl_yellow='\033[33m'
  export shl_blue='\033[34m'
fi

# Cosmetic pass and fail indicators
export shl_pass="${shl_green}✅${shl_reset}"
export shl_fail="${shl_red}❌${shl_reset}"

# Provides pretty colourful output with timestamps. A label can be set using the
# global variable 'LABEL', and a specific mode can be set by providing an
# argument.
function shl_log() {
  local LABEL="${LABEL^^}"
  local TIMEFMT=${TIMEFMT:-'%H:%M:%S'}
  local RESET="${shl_reset}"
  [[ -n "${LABEL}" ]] && LABEL+=' '
  # Switch color based on argument.
  case ${1} in
      ERROR) local COLOUR="${shl_red}"    ;; # Red
    SUCCESS) local COLOUR="${shl_green}"  ;; # Green
       WARN) local COLOUR="${shl_yellow}" ;; # Yellow
          *) local COLOUR="${shl_blue}"   ;; # Blue
  esac
  # Print output
  IFS=""
  while read -r LINE; do
    echo -e "${COLOUR}${LABEL}[$(date +"${TIMEFMT}")]${RESET} ${LINE}"
  done
}

# Produces bold output.
function shl_say() {
  echo -e "${shl_bold}${*}${shl_reset}"
}

# Adds a line break the same length as $1
function shl_lbr() {
  local WIDTH=${1}
  local SYMBOL=${2:-'-'}
  for ((i = 1; i <= ${#WIDTH}; i++)); do
    printf '%s' "${SYMBOL}"
  done
  printf '\n'
}

# Creates a title which uses bold text and a corresponding line break
function shl_title() {
  shl_say "${1}"
  shl_lbr "${1}" "${2}"
}

# Creates a intro piece
function shl_intro() {
  local SELF="${SELF^^}"
  local VER DESC
  [[ -n "${VERSION}" ]] && VER=" ${VERSION}"
  [[ -n "${1}" ]] && DESC=" - ${1}"
  shl_title "${SELF}${VER}${DESC}"
  echo
}

# Checks that a command exists, and informs the user to install the necessary
# package if necessary. Optionally a second string can be provided if the
# command and package name differ.
function shl_dependency(){
  local SELF=${SELF:-'This script'}
  local RPM=${2:-$1}
  if ! command -v "${1}" >/dev/null 2>&1 && ! rpm -q "${RPM}" >/dev/null; then
    echo "${SELF} requires the '${RPM}' package to be installed." | shl_log ERROR
    exit 1
  fi
}

# Check yo' privilege!
function shl_require_root() {
  local SELF=${SELF:-'This script'}
  if [[ $(id -u) != '0' ]]; then
    echo "You must be root to run ${SELF}." | shl_log ERROR
    exit 1
  fi
}

# Checks if the system is running on a virtualisation platform.
function shl_virtualisation() {
  case $(cat /sys/devices/virtual/dmi/id/sys_vendor) in
    'VMware Virtual Platform') return 0;;
                 'VirtualBox') return 0;;
                        'KVM') return 0;;
                      'BHYVE') return 0;;
                            *) return 1;;
  esac
}
