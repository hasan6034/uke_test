#!/system/bin/sh
# uke: touchfeature-service resurrection watchdog.
#
# The xiaomi-uinput bridge sends an active-mode keepalive ioctl every 15s
# which keeps the THP daemon out of doze mode, so no periodic restarts are
# needed. This watchdog only brings the daemon back if it actually died.

LOGFILE=/tmp/recovery.log

while true; do
	sleep 20

	svc=$(getprop init.svc.touchfeature-service)
	if [ "$svc" != "running" ]; then
		setprop ctl.start touchfeature-service
		echo "I:touch_watchdog: service was $svc, started" >> "$LOGFILE"
		sleep 5
	fi
done
