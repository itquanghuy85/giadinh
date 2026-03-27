import 'package:cloud_firestore/cloud_firestore.dart';

enum SafeSearchLevel { strict, moderate, off }

class ContentFilterConfig {
  final String id;
  final String familyId;
  final String childId;

  // Chrome / Web filtering
  final bool chromeFilterEnabled;
  final bool blockExplicitSites;
  final List<String> blockedWebsites;
  final List<String> allowedWebsites;

  // Google Play
  final bool playStoreFilterEnabled;
  final bool requireApprovalForApps;
  final String playContentRating; // "Everyone" | "Teen" | "Mature"

  // YouTube
  final bool youtubeRestrictedMode;

  // Safe Search
  final SafeSearchLevel safeSearchLevel;

  // Approval requests
  final bool requireApprovalForWebsites;

  // Privacy & account
  final bool shareLocationWithFamily;
  final bool allowProfileEditing;
  final bool allowThirdPartyAccess;

  final DateTime updatedAt;

  ContentFilterConfig({
    required this.id,
    required this.familyId,
    required this.childId,
    this.chromeFilterEnabled = true,
    this.blockExplicitSites = true,
    this.blockedWebsites = const [],
    this.allowedWebsites = const [],
    this.playStoreFilterEnabled = true,
    this.requireApprovalForApps = true,
    this.playContentRating = 'Everyone',
    this.youtubeRestrictedMode = true,
    this.safeSearchLevel = SafeSearchLevel.strict,
    this.requireApprovalForWebsites = true,
    this.shareLocationWithFamily = true,
    this.allowProfileEditing = false,
    this.allowThirdPartyAccess = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'childId': childId,
      'chromeFilterEnabled': chromeFilterEnabled,
      'blockExplicitSites': blockExplicitSites,
      'blockedWebsites': blockedWebsites,
      'allowedWebsites': allowedWebsites,
      'playStoreFilterEnabled': playStoreFilterEnabled,
      'requireApprovalForApps': requireApprovalForApps,
      'playContentRating': playContentRating,
      'youtubeRestrictedMode': youtubeRestrictedMode,
      'safeSearchLevel': safeSearchLevel.name,
      'requireApprovalForWebsites': requireApprovalForWebsites,
      'shareLocationWithFamily': shareLocationWithFamily,
      'allowProfileEditing': allowProfileEditing,
      'allowThirdPartyAccess': allowThirdPartyAccess,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ContentFilterConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentFilterConfig(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      childId: data['childId'] ?? '',
      chromeFilterEnabled: data['chromeFilterEnabled'] ?? true,
      blockExplicitSites: data['blockExplicitSites'] ?? true,
      blockedWebsites: List<String>.from(data['blockedWebsites'] ?? []),
      allowedWebsites: List<String>.from(data['allowedWebsites'] ?? []),
      playStoreFilterEnabled: data['playStoreFilterEnabled'] ?? true,
      requireApprovalForApps: data['requireApprovalForApps'] ?? true,
      playContentRating: data['playContentRating'] ?? 'Everyone',
      youtubeRestrictedMode: data['youtubeRestrictedMode'] ?? true,
      safeSearchLevel: SafeSearchLevel.values.firstWhere(
        (e) => e.name == data['safeSearchLevel'],
        orElse: () => SafeSearchLevel.strict,
      ),
      requireApprovalForWebsites: data['requireApprovalForWebsites'] ?? true,
      shareLocationWithFamily: data['shareLocationWithFamily'] ?? true,
      allowProfileEditing: data['allowProfileEditing'] ?? false,
      allowThirdPartyAccess: data['allowThirdPartyAccess'] ?? false,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  ContentFilterConfig copyWith({
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
    return ContentFilterConfig(
      id: id,
      familyId: familyId,
      childId: childId,
      chromeFilterEnabled: chromeFilterEnabled ?? this.chromeFilterEnabled,
      blockExplicitSites: blockExplicitSites ?? this.blockExplicitSites,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
      allowedWebsites: allowedWebsites ?? this.allowedWebsites,
      playStoreFilterEnabled:
          playStoreFilterEnabled ?? this.playStoreFilterEnabled,
      requireApprovalForApps:
          requireApprovalForApps ?? this.requireApprovalForApps,
      playContentRating: playContentRating ?? this.playContentRating,
      youtubeRestrictedMode:
          youtubeRestrictedMode ?? this.youtubeRestrictedMode,
      safeSearchLevel: safeSearchLevel ?? this.safeSearchLevel,
      requireApprovalForWebsites:
          requireApprovalForWebsites ?? this.requireApprovalForWebsites,
      shareLocationWithFamily:
          shareLocationWithFamily ?? this.shareLocationWithFamily,
      allowProfileEditing: allowProfileEditing ?? this.allowProfileEditing,
      allowThirdPartyAccess:
          allowThirdPartyAccess ?? this.allowThirdPartyAccess,
      updatedAt: DateTime.now(),
    );
  }
}
