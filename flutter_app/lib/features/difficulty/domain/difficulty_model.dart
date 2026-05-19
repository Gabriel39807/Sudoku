enum DifficultyState { unlocked, locked, hidden }

class DifficultyModel {
  final String id;
  final String name;
  final String description;
  final DifficultyState state;
  final String? unlockRequirement;

  const DifficultyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    this.unlockRequirement,
  });

  factory DifficultyModel.fromJson(Map<String, dynamic> json) {
    return DifficultyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      state: DifficultyState.values.firstWhere((e) => e.name == json['state']),
      unlockRequirement: json['unlockRequirement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'state': state.name,
      'unlockRequirement': unlockRequirement,
    };
  }

  DifficultyModel copyWith({
    String? id,
    String? name,
    String? description,
    DifficultyState? state,
    String? unlockRequirement,
  }) {
    return DifficultyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
    );
  }
}
