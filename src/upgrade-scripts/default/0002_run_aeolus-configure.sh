#!/bin/bash

#name: Execute aeolus-configure
#apply: aeolus-conductor
#description: Executes aeolus-configure. Note: this restarts aeolus services. Skip this step if you want to manually run aeolus-configure later.

# default configuration values (should be the same as in our sysv init script)
if [ -f /etc/sysconfig/aeolus-conductor ]; then . /etc/sysconfig/aeolus-conductor; fi

aeolus-configure 2>&1
ret_code=$?

exit $ret_code
