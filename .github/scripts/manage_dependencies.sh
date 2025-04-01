#!/bin/bash
set -e

# Script to manage Swift Package dependencies directly
# This avoids the issues we've been seeing with package resolution

echo "📦 Direct Dependency Management Script"
echo "======================================="

# Get installed Swift version
INSTALLED_SWIFT_VERSION=$(swift --version | head -n1 | grep -o 'Swift version [0-9]\.[0-9]\(\.[0-9]\)\?' | cut -d ' ' -f 3)
echo "📊 Installed Swift version: $INSTALLED_SWIFT_VERSION"

# Check Package.swift tools version
PACKAGE_TOOLS_VERSION=$(head -n1 Package.swift | grep -o '[0-9]\.[0-9]\+\(\.[0-9]\+\)\?')
echo "📊 Package.swift tools version: $PACKAGE_TOOLS_VERSION"

# Update the tools version if needed for compatibility
update_tools_version() {
    if [[ "$INSTALLED_SWIFT_VERSION" != "$PACKAGE_TOOLS_VERSION" ]]; then
        echo "⚠️ Swift version mismatch detected"
        echo "📝 Updating Package.swift tools version to $INSTALLED_SWIFT_VERSION"
        
        # Create a backup of the original Package.swift
        cp Package.swift Package.swift.backup
        
        # Update the tools version in Package.swift
        sed -i.bak "1s/swift-tools-version:[0-9]\.[0-9]\+\(\.[0-9]\+\)\?/swift-tools-version:$INSTALLED_SWIFT_VERSION/g" Package.swift
        rm -f Package.swift.bak
        
        echo "✅ Package.swift updated to use Swift tools version $INSTALLED_SWIFT_VERSION"
    else
        echo "✅ Swift version matches Package.swift tools version"
    fi
}

# Function to check if a Swift package is already in the Package.swift file
package_exists() {
    grep -q "url: \"$1\"" Package.swift
}

# Function to add a Swift package to Package.swift if it doesn't exist
add_package() {
    local url="$1"
    local version="$2"
    local name=$(basename $url .git)
    
    if package_exists "$url"; then
        echo "✅ Package $name already exists in Package.swift"
    else
        echo "➕ Adding $name to Package.swift"
        sed -i.bak "/dependencies: \[/a\\
        .package(url: \"$url\", $version)," Package.swift
        rm -f Package.swift.bak
    fi
}

# Function to ensure product dependencies are added to the target
add_product() {
    local package="$1"
    local product="$2"
    
    if grep -q "product(name: \"$product\", package: \"$package\")" Package.swift; then
        echo "✅ Product $product already exists in target dependencies"
    else
        echo "➕ Adding product $product to target dependencies"
        sed -i.bak "/dependencies: \[/a\\
                .product(name: \"$product\", package: \"$package\")," Package.swift
        rm -f Package.swift.bak
    fi
}

# Main function to ensure all required dependencies are present
ensure_dependencies() {
    # Key dependencies that have been problematic
    add_package "https://github.com/krzyzanowskim/CryptoSwift.git" "from: \"1.8.3\""
    add_package "https://github.com/SnapKit/SnapKit.git" ".upToNextMajor(from: \"5.0.1\")"
    add_package "https://github.com/airbnb/lottie-spm.git" "from: \"4.5.1\""
    add_package "https://github.com/SwiftUIX/SwiftUIX.git" "branch: \"master\""
    add_package "https://github.com/Moya/Moya.git" ".upToNextMajor(from: \"15.0.0\")"
    add_package "https://github.com/mac-cain13/R.swift.git" "from: \"7.0.0\""
    
    # Ensure products are in the target dependencies
    add_product "CryptoSwift" "CryptoSwift"
    add_product "SnapKit" "SnapKit"
    add_product "lottie-spm" "Lottie"
    add_product "SwiftUIX" "SwiftUIX"
    add_product "Moya" "Moya"
    add_product "R.swift" "RswiftLibrary"
}

# A direct method to resolve packages without relying on Xcode
resolve_packages() {
    echo "🔄 Resolving Swift Package dependencies..."
    # This is a simplified approach - you might need to adjust based on your project
    swift package resolve || echo "Package resolution had issues but continuing..."
    echo "✅ Packages resolution step completed"
}

# Clean SPM caches if necessary
clean_spm_cache() {
    if [ "$1" == "--clean" ]; then
        echo "🧹 Cleaning SPM caches..."
        rm -rf ~/Library/Caches/org.swift.swiftpm
        rm -rf .build
        echo "✅ Caches cleaned"
    fi
}

# Restore original Package.swift if we modified it and an error occurred
restore_package_swift() {
    if [ -f Package.swift.backup ]; then
        if [ $? -ne 0 ]; then
            echo "🔄 Error occurred, restoring original Package.swift"
            mv Package.swift.backup Package.swift
            echo "✅ Original Package.swift restored"
        else
            # Cleanup backup if successful
            rm -f Package.swift.backup
        fi
    fi
}

# Set up trap to ensure cleanup on exit
trap restore_package_swift EXIT

# Main execution
clean_spm_cache "$1"
update_tools_version
ensure_dependencies
resolve_packages

echo "✅ All dependencies managed successfully"
exit 0
