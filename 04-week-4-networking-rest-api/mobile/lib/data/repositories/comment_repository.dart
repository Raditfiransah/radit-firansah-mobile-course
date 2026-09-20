import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository untuk mengelola pengambilan data komentar dari API JSONPlaceholder.
class CommentRepository {
  /// Menerima instance Dio yang telah dikonfigurasi secara terpusat (BaseUrl, Interceptors, Timeouts).
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil daftar komentar berdasarkan [postId].
  /// Endpoint: GET /comments?postId={id}
  /// Konfigurasi timeout spesifik (10 detik) dapat diberikan via [Options] atau mewarisi BaseOptions Dio.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
