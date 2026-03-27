import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // ─── COMMON ───
      'app_name': 'Family Safety',
      'loading': 'Loading...',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'continue_btn': 'Continue',
      'back': 'Back',
      'error': 'Error',
      'success': 'Success',
      'ok': 'OK',
      'retry': 'Retry',
      'search': 'Search',
      'settings': 'Settings',
      'close': 'Close',
      'yes': 'Yes',
      'no': 'No',
      'just_now': 'Just now',
      'min_ago': '{} min ago',
      'hour_ago': '{} h ago',
      'day_ago': '{} d ago',
      'online': 'Online',
      'offline': 'Offline',
      'active': 'Active',
      'paused': 'Paused',
      'parent': 'Parent',
      'child': 'Child',
      'language': 'Language',
      'english': 'English',
      'vietnamese': 'Tiếng Việt',

      // ─── AUTH ───
      'sign_in_title': 'Family Safety',
      'sign_in_subtitle':
          'Keep your family safe and connected.\nReal-time location sharing & alerts.',
      'sign_in_google': 'Sign in with Google',
      'sign_in_agree':
          'By signing in, you agree to our Privacy Policy\nand Terms of Service.',
      'welcome': 'Welcome,\n{}! 👋',
      'choose_role': 'Choose your role to get started:',
      'im_parent': "I'm a Parent",
      'parent_subtitle':
          "Create a family group and\nmonitor your children's safety",
      'im_child': "I'm a Child",
      'child_subtitle':
          'Join your family group and\nshare your location safely',
      'sign_out_other': 'Sign out & use different account',
      'create_family': 'Create Family',
      'create_family_group': 'Create your Family Group',
      'create_family_desc':
          "Give your family group a name. You'll receive a unique code to share with your children.",
      'family_name_hint': 'Family name (e.g. "The Smiths")',
      'family_name_required': 'Please enter a family name',
      'family_created': 'Family Created! 🎉',
      'share_code_msg': 'Share this code with your children to join:',
      'keep_code_safe': 'Keep this code safe!',
      'join_family': 'Join Family',
      'join_family_title': 'Join your Family',
      'join_family_desc':
          'Enter the family code your parent shared with you to join the family group.',
      'enter_code': 'Enter 6-digit family code',
      'invalid_code': 'Please enter a valid 6-digit code',
      'consent_text':
          'I agree to share my location with my family for safety purposes',

      // ─── PARENT HOME ───
        'home': 'Home',
      'map': 'Map',
      'members': 'Members',
      'zones': 'Zones',
      'reports': 'Reports',
        'home_welcome_parent': 'Hello, {}',
        'home_reminder_info':
          'Upcoming events are automatically reminded 15 minutes in advance.',
        'home_online_children': 'Children online',
        'home_offline_children': 'Children offline',
        'home_upcoming_events': 'Upcoming events',
        'home_security_today': 'Security alerts today',
        'home_quick_actions': 'Quick Actions',
        'home_agenda_today': 'Today Agenda',
        'home_recent_alerts': 'Recent Security Alerts',
        'home_no_agenda': 'No schedule or events yet.',
        'home_agenda_now': 'Now',
        'home_agenda_past': 'Passed',
        'home_agenda_in_min': 'In {} min',
        'home_agenda_in_hour': 'In {} h',
        'home_school_mode_start': 'School mode starts',
        'home_school_mode_end': 'School mode ends',
          'home_filter_3days': '3 Days',
          'home_filter_7days': '7 Days',
          'home_quick_add_event': 'Quick Add Event',
          'event_reminder_settings': 'Event Reminders',
          'event_reminder_settings_sub': 'Set reminder time points',
          'event_reminder_settings_desc':
            'Notifications are sent before event time based on your selected stages.',
          'enable_event_reminders': 'Enable event reminders',
          'reminder_time_points': 'Reminder time points',
          'event_reminder_before_min': '{} minutes before',
          'event_reminder_note':
            'Tip: Keep at least one stage enabled (e.g. 15 minutes) to avoid missing events.',
      'family_map': 'Family Map',
      'family_members': 'Family Members',
      'family_code': 'Code: {}',
      'no_children': 'No children connected yet.',
      'share_code': 'Share your family code to add members.',
      'no_members': 'No members yet',
      'share_code_invite': 'Share your family code to invite members',
      'family_code_title': 'Family Code',
      'share_code_with': 'Share this code with family members',
      'last_seen': 'Last seen: {}',
      'never_connected': 'Never connected',
      'battery': 'Battery',
      'status': 'Status',
      'you': 'You',
      'my_location': 'My Location',
      'getting_location': 'Getting your location...',
      'distance_from_you': 'Distance from you',
      'current_location_label': 'Current location',
      'last_update': 'Last update',
      'get_directions': 'Directions',
      'open_in_maps': 'Open in Maps',
      'go': 'Go',
      'no_location_data': 'No location data',
      'navigate_to': 'Navigate',
      'google_maps': 'Google Maps',
      'calculating_route': 'Calculating route...',
      'route_not_found': 'Could not find a route',
      'eta_minutes': '{} min',
      'all_steps': 'All Steps',
      'recalculate': 'Recalculate',
      'fit_route': 'Fit Route',
      'stop_nav': 'Stop',
      'turn_by_turn': 'Turn-by-Turn Directions',
      'steps_label': 'steps',

      // ─── SOS ───
      'sos': 'SOS',
      'sos_alert': '🚨 SOS Alert!',
      'sos_from': '🚨 SOS from {}',
      'sos_needs_help': '{} needs help! Location: ({}, {})',
      'send_sos': 'Send SOS?',
      'send_sos_desc':
          'This will immediately alert your parents with your current location. Use only in emergencies.',
      'send_sos_btn': 'SEND SOS',
      'sos_sent': 'SOS alert sent to your parents!',
      'sos_failed': 'Failed to send SOS. Try again.',
      'sos_hold': 'Press and hold for emergency SOS',

      // ─── GEOFENCE ───
      'safe_zones': 'Safe Zones',
      'safe_zones_desc':
          'Create safe zones and get notified when your child enters or leaves.',
      'no_safe_zones': 'No safe zones yet',
      'tap_add_zone': 'Tap + to create your first safe zone',
      'add_zone': 'Add Zone',
      'add_safe_zone': 'Add Safe Zone',
      'zone_name_hint': 'Zone name (e.g. Home, School)',
      'radius_hint': 'Radius in meters',
      'meters': 'meters',
      'tap_map': 'Tap on map to select location:',
      'create_safe_zone': 'Create Safe Zone',
      'radius': 'Radius: {}m',
      'entered_safe_zone': '✅ Entered Safe Zone',
      'left_safe_zone': '⚠️ Left Safe Zone',
      'entered_zone_msg': '{} entered "{}"',
      'left_zone_msg': '{} left "{}"',

      // ─── DANGER ZONE ───
      'danger_zones': 'Danger Zones',
      'danger_zones_desc':
          'Mark dangerous areas. Get alerted when your child enters.',
      'no_danger_zones': 'No danger zones yet',
      'tap_add_danger': 'Tap + to mark a danger zone',
      'add_danger_zone': 'Add Danger Zone',
      'danger_zone_name': 'Zone name (e.g. "Busy intersection")',
      'create_danger_zone': 'Create Danger Zone',
      'danger_alert': '🚨 Danger Zone Alert',
      'entered_danger': '{} entered danger zone "{}"',
      'latitude': 'Latitude',
      'longitude': 'Longitude',

      // ─── CHILD HOME ───
      'hi_user': 'Hi, {}!',
      'location_sharing_active': 'Location Sharing Active',
      'location_sharing_paused': 'Location Sharing Paused',
      'family_can_see': 'Your family can see your location',
      'family_cannot_see': 'Your family cannot see your location',
      'pause_sharing': 'Pause Sharing',
      'start_sharing': 'Start Sharing',
      'sign_out': 'Sign Out',
      'sign_out_confirm': 'Are you sure you want to sign out?',

      // ─── PERMISSIONS ───
      'location_access': 'Location Access',
      'location_access_desc':
          'We need location access to share your position with your family. This helps your parents know you are safe.',
      'location_access_detail':
          'Your location is only shared with your family members. We never sell or share your data with third parties.',
      'bg_location': 'Background Location',
      'bg_location_desc':
          'To keep your family updated, we need to access your location even when the app is in the background.',
      'bg_location_detail':
          'A notification will always be shown when location sharing is active. You can pause sharing at any time. This is required by Google Play policy for transparency.',
      'notifications': 'Notifications',
      'notifications_desc':
          'Notifications are used for SOS alerts, geofence alerts, and showing the location sharing status.',
      'notifications_detail':
          'You will receive important safety alerts from your family. A persistent notification shows when location sharing is active.',
      'already_granted': 'Already Granted - Next',
      'allow_location': 'Allow Location',
      'allow_bg_location': 'Allow Background Location',
      'allow_notifications': 'Allow Notifications',
      'already_granted_continue': 'Already Granted - Continue',

      // ─── SETTINGS ───
      'family': 'Family',
      'family_name': 'Family Name',
      'family_code_label': 'Family Code',
      'family_members_count': '{} members',
      'app': 'App',
      'privacy_policy': 'Privacy Policy',
      'privacy_policy_sub': 'Read our privacy policy',
      'about': 'About',
      'version': 'Version 1.0.0',
      'code_copied': 'Code copied!',

      // ─── DAILY REPORT ───
      'daily_report': 'Daily Report',
      'smart_daily_report': 'Smart Daily Report',
      'total_distance': 'Total Distance',
      'total_moving_time': 'Moving Time',
      'max_speed': 'Max Speed',
      'most_visited': 'Most Visited',
      'left_home': 'Left Home',
      'arrived_home': 'Arrived Home',
      'no_report': 'No report data for this day',
      'km': 'km',
      'kmh': 'km/h',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'select_child': 'Select Child',
      'daily_summary': 'Daily Summary',
      'movement_log': 'Movement Log',

      // ─── TIMELINE ───
      'timeline': 'Timeline',
      'auto_timeline': 'Auto Timeline',
      'left_place': 'Left {}',
      'arrived_at': 'Arrived at {}',
      'stopped_at': 'Stopped at {}',
      'moving': 'Moving',
      'stopped': 'Stopped',
      'no_timeline': 'No timeline events for this day',
      'stop_event': 'Stop',
      'move_event': 'Move',
      'duration_min': '{} min',
      'duration_hour': '{}h {}m',

      // ─── BATTERY ALERT ───
      'battery_low_warning': '⚠️ Low Battery Warning',
      'battery_critical': '🔴 Critical Battery',
      'battery_low_msg': '{} battery is at {}%',
      'battery_critical_msg': '{} battery critically low at {}%! May lose contact soon.',
      'connection_lost': '📡 Connection Lost',
      'connection_lost_msg': 'No update from {} for over 15 minutes',
      'battery_alert': 'Battery Alert',

      // ─── SCHEDULE MODE ───
      'school_mode': 'School Mode',
      'smart_schedule': 'Smart Schedule Mode',
      'schedule_desc':
          'Optimize battery and tracking during school hours.',
      'school_hours': 'School Hours',
      'school_start': 'School Start',
      'school_end': 'School End',
      'tracking_interval': 'Tracking Interval',
      'school_interval': 'During School: Every 20 sec',
      'off_hours_interval': 'Off Hours: Every 2-5 min',
      'schedule_enabled': 'Schedule Mode Enabled',
      'schedule_disabled': 'Schedule Mode Disabled',
      'school_days': 'School Days',
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',

      // ─── AUTO CHECK-IN ───
      'auto_checkin': 'Auto Check-in',
      'auto_arrival': 'Auto Arrival Detection',
      'arrived_notification': '{} arrived at {} at {}',
      'checkin_cooldown': 'Cooldown: 30 minutes between check-ins',
      'checkin_zones': 'Check-in Zones',

      // ─── USER GUIDE ───
      'user_guide': 'User Guide',
      'user_guide_subtitle': 'Learn how to use all features',
      'getting_started': 'Getting Started',
      'guide_getting_started_title': '1. Getting Started',
      'guide_getting_started_1': 'Sign in with your Google account.',
      'guide_getting_started_2': 'Choose your role: Parent or Child.',
      'guide_getting_started_3_parent': 'As a Parent: Create a Family Group and receive a unique 6-digit code.',
      'guide_getting_started_4_parent': 'Share this code with your children so they can join.',
      'guide_getting_started_3_child': 'As a Child: Enter the 6-digit family code from your parent to join.',
      'guide_getting_started_4_child': 'Grant location and notification permissions to start sharing.',

      'guide_realtime_map_title': '2. Real-time Map',
      'guide_realtime_map_1': 'The Map tab shows all family members\' live locations on a map.',
      'guide_realtime_map_2': 'Tap on a marker to view a member\'s name, battery level, and last seen time.',
      'guide_realtime_map_3': 'The map refreshes automatically every 20 seconds during school hours.',

      'guide_members_title': '3. Family Members',
      'guide_members_1': 'The Members tab lists all family members with their status.',
      'guide_members_2': 'View each child\'s battery level, online/offline status, and last active time.',
      'guide_members_3': 'SOS alerts from children will appear here with a red badge.',

      'guide_safe_zones_title': '4. Safe Zones (Geofences)',
      'guide_safe_zones_1': 'Create circular safe zones around important places like Home, School, etc.',
      'guide_safe_zones_2': 'Enter a zone name, tap the map to select the center, and set the radius.',
      'guide_safe_zones_3': 'You\'ll receive an instant notification when your child enters or leaves a safe zone.',
      'guide_safe_zones_4': 'Swipe left on a zone to delete it.',

      'guide_danger_zones_title': '5. Danger Zones',
      'guide_danger_zones_1': 'Mark dangerous areas (busy roads, construction sites, etc.) on the map.',
      'guide_danger_zones_2': 'Enter the zone name, coordinates, and radius.',
      'guide_danger_zones_3': 'A "Danger Zone Alert" notification is sent immediately when your child enters.',
      'guide_danger_zones_4': 'Access from Settings > Danger Zones.',

      'guide_daily_report_title': '6. Smart Daily Report',
      'guide_daily_report_1': 'Go to the Reports > Daily Summary tab.',
      'guide_daily_report_2': 'Select a child and a date to view the report.',
      'guide_daily_report_3': 'Shows: total distance, max speed, moving time, most visited place.',
      'guide_daily_report_4': 'Also shows home departure and arrival times (if a "Home" safe zone is set).',
      'guide_daily_report_5': 'Tap "Daily Report" button to generate a report from location history.',

      'guide_timeline_title': '7. Auto Timeline',
      'guide_timeline_1': 'Go to the Reports > Timeline tab.',
      'guide_timeline_2': 'Automatically detects stops (stayed > 10 min within 50m) and moves.',
      'guide_timeline_3': 'Each event shows location name (if near a known zone), start/end time, and duration.',
      'guide_timeline_4': 'Tap the refresh button to regenerate the timeline from location history.',

      'guide_battery_alerts_title': '8. Low Battery Alerts',
      'guide_battery_alerts_1': 'Automatic alerts when a child\'s battery drops below 20% (warning) or 10% (critical).',
      'guide_battery_alerts_2': 'If no location update is received for 15 minutes, a "Connection Lost" alert is sent.',
      'guide_battery_alerts_3': 'These notifications help you stay aware of your child\'s phone status.',

      'guide_schedule_title': '9. Smart Schedule Mode',
      'guide_schedule_1': 'Access from Settings > Smart Schedule Mode.',
      'guide_schedule_2': 'Set school start/end times and select school days.',
      'guide_schedule_3': 'During school hours: location updates every 20 seconds (intensive tracking).',
      'guide_schedule_4': 'Outside school hours: updates every 2-5 minutes (preserves battery).',
      'guide_schedule_5': 'Toggle the switch to enable or disable schedule mode.',

      'guide_auto_checkin_title': '10. Auto Arrival Detection',
      'guide_auto_checkin_1': 'When a child enters any safe zone, an automatic check-in notification is sent.',
      'guide_auto_checkin_2': 'Example: "Tommy arrived at School at 07:25".',
      'guide_auto_checkin_3': 'A 30-minute cooldown prevents duplicate notifications for the same zone.',

      'guide_sos_title': '11. SOS Emergency Alert',
      'guide_sos_1': 'Children can press and hold the SOS button to send an emergency alert.',
      'guide_sos_2': 'Parents receive an instant notification with the child\'s exact location.',
      'guide_sos_3': 'The alert includes GPS coordinates for quick response.',
      'guide_sos_4': 'This feature should only be used in real emergencies.',

      'guide_location_sharing_title': '12. Location Sharing (Child)',
      'guide_location_sharing_1': 'As a child, your location is shared automatically after granting permissions.',
      'guide_location_sharing_2': 'You can pause sharing at any time from the home screen.',
      'guide_location_sharing_3': 'A persistent notification shows when location sharing is active.',
      'guide_location_sharing_4': 'Your location is only visible to your family members — never to strangers.',

      'guide_language_title': '13. Language Settings',
      'guide_language_1': 'Go to Settings and toggle the Language switch.',
      'guide_language_2': 'The app supports English and Vietnamese.',
      'guide_language_3': 'Your language preference is saved and remembered on next launch.',

      'guide_tips_title': 'Tips & Best Practices',
      'guide_tip_1': '• Create a "Home" safe zone first to enable home departure/arrival tracking.',
      'guide_tip_2': '• Enable Schedule Mode to optimize battery life during school.',
      'guide_tip_3': '• Check the Daily Report each evening to review your child\'s day.',
      'guide_tip_4': '• Mark any known dangerous areas in your neighborhood as Danger Zones.',
      'guide_tip_5': '• Make sure children keep their phone charged above 20% when possible.',
      'guide_tip_6': '• Test the SOS feature once so your child knows how to use it.',

      // ─── SECURITY ALERTS ───
      'security_alerts': 'Security Alerts',
      'no_security_events': 'No security events',
      'security_events_desc': 'GPS, SIM, and connection alerts appear here.',
      'gps_disabled': 'GPS Disabled',
      'gps_enabled': 'GPS Enabled',
      'permission_revoked': 'Permission Revoked',
      'sim_changed': 'SIM Changed',
      'connection_lost_event': 'Connection Lost',
      'connection_restored': 'Connection Restored',
      'night_movement': 'Night Movement',
      'gps_disabled_title': '📍 GPS Disabled',
      'gps_disabled_body': 'GPS has been turned off on the tracked device. Location tracking is not available.',
      'permission_revoked_title': '🔒 Permission Revoked',
      'permission_revoked_body': 'Location permission was revoked. Cannot track device.',
      'sim_changed_title': '📱 SIM Card Changed',
      'sim_changed_body': 'The SIM card has been changed on the tracked device.',
      'long_disconnection_title': '📡 Long Disconnection',
      'long_disconnection_body': 'No update for over 30 minutes. Device may be off or out of range.',
      'night_movement_title': '🌙 Night Movement',
      'night_movement_body': 'Movement detected outside home zone during night hours.',
      'near_home_title': '🏠 Near Home',
      'near_home_body': '{} is approaching home (within 500m).',

      // ─── FAMILY CALENDAR ───
      'family_calendar': 'Family Calendar',
      'no_events': 'No events yet',
      'tap_add_event': 'Tap + to add your first event',
      'add_event': 'Add Event',
      'event_title': 'Event Title',
      'event_title_required': 'Please enter an event title',
      'event_location_optional': 'Location (optional)',
      'create_event': 'Create Event',
      'upcoming_events': 'Upcoming Events',
      'past_events': 'Past Events',
      'at_time': 'at {}',
      'event_reminder_title': '📅 Event Reminder',
      'event_reminder_body': '"{}" starts in 15 minutes',
      'event_location': 'Location: {}',

      // ─── NIGHT ALERT ───
      'night_alert': 'Night Alert',
      'night_alert_desc': 'Get alerted when movement is detected outside home during night hours.',
      'enable_night_alert': 'Enable Night Alert',
      'night_alert_toggle_desc': 'Receive notifications for night movements outside home',
      'night_time_window': 'Night Time Window',
      'night_start': 'Night Start',
      'night_end': 'Night End',
      'night_alert_info': 'Night alerts are sent when your child moves outside the home zone during the night time window. Make sure you have a "Home" safe zone configured.',

      // ─── AREA TIME ANALYSIS ───
      'area_time_analysis': 'Area Time Analysis',
      'time_by_area': 'Time by Area',
      'area_home': 'Home',
      'area_school': 'School',
      'area_other': 'Other',
      'no_area_data': 'No area data for this day',
      'date': 'Date',

      // ─── PDF REPORT ───
      'pdf_report': 'PDF Report',
      'weekly_pdf_report': 'Weekly PDF Report',
      'pdf_report_desc': 'Generate a detailed PDF report of your child\'s activities for the selected week.',
      'generate_pdf': 'Generate & Share PDF',
      'generating': 'Generating...',
      'week_of': 'Week of',
      'weekly_report': 'Weekly Report',

      // ─── HOME WIDGET ───
      'home_widget': 'Home Widget',
      'home_widget_desc': 'Add a widget to your home screen to see child status at a glance.',
      'widget_updated': 'Widget updated',

      // ─── NEW USER GUIDE SECTIONS ───
      'guide_gps_detection_title': '14. GPS Disable Detection',
      'guide_gps_detection_1': 'Automatically detects when GPS is turned off on the child\'s device.',
      'guide_gps_detection_2': 'A push notification alerts the parent immediately.',
      'guide_gps_detection_3': 'Also detects if location permission is revoked.',
      'guide_gps_detection_4': 'All security events are logged and viewable under Security Alerts.',

      'guide_sim_detection_title': '15. SIM Change Detection',
      'guide_sim_detection_1': 'The app stores the child\'s initial SIM card serial.',
      'guide_sim_detection_2': 'If the SIM card is swapped, a notification is sent to the parent.',
      'guide_sim_detection_3': 'Useful for detecting if the child\'s phone is tampered with.',
      'guide_sim_detection_4': 'View SIM change events under Settings > Security Alerts.',

      'guide_disconnection_title': '16. Long Disconnection Alert',
      'guide_disconnection_1': 'If no location update is received for over 30 minutes, an alert is sent.',
      'guide_disconnection_2': 'The alert is sent only once per disconnection event.',
      'guide_disconnection_3': 'When the child comes back online, the alert resets.',
      'guide_disconnection_4': 'Check the Security Alerts screen for connection history.',

      'guide_area_time_title': '17. Area Time Analysis',
      'guide_area_time_1': 'Go to Settings > Area Time Analysis.',
      'guide_area_time_2': 'Select a child and a date to see a pie chart of time spent by area.',
      'guide_area_time_3': 'Areas are classified as Home, School, or Other based on safe zone names.',
      'guide_area_time_4': 'Helps you understand how much time your child spends in each location.',

      'guide_night_alert_title': '18. Night Movement Alerts',
      'guide_night_alert_1': 'Go to Settings > Night Alert to enable this feature.',
      'guide_night_alert_2': 'Set the night window (default: 22:00 to 06:00).',
      'guide_night_alert_3': 'If movement is detected outside the Home zone during night hours, an alert is sent.',
      'guide_night_alert_4': 'Alerts have a cooldown to prevent spam.',

      'guide_calendar_title': '19. Family Calendar',
      'guide_calendar_1': 'Go to Settings > Family Calendar.',
      'guide_calendar_2': 'Add family events with title, optional location, and date/time.',
      'guide_calendar_3': 'All family members can see upcoming events.',
      'guide_calendar_4': 'A reminder notification is sent 15 minutes before each event.',

      'guide_near_home_title': '20. Near Home Alerts',
      'guide_near_home_1': 'When your child is within 500 meters of home, you receive a notification.',
      'guide_near_home_2': 'This works automatically if you have a "Home" safe zone set up.',
      'guide_near_home_3': 'A 20-minute cooldown prevents repeated alerts.',
      'guide_near_home_4': 'Useful for knowing when your child is almost home from school.',

      'guide_pdf_title': '21. PDF Report Export',
      'guide_pdf_1': 'Go to Settings > PDF Report.',
      'guide_pdf_2': 'Select a child and a week to generate a PDF report.',
      'guide_pdf_3': 'The report includes: total distance, moving time, max speed, area time, and timeline.',
      'guide_pdf_4': 'Share the PDF via email, messaging apps, or save to your device.',

      'guide_widget_title': '22. Home Screen Widget',
      'guide_widget_1': 'Long-press your Android home screen and select "Widgets".',
      'guide_widget_2': 'Find "Family Safety" and drag the widget to your home screen.',
      'guide_widget_3': 'The widget shows: child name, online/offline status, battery level, and last update time.',
      'guide_widget_4': 'The widget updates automatically every 15 minutes.',

      // ─── SCREEN TIME ───
      'screen_time': 'Screen Time',
      'screen_time_desc': 'Set daily limits, bedtime, and schedule for your child\'s device usage.',
      'enable_screen_time': 'Enable Screen Time',
      'enable_screen_time_desc': 'Turn on screen time management for this child',
      'daily_limit': 'Daily Limit',
      'minutes': 'minutes',
      'min_short': 'min',
      'bedtime': 'Bedtime',
      'bedtime_desc': 'Block device usage during sleep hours',
      'bedtime_start': 'Bedtime Start',
      'bedtime_end': 'Bedtime End',
      'school_time_downtime': 'School Time / Downtime',
      'school_time_downtime_desc': 'Block device usage during school hours',
      'bonus_time': 'Bonus Time',
      'bonus_time_desc': 'Grant extra screen time for today',
      'bonus_active': 'Bonus active today',
      'reset': 'Reset',

      // ─── APP MANAGEMENT ───
      'app_management': 'App Management',
      'app_management_desc': 'Control which apps your child can use, set per-app limits, and prioritize education.',
      'block_new_installs': 'Block New Installs',
      'block_new_installs_desc': 'Prevent installation of new apps on the child\'s device',
      'priority_apps': 'Priority Apps',
      'blocked_apps': 'Blocked Apps',
      'limited_apps': 'Limited Apps',
      'other_apps': 'Other Apps',
      'no_managed_apps': 'No managed apps',
      'tap_add_app': 'Tap + to add an app',
      'add_app': 'Add App',
      'app_name_hint': 'App name (e.g. YouTube)',
      'package_name_hint': 'Package name (e.g. com.google.youtube)',
      'category': 'Category',
      'cat_education': 'Education',
      'cat_social': 'Social',
      'cat_entertainment': 'Entertainment',
      'cat_games': 'Games',
      'cat_tools': 'Tools',
      'cat_other': 'Other',
      'status_blocked': 'Blocked',
      'limit': 'Limit',
      'educational_priority': 'Educational priority',
      'allowed': 'Allowed',
      'block_app': 'Block',
      'unblock': 'Unblock',
      'mark_priority': 'Mark as Priority',
      'remove_priority': 'Remove Priority',
      'set_limit': 'Set Limit',
      'no_limit': 'No Limit',

      // ─── CONTENT FILTER & PRIVACY ───
      'content_filter': 'Content Filtering',
      'content_filter_desc': 'Control web, app store, YouTube, and search content. Manage privacy settings.',
      'chrome_web_filter': 'Chrome / Web Filter',
      'enable_chrome_filter': 'Enable Chrome Filter',
      'enable_chrome_filter_desc': 'Filter web content in Chrome browser',
      'block_explicit_sites': 'Block Explicit Sites',
      'blocked_websites': 'Blocked Websites',
      'allowed_websites': 'Allowed Websites',
      'sites': 'sites',
      'enter_website_url': 'Enter website URL',
      'no_websites': 'No websites added yet',
      'play_store_filter': 'Google Play Store',
      'enable_play_filter': 'Enable Play Store Filter',
      'enable_play_filter_desc': 'Filter apps and content in Google Play Store',
      'require_approval_apps': 'Require Approval for Apps',
      'require_approval_apps_desc': 'Child must get approval before installing apps',
      'content_rating': 'Content Rating',
      'select_content_rating': 'Select Content Rating',
      'youtube_restricted': 'YouTube Restricted Mode',
      'youtube_restricted_desc': 'Enable restricted mode to filter mature content on YouTube',
      'safe_search': 'Safe Search',
      'safe_search_strict': 'Strict',
      'safe_search_strict_desc': 'Filter explicit results from all searches',
      'safe_search_moderate': 'Moderate',
      'safe_search_moderate_desc': 'Filter explicit images but allow text results',
      'safe_search_off': 'Off',
      'safe_search_off_desc': 'Do not filter search results',
      'approval_settings': 'Approval Settings',
      'require_approval_websites': 'Require Approval for Websites',
      'require_approval_websites_desc': 'Child must get approval to visit blocked websites',
      'privacy_settings': 'Privacy Settings',
      'share_location_family': 'Share Location with Family',
      'share_location_family_desc': 'Allow family members to see this child\'s location',
      'allow_profile_edit': 'Allow Profile Editing',
      'allow_profile_edit_desc': 'Allow this child to edit their own profile',
      'allow_third_party': 'Allow Third-Party Access',
      'allow_third_party_desc': 'Allow third-party apps to access child\'s data',

      // ─── GUIDE: SCREEN TIME ───
      'guide_screen_time_title': '23. Screen Time Management',
      'guide_screen_time_1': 'Go to Settings > Screen Time to set daily limits for your child.',
      'guide_screen_time_2': 'Set bedtime hours to automatically block device usage during sleep.',
      'guide_screen_time_3': 'Configure School Time / Downtime to restrict usage during school hours (select specific days).',
      'guide_screen_time_4': 'Grant bonus time (+15/30/60 min) to reward good behavior today.',

      // ─── GUIDE: APP MANAGEMENT ───
      'guide_app_management_title': '24. App Management',
      'guide_app_management_1': 'Go to Settings > App Management to control installed apps.',
      'guide_app_management_2': 'Block new app installations entirely or block specific apps individually.',
      'guide_app_management_3': 'Set per-app daily time limits (e.g. 30 min for games).',
      'guide_app_management_4': 'Mark educational apps as priority so they are always allowed.',

      // ─── GUIDE: CONTENT FILTER ───
      'guide_content_filter_title': '25. Content Filtering & Privacy',
      'guide_content_filter_1': 'Go to Settings > Content Filtering to manage web and app content.',
      'guide_content_filter_2': 'Enable Chrome filter to block explicit websites. Add custom blocked/allowed lists.',
      'guide_content_filter_3': 'Set Google Play content rating, enable YouTube restricted mode, and configure Safe Search level.',
      'guide_content_filter_4': 'Manage privacy settings: location sharing, profile editing, and third-party app access.',
    },

    'vi': {
      // ─── CHUNG ───
      'app_name': 'An Toàn Gia Đình',
      'loading': 'Đang tải...',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'delete': 'Xóa',
      'confirm': 'Xác nhận',
      'continue_btn': 'Tiếp tục',
      'back': 'Quay lại',
      'error': 'Lỗi',
      'success': 'Thành công',
      'ok': 'OK',
      'retry': 'Thử lại',
      'search': 'Tìm kiếm',
      'settings': 'Cài đặt',
      'close': 'Đóng',
      'yes': 'Có',
      'no': 'Không',
      'just_now': 'Vừa xong',
      'min_ago': '{} phút trước',
      'hour_ago': '{} giờ trước',
      'day_ago': '{} ngày trước',
      'online': 'Trực tuyến',
      'offline': 'Ngoại tuyến',
      'active': 'Đang hoạt động',
      'paused': 'Đã tạm dừng',
      'parent': 'Phụ huynh',
      'child': 'Con',
      'language': 'Ngôn ngữ',
      'english': 'English',
      'vietnamese': 'Tiếng Việt',

      // ─── ĐĂNG NHẬP ───
      'sign_in_title': 'An Toàn Gia Đình',
      'sign_in_subtitle':
          'Giữ gia đình an toàn và kết nối.\nChia sẻ vị trí & cảnh báo thời gian thực.',
      'sign_in_google': 'Đăng nhập bằng Google',
      'sign_in_agree':
          'Bằng việc đăng nhập, bạn đồng ý với\nChính sách bảo mật và Điều khoản dịch vụ.',
      'welcome': 'Xin chào,\n{}! 👋',
      'choose_role': 'Chọn vai trò của bạn:',
      'im_parent': 'Tôi là Phụ huynh',
      'parent_subtitle':
          'Tạo nhóm gia đình và\ntheo dõi sự an toàn của con',
      'im_child': 'Tôi là Con',
      'child_subtitle':
          'Tham gia nhóm gia đình và\nchia sẻ vị trí an toàn',
      'sign_out_other': 'Đăng xuất & dùng tài khoản khác',
      'create_family': 'Tạo Gia đình',
      'create_family_group': 'Tạo Nhóm Gia đình',
      'create_family_desc':
          'Đặt tên cho nhóm gia đình. Bạn sẽ nhận mã duy nhất để chia sẻ với con.',
      'family_name_hint': 'Tên gia đình (VD: "Nhà Nguyễn")',
      'family_name_required': 'Vui lòng nhập tên gia đình',
      'family_created': 'Đã tạo gia đình! 🎉',
      'share_code_msg': 'Chia sẻ mã này cho con để tham gia:',
      'keep_code_safe': 'Giữ mã này an toàn!',
      'join_family': 'Tham gia Gia đình',
      'join_family_title': 'Tham gia Gia đình',
      'join_family_desc':
          'Nhập mã gia đình mà bố mẹ đã chia sẻ để tham gia nhóm.',
      'enter_code': 'Nhập mã 6 ký tự',
      'invalid_code': 'Vui lòng nhập mã 6 ký tự hợp lệ',
      'consent_text':
          'Tôi đồng ý chia sẻ vị trí với gia đình vì mục đích an toàn',

      // ─── TRANG CHỦ PHỤ HUYNH ───
        'home': 'Trang chủ',
      'map': 'Bản đồ',
      'members': 'Thành viên',
      'zones': 'Vùng',
      'reports': 'Báo cáo',
        'home_welcome_parent': 'Xin chào, {}',
        'home_reminder_info':
          'Sự kiện sắp tới sẽ được tự động nhắc trước 15 phút.',
        'home_online_children': 'Con đang online',
        'home_offline_children': 'Con đang offline',
        'home_upcoming_events': 'Sự kiện sắp tới',
        'home_security_today': 'Cảnh báo hôm nay',
        'home_quick_actions': 'Tác vụ nhanh',
        'home_agenda_today': 'Lịch hôm nay',
        'home_recent_alerts': 'Cảnh báo bảo mật gần đây',
        'home_no_agenda': 'Chưa có lịch hoặc sự kiện.',
        'home_agenda_now': 'Ngay bây giờ',
        'home_agenda_past': 'Đã qua',
        'home_agenda_in_min': 'Sau {} phút',
        'home_agenda_in_hour': 'Sau {} giờ',
        'home_school_mode_start': 'Bắt đầu chế độ giờ học',
        'home_school_mode_end': 'Kết thúc chế độ giờ học',
          'home_filter_3days': '3 ngày',
          'home_filter_7days': '7 ngày',
          'home_quick_add_event': 'Thêm sự kiện nhanh',
          'event_reminder_settings': 'Nhắc nhở sự kiện',
          'event_reminder_settings_sub': 'Thiết lập mốc nhắc giờ',
          'event_reminder_settings_desc':
            'Thông báo sẽ được gửi trước giờ sự kiện theo các mốc bạn chọn.',
          'enable_event_reminders': 'Bật nhắc nhở sự kiện',
          'reminder_time_points': 'Các mốc nhắc giờ',
          'event_reminder_before_min': 'Trước {} phút',
          'event_reminder_note':
            'Gợi ý: Nên giữ ít nhất 1 mốc nhắc (ví dụ 15 phút) để tránh bỏ lỡ sự kiện.',
      'family_map': 'Bản đồ Gia đình',
      'family_members': 'Thành viên Gia đình',
      'family_code': 'Mã: {}',
      'no_children': 'Chưa có con nào kết nối.',
      'share_code': 'Chia sẻ mã gia đình để thêm thành viên.',
      'no_members': 'Chưa có thành viên',
      'share_code_invite': 'Chia sẻ mã gia đình để mời thành viên',
      'family_code_title': 'Mã Gia đình',
      'share_code_with': 'Chia sẻ mã này cho thành viên',
      'last_seen': 'Lần cuối: {}',
      'never_connected': 'Chưa kết nối',
      'battery': 'Pin',
      'status': 'Trạng thái',
      'you': 'Bạn',
      'my_location': 'Vị trí của tôi',
      'getting_location': 'Đang lấy vị trí...',
      'distance_from_you': 'Khoảng cách từ bạn',
      'current_location_label': 'Vị trí hiện tại',
      'last_update': 'Cập nhật lần cuối',
      'get_directions': 'Chỉ đường',
      'open_in_maps': 'Mở bản đồ',
      'go': 'Đi',
      'no_location_data': 'Chưa có vị trí',
      'navigate_to': 'Dẫn đường',
      'google_maps': 'Google Maps',
      'calculating_route': 'Đang tính tuyến đường...',
      'route_not_found': 'Không tìm thấy tuyến đường',
      'eta_minutes': '{} phút',
      'all_steps': 'Tất cả',
      'recalculate': 'Tính lại',
      'fit_route': 'Xem toàn bộ',
      'stop_nav': 'Dừng',
      'turn_by_turn': 'Chỉ dẫn từng bước',
      'steps_label': 'bước',

      // ─── SOS ───
      'sos': 'SOS',
      'sos_alert': '🚨 Cảnh báo SOS!',
      'sos_from': '🚨 SOS từ {}',
      'sos_needs_help': '{} cần giúp đỡ! Vị trí: ({}, {})',
      'send_sos': 'Gửi SOS?',
      'send_sos_desc':
          'Điều này sẽ báo ngay cho bố mẹ kèm vị trí hiện tại. Chỉ dùng khi khẩn cấp.',
      'send_sos_btn': 'GỬI SOS',
      'sos_sent': 'Đã gửi SOS cho bố mẹ!',
      'sos_failed': 'Gửi SOS thất bại. Thử lại.',
      'sos_hold': 'Nhấn giữ để gửi SOS khẩn cấp',

      // ─── VÙNG AN TOÀN ───
      'safe_zones': 'Vùng An toàn',
      'safe_zones_desc':
          'Tạo vùng an toàn và nhận thông báo khi con vào hoặc rời đi.',
      'no_safe_zones': 'Chưa có vùng an toàn',
      'tap_add_zone': 'Nhấn + để tạo vùng an toàn đầu tiên',
      'add_zone': 'Thêm vùng',
      'add_safe_zone': 'Thêm Vùng An toàn',
      'zone_name_hint': 'Tên vùng (VD: Nhà, Trường)',
      'radius_hint': 'Bán kính (mét)',
      'meters': 'mét',
      'tap_map': 'Chạm vào bản đồ để chọn vị trí:',
      'create_safe_zone': 'Tạo Vùng An toàn',
      'radius': 'Bán kính: {}m',
      'entered_safe_zone': '✅ Đã vào Vùng An toàn',
      'left_safe_zone': '⚠️ Đã rời Vùng An toàn',
      'entered_zone_msg': '{} đã vào "{}"',
      'left_zone_msg': '{} đã rời "{}"',

      // ─── VÙNG NGUY HIỂM ───
      'danger_zones': 'Vùng Nguy hiểm',
      'danger_zones_desc':
          'Đánh dấu khu vực nguy hiểm. Nhận cảnh báo khi con vào.',
      'no_danger_zones': 'Chưa có vùng nguy hiểm',
      'tap_add_danger': 'Nhấn + để đánh dấu vùng nguy hiểm',
      'add_danger_zone': 'Thêm Vùng Nguy hiểm',
      'danger_zone_name': 'Tên vùng (VD: "Ngã tư đông đúc")',
      'create_danger_zone': 'Tạo Vùng Nguy hiểm',
      'danger_alert': '🚨 Cảnh báo Vùng Nguy hiểm',
      'entered_danger': '{} đã vào vùng nguy hiểm "{}"',
      'latitude': 'Vĩ độ',
      'longitude': 'Kinh độ',

      // ─── TRANG CHỦ CON ───
      'hi_user': 'Xin chào, {}!',
      'location_sharing_active': 'Đang chia sẻ vị trí',
      'location_sharing_paused': 'Đã tạm dừng chia sẻ',
      'family_can_see': 'Gia đình có thể thấy vị trí của bạn',
      'family_cannot_see': 'Gia đình không thể thấy vị trí của bạn',
      'pause_sharing': 'Tạm dừng',
      'start_sharing': 'Bắt đầu chia sẻ',
      'sign_out': 'Đăng xuất',
      'sign_out_confirm': 'Bạn có chắc muốn đăng xuất?',

      // ─── QUYỀN ───
      'location_access': 'Truy cập Vị trí',
      'location_access_desc':
          'Chúng tôi cần quyền vị trí để chia sẻ vị trí với gia đình. Giúp bố mẹ biết bạn an toàn.',
      'location_access_detail':
          'Vị trí chỉ chia sẻ với thành viên gia đình. Chúng tôi không bao giờ bán hay chia sẻ dữ liệu với bên thứ ba.',
      'bg_location': 'Vị trí Nền',
      'bg_location_desc':
          'Để cập nhật liên tục, chúng tôi cần truy cập vị trí ngay cả khi ứng dụng chạy nền.',
      'bg_location_detail':
          'Thông báo luôn hiển thị khi chia sẻ vị trí. Bạn có thể tạm dừng bất cứ lúc nào. Google Play yêu cầu điều này để minh bạch.',
      'notifications': 'Thông báo',
      'notifications_desc':
          'Thông báo dùng cho cảnh báo SOS, vùng an toàn và trạng thái chia sẻ vị trí.',
      'notifications_detail':
          'Bạn sẽ nhận cảnh báo an toàn quan trọng từ gia đình. Thông báo liên tục hiển thị khi chia sẻ vị trí.',
      'already_granted': 'Đã cấp - Tiếp tục',
      'allow_location': 'Cho phép Vị trí',
      'allow_bg_location': 'Cho phép Vị trí Nền',
      'allow_notifications': 'Cho phép Thông báo',
      'already_granted_continue': 'Đã cấp - Tiếp tục',

      // ─── CÀI ĐẶT ───
      'family': 'Gia đình',
      'family_name': 'Tên Gia đình',
      'family_code_label': 'Mã Gia đình',
      'family_members_count': '{} thành viên',
      'app': 'Ứng dụng',
      'privacy_policy': 'Chính sách Bảo mật',
      'privacy_policy_sub': 'Đọc chính sách bảo mật',
      'about': 'Giới thiệu',
      'version': 'Phiên bản 1.0.0',
      'code_copied': 'Đã sao chép mã!',

      // ─── BÁO CÁO HẰNG NGÀY ───
      'daily_report': 'Báo cáo ngày',
      'smart_daily_report': 'Báo cáo Di chuyển',
      'total_distance': 'Tổng quãng đường',
      'total_moving_time': 'Thời gian di chuyển',
      'max_speed': 'Tốc độ tối đa',
      'most_visited': 'Ghé nhiều nhất',
      'left_home': 'Rời nhà',
      'arrived_home': 'Về nhà',
      'no_report': 'Không có dữ liệu cho ngày này',
      'km': 'km',
      'kmh': 'km/h',
      'today': 'Hôm nay',
      'yesterday': 'Hôm qua',
      'select_child': 'Chọn con',
      'daily_summary': 'Tóm tắt ngày',
      'movement_log': 'Nhật ký di chuyển',

      // ─── TIMELINE ───
      'timeline': 'Dòng thời gian',
      'auto_timeline': 'Dòng thời gian thông minh',
      'left_place': 'Rời {}',
      'arrived_at': 'Đến {}',
      'stopped_at': 'Dừng tại {}',
      'moving': 'Đang di chuyển',
      'stopped': 'Đang dừng',
      'no_timeline': 'Không có sự kiện cho ngày này',
      'stop_event': 'Dừng',
      'move_event': 'Di chuyển',
      'duration_min': '{} phút',
      'duration_hour': '{}g {}p',

      // ─── CẢNH BÁO PIN ───
      'battery_low_warning': '⚠️ Cảnh báo Pin yếu',
      'battery_critical': '🔴 Pin sắp hết',
      'battery_low_msg': 'Pin {} còn {}%',
      'battery_critical_msg':
          'Pin {} cực thấp còn {}%! Có thể mất liên lạc sớm.',
      'connection_lost': '📡 Mất kết nối',
      'connection_lost_msg': 'Không nhận cập nhật từ {} hơn 15 phút',
      'battery_alert': 'Cảnh báo Pin',

      // ─── CHẾ ĐỘ ĐI HỌC ───
      'school_mode': 'Chế độ Đi học',
      'smart_schedule': 'Lịch Thông minh',
      'schedule_desc':
          'Tối ưu pin và theo dõi trong giờ học.',
      'school_hours': 'Giờ học',
      'school_start': 'Bắt đầu học',
      'school_end': 'Kết thúc học',
      'tracking_interval': 'Tần suất theo dõi',
      'school_interval': 'Trong giờ học: Mỗi 20 giây',
      'off_hours_interval': 'Ngoài giờ: Mỗi 2-5 phút',
      'schedule_enabled': 'Đã bật Chế độ Lịch',
      'schedule_disabled': 'Đã tắt Chế độ Lịch',
      'school_days': 'Ngày học',
      'mon': 'T2',
      'tue': 'T3',
      'wed': 'T4',
      'thu': 'T5',
      'fri': 'T6',
      'sat': 'T7',
      'sun': 'CN',

      // ─── TỰ ĐỘNG CHECK-IN ───
      'auto_checkin': 'Tự động Check-in',
      'auto_arrival': 'Phát hiện Đến nơi',
      'arrived_notification': '{} đã đến {} lúc {}',
      'checkin_cooldown': 'Thời gian chờ: 30 phút giữa các check-in',
      'checkin_zones': 'Vùng Check-in',

      // ─── HƯỚNG DẪN SỬ DỤNG ───
      'user_guide': 'Hướng dẫn sử dụng',
      'user_guide_subtitle': 'Tìm hiểu cách sử dụng tất cả tính năng',
      'getting_started': 'Bắt đầu',
      'guide_getting_started_title': '1. Bắt đầu sử dụng',
      'guide_getting_started_1': 'Đăng nhập bằng tài khoản Google.',
      'guide_getting_started_2': 'Chọn vai trò: Phụ huynh hoặc Con.',
      'guide_getting_started_3_parent': 'Phụ huynh: Tạo Nhóm Gia đình và nhận mã 6 ký tự duy nhất.',
      'guide_getting_started_4_parent': 'Chia sẻ mã này cho con để tham gia nhóm.',
      'guide_getting_started_3_child': 'Con: Nhập mã 6 ký tự từ bố mẹ để tham gia gia đình.',
      'guide_getting_started_4_child': 'Cấp quyền vị trí và thông báo để bắt đầu chia sẻ.',

      'guide_realtime_map_title': '2. Bản đồ thời gian thực',
      'guide_realtime_map_1': 'Tab Bản đồ hiển thị vị trí trực tiếp của tất cả thành viên.',
      'guide_realtime_map_2': 'Chạm vào đánh dấu để xem tên, pin và thời gian cuối.',
      'guide_realtime_map_3': 'Bản đồ tự cập nhật mỗi 20 giây trong giờ học.',

      'guide_members_title': '3. Thành viên gia đình',
      'guide_members_1': 'Tab Thành viên liệt kê tất cả thành viên với trạng thái.',
      'guide_members_2': 'Xem pin, trạng thái online/offline và thời gian hoạt động cuối của con.',
      'guide_members_3': 'Cảnh báo SOS từ con sẽ hiện ở đây với huy hiệu đỏ.',

      'guide_safe_zones_title': '4. Vùng An toàn (Geofence)',
      'guide_safe_zones_1': 'Tạo vùng an toàn hình tròn quanh các địa điểm quan trọng như Nhà, Trường...',
      'guide_safe_zones_2': 'Nhập tên vùng, chạm bản đồ để chọn tâm và đặt bán kính.',
      'guide_safe_zones_3': 'Bạn sẽ nhận thông báo ngay khi con vào hoặc rời vùng an toàn.',
      'guide_safe_zones_4': 'Vuốt trái để xóa một vùng.',

      'guide_danger_zones_title': '5. Vùng Nguy hiểm',
      'guide_danger_zones_1': 'Đánh dấu khu vực nguy hiểm (đường lớn, công trình...) trên bản đồ.',
      'guide_danger_zones_2': 'Nhập tên vùng, tọa độ và bán kính.',
      'guide_danger_zones_3': 'Thông báo "Cảnh báo Vùng Nguy hiểm" được gửi ngay khi con vào.',
      'guide_danger_zones_4': 'Truy cập từ Cài đặt > Vùng Nguy hiểm.',

      'guide_daily_report_title': '6. Báo cáo Di chuyển hằng ngày',
      'guide_daily_report_1': 'Vào Báo cáo > Tab Tóm tắt ngày.',
      'guide_daily_report_2': 'Chọn con và ngày để xem báo cáo.',
      'guide_daily_report_3': 'Hiển thị: tổng quãng đường, tốc độ tối đa, thời gian di chuyển, nơi ghé nhiều nhất.',
      'guide_daily_report_4': 'Cũng hiển thị giờ rời nhà và về nhà (nếu đã tạo vùng "Nhà").',
      'guide_daily_report_5': 'Nhấn nút "Báo cáo ngày" để tạo báo cáo từ lịch sử vị trí.',

      'guide_timeline_title': '7. Dòng thời gian tự động',
      'guide_timeline_1': 'Vào Báo cáo > Tab Dòng thời gian.',
      'guide_timeline_2': 'Tự động phát hiện điểm dừng (ở lại > 10 phút trong 50m) và di chuyển.',
      'guide_timeline_3': 'Mỗi sự kiện hiển thị tên địa điểm (nếu gần vùng đã biết), giờ bắt đầu/kết thúc và thời lượng.',
      'guide_timeline_4': 'Nhấn nút làm mới để tạo lại dòng thời gian từ lịch sử.',

      'guide_battery_alerts_title': '8. Cảnh báo Pin yếu',
      'guide_battery_alerts_1': 'Tự động cảnh báo khi pin con dưới 20% (cảnh báo) hoặc 10% (nghiêm trọng).',
      'guide_battery_alerts_2': 'Nếu không nhận cập nhật vị trí trong 15 phút, gửi cảnh báo "Mất kết nối".',
      'guide_battery_alerts_3': 'Các thông báo này giúp bạn nắm bắt tình trạng điện thoại con.',

      'guide_schedule_title': '9. Chế độ Lịch thông minh',
      'guide_schedule_1': 'Truy cập từ Cài đặt > Lịch thông minh.',
      'guide_schedule_2': 'Đặt giờ bắt đầu/kết thúc học và chọn ngày học.',
      'guide_schedule_3': 'Trong giờ học: cập nhật vị trí mỗi 20 giây (theo dõi chuyên sâu).',
      'guide_schedule_4': 'Ngoài giờ học: cập nhật mỗi 2-5 phút (tiết kiệm pin).',
      'guide_schedule_5': 'Bật/tắt công tắc để kích hoạt chế độ lịch.',

      'guide_auto_checkin_title': '10. Phát hiện Đến nơi tự động',
      'guide_auto_checkin_1': 'Khi con vào bất kỳ vùng an toàn nào, thông báo check-in tự động được gửi.',
      'guide_auto_checkin_2': 'Ví dụ: "Bé Nam đã đến Trường lúc 07:25".',
      'guide_auto_checkin_3': 'Thời gian chờ 30 phút giữa các thông báo cùng một vùng.',

      'guide_sos_title': '11. Cảnh báo SOS khẩn cấp',
      'guide_sos_1': 'Con có thể nhấn giữ nút SOS để gửi cảnh báo khẩn cấp.',
      'guide_sos_2': 'Phụ huynh nhận thông báo ngay lập tức kèm vị trí chính xác.',
      'guide_sos_3': 'Cảnh báo bao gồm tọa độ GPS để phản hồi nhanh.',
      'guide_sos_4': 'Tính năng này chỉ nên sử dụng trong trường hợp khẩn cấp thật sự.',

      'guide_location_sharing_title': '12. Chia sẻ vị trí (Con)',
      'guide_location_sharing_1': 'Là con, vị trí được chia sẻ tự động sau khi cấp quyền.',
      'guide_location_sharing_2': 'Bạn có thể tạm dừng chia sẻ bất cứ lúc nào từ màn hình chính.',
      'guide_location_sharing_3': 'Thông báo liên tục hiển thị khi đang chia sẻ vị trí.',
      'guide_location_sharing_4': 'Vị trí chỉ hiển thị cho thành viên gia đình — không bao giờ cho người lạ.',

      'guide_language_title': '13. Cài đặt Ngôn ngữ',
      'guide_language_1': 'Vào Cài đặt và bật/tắt công tắc Ngôn ngữ.',
      'guide_language_2': 'Ứng dụng hỗ trợ Tiếng Anh và Tiếng Việt.',
      'guide_language_3': 'Ngôn ngữ được lưu và ghi nhớ cho lần mở tiếp theo.',

      'guide_tips_title': 'Mẹo & Lưu ý',
      'guide_tip_1': '• Tạo vùng an toàn "Nhà" đầu tiên để theo dõi giờ rời/về nhà.',
      'guide_tip_2': '• Bật Chế độ Lịch để tối ưu pin trong giờ học.',
      'guide_tip_3': '• Xem Báo cáo ngày mỗi tối để theo dõi hoạt động con.',
      'guide_tip_4': '• Đánh dấu các khu vực nguy hiểm trong khu phố là Vùng Nguy hiểm.',
      'guide_tip_5': '• Đảm bảo con luôn sạc điện thoại trên 20% khi có thể.',
      'guide_tip_6': '• Thử tính năng SOS một lần để con biết cách sử dụng.',

      // ─── CẢNH BÁO BẢO MẬT ───
      'security_alerts': 'Cảnh báo Bảo mật',
      'no_security_events': 'Chưa có sự kiện bảo mật',
      'security_events_desc': 'Cảnh báo GPS, SIM và kết nối hiện ở đây.',
      'gps_disabled': 'GPS bị tắt',
      'gps_enabled': 'GPS đã bật',
      'permission_revoked': 'Đã thu hồi quyền',
      'sim_changed': 'Đổi SIM',
      'connection_lost_event': 'Mất kết nối',
      'connection_restored': 'Đã kết nối lại',
      'night_movement': 'Di chuyển ban đêm',
      'gps_disabled_title': '📍 GPS bị tắt',
      'gps_disabled_body': 'GPS đã bị tắt trên thiết bị theo dõi. Không thể theo dõi vị trí.',
      'permission_revoked_title': '🔒 Quyền bị thu hồi',
      'permission_revoked_body': 'Quyền vị trí đã bị thu hồi. Không thể theo dõi thiết bị.',
      'sim_changed_title': '📱 Đổi thẻ SIM',
      'sim_changed_body': 'Thẻ SIM đã được thay đổi trên thiết bị theo dõi.',
      'long_disconnection_title': '📡 Mất kết nối lâu',
      'long_disconnection_body': 'Không có cập nhật hơn 30 phút. Thiết bị có thể đã tắt hoặc ngoài vùng phủ sóng.',
      'night_movement_title': '🌙 Di chuyển ban đêm',
      'night_movement_body': 'Phát hiện di chuyển ngoài vùng nhà trong giờ ban đêm.',
      'near_home_title': '🏠 Gần nhà',
      'near_home_body': '{} đang đến gần nhà (trong 500m).',

      // ─── LỊCH GIA ĐÌNH ───
      'family_calendar': 'Lịch Gia đình',
      'no_events': 'Chưa có sự kiện',
      'tap_add_event': 'Nhấn + để thêm sự kiện đầu tiên',
      'add_event': 'Thêm Sự kiện',
      'event_title': 'Tên Sự kiện',
      'event_title_required': 'Vui lòng nhập tên sự kiện',
      'event_location_optional': 'Địa điểm (tùy chọn)',
      'create_event': 'Tạo Sự kiện',
      'upcoming_events': 'Sự kiện sắp tới',
      'past_events': 'Sự kiện đã qua',
      'at_time': 'lúc {}',
      'event_reminder_title': '📅 Nhắc nhở Sự kiện',
      'event_reminder_body': '"{}" bắt đầu trong 15 phút',
      'event_location': 'Địa điểm: {}',

      // ─── CẢNH BÁO BAN ĐÊM ───
      'night_alert': 'Cảnh báo Ban đêm',
      'night_alert_desc': 'Nhận cảnh báo khi phát hiện di chuyển ngoài nhà trong giờ ban đêm.',
      'enable_night_alert': 'Bật Cảnh báo Ban đêm',
      'night_alert_toggle_desc': 'Nhận thông báo khi con di chuyển ban đêm ngoài nhà',
      'night_time_window': 'Khung giờ ban đêm',
      'night_start': 'Bắt đầu đêm',
      'night_end': 'Kết thúc đêm',
      'night_alert_info': 'Cảnh báo ban đêm được gửi khi con di chuyển ngoài vùng nhà trong khung giờ ban đêm. Hãy đảm bảo bạn đã cấu hình vùng an toàn "Nhà".',

      // ─── PHÂN TÍCH THỜI GIAN KHU VỰC ───
      'area_time_analysis': 'Phân tích Thời gian Khu vực',
      'time_by_area': 'Thời gian theo Khu vực',
      'area_home': 'Nhà',
      'area_school': 'Trường',
      'area_other': 'Khác',
      'no_area_data': 'Không có dữ liệu khu vực cho ngày này',
      'date': 'Ngày',

      // ─── BÁO CÁO PDF ───
      'pdf_report': 'Báo cáo PDF',
      'weekly_pdf_report': 'Báo cáo PDF Tuần',
      'pdf_report_desc': 'Tạo báo cáo PDF chi tiết về hoạt động của con cho tuần đã chọn.',
      'generate_pdf': 'Tạo & Chia sẻ PDF',
      'generating': 'Đang tạo...',
      'week_of': 'Tuần của',
      'weekly_report': 'Báo cáo Tuần',

      // ─── WIDGET MÀN HÌNH ───
      'home_widget': 'Widget Màn hình',
      'home_widget_desc': 'Thêm widget vào màn hình chính để xem nhanh trạng thái con.',
      'widget_updated': 'Đã cập nhật widget',

      // ─── HƯỚNG DẪN MỚI ───
      'guide_gps_detection_title': '14. Phát hiện GPS bị tắt',
      'guide_gps_detection_1': 'Tự động phát hiện khi GPS bị tắt trên thiết bị của con.',
      'guide_gps_detection_2': 'Thông báo đẩy cảnh báo phụ huynh ngay lập tức.',
      'guide_gps_detection_3': 'Cũng phát hiện nếu quyền vị trí bị thu hồi.',
      'guide_gps_detection_4': 'Tất cả sự kiện bảo mật được ghi lại và xem trong Cảnh báo Bảo mật.',

      'guide_sim_detection_title': '15. Phát hiện đổi SIM',
      'guide_sim_detection_1': 'Ứng dụng lưu số serial SIM ban đầu của con.',
      'guide_sim_detection_2': 'Nếu SIM bị thay đổi, thông báo được gửi cho phụ huynh.',
      'guide_sim_detection_3': 'Hữu ích để phát hiện nếu điện thoại con bị can thiệp.',
      'guide_sim_detection_4': 'Xem sự kiện đổi SIM trong Cài đặt > Cảnh báo Bảo mật.',

      'guide_disconnection_title': '16. Cảnh báo mất kết nối lâu',
      'guide_disconnection_1': 'Nếu không nhận cập nhật vị trí hơn 30 phút, cảnh báo được gửi.',
      'guide_disconnection_2': 'Cảnh báo chỉ gửi một lần cho mỗi sự kiện mất kết nối.',
      'guide_disconnection_3': 'Khi con trực tuyến trở lại, cảnh báo được đặt lại.',
      'guide_disconnection_4': 'Kiểm tra màn hình Cảnh báo Bảo mật để xem lịch sử kết nối.',

      'guide_area_time_title': '17. Phân tích Thời gian Khu vực',
      'guide_area_time_1': 'Vào Cài đặt > Phân tích Thời gian Khu vực.',
      'guide_area_time_2': 'Chọn con và ngày để xem biểu đồ tròn thời gian theo khu vực.',
      'guide_area_time_3': 'Khu vực được phân loại: Nhà, Trường, hoặc Khác dựa trên tên vùng an toàn.',
      'guide_area_time_4': 'Giúp bạn hiểu con dành bao nhiêu thời gian ở mỗi địa điểm.',

      'guide_night_alert_title': '18. Cảnh báo Di chuyển ban đêm',
      'guide_night_alert_1': 'Vào Cài đặt > Cảnh báo Ban đêm để bật tính năng.',
      'guide_night_alert_2': 'Đặt khung giờ ban đêm (mặc định: 22:00 đến 06:00).',
      'guide_night_alert_3': 'Nếu phát hiện di chuyển ngoài vùng Nhà trong giờ đêm, cảnh báo được gửi.',
      'guide_night_alert_4': 'Cảnh báo có thời gian chờ để tránh gửi quá nhiều.',

      'guide_calendar_title': '19. Lịch Gia đình',
      'guide_calendar_1': 'Vào Cài đặt > Lịch Gia đình.',
      'guide_calendar_2': 'Thêm sự kiện gia đình với tên, địa điểm (tùy chọn) và thời gian.',
      'guide_calendar_3': 'Tất cả thành viên gia đình có thể xem sự kiện sắp tới.',
      'guide_calendar_4': 'Thông báo nhắc nhở được gửi 15 phút trước mỗi sự kiện.',

      'guide_near_home_title': '20. Cảnh báo gần nhà',
      'guide_near_home_1': 'Khi con ở trong 500 mét quanh nhà, bạn nhận thông báo.',
      'guide_near_home_2': 'Hoạt động tự động nếu bạn đã tạo vùng an toàn "Nhà".',
      'guide_near_home_3': 'Thời gian chờ 20 phút tránh cảnh báo lặp lại.',
      'guide_near_home_4': 'Hữu ích để biết khi con sắp về đến nhà từ trường.',

      'guide_pdf_title': '21. Xuất Báo cáo PDF',
      'guide_pdf_1': 'Vào Cài đặt > Báo cáo PDF.',
      'guide_pdf_2': 'Chọn con và tuần để tạo báo cáo PDF.',
      'guide_pdf_3': 'Báo cáo gồm: tổng quãng đường, thời gian di chuyển, tốc độ tối đa, thời gian khu vực và dòng thời gian.',
      'guide_pdf_4': 'Chia sẻ PDF qua email, tin nhắn hoặc lưu vào thiết bị.',

      'guide_widget_title': '22. Widget Màn hình chính',
      'guide_widget_1': 'Nhấn giữ màn hình chính Android và chọn "Widget".',
      'guide_widget_2': 'Tìm "Family Safety" và kéo widget vào màn hình chính.',
      'guide_widget_3': 'Widget hiển thị: tên con, trạng thái online/offline, mức pin và giờ cập nhật cuối.',
      'guide_widget_4': 'Widget tự động cập nhật mỗi 15 phút.',

      // ─── THỜI GIAN MÀN HÌNH ───
      'screen_time': 'Thời gian Màn hình',
      'screen_time_desc': 'Đặt giới hạn hàng ngày, giờ ngủ và lịch sử dụng thiết bị cho con.',
      'enable_screen_time': 'Bật Quản lý Thời gian',
      'enable_screen_time_desc': 'Bật quản lý thời gian màn hình cho con',
      'daily_limit': 'Giới hạn Hàng ngày',
      'minutes': 'phút',
      'min_short': 'ph',
      'bedtime': 'Giờ Ngủ',
      'bedtime_desc': 'Chặn sử dụng thiết bị trong giờ ngủ',
      'bedtime_start': 'Bắt đầu giờ ngủ',
      'bedtime_end': 'Kết thúc giờ ngủ',
      'school_time_downtime': 'Giờ Học / Thời gian Nghỉ',
      'school_time_downtime_desc': 'Chặn sử dụng thiết bị trong giờ học',
      'bonus_time': 'Thời gian Thưởng',
      'bonus_time_desc': 'Cấp thêm thời gian màn hình cho con hôm nay',
      'bonus_active': 'Thưởng đang hoạt động hôm nay',
      'reset': 'Đặt lại',

      // ─── QUẢN LÝ ỨNG DỤNG ───
      'app_management': 'Quản lý Ứng dụng',
      'app_management_desc': 'Kiểm soát ứng dụng con dùng, đặt giới hạn từng ứng dụng và ưu tiên giáo dục.',
      'block_new_installs': 'Chặn Cài đặt mới',
      'block_new_installs_desc': 'Ngăn cài đặt ứng dụng mới trên thiết bị con',
      'priority_apps': 'Ứng dụng Ưu tiên',
      'blocked_apps': 'Ứng dụng bị Chặn',
      'limited_apps': 'Ứng dụng Giới hạn',
      'other_apps': 'Ứng dụng Khác',
      'no_managed_apps': 'Chưa có ứng dụng quản lý',
      'tap_add_app': 'Nhấn + để thêm ứng dụng',
      'add_app': 'Thêm Ứng dụng',
      'app_name_hint': 'Tên ứng dụng (VD: YouTube)',
      'package_name_hint': 'Tên gói (VD: com.google.youtube)',
      'category': 'Danh mục',
      'cat_education': 'Giáo dục',
      'cat_social': 'Mạng xã hội',
      'cat_entertainment': 'Giải trí',
      'cat_games': 'Trò chơi',
      'cat_tools': 'Công cụ',
      'cat_other': 'Khác',
      'status_blocked': 'Đã chặn',
      'limit': 'Giới hạn',
      'educational_priority': 'Ưu tiên giáo dục',
      'allowed': 'Cho phép',
      'block_app': 'Chặn',
      'unblock': 'Bỏ chặn',
      'mark_priority': 'Đánh dấu Ưu tiên',
      'remove_priority': 'Bỏ Ưu tiên',
      'set_limit': 'Đặt Giới hạn',
      'no_limit': 'Không giới hạn',

      // ─── LỌC NỘI DUNG & QUYỀN RIÊNG TƯ ───
      'content_filter': 'Lọc Nội dung',
      'content_filter_desc': 'Kiểm soát nội dung web, Play Store, YouTube và tìm kiếm. Quản lý quyền riêng tư.',
      'chrome_web_filter': 'Bộ lọc Chrome / Web',
      'enable_chrome_filter': 'Bật Bộ lọc Chrome',
      'enable_chrome_filter_desc': 'Lọc nội dung web trong trình duyệt Chrome',
      'block_explicit_sites': 'Chặn Trang nhạy cảm',
      'blocked_websites': 'Trang web bị Chặn',
      'allowed_websites': 'Trang web Cho phép',
      'sites': 'trang',
      'enter_website_url': 'Nhập URL trang web',
      'no_websites': 'Chưa thêm trang web nào',
      'play_store_filter': 'Google Play Store',
      'enable_play_filter': 'Bật Bộ lọc Play Store',
      'enable_play_filter_desc': 'Lọc ứng dụng và nội dung trong Google Play Store',
      'require_approval_apps': 'Yêu cầu Phê duyệt Ứng dụng',
      'require_approval_apps_desc': 'Con phải được phê duyệt trước khi cài đặt ứng dụng',
      'content_rating': 'Xếp hạng Nội dung',
      'select_content_rating': 'Chọn Xếp hạng Nội dung',
      'youtube_restricted': 'Chế độ Giới hạn YouTube',
      'youtube_restricted_desc': 'Bật chế độ giới hạn để lọc nội dung người lớn trên YouTube',
      'safe_search': 'Tìm kiếm An toàn',
      'safe_search_strict': 'Nghiêm ngặt',
      'safe_search_strict_desc': 'Lọc kết quả nhạy cảm từ tất cả tìm kiếm',
      'safe_search_moderate': 'Vừa phải',
      'safe_search_moderate_desc': 'Lọc hình ảnh nhạy cảm nhưng cho phép kết quả văn bản',
      'safe_search_off': 'Tắt',
      'safe_search_off_desc': 'Không lọc kết quả tìm kiếm',
      'approval_settings': 'Cài đặt Phê duyệt',
      'require_approval_websites': 'Yêu cầu Phê duyệt Trang web',
      'require_approval_websites_desc': 'Con phải được phê duyệt để truy cập trang web bị chặn',
      'privacy_settings': 'Cài đặt Quyền riêng tư',
      'share_location_family': 'Chia sẻ Vị trí với Gia đình',
      'share_location_family_desc': 'Cho phép thành viên gia đình xem vị trí con',
      'allow_profile_edit': 'Cho phép Sửa Hồ sơ',
      'allow_profile_edit_desc': 'Cho phép con chỉnh sửa hồ sơ cá nhân',
      'allow_third_party': 'Cho phép Bên thứ ba',
      'allow_third_party_desc': 'Cho phép ứng dụng bên thứ ba truy cập dữ liệu con',

      // ─── HƯỚNG DẪN: THỜI GIAN MÀN HÌNH ───
      'guide_screen_time_title': '23. Quản lý Thời gian Màn hình',
      'guide_screen_time_1': 'Vào Cài đặt > Thời gian Màn hình để đặt giới hạn hàng ngày cho con.',
      'guide_screen_time_2': 'Đặt giờ ngủ để tự động chặn sử dụng thiết bị trong giờ ngủ.',
      'guide_screen_time_3': 'Cấu hình Giờ Học / Thời gian Nghỉ để hạn chế sử dụng trong giờ học (chọn ngày cụ thể).',
      'guide_screen_time_4': 'Cấp thời gian thưởng (+15/30/60 phút) để thưởng cho hành vi tốt hôm nay.',

      // ─── HƯỚNG DẪN: QUẢN LÝ ỨNG DỤNG ───
      'guide_app_management_title': '24. Quản lý Ứng dụng',
      'guide_app_management_1': 'Vào Cài đặt > Quản lý Ứng dụng để kiểm soát ứng dụng đã cài.',
      'guide_app_management_2': 'Chặn cài đặt ứng dụng mới hoàn toàn hoặc chặn từng ứng dụng riêng lẻ.',
      'guide_app_management_3': 'Đặt giới hạn thời gian hàng ngày cho từng ứng dụng (VD: 30 phút cho trò chơi).',
      'guide_app_management_4': 'Đánh dấu ứng dụng giáo dục là ưu tiên để luôn được phép sử dụng.',

      // ─── HƯỚNG DẪN: LỌC NỘI DUNG ───
      'guide_content_filter_title': '25. Lọc Nội dung & Quyền riêng tư',
      'guide_content_filter_1': 'Vào Cài đặt > Lọc Nội dung để quản lý nội dung web và ứng dụng.',
      'guide_content_filter_2': 'Bật bộ lọc Chrome để chặn trang web nhạy cảm. Thêm danh sách chặn/cho phép tùy chỉnh.',
      'guide_content_filter_3': 'Đặt xếp hạng nội dung Google Play, bật chế độ giới hạn YouTube và cấu hình mức Tìm kiếm An toàn.',
      'guide_content_filter_4': 'Quản lý quyền riêng tư: chia sẻ vị trí, chỉnh sửa hồ sơ và quyền truy cập ứng dụng bên thứ ba.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String t(String key, [List<String>? args]) {
    String value = translate(key);
    if (args != null) {
      for (final arg in args) {
        value = value.replaceFirst('{}', arg);
      }
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language') ?? 'en';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('vi'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
