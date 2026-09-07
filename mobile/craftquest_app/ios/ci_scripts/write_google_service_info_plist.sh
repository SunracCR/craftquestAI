#!/bin/sh
# Restaura GoogleService-Info.plist (gitignored) para Xcode Cloud.
# Secreto del workflow: GOOGLE_SERVICE_INFO_PLIST_BASE64

write_google_service_info_plist() {
  _app_path="${1:-$FLUTTER_APP_PATH}"
  _dest="$_app_path/ios/Runner/GoogleService-Info.plist"

  if [ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
    echo ">>> writing GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_BASE64"
    GOOGLE_SERVICE_INFO_PLIST_BASE64="$GOOGLE_SERVICE_INFO_PLIST_BASE64" python3 -c '
import base64, os, sys
raw = "".join(os.environ["GOOGLE_SERVICE_INFO_PLIST_BASE64"].split())
open(sys.argv[1], "wb").write(base64.b64decode(raw))
' "$_dest"
  fi

  if [ ! -s "$_dest" ]; then
    echo "error: missing $_dest"
    echo "Xcode Cloud no clona GoogleService-Info.plist (.gitignore)."
    echo "Añade el secreto GOOGLE_SERVICE_INFO_PLIST_BASE64 al workflow:"
    echo "  base64 -i mobile/craftquest_app/ios/Runner/GoogleService-Info.plist | pbcopy"
    exit 1
  fi

  echo ">>> GoogleService-Info.plist ready"
}
