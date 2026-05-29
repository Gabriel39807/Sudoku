import 'package:flutter/material.dart';

class HintTargetKeys {
  final erase = GlobalKey();
  final notes = GlobalKey();
  final advNotes = GlobalKey();

  Map<String, GlobalKey> get asMap => {
    'erase_button': erase,
    'notes_button': notes,
    'adv_notes_button': advNotes,
  };
}