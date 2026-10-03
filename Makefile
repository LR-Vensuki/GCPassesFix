TARGET := iphone:clang:6.1:5.0
ARCHS := armv7 armv7s
INSTALL_TARGET_PROCESSES = Passbook SpringBoard

# Cydia/dpkg on iOS 5/6 only unpacks gzip-compressed debs.
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GCPassesFix
GCPassesFix_FILES = Tweak.x
GCPassesFix_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += helper
SUBPROJECTS += prefs
include $(THEOS_MAKE_PATH)/aggregate.mk

# Regenerate the certificate profile and icons from source before packaging.
before-package::
	@python3 tools/make-profile.py

after-install::
	install.exec "killall -9 Preferences || true"

# Publish to the LegacyReborn Cydia repository (see cydia-repo/README.md).
CYDIA_REPO = $(HOME)/Theos-Projects/cydia-repo

publish:: package
	@python3 $(CYDIA_REPO)/tools/repo.py publish $(CURDIR) $(if $(MSG),-m "$(MSG)")

depiction::
	@python3 $(CYDIA_REPO)/tools/repo.py publish $(CURDIR) --depiction-only
