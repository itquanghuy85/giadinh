import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<AppUser> _members = [];
  List<AppUser> _children = [];
  StreamSubscription? _membersSubscription;
  StreamSubscription? _childrenSubscription;

  List<AppUser> get members => _members;
  List<AppUser> get children => _children;

  void listenToMembers(String familyId) {
    _membersSubscription?.cancel();
    _membersSubscription =
        _firestoreService.familyMembersStream(familyId).listen((members) {
      _members = members;
      notifyListeners();
    }, onError: (e) => debugPrint('familyMembersStream error: $e'));
  }

  void listenToChildren(String familyId) {
    _childrenSubscription?.cancel();
    _childrenSubscription =
        _firestoreService.familyChildrenStream(familyId).listen((children) {
      _children = children;
      notifyListeners();
    }, onError: (e) => debugPrint('familyChildrenStream error: $e'));
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    _childrenSubscription?.cancel();
    super.dispose();
  }
}
