import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/models/wallet.dart';
import 'package:family_finance/shared/providers/access_scope_provider.dart';
import 'package:family_finance/shared/services/firestore_service.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletsProvider = StreamProvider.autoDispose<List<WalletModel>>((ref) {
  final uid = ref.watch(authControllerProvider).user?.uid;
  if (uid == null) {
    return Stream.value(const []);
  }

  final ownersAsync = ref.watch(accessibleOwnerIdsProvider);
  final owners = ownersAsync.valueOrNull?.isNotEmpty == true
      ? ownersAsync.valueOrNull!
      : <String>[uid];

  if (owners.isEmpty) {
    return Stream.value(const []);
  }

  return ref.watch(financeRepositoryProvider).streamWalletsByOwners(owners);
});

class WalletTransactionsState {
  const WalletTransactionsState({
    required this.items,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
  });

  const WalletTransactionsState.initial()
      : items = const [],
        isLoadingMore = false,
        hasMore = true,
        error = null;

  final List<TransactionModel> items;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  WalletTransactionsState copyWith({
    List<TransactionModel>? items,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return WalletTransactionsState(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

final walletTransactionsProvider = StateNotifierProvider.autoDispose<WalletTransactionsController, WalletTransactionsState>((ref) {
  final controller = WalletTransactionsController(
    ref.watch(firestoreServiceProvider),
  );
  final uid = ref.watch(authControllerProvider).user?.uid;
  final ownersAsync = ref.watch(accessibleOwnerIdsProvider);
  final owners = uid == null
      ? const <String>[]
      : (ownersAsync.valueOrNull?.isNotEmpty == true
            ? ownersAsync.valueOrNull!
            : <String>[uid]);
  controller.bindOwners(owners);
  return controller;
});

class WalletTransactionsController extends StateNotifier<WalletTransactionsState> {
  WalletTransactionsController(this._service) : super(const WalletTransactionsState.initial());

  final FirestoreService _service;
  final List<StreamSubscription<dynamic>> _streamSubs = [];
  final Map<String, List<TransactionModel>> _liveByOwner = {};
  final Map<String, DocumentSnapshot<Map<String, dynamic>>?> _cursorByOwner = {};
  final Map<String, List<TransactionModel>> _olderByOwner = {};
  List<String> _owners = const [];

  static const int _pageSize = 20;

  void bindOwners(List<String> owners) {
    if (_owners.join(',') == owners.join(',')) {
      return;
    }

    _owners = owners;
    _resetStreams();
  }

  void _resetStreams() {
    for (final sub in _streamSubs) {
      sub.cancel();
    }
    _streamSubs.clear();

    _liveByOwner.clear();
    _olderByOwner.clear();
    _cursorByOwner.clear();

    if (_owners.isEmpty) {
      state = const WalletTransactionsState.initial().copyWith(hasMore: false);
      return;
    }

    for (final uid in _owners) {
      _streamSubs.add(_service.streamTransactions(uid, limit: _pageSize).listen(
        (data) {
          _liveByOwner[uid] = data;
          _mergeAndEmit();
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      ));

      _service.getTransactionsPaginated(uid, limit: _pageSize).then((page) {
        _cursorByOwner[uid] = page.lastDoc;
        _mergeAndEmit();
      });
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    bool gotNew = false;

    try {
      for (final uid in _owners) {
        final page = await _service.getTransactionsPaginated(
          uid,
          limit: _pageSize,
          startAfter: _cursorByOwner[uid],
        );

        if (page.data.isNotEmpty) {
          gotNew = true;
          _cursorByOwner[uid] = page.lastDoc;
          _olderByOwner[uid] = [...?_olderByOwner[uid], ...page.data];
        }
      }

      _mergeAndEmit(isLoadingMore: false, hasMore: gotNew);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void _mergeAndEmit({bool? isLoadingMore, bool? hasMore}) {
    final merged = [
      ..._liveByOwner.values.expand((e) => e),
      ..._olderByOwner.values.expand((e) => e),
    ];

    final unique = <String, TransactionModel>{};
    for (final tx in merged) {
      unique['${tx.ownerUid}:${tx.id}'] = tx;
    }

    final list = unique.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = state.copyWith(
      items: list,
      isLoadingMore: isLoadingMore ?? state.isLoadingMore,
      hasMore: hasMore ?? state.hasMore,
    );
  }

  @override
  void dispose() {
    for (final sub in _streamSubs) {
      sub.cancel();
    }
    super.dispose();
  }
}
