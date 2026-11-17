import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/controllers/task_controller.dart';
import 'package:task_app/models/task.dart';
import 'package:task_app/services/task_service.dart';

/// In-memory stand-in for [TaskService] so the controller can be tested
/// without Supabase.
class FakeTaskService implements TaskService {
  final List<Task> _store;
  FakeTaskService(this._store);
  var _seq = 0;

  @override
  Future<List<Task>> getTasks() async => List.of(_store);

  @override
  Future<Task> addTask(String title, String? description) async {
    final task = Task(
      id: 'new-${_seq++}',
      userId: 'u',
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    _store.insert(0, task);
    return task;
  }

  @override
  Future<Task> updateTask(String id, String title, String? description) async {
    final t = _store.firstWhere((e) => e.id == id);
    return t.copyWith(title: title, description: description);
  }

  @override
  Future<void> setCompleted(String id, bool completed) async {}

  @override
  Future<void> deleteTask(String id) async {}
}

Task _task(String id, {bool done = false, int ageMinutes = 0, String? title}) => Task(
      id: id,
      userId: 'u',
      title: title ?? 'Task $id',
      isCompleted: done,
      createdAt: DateTime(2026).subtract(Duration(minutes: ageMinutes)),
    );

void main() {
  group('TaskController', () {
    test('load fills tasks and clears loading', () async {
      final c = TaskController(FakeTaskService([_task('1'), _task('2')]));
      expect(c.loading, isTrue);
      await c.load();
      expect(c.loading, isFalse);
      expect(c.total, 2);
    });

    test('add prepends a task', () async {
      final c = TaskController(FakeTaskService([_task('1')]));
      await c.load();
      await c.add('Fresh', null);
      expect(c.total, 2);
      expect(c.visibleTasks.first.title, 'Fresh');
    });

    test('toggle flips completion optimistically', () async {
      final c = TaskController(FakeTaskService([_task('1')]));
      await c.load();
      await c.toggle(c.visibleTasks.first);
      expect(c.completedCount, 1);
      expect(c.pendingCount, 0);
    });

    test('delete removes a task', () async {
      final c = TaskController(FakeTaskService([_task('1'), _task('2')]));
      await c.load();
      await c.delete(c.visibleTasks.first);
      expect(c.total, 1);
    });

    test('filter and sort shape the visible list', () async {
      final c = TaskController(FakeTaskService([
        _task('a', done: true, ageMinutes: 10, title: 'Beta'),
        _task('b', ageMinutes: 5, title: 'Alpha'),
      ]));
      await c.load();

      c.setFilter(TaskFilter.pending);
      expect(c.visibleTasks.every((t) => !t.isCompleted), isTrue);

      c.setFilter(TaskFilter.all);
      c.setSort(TaskSort.title);
      expect(c.visibleTasks.first.title, 'Alpha');
    });
  });
}
