import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._openDb, {Dio? dio}) : _dio = dio ?? Dio();

  final Future<Database> Function() _openDb;
  final Dio _dio;

  @override
  Future<({List<Post> posts, Failure? failure})> readCachedPosts() async {
    try {
      final db = await _openDb();
      final rows = await db.query('cached_posts', orderBy: 'id ASC');
      final posts = rows.map((row) {
        final jsonMap =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        return PostModel.fromJson(jsonMap).toEntity();
      }).toList();
      return (posts: posts, failure: null);
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: LocalFailure('Gagal membaca cache posts: $e'),
      );
    }
  }

  @override
  Future<Failure?> savePostsToCache(List<Post> posts) async {
    try {
      final db = await _openDb();
      final batch = db.batch();
      for (final post in posts) {
        batch.insert(
          'cached_posts',
          {
            'id': post.id,
            'payload': jsonEncode(
              PostModel(
                id: post.id,
                userId: post.userId,
                title: post.title,
                body: post.body,
              ).toJson(),
            ),
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return null;
    } catch (e) {
      return LocalFailure('Gagal menyimpan cache posts: $e');
    }
  }

  @override
  Future<({List<Post> posts, Failure? failure})> fetchFromApi() async {
    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts?_limit=15',
      );
      if (response.statusCode == 200) {
        final data = response.data as List;
        final posts = data
            .map((item) =>
                PostModel.fromJson(item as Map<String, dynamic>).toEntity())
            .toList();
        return (posts: posts, failure: null);
      }
      return (
        posts: const <Post>[],
        failure: NetworkFailure(
          'Gagal memuat posts dari API: ${response.statusCode}',
        ),
      );
    } catch (e) {
      return (
        posts: const <Post>[],
        failure: NetworkFailure('Gagal memuat posts dari API: $e'),
      );
    }
  }
}
