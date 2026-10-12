# CourtOCR — SC.xlsx mapped build

Flutter Android app source for scanning court orders/warrants, extracting text on-device with Google ML Kit, reviewing/editing the proposed fields, and exporting a copy of the existing `SC.xlsx` workbook.

## Main behavior
- Camera or photo-gallery scan.
- Editable review screen before export; raw OCR text is available for verification.
- Imports the user's workbook and appends a row to `Visible Data`, retaining all existing columns.
- Maps A, B, C, D, E, F, G, H, I, J, K, P, Q, R, S, T, W, AE, AF and AM to their intended workbook columns.
- A is a per-receipt-date serial counter; B counts registrations per court name.
- D/K use `Sep2026` style. Issue date falls back to receipt date when OCR finds no issue date.
- Dropdowns for order type, arrest status, peshi status, AE person type, AF area and AM case role. MARK TO has saved recipient suggestions plus manual editing.
- OCR runs locally on the device. Excel export uses Android share sheet; it does not directly write to Google Sheets.

## Build APK with GitHub Actions
1. Upload/extract these files into the root of a GitHub repository, preserving `lib/main.dart`, `pubspec.yaml`, and `.github/workflows/build-apk.yml`.
2. On GitHub open **Actions → Build CourtOCR APK → Run workflow** (or push to `main`).
3. Wait for a green workflow run, open that run, then download the artifact named `Court-OCR-Scanner-APK`.
4. Extract the artifact ZIP; install `app-release.apk` on Android.
5. In the app, import `SC.xlsx`, scan, check/edit the fields, and tap **Prepare Excel and export**.

## Important
- The build workflow creates a standard Android Flutter wrapper on GitHub's Linux runner; it does not build on an ARM phone/Termux.
- The APK has not been compiled or device-tested in this environment because Flutter/Android SDK are not installed here.
- OCR is not guaranteed to be accurate on faint, skewed, stamped, or handwritten text. Verify every field against the original before exporting or taking official action.
