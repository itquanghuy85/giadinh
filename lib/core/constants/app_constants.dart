class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'Family Safety';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String familiesCollection = 'families';
  static const String locationsCollection = 'locations';
  static const String geofencesCollection = 'geofences';
  static const String sosAlertsCollection = 'sos_alerts';

  // Location Settings
  static const int locationUpdateIntervalMs = 20000; // 20 seconds
  static const double locationDistanceFilter = 20.0; // 20 meters
  static const int locationTimeoutSeconds = 15;

  // Geofence
  static const double defaultGeofenceRadius = 200.0; // meters

  // Family Code
  static const int familyCodeLength = 6;

  // Notification Channels
  static const String locationChannelId = 'location_tracking';
  static const String locationChannelName = 'Location Tracking';
  static const String sosChannelId = 'sos_alerts';
  static const String sosChannelName = 'SOS Alerts';
  static const String geofenceChannelId = 'geofence_alerts';
  static const String geofenceChannelName = 'Geofence Alerts';

  // SharedPreferences Keys
  static const String prefUserRole = 'user_role';
  static const String prefFamilyId = 'family_id';
  static const String prefTrackingEnabled = 'tracking_enabled';
}
