import 'package:flutter/material.dart';
import '../controllers/task_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../widgets/task_editor.dart';
import '../widgets/task_list.dart';

const _desktopBreakpoint = 900.0;

const _filters = [
  (TaskFilter.all, 'Todas', Icons.list_alt),
  (TaskFilter.pending, 'Pendientes', Icons.radio_button_unchecked),
  (TaskFilter.completed, 'Completadas', Icons.check_circle_outline),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.controller});

  /// Injectable for tests and previews; defaults to a Supabase-backed one.
  final TaskController? controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _controller = widget.controller ?? TaskController(TaskService());
  final _auth = AuthService();
  late final _ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _newTask() => showTaskEditor(context, _controller);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
        return wide ? _buildDesktop(context) : _buildMobile(context);
      },
    );
  }

  // ---- Mobile: top app bar, full-width list, bottom navigation ----
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
        actions: [
          _SortMenu(controller: _controller),
          const _ThemeToggle(),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión', onPressed: _signOut),
        ],
      ),
      body: SafeArea(child: TaskList(controller: _controller, swipeToDelete: true)),
      floatingActionButton: FloatingActionButton(
        onPressed: _newTask,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _controller.filter.index,
        onDestinationSelected: (i) => _controller.setFilter(TaskFilter.values[i]),
        destinations: [
          for (final (_, label, icon) in _filters)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }

  // ---- Desktop: left sidebar + centered, max-width content ----
  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            controller: _controller,
            onNewTask: _newTask,
            onSignOut: _signOut,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                  child: Row(
                    children: [
                      Text(_filterLabel(_controller.filter),
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(width: 12),
                      Text('${_controller.visibleTasks.length}',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      const Spacer(),
                      _SortMenu(controller: _controller),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: TaskList(
                        controller: _controller,
                        padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(TaskFilter f) =>
      _filters.firstWhere((e) => e.$1 == f).$2;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.controller, required this.onNewTask, required this.onSignOut});
  final TaskController controller;
  final VoidCallback onNewTask;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = {
      TaskFilter.all: controller.total,
      TaskFilter.pending: controller.pendingCount,
      TaskFilter.completed: controller.completedCount,
    };

    return SizedBox(
      width: 272,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text('Senkai', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onNewTask,
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            ),
            const SizedBox(height: 20),
            for (final (filter, label, icon) in _filters)
              _SidebarItem(
                icon: icon,
                label: label,
                count: counts[filter]!,
                selected: controller.filter == filter,
                onTap: () => controller.setFilter(filter),
              ),
            const Spacer(),
            const _ThemeToggle(labelled: true),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: onSignOut,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      selectedColor: theme.colorScheme.onSecondaryContainer,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text('$count'),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.controller});
  final TaskController controller;

  static const _labels = {
    TaskSort.newest: 'Más recientes',
    TaskSort.oldest: 'Más antiguas',
    TaskSort.title: 'Título (A–Z)',
    TaskSort.pendingFirst: 'Pendientes primero',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskSort>(
      icon: const Icon(Icons.sort),
      tooltip: 'Ordenar',
      initialValue: controller.sort,
      onSelected: controller.setSort,
      itemBuilder: (_) => [
        for (final entry in _labels.entries)
          PopupMenuItem(value: entry.key, child: Text(entry.value)),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({this.labelled = false});
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    if (labelled) {
      return ListTile(
        leading: Icon(icon),
        title: Text(isDark ? 'Modo claro' : 'Modo oscuro'),
        onTap: themeController.toggle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }
    return IconButton(
      icon: Icon(icon),
      tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
      onPressed: themeController.toggle,
    );
  }
}
