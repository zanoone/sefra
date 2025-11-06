#!/bin/bash

# Fix firebase_messaging plugin header to avoid non-modular include error
PLUGIN_HEADER=".pub-cache/hosted/pub.dev/firebase_messaging-14.7.10/ios/Classes/FLTFirebaseMessagingPlugin.h"

if [ -f "$HOME/$PLUGIN_HEADER" ]; then
  echo "Fixing firebase_messaging plugin header..."
  sed -i '' 's/#import <Firebase\/Firebase.h>/#import <FirebaseCore\/FirebaseCore.h>\n#import <FirebaseMessaging\/FirebaseMessaging.h>/' "$HOME/$PLUGIN_HEADER"
  echo "Fixed!"
else
  echo "firebase_messaging plugin not found, skipping..."
fi
