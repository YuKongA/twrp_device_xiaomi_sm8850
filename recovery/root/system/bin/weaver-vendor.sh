#!/system/bin/sh

[ "$(getprop ro.boot.hardware.sku)" = "nezha" ] || exit 0

log() {
    echo "weaver-vendor.sh: nezha $*" >> /tmp/recovery.log
}

edition=$(getprop ro.special_edition)
source=ro.special_edition
if [ -z "$edition" ]; then
    # ODM is a logical, slotted partition on SM8850. modules.loaded is
    # published after recovery creates its mapper nodes; never guess the slot.
    suffix=$(getprop ro.boot.slot_suffix)
    if [ -z "$suffix" ]; then
        slot=$(getprop ro.boot.slot)
        [ -z "$slot" ] || suffix="_$slot"
    fi
    case "$suffix" in
        _a|_b) ;;
        *) log "missing or invalid boot slot; vendor not selected"; exit 1 ;;
    esac
    block=""
    for candidate in "/dev/block/mapper/odm$suffix" "/dev/block/bootdevice/by-name/odm$suffix"; do
        if [ -b "$candidate" ]; then
            block="$candidate"
            break
        fi
    done
    [ -n "$block" ] || {
        log "no ODM block device for slot $suffix; vendor not selected"
        exit 1
    }
    log "reading ROM properties from $block"
    rom=/mnt/nezha-weaver-odm
    sku=$(getprop ro.boot.product.hardware.sku)
    hw=$(getprop ro.boot.hwversion)
    country=$(getprop ro.boot.ptcountrycode)
    case "$sku:$hw:$country" in
        *[!a-zA-Z0-9_.:-]*) log "invalid boot properties; vendor not selected"; exit 1 ;;
    esac
    [ "$sku" = nezha ] && [ -n "$hw" ] || {
        log "missing ROM property selectors; vendor not selected"
        exit 1
    }

    if grep -q " $rom " /proc/mounts; then
        log "ROM inspection mount already in use; vendor not selected"
        exit 1
    fi
    mkdir -p "$rom" || exit 1
    # Inspect the installed ROM without overmounting the recovery's /odm.
    if ! mount -t erofs -o ro,nodev,nosuid,noexec "$block" "$rom" &&
       ! mount -t ext4 -o ro,noload,nodev,nosuid,noexec "$block" "$rom"; then
        log "cannot read ROM odm; vendor not selected"
        rmdir "$rom"
        exit 1
    fi
    trap 'umount "$rom" && rmdir "$rom"' EXIT
    trap 'exit 1' HUP INT TERM

    # Follow stock ODM imports; only read the edition, never execute property files.
    edition=$(awk -v root="$rom" -v sku="$sku" -v hw="$hw" -v country="$country" '
        function load(path, depth, line, fields, n, key, value, status) {
            if (depth > 8 || path !~ /^\/odm\// || path ~ /\/\.\.\//) { bad=1; return }
            path=root substr(path, 5)
            if (active[path]) { bad=1; return }
            active[path]=1
            while ((status=(getline line < path)) > 0) {
                sub(/\r$/, "", line)
                sub(/^[ \t]+/, "", line)
                if (line ~ /^#/ || line == "") continue
                if (line ~ /^import[ \t]+/) {
                    n=split(line, fields, /[ \t]+/)
                    value=fields[2]
                    gsub(/\$\{ro.boot.product.hardware.sku\}/, sku, value)
                    gsub(/\$\{ro.boot.hwversion\}/, hw, value)
                    gsub(/\$\{ro.boot.ptcountrycode\}/, country, value)
                    if (value ~ /\$/ || n != 2) { bad=1; continue }
                    load(value, depth+1)
                    if (bad) break
                } else if (line ~ /^ro.special_edition[ \t]*=/) {
                    sub(/^[^=]*=[ \t]*/, "", line)
                    sub(/[ \t]+$/, "", line)
                    edition=line
                } else if (line ~ /^ro.product.odm.device[ \t]*=/) {
                    sub(/^[^=]*=[ \t]*/, "", line)
                    sub(/[ \t]+$/, "", line)
                    device=line
                }
            }
            if (depth == 0 && status < 0) bad=1
            close(path)
            delete active[path]
        }
        BEGIN {
            edition="false"
            load("/odm/etc/build.prop", 0)
            if (bad || device != "nezha") exit 1
            print edition
        }
    ')
    result=$?
    if ! umount "$rom"; then
        log "cannot release ROM inspection mount; vendor not selected"
        exit 1
    fi
    trap - EXIT HUP INT TERM
    rmdir "$rom"
    if [ "$result" -ne 0 ]; then
        log "cannot resolve stock ODM properties; vendor not selected"
        exit 1
    fi
    source=ROM-odm
fi

case "$edition" in
    true) vendor=goodix ;;
    false) vendor=thales ;;
    *) log "invalid ro.special_edition '$edition'; vendor not selected"; exit 1 ;;
esac
if ! setprop ro.twrp.weaver "$vendor"; then
    log "failed to select $vendor"
    exit 1
fi
log "selected $vendor (source=$source, ro.special_edition=$edition)"
