#!/bin/bash

# isqueue
# Usage: consume.sh -q queue_name script_name
# Example consume.sh -q fetch_thumb "/usr/local/proj/manage.py fetch_thumb"

acquire_lock() {

    if [ $IS_LOCK -eq 0 ]; then
        return
    fi

    while [ -f $LOCK ]; do
        sleep 0.1
    done
    touch $LOCK
}

release_lock() {
    if [ $IS_LOCK -eq 0 ]; then
        return
    fi

    rm $LOCK
}

# Starts command with a single message from the queue
process_single() {
    acquire_lock

    # Read next message from queue
    local param=`head -1 $QUEUE`

    # Remove that message from queue
    # This has the side effect of triggering incron to start another
    # process, until we reach max process count
    printf '%s\n' 1d w | ed -s $QUEUE 

    release_lock

    echo $COMMAND "$param"
    $COMMAND "$param"
}

#
# MAIN
#

ME=`basename $0`
USAGE="Usage: $ME [-nl] [-p <num_procs>] -q <queue_name> <command>"

QUEUE_DIR=/var/spool/isqueue/
QUEUE_NAME=''

# Lock access to the queue? Defaults to false.
IS_LOCK=0

# Max number of processes
PROCS=2

# Parse command line arguments
# See: http://unmaintainable.wordpress.com/2007/08/05/cmdline-options-in-shell-scripts/
while getopts lhq:p: OPT; do
    case "$OPT" in
        h)
            echo $USAGE
            exit 0
            ;;
        l)
            IS_LOCK=1
            ;;
        q)
            QUEUE_NAME=$OPTARG
            ;;
        p)
            PROCS=$OPTARG
            ;;
        \?)
            # getopts issues an error message
            echo $USAGE >&2
            exit 1
            ;;
    esac
done

# Remove the switches we parsed above.
shift `expr $OPTIND - 1`

# We want at least one non-option argument.
if [ $# -eq 0 ]; then
    echo $USAGE >&2
    exit 1
fi

# Last remaining param must be command to run
COMMAND=$1

QUEUE=${QUEUE_DIR}${QUEUE_NAME}.queue
LOCK=${QUEUE_DIR}${QUEUE_NAME}.lock

NUM_RUNNING=`pgrep -c "$ME"`
while [ -s $QUEUE -a $NUM_RUNNING -le $PROCS ]; do
    process_single
    NUM_RUNNING=`pgrep -c "$ME"`
done

