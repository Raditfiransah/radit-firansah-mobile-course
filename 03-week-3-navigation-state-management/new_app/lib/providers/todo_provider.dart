import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void toggleTodo(Todo todo) {
    final todos = [...state];
    final index = todos.indexOf(todo);
    if (index != -1) {
      todos[index] = todos[index].copyWith(done: !todos[index].done);
      state = todos;
    }
  }

  void remove(int index) => state = [...state]..removeAt(index);

  void removeTodo(Todo todo) {
    state = state.where((item) => item != todo).toList();
  }
}

final todoListProvider = NotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

/// Provider turunan (derived provider) yang membaca todoListProvider 
/// dan memfilter hanya tugas yang belum selesai (done == false).
final uncompletedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => !todo.done).toList();
});

class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi network
    return ['Keyboard', 'Mouse', 'Monitor'];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<String>>(
  ProductsNotifier.new,
);
