import 'package:campus_notify/messaging/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routeFromData membaca data.route', () {
    expect(
      routeFromData({'route': '/pengumuman/3', 'id': '3'}),
      '/pengumuman/3',
    );
  });

  test('routeFromData fallback ke / bila route tidak ada', () {
    expect(routeFromData({'id': '3'}), '/');
  });
}
