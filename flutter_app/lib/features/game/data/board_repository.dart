import 'dart:convert';
import 'package:flutter/services.dart';

class BoardRepository {
  static Future<List<String>> getAvailableBoards(String difficulty) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    
    final path = 'assets/boards/${difficulty.toLowerCase()}/';
    return manifestMap.keys.where((String key) => key.startsWith(path)).toList();
  }

  static Future<Map<String, dynamic>> loadBoard(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return json.decode(jsonString);
  }
}
