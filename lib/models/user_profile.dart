class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String bio;
  final String favoriteGenre;
  final int totalListeningSeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio = 'Music lover on Harmoniq',
    this.favoriteGenre = 'All Genres',
    this.totalListeningSeconds = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get handle => username.startsWith('@') ? username : '@$username';

  String get effectiveName =>
      displayName.trim().isNotEmpty ? displayName : username;

  String get formattedListeningTime {
    if (totalListeningSeconds < 60) {
      return '$totalListeningSeconds sec';
    }
    final minutes = totalListeningSeconds ~/ 60;
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final remMins = minutes % 60;
    if (remMins == 0) return '${hours}h';
    return '${hours}h ${remMins}m';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'user',
      displayName: json['display_name'] as String? ??
          json['username'] as String? ??
          'Harmoniq User',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? 'Music lover on Harmoniq',
      favoriteGenre: json['favorite_genre'] as String? ?? 'All Genres',
      totalListeningSeconds: (json['total_listening_seconds'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'bio': bio,
      'favorite_genre': favoriteGenre,
      'total_listening_seconds': totalListeningSeconds,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? favoriteGenre,
    int? totalListeningSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      totalListeningSeconds:
          totalListeningSeconds ?? this.totalListeningSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
