#!/usr/bin/env python3
import os, json
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

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

assets_path = Path("GutCheck/Assets.xcassets")
if not assets_path.exists():
    print(f"❌ Error: {assets_path} not found!")
    exit(1)

print("🎨 Creating GutCheck color assets...")
for name, (light, dark) in COLORS.items():
    print(f"   ✓ {name}")
    path = assets_path / f"{name}.colorset"
    path.mkdir(exist_ok=True)
    lr, lg, lb = hex_to_rgb(light)
    dr, dg, db = hex_to_rgb(dark)
    data = {
        "colors": [
            {
                "color": {
                    "color-space": "srgb",
                    "components": {
                        "alpha": "1.000",
                        "blue": f"{lb:.3f}",
                        "green": f"{lg:.3f}",
                        "red": f"{lr:.3f}"
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
                        "blue": f"{db:.3f}",
                        "green": f"{dg:.3f}",
                        "red": f"{dr:.3f}"
                    }
                },
                "idiom": "universal"
            }
        ],
        "info": {"author": "xcode", "version": 1}
    }
    with open(path / "Contents.json", 'w') as f:
        json.dump(data, f, indent=2)

print(f"\n✅ Created {len(COLORS)} color assets!")
print("\n📋 Next steps:")
print("1. Close Xcode if it's open")
print("2. Reopen Xcode")
print("3. Clean Build (Cmd+Shift+K)")
print("4. Build & Run")
