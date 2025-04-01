#!/bin/bash
set -e

# Script to manage Swift Package dependencies directly
# This avoids the issues we've been seeing with package resolution

echo "📦 Direct Dependency Management Script"
echo "======================================="

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
        # This is a simplified version - in reality, you'd want a more robust way to edit Package.swift
        sed -i '' "/dependencies: \[/a\\
        .package(url: \"$url\", $version)," Package.swift
    end
}

# Function to ensure product dependencies are added to the target
add_product() {
    local package="$1"
    local product="$2"
    
    if grep -q "product(name: \"$product\", package: \"$package\")" Package.swift; then
        echo "✅ Product $product already exists in target dependencies"
    else
        echo "➕ Adding product $product to target dependencies"
        # Again, simplified - would need a more robust approach for a real implementation
        sed -i '' "/dependencies: \[/a\\
                .product(name: \"$product\", package: \"$package\")," Package.swift
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
    swift package resolve
    echo "✅ Packages resolved"
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

# Main execution
clean_spm_cache "$1"
ensure_dependencies
resolve_packages

echo "✅ All dependencies managed successfully"
exit 0
