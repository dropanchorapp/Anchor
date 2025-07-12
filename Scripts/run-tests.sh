#!/bin/bash

set -e

echo "📱 Finding available iOS simulators..."

# Get available destinations from xcodebuild and extract iOS Simulator
IOS_UDID=$(xcodebuild -project Anchor.xcodeproj -scheme AnchorMobile -showdestinations 2>/dev/null | \
    grep "platform:iOS Simulator" | \
    grep -v "placeholder" | \
    head -1 | \
    sed -n 's/.*id:\([^,]*\).*/\1/p')

if [ -z "$IOS_UDID" ]; then
    echo "❌ No available iOS simulators found"
    exit 1
fi

echo "✅ Using iOS Simulator ID: $IOS_UDID"

echo "🧪 Running Xcode tests..."
xcodebuild test \
  -project Anchor.xcodeproj \
  -scheme AnchorMobile \
  -destination "platform=iOS Simulator,id=$IOS_UDID" \
  -enableCodeCoverage YES \
  -derivedDataPath DerivedData \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM=""

echo "✅ Tests completed successfully!"