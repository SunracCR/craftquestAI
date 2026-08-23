#!/bin/sh
# Xcode Cloud: exporta FLUTTER_ROOT y prepara config iOS antes de xcodebuild.
set -e

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_APP_PATH="$CI_PRIMARY_REPOSITORY_PATH/mobile/craftquest_app"

export FLUTTER_ROOT="$FLUTTER_HOME"
export PATH="$FLUTTER_ROOT/bin:$PATH"

echo ">>> ci_pre_xcodebuild: FLUTTER_ROOT=$FLUTTER_ROOT"

cd "$FLUTTER_APP_PATH"

# Regenera Generated.xcconfig y asegura artefactos iOS (Release = TestFlight).
flutter pub get
flutter build ios --config-only --release

echo ">>> ci_pre_xcodebuild: iOS config ready"
