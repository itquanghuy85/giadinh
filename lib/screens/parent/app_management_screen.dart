import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_management_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/firestore_service.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedChildId;
  AppManagementConfig? _config;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final children = context.watch<FamilyProvider>().children;
    final familyId = context.read<AuthProvider>().currentUser?.familyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('app_management'))),
      floatingActionButton: _selectedChildId != null
          ? FloatingActionButton(
              onPressed: () => _showAddAppDialog(context),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  const Icon(Icons.apps_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(t('app_management'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(t('app_management_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Child selector
            Text(t('select_child'),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: children.map((child) {
                final selected = _selectedChildId == child.uid;
                return ChoiceChip(
                  label: Text(child.displayName),
                  selected: selected,
                  selectedColor: const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                  onSelected: (_) {
                    setState(() => _selectedChildId = child.uid);
                    _loadConfig(familyId, child.uid);
                  },
                );
              }).toList(),
            ),

            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
            ],

            if (_selectedChildId != null && !_loading) ...[
              const SizedBox(height: 20),

              // Block new installs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.cardShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: SwitchListTile(
                  title: Text(t('block_new_installs'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t('block_new_installs_desc')),
                  secondary: const Icon(Icons.block, color: AppTheme.errorColor),
                  value: _config?.blockNewInstalls ?? false,
                  activeColor: AppTheme.errorColor,
                  onChanged: (v) {
                    final updated = _config?.copyWith(blockNewInstalls: v);
                    if (updated != null) {
                      setState(() => _config = updated);
                      _firestore.saveAppManagementConfig(updated);
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Managed apps list
              if ((_config?.managedApps ?? []).isNotEmpty) ...[
                // Priority apps
                _buildAppSection(
                  t('priority_apps'),
                  Icons.star,
                  const Color(0xFFFFA000),
                  _config!.managedApps.where((a) => a.isPriority).toList(),
                ),
                const SizedBox(height: 12),

                // Blocked apps
                _buildAppSection(
                  t('blocked_apps'),
                  Icons.block,
                  AppTheme.errorColor,
                  _config!.managedApps.where((a) => a.blocked).toList(),
                ),
                const SizedBox(height: 12),

                // Limited apps
                _buildAppSection(
                  t('limited_apps'),
                  Icons.timer,
                  const Color(0xFF2196F3),
                  _config!.managedApps
                      .where((a) =>
                          !a.blocked &&
                          !a.isPriority &&
                          a.dailyLimitMinutes != null)
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Other apps
                _buildAppSection(
                  t('other_apps'),
                  Icons.apps,
                  AppTheme.textSecondary,
                  _config!.managedApps
                      .where((a) =>
                          !a.blocked &&
                          !a.isPriority &&
                          a.dailyLimitMinutes == null)
                      .toList(),
                ),
              ] else ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.apps_outlined,
                          size: 60,
                          color: AppTheme.textHint.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(t('no_managed_apps'),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(t('tap_add_app'),
                          style: const TextStyle(
                              color: AppTheme.textHint, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppSection(
      String title, IconData icon, Color color, List<ManagedApp> apps) {
    final t = AppLocalizations.of(context).t;
    if (apps.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${apps.length}',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...apps.map((app) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _categoryColor(app.category),
                  radius: 20,
                  child: Text(app.appName.isNotEmpty ? app.appName[0] : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                title: Text(app.appName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  app.blocked
                      ? t('status_blocked')
                      : app.dailyLimitMinutes != null
                          ? '${t('limit')}: ${app.dailyLimitMinutes} ${t('min_short')}'
                          : app.isPriority
                              ? t('educational_priority')
                              : t('allowed'),
                  style: TextStyle(
                      color: app.blocked ? AppTheme.errorColor : null,
                      fontSize: 12),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _onAppAction(app, action),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'block',
                        child: Text(
                            app.blocked ? t('unblock') : t('block_app'))),
                    PopupMenuItem(
                        value: 'priority',
                        child: Text(app.isPriority
                            ? t('remove_priority')
                            : t('mark_priority'))),
                    PopupMenuItem(
                        value: 'limit', child: Text(t('set_limit'))),
                    PopupMenuItem(
                        value: 'remove',
                        child: Text(t('delete'),
                            style:
                                const TextStyle(color: AppTheme.errorColor))),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  void _onAppAction(ManagedApp app, String action) {
    if (_config == null) return;
    final apps = List<ManagedApp>.from(_config!.managedApps);
    final idx = apps.indexWhere((a) => a.packageName == app.packageName);
    if (idx == -1) return;

    switch (action) {
      case 'block':
        apps[idx] = app.copyWith(blocked: !app.blocked);
        break;
      case 'priority':
        apps[idx] = app.copyWith(isPriority: !app.isPriority, blocked: false);
        break;
      case 'limit':
        _showLimitDialog(app);
        return;
      case 'remove':
        apps.removeAt(idx);
        break;
    }

    final updated = _config!.copyWith(managedApps: apps);
    setState(() => _config = updated);
    _firestore.saveAppManagementConfig(updated);
  }

  void _showLimitDialog(ManagedApp app) {
    final t = AppLocalizations.of(context).t;
    int limit = app.dailyLimitMinutes ?? 60;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('${t('set_limit')}: ${app.appName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$limit ${t('minutes')}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700)),
                Slider(
                  value: limit.toDouble(),
                  min: 5,
                  max: 300,
                  divisions: 59,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) =>
                      setDialogState(() => limit = v.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear limit
                  _updateAppLimit(app, null);
                  Navigator.pop(ctx);
                },
                child: Text(t('no_limit')),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateAppLimit(app, limit);
                  Navigator.pop(ctx);
                },
                child: Text(t('save')),
              ),
            ],
          );
        });
      },
    );
  }

  void _updateAppLimit(ManagedApp app, int? limit) {
    if (_config == null) return;
    final apps = List<ManagedApp>.from(_config!.managedApps);
    final idx = apps.indexWhere((a) => a.packageName == app.packageName);
    if (idx == -1) return;

    apps[idx] = limit != null
        ? app.copyWith(dailyLimitMinutes: limit)
        : app.copyWith(clearLimit: true);

    final updated = _config!.copyWith(managedApps: apps);
    setState(() => _config = updated);
    _firestore.saveAppManagementConfig(updated);
  }

  void _showAddAppDialog(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final nameController = TextEditingController();
    final packageController = TextEditingController();
    AppCategory selectedCat = AppCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('add_app'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: t('app_name_hint'),
                    prefixIcon: const Icon(Icons.apps),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: packageController,
                  decoration: InputDecoration(
                    hintText: t('package_name_hint'),
                    prefixIcon: const Icon(Icons.code),
                  ),
                ),
                const SizedBox(height: 12),
                Text(t('category'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: AppCategory.values.map((cat) {
                    return ChoiceChip(
                      label: Text(_categoryLabel(cat, t)),
                      selected: selectedCat == cat,
                      onSelected: (_) =>
                          setSheetState(() => selectedCat = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: nameController.text.isEmpty
                        ? null
                        : () {
                            _addApp(ManagedApp(
                              packageName: packageController.text.isNotEmpty
                                  ? packageController.text.trim()
                                  : 'com.app.${nameController.text.trim().toLowerCase().replaceAll(' ', '_')}',
                              appName: nameController.text.trim(),
                              category: selectedCat,
                              isPriority:
                                  selectedCat == AppCategory.education,
                            ));
                            Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(t('add_app')),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _addApp(ManagedApp app) {
    if (_config == null) return;
    final apps = List<ManagedApp>.from(_config!.managedApps)..add(app);
    final updated = _config!.copyWith(managedApps: apps);
    setState(() => _config = updated);
    _firestore.saveAppManagementConfig(updated);
  }

  void _loadConfig(String familyId, String childId) {
    setState(() => _loading = true);
    _firestore.appManagementConfigStream(childId).first.then((config) {
      if (mounted) {
        setState(() {
          _config = config ??
              AppManagementConfig(
                id: const Uuid().v4(),
                familyId: familyId,
                childId: childId,
              );
          _loading = false;
        });
      }
    });
  }

  Color _categoryColor(AppCategory cat) {
    switch (cat) {
      case AppCategory.education:
        return const Color(0xFF4CAF50);
      case AppCategory.social:
        return const Color(0xFF2196F3);
      case AppCategory.entertainment:
        return const Color(0xFFFF9800);
      case AppCategory.games:
        return const Color(0xFFE91E63);
      case AppCategory.tools:
        return const Color(0xFF607D8B);
      case AppCategory.other:
        return const Color(0xFF9E9E9E);
    }
  }

  String _categoryLabel(AppCategory cat, String Function(String) t) {
    switch (cat) {
      case AppCategory.education:
        return t('cat_education');
      case AppCategory.social:
        return t('cat_social');
      case AppCategory.entertainment:
        return t('cat_entertainment');
      case AppCategory.games:
        return t('cat_games');
      case AppCategory.tools:
        return t('cat_tools');
      case AppCategory.other:
        return t('cat_other');
    }
  }
}
