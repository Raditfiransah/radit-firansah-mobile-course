import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../local/db.dart';
import '../local/post.dart';

class PostRepository {
  PostRepository({
    Future<Database> Function()? openDb,
    Dio? dio,
  })  : _openDb = openDb ?? openNotesDb,
        _dio = dio ?? Dio();

  final Future<Database> Function() _openDb;
  final Dio _dio;

  // Baca data dari tabel cached_posts
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((row) {
      final jsonMap = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return Post.fromJson(jsonMap);
    }).toList();
  }

  // Simpan data posts ke SQLite cached_posts
  Future<void> savePostsToCache(List<Post> posts) async {
    final db = await _openDb();
    final batch = db.batch();
    for (final post in posts) {
      batch.insert(
        'cached_posts',
        {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Fetch data dari endpoint REST API JSONPlaceholder
  Future<List<Post>> fetchFromApi() async {
    final response = await _dio.get(
      'https://jsonplaceholder.typicode.com/posts?_limit=15',
    );
    if (response.statusCode == 200) {
      final List data = response.data as List;
      return data
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Gagal memuat posts dari API: ${response.statusCode}');
    }
  }
}
