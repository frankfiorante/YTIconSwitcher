TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YTIconSwitcher
$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_FILTER_BUNDLES = com.google.ios.youtube

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 YouTube 2>/dev/null; uicache -p /Applications/YouTube.app 2>/dev/null; true"
