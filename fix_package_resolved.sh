#!/bin/bash
set -e

# Create updated package.resolved files
for FILE in ./backdoor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved ./backdoor.xcworkspace/xcshareddata/swiftpm/Package.resolved; do
    # Make sure the file is in valid JSON format
    if ! jq . "$FILE" > /dev/null 2>&1; then
        echo "Warning: $FILE is not valid JSON, will create a new one"
        # Create a new package.resolved file
        cat << 'JSON' > "$FILE"
{
  "pins": [
    {
      "identity": "cryptoswift",
      "kind": "remoteSourceControl",
      "location": "https://github.com/krzyzanowskim/CryptoSwift.git",
      "state": {
        "revision": "a0c87c6dd858e27efc3b5d9118afc451ec0d29e6",
        "version": "1.8.3"
      }
    },
    {
      "identity": "lottie-spm",
      "kind": "remoteSourceControl",
      "location": "https://github.com/airbnb/lottie-spm.git",
      "state": {
        "revision": "96300214cc4101f2876bda5a7959cb9e108acfa3",
        "version": "4.5.1"
      }
    },
    {
      "identity": "moya",
      "kind": "remoteSourceControl",
      "location": "https://github.com/Moya/Moya.git",
      "state": {
        "revision": "c263811c1f3dbf002be9bd83107f7cdc38992b26",
        "version": "15.0.3"
      }
    },
    {
      "identity": "r.swift",
      "kind": "remoteSourceControl",
      "location": "https://github.com/mac-cain13/R.swift.git",
      "state": {
        "revision": "337f4b2e43c3cf38ea5e9449d7c7ff89e6a08ac6",
        "version": "7.5.0"
      }
    },
    {
      "identity": "snapkit",
      "kind": "remoteSourceControl",
      "location": "https://github.com/SnapKit/SnapKit.git",
      "state": {
        "revision": "f222cbdf325885926566172f6f5f06af95473158",
        "version": "5.7.0"
      }
    },
    {
      "identity": "swiftuix",
      "kind": "remoteSourceControl",
      "location": "https://github.com/SwiftUIX/SwiftUIX.git",
      "state": {
        "branch": "master",
        "revision": "0d0e372760e596a429a8c75166e00fafc40126cb"
      }
    },
    {
      "identity": "zipfoundation",
      "kind": "remoteSourceControl",
      "location": "https://github.com/weichsel/ZIPFoundation.git",
      "state": {
        "revision": "b979e8b52c7ae7f3f07401f5e91f8eeef7e5dcae",
        "version": "0.9.18"
      }
    }
  ],
  "version": 2
}
JSON
        continue
    fi

    # Update URLs to ensure they match the expected ones
    jq '.pins |= map(if .identity == "cryptoswift" then .location = "https://github.com/krzyzanowskim/CryptoSwift.git" else . end)' "$FILE" |
    jq '.pins |= map(if .identity == "snapkit" then .location = "https://github.com/SnapKit/SnapKit.git" else . end)' |
    jq '.pins |= map(if .identity == "lottie-spm" then .location = "https://github.com/airbnb/lottie-spm.git" else . end)' |
    jq '.pins |= map(if .identity == "swiftuix" then .location = "https://github.com/SwiftUIX/SwiftUIX.git" else . end)' |
    jq '.pins |= map(if .identity == "moya" then .location = "https://github.com/Moya/Moya.git" else . end)' |
    jq '.pins |= map(if .identity == "r.swift" then .location = "https://github.com/mac-cain13/R.swift.git" else . end)' |
    jq '.pins |= map(if .identity == "zipfoundation" then .location = "https://github.com/weichsel/ZIPFoundation.git" else . end)' > "$FILE.fixed"

    # Apply the fix
    mv "$FILE.fixed" "$FILE"
    echo "Fixed package URLs in $FILE"
done

echo "Fixed all package.resolved files"
