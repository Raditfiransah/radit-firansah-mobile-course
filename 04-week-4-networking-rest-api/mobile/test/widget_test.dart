import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/post.dart';
import 'package:mobile/data/providers.dart';
import 'package:mobile/data/repositories/post_repository.dart';
import 'package:mobile/main.dart';

class FakePostRepository extends PostRepository {
  FakePostRepository() : super(Dio());

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    return [
      const Post(userId: 1, id: 1, title: 'Test Post', body: 'Test Body'),
    ];
  }

  @override
  Future<List<Post>> fetchPosts() async {
    return fetchPostsPage(page: 1);
  }
}

void main() {
  testWidgets('App smoke test loads MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(FakePostRepository()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
