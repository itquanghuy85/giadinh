import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/services/wallet_edit_service.dart';

/// [THÊM MỚI] Provider cho WalletEditService
final walletEditServiceProvider = Provider((ref) => WalletEditService());
