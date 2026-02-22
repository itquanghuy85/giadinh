# Family Safety - Setup & Configuration Guide

## 📋 Prerequisites

- Flutter SDK (latest stable, 3.x+)
- Android Studio / VS Code
- Firebase account
- Google Cloud Console account
- A physical Android device (Android 10+) for testing

---

## 🔥 Step 1: Firebase Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Add project"** → Name it `family-safety`
3. Enable Google Analytics (optional)
4. Wait for project creation

### 1.2 Add Android App
1. In Firebase Console → **Project Settings** → **Add app** → **Android**
2. Package name: `com.familysafety.family_safety`
3. App nickname: `Family Safety`
4. Get SHA-1 key:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Or on Windows:
   ```cmd
   cd android
   gradlew signingReport
   ```
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

### 1.3 Enable Authentication
1. Firebase Console → **Authentication** → **Sign-in method**
2. Enable **Google** sign-in provider
3. Add your SHA-1 fingerprint if not already added

### 1.4 Enable Firestore
1. Firebase Console → **Firestore Database** → **Create database**
2. Choose **Production mode**
3. Select a region close to your users
4. After creation, go to **Rules** tab and paste the contents of `firestore.rules`

### 1.5 Enable Cloud Messaging
1. Firebase Console → **Cloud Messaging**
2. It's enabled by default; no additional setup needed

### 1.6 Deploy Firestore Rules
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize (select Firestore)
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

---

## 🗺️ Step 2: Google Maps Setup

### 2.1 Enable Maps SDK
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Go to **APIs & Services** → **Library**
4. Search and enable:
   - **Maps SDK for Android**
   - **Geocoding API** (optional)

### 2.2 Create API Key
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Restrict the key:
   - **Application restrictions**: Android apps
   - **Package name**: `com.familysafety.family_safety`
   - **SHA-1 fingerprint**: Your debug/release fingerprint
   - **API restrictions**: Maps SDK for Android

### 2.3 Add API Key to Project
Open `android/app/src/main/AndroidManifest.xml` and replace:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```
with your actual API key.

---

## 📱 Step 3: Build & Run

### 3.1 Install Dependencies
```bash
flutter pub get
```

### 3.2 Run on Device
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### 3.3 Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   └── theme/
│       └── app_theme.dart             # Material theme & colors
├── models/
│   ├── app_user.dart                  # User model
│   ├── family.dart                    # Family group model
│   ├── location_data.dart             # Location data model
│   ├── geofence.dart                  # Geofence zone model
│   └── sos_alert.dart                 # SOS alert model
├── services/
│   ├── auth_service.dart              # Firebase Auth + Google Sign-In
│   ├── firestore_service.dart         # All Firestore CRUD operations
│   ├── location_service.dart          # Geolocator wrapper
│   ├── background_location_service.dart # Foreground service
│   ├── notification_service.dart      # FCM + local notifications
│   └── permission_service.dart        # Runtime permissions
├── providers/
│   ├── auth_provider.dart             # Auth state management
│   ├── location_provider.dart         # Location tracking state
│   ├── sos_provider.dart              # SOS alerts state
│   └── family_provider.dart           # Family members state
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart          # Google Sign-In
│   │   ├── role_selection_screen.dart  # Parent/Child selection
│   │   ├── family_setup_screen.dart   # Create family (Parent)
│   │   └── join_family_screen.dart    # Join family (Child)
│   ├── parent/
│   │   ├── parent_home_screen.dart    # Parent main screen + nav
│   │   ├── parent_map_screen.dart     # Map with children markers
│   │   ├── parent_members_screen.dart # Family members list
│   │   ├── parent_geofence_screen.dart# Safe zones management
│   │   └── parent_settings_screen.dart# Parent settings
│   └── child/
│       ├── child_home_screen.dart     # Child main screen + SOS
│       └── permission_explanation_screen.dart # Permission flow
└── widgets/
    └── common_widgets.dart            # Shared UI components
```

---

## 🔒 Firestore Data Structure

```
users/{userId}
├── email: string
├── displayName: string
├── photoUrl: string?
├── role: "parent" | "child"
├── familyId: string?
├── batteryLevel: number
├── isOnline: boolean
├── lastActive: timestamp
└── fcmToken: string?

families/{familyId}
├── name: string
├── code: string (6-char unique)
├── createdBy: string (userId)
├── members: string[] (userIds)
└── createdAt: timestamp

locations/{userId}
├── userId: string
├── lat: number
├── lng: number
├── accuracy: number?
├── speed: number?
├── batteryLevel: number
├── timestamp: timestamp
└── history/{historyId}
    ├── (same fields as parent)
    └── ...

geofences/{geofenceId}
├── familyId: string
├── name: string
├── lat: number
├── lng: number
├── radius: number (meters)
├── createdBy: string
└── createdAt: timestamp

sos_alerts/{alertId}
├── childId: string
├── childName: string
├── familyId: string
├── lat: number
├── lng: number
├── timestamp: timestamp
└── isResolved: boolean
```

---

## 🛡️ Google Play Compliance

### Background Location Disclosure
When publishing to Google Play, you must:

1. **Declare permissions in Play Console**:
   - Go to **App content** → **Permissions declarations**
   - Declare `ACCESS_BACKGROUND_LOCATION` usage
   - Provide a video showing the in-app disclosure

2. **In-app disclosure** (already implemented):
   - `PermissionExplanationScreen` shows clear explanation before requesting
   - Visible notification always displayed during tracking
   - Users can pause/stop sharing at any time

3. **Privacy Policy** (included):
   - Host `privacy_policy.html` on a public URL
   - Link it in Google Play Store listing
   - Link it in the app (Settings screen)

### Family Policy Compliance
- App clearly distinguishes parent/child roles
- Child consent checkbox before joining family
- Location sharing status clearly visible
- No hidden tracking - foreground notification always shown

---

## 🐛 Troubleshooting

### Common Issues

**Google Sign-In fails:**
- Ensure SHA-1 is added in Firebase Console
- Ensure `google-services.json` is in the correct location
- Check internet connectivity

**Location not updating:**
- Check location permissions in device settings
- Ensure GPS is enabled
- Check if battery optimization is killing the background service

**Maps not showing:**
- Verify Google Maps API key is correct
- Ensure Maps SDK for Android is enabled in Google Cloud Console
- Check API key restrictions

**Build fails:**
- Run `flutter clean && flutter pub get`
- Ensure `minSdk` is 23 or higher
- Check that `google-services.json` exists in `android/app/`

---

## 📄 License

This project is for educational and personal use. Ensure compliance with local privacy laws before deploying.
