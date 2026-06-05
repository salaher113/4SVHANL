class FavoriteItem {
  final String id;
  final String subProfileId;
  final String itemId;
  final String itemType;
  final String title;
  final String? posterPath;
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.subProfileId,
    required this.itemId,
    required this.itemType,
    required this.title,
    this.posterPath,
    required this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      subProfileId: json['sub_profile_id'] as String,
      itemId: json['item_id'] as String,
      itemType: json['item_type'] as String,
      title: json['title'] as String,
      posterPath: json['poster_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_profile_id': subProfileId,
      'item_id': itemId,
      'item_type': itemType,
      'title': title,
      'poster_path': posterPath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
