TARGET_CODESIGN = $(shell which ldid)

PLATFORM = iphoneos
NAME = backdoor
SCHEME ?= 'backdoor (Debug)'
RELEASE = Release-iphoneos
CONFIGURATION = Release

MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk $(PLATFORM) --show-sdk-path)

APP_TMP         = $(TMPDIR)/$(NAME)
STAGE_DIR   = $(APP_TMP)/stage
APP_DIR     = $(APP_TMP)/Build/Products/$(RELEASE)/$(NAME).app

# Default CFLAGS if not provided externally
CFLAGS ?= -Onone

# Default SPM settings for CI environments
DERIVED_DATA = $(TMPDIR)/DerivedData

all: package

package: clean-spm-caches prepare-build build

# Clean SPM caches to prevent "already exists unexpectedly" errors
clean-spm-caches:
	@echo "Cleaning Swift Package Manager caches..."
	@rm -rf $(HOME)/Library/Caches/org.swift.swiftpm
	@rm -rf $(HOME)/.swiftpm
	@rm -rf $(DERIVED_DATA)
	@mkdir -p $(DERIVED_DATA)

# Prepare the build environment with proper package resolution
prepare-build:
	@echo "Preparing build environment and resolving packages..."
	@xcodebuild clean -project '$(NAME).xcodeproj' -scheme $(SCHEME) -quiet
	@xcodebuild -resolvePackageDependencies -project '$(NAME).xcodeproj' -scheme $(SCHEME) -derivedDataPath $(DERIVED_DATA) -quiet || true
	@echo "Validating package resolution..."
	@xcodebuild -project '$(NAME).xcodeproj' -scheme $(SCHEME) -list -quiet

# Main build step with simplified approach
build:
	@echo "Building project..."
	@rm -rf $(APP_TMP)
	
	@set -o pipefail; \
		xcodebuild \
		-jobs $(shell sysctl -n hw.ncpu) \
		-project '$(NAME).xcodeproj' \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-arch arm64 -sdk $(PLATFORM) \
		-derivedDataPath $(APP_TMP) \
		CODE_SIGNING_ALLOWED=NO \
		DSTROOT=$(APP_TMP)/install \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		SWIFT_ACTIVE_COMPILATION_CONDITIONS="RELEASE" \
		GCC_PREPROCESSOR_DEFINITIONS="RELEASE=1" \
		OTHER_SWIFT_FLAGS="-Xfrontend -enable-experimental-cxx-interop" \
		CFLAGS="$(CFLAGS)"
		
	@rm -rf Payload
	@rm -rf $(STAGE_DIR)/
	@mkdir -p $(STAGE_DIR)/Payload
	@mv $(APP_DIR) $(STAGE_DIR)/Payload/$(NAME).app
	@echo $(APP_TMP)
	@echo $(STAGE_DIR)
	
	@rm -rf $(STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	@ln -sf $(STAGE_DIR)/Payload Payload
	@rm -rf packages
	@mkdir -p packages

ifeq ($(TIPA),1)
	@zip -r9 packages/$(NAME)-ts.tipa Payload
else
	@zip -r9 packages/$(NAME).ipa Payload
endif

clean:
	@rm -rf $(STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf apple-include
	@rm -rf $(APP_TMP)

.PHONY: apple-include