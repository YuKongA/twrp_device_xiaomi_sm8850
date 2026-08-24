#!/system/bin/sh

FASTBOOTD_PROP=$(getprop ro.twrp.fastbootd)
[ "$FASTBOOTD_PROP" = "1" ] && exit 0

LOG_TAG="I:cp-wifi-ko"
TARGET_DIR="/odm/wifi/modules"
SEARCH_DIRS="/vendor_dlkm /system_dlkm"
FIRMWARE_MOUNT="/vendor/firmware_mnt"
KO_FILES="smem-mailbox.ko qmi_helpers.ko qcom_glink.ko qcom_glink_smem.ko qcom_smd.ko rproc_qcom_common.ko qcom_ramdump.ko qcom_va_minidump.ko pci-msm-drv.ko pcie-pdc.ko mhi.ko usb_f_gsi.ko dwc3-msm.ko repeater.ko redriver.ko mca_sysfs.ko wcd_usbss_i2c.ko cnss_prealloc.ko cnss_utils.ko cnss_plat_ipc_qmi_svc.ko cnss_nl.ko wlan_firmware_service.ko cnss2.ko rfkill.ko cfg80211.ko mac80211.ko gsim.ko rmnet_mem.ko ipam.ko qca_cld3_peach_v2.ko"

log_print() {
    echo "$LOG_TAG: $1" >> /tmp/recovery.log
}

is_mounted() {
    mount | grep -q " on $1 "
}

mount_dlkm_image() {
    image_name="$1"
    mount_point="$2"

    is_mounted "$mount_point" && return 0
    mkdir -p "$mount_point"

    slot_suffix=$(getprop ro.boot.slot_suffix)
    image_device="/dev/block/mapper/${image_name}${slot_suffix}"
    [ -e "$image_device" ] || image_device="/dev/block/mapper/${image_name}_a"
    [ -e "$image_device" ] || image_device="/dev/block/bootdevice/by-name/${image_name}${slot_suffix}"
    [ -e "$image_device" ] || image_device="/dev/block/bootdevice/by-name/${image_name}"

    if [ -e "$image_device" ]; then
        mount -o ro "$image_device" "$mount_point" 2>/dev/null
        if is_mounted "$mount_point"; then
            log_print "Mounted $image_name: $image_device -> $mount_point"
            return 0
        fi
    fi

    log_print "Unable to mount $image_name"
    return 1
}

# The WLAN firmware lives on the modem VFAT image.  It must remain mounted
# after the normal recovery firmware setup has finished, otherwise cnss2 can
# load but qca_cld3_peach_v2 cannot boot the WLAN firmware.
mount_wifi_firmware() {
    mkdir -p "$FIRMWARE_MOUNT"
    if is_mounted "$FIRMWARE_MOUNT"; then
        return 0
    fi

    slot_suffix=$(getprop ro.boot.slot_suffix)
    firmware_device="/dev/block/bootdevice/by-name/modem${slot_suffix}"
    [ -e "$firmware_device" ] || firmware_device="/dev/block/bootdevice/by-name/modem"

    if [ -e "$firmware_device" ]; then
        mount -t vfat -o ro,shortname=lower,uid=1000,gid=1000,dmask=227,fmask=337 "$firmware_device" "$FIRMWARE_MOUNT"
        if is_mounted "$FIRMWARE_MOUNT"; then
            log_print "Mounted WLAN firmware: $firmware_device -> $FIRMWARE_MOUNT"
            return 0
        fi
    fi

    log_print "Unable to mount WLAN firmware image"
    return 1
}

ensure_link() {
    source_path="$1"
    link_path="$2"
    [ -e "$link_path" ] || [ -L "$link_path" ] || ln -s "$source_path" "$link_path"
}

mount_wifi_firmware
mount_dlkm_image vendor_dlkm /vendor_dlkm
mount_dlkm_image system_dlkm /system_dlkm
mkdir -p "$TARGET_DIR"
chmod 0755 "$TARGET_DIR"

# These links are present on stock vendor, but creating them when absent keeps
# the recovery tree usable with vendor images that omit the WLAN links.
mkdir -p /vendor/firmware/wlan/qca_cld/peach_v2 2>/dev/null
cfg_source="/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini"
[ -f "$cfg_source" ] || cfg_source="/system/etc/wifi/WCNSS_qcom_cfg.ini"
ensure_link "$cfg_source" /vendor/firmware/wlan/qca_cld/peach_v2/WCNSS_qcom_cfg.ini
if [ -f /mnt/vendor/persist/wlan/wlan_mac.bin ]; then
    ensure_link /mnt/vendor/persist/wlan/wlan_mac.bin /vendor/firmware/wlan/qca_cld/peach_v2/wlan_mac.bin
elif [ -f /persist/wlan/wlan_mac.bin ]; then
    ensure_link /persist/wlan/wlan_mac.bin /vendor/firmware/wlan/qca_cld/peach_v2/wlan_mac.bin
fi

found_count=0
for ko_file in $KO_FILES; do
    file_path=""
    for search_dir in $SEARCH_DIRS; do
        if [ -d "$search_dir" ]; then
            file_path=$(find "$search_dir" -type f -name "$ko_file" 2>/dev/null | head -1)
            [ -n "$file_path" ] && break
        fi
    done

    if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        cp -f "$file_path" "$TARGET_DIR/$ko_file"
        chmod 0644 "$TARGET_DIR/$ko_file"
        found_count=$((found_count + 1))
    else
        log_print "Unable to find $ko_file"
    fi
done

log_print "Copied $found_count Wi-Fi kernel modules"
setprop twrp.cpko true
