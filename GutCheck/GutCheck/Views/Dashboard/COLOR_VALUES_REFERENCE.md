# Color Values Quick Reference

Use this as a quick reference when creating color assets in Xcode.

## How to Add These in Xcode

1. Open `Assets.xcassets` in Xcode
2. Click `+` → "Color Set"
3. Name it exactly as shown below
4. In the Attributes Inspector, set "Appearances" to "Any, Dark"
5. Click the "Any Appearance" color well, choose "Custom" → "RGB Sliders" or "Hex"
6. Enter the Light Mode hex value
7. Click the "Dark Appearance" color well and enter the Dark Mode hex value

---

## Color Asset Values

### PrimaryColor
- **Light Mode**: `#0891B2` (RGB: 8, 145, 178)
- **Dark Mode**: `#06B6D4` (RGB: 6, 182, 212)

### AccentColor
- **Light Mode**: `#F97316` (RGB: 249, 115, 22)
- **Dark Mode**: `#FB923C` (RGB: 251, 146, 60)

### SecondaryColor
- **Light Mode**: `#8B5CF6` (RGB: 139, 92, 246)
- **Dark Mode**: `#A78BFA` (RGB: 167, 139, 250)

---

### BackgroundColor
- **Light Mode**: `#FFFFFF` (RGB: 255, 255, 255)
- **Dark Mode**: `#0F172A` (RGB: 15, 23, 42)

### CardBackground
- **Light Mode**: `#F8FAFC` (RGB: 248, 250, 252)
- **Dark Mode**: `#1E293B` (RGB: 30, 41, 59)

### SurfaceColor
- **Light Mode**: `#F1F5F9` (RGB: 241, 245, 249)
- **Dark Mode**: `#334155` (RGB: 51, 65, 85)

---

### PrimaryText
- **Light Mode**: `#0F172A` (RGB: 15, 23, 42)
- **Dark Mode**: `#F8FAFC` (RGB: 248, 250, 252)

### SecondaryText
- **Light Mode**: `#475569` (RGB: 71, 85, 105)
- **Dark Mode**: `#CBD5E1` (RGB: 203, 213, 225)

### TertiaryText
- **Light Mode**: `#94A3B8` (RGB: 148, 163, 184)
- **Dark Mode**: `#64748B` (RGB: 100, 116, 139)

---

### SuccessColor
- **Light Mode**: `#10B981` (RGB: 16, 185, 129)
- **Dark Mode**: `#34D399` (RGB: 52, 211, 153)

### WarningColor
- **Light Mode**: `#F59E0B` (RGB: 245, 158, 11)
- **Dark Mode**: `#FBBF24` (RGB: 251, 191, 36)

### ErrorColor
- **Light Mode**: `#EF4444` (RGB: 239, 68, 68)
- **Dark Mode**: `#F87171` (RGB: 248, 113, 113)

### InfoColor
- **Light Mode**: `#3B82F6` (RGB: 59, 130, 246)
- **Dark Mode**: `#60A5FA` (RGB: 96, 165, 250)

---

### BorderColor
- **Light Mode**: `#E2E8F0` (RGB: 226, 232, 240)
- **Dark Mode**: `#334155` (RGB: 51, 65, 85)

### DisabledColor
- **Light Mode**: `#CBD5E1` (RGB: 203, 213, 225)
- **Dark Mode**: `#475569` (RGB: 71, 85, 105)

### InputBackground
- **Light Mode**: `#F8FAFC` (RGB: 248, 250, 252)
- **Dark Mode**: `#1E293B` (RGB: 30, 41, 59)

---

### SymptomColor
- **Light Mode**: `#EC4899` (RGB: 236, 72, 153)
- **Dark Mode**: `#F472B6` (RGB: 244, 114, 182)

---

## Visual Preview (Copy to Preview in Notes)

### Light Mode
```
Primary:    ████ Teal-600
Accent:     ████ Orange-500
Secondary:  ████ Violet-500
Background: ████ White
Text:       ████ Slate-900
Success:    ████ Emerald-500
Warning:    ████ Amber-500
Error:      ████ Red-500
```

### Dark Mode
```
Primary:    ████ Cyan-500
Accent:     ████ Orange-400
Secondary:  ████ Violet-400
Background: ████ Slate-900
Text:       ████ Slate-50
Success:    ████ Emerald-400
Warning:    ████ Amber-400
Error:      ████ Red-400
```

---

## Fallback Strategy

If you want to test the colors before creating all the assets, you can temporarily use this code in ColorTheme.swift:

```swift
// Temporary fallback with light/dark mode support
static let primary = Color(light: Color(hex: "0891B2"), dark: Color(hex: "06B6D4"))

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
```

But for production, always use named color assets from the Assets catalog!
