# TWRP device tree for Xiaomi SM8850

## Supported devices

| Codename | Device                                |
| -------- | ------------------------------------- |
| pudding  | Xiaomi 17                             |
| pandora  | Xiaomi 17 Pro                         |
| popsicle | Xiaomi 17 Pro Max \*                  |
| nezha    | Xiaomi 17 Ultra                       |
| byron    | Xiaomi 17 Max                         |
| myron    | REDMI K90 Pro Max / POCO F8 Ultra     |
| athens   | REDMI K100 Pro / POCO F9 Pro          |
| songyuan | REDMI K100 Pro Max / POCO F9 Ultra    |

\* Primary test device

## Features

- [x] ADB
- [x] Decryption
- [x] Display
- [x] Fastbootd
- [x] Flashing
- [x] MTP
- [x] Sideload
- [x] USB-OTG
- [x] Vibrator

## nezha Weaver selection

`nezha` uses either Thales or Goodix eSE. Recovery selects one Weaver
implementation from the installed ROM's `ro.special_edition`: `true` selects
Goodix; `false` selects Thales. It does not start both implementations.

If that property is absent in recovery, `weaver-vendor.sh` reads the active
slot's ODM read-only at a separate mount point and follows its boot-property
imports. A successfully read configuration without the property uses the stock
Thales default. Invalid or unreadable configuration leaves Weaver unselected
and logs the reason instead of guessing from device nodes or hardware tables.

The selector runs after variant files and logical partition nodes are ready.
Both implementations and their existing libraries remain bundled. Check the
selection with `adb shell getprop ro.twrp.weaver` and the
`weaver-vendor.sh:` lines in `/tmp/recovery.log`. Selection checks do not
verify credential decryption; both hardware variants still need device testing.

## Build it yourself

- [TWRP-Test/platform_manifest_twrp_aosp](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)
