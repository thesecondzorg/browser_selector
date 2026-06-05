# BrowserSelector

BrowserSelector is a lightweight, native macOS application designed to act as your system's default web browser. Instead of opening links in a single, hardcoded browser, BrowserSelector intercepts clicked links (e.g., from Slack, Teams, Notes, or Terminal) and displays a sleek popup menu allowing you to choose exactly which browser you want to use for that specific link.

It runs entirely in the background without cluttering your Dock and dynamically detects all web browsers installed on your Mac.

## Features
- **Dynamic Detection**: Automatically finds all installed browsers (Safari, Chrome, Firefox, Arc, etc.).
- **Browser Profiles Integration**: Automatically detects and separates individual profiles for Chromium-based browsers (Chrome, Edge, Brave, Opera, Vivaldi) and Firefox.
- **Background Agent**: Runs silently. Only appears when you actually click a link.
- **Native UI**: Built with SwiftUI for a fast, modern, and native macOS experience.
- **No Xcode Required**: Can be compiled directly from the terminal using the Swift compiler.

## Prerequisites
- macOS 11.0 or later.
- Swift compiler (comes with Xcode Command Line Tools. Install via `xcode-select --install` if you don't have it).

## Installation

We've provided a simple installation script that compiles the app, moves it to your Applications folder, and registers it with macOS Launch Services so it can be recognized as a default browser.

1. Clone or download this repository.
2. Open Terminal and navigate to the directory:
   ```bash
   cd /path/to/browser_selector
   ```
3. Run the installation script:
   ```bash
   ./install.sh
   ```
   *(If you get a permission error, run `chmod +x install.sh` first).*

## Setup

After running the installation script, you must tell macOS to use it:

1. **Launch it once manually**: Open your `~/Applications` folder and double-click `BrowserSelector.app`. You won't see a window appear (since it runs in the background), but this step is required to register it with the system.
2. **Set as Default Browser**: 
   - Open macOS **System Settings**.
   - Navigate to **Desktop & Dock**.
   - Scroll down to the **Default web browser** dropdown.
   - Select **BrowserSelector**.

## Usage

Simply click any `http` or `https` link in a non-browser application (like Slack or Apple Notes). The BrowserSelector popup will appear. Click the browser icon of your choice, and the link will immediately open in that app. Press `Escape` if you want to cancel and not open the link.

## Modifying the App

If you want to edit the Swift code (e.g., in `ContentView.swift`), simply make your changes and run `./install.sh` again to rebuild and install the updated app.
