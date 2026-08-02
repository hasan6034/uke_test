#!/system/bin/sh

DEBUG=0
[ "$DEBUG" = "1" ] && set -o xtrace;

LOGMSG() {
	echo "I:$@" >> /tmp/recovery.log
}

# Force-load touch driver chain if TWRP's module loader missed them
# (dependency order: xiaomi_touch must precede nt36532_touch)
ensure_touch_modules() {
	MODULES_DIR="/vendor/lib/modules"
	DRIVERS="panel_event_notifier miev msm_drm metis xiaomi_touch nt36532_touch"

	for d in $DRIVERS; do
		if lsmod | grep -q "^${d//-/_} "; then
			continue
		fi
		path=$(find "$MODULES_DIR" -name "$d.ko" | head -n 1)
		if [ -f "$path" ]; then
			insmod "$path" 2>/dev/null
			if [ $? -eq 0 ]; then
				LOGMSG "Force inserted module: $d"
			else
				LOGMSG "insmod failed for: $d (will rely on vendor_dlkm)"
			fi
		else
			LOGMSG "Module not found in ramdisk: $d"
		fi
	done
}

# Restart the Xiaomi THP / touchfeature service if it is not up, or if its
# THP daemon aborted init (boot race vs. panel probe -> no touch events)
ensure_touch_service() {
	TOUCH_SVC_STATUS=$(getprop init.svc.touchfeature-service)
	if [ "$TOUCH_SVC_STATUS" != "running" ]; then
		setprop ctl.start touchfeature-service
		LOGMSG "Forced touchscreen service start"
		return
	fi
	if [ -x /system/bin/logcat ] && logcat -d 2>/dev/null | grep -q "thp hal init failed"; then
		setprop ctl.stop touchfeature-service
		sleep 1
		setprop ctl.start touchfeature-service
		sleep 2
		LOGMSG "Restarted touchfeature-service after THP init failure"
	fi
}

SCRIPT_NAME="$(basename "$0")"

LOGMSG "---$SCRIPT_NAME start---"

ensure_touch_modules

# Apply touch node permissions here too: the daemon retries opening
# abnormal_event every 5s, so fixing perms late still lets it recover.
if [ -f /odm/etc/touch_perms.sh ]; then
	sh /odm/etc/touch_perms.sh
	LOGMSG "Applied touch permissions"
fi

ensure_touch_service

# Keep the THP daemon out of doze mode for the whole recovery session
if [ -f /system/bin/touch_watchdog.sh ]; then
	/system/bin/touch_watchdog.sh </dev/null >/dev/null 2>&1 &
	LOGMSG "Touch watchdog started"
fi

/sbin/prune_historic_logs.sh 10

LOGMSG "---$SCRIPT_NAME end---"
exit 0
