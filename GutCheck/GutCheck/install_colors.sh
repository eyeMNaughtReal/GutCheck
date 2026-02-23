#!/bin/bash

# Color Asset Installer for GutCheck
# This script copies the color assets to your Xcode Assets catalog

echo "🎨 GutCheck Color Asset Installer"
echo "=================================="
echo ""

# Find the Assets.xcassets directory
ASSETS_DIR=$(find . -name "Assets.xcassets" -type d | grep -v "ColorAssets" | head -n 1)

if [ -z "$ASSETS_DIR" ]; then
    echo "❌ Error: Could not find Assets.xcassets in your project"
    echo ""
    echo "Please ensure you're running this script from your project root directory."
    echo "Your project structure should include an Assets.xcassets folder."
    exit 1
fi

echo "✅ Found Assets catalog: $ASSETS_DIR"
echo ""

# Check if ColorAssets directory exists
if [ ! -d "ColorAssets" ]; then
    echo "❌ Error: ColorAssets directory not found"
    echo ""
    echo "Make sure the ColorAssets folder is in the same directory as this script."
    exit 1
fi

echo "📦 Found color assets to install"
echo ""

# Count color sets
COLOR_COUNT=$(find ColorAssets -name "*.colorset" -type d | wc -l | tr -d ' ')
echo "Found $COLOR_COUNT color sets to install:"
echo ""

# List the colors
find ColorAssets -name "*.colorset" -type d -exec basename {} \; | sed 's/.colorset//' | sort | sed 's/^/  • /'
echo ""

# Ask for confirmation
read -p "Install these colors to $ASSETS_DIR? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "🚀 Installing colors..."
echo ""

# Copy each colorset
INSTALLED=0
FAILED=0

for colorset in ColorAssets/*.colorset; do
    if [ -d "$colorset" ]; then
        COLOR_NAME=$(basename "$colorset")
        
        # Check if it already exists
        if [ -d "$ASSETS_DIR/$COLOR_NAME" ]; then
            echo "⚠️  $COLOR_NAME already exists - skipping"
        else
            cp -r "$colorset" "$ASSETS_DIR/"
            if [ $? -eq 0 ]; then
                echo "✅ Installed $COLOR_NAME"
                ((INSTALLED++))
            else
                echo "❌ Failed to install $COLOR_NAME"
                ((FAILED++))
            fi
        fi
    fi
done

echo ""
echo "=================================="
echo "🎉 Installation Complete!"
echo ""
echo "Installed: $INSTALLED colors"
if [ $FAILED -gt 0 ]; then
    echo "Failed: $FAILED colors"
fi
echo ""
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Navigate to Assets.xcassets"
echo "3. Verify all colors are present"
echo "4. Clean build folder (⌘⇧K)"
echo "5. Build and run (⌘R)"
echo ""
echo "Your app will now automatically support light and dark mode! ✨"

