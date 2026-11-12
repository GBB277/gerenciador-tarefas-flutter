import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/task_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final TaskController controller;
  final ThemeController themeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  TaskController get c => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([Task? task]) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    if (result is Task) {
      task == null ? await c.add(result) : await c.update(result);
    } else if (result == 'delete' && task != null) {
      await _delete(task);
    }
  }

  Future<void> _delete(Task task) async {
    await c.remove(task.id);
    if (!mounted) return;
    _showSnack(
        SnackBar(
          content: Text('"${task.title}" excluída'),
          action: SnackBarAction(
            label: 'DESFAZER',
            onPressed: () => c.restore(task),
          ),
        ),
      );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        c.setQuery('');
      }
    });
  }

  /// Mostra um aviso que some sozinho, mesmo tendo o botão DESFAZER.
  /// (Nas versões novas do Flutter, avisos com ação ficam fixos.)
  void _showSnack(SnackBar bar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final ctrl = messenger.showSnackBar(bar);
    var open = true;
    ctrl.closed.then((_) => open = false);
    Future.delayed(bar.duration, () {
      if (open) ctrl.close();
    });
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(controller: c),
    );
  }

  /// Conclui ou reabre a tarefa. Ao concluir, mostra um aviso com desfazer.
  Future<void> _toggle(Task task) async {
    HapticFeedback.selectionClick();
    await c.toggleDone(task);
    if (!mounted || task.done) return;
    _showSnack(
        SnackBar(
          content: Text('"${task.title}" concluída'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'DESFAZER',
            onPressed: () => c.update(task),
          ),
        ),
      );
  }

  /// Alterna entre claro e escuro a partir do tema que está na tela.
  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.themeController.setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _clearCompleted() async {
    final count = c.doneCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar concluídas?'),
        content: Text(
          count == 1
              ? 'A tarefa concluída será removida.'
              : 'As $count tarefas concluídas serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await c.removeCompleted();
    if (!mounted) return;
    _showSnack(
        SnackBar(
          content: Text(
            removed.length == 1
                ? '1 tarefa concluída removida'
                : '${removed.length} tarefas concluídas removidas',
          ),
          action: SnackBarAction(
            label: 'DESFAZER',
            onPressed: () => c.restoreAll(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: _searching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar tarefas...',
                      border: InputBorder.none,
                    ),
                    onChanged: c.setQuery,
                  )
                : const Text(
                    'Minhas Tarefas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
            actions: [
              IconButton(
                tooltip: _searching ? 'Fechar busca' : 'Buscar',
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: _toggleSearch,
              ),
              IconButton(
                tooltip: 'Filtros',
                onPressed: _openFilters,
                icon: Badge(
                  isLabelVisible: c.panelFilterCount > 0,
                  label: Text('${c.panelFilterCount}'),
                  child: const Icon(Icons.tune),
                ),
              ),
              IconButton(
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Tema claro'
                    : 'Tema escuro',
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: _toggleTheme,
              ),
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                onSelected: (value) {
                  if (value == 'system') {
                    widget.themeController.setMode(ThemeMode.system);
                  } else if (value == 'clear') {
                    _clearCompleted();
                  }
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem<String>(
                    value: 'system',
                    checked: widget.themeController.mode == ThemeMode.system,
                    child: const Text('Seguir tema do sistema'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'clear',
                    enabled: c.doneCount > 0,
                    child: const Row(
                      children: [
                        Icon(Icons.cleaning_services_outlined),
                        SizedBox(width: 12),
                        Text('Limpar concluídas'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: c.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _SummaryCard(controller: c),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<StatusFilter>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: StatusFilter.pendentes,
                              label: Text('Pendentes'),
                            ),
                            ButtonSegment(
                              value: StatusFilter.todas,
                              label: Text('Todas'),
                            ),
                            ButtonSegment(
                              value: StatusFilter.concluidas,
                              label: Text('Concluídas'),
                            ),
                          ],
                          selected: {c.statusFilter},
                          onSelectionChanged: (s) =>
                              c.setStatusFilter(s.first),
                        ),
                      ),
                    ),
                    if (c.panelFilterCount > 0) _ActiveFilters(controller: c),
                    Expanded(child: _buildList()),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nova tarefa'),
          ),
        );
      },
    );
  }

  Widget _buildList() {
    final tasks = c.visibleTasks;
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                c.hasActiveFilters ? Icons.search_off : Icons.task_alt,
                size: 72,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                c.hasActiveFilters
                    ? 'Nenhuma tarefa encontrada com esses filtros.'
                    : c.totalCount == 0
                        ? 'Você ainda não tem tarefas.\nToque em "Nova tarefa" para começar.'
                        : 'Tudo em dia! Nenhuma tarefa pendente.',
                textAlign: TextAlign.center,
              ),
              if (c.hasActiveFilters) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    c.clearFilters();
                  },
                  child: const Text('Limpar filtros'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    // Cabeçalhos (String) e tarefas (Task) na mesma lista.
    final items = <Object>[
      if (pending.isNotEmpty) 'Pendentes (${pending.length})',
      ...pending,
      if (done.isNotEmpty) 'Concluídas (${done.length})',
      ...done,
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item is String) return _SectionHeader(text: item);
        final task = item as Task;
        return Dismissible(
          key: ValueKey(task.id),
          // Deslizar para a direita: concluir / reabrir.
          background: _SwipeBackground(
            color: const Color(0xFF2E7D32),
            icon: task.done ? Icons.undo : Icons.check,
            label: task.done ? 'Reabrir' : 'Concluir',
            alignLeft: true,
          ),
          // Deslizar para a esquerda: excluir.
          secondaryBackground: const _SwipeBackground(
            color: Color(0xFFC62828),
            icon: Icons.delete_outline,
            label: 'Excluir',
            alignLeft: false,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _toggle(task);
              return false;
            }
            return true;
          },
          onDismissed: (_) => _delete(task),
          child: TaskTile(
            task: task,
            onToggle: () => _toggle(task),
            onTap: () => _openForm(task),
          ),
        );
      },
    );
  }
}

IconData _dueIcon(DueFilter f) {
  switch (f) {
    case DueFilter.atrasadas:
      return Icons.warning_amber_rounded;
    case DueFilter.hoje:
      return Icons.today;
    case DueFilter.semana:
      return Icons.date_range;
    case DueFilter.semPrazo:
      return Icons.event_busy;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final TaskController controller;

  String _plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = controller.totalCount;
    final done = controller.doneCount;
    final overdue = controller.overdueCount;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();

    final subtitle = StringBuffer(
      _plural(controller.pendingCount, 'pendente', 'pendentes'),
    );
    if (overdue > 0) {
      subtitle.write(' · ${_plural(overdue, 'atrasada', 'atrasadas')}');
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    color: scheme.primary,
                    backgroundColor:
                        scheme.onPrimaryContainer.withValues(alpha: 0.15),
                  ),
                ),
                Text(
                  '$percent%',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'Nenhuma tarefa ainda'
                      : '$done de $total concluídas',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.toString(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: overdue > 0
                        ? scheme.error
                        : scheme.onPrimaryContainer,
                    fontWeight: overdue > 0 ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (c.categoryFilter != null)
              InputChip(
                avatar: Icon(categoryIcon(c.categoryFilter!), size: 18),
                label: Text(c.categoryFilter!),
                onDeleted: () => c.setCategoryFilter(null),
              ),
            if (c.priorityFilter != null)
              InputChip(
                avatar: Icon(
                  Icons.flag,
                  size: 18,
                  color: priorityColor(c.priorityFilter!),
                ),
                label: Text('Prioridade ${c.priorityFilter!.label}'),
                onDeleted: () => c.setPriorityFilter(null),
              ),
            if (c.dueFilter != null)
              InputChip(
                avatar: Icon(_dueIcon(c.dueFilter!), size: 18),
                label: Text(c.dueFilter!.label),
                onDeleted: () => c.setDueFilter(null),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final c = controller;
        final textTheme = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtros', style: textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Categoria', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in kCategories)
                      FilterChip(
                        showCheckmark: false,
                        avatar: Icon(categoryIcon(cat), size: 18),
                        label: Text(cat),
                        selected: c.categoryFilter == cat,
                        onSelected: (sel) =>
                            c.setCategoryFilter(sel ? cat : null),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Prioridade', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in Priority.values)
                      FilterChip(
                        showCheckmark: false,
                        avatar: Icon(
                          Icons.flag,
                          size: 18,
                          color: priorityColor(p),
                        ),
                        label: Text(p.label),
                        selected: c.priorityFilter == p,
                        onSelected: (sel) =>
                            c.setPriorityFilter(sel ? p : null),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Prazo', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in DueFilter.values)
                      FilterChip(
                        showCheckmark: false,
                        avatar: Icon(_dueIcon(f), size: 18),
                        label: Text(f.label),
                        selected: c.dueFilter == f,
                        onSelected: (sel) => c.setDueFilter(sel ? f : null),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    TextButton(
                      onPressed: c.panelFilterCount > 0
                          ? c.clearPanelFilters
                          : null,
                      child: const Text('Limpar'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignLeft,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
