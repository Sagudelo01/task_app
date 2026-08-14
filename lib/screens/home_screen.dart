import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

// Pantalla principal: lista, crea, edita y elimina tareas
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _taskService = TaskService();
  // Estado: tareas cargadas, carga, error y filtro activo
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'todas'; // todas, pendientes, completadas

  // Filtra las tareas en memoria según el filtro seleccionado
  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'pendientes':
        return _tasks.where((t) => !t.isCompleted).toList();
      case 'completadas':
        return _tasks.where((t) => t.isCompleted).toList();
      default:
        return _tasks;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
  // Carga las tareas del usuario desde Supabase
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _taskService.getTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error al cargar las tareas');
        _showSnackBar('Error al cargar las tareas', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Cierra sesión y vuelve al login
  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // Optimistic: actualiza el estado local al instante y guarda en segundo plano
  Future<void> _toggleComplete(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final nuevoEstado = !task.isCompleted;
    final tareaOriginal = _tasks[index];

    setState(() => _tasks[index] = tareaOriginal.copyWith(isCompleted: nuevoEstado));

    try {
      await _taskService.toggleComplete(task);
    } catch (e) {
      // Revierte el cambio local si falla Supabase
      setState(() => _tasks[index] = tareaOriginal);
      _showSnackBar('Error al actualizar la tarea', isError: true);
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final index = _tasks.indexWhere((t) => t.id == task.id);
    final tareaEliminada = _tasks[index];

    // Optimistic: quita la tarea de la lista al instante
    setState(() => _tasks.removeAt(index));

    try {
      await _taskService.deleteTask(task.id);
    } catch (e) {
      // Revierte: vuelve a insertar en la posición original
      setState(() => _tasks.insert(index, tareaEliminada));
      _showSnackBar('Error al eliminar la tarea', isError: true);
    }
  }

  // Diálogo unificado para crear o editar tarea
  Future<void> _showTaskDialog({Task? task}) async {
    final esEdicion = task != null;
    final tituloCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar tarea' : 'Nueva tarea'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: tituloCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.task_alt),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: Text(esEdicion ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final titulo = tituloCtrl.text.trim();
    final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();

    try {
      if (esEdicion) {
        await _taskService.updateTask(task.id, titulo, desc);
        _showSnackBar('Tarea actualizada');
      } else {
        await _taskService.addTask(titulo, desc);
        _showSnackBar('Tarea creada');
      }
      await _loadTasks();
    } catch (e) {
      _showSnackBar('Error al guardar la tarea', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
  
  // Construye la barra superior y el botón de agregar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Muestra loading, error, estado vacío o la lista con filtros
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadTasks,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No hay tareas aún',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Crea tu primera tarea con el botón +',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    final filtradas = _filteredTasks;

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todas', label: Text('Todas')),
                ButtonSegment(value: 'pendientes', label: Text('Pendientes')),
                ButtonSegment(value: 'completadas', label: Text('Completadas')),
              ],
              selected: {_filter},
              onSelectionChanged: (selected) {
                setState(() => _filter = selected.first);
              },
            ),
          ),
          if (filtradas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No hay tareas en este filtro',
                    style: TextStyle(fontSize: 16)),
              ),
            )
          else
            ...filtradas.map((task) {
          return Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              await _deleteTask(task);
              return false;
            },
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleComplete(task),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: task.description != null &&
                      task.description!.isNotEmpty
                  ? Text(task.description!)
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () => _showTaskDialog(task: task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar',
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
              onTap: () => _toggleComplete(task),
            ),
          );
        }),
        ],
      ),
    );
  }
}
