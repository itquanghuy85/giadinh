import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class LocalBiometricsService {
  LocalBiometricsService({LocalAuthentication? localAuthentication})
      : _localAuth = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  Future<bool> authenticate() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      // Nếu thiết bị không hỗ trợ hoặc chưa cài vân tay/PIN → bỏ qua xác thực
      if (!canCheck || !isSupported) return true;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return true;

      return await _localAuth.authenticate(
        localizedReason: 'Xác thực để mở ứng dụng tài chính gia đình',
        options: const AuthenticationOptions(biometricOnly: false),
      );
    } on PlatformException catch (e) {
      // NotAvailable: chưa cài PIN/vân tay; PasscodeNotSet; NotEnrolled
      // → bỏ qua xác thực, cho vào app bình thường
      if (e.code == 'NotAvailable' ||
          e.code == 'NotEnrolled' ||
          e.code == 'PasscodeNotSet') {
        return true;
      }
      return true; // Các lỗi khác cũng cho qua để không block app
    } catch (_) {
      return true;
    }
  }
}
