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
      'map': 'Map',
      'members': 'Members',
      'zones': 'Zones',
      'reports': 'Reports',
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
      'map': 'Bản đồ',
      'members': 'Thành viên',
      'zones': 'Vùng',
      'reports': 'Báo cáo',
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
