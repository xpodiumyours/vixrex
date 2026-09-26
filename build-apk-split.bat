cd /d C:\Projects\vixrex
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.local.json --dart-define=PUBLIC_SITE_URL=https://vixrex.com > C:\Projects\vixrex\build-apk.log 2>&1
