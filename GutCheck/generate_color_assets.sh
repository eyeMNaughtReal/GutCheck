#!/bin/bash

# GutCheck Color Assets Generator
# This script creates all color assets with proper light/dark mode support
# Run this script from your project root directory

echo "🎨 GutCheck Color Assets Generator"
echo "=================================="
echo ""

# Set the path to Assets.xcassets
ASSETS_PATH="GutCheck/Assets.xcassets"

# Check if Assets.xcassets exists
if [ ! -d "$ASSETS_PATH" ]; then
    echo "❌ Error: $ASSETS_PATH not found!"
    echo "Please run this script from your project root directory."
    exit 1
fi

echo "✅ Found Assets.xcassets at: $ASSETS_PATH"
echo ""

# Function to create a color asset with light and dark mode variants
create_color_asset() {
    local color_name=$1
    local light_hex=$2
    local dark_hex=$3
    local color_path="$ASSETS_PATH/${color_name}.colorset"
    
    echo "   Creating ${color_name}..."
    
    # Create directory
    mkdir -p "$color_path"
    
    # Convert hex to RGB
    light_r=$(printf "%d" 0x${light_hex:1:2})
    light_g=$(printf "%d" 0x${light_hex:3:2})
    light_b=$(printf "%d" 0x${light_hex:5:2})
    
    dark_r=$(printf "%d" 0x${dark_hex:1:2})
    dark_g=$(printf "%d" 0x${dark_hex:3:2})
    dark_b=$(printf "%d" 0x${dark_hex:5:2})
    
    # Create Contents.json with light and dark appearances
    cat > "$color_path/Contents.json" << EOF
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$(awk "BEGIN {printf \"%.3f\", $light_b/255}")",
          "green" : "$(awk "BEGIN {printf \"%.3f\", $light_g/255}")",
          "red" : "$(awk "BEGIN {printf \"%.3f\", $light_r/255}")"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "$(awk "BEGIN {printf \"%.3f\", $dark_b/255}")",
          "green" : "$(awk "BEGIN {printf \"%.3f\", $dark_g/255}")",
          "red" : "$(awk "BEGIN {printf \"%.3f\", $dark_r/255}")"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
}

echo "📝 Creating Primary Colors..."
create_color_asset "PrimaryColor" "#0891B2" "#06B6D4"
create_color_asset "AccentColor" "#F97316" "#FB923C"
create_color_asset "SecondaryColor" "#8B5CF6" "#A78BFA"

echo ""
echo "📝 Creating Background Colors..."
create_color_asset "BackgroundColor" "#FFFFFF" "#0F172A"
create_color_asset "CardBackground" "#F8FAFC" "#1E293B"
create_color_asset "SurfaceColor" "#F1F5F9" "#334155"

echo ""
echo "📝 Creating Text Colors..."
create_color_asset "PrimaryText" "#0F172A" "#F8FAFC"
create_color_asset "SecondaryText" "#475569" "#CBD5E1"
create_color_asset "TertiaryText" "#94A3B8" "#64748B"

echo ""
echo "📝 Creating Semantic Colors..."
create_color_asset "SuccessColor" "#10B981" "#34D399"
create_color_asset "WarningColor" "#F59E0B" "#FBBF24"
create_color_asset "ErrorColor" "#EF4444" "#F87171"
create_color_asset "InfoColor" "#3B82F6" "#60A5FA"

echo ""
echo "📝 Creating Interactive Element Colors..."
create_color_asset "BorderColor" "#E2E8F0" "#334155"
create_color_asset "DisabledColor" "#CBD5E1" "#475569"
create_color_asset "InputBackground" "#F8FAFC" "#1E293B"

echo ""
echo "📝 Creating Feature-Specific Colors..."
create_color_asset "SymptomColor" "#EC4899" "#F472B6"

echo ""
echo "=================================="
echo "✅ All color assets created successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Open your Xcode project"
echo "2. The colors should now appear in Assets.xcassets"
echo "3. If Xcode is already open, you may need to:"
echo "   - Close and reopen the project, OR"
echo "   - Clean build folder (Cmd+Shift+K)"
echo "4. Build and run your app"
echo ""
echo "🎨 Colors created:"
echo "   • PrimaryColor (Teal)"
echo "   • AccentColor (Orange)"
echo "   • SecondaryColor (Violet)"
echo "   • BackgroundColor"
echo "   • CardBackground"
echo "   • SurfaceColor"
echo "   • PrimaryText"
echo "   • SecondaryText"
echo "   • TertiaryText"
echo "   • SuccessColor (Green)"
echo "   • WarningColor (Amber)"
echo "   • ErrorColor (Red)"
echo "   • InfoColor (Blue)"
echo "   • BorderColor"
echo "   • DisabledColor"
echo "   • InputBackground"
echo "   • SymptomColor (Pink)"
echo ""
echo "🌓 All colors support both Light and Dark mode!"
echo ""

