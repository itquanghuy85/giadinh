import 'package:family_finance/app/theme/app_theme.dart';
import 'package:family_finance/app/routes/app_router.dart';
import 'package:family_finance/features/auth/presentation/login_screen.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/onboarding/onboarding_screen.dart';
import 'package:family_finance/features/onboarding/splash_screen.dart';
import 'package:family_finance/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider quản lý theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class FamilyFinanceApp extends ConsumerStatefulWidget {
  const FamilyFinanceApp({super.key});

  @override
  ConsumerState<FamilyFinanceApp> createState() => _FamilyFinanceAppState();
}

class _FamilyFinanceAppState extends ConsumerState<FamilyFinanceApp> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenOnboarding') ?? false;
    final savedTheme = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    if (mounted) {
      ref.read(themeModeProvider.notifier).state = ThemeMode.values[savedTheme];
      setState(() => _showOnboarding = !seen);
    }
  }

  void _onSplashDone() {
    setState(() => _showSplash = false);
  }

  void _onOnboardingDone() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    Widget home;
    if (_showSplash) {
      home = SplashScreen(onDone: _onSplashDone);
    } else if (_showOnboarding && authState.user == null) {
      home = OnboardingScreen(onDone: _onOnboardingDone);
    } else if (authState.isLoading) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (authState.user == null) {
      home = const LoginScreen();
    } else {
      home = const AppShell();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Family Finance',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('vi', 'VN');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('vi', 'VN');
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: home,
    );
  }
}
