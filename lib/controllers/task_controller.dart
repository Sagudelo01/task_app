import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

enum TaskFilter { all, pending, completed }

enum TaskSort { newest, oldest, title, pendingFirst }

class TaskController extends ChangeNotifier {
  TaskController(this._service);
  final TaskService _service;

  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.newest;

  bool get loading => _loading;
  String? get error => _error;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  bool get isEmpty => _tasks.isEmpty;

  int get total => _tasks.length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get completedCount => total - pendingCount;

  List<Task> get visibleTasks {
    final list = _tasks.where((t) {
      switch (_filter) {
        case TaskFilter.pending:
          return !t.isCompleted;
        case TaskFilter.completed:
          return t.isCompleted;
        case TaskFilter.all:
          return true;
      }
    }).toList();

    switch (_sort) {
      case TaskSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TaskSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case TaskSort.pendingFirst:
        list.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          return b.createdAt.compareTo(a.createdAt);
        });
    }
    return list;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _service.getTasks();
    } catch (_) {
      _error = 'No se pudieron cargar las tareas';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter(TaskFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  void setSort(TaskSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  Future<bool> add(String title, String? description) async {
    try {
      final task = await _service.addTask(title, description);
      _tasks = [task, ..._tasks];
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> edit(Task task, String title, String? description) async {
    try {
      final updated = await _service.updateTask(task.id, title, description);
      _replace(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Optimistic toggle: flips locally first, reverts if the write fails.
  Future<bool> toggle(Task task) async {
    final optimistic = task.copyWith(isCompleted: !task.isCompleted);
    _replace(optimistic);
    try {
      await _service.setCompleted(task.id, optimistic.isCompleted);
      return true;
    } catch (_) {
      _replace(task);
      return false;
    }
  }

  /// Optimistic delete: removes locally first, reinserts if the write fails.
  Future<bool> delete(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return false;
    _tasks = List.of(_tasks)..removeAt(index);
    notifyListeners();
    try {
      await _service.deleteTask(task.id);
      return true;
    } catch (_) {
      _tasks = List.of(_tasks)..insert(index, task);
      notifyListeners();
      return false;
    }
  }

  void _replace(Task task) {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    _tasks = List.of(_tasks)..[i] = task;
    notifyListeners();
  }
}
