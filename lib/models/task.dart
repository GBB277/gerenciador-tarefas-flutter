enum Priority { alta, media, baixa }

extension PriorityLabel on Priority {
  String get label {
    switch (this) {
      case Priority.alta:
        return 'Alta';
      case Priority.media:
        return 'Média';
      case Priority.baixa:
        return 'Baixa';
    }
  }

  /// Menor valor = mais importante (usado na ordenação).
  int get weight {
    switch (this) {
      case Priority.alta:
        return 0;
      case Priority.media:
        return 1;
      case Priority.baixa:
        return 2;
    }
  }
}

const List<String> kCategories = [
  'Trabalho',
  'Estudo',
  'Pessoal',
  'Saúde',
  'Outros',
];

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final Priority priority;
  final bool done;
  final DateTime createdAt;
  final DateTime? dueDate;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Outros',
    this.priority = Priority.media,
    this.done = false,
    required this.createdAt,
    this.dueDate,
  });

  /// Pendente e com prazo anterior a hoje.
  bool get isOverdue {
    if (done || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  Task copyWith({
    String? title,
    String? description,
    String? category,
    Priority? priority,
    bool? done,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      done: done ?? this.done,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority.name,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Outros',
      priority: Priority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => Priority.media,
      ),
      done: (json['done'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
    );
  }
}
