#
# This file is part of the OrangeFox Recovery Project
# Copyright (C) 2026 The OrangeFox Recovery Project
#
# OrangeFox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This software is released under GPL version 3 or any later version.
# See <http://www.gnu.org/licenses/>.
#

# OrangeFox settings
OF_AB_DEVICE_WITH_RECOVERY_PARTITION := 1
OF_VIRTUAL_AB_DEVICE := 1
OF_DYNAMIC_FULL_SIZE := 13421772800

# OrangeFox GUI settings
OF_SCREEN_H := 2656
OF_STATUS_H := 100
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_HIDE_NOTCH := 1
OF_CLOCK_POS := 1
OF_OPTIONS_LIST_NUM := 6

# Recovery additional features
OF_ENABLE_LPTOOLS := 1
OF_IGNORE_LOGICAL_MOUNT_ERRORS := 1
OF_ENABLE_USB_STORAGE := 1
OF_FLASHLIGHT_ENABLE := 1
OF_QUICK_BACKUP_LIST := /data;/boot;
OF_BIND_MOUNT_SDCARD_ON_FORMAT := 1
OF_SKIP_MULTIUSER_FOLDERS_BACKUP := 1

# OTA
OF_PATCH_AVB20 := 1
OF_KEEP_DM_VERITY_FORCED_ENCRYPTION := 1
OF_DISABLE_OTA_MENU := 1
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
