#!/bin/bash
# Cosmos — Xcode project setup script
# Run this AFTER installing Xcode from the Mac App Store

set -e

echo "🪐 Setting up Cosmos Xcode project..."

# Check Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install it from the Mac App Store first."
    exit 1
fi

# Check for swift-package-manager / xcodegen
if command -v xcodegen &> /dev/null; then
    echo "✅ XcodeGen found — generating project..."
    xcodegen generate
else
    echo ""
    echo "──────────────────────────────────────────────"
    echo "  Manual Xcode setup (2 minutes):"
    echo ""
    echo "  1. Open Xcode"
    echo "  2. File → New → Project → iOS → App"
    echo "  3. Product Name: Cosmos"
    echo "  4. Team: your Apple ID"
    echo "  5. Interface: SwiftUI  |  Language: Swift"
    echo "  6. Save to: $(pwd)"
    echo ""
    echo "  7. In Xcode: delete ContentView.swift"
    echo "  8. Right-click project → Add Files to 'Cosmos'"
    echo "     Select the Cosmos/ folder → ✅ Copy if needed"
    echo ""
    echo "  9. Run on iPhone simulator"
    echo "──────────────────────────────────────────────"
fi
