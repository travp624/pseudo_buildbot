#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
BUILD_ROOT=`pwd`

# OTAUPDATECENTER
USERID=userid
ROMID=romid
NOW=$(date +"%Y%m%d-%H%M)
CHANGELOG=$(cat $BUILD_ROOT/changelog.xml)
if [[ "$2" == "tf201" ]]
        then
        ROMID=816
elif [[ "$2" == "toro" ]]
        then
        ROMID=797
elif [[ "$2" == "maguro" ]]
        then
        ROMID=798
elif [[ "$2" == "SCH-I500" ]]
        then
        ROMID=829
elif [[ "$2" == "SGH-I897" ]]
        then
        ROMID=801
elif [[ "$2" == "crespo4g" ]]
        then
        ROMID=803
elif [[ "$2" == "grouper" ]]
        then
        ROMID=804
elif [[ "$2" == "d2tmo" ]]
        then
        ROMID=805
elif [[ "$2" == "GT-I9000" ]]
        then
        ROMID=813
elif [[ "$2" == "endeavoru" ]]
        then
        ROMID=812
elif [[ "$2" == "d2vzw" ]]
        then
        ROMID=811
elif [[ "$2" == "toroplus" ]]
        then
        ROMID=810
elif [[ "$2" == "espressowifi" ]]
        then
        ROMID=814
elif [[ "$2" == "stingray" ]]
        then
        ROMID=818
elif [[ "$2" == "tf300t" ]]
        then
        ROMID=819
elif [[ "$2" == "SGH-T959" ]]
        then
        ROMID=820
elif [[ "$2" == "d2spr" ]]
        then
        ROMID=847
elif [[ "$2" == "crespo" ]]
        then
        ROMID=850
else
echo "$2 unsupported, you need to add it to the script."
exit
fi









cd $BUILD_ROOT
. build/envsetup.sh
lunch $1

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')

# bacon check
if [ "$(grep -m 1 bacon build/envsetup.sh)" = "" ]; then
    echo "Y U NO MAKE BACON?!"
    BACON=false
else
    BACON=true
fi

# create log dir if not already present
if test ! -d "$ANDROID_PRODUCT_OUT"
    echo "$ANDROID_PRODUCT_OUT doesn't exist, creating now"
    then mkdir -p "$ANDROID_PRODUCT_OUT"
fi

# build
if [ "$BACON" = "true" ]; then
    make -j$(($(grep processor /proc/cpuinfo | wc -l) * 2)) bacon 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log
else
    make -j$(($(grep processor /proc/cpuinfo | wc -l) * 2)) otapackage 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log
fi

# clean out of previous zip
if [ "$BACON" = "true" ]; then
    ZIP=$(tail -2 "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
else
    ZIP=$(grep "Package OTA" "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f5 -d '/')
fi
OUTD=$(echo $(cd ../upload && pwd))
rm $OUTD/$ZIP
cp "$ANDROID_PRODUCT_OUT"/$ZIP $OUTD/$ZIP

# finish
echo "$2 build complete"

# md5sum list
cd $OUTD
md5sum $ZIP | cat >> md5sum
MD5=$(cat md5sum)


# upload
echo "checking on upload reference file"

BUILDBOT=$BUILD_ROOT/vendor/$TARGET_VENDOR/bot/
cd $BUILDBOT
if test -x upload ; then
    echo "Upload file exists, executing now"
    cp upload $OUTD
    cd $OUTD
    # device and zip names are passed on for upload
    ./upload $2 $ZIP && rm upload
    # Update rom on OTAUpdateCenter
    ./update_rominfo.sh -u $USERID -r $ROMID -d $2 -m $MD5 -l http://bakedrom.backupuser.com/$2/$ZIP -v $3 -t $NOW -c "$CHANGELOG"
else
    echo "No upload file found (or set to +x), build complete."
fi

cd $BUILD_ROOT
