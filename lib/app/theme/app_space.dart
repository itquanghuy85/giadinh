import 'package:flutter/widgets.dart';

class AppSpace {
  const AppSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets tile = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
}
