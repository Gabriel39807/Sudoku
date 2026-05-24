enum DifficultyState { unlocked, locked, hidden }

class DifficultyModel {
  final String id;
  final String name;
  final String description;
  final DifficultyState state;
  final String? unlockRequirement;
  final String subtitle;
  final int completedCount;
  final int totalCount;

  const DifficultyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    this.unlockRequirement,
    this.subtitle = '',
    this.completedCount = 0,
    this.totalCount = 0,
  });

  factory DifficultyModel.fromJson(Map<String, dynamic> json) {
    return DifficultyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      state: DifficultyState.values.firstWhere((e) => e.name == json['state']),
      unlockRequirement: json['unlockRequirement'] as String?,
      subtitle: json['subtitle'] as String? ?? '',
      completedCount: json['completedCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'state': state.name,
      'unlockRequirement': unlockRequirement,
      'subtitle': subtitle,
      'completedCount': completedCount,
      'totalCount': totalCount,
    };
  }

  DifficultyModel copyWith({
    String? id,
    String? name,
    String? description,
    DifficultyState? state,
    String? unlockRequirement,
    String? subtitle,
    int? completedCount,
    int? totalCount,
  }) {
    return DifficultyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      subtitle: subtitle ?? this.subtitle,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
