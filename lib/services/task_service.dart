import '../config/supabase_config.dart';
import '../models/task.dart';

class TaskService {
  final _table = 'tasks';

  // Obtiene todas las tareas del usuario autenticado, ordenadas por fecha
  Future<List<Task>> getTasks() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Crea una nueva tarea para el usuario actual
  Future<void> addTask(String title, String? description) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now().toIso8601String();
    await supabase.from(_table).insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'is_completed': false,
      'created_at': now,
    });
  }

  // Cambia el estado completado/pendiente de una tarea
  Future<void> toggleComplete(Task task) async {
    await supabase
        .from(_table)
        .update({'is_completed': !task.isCompleted}).eq('id', task.id);
  }

  // Actualiza título y descripción de una tarea
  Future<void> updateTask(String id, String title, String? description) async {
    await supabase.from(_table).update({
      'title': title,
      'description': description,
    }).eq('id', id);
  }

  // Elimina una tarea por su id
  Future<void> deleteTask(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }
}
