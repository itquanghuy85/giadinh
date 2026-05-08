import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/features/auth/presentation/login_screen.dart';
import 'package:family_finance/features/debt/presentation/debt_screen.dart';
import 'package:family_finance/features/family/presentation/family_screen.dart';
import 'package:family_finance/features/family/presentation/join_family_screen.dart';
import 'package:family_finance/features/family_map/presentation/family_map_screen.dart';
import 'package:family_finance/features/fund/presentation/fund_screen.dart';
import 'package:family_finance/features/report/presentation/report_screen.dart';
import 'package:family_finance/features/search/search_screen.dart';
import 'package:family_finance/features/settings/presentation/settings_screen.dart';
import 'package:family_finance/features/wallet/presentation/wallet_detail_screen.dart';
import 'package:family_finance/shared/models/wallet.dart';
import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.walletDetail:
        final wallet = settings.arguments as WalletModel;
        return MaterialPageRoute(builder: (_) => WalletDetailScreen(wallet: wallet));
      case AppRoutes.debt:
        return MaterialPageRoute(builder: (_) => const DebtScreen());
      case AppRoutes.fund:
        return MaterialPageRoute(builder: (_) => const FundScreen());
      case AppRoutes.report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      case AppRoutes.family:
        return MaterialPageRoute(builder: (_) => const FamilyScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.joinFamily:
        return MaterialPageRoute(builder: (_) => const JoinFamilyScreen());
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case AppRoutes.familyMap:
        return MaterialPageRoute(
          builder: (_) => const FamilyMapScreen(),
          fullscreenDialog: true,
        );
      default:
        return null;
    }
  }
}
