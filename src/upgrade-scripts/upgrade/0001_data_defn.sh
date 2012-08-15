#!/bin/bash

#name: Update aeolus-conductor Data Definition
#apply: aeolus-conductor
#description: Adds a role definition to the existing seeded data definition. noop if role is already defined.

# default configuration values (should be the same as in our sysv init script)
if [ -f /etc/sysconfig/aeolus-conductor ]; then . /etc/sysconfig/aeolus-conductor; fi
AEOLUS_HOME=${AEOLUS_HOME:-/usr/share/aeolus-conductor}
AEOLUS_ENV=${AEOLUS_ENV:-production}

SERVICES="postgresql"
for SERVICE in $SERVICES; do
    service $SERVICE start
done


pushd $AEOLUS_HOME >/dev/null
#if data defn has been previously added, this is a noop
RAILS_ENV=$AEOLUS_ENV rake dc:upgrade --trace 2>&1
ret_code=$?
popd >/dev/null

for SERVICE in $SERVICES; do
    service $SERVICE stop
done

exit $ret_code
