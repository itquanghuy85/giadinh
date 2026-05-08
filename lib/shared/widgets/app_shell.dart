import 'package:family_finance/features/calendar/presentation/calendar_screen.dart';
import 'package:family_finance/features/family/presentation/family_screen.dart';
import 'package:family_finance/features/home/presentation/home_screen.dart';
import 'package:family_finance/features/wallet/presentation/wallet_screen.dart';
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

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Trang chủ',
      ),
      const NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Ví',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Lịch',
      ),
      const NavigationDestination(
        icon: Icon(Icons.groups_2_outlined),
        selectedIcon: Icon(Icons.groups_2),
        label: 'Gia đình',
      ),
    ];

    final screens = [
      const HomeScreen(),
      const WalletScreen(),
      const CalendarScreen(),
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
          setState(() => _currentIndex = index);
        },
        destinations: destinations,
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
