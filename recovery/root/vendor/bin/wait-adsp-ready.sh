#!/system/bin/sh

tries=0
while [ "$tries" -lt 60 ]; do
    state=$(cat /sys/class/remoteproc/remoteproc1/state 2>/dev/null)
    if [ "$state" = "running" ]; then
        setprop twrp.adsp.ready true
        exit 0
    fi

    sleep 1
    tries=$((tries + 1))
done

setprop twrp.adsp.ready false
exit 1
