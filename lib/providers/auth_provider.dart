import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  AppUser? _currentUser;
  Family? _currentFamily;
  bool _isLoading = true;
  String? _error;

  AppUser? get currentUser => _currentUser;
  Family? get currentFamily => _currentFamily;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get hasFamily => _currentUser?.familyId != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        _currentFamily = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _firestoreService.getUser(uid);
      if (_currentUser?.familyId != null) {
        _currentFamily =
            await _firestoreService.getFamily(_currentUser!.familyId!);
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      _currentUser = null;
      _currentFamily = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user == null) {
        _setLoading(false);
        return false;
      }

      final user = credential!.user!;
      final existingUser = await _firestoreService.getUser(user.uid);

      if (existingUser == null) {
        // New user - will need to select role
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
          role: UserRole.parent, // default, will be changed
        );
      } else {
        _currentUser = existingUser;
        if (existingUser.familyId != null) {
          _currentFamily =
              await _firestoreService.getFamily(existingUser.familyId!);
        }
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> setupAsParent(String familyName) async {
    _setLoading(true);
    try {
      final user = _authService.currentUser!;
      final familyId = const Uuid().v4();
      final familyCode = _generateFamilyCode();
      final fcmToken = await _notificationService.getToken();

      final family = Family(
        id: familyId,
        name: familyName,
        code: familyCode,
        createdBy: user.uid,
        members: [user.uid],
        createdAt: DateTime.now(),
      );

      _currentUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        role: UserRole.parent,
        familyId: familyId,
        isOnline: true,
        lastActive: DateTime.now(),
        fcmToken: fcmToken,
      );

      await _firestoreService.createFamily(family);
      await _firestoreService.createUser(_currentUser!);

      _currentFamily = family;
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> setupAsChild(String familyCode) async {
    _setLoading(true);
    try {
      final family = await _firestoreService.getFamilyByCode(familyCode);
      if (family == null) {
        _error = 'Family code not found. Please check and try again.';
        _setLoading(false);
        return false;
      }

      final user = _authService.currentUser!;
      final fcmToken = await _notificationService.getToken();

      _currentUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        role: UserRole.child,
        familyId: family.id,
        isOnline: true,
        lastActive: DateTime.now(),
        fcmToken: fcmToken,
      );

      await _firestoreService.createUser(_currentUser!);
      await _firestoreService.addMemberToFamily(family.id, user.uid);

      _currentFamily = family;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    if (_currentUser != null) {
      await _firestoreService.updateUserOnlineStatus(
          _currentUser!.uid, false);
    }
    await _authService.signOut();
    _currentUser = null;
    _currentFamily = null;
    notifyListeners();
  }

  String _generateFamilyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final uuid = const Uuid().v4().replaceAll('-', '');
    String code = '';
    for (int i = 0; i < 6; i++) {
      final index = uuid.codeUnitAt(i) % chars.length;
      code += chars[index];
    }
    return code;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
