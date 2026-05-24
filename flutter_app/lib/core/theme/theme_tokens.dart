import 'package:flutter/material.dart';

class ThemeTokens {
  const ThemeTokens._();

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 14;
  static const double radiusXl = 16;
  static const double radiusXxl = 20;
  static const double radiusFull = 99;

  static Radius circular(double r) => Radius.circular(r);
  static BorderRadius rounded(double r) => BorderRadius.circular(r);

  // ── Button Sizes ──────────────────────────────────────────────────────────
  static const double btnHeight = 50;
  static const double btnWidth = 240;
  static const double btnIconSize = 18;
  static const double btnFontSize = 14;

  // ── Card ──────────────────────────────────────────────────────────────────
  static const double cardPadding = 16;
  static const double cardRadius = 16;
  static const double cardBorderWidth = 1;

  // ── Avatar / Icon ─────────────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 36;
  static const double iconXxl = 48;
  static const double iconXxxl = 56;

  // ── Currency ──────────────────────────────────────────────────────────────
  static const double currencySize = 16;
  static const double currencyIconGap = 4;

  // ── Wheel ─────────────────────────────────────────────────────────────────
  static const double wheelMin = 200;
  static const double wheelMax = 400;
  static const double wheelBorder = 2;
  static const int spinDurationMs = 4000;

  // ── Duration ──────────────────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration xl_duration = Duration(milliseconds: 600);
  static const Duration xxl_duration = Duration(milliseconds: 800);

  // ── Elevation ─────────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationSm = 2;
  static const double elevationMd = 4;
  static const double elevationLg = 8;
  static const double elevationXl = 12;
  static const double elevationHero = 16;
}
