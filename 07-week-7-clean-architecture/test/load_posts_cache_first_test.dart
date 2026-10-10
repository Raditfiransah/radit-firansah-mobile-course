import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/posts/domain/entities/post.dart';
import 'package:week5_offline_notes/features/posts/domain/repositories/post_repository.dart';
import 'package:week5_offline_notes/features/posts/domain/usecases/load_posts_cache_first.dart';

class FakePostRepository implements PostRepository {
  FakePostRepository({
    this.cached = const [],
    this.cachedFailure,
    this.api = const [],
    this.apiFailure,
  });

  final List<Post> cached;
  final Failure? cachedFailure;
  final List<Post> api;
  final Failure? apiFailure;
  int saveCalls = 0;

  @override
  Future<({List<Post> posts, Failure? failure})> readCachedPosts() async =>
      (posts: cached, failure: cachedFailure);

  @override
  Future<Failure?> savePostsToCache(List<Post> posts) async {
    saveCalls++;
    return null;
  }

  @override
  Future<({List<Post> posts, Failure? failure})> fetchFromApi() async =>
      (posts: api, failure: apiFailure);
}

void main() {
  test('LoadPostsCacheFirst mengembalikan cache saat forceOffline', () async {
    final repo = FakePostRepository(
      cached: [Post(id: 1, title: 't', body: 'b')],
      api: [Post(id: 2, title: 'api', body: 'x')],
    );
    final result = await LoadPostsCacheFirst(repo).call(forceOffline: true);
    expect(result.failure, isNull);
    expect(result.posts.length, 1);
    expect(result.posts.first.id, 1);
    expect(repo.saveCalls, 0);
  });

  test('LoadPostsCacheFirst meneruskan failure cache tanpa melempar', () async {
    final repo = FakePostRepository(
      cachedFailure: const LocalFailure('cache rusak'),
    );
    final result = await LoadPostsCacheFirst(repo).call(forceOffline: true);
    expect(result.failure, isA<LocalFailure>());
    expect(result.posts, isEmpty);
  });
}
