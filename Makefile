export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:13.7:13.0

THEOS_DEVICE_IP = 192.168.86.37

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

export ARCHS = arm64 arm64e

TWEAK_NAME = AutoHideJB
AutoHideJB_FILES = AutoHideJB.xm
AutoHideJB_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += HideJBHelper
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "sbreload"
