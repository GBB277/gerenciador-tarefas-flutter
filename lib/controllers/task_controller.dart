import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/task_storage.dart';

enum StatusFilter { todas, pendentes, concluidas }

/// Filtro por prazo, usado no painel de filtros.
enum DueFilter { atrasadas, hoje, semana, semPrazo }

extension DueFilterLabel on DueFilter {
  String get label {
    switch (this) {
      case DueFilter.atrasadas:
        return 'Atrasadas';
      case DueFilter.hoje:
        return 'Hoje';
      case DueFilter.semana:
        return 'Próximos 7 dias';
      case DueFilter.semPrazo:
        return 'Sem prazo';
    }
  }
}

/// Controlador de estado (ChangeNotifier): guarda as tarefas, os filtros
/// e salva no armazenamento local a cada alteração.
class TaskController extends ChangeNotifier {
  TaskController(this._storage);

  final TaskStorage _storage;

  final List<Task> _tasks = [];
  bool loading = true;

  String query = '';
  String? categoryFilter;
  Priority? priorityFilter;
  DueFilter? dueFilter;
  StatusFilter statusFilter = StatusFilter.pendentes;

  Future<void> load() async {
    _tasks
      ..clear()
      ..addAll(await _storage.load());
    loading = false;
    notifyListeners();
  }

  int get totalCount => _tasks.length;
  int get pendingCount => _tasks.where((t) => !t.done).length;
  int get doneCount => _tasks.where((t) => t.done).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  /// Quantos filtros do painel (categoria, prioridade e prazo) estão ativos.
  int get panelFilterCount =>
      (categoryFilter != null ? 1 : 0) +
      (priorityFilter != null ? 1 : 0) +
      (dueFilter != null ? 1 : 0);

  bool _matchesDue(Task t, DueFilter f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = t.dueDate;
    final day = due == null ? null : DateTime(due.year, due.month, due.day);
    switch (f) {
      case DueFilter.atrasadas:
        return t.isOverdue;
      case DueFilter.hoje:
        return day != null && day == today;
      case DueFilter.semana:
        return day != null &&
            !day.isBefore(today) &&
            day.isBefore(today.add(const Duration(days: 7)));
      case DueFilter.semPrazo:
        return day == null;
    }
  }

  /// Lista já filtrada e ordenada de forma "inteligente":
  /// pendentes primeiro, atrasadas no topo, depois prioridade,
  /// prazo mais próximo e, por fim, as mais recentes.
  List<Task> get visibleTasks {
    final q = query.trim().toLowerCase();
    final dueF = dueFilter;
    final result = _tasks.where((t) {
      if (dueF != null && !_matchesDue(t, dueF)) return false;
      if (q.isNotEmpty &&
          !t.title.toLowerCase().contains(q) &&
          !t.description.toLowerCase().contains(q)) {
        return false;
      }
      if (categoryFilter != null && t.category != categoryFilter) return false;
      if (priorityFilter != null && t.priority != priorityFilter) return false;
      switch (statusFilter) {
        case StatusFilter.pendentes:
          if (t.done) return false;
          break;
        case StatusFilter.concluidas:
          if (!t.done) return false;
          break;
        case StatusFilter.todas:
          break;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      final byPriority = a.priority.weight.compareTo(b.priority.weight);
      if (byPriority != 0) return byPriority;
      final da = a.dueDate ?? DateTime(9999);
      final db = b.dueDate ?? DateTime(9999);
      final byDue = da.compareTo(db);
      if (byDue != 0) return byDue;
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      categoryFilter != null ||
      priorityFilter != null ||
      dueFilter != null ||
      statusFilter != StatusFilter.pendentes;

  Future<void> add(Task task) async {
    _tasks.add(task);
    await _persist();
  }

  Future<void> update(Task task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    _tasks[i] = task;
    await _persist();
  }

  Future<void> remove(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _persist();
  }

  Future<void> restore(Task task) async {
    if (_tasks.any((t) => t.id == task.id)) return;
    _tasks.add(task);
    await _persist();
  }

  Future<void> toggleDone(Task task) => update(task.copyWith(done: !task.done));

  /// Remove todas as concluídas e devolve a lista removida (para desfazer).
  Future<List<Task>> removeCompleted() async {
    final removed = _tasks.where((t) => t.done).toList();
    _tasks.removeWhere((t) => t.done);
    await _persist();
    return removed;
  }

  Future<void> restoreAll(List<Task> tasks) async {
    for (final t in tasks) {
      if (!_tasks.any((x) => x.id == t.id)) _tasks.add(t);
    }
    await _persist();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategoryFilter(String? value) {
    categoryFilter = value;
    notifyListeners();
  }

  void setPriorityFilter(Priority? value) {
    priorityFilter = value;
    notifyListeners();
  }

  void setStatusFilter(StatusFilter value) {
    statusFilter = value;
    notifyListeners();
  }

  void setDueFilter(DueFilter? value) {
    dueFilter = value;
    notifyListeners();
  }

  void clearPanelFilters() {
    categoryFilter = null;
    priorityFilter = null;
    dueFilter = null;
    notifyListeners();
  }

  void clearFilters() {
    query = '';
    categoryFilter = null;
    priorityFilter = null;
    dueFilter = null;
    statusFilter = StatusFilter.pendentes;
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _storage.save(_tasks);
  }
}
