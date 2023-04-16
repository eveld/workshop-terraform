#!/bin/bash -x
stderr_log="/dev/shm/stderr.log"

set -o pipefail
set -o errtrace
set -o nounset
set -o errexit
set -o functrace

exec 2>"$stderr_log"

# Check if exact command was executed
command_executed() {
    COMMAND=$1
    HISTORY=""

    # Based on shell, get history
    shell=$(basename $SHELL)
    case $shell in
        "bash")
            HISTORY=$(cat ~/.bash_history)
            ;;
        "zsh")
            HISTORY=$(awk -F';' '{print $NF}' ~/.zsh_history) 
            ;;
        *)
            ;;
    esac

    # Check if command exists in the history
    RESULT=$(echo "$HISTORY" | grep "$COMMAND")
    if [ -z $RESULT ]; then
        return 1
    else
        return 0
    fi
}

command_executed_with_parameters() {
    echo "not implemented yet"
}

# Check if file exists
file_exists() {
    FILE=$1
    test -f "$FILE"
}

# Check if file contains value
file_contains() {
    FILE=$1
    LINE=$2

    RESULT=$(cat "$FILE" | grep "$LINE")
    if [ -z $RESULT ]; then
        return 1
    else
        return 0
    fi
}

# Check if file contains line exactly
file_contains_line() {
    FILE=$1
    LINE=$2

    RESULT=$(cat "$FILE" | grep -x "$LINE")
    echo $RESULT
    if [ -z $RESULT ]; then
        return 1
    else
        return 0
    fi
}

output_contains() {
    while read -r value; do
        RESULT=$(echo $value | grep -q -i "$1"; echo $?)
        if [ $RESULT -eq 0 ]; then
            return 0
        fi
    done
    return 1
}

# Output a failure message and exit with code 254
failure_and_exit() {
    failure_message="$1"
    failure_lineno="${BASH_LINENO}"
    jq -nc \
        --arg failure_message "$1" \
        --arg failure_lineno "$failure_lineno" \
        '{
            status: "failure",
            message: $failure_message,
            details: {
              line: $failure_lineno
            }
        }'
    exit 254
}

# Output a success message and exit with code 0
success_and_exit() {
    jq -nc \
        '{
            status: "success",
            message: "validation successful"
        }'
    exit 0
}

# Capture any errors and output them with debug information
exit_handler () {
    local error_code="$1"
    local error_lineno="$2"
    local error_command="$3"
    local error_source="$4"
    local error_caller="${FUNCNAME[-1]}"
    local error_message='unknown'
      
    case $error_code in
      0)
        exit 0
        ;;
      254)
        exit 1
        ;;
    esac

    # Check if there is an error
    if test -f "$stderr_log"
        then
            stderr=$(tail "$stderr_log")
            rm "$stderr_log"
    fi

    if test -n "$stderr"
        then
            stderr_parts=( $stderr )
            error_command=${stderr_parts[0]%":"}
            error_message="${stderr_parts[@]:1}"
    fi

    # Get a stack trace
    error_trace=$(backtrace)

    # Format the error as JSON
    jq -nc \
        --arg error_code "$error_code" \
        --arg error_lineno "$error_lineno" \
        --arg error_command "$error_command" \
        --arg error_source "$error_source" \
        --arg error_caller "$error_caller" \
        --arg error_message "$error_message" \
        --argjson error_trace "$error_trace" \
        '{
            status: "error",
            message: "something went wrong while validating",
            details: {
                code: $error_code,
                line: $error_lineno, 
                command: $error_command,
                source: $error_source,
                caller: $error_caller,
                message: $error_message,
                trace: $error_trace | reverse
            }
        }'
}

# Get a backtrace of calls that lead to the error
backtrace() {
    local i=1
    local first=false
    local steps=$(jq -n '[]')
    while read trace_line trace_caller trace_file < <(caller "$i")
    do
        steps=$(echo $steps | jq -c \
            --arg trace_line "$trace_line" \
            --arg trace_caller "$trace_caller" \
            --arg trace_file "$trace_file" \
            '. += [{ 
                line: $trace_line, 
                caller: $trace_caller, 
                file: $trace_file 
            }]')
        ((i=i+1))
    done
    echo $steps
}

trap 'exit_handler "${?}" "${BASH_LINENO}" "${BASH_COMMAND}" "${BASH_SOURCE}"' EXIT
trap exit ERR