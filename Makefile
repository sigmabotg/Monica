ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MonicaPro
MonicaPro_FILES = Tweak.x
MonicaPro_CFLAGS = -fobjc-arc
MonicaPro_LAYOUT = layoutinclude $(THEOS_MAKE_PATH)/tweak.mk
