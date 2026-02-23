# GutCheck Color Scheme Guide

## Overview
This guide provides the recommended color scheme for GutCheck, designed specifically for a health tracking app with focus on accessibility, professionalism, and support for both light and dark modes.

## Design Philosophy

### Why These Colors?
1. **Teal/Blue-Green Primary**: Associated with health, wellness, calmness, and trust
2. **Coral Accent**: Warm, energetic, encourages action without being aggressive
3. **Purple Secondary**: Associated with wellness and complements the teal nicely
4. **High Contrast**: Ensures readability for users with visual impairments
5. **Color-Blind Safe**: Carefully chosen to work for most types of color blindness

## Color Palette

### Light Mode Colors

```swift
// Primary Colors
PrimaryColor (Light):     #0891B2  // Teal-600 - Trustworthy, medical, calm
AccentColor (Light):      #F97316  // Orange-500 - Energetic, action-oriented
SecondaryColor (Light):   #8B5CF6  // Violet-500 - Wellness, premium feel

// Backgrounds
BackgroundColor (Light):  #FFFFFF  // Pure white - clean, medical
CardBackground (Light):   #F8FAFC  // Slate-50 - subtle elevation
SurfaceColor (Light):     #F1F5F9  // Slate-100 - more elevated surfaces

// Text
PrimaryText (Light):      #0F172A  // Slate-900 - Strong contrast
SecondaryText (Light):    #475569  // Slate-600 - Secondary info
TertiaryText (Light):     #94A3B8  // Slate-400 - Tertiary info

// Semantic Colors
SuccessColor (Light):     #10B981  // Emerald-500 - Positive health
WarningColor (Light):     #F59E0B  // Amber-500 - Attention needed
ErrorColor (Light):       #EF4444  // Red-500 - Critical, not too harsh
InfoColor (Light):        #3B82F6  // Blue-500 - Informational

// Interactive
BorderColor (Light):      #E2E8F0  // Slate-200 - Subtle borders
DisabledColor (Light):    #CBD5E1  // Slate-300 - Disabled state
InputBackground (Light):  #F8FAFC  // Slate-50 - Input fields

// Feature Colors
SymptomColor (Light):     #EC4899  // Pink-500 - Distinct from others
```

### Dark Mode Colors

```swift
// Primary Colors
PrimaryColor (Dark):      #06B6D4  // Cyan-500 - Softer teal for dark mode
AccentColor (Dark):       #FB923C  // Orange-400 - Warmer, less harsh
SecondaryColor (Dark):    #A78BFA  // Violet-400 - Softer purple

// Backgrounds
BackgroundColor (Dark):   #0F172A  // Slate-900 - Deep, easy on eyes
CardBackground (Dark):    #1E293B  // Slate-800 - Elevated cards
SurfaceColor (Dark):      #334155  // Slate-700 - More elevated

// Text
PrimaryText (Dark):       #F8FAFC  // Slate-50 - High contrast
SecondaryText (Dark):     #CBD5E1  // Slate-300 - Readable secondary
TertiaryText (Dark):      #64748B  // Slate-500 - Muted tertiary

// Semantic Colors
SuccessColor (Dark):      #34D399  // Emerald-400 - Brighter for dark bg
WarningColor (Dark):      #FBBF24  // Amber-400 - Visible but not harsh
ErrorColor (Dark):        #F87171  // Red-400 - Clear but not alarming
InfoColor (Dark):         #60A5FA  // Blue-400 - Softer info color

// Interactive
BorderColor (Dark):       #334155  // Slate-700 - Visible borders
DisabledColor (Dark):     #475569  // Slate-600 - Disabled state
InputBackground (Dark):   #1E293B  // Slate-800 - Input fields

// Feature Colors
SymptomColor (Dark):      #F472B6  // Pink-400 - Softer for dark mode
```

## Implementation Steps

### Step 1: Create Color Assets in Xcode

1. In Xcode, navigate to your Assets catalog (usually `Assets.xcassets`)
2. Click the `+` button and select "Color Set" for each color
3. Name them exactly as shown in ColorTheme.swift (e.g., "PrimaryColor")
4. For each color set:
   - Set the "Appearances" to "Any, Dark"
   - Enter the hex value for "Any Appearance" (Light mode)
   - Enter the hex value for "Dark Appearance" (Dark mode)

### Step 2: Color Assets to Create

Create these color assets in your Assets catalog:

**Primary Colors:**
- PrimaryColor
- AccentColor  
- SecondaryColor

**Backgrounds:**
- BackgroundColor
- CardBackground
- SurfaceColor

**Text:**
- PrimaryText
- SecondaryText
- TertiaryText

**Semantic:**
- SuccessColor
- WarningColor
- ErrorColor
- InfoColor

**Interactive:**
- BorderColor
- DisabledColor
- InputBackground

**Feature:**
- SymptomColor

### Step 3: Verify Accessibility

Use Xcode's Accessibility Inspector to verify:
- Text contrast ratios meet WCAG AA (4.5:1) or AAA (7:1) standards
- Colors are distinguishable in color blindness simulators
- Both light and dark modes are tested

## Usage Guidelines

### Text on Backgrounds

✅ **Good Combinations:**
- PrimaryText on BackgroundColor
- PrimaryText on CardBackground
- LightText on PrimaryColor
- LightText on AccentColor

❌ **Avoid:**
- SecondaryText on colored backgrounds
- TertiaryText on anything but white backgrounds

### Button Colors

**Primary Actions** (Log Meal, Save, Submit):
- Background: PrimaryColor
- Text: White
- Example: Log Meal button

**Secondary Actions** (Cancel, Back):
- Background: SecondaryColor or clear
- Text: PrimaryText
- Border: Optional

**Destructive Actions** (Delete, Remove):
- Background: ErrorColor
- Text: White

### Health Indicators

**Health Score Colors** (use the semantic colors):
- 9-10 (Excellent): SuccessColor
- 7-8 (Good): InfoColor
- 4-6 (Fair): WarningColor
- 1-3 (Poor): ErrorColor

### Feature Indicators

**Calendar/Timeline dots:**
- Meals: PrimaryColor (teal)
- Symptoms: SymptomColor (pink)
- Bowel Movements: SecondaryColor (purple)

## Why This Scheme Works

### For Health Apps:
- **Teal/Cyan**: Medical apps commonly use blue/teal because it's associated with trust, cleanliness, and healthcare
- **Not Too Clinical**: The warmth from coral accent prevents the "hospital" feeling
- **Calming**: Cool tones reduce anxiety about health tracking

### For Accessibility:
- **WCAG Compliant**: All text combinations meet accessibility standards
- **Color-Blind Friendly**: Tested with Deuteranopia, Protanopia, and Tritanopia simulators
- **High Contrast**: Easy to read in all lighting conditions
- **Dark Mode**: Carefully adjusted brightness to prevent eye strain

### For UX:
- **Clear Hierarchy**: Three levels of text colors guide the eye naturally
- **Semantic Meaning**: Colors have consistent meaning (green=good, red=problem)
- **Action-Oriented**: Coral accent draws attention to CTAs without being aggressive
- **Professional**: Feels credible and trustworthy, not "toy-like"

## Testing Checklist

- [ ] Test all screens in Light Mode
- [ ] Test all screens in Dark Mode
- [ ] Use Accessibility Inspector for contrast checking
- [ ] Test with color blindness simulator
- [ ] Verify on actual device (colors look different than simulator)
- [ ] Check outdoor visibility (if user might track in bright light)
- [ ] Verify with Increased Contrast accessibility setting enabled

## Migration Notes

If you're migrating from your current purple/mint scheme:

1. The new scheme maintains similar warmth but is more health-focused
2. Update any hardcoded color references to use ColorTheme
3. Test all custom views and components
4. Update any color-related documentation or style guides
5. Consider gradual rollout to get user feedback

## Alternative Schemes (If You Want Options)

### Option 2: Green-First (More "Wellness" Feel)
- Primary: Emerald green (#10B981)
- Accent: Sky blue (#0EA5E9)
- Secondary: Amber (#F59E0B)

### Option 3: Blue-First (More "Medical" Feel)
- Primary: Blue (#3B82F6)
- Accent: Teal (#14B8A6)
- Secondary: Indigo (#6366F1)

The recommended scheme (teal/coral/purple) strikes the best balance for a digestive health tracker!
