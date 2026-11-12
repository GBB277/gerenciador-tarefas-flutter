import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final TaskController controller;

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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
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
                : const Text('Minhas Tarefas'),
            actions: [
              IconButton(
                tooltip: _searching ? 'Fechar busca' : 'Buscar',
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: _toggleSearch,
              ),
              if (c.hasActiveFilters)
                IconButton(
                  tooltip: 'Limpar filtros',
                  icon: const Icon(Icons.filter_alt_off),
                  onPressed: () {
                    _searchController.clear();
                    c.clearFilters();
                  },
                ),
            ],
          ),
          body: c.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _Summary(controller: c),
                    _Filters(controller: c),
                    const Divider(height: 1),
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
                c.hasActiveFilters ? Icons.search_off : Icons.checklist,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 12),
              Text(
                c.hasActiveFilters
                    ? 'Nenhuma tarefa encontrada com esses filtros.'
                    : 'Você ainda não tem tarefas.\nToque em "Nova tarefa" para começar.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _delete(task),
          child: TaskTile(
            task: task,
            onToggle: () => c.toggleDone(task),
            onTap: () => _openForm(task),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final total = controller.totalCount;
    final done = controller.doneCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.pendingCount} pendentes · $done concluídas · $total no total',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress, minHeight: 6),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: [
        _ChipRow(
          children: [
            for (final s in StatusFilter.values)
              ChoiceChip(
                label: Text(_statusLabel(s)),
                selected: c.statusFilter == s,
                onSelected: (_) => c.setStatusFilter(s),
              ),
          ],
        ),
        _ChipRow(
          children: [
            for (final cat in kCategories)
              FilterChip(
                label: Text(cat),
                selected: c.categoryFilter == cat,
                onSelected: (sel) => c.setCategoryFilter(sel ? cat : null),
              ),
          ],
        ),
        _ChipRow(
          children: [
            for (final p in Priority.values)
              FilterChip(
                avatar: Icon(Icons.flag, size: 16, color: priorityColor(p)),
                label: Text(p.label),
                selected: c.priorityFilter == p,
                onSelected: (sel) => c.setPriorityFilter(sel ? p : null),
              ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(StatusFilter s) {
    switch (s) {
      case StatusFilter.todas:
        return 'Todas';
      case StatusFilter.pendentes:
        return 'Pendentes';
      case StatusFilter.concluidas:
        return 'Concluídas';
    }
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}
