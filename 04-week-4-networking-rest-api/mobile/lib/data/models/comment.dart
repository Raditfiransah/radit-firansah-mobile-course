class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Factory constructor untuk deserialisasi JSON secara null-safe dan tahan terhadap missing field.
  /// Menggunakan fallback default value agar tidak terjadi TypeError / Null check crash saat parsing.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // (json['postId'] as num?)?.toInt() menangani int, double, maupun null secara aman
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      // Fallback string kosong jika null atau missing
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Serialisasi model ke Map JSON
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
