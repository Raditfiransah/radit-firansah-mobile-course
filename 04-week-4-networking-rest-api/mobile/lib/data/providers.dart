import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'models/comment.dart';
import 'repositories/post_repository.dart';
import 'repositories/comment_repository.dart';

/// Provider instance Dio global dengan konfigurasi dasar terpusat.
final dioProvider = Provider<Dio>((ref) => createDio());

/// Provider untuk PostRepository.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

/// Provider untuk CommentRepository.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Notifier untuk mengelola daftar postingan.
class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError (deklaratif).
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPostsPage(page: 1, limit: 10);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPostsPage(page: 1, limit: 10));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
  PostListNotifier.new,
  // Nonaktifkan retry otomatis Riverpod agar error langsung final dan mudah diuji
  retry: (retryCount, error) => null,
);

/// Notifier untuk mengelola daftar komentar dengan AsyncNotifier.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  int _currentPostId = 1;

  @override
  Future<List<Comment>> build() async {
    // Exception dari repository otomatis ditangkap dan menjadi AsyncError secara deklaratif
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(_currentPostId);
  }

  /// Memuat komentar berdasarkan ID postingan tertentu
  Future<void> loadComments(int postId) async {
    _currentPostId = postId;
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Fungsi untuk me-refresh data komentar saat ini
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(_currentPostId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final commentListProvider =
    AsyncNotifierProvider<CommentListNotifier, List<Comment>>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,
);

/// Helper khusus testing: membaca state pertama yang bukan loading lewat listener + completer.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

/// Helper khusus testing untuk membaca error komentar
Future<Object?> readCommentsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Comment>>>(
    commentListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

/// Fungsi pemetaan error Dio / Exception ke pesan ramah pengguna (User-friendly).
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 500) {
          return 'Terjadi kesalahan internal pada server (500). Coba lagi nanti.';
        }
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}