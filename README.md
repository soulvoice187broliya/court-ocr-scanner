Court OCR Scanner
Scan court documents → review OCR → export to Excel.
A Flutter Android app for extracting court-document text in English and Hindi, reviewing the results, and appending approved records to the GH.xlsx register.
Features
Scan using the camera or choose an image.
Optional Google Cloud Vision OCR through a configurable HTTPS backend.
Edit extracted fields before saving.
Use GH.xlsx as the default workbook and append to Sheet1.
Preserve existing rows, other columns, and other worksheets.
Manage MARK TO assignees and dropdown values in the app.
Export the updated .xlsx file using Android's Share menu.
Format dates as DD/MM/YYYY and month/year as Oct2026.
Excel mapping
The app maps these register columns:
A, B, C, D, E, F, G, H, I, J, K, P, Q, R, S, T, W, AE, AF, AM
Important GH.xlsx fields:
Column   Header / purpose
T        Mobile number W        MARK TO AE       SUMMON FOR AF       AREA OF TAMILI AM       PURPOSE OF SUMMON
The app checks the expected headers before appending. Keep a backup of the original workbook. The bundled template is not changed on disk; save the exported workbook and open that updated file next time to retain previously added records.
Build the APK
GitHub Actions builds on pushes to main and can also be started manually:
Open the repository's Actions tab.
Select Build Court OCR Scanner APK.
Select Run workflow.
Wait for the workflow to finish successfully.
Download Court-OCR-Scanner-APK from the run's Artifacts section.
The workflow should run:
flutter pub get
flutter analyze
flutter test
flutter build apk --release
Expected APK path:
build/app/outputs/flutter-apk/app-release.apk
Required project files include pubspec.yaml, lib/main.dart, and .github/workflows/build-apk.yml.
Set up Google Cloud Vision
Cloud Vision is not active until the backend is deployed and its HTTPS URL is configured in the app. The GitHub Actions workflow builds the APK; it does not deploy the backend.
Backend API
GET /health --- health check.
POST /ocr --- accepts JSON:
{
  "imageBase64": "BASE64_ENCODED_IMAGE",
  "languageHints": ["en", "hi"]
}
Successful response:
{
  "text": "recognized text"
}
Deploy securely
In Google Cloud, select a project and enable the Cloud Vision API and billing.
Deploy the cloud_vision_backend folder to Cloud Run or another HTTPS server.
Store GOOGLE_CLOUD_VISION_API_KEY as a server-side secret, preferably in Secret Manager, and expose it to the service as an environment variable.
Restrict the key to the Cloud Vision API. Never commit the key to Git or embed it in the APK.
Configure authentication/access controls for the backend. Court documents contain sensitive personal information; do not leave the endpoint publicly callable without appropriate protection.
Copy the HTTPS service URL, append /ocr, and save that URL in the app using the scanner/settings control.
Configure quotas, budget alerts, and suitable privacy and data-retention controls.
The sample backend uses a server-side API key for simplicity. For production, consider service-account authentication to the Vision API, strict caller authentication, request-size limits, rate limits, and logging that avoids storing document contents.
See CLOUD_VISION_SETUP.md and cloud_vision_backend/README.md for deployment-specific instructions.
Data safety and accuracy
OCR extraction is heuristic, not a certified legal-document parser.
Review every field against the original document before exporting or using it officially.
Verify registration numbering and daily serial-number behavior against the real register.
Use only a compatible Sheet1 layout; do not test on the sole copy of an operational register.
Cloud OCR sends the selected image to your configured backend. Only use a backend and retention policy approved for your court's data.
This project exports Excel files. Direct Google Sheets synchronization is not configured.
A successful GitHub build does not prove that OCR, workbook editing, sharing, or all features work on a real device. Test the APK on an Android device before official use.
Project structure
court-ocr-scanner/
├── pubspec.yaml
├── lib/
│   └── main.dart
├── assets/
│   └── GH.xlsx
├── cloud_vision_backend/
├── CLOUD_VISION_SETUP.md
├── test/
└── .github/
    └── workflows/
        └── build-apk.yml
Before official use: back up GH.xlsx, configure and secure the OCR backend if using Cloud Vision, and verify all extracted data manually.