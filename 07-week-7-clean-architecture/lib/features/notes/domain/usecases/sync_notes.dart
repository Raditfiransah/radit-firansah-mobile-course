import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

class SyncNotes {
  const SyncNotes(this._repository);
  final NoteRepository _repository;

  Future<({int synced, Failure? failure})> call() async {
    final counted = await _repository.countDirty();
    if (counted.failure != null) {
      return (synced: 0, failure: counted.failure);
    }
    if (counted.count == 0) {
      return (synced: 0, failure: null);
    }

    // Simulasi upload catatan dirty ke server sebelum menandai bersih.
    await Future.delayed(const Duration(seconds: 1));
    final marked = await _repository.markAllSynced();
    if (marked != null) {
      return (synced: 0, failure: marked);
    }
    return (synced: counted.count, failure: null);
  }
}
