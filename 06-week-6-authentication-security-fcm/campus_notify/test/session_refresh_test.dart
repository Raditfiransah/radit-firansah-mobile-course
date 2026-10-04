import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements TokenStore {
  _FakeStore({this.access, this.refresh});
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class _FakeAuth implements AuthRepository {
  _FakeAuth({this.renewed = 'new-access', this.fail = false});
  final String renewed;
  final bool fail;
  int refreshCalls = 0;

  @override
  Future<AuthSession> login(
          {required String email, required String password}) async =>
      const AuthSession(access: 'a', refresh: 'r');

  @override
  Future<String> refresh(String refreshToken) async {
    refreshCalls++;
    if (fail) throw Exception('refresh mati');
    return renewed;
  }
}

// Adapter palsu: `failTimes` request pertama mengembalikan 401, sisanya 200.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.failTimes = 1});
  final int failTimes;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    final headers = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (calls <= failTimes) {
      return ResponseBody.fromString('{"error":"unauthorized"}', 401,
          headers: headers);
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'auth': options.headers['Authorization']}),
      200,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('401 -> refresh sekali, simpan access baru, ulang request', () async {
    final store = _FakeStore(access: 'old-access', refresh: 'ref');
    final auth = _FakeAuth(renewed: 'new-access');
    final dio = buildApiClient(store, auth);
    final adapter = _FakeAdapter(failTimes: 1);
    dio.httpClientAdapter = adapter;

    final res = await dio.get('/protected');

    expect(res.statusCode, 200);
    expect(res.data['auth'], 'Bearer new-access');
    expect(auth.refreshCalls, 1);
    expect(store.access, 'new-access');
    expect(adapter.calls, 2);
  });

  test('token hasil refresh tetap ditolak -> refresh tidak berulang', () async {
    final store = _FakeStore(access: 'old-access', refresh: 'ref');
    final auth = _FakeAuth(renewed: 'still-bad');
    final dio = buildApiClient(store, auth);
    dio.httpClientAdapter = _FakeAdapter(failTimes: 99);

    await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));

    expect(auth.refreshCalls, 1);
  });

  test('refresh gagal -> sesi dibersihkan (logout)', () async {
    final store = _FakeStore(access: 'old-access', refresh: 'ref');
    final auth = _FakeAuth(fail: true);
    final dio = buildApiClient(store, auth);
    dio.httpClientAdapter = _FakeAdapter(failTimes: 99);

    await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));

    expect(auth.refreshCalls, 1);
    expect(store.access, isNull);
    expect(store.refresh, isNull);
  });
}
