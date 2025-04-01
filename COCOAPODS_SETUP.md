# Hybrid CocoaPods/SPM Setup

This project uses a hybrid approach with both CocoaPods and Swift Package Manager (SPM) for dependency management.

## Why a Hybrid Approach?

- **More Reliable Package Resolution**: CocoaPods provides more reliable dependency resolution for some iOS packages
- **Better Build Performance**: Pre-built binaries can lead to faster build times
- **Preserves Working SPM Dependencies**: Keeps the existing SPM dependencies that are working well

## Setup Instructions

### Initial Setup

1. Make sure you have CocoaPods installed:
   ```bash
   sudo gem install cocoapods
   ```

2. Install the CocoaPods dependencies:
   ```bash
   pod install
   ```

3. **IMPORTANT**: After running `pod install`, always open the `.xcworkspace` file, not the `.xcodeproj` file!

### Adding New Dependencies

- **For CocoaPods dependencies**: Add them to the Podfile and run `pod install`
- **For SPM dependencies**: Add them through Xcode's "File > Add Packages..." interface

## Package Management

### CocoaPods Packages (in Podfile)
- CryptoSwift
- SnapKit
- Lottie (as lottie-ios)
- Moya
- R.swift

### SPM Packages (still in Package.swift and project.pbxproj)
- SwiftUIX (must be added via SPM since it's not available in CocoaPods)
- All other packages listed in Package.swift

## Troubleshooting

If you encounter issues with the dependencies:

1. Update CocoaPods: `pod repo update`
2. Clean your build folder: In Xcode, "Product > Clean Build Folder"
3. Restart Xcode
4. Reinstall pods: `pod install --repo-update`

## CI/CD Integration

For CI systems, ensure that:
1. CocoaPods is installed in the CI environment
2. `pod install` is run before building the project
3. The `.xcworkspace` file is used for building, not the `.xcodeproj`
