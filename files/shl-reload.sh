#!/usr/bin/bash
# Author: Ben Fairless <benfairless@gmail.com>
# Description: Reload services as an alternative to rebooting

# Load SHL functions.
# shellcheck disable=SC1091
source /usr/local/lib/shl
SELF=$(basename "${0}")
COMMAND="${*}"

################################################################################
############################# FUNCTION DEFINITIONS #############################
################################################################################

# Determine if systemd reload is necessary.
function systemd_restart(){
  # The best way to figure this out is to look for deleted file descriptors in
  # use by the init process, as systemd reloads over the top of itself and can't
  # easily be identified as needing reloading.
  if lsof -p 1 | grep 'DEL' >/dev/null; then
    return 0
  else
    return 1
  fi
}

# Return a specific property for a systemd unit, defaults to 'Names'.
function systemd_property(){
  local UNIT=${1}
  local PROPERTY=${2:-'Names'}
  systemctl show "${UNIT}" -p "${PROPERTY}" | sed -nr "s/${PROPERTY}=(.*)/\1/p"
}

# Restart unit as cleanly as possible.
function restart_unit(){
  local UNIT="${1}"
  local DESCRIPTION MESSAGE COMMAND
  DESCRIPTION="${UNIT} - $(systemd_property "${UNIT}")"
  TASK="restart"
  # Carry out different action depending on unit type.
  case ${UNIT} in
                init.scope) COMMAND='systemctl daemon-reexec';;
            auditd.service) # shellcheck disable=SC2016
                            COMMAND='pidof auditd >/dev/null && kill -TERM $(pidof auditd)'"; sleep 1; systemctl start ${UNIT}";;
    NetworkManager.service) COMMAND="systemctl restart ${UNIT}";;
            user@*.service) COMMAND="systemctl stop ${UNIT}"
                            TASK="terminate";;
                 *.service) COMMAND="systemctl try-restart ${UNIT}";;
                   *.scope) COMMAND="systemctl stop ${UNIT}"
                            TASK="terminate";;
                         *) COMMAND='false'
                            TASK="";;
  esac
  # Report back any issues.
  if eval ${COMMAND}; then
    case ${TASK} in
         'restart') echo "Restarted ${DESCRIPTION}" | shl_log SUCCESS;;
       'terminate') echo "Terminated ${DESCRIPTION}" | shl_log SUCCESS;;
    esac
    return 0
  else
    case ${TASK} in
        'restart') echo "Failed to restart ${DESCRIPTION}" | shl_log ERROR;;
      'terminate') echo "Failed to terminate ${DESCRIPTION}" | shl_log ERROR;;
    esac
    return 1
  fi
}

# Present a change summary for units of specific types.
function change_summary(){
  local TYPE="${1}"
  local UNITS MESSAGE
  read -r -a UNITS <<< "${2}"
  if [[ -n "${UNITS[*]}" ]]; then
    case "${TYPE}" in
      'service') MESSAGE='The following SystemD service units need to be restarted:';;
        'scope') MESSAGE='The following SystemD scopes need to be terminated:';;
         'core') MESSAGE='The following core systems need to be restarted:';;
              *) shl_say "Managing ${TYPE} units is not supported." | shl_log WARN; return 1;;
    esac
    shl_title "${MESSAGE}" | shl_log
    for UNIT in "${UNITS[@]}"; do
      echo "${UNIT} - $(systemd_property "${UNIT}" Description)" | shl_log
    done
    echo | shl_log
  fi
}

# Check if a unit contains this process.
function active_session(){
  local PID="${$}"
  local UNIT="${1}"
  if systemd-cgls -u "${UNIT}" --no-pager | grep "${PID}" >/dev/null; then
    return 0
  else
    return 1
  fi
}

# Check if a new kernel is detected, as a reboot may be necessary.
function check_kernel(){
  # [[ ! $(command -v "shl-reboot" 2>/dev/null) ]] && return 0
  if shl-reboot >/dev/null; then
    shl_say "A new kernel was found." | shl_log WARN
    echo "A reboot is required to use the new kernel. It may be better to reboot." | shl_log WARN
    echo "Run 'shl-reboot' to investigate." | shl_log WARN
    echo | shl_log
  fi
}

################################################################################
################################### RUNTIME ####################################
################################################################################

# Print title summary
shl_intro 'Automatically reload services when patches are available' | shl_log

# Check dependencies.
shl_require_root
shl_dependency needs-restarting dnf-utils
shl_dependency pidof procps-ng
shl_dependency lsof

# Check for new kernel first.
check_kernel

# Get all PIDs for processes which have been updated and are marked for restart.
mapfile -t RESTART_PIDS < <(needs-restarting 2>/dev/null | awk '{print $1}')

# If the list of processes is empty, assume no new updates need to be applied to
# any active processes and exit.
if [[ -z "${RESTART_PIDS[*]}" ]] || [[ "${RESTART_PIDS[*]}" == '1' ]]; then
  if ! systemd_restart; then
    echo 'Reload not necessary.' | shl_log SUCCESS
    exit 0
  fi
fi

# Lookup matching unit for each PID.
mapfile -t CANDIDATE_UNITS < <(ps -o unit --no-headers "${RESTART_PIDS[@]}" | sort -u)

# Filter units into types which may need treating differently.
for UNIT in "${CANDIDATE_UNITS[@]}"; do
  case ${UNIT} in
         init.scope) if systemd_restart; then CORE+=("${UNIT}"); fi;;
     auditd.service) CORE+=("${UNIT}");;
    session-*.scope) SESSIONS+=("${UNIT}");;
          *.service) SERVICES+=("${UNIT}");;
            *.scope) SCOPES+=("${UNIT}");;
                  *) UNRECOGNISED+=("${UNIT}")
  esac
done

# Display change summary.
cat <<SUMMARY | shl_log
There are actions that need to be carried out so that changes can be
applied to your system.

Some of these are potentially disruptive as they restart or terminate
processes. Although ${SELF} tries to carry out the actions cleanly,
this should be seen as a quick alternative to a reboot, and is not a
zero-downtime solution.

SUMMARY
change_summary core "${CORE[*]}"
change_summary service "${SERVICES[*]}"
change_summary scope "${SCOPES[*]} ${SESSIONS[*]}"
change_summary other "${UNRECOGNISED[*]}"

# If apply command is not used, provide advice and exit.
if [[ "${COMMAND}" != 'apply' ]]; then
  shl_say "You can apply these changes by running '${SELF} apply'." | shl_log
  exit 0
else
  shl_title 'Applying changes now:' | shl_log
fi

# Merge most units together, as unique behaviours are handled by restart_unit.
UNITS=("${CORE[@]}" "${SERVICES[@]}" "${SCOPES[@]}")
for UNIT in "${UNITS[@]}"; do
  if ! restart_unit "${UNIT}"; then ERRORS='1'; fi
done

# Deal with sessions last as they will kick users out.
for SESSION in "${SESSIONS[@]}"; do
  # Prevent termination of current session.
  if active_session "${SESSION}"; then
    shl_say "${SESSION} will not be terminated and will not pick up changes." | shl_log WARN
    echo "Please exit your current session to terminate ${SESSION}." | shl_log WARN
    echo "If you are using SSH, you should simply disconnect and reconnect." | shl_log WARN
  else
    if ! restart_unit "${SESSION}"; then ERRORS='1'; fi
  fi
done

# If there were errors during the run, exit with an error code.
if [[ "${ERRORS}" == '1' ]]; then
  shl_say "There were issues carrying out some of the tasks. Please review output." | shl_log ERROR
  exit 1
else
  shl_say "Reloading of SystemD units completed successfully." | shl_log SUCCESS
  exit 0
fi
