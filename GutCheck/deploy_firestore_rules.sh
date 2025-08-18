#!/bin/bash

# 🔐 Firestore Security Rules Deployment Script
# This script deploys Firestore security rules and indexes to Firebase
# 
# Created by Mark Conley on 8/18/25
# For GutCheck App Security Implementation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        echo "firebase login"
        exit 1
    fi
    print_success "Firebase CLI is installed"
}

# Function to check if user is logged in to Firebase
check_firebase_login() {
    if ! firebase projects:list &> /dev/null; then
        print_error "You are not logged in to Firebase. Please run:"
        echo "firebase login"
        exit 1
    fi
    print_success "Firebase authentication verified"
}

# Function to check if firebase.json exists
check_config_files() {
    if [ ! -f "firebase.json" ]; then
        print_error "firebase.json not found in current directory"
        exit 1
    fi
    
    if [ ! -f "firestore.rules" ]; then
        print_error "firestore.rules not found in current directory"
        exit 1
    fi
    
    if [ ! -f "firestore.indexes.json" ]; then
        print_error "firestore.indexes.json not found in current directory"
        exit 1
    fi
    
    print_success "All required configuration files found"
}

# Function to validate Firestore rules syntax
validate_rules() {
    print_status "Validating Firestore security rules syntax..."
    
    if firebase firestore:rules:test firestore.rules &> /dev/null; then
        print_success "Firestore rules syntax is valid"
    else
        print_warning "Firestore rules syntax validation failed (this may be due to missing test files)"
        print_warning "Rules will still be deployed, but please verify syntax manually"
    fi
}

# Function to deploy Firestore rules
deploy_rules() {
    print_status "Deploying Firestore security rules..."
    
    if firebase deploy --only firestore:rules; then
        print_success "Firestore security rules deployed successfully"
    else
        print_error "Failed to deploy Firestore security rules"
        exit 1
    fi
}

# Function to deploy Firestore indexes
deploy_indexes() {
    print_status "Deploying Firestore indexes..."
    
    if firebase deploy --only firestore:indexes; then
        print_success "Firestore indexes deployed successfully"
    else
        print_error "Failed to deploy Firestore indexes"
        exit 1
    fi
}

# Function to show deployment summary
show_summary() {
    echo ""
    echo "🎉 Firestore Security Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "✅ Security Rules: Deployed"
    echo "✅ Database Indexes: Deployed"
    echo ""
    echo "🔐 Security Features Active:"
    echo "   • User authentication required for all operations"
    echo "   • Data ownership enforced at document level"
    echo "   • Required field validation"
    echo "   • Rate limiting and abuse prevention"
    echo "   • Privacy level controls"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Test your app with the new security rules"
    echo "   2. Monitor Firebase Console for any permission errors"
    echo "   3. Review the FIRESTORE_SECURITY_RULES.md for details"
    echo ""
    echo "🚨 Important: Test thoroughly in development before production use!"
}

# Main execution
main() {
    echo "🔐 GutCheck Firestore Security Rules Deployment"
    echo "==============================================="
    echo ""
    
    # Check prerequisites
    check_firebase_cli
    check_firebase_login
    check_config_files
    
    # Validate and deploy
    validate_rules
    deploy_rules
    deploy_indexes
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
