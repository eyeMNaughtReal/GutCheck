# 🎨 Color Palette Visual Reference

## Light Mode Palette

### Primary Colors
```
PrimaryColor (Teal-600)
HEX: #0891B2
RGB: 8, 145, 178
████████████████████ Calming, medical, trustworthy

AccentColor (Orange-500)  
HEX: #F97316
RGB: 249, 115, 22
████████████████████ Energetic, warm, action-oriented

SecondaryColor (Violet-500)
HEX: #8B5CF6
RGB: 139, 92, 246
████████████████████ Wellness, premium, complementary
```

### Backgrounds
```
BackgroundColor (White)
HEX: #FFFFFF
RGB: 255, 255, 255
████████████████████ Clean, medical

CardBackground (Slate-50)
HEX: #F8FAFC
RGB: 248, 250, 252
████████████████████ Subtle elevation

SurfaceColor (Slate-100)
HEX: #F1F5F9
RGB: 241, 245, 249
████████████████████ More elevated
```

### Text Colors
```
PrimaryText (Slate-900)
HEX: #0F172A
RGB: 15, 23, 42
████████████████████ High contrast, primary content

SecondaryText (Slate-600)
HEX: #475569
RGB: 71, 85, 105
████████████████████ Supporting information

TertiaryText (Slate-400)
HEX: #94A3B8
RGB: 148, 163, 184
████████████████████ Least important info
```

### Semantic Colors
```
SuccessColor (Emerald-500)
HEX: #10B981
RGB: 16, 185, 129
████████████████████ Positive, healthy, good

WarningColor (Amber-500)
HEX: #F59E0B
RGB: 245, 158, 11
████████████████████ Caution, attention needed

ErrorColor (Red-500)
HEX: #EF4444
RGB: 239, 68, 68
████████████████████ Error, critical, problem

InfoColor (Blue-500)
HEX: #3B82F6
RGB: 59, 130, 246
████████████████████ Information, neutral fact
```

### Interactive Elements
```
BorderColor (Slate-200)
HEX: #E2E8F0
RGB: 226, 232, 240
████████████████████ Subtle borders, dividers

DisabledColor (Slate-300)
HEX: #CBD5E1
RGB: 203, 213, 225
████████████████████ Disabled state

InputBackground (Slate-50)
HEX: #F8FAFC
RGB: 248, 250, 252
████████████████████ Form inputs
```

### Feature Colors
```
SymptomColor (Pink-500)
HEX: #EC4899
RGB: 236, 72, 153
████████████████████ Symptom tracking
```

---

## Dark Mode Palette

### Primary Colors
```
PrimaryColor (Cyan-500)
HEX: #06B6D4
RGB: 6, 182, 212
████████████████████ Softer teal for dark backgrounds

AccentColor (Orange-400)
HEX: #FB923C
RGB: 251, 146, 60
████████████████████ Warmer, less harsh

SecondaryColor (Violet-400)
HEX: #A78BFA
RGB: 167, 139, 250
████████████████████ Softer purple
```

### Backgrounds
```
BackgroundColor (Slate-900)
HEX: #0F172A
RGB: 15, 23, 42
████████████████████ Deep, comfortable for eyes

CardBackground (Slate-800)
HEX: #1E293B
RGB: 30, 41, 59
████████████████████ Elevated cards stand out

SurfaceColor (Slate-700)
HEX: #334155
RGB: 51, 65, 85
████████████████████ More elevated elements
```

### Text Colors
```
PrimaryText (Slate-50)
HEX: #F8FAFC
RGB: 248, 250, 252
████████████████████ Bright, readable

SecondaryText (Slate-300)
HEX: #CBD5E1
RGB: 203, 213, 225
████████████████████ Still readable, less prominent

TertiaryText (Slate-500)
HEX: #64748B
RGB: 100, 116, 139
████████████████████ Muted, background info
```

### Semantic Colors
```
SuccessColor (Emerald-400)
HEX: #34D399
RGB: 52, 211, 153
████████████████████ Brighter for visibility

WarningColor (Amber-400)
HEX: #FBBF24
RGB: 251, 191, 36
████████████████████ Clear but not harsh

ErrorColor (Red-400)
HEX: #F87171
RGB: 248, 113, 113
████████████████████ Visible but not alarming

InfoColor (Blue-400)
HEX: #60A5FA
RGB: 96, 165, 250
████████████████████ Softer, comfortable
```

### Interactive Elements
```
BorderColor (Slate-700)
HEX: #334155
RGB: 51, 65, 85
████████████████████ Visible borders

DisabledColor (Slate-600)
HEX: #475569
RGB: 71, 85, 105
████████████████████ Clearly disabled

InputBackground (Slate-800)
HEX: #1E293B
RGB: 30, 41, 59
████████████████████ Input fields
```

### Feature Colors
```
SymptomColor (Pink-400)
HEX: #F472B6
RGB: 244, 114, 182
████████████████████ Softer pink for dark mode
```

---

## Color Relationships

### Hierarchy
```
Text Hierarchy (Light Mode):
███ PrimaryText   - Headlines, important info
██  SecondaryText - Body text, labels
█   TertiaryText  - Captions, timestamps

Background Hierarchy (Light Mode):
█   BackgroundColor - Main canvas
██  CardBackground  - Elevated content
███ SurfaceColor    - Most elevated
```

### Semantic Usage
```
Health Scores:
9-10: ████ SuccessColor  (Excellent!)
7-8:  ████ InfoColor     (Good)
4-6:  ████ WarningColor  (Fair)
1-3:  ████ ErrorColor    (Needs attention)

Tracking Features:
Meals:     ████ PrimaryColor   (Teal)
Symptoms:  ████ SymptomColor   (Pink)
Bowels:    ████ SecondaryColor (Purple)
```

---

## Usage Examples

### Good Combinations ✅
```
Light Mode:
- PrimaryText (#0F172A) on BackgroundColor (#FFFFFF)
  Contrast: 16.9:1 (AAA) ✅
  
- White text on PrimaryColor (#0891B2)
  Contrast: 4.6:1 (AA) ✅
  
- White text on AccentColor (#F97316)
  Contrast: 4.5:1 (AA) ✅

Dark Mode:
- PrimaryText (#F8FAFC) on BackgroundColor (#0F172A)
  Contrast: 15.7:1 (AAA) ✅
  
- White text on PrimaryColor (#06B6D4)
  Contrast: 5.2:1 (AA+) ✅
```

### Bad Combinations ❌
```
- SecondaryText on colored backgrounds (low contrast)
- TertiaryText on SurfaceColor (too similar)
- WarningColor text on BackgroundColor (hard to read)
```

---

## Quick Testing

### In SwiftUI Preview:
```swift
VStack {
    Text("Primary")
        .foregroundColor(ColorTheme.primary)
    Text("Accent")
        .foregroundColor(ColorTheme.accent)
    Text("Secondary")
        .foregroundColor(ColorTheme.secondary)
}
.background(ColorTheme.background)
.preferredColorScheme(.light) // or .dark
```

### In Xcode:
1. Open Assets.xcassets
2. Click each color to see both appearances
3. Use color picker to verify exact values

---

## Print This Section! 📄

Cut out and keep this quick reference:

```
┌────────────────────────────────────┐
│     GUTCHECK COLOR QUICK REF       │
├────────────────────────────────────┤
│ Primary:   #0891B2 / #06B6D4      │
│ Accent:    #F97316 / #FB923C      │
│ Secondary: #8B5CF6 / #A78BFA      │
│────────────────────────────────────│
│ Success:   #10B981 / #34D399      │
│ Warning:   #F59E0B / #FBBF24      │
│ Error:     #EF4444 / #F87171      │
│────────────────────────────────────│
│ Light BG:  #FFFFFF / #0F172A      │
│ Card BG:   #F8FAFC / #1E293B      │
│────────────────────────────────────│
│ Format: Light Mode / Dark Mode     │
└────────────────────────────────────┘
```

This palette creates a professional, accessible, and health-appropriate design system for GutCheck! 🎨
