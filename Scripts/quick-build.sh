#!/bin/bash

# Quick build script for local testing
# Creates a simple .app bundle without DMG

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Quick Build - macToSearch${NC}"
echo "================================"

# Build configuration
CONFIGURATION="Release"
if [ "$1" == "debug" ]; then
    CONFIGURATION="Debug"
    echo -e "${YELLOW}Building in Debug mode${NC}"
fi

# Clean and build
echo -e "${YELLOW}🔨 Building app...${NC}"
xcodebuild -project macToSearch.xcodeproj \
    -scheme macToSearch \
    -configuration $CONFIGURATION \
    -derivedDataPath build/DerivedData \
    clean build

# Find the built app
APP_PATH=$(find build/DerivedData -name "macToSearch.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Build failed - app not found${NC}"
    exit 1
fi

# Copy to build directory
echo -e "${YELLOW}📦 Copying app...${NC}"
rm -rf build/macToSearch.app
cp -R "$APP_PATH" build/

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo "================================"
echo -e "App location: ${GREEN}build/macToSearch.app${NC}"
echo ""
echo "To run the app:"
echo "  open build/macToSearch.app"
echo ""
echo "To install to Applications:"
echo "  cp -R build/macToSearch.app /Applications/"