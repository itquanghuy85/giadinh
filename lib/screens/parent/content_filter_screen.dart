import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_filter_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/firestore_service.dart';

class ContentFilterScreen extends StatefulWidget {
  const ContentFilterScreen({super.key});

  @override
  State<ContentFilterScreen> createState() => _ContentFilterScreenState();
}

class _ContentFilterScreenState extends State<ContentFilterScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedChildId;
  ContentFilterConfig? _config;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final children = context.watch<FamilyProvider>().children;
    final familyId = context.read<AuthProvider>().currentUser?.familyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('content_filter'))),
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
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(t('content_filter'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(t('content_filter_desc'),
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
                  selectedColor:
                      const Color(0xFF1565C0).withValues(alpha: 0.15),
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

              // ── Chrome / Web ──
              _SectionCard(
                icon: Icons.language,
                color: const Color(0xFF4CAF50),
                title: t('chrome_web_filter'),
                children: [
                  SwitchListTile(
                    title: Text(t('enable_chrome_filter')),
                    subtitle: Text(t('enable_chrome_filter_desc')),
                    value: _config?.chromeFilterEnabled ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _update(chromeFilterEnabled: v),
                  ),
                  SwitchListTile(
                    title: Text(t('block_explicit_sites')),
                    value: _config?.blockExplicitSites ?? true,
                    activeColor: AppTheme.errorColor,
                    onChanged: (v) => _update(blockExplicitSites: v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block, color: AppTheme.errorColor),
                    title: Text(t('blocked_websites')),
                    subtitle: Text(
                        '${(_config?.blockedWebsites ?? []).length} ${t('sites')}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWebsiteListDialog(true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.check_circle,
                        color: Color(0xFF4CAF50)),
                    title: Text(t('allowed_websites')),
                    subtitle: Text(
                        '${(_config?.allowedWebsites ?? []).length} ${t('sites')}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWebsiteListDialog(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Google Play Store ──
              _SectionCard(
                icon: Icons.store,
                color: const Color(0xFF2196F3),
                title: t('play_store_filter'),
                children: [
                  SwitchListTile(
                    title: Text(t('enable_play_filter')),
                    subtitle: Text(t('enable_play_filter_desc')),
                    value: _config?.playStoreFilterEnabled ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _update(playStoreFilterEnabled: v),
                  ),
                  SwitchListTile(
                    title: Text(t('require_approval_apps')),
                    subtitle: Text(t('require_approval_apps_desc')),
                    value: _config?.requireApprovalForApps ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _update(requireApprovalForApps: v),
                  ),
                  ListTile(
                    leading: const Icon(Icons.child_care,
                        color: Color(0xFFFF9800)),
                    title: Text(t('content_rating')),
                    subtitle: Text(_config?.playContentRating ?? 'PG-13'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showRatingPicker,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── YouTube ──
              _SectionCard(
                icon: Icons.play_circle_fill,
                color: const Color(0xFFFF0000),
                title: 'YouTube',
                children: [
                  SwitchListTile(
                    title: Text(t('youtube_restricted')),
                    subtitle: Text(t('youtube_restricted_desc')),
                    value: _config?.youtubeRestrictedMode ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _update(youtubeRestrictedMode: v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Safe Search ──
              _SectionCard(
                icon: Icons.search,
                color: const Color(0xFF9C27B0),
                title: t('safe_search'),
                children: [
                  ...SafeSearchLevel.values.map((level) {
                    return RadioListTile<SafeSearchLevel>(
                      title: Text(_safeSearchLabel(level, t)),
                      subtitle: Text(_safeSearchDesc(level, t)),
                      value: level,
                      groupValue:
                          _config?.safeSearchLevel ?? SafeSearchLevel.moderate,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) {
                        if (v != null) _update(safeSearchLevel: v);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),

              // ── Approval ──
              _SectionCard(
                icon: Icons.approval,
                color: const Color(0xFFFF9800),
                title: t('approval_settings'),
                children: [
                  SwitchListTile(
                    title: Text(t('require_approval_websites')),
                    subtitle: Text(t('require_approval_websites_desc')),
                    value: _config?.requireApprovalForWebsites ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) =>
                        _update(requireApprovalForWebsites: v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Privacy ──
              _SectionCard(
                icon: Icons.privacy_tip,
                color: const Color(0xFF607D8B),
                title: t('privacy_settings'),
                children: [
                  SwitchListTile(
                    title: Text(t('share_location_family')),
                    subtitle: Text(t('share_location_family_desc')),
                    value: _config?.shareLocationWithFamily ?? true,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) =>
                        _update(shareLocationWithFamily: v),
                  ),
                  SwitchListTile(
                    title: Text(t('allow_profile_edit')),
                    subtitle: Text(t('allow_profile_edit_desc')),
                    value: _config?.allowProfileEditing ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _update(allowProfileEditing: v),
                  ),
                  SwitchListTile(
                    title: Text(t('allow_third_party')),
                    subtitle: Text(t('allow_third_party_desc')),
                    value: _config?.allowThirdPartyAccess ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _update(allowThirdPartyAccess: v),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- helpers ----

  void _update({
    bool? chromeFilterEnabled,
    bool? blockExplicitSites,
    List<String>? blockedWebsites,
    List<String>? allowedWebsites,
    bool? playStoreFilterEnabled,
    bool? requireApprovalForApps,
    String? playContentRating,
    bool? youtubeRestrictedMode,
    SafeSearchLevel? safeSearchLevel,
    bool? requireApprovalForWebsites,
    bool? shareLocationWithFamily,
    bool? allowProfileEditing,
    bool? allowThirdPartyAccess,
  }) {
    if (_config == null) return;
    final updated = _config!.copyWith(
      chromeFilterEnabled: chromeFilterEnabled,
      blockExplicitSites: blockExplicitSites,
      blockedWebsites: blockedWebsites,
      allowedWebsites: allowedWebsites,
      playStoreFilterEnabled: playStoreFilterEnabled,
      requireApprovalForApps: requireApprovalForApps,
      playContentRating: playContentRating,
      youtubeRestrictedMode: youtubeRestrictedMode,
      safeSearchLevel: safeSearchLevel,
      requireApprovalForWebsites: requireApprovalForWebsites,
      shareLocationWithFamily: shareLocationWithFamily,
      allowProfileEditing: allowProfileEditing,
      allowThirdPartyAccess: allowThirdPartyAccess,
    );
    setState(() => _config = updated);
    _firestore.saveContentFilterConfig(updated);
  }

  void _loadConfig(String familyId, String childId) {
    setState(() => _loading = true);
    _firestore.contentFilterConfigStream(childId).first.then((config) {
      if (mounted) {
        setState(() {
          _config = config ??
              ContentFilterConfig(
                id: const Uuid().v4(),
                familyId: familyId,
                childId: childId,
              );
          _loading = false;
        });
      }
    });
  }

  void _showWebsiteListDialog(bool isBlocked) {
    final t = AppLocalizations.of(context).t;
    final sites = List<String>.from(
        isBlocked ? (_config?.blockedWebsites ?? []) : (_config?.allowedWebsites ?? []));
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBlocked ? t('blocked_websites') : t('allowed_websites'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: t('enter_website_url'),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: AppTheme.primaryColor),
                      onPressed: () {
                        final url = controller.text.trim();
                        if (url.isNotEmpty && !sites.contains(url)) {
                          setSheetState(() => sites.add(url));
                          controller.clear();
                          if (isBlocked) {
                            _update(blockedWebsites: sites);
                          } else {
                            _update(allowedWebsites: sites);
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sites.isEmpty
                      ? Center(
                          child: Text(t('no_websites'),
                              style: const TextStyle(
                                  color: AppTheme.textHint)))
                      : ListView.builder(
                          itemCount: sites.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.language, size: 18),
                            title: Text(sites[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppTheme.errorColor),
                              onPressed: () {
                                setSheetState(() => sites.removeAt(i));
                                if (isBlocked) {
                                  _update(blockedWebsites: sites);
                                } else {
                                  _update(allowedWebsites: sites);
                                }
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showRatingPicker() {
    final t = AppLocalizations.of(context).t;
    final ratings = ['G', 'PG', 'PG-13', 'R', 'NC-17'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t('select_content_rating')),
        children: ratings
            .map((r) => SimpleDialogOption(
                  onPressed: () {
                    _update(playContentRating: r);
                    Navigator.pop(ctx);
                  },
                  child: Row(
                    children: [
                      Icon(
                          r == (_config?.playContentRating ?? 'PG-13')
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: AppTheme.primaryColor,
                          size: 20),
                      const SizedBox(width: 12),
                      Text(r,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _safeSearchLabel(SafeSearchLevel level, String Function(String) t) {
    switch (level) {
      case SafeSearchLevel.strict:
        return t('safe_search_strict');
      case SafeSearchLevel.moderate:
        return t('safe_search_moderate');
      case SafeSearchLevel.off:
        return t('safe_search_off');
    }
  }

  String _safeSearchDesc(SafeSearchLevel level, String Function(String) t) {
    switch (level) {
      case SafeSearchLevel.strict:
        return t('safe_search_strict_desc');
      case SafeSearchLevel.moderate:
        return t('safe_search_moderate_desc');
      case SafeSearchLevel.off:
        return t('safe_search_off_desc');
    }
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: color)),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
