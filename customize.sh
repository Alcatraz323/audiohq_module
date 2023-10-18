SKIPUNZIP=1
API_SUPPORT_MAX=34
API_SUPPORT_MIN=26

TO_INSTALL_ARCH="arm"

run_oem_syetem_warning(){
  ui_print "!!!WARNING, Pls stop this installation or revert if you are"
  ui_print "using oem modified system, such as sumsung's one ui, flyme, "
  ui_print "emui...(EXCEPT MIUI for now)"
  ui_print "!!!WARNING, Pls stop this installation or revert if you are"
  ui_print "using oem modified system, such as sumsung's one ui, flyme, "
  ui_print "emui...(EXCEPT MIUI for now)"
  ui_print "!!!WARNING, Pls stop this installation or revert if you are"
  ui_print "using oem modified system, such as sumsung's one ui, flyme, "
  ui_print "emui...(EXCEPT MIUI for now)"
  ui_print "!!!Installing and reboot on those system will cause soft brick"
  ui_print "!!!Waiting for 10secs for you to exit"
  sleep 10s
}

run_arch_check(){
  ui_print "- Current support arch : arm, arm64"
  ui_print "- Running Arch check"
  if [[  "$ARCH" != "arm" && "$ARCH" != "arm64" ]]; then
    abort "! Err : unsupported platform: $ARCH, please check for the latest version to try if supported now"
  else
    ui_print "- Device platform: $ARCH"
  fi

  ui_print "- Checking audioserver info"
  audioserver_info=$(file /system/bin/audioserver)
  ui_print "'audioserver' info : $audioserver_info"

 filter="64-bit"
  result=$(echo $audioserver_info | grep "${filter}")
  if [[ "$result" != "" ]]; then
    ui_print "- To install arch : arm64"
    TO_INSTALL_ARCH="arm64"
    if [[ $API == 26 || $API == 27 ]]; then
      abort "! Err : Your api isn't support this arch audiohq, contact developer for more information"
    fi

    if [[ $API == 28 || $API == 32 || $API == 33 || $API == 34 ]]; then
      ui_print "! WARNING : This api may not fit arm64 arch, the software would not work probably, and your audiosystem may crash"
    fi
  else
    ui_print "- To install arch : arm"
    TO_INSTALL_ARCH="arm"
  fi
}

run_api_check(){
  ui_print "- Current support api $API_SUPPORT_MIN - $API_SUPPORT_MAX"
	ui_print "- Running Api Version check"
	if [[ $API < API_SUPPORT_MIN || $API > API_SUPPORT_MAX ]]; then
    abort "! Err : unsupported Api: $API, please check for the latest version to try if supported now"
  else
    ui_print "- Android System Api: $API"
  fi
}

run_magisk_check(){
  ui_print "- Your Magisk version : $MAGISK_VER_CODE"
  if [[ $MAGISK_VER_CODE -ge 20200 ]]; then
    ui_print "- Magisk version available"
  else
    abort "! Err : Your Magisk is too old too add sepolicy, pls upgrade to 20.2 or higher"
  fi
}

volume_keytest() 
{
  ui_print "- Vol Key Test -"
  ui_print "   Pls Press Vol Up(+):"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > "$TMPDIR"/events) || return 1
  return 0
}

volume_choose() 
{
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > "$TMPDIR"/events
      if (`cat "$TMPDIR"/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
          break
      fi
  done
  if (`cat "$TMPDIR"/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
      return 1
  else
      return 0
  fi
}

run_volume_key_test(){
  # Check whether using a legacy device
  # -----------------------------------
  ui_print "- Start volume key test"
  if volume_keytest; then
    KEYTEST=volume_choose
  else
    KEYTEST=false
    ui_print "! Can't do volume key selection, install will run as default (CHECK and SHUTDOWN SeLinux)"
    ui_print "! If the installtion is SUCCESSFUL, You can comment 'setenforce 0' in $MODPATH/service.sh to enable Se Enforcing Mode"
  fi
  ui_print "- Key test function complete"
}

run_selinux_select_n_check(){
  ui_print " "
  ui_print "--- Select Installation Target ---"
  ui_print "  Vol+ = Default(CHECK and SHUTDOWN SeLinux)"
  ui_print "  Vol- = Try enforcing(This would probably NOT work on some third party or default permissive kernel)"
  ui_print " "

  if "$KEYTEST"; then
    CHECK_SE=1
    ui_print "Selected: Try Se enforcing"
  else
    CHECK_SE=0
    ui_print "Selected: Default(CHECK and SHUTDOWN SeLinux), script will try shutdown SeLinux"
    ui_print "If the installtion is SUCCESSFUL, You can comment 'setenforce 0' in $MODPATH/service.sh to enable Se Enforcing Mode"
  fi
  
  if [[ $CHECK_SE == 0 ]]; then
    ui_print "- Checking SeLinux state"
    selinux=$(getenforce)
    ui_print "-- Current SeLinux : $selinux"
    setenforce 0
    aft_selinux=$(getenforce)
    ui_print "-- Aft SeLinux : $aft_selinux"
    if [[ "$aft_selinux" != "Permissive" ]]; then
      abort "! Err : Your SeLinux cannot be shutdown, check your kernel"
    else
      ui_print "- SeLinux can be shutdown"
    fi
  fi
}

print_warning() {
  ui_print "! Caution, If you have installed AudioHQ's Apk, this operation will override the apk data, pls do backup"
}

set_permissions() {
  ui_print "- Setting permissions"
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Here are some examples:
  set_perm_recursive  $MODPATH/system/lib         0     0       0644
  set_perm_recursive  $MODPATH/system/lib64       0     0       0644
  set_perm  $MODPATH/system/bin/audiohq   0     2000    0755      u:object_r:system_file:s0
  set_perm  $MODPATH/system/bin/audiohqserver   0     2000    0755      u:object_r:system_file:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}

run_oem_syetem_warning
print_warning
run_api_check
run_arch_check
run_magisk_check
run_volume_key_test
run_selinux_select_n_check

ui_print "- Extracting module files"

UNZIP_TARGET="apis/$API/$TO_INSTALL_ARCH/system"
ui_print "- Target unzip $UNZIP_TARGET"

unzip -o "$ZIPFILE" "uninstall.sh" -d $MODPATH >&2
unzip -o "$ZIPFILE" "$UNZIP_TARGET/*" -d $MODPATH >&2
unzip -o "$ZIPFILE" "sepolicy.rule" -d $MODPATH >&2
unzip -o "$ZIPFILE" "module.prop" -d $MODPATH >&2

if [[ $CHECK_SE == 0 ]]; then
  unzip -o "$ZIPFILE" "service.sh" -d $MODPATH >&2
else
  unzip -o "$ZIPFILE" "service_try_enforcing.sh" -d $MODPATH >&2
  mv "$MODPATH/service_try_enforcing.sh" "$MODPATH/service.sh"
fi

mv "$MODPATH/$UNZIP_TARGET" "$MODPATH/"
rm -rf "$MODPATH/apis"

ui_print "- Extracting apk"
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

ui_print "- File extraction complete"
set_permissions
