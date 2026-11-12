import 'package:flutter_test/flutter_test.dart';
import 'package:gerenciador_tarefas/models/task.dart';

void main() {
  test('Task serializa e desserializa em JSON', () {
    final task = Task(
      id: '1',
      title: 'Estudar Flutter',
      description: 'Ler a documentação',
      category: 'Estudo',
      priority: Priority.alta,
      done: true,
      createdAt: DateTime(2026, 11, 9),
      dueDate: DateTime(2026, 11, 12),
    );

    final copy = Task.fromJson(task.toJson());

    expect(copy.id, '1');
    expect(copy.title, 'Estudar Flutter');
    expect(copy.category, 'Estudo');
    expect(copy.priority, Priority.alta);
    expect(copy.done, isTrue);
    expect(copy.dueDate, DateTime(2026, 11, 12));
  });
}
