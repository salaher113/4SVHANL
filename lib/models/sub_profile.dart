class SubProfile {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  SubProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  factory SubProfile.fromJson(Map<String, dynamic> json) {
    return SubProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SubProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return SubProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
