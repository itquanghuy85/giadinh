import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service theo dõi kết nối mạng
class ConnectivityService {
  ConnectivityService() {
    _init();
  }

  final _ctrl = StreamController<bool>.broadcast();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _isOnline;
  Stream<bool> get onlineStream => _ctrl.stream;

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.any((r) => r != ConnectivityResult.none);
    _ctrl.add(_isOnline);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _ctrl.add(online);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _ctrl.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final svc = ConnectivityService();
  ref.onDispose(svc.dispose);
  return svc;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStream;
});
