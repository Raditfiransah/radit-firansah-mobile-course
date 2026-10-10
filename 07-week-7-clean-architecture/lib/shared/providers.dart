import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider lintas fitur. Diletakkan di luar `lib/core` dan `features/*/domain`
// agar grep sterilitas (lib/core) tetap nol hasil.
final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setOffline(bool value) => state = value;
}
