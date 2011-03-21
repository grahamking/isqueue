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
# Usage: produce.sh queue_name "message"
#

QUEUE=/var/spool/isqueue/$1.queue

source /usr/local/bin/isq-lockutil.sh

acquire_lock
echo $2 >> $QUEUE
release_lock
