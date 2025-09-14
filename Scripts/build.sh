#!/bin/bash

# macToSearch Build Script
# This script builds the macToSearch app and creates a DMG for distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="macToSearch"
PROJECT_NAME="macToSearch.xcodeproj"
SCHEME="macToSearch"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
DMG_DIR="$BUILD_DIR/DMG"
DMG_NAME="$APP_NAME.dmg"
VERSION=$(defaults read "$PWD/$APP_NAME/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")

echo -e "${GREEN}🚀 Building $APP_NAME v$VERSION${NC}"
echo "================================"

# Clean previous builds
echo -e "${YELLOW}📁 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the archive
echo -e "${YELLOW}🔨 Building archive...${NC}"
xcodebuild -project "$PROJECT_NAME" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "platform=macOS" \
    clean archive

# Check if archive was created
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}❌ Archive creation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive created successfully${NC}"

# Export the app
echo -e "${YELLOW}📦 Exporting app...${NC}"

# Create export options plist
cat > "$BUILD_DIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string></string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist"

# Check if app was exported
if [ ! -d "$EXPORT_PATH/$APP_NAME.app" ]; then
    echo -e "${RED}❌ App export failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ App exported successfully${NC}"

# Create DMG
echo -e "${YELLOW}💿 Creating DMG...${NC}"

mkdir -p "$DMG_DIR"
cp -R "$EXPORT_PATH/$APP_NAME.app" "$DMG_DIR/"

# Create a symbolic link to Applications folder
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$BUILD_DIR/$APP_NAME-v$VERSION.dmg"

# Clean up
rm -rf "$DMG_DIR"
rm -f "$BUILD_DIR/ExportOptions.plist"

echo ""
echo -e "${GREEN}🎉 Build complete!${NC}"
echo "================================"
echo -e "📦 App: ${GREEN}$EXPORT_PATH/$APP_NAME.app${NC}"
echo -e "💿 DMG: ${GREEN}$BUILD_DIR/$APP_NAME-v$VERSION.dmg${NC}"
echo ""
echo "To install, users can:"
echo "  1. Open the DMG file"
echo "  2. Drag $APP_NAME to Applications folder"
echo "  3. Run the app from Applications"