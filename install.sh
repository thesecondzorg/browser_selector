#!/bin/bash
set -e

APP_NAME="BrowserSelector"
SOURCE_APP_DIR="${APP_NAME}.app"
INSTALL_DIR="$HOME/Applications"
TARGET_APP_DIR="${INSTALL_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
./build.sh

echo "Installing to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_APP_DIR"
cp -R "$SOURCE_APP_DIR" "$INSTALL_DIR/"

echo "Registering app with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$TARGET_APP_DIR"

echo ""
echo "Installation complete!"
echo "Please do the following to complete setup:"
echo "1. Run the app once: open \"$TARGET_APP_DIR\""
echo "2. Open System Settings > Desktop & Dock"
echo "3. Select '$APP_NAME' in the 'Default web browser' dropdown."
