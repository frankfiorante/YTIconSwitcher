TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = YTIconSwitcherPrefs
$(BUNDLE_NAME)_FILES = RootListController.m
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_FRAMEWORKS = UIKit Foundation
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceLoader/Preferences
$(BUNDLE_NAME)_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/bundle.mk
