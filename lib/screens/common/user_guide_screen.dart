import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;

    final sections = [
      _GuideSection(
        icon: Icons.rocket_launch,
        color: AppTheme.primaryColor,
        title: t('guide_getting_started_title'),
        steps: [
          t('guide_getting_started_1'),
          t('guide_getting_started_2'),
          t('guide_getting_started_3_parent'),
          t('guide_getting_started_4_parent'),
          t('guide_getting_started_3_child'),
          t('guide_getting_started_4_child'),
        ],
      ),
      _GuideSection(
        icon: Icons.map,
        color: const Color(0xFF4CAF50),
        title: t('guide_realtime_map_title'),
        steps: [
          t('guide_realtime_map_1'),
          t('guide_realtime_map_2'),
          t('guide_realtime_map_3'),
        ],
      ),
      _GuideSection(
        icon: Icons.people,
        color: const Color(0xFF2196F3),
        title: t('guide_members_title'),
        steps: [
          t('guide_members_1'),
          t('guide_members_2'),
          t('guide_members_3'),
        ],
      ),
      _GuideSection(
        icon: Icons.shield,
        color: AppTheme.accentColor,
        title: t('guide_safe_zones_title'),
        steps: [
          t('guide_safe_zones_1'),
          t('guide_safe_zones_2'),
          t('guide_safe_zones_3'),
          t('guide_safe_zones_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.errorColor,
        title: t('guide_danger_zones_title'),
        steps: [
          t('guide_danger_zones_1'),
          t('guide_danger_zones_2'),
          t('guide_danger_zones_3'),
          t('guide_danger_zones_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.assessment,
        color: const Color(0xFF9C27B0),
        title: t('guide_daily_report_title'),
        steps: [
          t('guide_daily_report_1'),
          t('guide_daily_report_2'),
          t('guide_daily_report_3'),
          t('guide_daily_report_4'),
          t('guide_daily_report_5'),
        ],
      ),
      _GuideSection(
        icon: Icons.timeline,
        color: const Color(0xFF009688),
        title: t('guide_timeline_title'),
        steps: [
          t('guide_timeline_1'),
          t('guide_timeline_2'),
          t('guide_timeline_3'),
          t('guide_timeline_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.battery_alert,
        color: AppTheme.warningColor,
        title: t('guide_battery_alerts_title'),
        steps: [
          t('guide_battery_alerts_1'),
          t('guide_battery_alerts_2'),
          t('guide_battery_alerts_3'),
        ],
      ),
      _GuideSection(
        icon: Icons.schedule,
        color: const Color(0xFF3F51B5),
        title: t('guide_schedule_title'),
        steps: [
          t('guide_schedule_1'),
          t('guide_schedule_2'),
          t('guide_schedule_3'),
          t('guide_schedule_4'),
          t('guide_schedule_5'),
        ],
      ),
      _GuideSection(
        icon: Icons.location_on,
        color: const Color(0xFF00BCD4),
        title: t('guide_auto_checkin_title'),
        steps: [
          t('guide_auto_checkin_1'),
          t('guide_auto_checkin_2'),
          t('guide_auto_checkin_3'),
        ],
      ),
      _GuideSection(
        icon: Icons.sos,
        color: AppTheme.sosColor,
        title: t('guide_sos_title'),
        steps: [
          t('guide_sos_1'),
          t('guide_sos_2'),
          t('guide_sos_3'),
          t('guide_sos_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.share_location,
        color: const Color(0xFF8BC34A),
        title: t('guide_location_sharing_title'),
        steps: [
          t('guide_location_sharing_1'),
          t('guide_location_sharing_2'),
          t('guide_location_sharing_3'),
          t('guide_location_sharing_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.language,
        color: const Color(0xFF607D8B),
        title: t('guide_language_title'),
        steps: [
          t('guide_language_1'),
          t('guide_language_2'),
          t('guide_language_3'),
        ],
      ),
      _GuideSection(
        icon: Icons.gps_off,
        color: const Color(0xFFE91E63),
        title: t('guide_gps_detection_title'),
        steps: [
          t('guide_gps_detection_1'),
          t('guide_gps_detection_2'),
          t('guide_gps_detection_3'),
          t('guide_gps_detection_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.sim_card,
        color: const Color(0xFFFF9800),
        title: t('guide_sim_detection_title'),
        steps: [
          t('guide_sim_detection_1'),
          t('guide_sim_detection_2'),
          t('guide_sim_detection_3'),
          t('guide_sim_detection_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.signal_wifi_off,
        color: const Color(0xFF795548),
        title: t('guide_disconnection_title'),
        steps: [
          t('guide_disconnection_1'),
          t('guide_disconnection_2'),
          t('guide_disconnection_3'),
          t('guide_disconnection_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.pie_chart,
        color: const Color(0xFF673AB7),
        title: t('guide_area_time_title'),
        steps: [
          t('guide_area_time_1'),
          t('guide_area_time_2'),
          t('guide_area_time_3'),
          t('guide_area_time_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.nightlight_round,
        color: const Color(0xFF1A237E),
        title: t('guide_night_alert_title'),
        steps: [
          t('guide_night_alert_1'),
          t('guide_night_alert_2'),
          t('guide_night_alert_3'),
          t('guide_night_alert_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.calendar_month,
        color: const Color(0xFF00ACC1),
        title: t('guide_calendar_title'),
        steps: [
          t('guide_calendar_1'),
          t('guide_calendar_2'),
          t('guide_calendar_3'),
          t('guide_calendar_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.home,
        color: const Color(0xFF43A047),
        title: t('guide_near_home_title'),
        steps: [
          t('guide_near_home_1'),
          t('guide_near_home_2'),
          t('guide_near_home_3'),
          t('guide_near_home_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.picture_as_pdf,
        color: const Color(0xFFD32F2F),
        title: t('guide_pdf_title'),
        steps: [
          t('guide_pdf_1'),
          t('guide_pdf_2'),
          t('guide_pdf_3'),
          t('guide_pdf_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.widgets,
        color: const Color(0xFF546E7A),
        title: t('guide_widget_title'),
        steps: [
          t('guide_widget_1'),
          t('guide_widget_2'),
          t('guide_widget_3'),
          t('guide_widget_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.timer,
        color: const Color(0xFFE65100),
        title: t('guide_screen_time_title'),
        steps: [
          t('guide_screen_time_1'),
          t('guide_screen_time_2'),
          t('guide_screen_time_3'),
          t('guide_screen_time_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.apps_rounded,
        color: const Color(0xFF7B1FA2),
        title: t('guide_app_management_title'),
        steps: [
          t('guide_app_management_1'),
          t('guide_app_management_2'),
          t('guide_app_management_3'),
          t('guide_app_management_4'),
        ],
      ),
      _GuideSection(
        icon: Icons.shield_rounded,
        color: const Color(0xFF1565C0),
        title: t('guide_content_filter_title'),
        steps: [
          t('guide_content_filter_1'),
          t('guide_content_filter_2'),
          t('guide_content_filter_3'),
          t('guide_content_filter_4'),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('user_guide')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  t('user_guide'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('user_guide_subtitle'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Guide sections
          ...sections.map((section) => _GuideSectionCard(section: section)),

          // Tips section
          const SizedBox(height: 8),
          _TipsCard(t: t),
        ],
      ),
    );
  }
}

class _GuideSection {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> steps;

  const _GuideSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.steps,
  });
}

class _GuideSectionCard extends StatefulWidget {
  final _GuideSection section;

  const _GuideSectionCard({required this.section});

  @override
  State<_GuideSectionCard> createState() => _GuideSectionCardState();
}

class _GuideSectionCardState extends State<_GuideSectionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.icon, color: s.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content - expandable
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: AppTheme.dividerColor,
                  ),
                  const SizedBox(height: 12),
                  ...s.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: s.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: s.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final String Function(String, [List<String>?]) t;

  const _TipsCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final tips = [
      t('guide_tip_1'),
      t('guide_tip_2'),
      t('guide_tip_3'),
      t('guide_tip_4'),
      t('guide_tip_5'),
      t('guide_tip_6'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb,
                  color: AppTheme.warningColor, size: 22),
              const SizedBox(width: 10),
              Text(
                t('guide_tips_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
