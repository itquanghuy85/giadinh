import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/common_widgets.dart';

class ParentMembersScreen extends StatelessWidget {
  const ParentMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Members',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${auth.currentFamily?.code ?? "N/A"}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Share code
                  IconButton(
                    onPressed: () => _showFamilyCode(context, auth.currentFamily?.code ?? ''),
                    icon: const Icon(Icons.share, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),

            // SOS Alerts
            Consumer<SosProvider>(
              builder: (context, sosProv, _) {
                if (sosProv.alerts.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.sosGradient,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    children: sosProv.alerts.map((alert) {
                      return Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚨 SOS from ${alert.childName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Lat: ${alert.latitude.toStringAsFixed(4)}, Lng: ${alert.longitude.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                sosProv.resolveAlert(alert.id),
                            icon: const Icon(Icons.check_circle,
                                color: Colors.white, size: 28),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // Members List
            Expanded(
              child: Consumer2<FamilyProvider, LocationProvider>(
                builder: (context, familyProv, locationProv, _) {
                  final members = familyProv.members;
                  if (members.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: AppTheme.textHint),
                          SizedBox(height: 16),
                          Text(
                            'No members yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Share your family code to invite members',
                            style: TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: members.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final location =
                          locationProv.childLocations[member.uid];
                      return _MemberCard(
                        member: member,
                        batteryLevel: location?.batteryLevel ??
                            member.batteryLevel,
                        lastUpdate: location?.timestamp ?? member.lastActive,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFamilyCode(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Family Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with family members',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final AppUser member;
  final double batteryLevel;
  final DateTime? lastUpdate;

  const _MemberCard({
    required this.member,
    required this.batteryLevel,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: member.isParent
                    ? AppTheme.primaryColor
                    : AppTheme.accentColor,
                backgroundImage: member.photoUrl != null
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? Text(
                        member.displayName.isNotEmpty
                            ? member.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: member.isOnline
                        ? AppTheme.onlineColor
                        : AppTheme.offlineColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (member.isParent
                                ? AppTheme.primaryColor
                                : AppTheme.accentColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        member.isParent ? 'Parent' : 'Child',
                        style: TextStyle(
                          color: member.isParent
                              ? AppTheme.primaryColor
                              : AppTheme.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastUpdate != null
                      ? 'Last seen: ${DateFormat('HH:mm, dd/MM').format(lastUpdate!)}'
                      : 'Never connected',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Battery
          if (member.isChild) BatteryIndicator(level: batteryLevel),
        ],
      ),
    );
  }
}
