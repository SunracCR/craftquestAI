#!/bin/sh
# Xcode Cloud: instala Flutter y genera ios/Flutter/ephemeral (SPM plugins).
set -e

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_APP_PATH="$CI_PRIMARY_REPOSITORY_PATH/mobile/craftquest_app"

echo ">>> ci_post_clone: repo=$CI_PRIMARY_REPOSITORY_PATH"
echo ">>> ci_post_clone: flutter app=$FLUTTER_APP_PATH"

if [ ! -d "$FLUTTER_HOME/bin" ]; then
  echo ">>> ci_post_clone: cloning Flutter stable to $FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

cd "$FLUTTER_APP_PATH"

flutter --version
flutter precache --ios
flutter pub get

echo ">>> ci_post_clone: FlutterGeneratedPluginSwiftPackage ready"
test -d "$FLUTTER_APP_PATH/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"
