# 🎨 Quick Start: Fix Your Colors

## Choose Your Method

### ✅ Method 1: Bash Script (Mac/Linux) - RECOMMENDED

```bash
cd /Users/markconley/Documents/GutCheck/GutCheck
chmod +x generate_color_assets.sh
./generate_color_assets.sh
```

### ✅ Method 2: Python Script (Cross-platform)

```bash
cd /Users/markconley/Documents/GutCheck/GutCheck
python3 generate_color_assets.py
```

### ✅ Method 3: Manual (If scripts fail)

See **COLOR_ASSETS_SETUP.md** for detailed manual instructions.

---

## After Running Script

1. **Open Xcode**
2. **Clean Build** (Cmd+Shift+K)
3. **Build & Run** (Cmd+R)
4. **Check both Light and Dark mode**

---

## What Gets Created

17 color assets in `Assets.xcassets/`:
- PrimaryColor (Teal)
- AccentColor (Orange)  
- SecondaryColor (Violet)
- BackgroundColor
- CardBackground
- SurfaceColor
- PrimaryText
- SecondaryText
- TertiaryText
- SuccessColor (Green)
- WarningColor (Amber)
- ErrorColor (Red)
- InfoColor (Blue)
- BorderColor
- DisabledColor
- InputBackground
- SymptomColor (Pink)

All with Light & Dark mode support! 🌓

---

## Troubleshooting

**Can't find Assets.xcassets?**
- Make sure you're in the right directory
- Path should be: `/Users/markconley/Documents/GutCheck/GutCheck`

**Permission denied?**
- Run: `chmod +x generate_color_assets.sh`

**Colors still not working?**
- Close and reopen Xcode
- Clean Build Folder (Cmd+Shift+K)
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

---

**Need more help?** See **COLOR_ASSETS_SETUP.md** for detailed guide.
