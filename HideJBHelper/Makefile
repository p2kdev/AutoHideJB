include $(THEOS)/makefiles/common.mk

TOOL_NAME = hidejbhelper

hidejbhelper_FILES = main.m
hidejbhelper_CFLAGS = -fobjc-arc
hidejbhelper_CODESIGN_FLAGS = -Sentitlements.plist
hidejbhelper_INSTALL_PATH = /usr/libexec

include $(THEOS_MAKE_PATH)/tool.mk

internal-stage::
	$(ECHO_NOTHING)chmod 6755 $(THEOS_STAGING_DIR)/usr/libexec/$(TOOL_NAME)$(ECHO_END)