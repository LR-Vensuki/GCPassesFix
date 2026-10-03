TARGET := iphone:clang:6.1:5.0
ARCHS := armv7 armv7s
INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = GCPassesFixPrefs

GCPassesFixPrefs_FILES = GCPFRootListController.m
GCPassesFixPrefs_FRAMEWORKS = UIKit
GCPassesFixPrefs_PRIVATE_FRAMEWORKS = Preferences
GCPassesFixPrefs_INSTALL_PATH = /Library/PreferenceBundles
GCPassesFixPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
