import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = task.description != null && task.description!.isNotEmpty;

    return Card(
      child: ListTile(
        leading: Checkbox(value: task.isCompleted, onChanged: (_) => onToggle()),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted
                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
          ),
        ),
        subtitle: hasDescription ? Text(task.description!) : null,
        onTap: onToggle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
