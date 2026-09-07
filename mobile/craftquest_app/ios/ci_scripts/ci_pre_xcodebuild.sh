#!/bin/sh
# Xcode Cloud: exporta FLUTTER_ROOT y prepara config iOS antes de xcodebuild.
set -e

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_APP_PATH="$CI_PRIMARY_REPOSITORY_PATH/mobile/craftquest_app"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

. "$SCRIPT_DIR/write_google_service_info_plist.sh"

export FLUTTER_ROOT="$FLUTTER_HOME"
export PATH="$FLUTTER_ROOT/bin:$PATH"

echo ">>> ci_pre_xcodebuild: FLUTTER_ROOT=$FLUTTER_ROOT"

write_google_service_info_plist "$FLUTTER_APP_PATH"

cd "$FLUTTER_APP_PATH"

# Regenera Generated.xcconfig y asegura artefactos iOS (Release = TestFlight).
flutter pub get
flutter build ios --config-only --release

echo ">>> ci_pre_xcodebuild: iOS config ready"
