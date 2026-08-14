# ET Calculator — PWA Production Deployment Guide

## 1. Production Build Location

The production-ready web bundle for the **ET Calculator Progressive Web App (PWA)** is generated at:

```
build/web/
```

This directory contains all compiled JavaScript/WASM assets, HTML shell, web app manifest, icons, and offline service worker files.

---

## 2. Build Instructions

To generate a clean production release build, run:

```bash
flutter clean
flutter pub get
flutter build web --release
```

The output artifacts in `build/web/` are completely self-contained static files.

---

## 3. Web Deployment Requirements (HTTPS)

For browser PWA installation and offline service worker caching to function on modern web browsers (Google Chrome, Microsoft Edge, Mozilla Firefox, Apple Safari), the static files in `build/web/` **MUST be served over HTTPS** (or `localhost` during local testing).

Supported static hosting platforms:
* **Firebase Hosting** (Static only, no database needed)
* **GitHub Pages**
* **Netlify / Vercel**
* **Nginx / Apache** (configured with SSL/TLS certificates)

---

## 4. Installation Instructions per Platform

### **Windows 10 / Windows 11 (Chrome / Edge)**
1. Open the deployed HTTPS URL in Google Chrome or Microsoft Edge.
2. Click the **Install Icon** (computer with down arrow) in the address bar, or open the menu `(...)` -> **Install ET Calculator**.
3. ET Calculator will open as a standalone desktop window with a desktop icon and Start Menu shortcut.

### **Android (Google Chrome)**
1. Open the deployed HTTPS URL in Google Chrome on your Android phone.
2. Tap the menu `(...)` and select **Add to Home screen** or **Install app**.
3. ET Calculator will install on your home screen and open in full-screen standalone mode.

### **Ubuntu / Linux (Chromium / Chrome)**
1. Open the deployed HTTPS URL in Chromium or Google Chrome.
2. Click the install icon in the address bar or select **Install ET Calculator** from the menu.
3. ET Calculator will run in a standalone application window with a desktop icon.

---

## 5. Application Updates & Versioning

When deploying an updated version of the ET Calculator PWA:
1. Rebuild using `flutter build web --release`.
2. Deploy the updated `build/web/` files to your static server.
3. The PWA service worker will fetch updated code assets in the background.
4. **User Production Records in IndexedDB will NOT be cleared or affected during application updates.**

---

## 6. Backup Strategy

* All application data is stored locally in the user's browser IndexedDB storage.
* Users should **export regular XLSX backups** using the **Export Excel** feature on the Data Sheet screen.
* Exported XLSX files can be re-imported anytime to restore complete production records.

---

## 7. Storage Scope Notice

* Production data is strictly **local to the user's device and browser profile**.
* Device A does **NOT** sync or share data with Device B.
* No data is sent to any remote server or cloud database.
