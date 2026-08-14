# ET Calculator — Local Data Storage & Privacy Documentation

## 1. Storage Architecture

The **ET Calculator PWA** is designed as a **100% Offline-First, Local-Data-Only Application**.

```
    ET Calculator PWA
            │
            ▼
      DatabaseHelper
            │
            ▼
  sqflite_common_ffi_web
            │
            ▼
        IndexedDB (User's Device Browser Storage)
```

---

## 2. Data Categories & Storage Locations

| Data Category | Storage Mechanism | Storage Scope |
| :--- | :--- | :--- |
| **Production Records** | `IndexedDB` (`et_calculator.db`) | Local Browser Storage |
| **App Settings** (Theme, Preferences) | `localStorage` (`shared_preferences`) | Local Browser Storage |
| **Excel Export Files** | Browser Downloads Folder | Local Filesystem |

---

## 3. Privacy & Zero Cloud Architecture

* **NO Firebase / SUPABASE / Cloud DB**: No remote databases exist.
* **NO Backend APIs**: No REST, GraphQL, or HTTP endpoints are called.
* **NO Telemetry / Analytics**: No user tracking, metrics, or telemetry are transmitted.
* **NO Login / Authentication**: All functionality is available immediately without accounts.
* **Zero Production Data Upload**: Production records **NEVER** leave the local device.

---

## 4. Multi-Device & Browser Profile Isolation

* Production data is strictly bound to the specific browser profile and local device where it was entered.
* **Device A** and **Device B** operate independently.
* **Chrome Profile 1** and **Chrome Profile 2** operate independently.

---

## 5. Data Loss Prevention & Backup Recommendations

> [!WARNING]
> Because production records reside inside the browser's IndexedDB storage, clearing browser site data, clearing cookies, or uninstalling the browser profile can erase local production database records.

### **Recommended User Backup Routine:**
1. Navigate to the **Data Sheet** screen.
2. Click **Export Excel**.
3. Select the shift (`First`, `Second`, `Night`).
4. Save the generated `.xlsx` file (e.g. `First_9-8-2026.xlsx`) to a safe location or USB drive.

### **Restoring Data from Backup:**
1. Navigate to the **Data Sheet** or **Reports** screen.
2. Click **Import Excel**.
3. Select your exported `.xlsx` backup file.
4. All production records will be restored into the local IndexedDB database.
