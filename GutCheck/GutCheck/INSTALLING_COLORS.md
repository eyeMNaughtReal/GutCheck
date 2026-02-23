# Installing Color Assets - Step by Step Guide

I've created all the color asset JSON files for you! Here's how to add them to your Xcode project.

## Option 1: Manual Installation (Recommended)

### Step 1: Locate Your Assets Catalog
1. Open your GutCheck project in Xcode
2. In the Project Navigator (left sidebar), look for `Assets.xcassets`
3. Click on it to open the Assets Catalog

### Step 2: Add the Color Assets

I've created 17 color asset files in the `/repo/ColorAssets/` folder. You need to move these into your Xcode project's `Assets.xcassets` folder.

**In Finder:**

1. Open Finder and navigate to your GutCheck project folder
2. Find the `Assets.xcassets` folder (it's inside your project directory)
3. Open the `ColorAssets` folder I created (it should be in your repo root)
4. **Drag and drop** each `.colorset` folder into your `Assets.xcassets` folder

The `.colorset` folders to move:
- PrimaryColor.colorset
- AccentColor.colorset
- SecondaryColor.colorset
- BackgroundColor.colorset
- CardBackground.colorset
- SurfaceColor.colorset
- PrimaryText.colorset
- SecondaryText.colorset
- TertiaryText.colorset
- SuccessColor.colorset
- WarningColor.colorset
- ErrorColor.colorset
- InfoColor.colorset
- BorderColor.colorset
- DisabledColor.colorset
- InputBackground.colorset
- SymptomColor.colorset

### Step 3: Verify in Xcode

1. Go back to Xcode
2. Click on `Assets.xcassets` in the Project Navigator
3. You should now see all 17 color assets listed
4. Click on each one to verify:
   - It has two appearances: "Any Appearance" and "Dark Appearance"
   - The colors look correct (teal, coral, purple, etc.)

### Step 4: Test It Out

Build and run your app (⌘R). The colors should now automatically adapt to light/dark mode!

---

## Option 2: Create Manually in Xcode (If Drag-Drop Doesn't Work)

If for some reason the files don't work, you can create them manually:

### For Each Color:

1. In Xcode, select `Assets.xcassets`
2. Click the `+` button at the bottom
3. Choose "Color Set"
4. Name it (e.g., "PrimaryColor")
5. In the Attributes Inspector (right sidebar):
   - Set "Appearances" to "Any, Dark"
6. Click the color well for "Any Appearance"
7. Choose "sRGB" color space
8. Enter the RGB values from the reference below
9. Repeat for "Dark Appearance"

### Quick Reference (RGB Values 0-1 scale):

**PrimaryColor:**
- Light: R: 0.031, G: 0.569, B: 0.698
- Dark: R: 0.024, G: 0.714, B: 0.831

**AccentColor:**
- Light: R: 0.976, G: 0.451, B: 0.086
- Dark: R: 0.984, G: 0.573, B: 0.235

**SecondaryColor:**
- Light: R: 0.545, G: 0.361, B: 0.965
- Dark: R: 0.655, G: 0.545, B: 0.980

(See `COLOR_VALUES_REFERENCE.md` for hex values, or the JSON files for exact decimal values)

---

## Option 3: Terminal Commands (Advanced)

If you're comfortable with Terminal, you can copy the files directly:

```bash
# Navigate to your project directory
cd /path/to/your/GutCheck

# Copy all color assets to your Assets catalog
cp -r ColorAssets/*.colorset ./Assets.xcassets/
```

Then refresh Xcode (⌘⌥P to clean build folder, then rebuild).

---

## Verification Checklist

After installation, verify:

- [ ] All 17 colors appear in Assets.xcassets
- [ ] Each color has both "Any" and "Dark" appearances
- [ ] Build succeeds without errors
- [ ] Dashboard displays correctly in light mode
- [ ] Dashboard displays correctly in dark mode (Settings app → Display → Dark)
- [ ] Colors look professional and health-appropriate
- [ ] Text is readable on all backgrounds

---

## Troubleshooting

### "Color not found" errors:
- Make sure the color names in `Assets.xcassets` match exactly (case-sensitive)
- Clean build folder (⌘⇧K) and rebuild

### Colors don't change in dark mode:
- Check that "Appearances" is set to "Any, Dark" for each color
- Verify you're testing on a device/simulator, not just SwiftUI previews
- Try toggling dark mode in Settings

### Some colors look wrong:
- Double-check the RGB values match the JSON files
- Ensure you're using sRGB color space (not Display P3)

---

## Need Help?

If you run into any issues:

1. Check that all files are in the correct location
2. Verify the Contents.json files are valid JSON
3. Clean and rebuild the project
4. Restart Xcode if necessary

The color files are already created and ready to use! Just need to move them into your Assets catalog.
