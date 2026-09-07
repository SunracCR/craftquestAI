#!/bin/sh
# Restaura GoogleService-Info.plist si falta (git o secreto de Xcode Cloud).
# Si el archivo ya está en el clone, no toca el secreto (un Base64 inválido
# no debe tumbar el workflow).

write_google_service_info_plist() {
  _app_path="${1:-$FLUTTER_APP_PATH}"
  _dest="$_app_path/ios/Runner/GoogleService-Info.plist"

  if [ -s "$_dest" ]; then
    echo ">>> GoogleService-Info.plist already present"
    return 0
  fi

  if [ -n "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
    echo ">>> writing GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_BASE64"
    if ! GOOGLE_SERVICE_INFO_PLIST_BASE64="$GOOGLE_SERVICE_INFO_PLIST_BASE64" python3 -c '
import base64, os, sys
raw = "".join(os.environ["GOOGLE_SERVICE_INFO_PLIST_BASE64"].split())
open(sys.argv[1], "wb").write(base64.b64decode(raw))
' "$_dest"; then
      echo "warning: failed to decode GOOGLE_SERVICE_INFO_PLIST_BASE64"
    fi
  fi

  if [ ! -s "$_dest" ]; then
    echo "error: missing $_dest"
    echo "El plist debe estar en git o el secreto GOOGLE_SERVICE_INFO_PLIST_BASE64 en el workflow."
    exit 1
  fi

  echo ">>> GoogleService-Info.plist ready"
}
