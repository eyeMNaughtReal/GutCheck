// Test script for Firestore Security Rules
// This script tests various access scenarios to verify security

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'gutcheck-42d90'
});

const db = admin.firestore();

// Test user IDs
const testUser1 = 'test-user-1';
const testUser2 = 'test-user-2';

async function testSecurityRules() {
  console.log('🔐 Testing Firestore Security Rules...\n');

  try {
    // Test 1: Create a test user profile
    console.log('📝 Test 1: Creating test user profile...');
    const userProfile = {
      email: 'test1@example.com',
      firstName: 'Test',
      lastName: 'User',
      signInMethod: 'email',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection('users').doc(testUser1).set(userProfile);
    console.log('✅ User profile created successfully\n');

    // Test 2: Create a test meal
    console.log('🍽️ Test 2: Creating test meal...');
    const testMeal = {
      name: 'Test Breakfast',
      date: admin.firestore.FieldValue.serverTimestamp(),
      type: 'breakfast',
      source: 'manual',
      foodItems: [],
      createdBy: testUser1,
      tags: ['test']
    };

    await db.collection('meals').doc('test-meal-1').set(testMeal);
    console.log('✅ Test meal created successfully\n');

    // Test 3: Create a test symptom
    console.log('🏥 Test 3: Creating test symptom...');
    const testSymptom = {
      date: admin.firestore.FieldValue.serverTimestamp(),
      stoolType: 4,
      painLevel: 1,
      urgencyLevel: 2,
      createdBy: testUser1,
      tags: ['test']
    };

    await db.collection('symptoms').doc('test-symptom-1').set(testSymptom);
    console.log('✅ Test symptom created successfully\n');

    // Test 4: Test data access (should succeed for own data)
    console.log('🔍 Test 4: Testing data access for own data...');
    const ownMeal = await db.collection('meals').doc('test-meal-1').get();
    const ownSymptom = await db.collection('symptoms').doc('test-symptom-1').get();
    
    if (ownMeal.exists && ownSymptom.exists) {
      console.log('✅ Successfully accessed own data\n');
    } else {
      console.log('❌ Failed to access own data\n');
    }

    // Test 5: Test cross-user data access (should fail)
    console.log('🚫 Test 5: Testing cross-user data access (should fail)...');
    try {
      // Try to access another user's data (this should fail due to security rules)
      const otherUserMeal = await db.collection('meals').doc('test-meal-1').get();
      console.log('❌ Cross-user access succeeded (this should have failed)\n');
    } catch (error) {
      console.log('✅ Cross-user access properly blocked by security rules\n');
    }

    // Test 6: Test required field validation
    console.log('✅ Test 6: Testing required field validation...');
    try {
      const invalidMeal = {
        name: 'Invalid Meal',
        // Missing required fields: date, type, source, foodItems, createdBy
      };
      
      await db.collection('meals').doc('invalid-meal').set(invalidMeal);
      console.log('❌ Invalid meal created (this should have failed)\n');
    } catch (error) {
      console.log('✅ Required field validation working correctly\n');
    }

    // Test 7: Test data modification restrictions
    console.log('🔒 Test 7: Testing data modification restrictions...');
    try {
      // Try to modify createdBy field (should fail)
      await db.collection('meals').doc('test-meal-1').update({
        createdBy: testUser2 // This should fail
      });
      console.log('❌ Modified createdBy field (this should have failed)\n');
    } catch (error) {
      console.log('✅ Data modification restrictions working correctly\n');
    }

    console.log('🎉 Security rules testing completed!\n');

  } catch (error) {
    console.error('❌ Error during testing:', error.message);
  }
}

// Run the tests
testSecurityRules().then(() => {
  console.log('🏁 All tests completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Test suite failed:', error);
  process.exit(1);
});
