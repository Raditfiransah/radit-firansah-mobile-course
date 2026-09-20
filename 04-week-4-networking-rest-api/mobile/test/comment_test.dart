import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/comment.dart';
import 'package:mobile/data/providers.dart';

void main() {
  group('Comment.fromJson', () {
    test('berhasil parsing JSON lengkap (Happy Path)', () {
      final json = {
        'postId': 1,
        'id': 101,
        'name': 'id labore ex et quam laborum',
        'email': 'Eliseo@gardner.biz',
        'body': 'laudantium enim quasi est quidem magnam voluptate ipsam eos',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 101);
      expect(comment.name, 'id labore ex et quam laborum');
      expect(comment.email, 'Eliseo@gardner.biz');
      expect(comment.body, 'laudantium enim quasi est quidem magnam voluptate ipsam eos');
    });

    test('aman null saat beberapa field hilang atau null (Missing & Null Fields)', () {
      final json = {
        'postId': 1,
        // 'id' tidak disertakan (missing)
        'name': null,
        // 'email' tidak disertakan
        'body': 'Komentar tanpa email dan name',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 0); // fallback default
      expect(comment.name, ''); // fallback default
      expect(comment.email, ''); // fallback default
      expect(comment.body, 'Komentar tanpa email dan name');
    });

    test('Edge Case: aman null saat JSON berupa map kosong {}', () {
      final json = <String, dynamic>{};

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('Edge Case: tipe data numerik berupa double / float berhasil dikonversi ke int', () {
      final json = {
        'postId': 2.0,
        'id': 45.0,
        'name': 'Test Float ID',
        'email': 'test@example.com',
        'body': 'Body text',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 2);
      expect(comment.id, 45);
    });
  });

  group('friendlyErrorMessage', () {
    test('memetakan DioExceptionType.connectionTimeout ke pesan ramah timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionTimeout,
      );

      final message = friendlyErrorMessage(dioException);
      expect(message, contains('timeout'));
    });

    test('memetakan DioExceptionType.connectionError ke pesan ramah koneksi', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionError,
      );

      final message = friendlyErrorMessage(dioException);
      expect(message, contains('Tidak dapat terhubung ke server'));
    });

    test('memetakan status code 404 ke pesan data tidak ditemukan', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 404,
        ),
      );

      final message = friendlyErrorMessage(dioException);
      expect(message, contains('404'));
      expect(message, contains('Data tidak ditemukan'));
    });

    test('memetakan status code 500 ke pesan server bermasalah', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 500,
        ),
      );

      final message = friendlyErrorMessage(dioException);
      expect(message, contains('500'));
      expect(message, contains('server'));
    });
  });
}
