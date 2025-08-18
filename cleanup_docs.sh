#!/bin/bash

# GutCheck Documentation Cleanup Script
# This script helps clean up old scattered markdown files after consolidation

echo "🧹 GutCheck Documentation Cleanup"
echo "=================================="
echo ""

# List all markdown files that can be removed
echo "📋 The following markdown files can be removed (consolidated into DOCUMENTATION.md):"
echo ""

# Files to remove (consolidated into DOCUMENTATION.md)
files_to_remove=(
    "PRIVACY_INTEGRATION_COMPLETE.md"
    "PROJECT_STATUS_2025.md"
    "HEALTHCARE_EXPORT_SYSTEM.md"
    "DATA_PRIVACY_IMPLEMENTATION_STATUS.md"
    "GUTCHECK_WORKFLOWS.md"
    "GutCheck_Wiki.md"
    "GutCheck_Developer_Guide.md"
    "GutCheck_Architecture_Plan.md"
    "SMART_SCAN_NAVIGATION_FIXES.md"
    "FOOD_DETAIL_UNIFICATION_SUMMARY.md"
    "UNIFIED_MEAL_IMPLEMENTATION_COMPLETE.md"
    "UNIFIED_MEAL_ARCHITECTURE.md"
    "BUG_FIXES_SUMMARY.md"
    "BARCODE_ENHANCEMENT_SUMMARY.md"
    "FOLDER_STRUCTURE.md"
)

# Files to keep
files_to_keep=(
    "README.md"
    "DOCUMENTATION.md"
    "LICENSE"
    "GutCheck/CONTRIBUTING.md"
)

echo "📁 Files to REMOVE (consolidated):"
for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        echo "   ❌ $file"
    else
        echo "   ⚠️  $file (not found)"
    fi
done

echo ""
echo "📁 Files to KEEP:"
for file in "${files_to_keep[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ⚠️  $file (not found)"
    fi
done

echo ""
echo "🔍 Current markdown files in project:"
find . -name "*.md" -type f | sort

echo ""
echo "💡 To remove the old files, run:"
echo "   ./cleanup_docs.sh --remove"
echo ""
echo "💡 To see what will be removed without actually removing:"
echo "   ./cleanup_docs.sh --dry-run"
echo ""

# Check if --remove flag is provided
if [ "$1" = "--remove" ]; then
    echo "🗑️  Removing old documentation files..."
    echo ""
    
    removed_count=0
    for file in "${files_to_remove[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
            echo "   ✅ Removed: $file"
            ((removed_count++))
        fi
    done
    
    echo ""
    echo "🎉 Cleanup complete! Removed $removed_count files."
    echo "📚 All documentation is now consolidated in DOCUMENTATION.md"
    
elif [ "$1" = "--dry-run" ]; then
    echo "🔍 DRY RUN - Files that would be removed:"
    echo ""
    
    for file in "${files_to_remove[@]}"; do
        if [ -f "$file" ]; then
            echo "   🗑️  Would remove: $file"
        fi
    done
    
    echo ""
    echo "💡 Run './cleanup_docs.sh --remove' to actually remove these files"
fi

echo ""
echo "📖 Documentation is now consolidated in DOCUMENTATION.md"
echo "📚 README.md has been updated to reference the consolidated docs"
echo "🚀 GitHub Actions workflow has been updated for iOS 15.0+"
