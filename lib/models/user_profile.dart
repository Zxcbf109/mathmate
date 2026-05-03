class UserProfile {
  String nickname;
  String avatar;
  String grade;
  String bio;

  UserProfile({
    this.nickname = 'MathMate_User',
    this.avatar = '',
    this.grade = 'Math Explorer',
    this.bio = '',
  });

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'avatar': avatar,
        'grade': grade,
        'bio': bio,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nickname: json['nickname'] as String? ?? 'MathMate_User',
        avatar: json['avatar'] as String? ?? '',
        grade: json['grade'] as String? ?? 'Math Explorer',
        bio: json['bio'] as String? ?? '',
      );

  UserProfile copyWith({
    String? nickname,
    String? avatar,
    String? grade,
    String? bio,
  }) =>
      UserProfile(
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        grade: grade ?? this.grade,
        bio: bio ?? this.bio,
      );
}
