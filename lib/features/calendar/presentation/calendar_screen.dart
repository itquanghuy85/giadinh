import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/calendar/providers/calendar_provider.dart';
import 'package:family_finance/features/calendar/providers/event_edit_provider.dart';
import 'package:family_finance/features/calendar/presentation/add_event_dialog.dart';
import 'package:family_finance/features/family/providers/family_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/models/family_event.dart';
import 'package:family_finance/shared/widgets/role_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  bool _canDeleteEvent(FamilyEvent event, UserRole role, String uid) {
    return role == UserRole.fatherAdmin || role == UserRole.motherManager || event.createdBy == uid;
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sự kiện này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteEvent(String familyId, FamilyEvent event) async {
    await ref.read(eventEditServiceProvider).deleteEvent(familyId, event.id);
    ref.invalidate(familyEventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedCalendarDayProvider);
    final role = ref.watch(authControllerProvider).profile?.role ?? UserRole.childLimited;
    final familyId = ref.watch(authControllerProvider).profile?.familyId;
    final uid = ref.watch(authControllerProvider).user?.uid ?? '';
    final eventsAsync = ref.watch(familyEventsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final selectedDayEvents = ref.watch(selectedDayEventsProvider);

    if (familyId == null || familyId.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu'));
    }

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không tải được lịch: $error'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(familyEventsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (events) {
        return membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lịch gia đình', style: Theme.of(context).textTheme.titleLarge),
                  RoleGuard(
                    roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
                    child: FilledButton.tonal(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể tải danh sách thành viên')),
                      ),
                      child: const Text('+ Thêm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          data: (members) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lịch gia đình', style: Theme.of(context).textTheme.titleLarge),
                    RoleGuard(
                      roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
                      child: FilledButton.tonal(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AddEventDialog(
                            familyId: familyId,
                            uid: uid,
                            members: members,
                            onSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sự kiện được tạo thành công')),
                            ),
                          ),
                        ),
                        child: const Text('+ Thêm'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar<FamilyEvent>(
                      firstDay: DateTime(2020),
                  lastDay: DateTime(2035),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  onDaySelected: (nextDay, focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    ref.read(selectedCalendarDayProvider.notifier).state = DateTime(
                      nextDay.year,
                      nextDay.month,
                      nextDay.day,
                    );
                  },
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(color: AppColors.income, shape: BoxShape.circle),
                  ),
                  eventLoader: (day) {
                    return events.where((event) {
                      final d = event.startAt;
                      return d.year == day.year && d.month == day.month && d.day == day.day;
                    }).toList();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Sự kiện hôm nay', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (selectedDayEvents.isEmpty)
              const Card(child: ListTile(title: Text('Chưa có sự kiện cho ngày này'))),
            ...selectedDayEvents.map((event) {
              final canDelete = _canDeleteEvent(event, role, uid);
              final tile = Card(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                  ),
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text('${DateFormat('HH:mm').format(event.startAt)} · ${event.assignee} · Lặp ${event.repeat}'),
                    onLongPress: !canDelete
                        ? null
                        : () => showModalBottomSheet(
                              context: context,
                              builder: (_) => ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final ok = await _confirmDelete();
                                  if (!ok) return;
                                  await _deleteEvent(familyId, event);
                                },
                              ),
                            ),
                  ),
                ),
              );

              if (!canDelete) return tile;
              return Dismissible(
                key: ValueKey('event-${event.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(),
                onDismissed: (_) async => _deleteEvent(familyId, event),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                child: tile,
              );
            }),
          ],
            );
          },
        );
      },
    );
  }
}
