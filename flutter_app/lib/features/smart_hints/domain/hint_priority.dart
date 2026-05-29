enum HintPriority { high, normal, low }

extension HintPriorityCompare on HintPriority {
  bool get isCritical => this == HintPriority.high;
  int get rank {
    switch (this) {
      case HintPriority.high:
        return 3;
      case HintPriority.normal:
        return 2;
      case HintPriority.low:
        return 1;
    }
  }
}