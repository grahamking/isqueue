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

# lockfile-create and lockfile-remove are in package lockfile-progs in Debian / Ubuntu

acquire_lock() {

    lockfile-create --use-pid --quiet --retry 0 $QUEUE 
    while [ $? -ne 0 ]; do
        sleep 0.05
        lockfile-create --use-pid --quiet --retry 0 $QUEUE 
    done
}

release_lock() {
    lockfile-remove $QUEUE
}

