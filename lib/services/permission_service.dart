import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> requestBackgroundLocationPermission() async {
    // First ensure "while in use" location is granted
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) return false;
    }

    final bgStatus = await Permission.locationAlways.request();
    return bgStatus.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> isLocationGranted() async {
    return await Permission.location.isGranted;
  }

  Future<bool> isBackgroundLocationGranted() async {
    return await Permission.locationAlways.isGranted;
  }

  Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await Permission.location.isGranted,
      'backgroundLocation': await Permission.locationAlways.isGranted,
      'notification': await Permission.notification.isGranted,
    };
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
