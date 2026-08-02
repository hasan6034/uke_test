#!/system/bin/sh
# uke: apply touch node permissions for whatever actually exists on this
# device. The stock rc block chowns a fixed phone-oriented list
# (tp_dev/fod_status, xiaomi-touch-knock, ...); the first missing path makes
# init abort the whole action, so later nodes (incl. abnormal_event, which
# the THP daemon must open) stay root-owned and touch never works.
# This script only touches nodes that exist and always exits 0.

# Character devices
for f in /dev/xiaomi-touch /dev/xiaomi-touch-knock /dev/xiaomi-thp \
         /proc/tp_selftest /proc/tp_selftest_1; do
    if [ -e "$f" ]; then
        chown system:system "$f"
        chmod 0664 "$f"
    fi
done
# The THP daemon and HAL clients need world access to the main ioctl node
[ -e /dev/xiaomi-touch ] && chmod 0666 /dev/xiaomi-touch

# touch sysfs nodes (xiaomi_touch module)
for f in /sys/class/touch/touch_dev/* /sys/class/touch/tp_dev/*; do
    [ -f "$f" ] || continue
    case "$f" in
        */uevent|*/power/*) continue ;;
    esac
    chown system:system "$f" 2>/dev/null
    chmod 0664 "$f" 2>/dev/null
done

# Virtual keypad status node
f=/sys/devices/virtual/keyboard/keypad/keyboard_status_param
if [ -e "$f" ]; then
    chown system:system "$f"
    chmod 0664 "$f"
fi

exit 0
