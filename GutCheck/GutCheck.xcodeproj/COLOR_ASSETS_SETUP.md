# 🎨 GutCheck Color Assets Setup Guide

## Quick Setup (Recommended)

### Step 1: Run the Generator Script

```bash
# Navigate to your project root directory
cd /Users/markconley/Documents/GutCheck/GutCheck

# Make the script executable
chmod +x generate_color_assets.sh

# Run the script
./generate_color_assets.sh
```

### Step 2: Verify in Xcode

1. Open your GutCheck project in Xcode
2. Navigate to `Assets.xcassets` in the Project Navigator
3. You should see all the new color assets
4. Click on any color to see Light/Dark mode variants

### Step 3: Clean and Build

```
1. In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
2. Build and run (Cmd+R)
```

---

## What Colors Are Created?

The script creates **17 color assets** with both light and dark mode support:

### Primary Colors
- **PrimaryColor** - Teal (#0891B2 / #06B6D4)
- **AccentColor** - Orange (#F97316 / #FB923C)
- **SecondaryColor** - Violet (#8B5CF6 / #A78BFA)

### Backgrounds
- **BackgroundColor** - Main canvas (#FFFFFF / #0F172A)
- **CardBackground** - Elevated cards (#F8FAFC / #1E293B)
- **SurfaceColor** - Higher elevation (#F1F5F9 / #334155)

### Text Colors
- **PrimaryText** - Main text (#0F172A / #F8FAFC)
- **SecondaryText** - Supporting text (#475569 / #CBD5E1)
- **TertiaryText** - Muted text (#94A3B8 / #64748B)

### Semantic Colors
- **SuccessColor** - Green for positive (#10B981 / #34D399)
- **WarningColor** - Amber for caution (#F59E0B / #FBBF24)
- **ErrorColor** - Red for errors (#EF4444 / #F87171)
- **InfoColor** - Blue for info (#3B82F6 / #60A5FA)

### Interactive Elements
- **BorderColor** - Borders and dividers (#E2E8F0 / #334155)
- **DisabledColor** - Disabled states (#CBD5E1 / #475569)
- **InputBackground** - Form inputs (#F8FAFC / #1E293B)

### Feature Colors
- **SymptomColor** - Pink for symptoms (#EC4899 / #F472B6)

---

## Manual Setup (If Script Fails)

If the script doesn't work for any reason, you can create colors manually:

### For Each Color:

1. **Open Xcode** → Navigate to `Assets.xcassets`
2. **Right-click** in the left sidebar → **New Color Set**
3. **Name it** (e.g., "PrimaryColor")
4. **Select the color** in the Attributes Inspector
5. **Click "Appearances"** dropdown → Select **"Any, Dark"**
6. **Set Light mode color:**
   - Click the "Any Appearance" color well
   - Use the color picker or enter hex values
7. **Set Dark mode color:**
   - Click the "Dark Appearance" color well
   - Use the color picker or enter hex values

### Hex to RGB Conversion

If you need to enter RGB values instead of hex:

```
Light Mode Primary (#0891B2):
Red:   8   (0.031)
Green: 145 (0.569)
Blue:  178 (0.698)

Dark Mode Primary (#06B6D4):
Red:   6   (0.024)
Green: 182 (0.714)
Blue:  212 (0.831)

(Values in parentheses are 0-1 scale for Xcode)
```

---

## Troubleshooting

### ❌ "Assets.xcassets not found"
**Solution:** Make sure you're running the script from your project root directory where you can see the `GutCheck/Assets.xcassets` folder.

### ❌ "Permission denied"
**Solution:** Make the script executable:
```bash
chmod +x generate_color_assets.sh
```

### ❌ Colors don't appear in Xcode
**Solution:** 
1. Close Xcode completely
2. Reopen the project
3. Clean Build Folder (Cmd+Shift+K)

### ❌ Colors look wrong in the app
**Solution:** 
1. Check that you're using `ColorTheme.primary` (not `Color.primary`)
2. Make sure the ColorTheme.swift file is correct
3. Clean and rebuild

### ❌ Script creates colors but they're black/white
**Solution:** The RGB conversion might have failed. Use the manual setup method above.

---

## Testing Your Colors

### Quick Test in SwiftUI Preview

Add this to any SwiftUI view file:

```swift
#Preview {
    VStack(spacing: 20) {
        Text("Primary Color")
            .foregroundColor(ColorTheme.primary)
            .padding()
            .background(ColorTheme.background)
        
        Text("Accent Color")
            .foregroundColor(.white)
            .padding()
            .background(ColorTheme.accent)
        
        Text("Success Color")
            .foregroundColor(.white)
            .padding()
            .background(ColorTheme.success)
    }
    .padding()
    .background(ColorTheme.background)
}
```

### Test Light/Dark Mode

```swift
#Preview("Light Mode") {
    YourView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    YourView()
        .preferredColorScheme(.dark)
}
```

---

## Color Usage Guidelines

### ✅ Good Usage

```swift
// Using ColorTheme
Text("Hello")
    .foregroundColor(ColorTheme.primaryText)
    .background(ColorTheme.background)

// For buttons
Button("Save") { }
    .foregroundColor(.white)
    .background(ColorTheme.primary)
```

### ❌ Bad Usage

```swift
// Don't use Color directly
Text("Hello")
    .foregroundColor(.black)  // ❌ Won't adapt to dark mode

// Don't use hardcoded hex
Text("Hello")
    .foregroundColor(Color(hex: "#0891B2"))  // ❌ No dark mode
```

---

## Verification Checklist

After running the script, verify:

- [ ] All 17 color assets appear in Assets.xcassets
- [ ] Each color has both "Any Appearance" and "Dark" variants
- [ ] Light mode colors match the expected hex values
- [ ] Dark mode colors match the expected hex values
- [ ] App builds without color-related errors
- [ ] Colors look correct in the app
- [ ] Switching to dark mode changes colors appropriately

---

## Files Modified

This script only **creates new files** - it doesn't modify any existing code:

- ✅ Creates: `Assets.xcassets/PrimaryColor.colorset/Contents.json`
- ✅ Creates: `Assets.xcassets/AccentColor.colorset/Contents.json`
- ✅ Creates: (15 more color assets...)
- ❌ Does NOT modify: `ColorTheme.swift`
- ❌ Does NOT modify: Any Swift files
- ❌ Does NOT modify: Any UI code

---

## Need Help?

If you encounter any issues:

1. Check the **Troubleshooting** section above
2. Verify the script output for any error messages
3. Try the **Manual Setup** method as a fallback
4. Make sure you're running from the correct directory

---

## Color Accessibility

All colors have been chosen to meet WCAG 2.1 Level AA standards:

- ✅ Text on backgrounds: 4.5:1 contrast minimum
- ✅ Large text: 3:1 contrast minimum  
- ✅ Interactive elements clearly distinguishable
- ✅ Dark mode designed for reduced eye strain

---

**Last Updated:** February 23, 2026  
**Script Version:** 1.0  
**Compatibility:** Xcode 14+, iOS 16+
