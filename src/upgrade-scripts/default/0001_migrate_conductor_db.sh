#!/bin/bash

#name: Migrate aeolus-conductor rails database
#apply: aeolus-conductor
#description: Executes rake db:migrate for the aeolus-conductor database

# default configuration values (should be the same as in our sysv init script)
if [ -f /etc/sysconfig/aeolus-conductor ]; then . /etc/sysconfig/aeolus-conductor; fi
AEOLUS_HOME=${AEOLUS_HOME:-/usr/share/aeolus-conductor}
AEOLUS_ENV=${AEOLUS_ENV:-production}

SERVICES="postgresql"
for SERVICE in $SERVICES; do
    service $SERVICE start
done


pushd $AEOLUS_HOME >/dev/null
RAILS_ENV=$AEOLUS_ENV rake db:migrate --trace 2>&1
ret_code=$?
popd >/dev/null

for SERVICE in $SERVICES; do
    service $SERVICE stop
done

exit $ret_code
