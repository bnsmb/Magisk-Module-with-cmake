#
# Customization script for the Magisk Module with cmake 
#
# History
#   30.09.2024 /bs
#     initial release
#   28.12.2024 /bs
#     added code to decompress compressed executables in the Magisk Module
#
#
#
# Notes:
#
# This Magisk Module contains files for arm64 CPUs
#
# Documentation for creating Magisk Modules: https://topjohnwu.github.io/Magisk/guides.html
#
# Environment variables that can be used:
#
#    MAGISK_VER (string): the version string of current installed Magisk (e.g. v20.0)
#    MAGISK_VER_CODE (int): the version code of current installed Magisk (e.g. 20000)
#    BOOTMODE (bool): true if the module is being installed in the Magisk app
#    MODPATH (path): the path where your module files should be installed
#    TMPDIR (path): a place where you can temporarily store files
#    ZIPFILE (path): your module’s installation zip
#    ARCH (string): the CPU architecture of the device. Value is either arm, arm64, x86, or x64
#    IS64BIT (bool): true if $ARCH is either arm64 or x64
#    API (int): the API level (Android version) of the device (e.g. 21 for Android 5.0)
#

# -----------------------------------------------------------------------------

# define constants
#
__TRUE=0
__FALSE=1


if [ 0 = 1 -o -f /data/local/tmp/debug  ] ; then
  exec 1>/data/local/tmp/customize.log 2>&1
  set -x
fi

# -----------------------------------------------------------------------------
# init global variables
#

MODULE_VERSION="$( grep "^version=" $MODPATH/module.prop  | cut -f2 -d "=" )"

CMD_PARAMETER=""

# -----------------------------------------------------------------------------

function LogMsg {
  ui_print "$*"
}

function LogInfo {
  LogMsg "INFO: $*"
}

function LogWarning {
  LogMsg "WARNING: $*"
}

function LogError {
  LogMsg "ERROR: $*"
}


# -----------------------------------------------------------------------------

LogMsg "The current environment for this installation is"

LogMsg "The version of the installed Magisk is \"${MAGISK_VER}\" (${MAGISK_VER_CODE})"

LogInfo "BOOTMODE is \"${BOOTMODE}\" "
LogInfo "MODPATH is \"${MODPATH}\" "
LogInfo "TMPDIR is \"${TMPDIR}\" "
LogInfo "ZIPFILE is \"${ZIPFILE}\" "
LogInfo "ARCH is \"${ARCH}\" "
LogInfo "IS64BIT is \"${IS64BIT}\" "
LogInfo "API is \"${API}\" "

# -----------------------------------------------------------------------------

# example output for the variables:


#  The version of the installed Magisk is "25.0" (25000)
#  INFO: BOOTMODE is "true" 
#  INFO: MODPATH is "/data/adb/modules_update/PlayStore_for_MicroG" 
#  INFO: TMPDIR is "/dev/tmp" 
#  INFO: ZIPFILE is "/data/user/0/com.topjohnwu.magisk/cache/flash/install.zip" 
#  INFO: ARCH is "arm64" 
#  INFO: IS64BIT is "true" 
#  INFO: API is "32"


# -----------------------------------------------------------------------------

LogMsg "Installing the Magisk Module with cmake \"${MODULE_VERSION}\" ..."

# LogMsg "Checking the OS configuration ..."

ERRORS_FOUND=${__FALSE}

MACHINE_TYPE="$( uname -m )"

# check the current CPU
#
LogMsg "Checking the type of the CPU used in this device ...."
LogMsg "The CPU in this device is a ${ARCH} CPU"
LogMsg "The machine type reported by \"uname -m\" is \"${MACHINE_TYPE}\" "


if [ "${ARCH}"x != "arm64"x ] ; then
  abort "This Magisk module is for arm64 CPUs only"
fi

# ---------------------------------------------------------------------

ls -l ${MODPATH}/system/usr/bin/*.gz 2>/dev/null 1>/dev/null
if [ $? -eq 0 ] ; then
  LogMsg "Decompressing the compressed executables in \"${MODPAT}/usr/bin\" ..."
  chmod 755 ${MODPATH}/gzip
  for CUR_FILE in ${MODPATH}/system/usr/bin/*.gz ; do
    LogMsg "Decompressing the file \"${CUR_FILE}\" ..."
    ${MODPATH}/gzip -d "${CUR_FILE}"
  done
else
  LogMsg "INFO: No compressed executables found"
fi

LogMsg "Installing the binaries for ${ARCH} ..."

for i in bin lib lib64 ; do
  [ ! -d "${MODPATH}/system/$i" ] && continue
  LogMsg "Processing the files in the directory ${MODPATH}/system/$i ..."

  set_perm_recursive "${MODPATH}/system/$i" 0 0 0755 0755 u:object_r:system_file:s0

  chcon -R -h  u:object_r:system_file:s0 "${MODPATH}/system/$i"
done

for i in usr/share usr/include  etc ; do
  
  [[ $i != /\* ]] && CUR_ENTRY="${MODPATH}/system/$i" || CUR_ENTRY="$i"

  [ ! -d "${CUR_ENTRY}" ] && continue 
  
  LogMsg "Processing the files in the directory ${CUR_ENTRY} ..."
  set_perm_recursive "${CUR_ENTRY}" 0 0 0755 0644 u:object_r:system_file:s0
  chcon -R -h u:object_r:system_file:s0 "${CUR_ENTRY}"
done


