#!/bin/bash

set -e

echo "📱 Finding available iOS simulators..."

# Get available destinations from xcodebuild and find iPhone simulators
IOS_DEVICE=$(xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile -showdestinations 2>/dev/null | \
    grep "platform:iOS Simulator" | \
    grep -v "placeholder" | \
    grep "iPhone" | \
    head -1 | \
    sed -n 's/.*id:\([^,]*\).*/\1/p')

if [ -z "$IOS_DEVICE" ]; then
    echo "🔍 No iPhone simulators found, trying any iOS Simulator..."
    
    # Fallback: Get any iOS simulator (including iPads)
    IOS_DEVICE=$(xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile -showdestinations 2>/dev/null | \
        grep "platform:iOS Simulator" | \
        grep -v "placeholder" | \
        head -1 | \
        sed -n 's/.*id:\([^,]*\).*/\1/p')
fi

if [ -z "$IOS_DEVICE" ]; then
    echo "🔍 No real simulators found, trying placeholder iOS Simulator for CI..."
    
    # CI Fallback: Use placeholder simulator (for GitHub Actions)
    IOS_DEVICE=$(xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile -showdestinations 2>/dev/null | \
        grep "platform:iOS Simulator" | \
        grep "placeholder" | \
        head -1 | \
        sed -n 's/.*id:\([^,]*\).*/\1/p')
fi

if [ -z "$IOS_DEVICE" ]; then
    echo "❌ No available iOS simulators found"
    echo "Available destinations:"
    xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile -showdestinations
    exit 1
fi

echo "✅ Using iOS Simulator ID: $IOS_DEVICE"

echo "🧪 Running Xcode tests..."
xcodebuild test \
  -project Anchor.xcodeproj \
  -scheme AnchorMobile \
  -destination "platform=iOS Simulator,id=$IOS_DEVICE" \
  -enableCodeCoverage YES \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM=""

echo "✅ Tests completed successfully!"