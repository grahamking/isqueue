#!/bin/bash

# This file is part of isqueue: https://github.com/grahamking/isqueue

# Copyright 2011 Graham King <graham@gkgk.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# For the full licence see <http://www.gnu.org/licenses/>.

# isqueue
# Usage: consume.sh -q queue_name script_name
# Example consume.sh -q fetch_thumb "/usr/local/proj/manage.py fetch_thumb"

# Starts command with a single message from the queue
process_single() {
    acquire_lock

    # Read next message from queue
    local param=`head -1 $QUEUE`

    # Remove that message from queue.
    # This has the side effect of triggering incron to start another
    # process, until we reach max process count.
    printf '%s\n' 1d w | ed -s $QUEUE 

    release_lock

    $COMMAND "$param"
}

#
# MAIN
#

ME=`basename $0`
USAGE="Usage: $ME [-p <num_procs>] -q <queue_name> <command>"

QUEUE_DIR=/var/spool/isqueue/
QUEUE_NAME=''

# Max number of processes
PROCS=2

# Parse command line arguments
# See: http://unmaintainable.wordpress.com/2007/08/05/cmdline-options-in-shell-scripts/
while getopts hq:p: OPT; do
    case "$OPT" in
        q)
            QUEUE_NAME=$OPTARG
            ;;
        p)
            PROCS=$OPTARG
            ;;
        h)
            echo $USAGE
            exit 0
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

# Get acquire_lock and release_lock functions
source /usr/local/bin/isq-lockutil.sh

NUM_RUNNING=`/usr/bin/pgrep -c "$ME"`
while [ -s $QUEUE -a $NUM_RUNNING -le $PROCS ]; do
    process_single
    NUM_RUNNING=`/usr/bin/pgrep -c "$ME"`
done

