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
  static const String familyEventsCollection = 'family_events';
  static const String securityEventsCollection = 'security_events';
  static const String screenTimeCollection = 'screen_time_configs';
  static const String appManagementCollection = 'app_management_configs';
  static const String contentFilterCollection = 'content_filter_configs';
  static const String transactionsCollection = 'transactions';

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

  // GPS Detection
  static const int gpsAlertCooldownMinutes = 10;
  static const int permissionCheckIntervalSeconds = 30;

  // Connection Lost
  static const int longDisconnectionMinutes = 30;

  // Night Alert
  static const int defaultNightStartHour = 22;
  static const int defaultNightEndHour = 6;

  // Near Home
  static const double nearHomeDistanceMeters = 500.0;
  static const int nearHomeCooldownMinutes = 20;

  // Calendar
  static const int eventReminderMinutes = 15;
  static const List<int> defaultEventReminderStages = [60, 15, 5];

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
  static const String securityChannelId = 'security_alerts';
  static const String securityChannelName = 'Security Alerts';
  static const String calendarChannelId = 'calendar_alerts';
  static const String calendarChannelName = 'Calendar Alerts';
  static const String nightAlertChannelId = 'night_alerts';
  static const String nightAlertChannelName = 'Night Movement Alerts';

  // SharedPreferences Keys
  static const String prefUserRole = 'user_role';
  static const String prefFamilyId = 'family_id';
  static const String prefTrackingEnabled = 'tracking_enabled';
  static const String prefLanguage = 'app_language';
  static const String prefSimSerial = 'sim_serial';
  static const String prefNightAlertEnabled = 'night_alert_enabled';
  static const String prefNightStartHour = 'night_start_hour';
  static const String prefNightEndHour = 'night_end_hour';
  static const String prefEventReminderEnabled = 'event_reminder_enabled';
  static const String prefEventReminderStages = 'event_reminder_stages';

  // Screen Time
  static const String screenTimeChannelId = 'screen_time_alerts';
  static const String screenTimeChannelName = 'Screen Time Alerts';
  static const int defaultDailyLimitMinutes = 120;
}
