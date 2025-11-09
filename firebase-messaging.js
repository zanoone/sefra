#!/usr/bin/env node

/**
 * Firebase Cloud Messaging Test Script with Korean Support
 *
 * This script sends test push notifications to iOS/Android devices
 * with Korean language content.
 *
 * Usage:
 *   node firebase-messaging.js [token]
 *
 * Prerequisites:
 *   1. npm install firebase-admin
 *   2. Place Firebase service account key JSON in this directory as 'service-account-key.json'
 *   3. Get FCM token from device
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Configuration
const PROJECT_ID = 'sefra-5f70b';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'service-account-key.json');

// Initialize Firebase Admin
try {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error('❌ Service account key file not found!');
    console.error(`   Expected location: ${SERVICE_ACCOUNT_PATH}`);
    console.error('\n📋 How to get the service account key:');
    console.error('   1. Go to Firebase Console: https://console.firebase.google.com/project/sefra-5f70b');
    console.error('   2. Settings > Service Accounts');
    console.error('   3. Click "Generate New Private Key"');
    console.error('   4. Save as service-account-key.json in this directory');
    process.exit(1);
  }

  const serviceAccount = require(SERVICE_ACCOUNT_PATH);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: PROJECT_ID
  });

  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error.message);
  process.exit(1);
}

// Get FCM token from command line or use test token
const fcmToken = process.argv[2];

if (!fcmToken) {
  console.error('❌ No FCM token provided!');
  console.error('\n📋 Usage:');
  console.error('   node firebase-messaging.js [FCM_TOKEN]');
  console.error('\n💡 To get FCM token:');
  console.error('   1. Install app on real device (TestFlight or Xcode)');
  console.error('   2. Check Xcode console logs for FCM token');
  console.error('   3. Look for: "🆕 새 FCM 토큰: ..."');
  process.exit(1);
}

console.log('\n🔔 Sending push notification with Korean text...');
console.log(`📱 Target token: ${fcmToken.substring(0, 20)}...`);

// Korean test messages
const koreanMessages = [
  {
    title: '안녕하세요! 👋',
    body: 'SefraiOS 푸시 알림 테스트입니다.',
    data: {
      type: 'test',
      timestamp: new Date().toISOString()
    }
  },
  {
    title: '새로운 메시지가 도착했습니다 📨',
    body: '한글 푸시 알림이 정상적으로 작동하고 있습니다.',
    data: {
      type: 'message',
      messageId: '12345'
    }
  },
  {
    title: '테스트 알림',
    body: '이것은 한글과 English가 섞인 mixed 메시지입니다.',
    data: {
      type: 'mixed',
      language: 'ko-en'
    }
  }
];

// Select a random message or use the first one
const message = koreanMessages[0];

// Construct FCM message
const fcmMessage = {
  token: fcmToken,
  notification: {
    title: message.title,
    body: message.body
  },
  data: message.data,
  apns: {
    payload: {
      aps: {
        alert: {
          title: message.title,
          body: message.body
        },
        sound: 'default',
        badge: 1,
        'content-available': 1
      }
    }
  },
  android: {
    notification: {
      title: message.title,
      body: message.body,
      sound: 'default',
      priority: 'high'
    }
  }
};

// Send message
admin.messaging().send(fcmMessage)
  .then((response) => {
    console.log('\n✅ Push notification sent successfully!');
    console.log(`📬 Message ID: ${response}`);
    console.log('\n📋 Message details:');
    console.log(`   Title: ${message.title}`);
    console.log(`   Body: ${message.body}`);
    console.log(`   Data: ${JSON.stringify(message.data, null, 2)}`);
    console.log('\n🎉 Check your device for the notification!');

    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Failed to send push notification!');
    console.error(`   Error: ${error.message}`);
    console.error(`   Code: ${error.code}`);

    if (error.code === 'messaging/registration-token-not-registered') {
      console.error('\n💡 This token is not registered or has been deleted.');
      console.error('   Possible causes:');
      console.error('   1. App was uninstalled and reinstalled (token changed)');
      console.error('   2. Token was deleted (builds 41-42 delete old tokens)');
      console.error('   3. Token was never sent to server');
      console.error('\n🔧 Solutions:');
      console.error('   1. Get new FCM token from Xcode console');
      console.error('   2. Check server database for latest token');
      console.error('   3. Ensure token transmission logic is working (build 42)');
    }

    if (error.code === 'messaging/invalid-registration-token') {
      console.error('\n💡 The token format is invalid.');
      console.error('   Make sure you copied the full token correctly.');
    }

    process.exit(1);
  });
