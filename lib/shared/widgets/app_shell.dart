import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/calendar/presentation/calendar_screen.dart';
import 'package:family_finance/features/family/presentation/family_screen.dart';
import 'package:family_finance/features/family_map/presentation/family_map_screen.dart';
import 'package:family_finance/features/home/presentation/home_screen.dart';
import 'package:family_finance/features/report/presentation/report_screen.dart';
import 'package:family_finance/features/transaction/presentation/add_transaction_screen.dart';
import 'package:family_finance/features/wallet/presentation/wallet_screen.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/services/connectivity_service.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  bool _checkedBiometric = false;
  bool _biometricOk = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final ok = await ref.read(localBiometricsServiceProvider).authenticate();
    if (!mounted) return;
    setState(() {
      _biometricOk = ok;
      _checkedBiometric = true;
    });
  }

  void _openAddTransaction() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedBiometric) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_biometricOk) {
      return Scaffold(
        body: Center(
          child: FilledButton.icon(
            onPressed: _authenticate,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Xác thực lại để mở ứng dụng'),
          ),
        ),
      );
    }

    final auth = ref.watch(authControllerProvider);
    final role = auth.profile?.role ?? UserRole.childLimited;

    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
      const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Ví'),
      const NavigationDestination(
        icon: CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.add, color: Colors.white),
        ),
        label: 'Thêm',
      ),
      const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Lịch'),
      const NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Bản đồ'),
      if (role != UserRole.childLimited)
        const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Báo cáo'),
      const NavigationDestination(icon: Icon(Icons.groups_2_outlined), label: 'Gia đình'),
    ];

    final screens = [
      const HomeScreen(),
      const WalletScreen(),
      const SizedBox.shrink(),
      const CalendarScreen(),
      const FamilyMapScreen(),
      if (role != UserRole.childLimited) const ReportScreen(),
      const FamilyScreen(),
    ];
    final selectedIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    return Scaffold(
      body: Column(
        children: [
          // Offline banner
          _OfflineBanner(),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            _openAddTransaction();
            return;
          }

          setState(() => _currentIndex = index);
        },
        destinations: destinations,
      ),
      appBar: AppBar(
        title: Text(
          'Xin chào ${auth.profile?.displayName ?? 'thành viên'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// ── Offline Banner ─────────────────────────────────────────────
class _OfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final isOnline = onlineAsync.valueOrNull ?? true;
    if (isOnline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.amber.shade700,
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang offline – Dữ liệu có thể chưa cập nhật',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
