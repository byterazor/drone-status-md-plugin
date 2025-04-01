#!/bin/bash

if [ -z  ${PLUGIN_FILE} ]; then
    PLUGIN_FILE="status.md"
fi

if [ -n "${PLUGIN_SHOW_TITLE}" ]; then
    export TITLE="### Build Status for Branch ${DRONE_BRANCH}"
else
    export TITLE=""
fi


#
# no parameters below
#

if [ -n "${PLUGIN_SHOW_DATE}" ]; then
    export DATE="Last Build: $(date)"
fi

if [ "${DRONE_BUILD_STATUS}" == "success" ]; then
    export STATUS_COLOR="green"
elif [ "${DRONE_BUILD_STATUS}" == "" ]; then
    export STATUS_COLOR="grey"
    export DRONE_BUILD_STATUS="unknown"
else
    export STATUS_COLOR="red"
fi


echo "Processing ${DRONE_BUILD_EVENT} event ... "

if [ "${DRONE_BUILD_EVENT}"  == "push" -o "${DRONE_BUILD_EVENT}"  == "cron" -o  "${DRONE_BUILD_EVENT}"  == "custom" ]; then
     cat /templates/simple_push.tmpl | envsubst > ${PLUGIN_FILE} 
fi



