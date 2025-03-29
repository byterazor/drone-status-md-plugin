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
if [ "${DRONE_BUILD_STATUS}" == "success" ]; then
    export STAUS_COLOR="green"
elif [ "${DRONE_BUILD_STATUS}" == "" ]; then
    export STATUS_COLOR="grey"
    export DRONE_BUILD_STATUS="unknown"
else
    export STATUS_COLOR="red"
fi


if [ "${DRONE_BUILD_EVENT}"  == "push" ]; then
    echo "Processing push event ... "
    cat templates/simple_push.tmpl | envsubst > ${PLUGIN_FILE} 
elif [ "${DRONE_BUILD_EVENT}"  == "pull_request" ]; then
    echo "Processing pull request ... "
else 
    echo "Proessing tag"
fi




