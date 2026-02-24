# 🔧 Fix: Color Asset Name Conflicts

## Problem
Xcode is generating symbol names from your color assets that conflict with SwiftUI's built-in colors:
- `PrimaryColor` → `.primary` (conflicts with `Color.primary`)
- `SecondaryColor` → `.secondary` (conflicts with `Color.secondary`)

## ✅ Solution

I've already updated `ColorTheme.swift` to use non-conflicting names. Now you need to **rename the color assets in Xcode**.

---

## Step-by-Step Fix

### Option 1: Rename Existing Assets (If you already ran the script)

1. **Open Xcode**
2. **Navigate to Assets.xcassets**
3. **Rename each color** by right-clicking → Rename:

| Old Name | New Name |
|----------|----------|
| `PrimaryColor` | `GutCheckPrimary` |
| `AccentColor` | `GutCheckAccent` |
| `SecondaryColor` | `GutCheckSecondary` |
| `BackgroundColor` | `GutCheckBackground` |
| `CardBackground` | `GutCheckCardBackground` |
| `SurfaceColor` | `GutCheckSurface` |
| `PrimaryText` | `GutCheckPrimaryText` |
| `SecondaryText` | `GutCheckSecondaryText` |
| `TertiaryText` | `GutCheckTertiaryText` |
| `SuccessColor` | `GutCheckSuccess` |
| `WarningColor` | `GutCheckWarning` |
| `ErrorColor` | `GutCheckError` |
| `InfoColor` | `GutCheckInfo` |
| `BorderColor` | `GutCheckBorder` |
| `DisabledColor` | `GutCheckDisabled` |
| `InputBackground` | `GutCheckInputBackground` |
| `SymptomColor` | `GutCheckSymptom` |

4. **Clean Build** (Cmd+Shift+K)
5. **Build & Run**

---

### Option 2: Delete Old Assets and Create New (Recommended)

If renaming is tedious:

1. **Open Xcode** → Navigate to `Assets.xcassets`
2. **Delete all the old color assets** (select and press Delete)
3. **Use the updated Python script below**

---

## Updated Python Script

Save this as `create_colors.py` and run it:

```python
#!/usr/bin/env python3
import os
import json
from pathlib import Path

COLORS = {
    "GutCheckPrimary": ("#0891B2", "#06B6D4"),
    "GutCheckAccent": ("#F97316", "#FB923C"),
    "GutCheckSecondary": ("#8B5CF6", "#A78BFA"),
    "GutCheckBackground": ("#FFFFFF", "#0F172A"),
    "GutCheckCardBackground": ("#F8FAFC", "#1E293B"),
    "GutCheckSurface": ("#F1F5F9", "#334155"),
    "GutCheckPrimaryText": ("#0F172A", "#F8FAFC"),
    "GutCheckSecondaryText": ("#475569", "#CBD5E1"),
    "GutCheckTertiaryText": ("#94A3B8", "#64748B"),
    "GutCheckSuccess": ("#10B981", "#34D399"),
    "GutCheckWarning": ("#F59E0B", "#FBBF24"),
    "GutCheckError": ("#EF4444", "#F87171"),
    "GutCheckInfo": ("#3B82F6", "#60A5FA"),
    "GutCheckBorder": ("#E2E8F0", "#334155"),
    "GutCheckDisabled": ("#CBD5E1", "#475569"),
    "GutCheckInputBackground": ("#F8FAFC", "#1E293B"),
    "GutCheckSymptom": ("#EC4899", "#F472B6"),
}

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0
    return (r, g, b)

def create_color_json(light_hex, dark_hex):
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
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
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
        "info": {"author": "xcode", "version": 1}
    }

assets_path = Path("GutCheck/Assets.xcassets")
if not assets_path.exists():
    print(f"❌ Error: {assets_path} not found!")
    exit(1)

print("🎨 Creating GutCheck color assets...")
for color_name, (light_hex, dark_hex) in COLORS.items():
    print(f"   Creating {color_name}...")
    colorset_path = assets_path / f"{color_name}.colorset"
    colorset_path.mkdir(exist_ok=True)
    color_json = create_color_json(light_hex, dark_hex)
    with open(colorset_path / "Contents.json", 'w') as f:
        json.dump(color_json, f, indent=2)

print(f"\n✅ Created {len(COLORS)} color assets!")
print("Now clean build in Xcode and run.")
```

**Run it:**
```bash
cd /Users/markconley/Documents/GutCheck/GutCheck
python3 create_colors.py
```

---

## What Changed

### ColorTheme.swift - ALREADY UPDATED ✅

The `ColorTheme.swift` file now references the new names:

```swift
static let primary = Color("GutCheckPrimary", bundle: nil)
static let accent = Color("GutCheckAccent", bundle: nil)
static let secondary = Color("GutCheckSecondary", bundle: nil)
// etc...
```

### Asset Names

**Old (Conflicting):**
- `PrimaryColor` → `.primary` ❌ Conflicts with SwiftUI
- `SecondaryColor` → `.secondary` ❌ Conflicts with SwiftUI

**New (Non-conflicting):**
- `GutCheckPrimary` → `.gutCheckPrimary` ✅ No conflict
- `GutCheckSecondary` → `.gutCheckSecondary` ✅ No conflict

---

## After Fixing

1. **Clean Build Folder** (Cmd+Shift+K)
2. **Delete DerivedData** (optional but recommended):
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```
3. **Build & Run**
4. **The warnings should be gone!** ✅

---

## Quick Manual Fix (Fastest)

If you just want to fix the two conflicting ones:

1. Open `Assets.xcassets` in Xcode
2. Right-click `PrimaryColor` → Rename → `GutCheckPrimary`
3. Right-click `SecondaryColor` → Rename → `GutCheckSecondary`
4. Clean & Build

(The other colors will still have warnings but won't break the build)

---

## Summary

✅ `ColorTheme.swift` - Updated with new names  
⏳ Color Assets - Need to be renamed/recreated  
✅ Python script - Updated with new names  

**Next:** Run the Python script or manually rename assets in Xcode.
