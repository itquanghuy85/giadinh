import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/repositories/finance_repository.dart';
import 'package:family_finance/shared/services/firebase_auth_service.dart';
import 'package:family_finance/shared/services/firestore_service.dart';
import 'package:family_finance/shared/services/local_biometrics_service.dart';
import 'package:family_finance/shared/services/seed_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(firestore: ref.watch(firestoreProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(firestore: ref.watch(firestoreProvider));
});

final localBiometricsServiceProvider = Provider<LocalBiometricsService>((ref) {
  return LocalBiometricsService();
});

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService();
});
