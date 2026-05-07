import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/services/firebase_auth_service.dart';
import 'package:family_finance/shared/services/seed_service.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    required this.user,
    required this.profile,
    required this.isLoading,
    this.error,
  });

  const AuthState.initial()
      : user = null,
        profile = null,
        isLoading = true,
        error = null;

  final User? user;
  final AppUser? profile;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    User? user,
    AppUser? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    authService: ref.read(firebaseAuthServiceProvider),
    seedService: ref.read(seedServiceProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({required FirebaseAuthService authService, required SeedService seedService})
      : _authService = authService,
        _seedService = seedService,
        super(const AuthState.initial()) {
    _subscription = _authService.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuthService _authService;
  final SeedService _seedService;
  late final StreamSubscription<User?> _subscription;

  Future<void> _onAuthChanged(User? user) async {
    debugPrint('[Auth] authStateChange: uid=${user?.uid}');
    if (user == null) {
      state = const AuthState(user: null, profile: null, isLoading: false);
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);
      var doc = await userRef.get();

      // Tạo profile mới cho user lần đầu đăng nhập
      if (!doc.exists || (doc.data()?['familyId'] as String? ?? '').isEmpty) {
        final familyId = 'family_${user.uid}';
        debugPrint('[Auth] 📝 Creating new profile: uid=${user.uid}, familyId=$familyId');
        await userRef.set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'Thành viên',
          'role': 'admin',
          'familyId': familyId,
        }, SetOptions(merge: true));
        doc = await userRef.get();
        debugPrint('[Auth] ✅ Profile created, now seeding data...');

        // Seed data mẫu cho user mới
        _seedService.seedIfNeeded(user.uid, familyId).then((seeded) {
          debugPrint('[Auth] ${seeded ? '✅' : '⏭️'} Seed result: $seeded');
        });
      }

      final profile = AppUser.fromMap(user.uid, doc.data() ?? <String, dynamic>{});
      debugPrint('[Auth] ✅ Profile loaded: role=${profile.role.name}, familyId=${profile.familyId}');
      state = AuthState(user: user, profile: profile, isLoading: false);

      // Seed nếu chưa được seed (user cũ chưa có data mẫu)
      if (profile.familyId.isNotEmpty) {
        _seedService.seedIfNeeded(user.uid, profile.familyId).then((seeded) {
          if (seeded) debugPrint('[Auth] Seed completed for existing user');
        });
      }
    } catch (e) {
      debugPrint('[Auth] Firestore profile load error: $e');
      final emptyProfile = AppUser.fromMap(user.uid, {'email': user.email ?? ''});
      state = AuthState(user: user, profile: emptyProfile, isLoading: false);
    }
  }

  Future<void> signInWithEmailPassword({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[Auth] signInWithEmailPassword: $email');
    try {
      await _authService.signInWithEmailPassword(email: email, password: password);
      debugPrint('[Auth] Email sign-in success, waiting authStateChange...');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] FirebaseAuthException: ${e.code} - ${e.message}');
      state = state.copyWith(isLoading: false, error: _friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('[Auth] Unknown sign-in error: $e');
      state = state.copyWith(isLoading: false, error: 'Đăng nhập thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[Auth] signInWithGoogle start');
    try {
      await _authService.signInWithGoogle();
      debugPrint('[Auth] Google sign-in success, waiting authStateChange...');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Google FirebaseAuthException: ${e.code} - ${e.message}');
      state = state.copyWith(isLoading: false, error: _friendlyAuthError(e.code));
    } catch (e) {
      debugPrint('[Auth] Google sign-in error: $e');
      final msg = e.toString();
      if (msg.contains('10') || msg.contains('developer_error')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Google Sign-In lỗi cấu hình (Error 10). Cần thêm SHA-1 vào Firebase Console. '
              'Chạy: cd android && gradlew signingReport',
        );
      } else if (msg.contains('network_error') || msg.contains('SocketException')) {
        state = state.copyWith(isLoading: false, error: 'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi/4G.');
      } else {
        state = state.copyWith(isLoading: false, error: 'Đăng nhập Google thất bại. Vui lòng thử lại.');
      }
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email chưa được đăng ký.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu không đúng.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản bị vô hiệu hoá.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi vài phút.';
      case 'network-request-failed':
        return 'Không có kết nối mạng.';
      default:
        return 'Đăng nhập thất bại ($code).';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
