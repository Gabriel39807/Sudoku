import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/wallet.dart';

class WalletStorage {
  static const _key = 'economy_wallet';

  static Future<Wallet> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const Wallet();
    return Wallet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(Wallet wallet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(wallet.toJson()));
  }
}
