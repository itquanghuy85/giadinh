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
  static const String dailyReportsCollection = 'daily_reports';
  static const String timelineEventsCollection = 'timeline_events';
  static const String dangerZonesCollection = 'danger_zones';
  static const String scheduleConfigCollection = 'schedule_configs';

  // Location Settings
  static const int locationUpdateIntervalMs = 20000; // 20 seconds
  static const double locationDistanceFilter = 20.0; // 20 meters
  static const int locationTimeoutSeconds = 15;
  static const int offHoursIntervalSeconds = 180; // 3 minutes

  // Geofence
  static const double defaultGeofenceRadius = 200.0; // meters

  // Family Code
  static const int familyCodeLength = 6;

  // Battery Thresholds
  static const int batteryLowThreshold = 20;
  static const int batteryCriticalThreshold = 10;
  static const int connectionLostMinutes = 15;

  // Timeline
  static const int stopDwellMinutes = 10; // Stay > 10 min = stop event
  static const double stopDistanceThreshold = 50.0; // meters

  // Auto Check-in
  static const int checkinCooldownMinutes = 30;

  // Notification Channels
  static const String locationChannelId = 'location_tracking';
  static const String locationChannelName = 'Location Tracking';
  static const String sosChannelId = 'sos_alerts';
  static const String sosChannelName = 'SOS Alerts';
  static const String geofenceChannelId = 'geofence_alerts';
  static const String geofenceChannelName = 'Geofence Alerts';
  static const String batteryChannelId = 'battery_alerts';
  static const String batteryChannelName = 'Battery Alerts';
  static const String checkinChannelId = 'checkin_alerts';
  static const String checkinChannelName = 'Check-in Alerts';

  // SharedPreferences Keys
  static const String prefUserRole = 'user_role';
  static const String prefFamilyId = 'family_id';
  static const String prefTrackingEnabled = 'tracking_enabled';
  static const String prefLanguage = 'app_language';
}
