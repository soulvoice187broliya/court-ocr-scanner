# Configure Google Cloud Vision for Court OCR Scanner

The app is configured to call a secure HTTPS backend, not Google Vision directly. This keeps the API key out of the APK.

1. Deploy `cloud_vision_backend/` to Cloud Run.
2. Enable Cloud Vision API and billing in Google Cloud.
3. Store `GOOGLE_CLOUD_VISION_API_KEY` as a server-side secret.
4. Use the deployed HTTPS URL ending in `/ocr`.
5. Install the APK, tap the document-scanner icon in the app bar, and save the URL.
6. Scan an image. The app requests document OCR with English and Hindi language hints.
7. Review/edit every extracted field before exporting. OCR is not guaranteed to map court-specific fields correctly.

The GitHub workflow builds and uploads the APK. It does not deploy the Cloud Run backend; backend deployment and API configuration are separate steps.
