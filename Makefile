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

# SPM cache settings for CI environments
SPM_CACHE = $(HOME)/Library/Caches/org.swift.swiftpm

all: package

package: resolve-packages build

# Explicitly resolve Swift Package dependencies before building
resolve-packages:
	@echo "Resolving Swift Package dependencies..."
	@mkdir -p $(SPM_CACHE)
	@set -o pipefail; \
		xcodebuild \
		-resolvePackageDependencies \
		-project '$(NAME).xcodeproj' \
		-scheme $(SCHEME) \
		-scmProvider system \
		-clonedSourcePackagesDirPath $(SPM_CACHE)

# Main build step
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
		-scmProvider system \
		-clonedSourcePackagesDirPath $(SPM_CACHE) \
		CODE_SIGNING_ALLOWED=NO \
		DSTROOT=$(APP_TMP)/install \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
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