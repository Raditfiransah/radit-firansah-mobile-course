import '../../domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    super.userId = 1,
    required super.title,
    required super.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };

  Post toEntity() => Post(id: id, userId: userId, title: title, body: body);
}
