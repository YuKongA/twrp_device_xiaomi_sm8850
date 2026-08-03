#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/sm8850

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

## Device identifier
PRODUCT_DEVICE := sm8850
PRODUCT_NAME := twrp_sm8850
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := sm8850
PRODUCT_MANUFACTURER := Xiaomi

# Theme
TW_STATUS_ICONS_ALIGN := center
