# Fixes and Cloud Vision configuration

- Replaced relative test imports with package imports.
- Mocked SharedPreferences in widget test.
- Added date helper tests.
- Made `_personCategory` final.
- Added Google Cloud Vision OCR integration using a configurable HTTPS backend.
- Requests English and Hindi language hints (`en`, `hi`).
- Kept API key on the server, not inside the APK.
- Added `cloud_vision_backend/` sample service and setup documentation.
- Updated GitHub Actions to run analysis/tests and build/upload a release APK.
- Workflow ensures Android internet permission and requests compileSdk 36 for the current Android dependency compatibility issue.

Build is not claimed verified until GitHub Actions completes successfully. Cloud Vision will only work after the backend is deployed and its URL saved in the app.
