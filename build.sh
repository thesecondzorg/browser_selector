#!/bin/bash
set -e

APP_NAME="BrowserSelector"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."

# Clean previous build
rm -rf "$APP_DIR"

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile Swift files
swiftc main.swift AppDelegate.swift BrowserManager.swift ContentView.swift \
    -o "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/"

echo "Build complete. App is at $PWD/$APP_DIR"
