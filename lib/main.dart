import 'package:family_finance/app/app.dart';
import 'package:family_finance/firebase_options.dart';
import 'package:family_finance/shared/services/notification_service.dart';
import 'package:family_finance/shared/utils/locale_bootstrap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocaleBootstrap.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: FamilyFinanceApp()));
}
