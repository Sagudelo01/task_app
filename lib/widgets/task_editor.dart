import 'package:flutter/material.dart';
import '../controllers/task_controller.dart';
import '../models/task.dart';

/// Opens the create/edit form as a dialog on wide screens and a bottom sheet
/// on phones. Returns true when a task was saved.
Future<void> showTaskEditor(
  BuildContext context,
  TaskController controller, {
  Task? task,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 600;
  final form = _TaskEditorForm(controller: controller, task: task);

  if (wide) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: form,
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: form,
    ),
  );
}

class _TaskEditorForm extends StatefulWidget {
  const _TaskEditorForm({required this.controller, this.task});
  final TaskController controller;
  final Task? task;

  @override
  State<_TaskEditorForm> createState() => _TaskEditorFormState();
}

class _TaskEditorFormState extends State<_TaskEditorForm> {
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _desc = TextEditingController(text: widget.task?.description ?? '');
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final title = _title.text.trim();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    final ok = _isEdit
        ? await widget.controller.edit(widget.task!, title, desc)
        : await widget.controller.add(title, desc);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (_isEdit ? 'Tarea actualizada' : 'Tarea creada')
          : 'No se pudo guardar la tarea'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Editar tarea' : 'Nueva tarea',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
