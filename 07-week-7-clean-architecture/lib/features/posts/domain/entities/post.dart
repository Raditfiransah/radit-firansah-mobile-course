class Post {
  const Post({
    required this.id,
    this.userId = 1,
    required this.title,
    required this.body,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
}
