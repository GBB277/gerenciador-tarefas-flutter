import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/task_storage.dart';

enum StatusFilter { todas, pendentes, concluidas }

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
  StatusFilter statusFilter = StatusFilter.todas;

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

  /// Lista já filtrada e ordenada: pendentes primeiro, depois por
  /// prioridade, depois por data de vencimento / criação.
  List<Task> get visibleTasks {
    final q = query.trim().toLowerCase();
    final result = _tasks.where((t) {
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
      statusFilter != StatusFilter.todas;

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

  void clearFilters() {
    query = '';
    categoryFilter = null;
    priorityFilter = null;
    statusFilter = StatusFilter.todas;
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _storage.save(_tasks);
  }
}
