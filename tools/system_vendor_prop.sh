#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2020 Sourangshu Ghosh
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/helpers/common_script.sh "y"

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply sytem &/ vendor build.prop as arguements!"
    exit 1
fi

# Get files via either cp or wget
if echo "$1" | grep "https" ; then
    wget -O $PROJECT_DIR/working/system_working.prop $1
elif [ -d "$1" ]; then
    if [ -e "$1"/system/system/build.prop ]; then
        SYSTEM_PATH="system/system"
    elif [ -e "$1"/system/build.prop ]; then
        SYSTEM_PATH="system"
    fi
    find "$1/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/system_working.prop \;
    find "$1/vendor" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/vendor_working.prop \;
else
    cp -a $1 $PROJECT_DIR/working/system_working.prop
fi
if [ ! -z "$2" ] ; then
    if echo "$2" | grep "https" ; then
        wget -O $PROJECT_DIR/working/vendor_working.prop $2
    else
        cp -a $2 $PROJECT_DIR/working/vendor_working.prop
    fi
fi

# system.prop
TSTART=$(grep -nr "# end build properties" $PROJECT_DIR/working/system_working.prop | sed "s|:.*||g")
TSTART=$((TSTART+1))
TEND=$(grep -nr "# ADDITIONAL_BUILD_PROPERTIES" $PROJECT_DIR/working/system_working.prop | sed "s|:.*||g")
TEND=$((TEND-1))
sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/system_working.prop > $PROJECT_DIR/working/system.prop

# vendor.prop
if [ ! -z "$2" ] || [ -d "$1" ]; then
    TSTART=$(grep -nr "ADDITIONAL VENDOR BUILD PROPERTIES" $PROJECT_DIR/working/vendor_working.prop | sed "s|:.*||g")
    TEND=$(wc -l $PROJECT_DIR/working/vendor_working.prop | sed "s| .*||g")
    sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/vendor_working.prop | sort | sed "s|#.*||g" | sed '/^[[:space:]]*$/d' > $PROJECT_DIR/working/vendor_new.prop
    sed -i -e 's/^/    /' $PROJECT_DIR/working/vendor_new.prop
    sed -i '1 i\PRODUCT_PROPERTY_OVERRIDES += ' $PROJECT_DIR/working/vendor_new.prop
    awk 'NF{print $0 " \\"}' $PROJECT_DIR/working/vendor_new.prop > $PROJECT_DIR/working/vendor_prop.mk
fi

# cleanup
rm -rf $PROJECT_DIR/working/system_working.prop $PROJECT_DIR/working/vendor_new.prop $PROJECT_DIR/working/vendor_working.prop

echo -e "$(ls -d $PROJECT_DIR/working/*) prepared!"
