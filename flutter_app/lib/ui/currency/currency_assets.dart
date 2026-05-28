import 'package:flutter/material.dart';
import 'currency_type.dart';

class CurrencyAssets {
  CurrencyAssets._();

  static const _gemsIcon = Icons.diamond;
  static const _gemsColor = Color(0xFFE91E63);
  static const _tokensIcon = Icons.water_drop;
  static const _tokensColor = Color(0xFF3498DB);

  static IconData iconFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.gems => _gemsIcon,
      CurrencyType.tokens => _tokensIcon,
    };
  }

  static Color colorFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.gems => _gemsColor,
      CurrencyType.tokens => _tokensColor,
    };
  }

  static String labelFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.gems => 'GEMS',
      CurrencyType.tokens => 'TOKENS',
    };
  }

  static String emojiFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.gems => '\u{1F48E}',
      CurrencyType.tokens => '\u{1F537}',
    };
  }
}
