import 'package:flutter/material.dart';
import '../controllers/task_controller.dart';
import '../models/task.dart';
import 'task_editor.dart';
import 'task_tile.dart';

class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.controller,
    this.swipeToDelete = false,
    this.padding = const EdgeInsets.all(16),
  });

  final TaskController controller;
  final bool swipeToDelete;
  final EdgeInsets padding;

  Future<void> _toggle(BuildContext context, Task task) async {
    final ok = await controller.toggle(task);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la tarea')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return false;
    final deleted = await controller.delete(task);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(deleted ? 'Tarea eliminada' : 'No se pudo eliminar la tarea'),
      ));
    }
    return deleted;
  }

  @override
  Widget build(BuildContext context) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.isEmpty) {
      return _Message(
        icon: Icons.cloud_off,
        title: controller.error!,
        action: FilledButton.tonal(
          onPressed: controller.load,
          child: const Text('Reintentar'),
        ),
      );
    }

    if (controller.isEmpty) {
      return const _Message(
        icon: Icons.task_alt,
        title: 'No hay tareas aún',
        subtitle: 'Crea tu primera tarea con el botón +',
      );
    }

    final tasks = controller.visibleTasks;
    if (tasks.isEmpty) {
      return const _Message(
        icon: Icons.filter_alt_off,
        title: 'Sin tareas en este filtro',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: padding,
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final task = tasks[i];
          final tile = TaskTile(
            task: task,
            onToggle: () => _toggle(context, task),
            onEdit: () => showTaskEditor(context, controller, task: task),
            onDelete: () => _confirmDelete(context, task),
          );
          if (!swipeToDelete) return tile;
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context, task),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            child: tile,
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
