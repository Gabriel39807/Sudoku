import 'package:flutter/material.dart';
import 'currency_type.dart';

class CurrencyAssets {
  CurrencyAssets._();

  static const _soulsIcon = Icons.diamond;
  static const _soulsColor = Color(0xFF9B59B6);
  static const _tokensIcon = Icons.water_drop;
  static const _tokensColor = Color(0xFF3498DB);

  static IconData iconFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.souls => _soulsIcon,
      CurrencyType.tokens => _tokensIcon,
    };
  }

  static Color colorFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.souls => _soulsColor,
      CurrencyType.tokens => _tokensColor,
    };
  }

  static String labelFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.souls => 'SOULS',
      CurrencyType.tokens => 'TOKENS',
    };
  }

  static String emojiFor(CurrencyType type) {
    return switch (type) {
      CurrencyType.souls => '\u{1F48E}',
      CurrencyType.tokens => '\u{1F537}',
    };
  }
}
