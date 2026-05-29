import 'hint_type.dart';
import 'hint_priority.dart';

class SmartHintConfig {
  final HintType type;
  final HintPriority priority;
  final bool repeatable;
  final int cooldownHours;
  final List<String> targetKey;
  final String message;

  const SmartHintConfig({
    required this.type,
    required this.priority,
    this.repeatable = false,
    this.cooldownHours = 0,
    required this.targetKey,
    required this.message,
  });

  static const all = [
    SmartHintConfig(
      type: HintType.erase,
      priority: HintPriority.high,
      targetKey: ['erase_button'],
      message: 'Toca aquí para borrar números o notas incorrectas',
    ),
    SmartHintConfig(
      type: HintType.notes,
      priority: HintPriority.normal,
      targetKey: ['notes_button'],
      message: 'Usa notas para probar posibilidades en celdas difíciles',
    ),
    SmartHintConfig(
      type: HintType.tabMode,
      priority: HintPriority.normal,
      targetKey: ['tab_mode_button'],
      message: 'Tab Mode cambia automáticamente al siguiente número disponible',
    ),
    SmartHintConfig(
      type: HintType.advancedNotes,
      priority: HintPriority.low,
      targetKey: ['adv_notes_button'],
      message: 'Mantén presionado o activa notas avanzadas para partidas difíciles',
    ),
  ];
}