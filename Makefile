TARGET := iphone:clang:14.5:7.0
ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = slice_fixup

slice_fixup_FILES = main.m
slice_fixup_CFLAGS = -fobjc-arc
slice_fixup_CODESIGN_FLAGS = -Sentitlements.plist
slice_fixup_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
