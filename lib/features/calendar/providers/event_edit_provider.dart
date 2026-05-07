import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/services/event_edit_service.dart';

/// [THÊM MỚI] Provider cho EventEditService
final eventEditServiceProvider = Provider((ref) => EventEditService());
