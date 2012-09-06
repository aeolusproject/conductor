#!/bin/bash

#name: Execute aeolus-configure
#apply: aeolus-conductor
#description: Executes aeolus-configure, but stops aeolus services before exiting

# default configuration values (should be the same as in our sysv init script)
if [ -f /etc/sysconfig/aeolus-conductor ]; then . /etc/sysconfig/aeolus-conductor; fi

aeolus-configure 2>&1
ret_code=$?
aeolus-services stop
exit $ret_code
