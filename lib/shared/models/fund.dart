class FundModel {
  const FundModel({
    required this.id,
    required this.name,
    required this.currentAmount,
    required this.targetAmount,
    this.description = '',
    this.colorHex = 'FF534AB7',
    this.createdBy = '',
  });

  final String id;
  final String name;
  final double currentAmount;
  final double targetAmount;
  final String description;
  final String colorHex;
  final String createdBy;

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
  bool get isCompleted => currentAmount >= targetAmount;

  factory FundModel.fromMap(String id, Map<String, dynamic> map) {
    return FundModel(
      id: id,
      name: map['name'] as String? ?? 'Quỹ',
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 1,
      description: map['description'] as String? ?? '',
      colorHex: map['colorHex'] as String? ?? 'FF534AB7',
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'currentAmount': currentAmount,
        'targetAmount': targetAmount,
        'description': description,
        'colorHex': colorHex,
        'createdBy': createdBy,
      };

  FundModel copyWith({
    String? name,
    double? currentAmount,
    double? targetAmount,
    String? description,
    String? colorHex,
  }) {
    return FundModel(
      id: id,
      name: name ?? this.name,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdBy: createdBy,
    );
  }
}
