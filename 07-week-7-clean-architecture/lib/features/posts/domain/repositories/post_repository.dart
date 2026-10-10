import '../../../../core/failures.dart';
import '../entities/post.dart';

abstract class PostRepository {
  Future<({List<Post> posts, Failure? failure})> readCachedPosts();
  Future<Failure?> savePostsToCache(List<Post> posts);
  Future<({List<Post> posts, Failure? failure})> fetchFromApi();
}
