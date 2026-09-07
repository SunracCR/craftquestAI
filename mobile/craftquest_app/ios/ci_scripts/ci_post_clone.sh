#!/bin/sh
# Xcode Cloud: instala Flutter y genera ios/Flutter/ephemeral (SPM plugins).
# No fallar aquí por el plist: si este script sale 1, Xcode no resuelve
# FlutterGeneratedPluginSwiftPackage y el archive ni llega a copiar recursos.
set -e

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_APP_PATH="$CI_PRIMARY_REPOSITORY_PATH/mobile/craftquest_app"
SPM_PACKAGE="$FLUTTER_APP_PATH/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"

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

if [ ! -d "$SPM_PACKAGE" ]; then
  echo ">>> ci_post_clone: SPM package missing after pub get; running config-only"
  flutter build ios --config-only --release
fi

echo ">>> ci_post_clone: FlutterGeneratedPluginSwiftPackage ready"
test -d "$SPM_PACKAGE"
