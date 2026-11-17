import '../config/supabase_config.dart';
import '../models/task.dart';

/// CRUD operations for tasks against Supabase.
class TaskService {
  static const _table = 'tasks';

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw Exception('No authenticated user');
    return id;
  }

  Future<List<Task>> getTasks() async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(Task.fromJson).toList();
  }

  /// Inserts a task and returns the stored row, so callers can update the
  /// local list without a second round trip.
  Future<Task> addTask(String title, String? description) async {
    final row = await supabase.from(_table).insert({
      'user_id': _userId,
      'title': title,
      'description': description,
      'is_completed': false,
    }).select().single();
    return Task.fromJson(row);
  }

  Future<Task> updateTask(String id, String title, String? description) async {
    final row = await supabase
        .from(_table)
        .update({'title': title, 'description': description})
        .eq('id', id)
        .select()
        .single();
    return Task.fromJson(row);
  }

  Future<void> setCompleted(String id, bool completed) async {
    await supabase.from(_table).update({'is_completed': completed}).eq('id', id);
  }

  Future<void> deleteTask(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
