import 'package:flutter/material.dart';

class WalletModel {
  const WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorHex,
    required this.ownerUid,
  });

  final String id;
  final String name;
  final double balance;
  final String colorHex;
  final String ownerUid;

  Color get dotColor => Color(int.parse(colorHex, radix: 16));

  factory WalletModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletModel(
      id: id,
      name: map['name'] as String? ?? 'Ví',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      colorHex: map['colorHex'] as String? ?? 'FF534AB7',
      ownerUid: map['ownerUid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'balance': balance,
        'colorHex': colorHex,
        'ownerUid': ownerUid,
      };
}
