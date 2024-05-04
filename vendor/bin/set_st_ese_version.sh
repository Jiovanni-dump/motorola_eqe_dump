#!/vendor/bin/sh

SCRIPT_NAME="set_st_ese_version.sh"
ESE_DIR="/mnt/vendor/persist/ese"
ST_ESE_VERSION="cqatest_st_ese_version"

debug()
{
    echo "Debug: $*"
}

notice()
{
    echo "Debug: $*"
    echo "$SCRIPT_NAME: $*" > /dev/kmsg
}

create_ese_version_file()
{
    notice "creat cqatest_st_ese_version to perist:"
    mkdir -p $ESE_DIR
    chmod 0775 $ESE_DIR
    chgrp system $ESE_DIR
    touch $ESE_DIR/$ST_ESE_VERSION
    if [ "$?" == "0" ]
    then
        notice "Creat cqatest_st_ese_version to perist done!"
    fi

    chgrp system $ESE_DIR/$ST_ESE_VERSION
    chmod 0666 $ESE_DIR/$ST_ESE_VERSION
}

if [ ! -f "$ESE_DIR/$ST_ESE_VERSION" ]
then
    create_ese_version_file
fi

fsync $ESE_DIR/$ST_ESE_VERSION
