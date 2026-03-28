import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// True while an active sign-in is in progress;
  /// prevents the auth state listener from overriding _currentUser.
  bool _isSigningIn = false;

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
      // Don't override state while sign-in is in progress
      if (_isSigningIn) return;

      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        _currentFamily = null;
        _isLoading = false;
        notifyListeners();
      }
    });

    // Safety timeout: if auth stream never fires, stop loading after 5s
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading && !_isSigningIn) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final loaded = await _firestoreService.getUser(uid);
      if (loaded != null) {
        _currentUser = loaded;
        if (loaded.familyId != null) {
          _currentFamily =
              await _firestoreService.getFamily(loaded.familyId!);
        }
      } else if (_currentUser?.uid != uid) {
        // Only clear if the signed-in user doesn't already match
        _currentUser = null;
        _currentFamily = null;
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
    _isSigningIn = true;
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user == null) {
        _error = 'Sign-in was cancelled or failed. Please try again.';
        _isSigningIn = false;
        _setLoading(false);
        return false;
      }

      final user = credential!.user!;
      final existingUser = await _firestoreService.getUser(user.uid);

      if (existingUser == null) {
        final fcmToken = await _notificationService.getToken();
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
          role: UserRole.parent,
          isOnline: true,
          lastActive: DateTime.now(),
          fcmToken: fcmToken,
        );
        // Save immediately so the auth-state listener won't null out _currentUser
        await _firestoreService.createUser(_currentUser!);
      } else {
        _currentUser = existingUser;
        if (existingUser.familyId != null) {
          _currentFamily =
              await _firestoreService.getFamily(existingUser.familyId!);
        }
      }

      _isSigningIn = false;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isSigningIn = false;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _isSigningIn = false;
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _isSigningIn = true;
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authService.signInWithApple();
      if (credential?.user == null) {
        _error = 'Apple sign-in was cancelled or failed. Please try again.';
        _isSigningIn = false;
        _setLoading(false);
        return false;
      }

      final user = credential!.user!;
      final existingUser = await _firestoreService.getUser(user.uid);

      if (existingUser == null) {
        final fcmToken = await _notificationService.getToken();
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
          role: UserRole.parent,
          isOnline: true,
          lastActive: DateTime.now(),
          fcmToken: fcmToken,
        );
        // Save immediately so the auth-state listener won't null out _currentUser
        await _firestoreService.createUser(_currentUser!);
      } else {
        _currentUser = existingUser;
        if (existingUser.familyId != null) {
          _currentFamily =
              await _firestoreService.getFamily(existingUser.familyId!);
        }
      }

      _isSigningIn = false;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isSigningIn = false;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _isSigningIn = false;
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

  /// Delete all user data from Firestore, remove from family, and delete Firebase Auth account.
  Future<void> deleteAccountAndData() async {
    final user = _currentUser;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (user == null || firebaseUser == null) return;

    try {
      // Remove from family members list
      if (user.familyId != null) {
        await FirebaseFirestore.instance
            .collection('families')
            .doc(user.familyId)
            .update({
          'members': FieldValue.arrayRemove([user.uid]),
        });
      }

      // Delete user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete location data
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(user.uid)
          .delete();

      // Delete Firebase Auth account
      await firebaseUser.delete();

      _currentUser = null;
      _currentFamily = null;
      notifyListeners();
    } catch (e) {
      // If re-authentication is required, sign out instead
      await _authService.signOut();
      _currentUser = null;
      _currentFamily = null;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
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
