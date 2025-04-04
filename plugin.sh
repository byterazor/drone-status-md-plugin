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
     echo ${TITLE} > ${PLUGIN_FILE} 
     
     if [ -n "${PLUGIN_SHOW_BRANCH}" ]; then
        echo -n "![Static Badge](https://img.shields.io/badge/branch-${DRONE_BRANCH}-blue) " >> ${PLUGIN_FILE} 
     fi
    
    if [ -n "${PLUGIN_SHOW_CICD}" ]; then
        echo -n "![Static Badge](https://img.shields.io/badge/CI--CD-${PLUGIN_SHOW_CICD}-green " >> ${PLUGIN_FILE} 
     fi

     if [ -z "${PLUGIN_USE_STAGES}" ]; then
        echo -n "[![Build Status](https://img.shields.io/badge/Build-${DRONE_BUILD_STATUS}-${STATUS_COLOR})](${DRONE_BUILD_LINK})" >> ${PLUGIN_FILE}
     else
        STAGES=$(echo ${DRONE_STAGE_DEPENDS_ON} | sed 's/,/ /g')
        FAILED=$(echo ${DRONE_FAILED_STAGES} | sed 's/,//g')

        for s in $STAGES; do 
            FOUND=0
            for f in $FAILED; do
                if [ "$f" == "$s" ]; then
                    FOUND=1
                fi
            done

            if [ $FOUND -eq 0 ]; then
                echo -n "[![Build Status](https://img.shields.io/badge/${s}-successful-green)](${DRONE_BUILD_LINK})" >> ${PLUGIN_FILE}
            else
                echo -n "[![Build Status](https://img.shields.io/badge/${s}-failed-red)](${DRONE_BUILD_LINK})" >> ${PLUGIN_FILE}
            fi

        done

     fi
     echo >> ${PLUGIN_FILE}
     echo >> ${PLUGIN_FILE}
     echo $DATE >> ${PLUGIN_FILE}


fi



