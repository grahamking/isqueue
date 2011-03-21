#!/bin/bash

# isqueue
# Usage: produce.sh queue_name "message"
#

QUEUE_DIR=/var/spool/isqueue/
QUEUE=${QUEUE_DIR}/$1.queue

#LOCK=${QUEUE_DIR}/$1.lock

#while [ -f $LOCK ]
#do
#    sleep 0.1
#done

echo $2 >> $QUEUE

