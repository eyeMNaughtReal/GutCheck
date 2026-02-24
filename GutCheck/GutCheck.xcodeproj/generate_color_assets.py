#!/usr/bin/env python3
"""
GutCheck Color Assets Generator (Python version)
Alternative to the bash script for Windows/cross-platform compatibility
"""

import os
import json
from pathlib import Path

# Color definitions (Light mode hex / Dark mode hex)
COLORS = {
    "PrimaryColor": ("#0891B2", "#06B6D4"),
    "AccentColor": ("#F97316", "#FB923C"),
    "SecondaryColor": ("#8B5CF6", "#A78BFA"),
    "BackgroundColor": ("#FFFFFF", "#0F172A"),
    "CardBackground": ("#F8FAFC", "#1E293B"),
    "SurfaceColor": ("#F1F5F9", "#334155"),
    "PrimaryText": ("#0F172A", "#F8FAFC"),
    "SecondaryText": ("#475569", "#CBD5E1"),
    "TertiaryText": ("#94A3B8", "#64748B"),
    "SuccessColor": ("#10B981", "#34D399"),
    "WarningColor": ("#F59E0B", "#FBBF24"),
    "ErrorColor": ("#EF4444", "#F87171"),
    "InfoColor": ("#3B82F6", "#60A5FA"),
    "BorderColor": ("#E2E8F0", "#334155"),
    "DisabledColor": ("#CBD5E1", "#475569"),
    "InputBackground": ("#F8FAFC", "#1E293B"),
    "SymptomColor": ("#EC4899", "#F472B6"),
}


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple (0-1 scale)"""
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0
    return (r, g, b)


def create_color_json(light_hex, dark_hex):
    """Create the Contents.json structure for a color asset"""
    light_r, light_g, light_b = hex_to_rgb(light_hex)
    dark_r, dark_g, dark_b = hex_to_rgb(dark_hex)
    
    return {
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "alpha": "1.000",
                        "blue": f"{light_b:.3f}",
                        "green": f"{light_g:.3f}",
                        "red": f"{light_r:.3f}"
                    }
                },
                "idiom": "universal"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark"
                    }
                ],
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "alpha": "1.000",
                        "blue": f"{dark_b:.3f}",
                        "green": f"{dark_g:.3f}",
                        "red": f"{dark_r:.3f}"
                    }
                },
                "idiom": "universal"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }


def main():
    print("🎨 GutCheck Color Assets Generator (Python)")
    print("=" * 50)
    print()
    
    # Find Assets.xcassets path
    assets_path = Path("GutCheck/Assets.xcassets")
    
    if not assets_path.exists():
        print(f"❌ Error: {assets_path} not found!")
        print("Please run this script from your project root directory.")
        return 1
    
    print(f"✅ Found Assets.xcassets at: {assets_path}")
    print()
    
    created_count = 0
    
    for color_name, (light_hex, dark_hex) in COLORS.items():
        print(f"   Creating {color_name}...")
        
        # Create colorset directory
        colorset_path = assets_path / f"{color_name}.colorset"
        colorset_path.mkdir(exist_ok=True)
        
        # Create Contents.json
        color_json = create_color_json(light_hex, dark_hex)
        contents_path = colorset_path / "Contents.json"
        
        with open(contents_path, 'w') as f:
            json.dump(color_json, f, indent=2)
        
        created_count += 1
    
    print()
    print("=" * 50)
    print(f"✅ Successfully created {created_count} color assets!")
    print()
    print("📋 Next Steps:")
    print("1. Open your Xcode project")
    print("2. The colors should now appear in Assets.xcassets")
    print("3. If Xcode is already open:")
    print("   - Close and reopen the project, OR")
    print("   - Clean build folder (Cmd+Shift+K)")
    print("4. Build and run your app")
    print()
    print("🎨 Colors created with Light/Dark mode support:")
    for color_name, (light_hex, dark_hex) in COLORS.items():
        print(f"   • {color_name}: {light_hex} / {dark_hex}")
    print()
    
    return 0


if __name__ == "__main__":
    exit(main())
